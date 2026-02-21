import os
import re
import requests

REPO = "trofimovelijah/red-flag-analysis"
API_BASE = f"https://api.github.com/repos/{REPO}/issues"

_EMPTY_MARKERS = {"_no response_", "no response", "n/a", ""}
_cache = {}  # ← кеш на время одной сборки


def _fetch_issue(number: int) -> dict:
    if number in _cache:
        return _cache[number]

    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    resp = requests.get(f"{API_BASE}/{number}", headers=headers, timeout=10)
    resp.raise_for_status()

    _cache[number] = resp.json()
    return _cache[number]


def _extract_section(body: str, header: str) -> str:
    pattern = rf"### {re.escape(header)}\s*\n(.*?)(?=\n### |\Z)"
    match = re.search(pattern, body, re.DOTALL)
    if match:
        text = match.group(1).strip()
        if text.lower() in _EMPTY_MARKERS:
            return ""
        return text
    return ""


def _clean_title(title: str) -> str:
    title = re.sub(r"^\[Requirement\]:?\s*", "", title, flags=re.IGNORECASE)
    return title.strip()


def define_env(env):

    @env.macro
    def github_req(issue_number: int, sections: list = None) -> str:
        if sections is None:
            sections = ["Описание"]

        try:
            data = _fetch_issue(issue_number)
        except Exception as e:
            return f'!!! warning "Ошибка загрузки issue #{issue_number}"\n\n    {e}\n'

        title = _clean_title(data["title"])
        body = data.get("body", "") or ""
        url = data["html_url"]

        lines = []
        lines.append(f"**{title}**")
        lines.append("")
        lines.append(
            f"[:octicons-link-external-16: Issue #{issue_number}]"
            f"({url}){{ .md-button .md-button--primary }}"
        )
        lines.append("")

        for section_name in sections:
            content = _extract_section(body, section_name)
            if content:
                lines.append(f"**{section_name}**")
                lines.append("")
                lines.append(content)
                lines.append("")

        return "\n".join(lines)

    @env.macro
    def github_req_full(issue_number: int) -> str:
        all_sections = [
            "Описание",
            "Критерии приёмки",
            "Предусловия",
            "Сценарии (основной)",
            "Альтернативные сценарии",
            "Примечания",
        ]
        return github_req(issue_number, sections=all_sections)
