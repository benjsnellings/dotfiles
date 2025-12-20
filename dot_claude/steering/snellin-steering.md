### Git Commit Operations

**ALWAYS delegate git commit operations to the `git-operator` agent.**

While you have permissions to run git commands directly, you MUST use the `git-operator` agent for all commit-related operations. This ensures consistent, well-formatted commit messages following Conventional Commits specification.

#### Operations requiring git-operator
- `git commit` - Creating commits (agent ensures proper message format)
- `git add` + `git commit` - Staging and committing together

#### Operations you CAN run directly
- `git status` - Checking repository state
- `git log` - Viewing commit history
- `git diff` - Viewing changes
- `git branch` - Listing/managing branches

#### How to Use

When the user asks to commit changes, use the Task tool:

```
Task tool with:
  subagent_type: git-operator
  prompt: [describe the commit operation and context]
```

The git-operator agent will:
1. Check `git status` to understand the changes
2. Review `git diff` to understand what's being committed
3. Create a properly formatted commit message following Conventional Commits
4. Execute the commit

#### Conventional Commits Specification

All commit messages MUST follow the Conventional Commits format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
| Type | When to Use |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Changes that don't affect code meaning (formatting, whitespace) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `chore` | Build process, tooling, or auxiliary changes |
| `ci` | CI/CD configuration changes |

**Rules:**
- Use imperative mood ("add" not "added" or "adds")
- Limit subject to 50 characters
- Capitalize subject line
- No period at end of subject
- Wrap body at 72 characters
- Body explains WHAT and WHY, not HOW

#### Commit Message Quality Requirements

The git-operator agent MUST ultrathink before creating commit messages:

1. **Deep Analysis**: Thoroughly explore `git diff` output to understand:
   - What files were changed and why
   - The nature of changes (new code, modifications, deletions)
   - Relationships between changed files
   - The intent behind the changes

2. **Context Gathering**:
   - Review recent commit history (`git log`) to match existing style
   - Consider the broader purpose of the changes
   - Identify if changes are part of a larger feature or fix

3. **Message Crafting**:
   - Choose the most accurate type (feat vs fix vs refactor)
   - Write a description that captures the essence of the change
   - Include body text for non-trivial changes explaining the "why"
   - Reference related issues/tickets when applicable

**Example of thorough analysis:**
```
# Bad (surface-level):
chore: Update files

# Good (after ultrathink analysis):
feat(auth): Add session timeout handling for inactive users

Implement automatic session expiration after 30 minutes of inactivity.
Sessions are now tracked with a last-activity timestamp and validated
on each request. This addresses security requirements for PCI compliance.
```

### Working with Quip Documents

When working with Quip documents, use the appropriate MCP tool based on your intent:

#### Tool Selection Rules

**ALWAYS use ReadInternalWebsites for read-only operations:**
- Viewing document content
- Reading comments (add `?includeComments=true` to URL)
- Batch reading multiple documents
- Any operation where you only need to retrieve information

**ONLY use QuipEditor when making edits:**
- Creating new Quip documents
- Modifying existing content (append, prepend, replace)
- Restructuring documents (moving sections, updating headings)
- Any operation that changes the document state

#### Examples

**Reading a Quip document (use ReadInternalWebsites):**
```json
{
  "inputs": ["https://quip-amazon.com/ABC123?includeComments=true"]
}
```

**Editing a Quip document (use QuipEditor):**
```json
{
  "documentId": "ABC123",
  "content": "New content to add",
  "format": "markdown",
  "location": 0
}
```

#### Rationale
ReadInternalWebsites is more efficient for read-only operations as it's a simpler, general-purpose tool designed for retrieving content from internal websites. QuipEditor has additional overhead for edit capabilities and should only be used when modifications are actually needed. This ensures optimal performance and follows the principle of using the simplest tool that accomplishes the task.

### Creating Scripts for Internal Amazon Websites

When creating Python scripts that need to fetch or scrape data from internal Amazon websites, **ALWAYS use the `read_internal_website.py` module** instead of implementing your own HTTP/scraping logic.

#### Module Location

`/Users/snellin/tools/ReadInternalWebsitesDirect/read_internal_website.py`

#### When to Use

