from pathlib import Path


def test_docs_index_links_phase_one_documents() -> None:
    contents = Path("docs/README.md").read_text(encoding="utf-8")
    expected_links = (
        "runbooks/first_run.md",
        "runbooks/smoke_qa.md",
        "reference/repo_structure.md",
        "policy/migrations_and_schema.md",
        "specs/README.md",
    )
    missing = [link for link in expected_links if link not in contents]
    assert not missing, f"docs/README.md is missing links: {missing}"
