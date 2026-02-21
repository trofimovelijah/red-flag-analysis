import os
import re
import requests

REPO = "trofimovelijah/red-flag-analysis"
API_BASE = f"https://api.github.com/repos/{REPO}/issues"


def _fetch_issue(number: int) -> dict:
    """Получить данные issue из GitHub API."""
    headers = {"Accept": "application/vnd.github+json"}
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    
    resp = requests.get(f"{API_BASE}/{number}", headers=headers, timeout=10)
    resp.raise_for_status()
    return resp.json()


def _extract_section(body: str, header: str) -> str:
    """Извлечь содержимое секции по заголовку ### из тела issue."""
    pattern = rf"### {re.escape(header)}\s*\n(.*?)(?=\n### |\Z)"
    match = re.search(pattern, body, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""


def _clean_title(title: str) -> str:
    """Убрать префикс [Requirement] / [Requirement]: из заголовка."""
    title = re.sub(r"^\[Requirement\]:?\s*", "", title, flags=re.IGNORECASE)
    return title.strip()


def define_env(env):
    """Регистрация макросов для mkdocs-macros."""

    @env.macro
    def github_req(issue_number: int, sections: list = None) -> str:
        """
        Макрос для вставки требования из GitHub Issue.
        
        Использование в Markdown:
            {{ github_req(21) }}
            {{ github_req(23, sections=["Описание", "Критерии приёмки"]) }}
        
        По умолчанию выводит: Заголовок + Описание.
        """
        if sections is None:
            sections = ["Описание"]
        
        try:
            data = _fetch_issue(issue_number)
        except Exception as e:
            return f'!!! warning "Ошибка загрузки issue #{issue_number}"\n\n    {e}\n'

        title = _clean_title(data["title"])
        body = data.get("body", "") or ""
        url = data["html_url"]
        
        # Формируем Markdown
        lines = []
        lines.append(f"**{title}**")
        lines.append("")
        lines.append(f"[:octicons-link-external-16: Issue #{issue_number}]({url}){{ .md-button .md-button--primary }}")
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
        """
        Макрос для полной вставки требования (все секции).
        
        Использование в Markdown:
            {{ github_req_full(21) }}
        """
        all_sections = [
            "Описание",
            "Критерии приёмки",
            "Предусловия",
            "Сценарии (основной)",
            "Альтернативные сценарии",
            "Примечания",
        ]
        return github_req(issue_number, sections=all_sections)