Use this module when creating scripts that need to:
- Fetch data from ANY internal Amazon website
- Batch process multiple internal URLs
- Create automation scripts that read internal resources
- Build tools that aggregate data from multiple internal sources
- Parse code reviews, user profiles, documentation, or other internal data

#### Standard Import Pattern

```python
from read_internal_website import (
    read_internal_website,      # Fetch single URL
    read_internal_websites,     # Batch fetch multiple URLs
    is_success,                 # Check if fetch succeeded
    get_content,                # Extract content from result
    has_warnings                # Check for warnings
)

# Basic usage
result = read_internal_website("https://phonetool.amazon.com/users/username")

if is_success(result):
    content = get_content(result)
    print(f"Content type: {result['content_type']}")
    print(content)
else:
    print(f"Error: {result['error_code']} - {result['error_details']}")

# Batch usage
urls = [
    "https://phonetool.amazon.com/users/user1",
    "https://phonetool.amazon.com/users/user2"
]
results = read_internal_websites(urls)

for result in results:
    if is_success(result):
        print(f"✓ {result['url']}")
```

#### Supported Websites

The module works with **ANY** internal Amazon website, including:

| Website | Content Type | Use Case |
|---------|--------------|----------|
| code.amazon.com | JSON/Markdown | Code reviews, packages, commits |
| phonetool.amazon.com | JSON | User profiles, org charts |
| builderhub.corp.amazon.com | JSON | Documentation, guides |
| board.amazon.com | JSON | Boards (requires board ID) |
| w.amazon.com | HTML/Markdown | Wiki pages |
| quip-amazon.com | Markdown/HTML | Documents |
| issues.amazon.com / sim.amazon.com | JSON | Tickets, tasks |
| apollo.amazon.com | JSON | Deployments, environments |
| pipelines.amazon.com | JSON | CI/CD pipelines |

#### Response Structure

All functions return a standardized response:

```python
{
    "success": True/False,
    "url": "the URL that was fetched",
    "content": <dict for JSON, string for others>,
    "content_type": "json|markdown|html|text",
    "content_length": 12345,
    "timestamp": "2025-11-17T10:00:00.000000",
    "warnings": [],
    "metadata": {"fetch_duration_ms": 123},
    "error": "error message if success=False",
    "error_code": "ERROR_CATEGORY",
    "error_details": "detailed error information"
}
```

#### Key Features

- **Automatic Content Detection**: Detects and parses JSON, Markdown, HTML, and plain text
- **Comprehensive Error Handling**: Specific error codes (MCP_ERROR, TIMEOUT, PARSE_ERROR, etc.)
- **Batch Processing**: Fetch multiple URLs efficiently
- **Authentication**: Works seamlessly with builder-mcp for credential management
- **Structured Output**: Consistent response format with metadata
- **CLI Support**: Can be used as command-line tool or Python library

#### CLI Usage (Alternative to Programmatic)

```bash
# Fetch single URL
python3 /Users/snellin/tools/ReadInternalWebsitesDirect/read_internal_website.py \
    https://phonetool.amazon.com/users/username --format content-only

# Batch fetch
python3 /Users/snellin/tools/ReadInternalWebsitesDirect/read_internal_website.py \
    --batch urls.txt --format json --output results.json
```

#### Special Case: Code Review Parsing

For code review specific parsing, also use the companion `cr_parser.py` module:

```python
from read_internal_website import read_internal_website, is_success
from cr_parser import parse_cr_table, count_pending_approvals

result = read_internal_website("https://code.amazon.com/reviews/to-user/username")

if is_success(result) and result["content_type"] == "markdown":
    crs = parse_cr_table(result["content"])
    print(f"Found {len(crs)} code reviews")

    pending = count_pending_approvals(crs, "username")
    print(f"{pending} pending your approval")
```

#### Rationale

- **Consistency**: Provides uniform authentication, error handling, and content parsing across all internal Amazon websites
- **Reliability**: Maintained and tested module that works with builder-mcp
- **Efficiency**: Eliminates need to reimplement HTTP/auth/parsing logic
- **Error Handling**: Built-in timeout handling, error categorization, and detailed error messages
- **Maintenance**: Single point of updates if internal website APIs change
- **Content Detection**: Automatically handles different response formats (JSON, Markdown, HTML, text)
