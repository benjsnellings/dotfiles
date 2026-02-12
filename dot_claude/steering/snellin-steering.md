
### Git and Code Review Operations

**ALWAYS delegate git and code review operations to specialized agents.**

#### Git Operations → `amzn-commit:amzn-commit` Agent

Use the `amzn-commit:amzn-commit` agent (via Task tool) for ALL git operations:
- Committing changes
- Viewing git status, log, diff
- Creating/switching branches
- Staging files
- Managing stash
- Cleaning up [gone] branches

**Do NOT run git commands directly** - always invoke the agent.

#### Code Reviews → `amzn-cr:amzn-cr` Agent

Use the `amzn-cr:amzn-cr` agent (via Task tool) for ALL CRUX code review operations:
- Creating new code reviews (`cr` command)
- Updating existing CRs
- Addressing reviewer feedback
- Reviewing code changes (local or CRUX URLs)
- Multi-package reviews

#### How to Invoke

```
Task tool with:
  subagent_type: amzn-commit:amzn-commit  # for git operations
  OR
  subagent_type: amzn-cr:amzn-cr          # for code reviews
  prompt: [describe the operation]
```

#### Examples

| User Request | Agent to Use |
|--------------|--------------|
| "Commit these changes" | `amzn-commit:amzn-commit` |
| "Show me git status" | `amzn-commit:amzn-commit` |
| "Create a code review" | `amzn-cr:amzn-cr` |
| "Address the CR feedback" | `amzn-cr:amzn-cr` |
| "Review this CR link" | `amzn-cr:amzn-cr` |

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

### Claude Code: Verbose Command Output Bug

**Problem**: Claude Code has issues detecting completion of commands that produce massive output (87,000+ characters). The process gets killed (SIGKILL, exit code 137) even after the command completes successfully.

**Affected Commands**:
- `brazil-build` / `brazil-build release` (CDK synth produces massive output)
- Any command that outputs tens of thousands of characters

**Symptoms**:
- Exit code 137 (128 + 9 = SIGKILL)
- Message: `[Request interrupted by user for tool use]`
- Build actually succeeded (visible in truncated output)
- Background tasks accumulate and never clean up properly

**Workaround**: Redirect output to a file and capture only the exit code:

```bash
# Instead of:
brazil-build release

# Use:
brazil-build release > /tmp/build.log 2>&1; echo "EXIT_CODE=$?"

# Then check results:
tail -20 /tmp/build.log  # Verify BUILD SUCCEEDED
```

**Why This Happens**: Claude Code's process handling appears to have buffer/stream issues with very large output. When output exceeds ~30,000 characters (truncation threshold), the underlying process management struggles to properly detect command completion.

**Date Discovered**: 2025-12-19
