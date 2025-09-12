# General Project Rules

1. **File Read Restrictions**

- Never read files that are ignored by git (as defined in `.gitignore` or `.git/info/exclude`).
- This includes sensitive files such as `.env`, credentials, and key files.
- Only read files that are tracked or untracked and not ignored. If you must read a file outside the current project, do it with `cat` and ask for explicit user permission.

2. **Git Repository Requirement**
   - Before any file operation (read, write, edit, create, delete), the assistant must check if the current working directory is a git repository. If it is not, the assistant must ask for explicit user permission before proceeding, or abort the operation and return the error: "Error: This operation is not permitted outside a git repository."

- This ensures all changes are version-controlled and secure.

3. **File Creation Scope**
   - Only create new files within the current working directory (CWD).
   - Do not create files outside the CWD, including parent, system, or user directories.
   - If you absolutely must create a file outside the CWD, first create it with `touch` and ask for explicit user permission, then you may edit it as needed.

4. **File Access Scope**

- Never read files outside the current working directory.
- If you must read a file outside the CWD, use a command like `cat` and always ask for explicit user permission first.

5. **Error Handling**

- If any rule is violated, abort the operation and return a clear error message.

6. **Examples**

- Do not read `/project/secret.key` if it is listed in `.gitignore`.
- Do not create `/tmp/newfile.txt` if the current working directory is `/project`.
- Do not create `/var/log/custom.log` unless you first create it with `touch` and ask for explicit user permission, then you may edit it as needed.
- Do not read `/etc/hosts` unless you ask for explicit permission using `cat`.

# Tools

## Edit

- Always prefer atomic edits (single, unique string replacements) for file modifications.
- Use `replaceAll` only for explicit "refactor" or "rename" requests, or if the user grants permission after being prompted.
- If `replaceAll` is needed outside of "refactor"/"rename", clearly inform the user: "I'm planning on using 'replaceAll' for this edit. Can I proceed?" and only proceed if permission is granted.

## MCP

### GitLab MCP Server

- The GitLab MCP server provides direct integration with GitLab for automation, data retrieval, and command execution.
- Always use the GitLab MCP server for any operations involving GitLab repositories, issues, merge requests, or CI/CD pipelines.
- **Important:** If you are provided with a direct link to a GitLab resource, always use the MCP server to fetch or interact with that resource. Do not use the link itself or raw webfetch requests unless the MCP server is unavailable or unsupported for your use case.
- MCP integration handles authentication, permissions, rate limits, and API changes, making it more robust and secure than using raw webfetch requests.
- Avoid using webfetch for GitLab unless MCP is unavailable or unsupported for your use case.

### Atlassian MCP Server (JIRA & Confluence)

- The Atlassian MCP server enables seamless interaction with Atlassian products, specifically JIRA and Confluence.
- Prefer the Atlassian MCP server for all operations involving JIRA issues, boards, projects, or Confluence pages and spaces.
- **Important:** If you are provided with a direct link to a JIRA or Confluence resource, always use the MCP server to fetch or interact with that resource. Do not use the link itself or raw webfetch requests unless the MCP server is unavailable or unsupported for your use case.
- MCP integration manages authentication, permissions, and adapts to Atlassian API changes, providing reliable and context-aware automation.
- Only use webfetch for Atlassian products if MCP does not support the required functionality.
