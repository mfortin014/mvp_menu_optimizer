from __future__ import annotations

import hashlib
import os
from types import SimpleNamespace

os.environ.setdefault("SUPABASE_URL", "https://example.supabase.co")
os.environ.setdefault(
    "SUPABASE_ANON_KEY",
    (
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
        "eyJzdWIiOiJzdXBhYmFzZS10ZXN0LWFub24ifQ."
        "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"
    ),
)

from utils import ingestion_jobs as subject


def test_upload_spec_from_bytes_hashes_payload() -> None:
    blob = b"roma tomato"
    spec = subject.IngestionUploadSpec.from_bytes("component", "components.csv", blob)

    assert spec.byte_length == len(blob)
    assert spec.checksum == hashlib.sha256(blob).hexdigest()
    assert spec.content_type == "text/csv"


class _StorageBucketStub:
    def __init__(self, name: str):
        self.name = name
        self.calls: list[tuple[str, int]] = []

    def create_signed_upload_url(self, path: str, *, expires_in: int = 900):
        self.calls.append((path, expires_in))
        return {"signed_url": f"https://upload.local/{self.name}/{path}"}


class _StorageStub:
    def __init__(self):
        self.buckets: dict[str, _StorageBucketStub] = {}

    def from_(self, bucket: str) -> _StorageBucketStub:
        if bucket not in self.buckets:
            self.buckets[bucket] = _StorageBucketStub(bucket)
        return self.buckets[bucket]


class _SupabaseStub:
    def __init__(self, data: dict):
        self._data = data
        self.rpc_calls: list[tuple[str, dict]] = []
        self.storage = _StorageStub()

    def rpc(self, name: str, params: dict):
        self.rpc_calls.append((name, params))

        data = self._data

        class _Runner:
            def execute(self_inner):
                return SimpleNamespace(data=data)

        return _Runner()


def test_open_ingestion_job_requests_signed_urls(monkeypatch) -> None:
    tenant_id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
    job_id = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    file_payload = {
        "file_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
        "kind": "component",
        "file_name": "components.csv",
        "storage_path": "tenants/a/jobs/b/components.csv",
        "checksum": "deadbeef",
        "byte_length": 128,
        "content_type": "text/csv",
        "bucket": "ingestion-artifacts",
    }
    rpc_response = {
        "job_id": job_id,
        "tenant_id": tenant_id,
        "files": [file_payload],
    }
    supabase_stub = _SupabaseStub(rpc_response)
    monkeypatch.setattr(subject, "supabase", supabase_stub)
    monkeypatch.setattr(subject.tenant_db, "current_tenant_id", lambda: tenant_id)

    spec = subject.IngestionUploadSpec(
        kind="component",
        filename="components.csv",
        byte_length=128,
        checksum="deadbeef",
        content_type="text/csv",
    )

    result = subject.open_ingestion_job("ingredients", [spec], expires_in=600)

    assert result["job_id"] == job_id
    assert result["tenant_id"] == tenant_id
    assert len(result["files"]) == 1
    assert result["files"][0]["signed_url"].endswith(file_payload["storage_path"])

    assert supabase_stub.rpc_calls[0][0] == "ingestion_open_job"
    params = supabase_stub.rpc_calls[0][1]
    assert params["p_tenant_id"] == tenant_id
    assert params["p_files"][0]["file_name"] == "components.csv"

    bucket_calls = supabase_stub.storage.buckets["ingestion-artifacts"].calls
    assert bucket_calls == [(file_payload["storage_path"], 600)]
