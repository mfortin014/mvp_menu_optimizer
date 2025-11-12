from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence

from utils import tenant_db
from utils.supabase_client import supabase

DEFAULT_BUCKET = "ingestion-artifacts"
DEFAULT_UPLOAD_TTL_SECONDS = 900  # 15 minutes


def _sha256(blob: bytes) -> str:
    return hashlib.sha256(blob).hexdigest()


@dataclass(frozen=True, slots=True)
class IngestionUploadSpec:
    kind: str
    filename: str
    byte_length: int
    checksum: str
    content_type: str = "text/csv"

    @classmethod
    def from_bytes(
        cls,
        kind: str,
        filename: str,
        blob: bytes,
        *,
        content_type: str = "text/csv",
    ) -> "IngestionUploadSpec":
        data = blob or b""
        return cls(
            kind=kind,
            filename=filename,
            byte_length=len(data),
            checksum=_sha256(data),
            content_type=content_type,
        )

    @classmethod
    def from_path(
        cls,
        kind: str,
        path: Path,
        *,
        content_type: str = "text/csv",
    ) -> "IngestionUploadSpec":
        data = path.read_bytes()
        return cls.from_bytes(kind, path.name, data, content_type=content_type)

    def as_rpc_payload(self) -> Dict[str, Any]:
        return {
            "kind": self.kind,
            "file_name": self.filename,
            "byte_length": self.byte_length,
            "checksum": self.checksum,
            "content_type": self.content_type,
        }


def _coerce_signed_url(response: Any) -> Optional[str]:
    """
    Supabase-python returns either dicts or StorageResponse objects.
    Normalize to a simple string.
    """
    if response is None:
        return None
    if isinstance(response, dict):
        return response.get("signed_url") or response.get("url") or response.get("signedURL")
    return getattr(response, "signed_url", None) or getattr(response, "url", None)


def open_ingestion_job(
    preset: str,
    files: Sequence[IngestionUploadSpec],
    *,
    tenant_id: Optional[str] = None,
    source: str = "wizard",
    expires_in: int = DEFAULT_UPLOAD_TTL_SECONDS,
) -> Dict[str, Any]:
    """
    Opens an ingestion job via the Supabase RPC helper and returns upload targets
    with signed URLs so the UI can stream files directly to storage.
    """
    active_tenant = tenant_id or tenant_db.current_tenant_id()
    payload = [spec.as_rpc_payload() for spec in files]
    rpc_payload = {
        "p_tenant_id": active_tenant,
        "p_preset": preset,
        "p_source": source,
        "p_files": payload,
    }
    rpc_result = supabase.rpc("ingestion_open_job", rpc_payload).execute()
    job_data = getattr(rpc_result, "data", None) or {}
    job_id = job_data.get("job_id")
    if not job_id:
        raise RuntimeError("ingestion_open_job did not return a job_id")

    uploads: List[Dict[str, Any]] = []
    storage_items: Iterable[Dict[str, Any]] = job_data.get("files") or []
    for item in storage_items:
        bucket_name = item.get("bucket") or DEFAULT_BUCKET
        storage_path = item["storage_path"]
        signer = supabase.storage.from_(bucket_name)
        signed = signer.create_signed_upload_url(storage_path, expires_in=expires_in)
        uploads.append(
            {
                "file_id": item["file_id"],
                "kind": item.get("kind"),
                "file_name": item.get("file_name"),
                "bucket": bucket_name,
                "storage_path": storage_path,
                "signed_url": _coerce_signed_url(signed),
                "checksum": item.get("checksum"),
                "byte_length": item.get("byte_length"),
                "content_type": item.get("content_type"),
            }
        )

    return {
        "job_id": job_id,
        "tenant_id": job_data.get("tenant_id", active_tenant),
        "files": uploads,
    }


__all__ = [
    "IngestionUploadSpec",
    "open_ingestion_job",
    "DEFAULT_BUCKET",
    "DEFAULT_UPLOAD_TTL_SECONDS",
]
