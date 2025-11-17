# read_internal_website

A generic Python module for fetching data from ANY Amazon internal website using builder-mcp.

## Features

- 🌐 **Universal Fetching**: Works with any internal Amazon website
- 📦 **Batch Processing**: Fetch multiple URLs in one command
- 🔍 **Content Detection**: Automatically detects JSON, Markdown, HTML, and text
- ⚡ **Fast**: Built on builder-mcp for optimal performance
- 🛡️ **Error Handling**: Comprehensive error detection and reporting
- 📊 **Multiple Output Formats**: JSON, text summary, or content-only
- 🔧 **Programmatic API**: Use as a Python library or CLI tool

## Installation

Ensure you have builder-mcp installed:

```bash
toolbox install mcp-registry
mcp-registry install builder-mcp
```

## Quick Start

### Command Line Usage

```bash
# Fetch a single URL
python3 read_internal_website.py https://phonetool.amazon.com/users/username

# Get just the content (for piping)
python3 read_internal_website.py https://phonetool.amazon.com/ --format content-only

# Get a text summary
python3 read_internal_website.py https://phonetool.amazon.com/ --format text

# Batch fetch multiple URLs
python3 read_internal_website.py --batch urls.txt

# Save output to file
python3 read_internal_website.py https://code.amazon.com/ --output result.json
```

### Python Library Usage

```python
from read_internal_website import (
    read_internal_website,
    read_internal_websites,
    is_success,
    get_content,
    has_warnings
)

# Fetch a single URL
result = read_internal_website("https://phonetool.amazon.com/users/username")

if is_success(result):
    content = get_content(result)
    print(f"Content type: {result['content_type']}")
    print(content)

# Batch fetching
urls = [
    "https://phonetool.amazon.com/users/user1",
    "https://phonetool.amazon.com/users/user2"
]
results = read_internal_websites(urls)

for result in results:
    if is_success(result):
        print(f"✓ {result['url']} - {result['content_type']}")
    else:
        print(f"✗ {result['url']} - {result['error']}")
```

## Supported Websites

| Website | Content Type | Example URL |
|---------|--------------|-------------|
| code.amazon.com | JSON | `https://code.amazon.com/reviews/to-user/username` |
| phonetool.amazon.com | Markdown | `https://phonetool.amazon.com/users/username` |
| builderhub.corp.amazon.com | JSON | `https://builderhub.corp.amazon.com/docs/brazil/` |
| board.amazon.com | JSON | `https://board.amazon.com/boards/BOARD-ID` |
| w.amazon.com | HTML/Markdown | `https://w.amazon.com/bin/view/Teams/MyTeam` |
| quip-amazon.com | Markdown/HTML | `https://quip-amazon.com/DOCID` |
| issues.amazon.com | JSON | `https://issues.amazon.com/issues/ISSUE-123` |
| apollo.amazon.com | JSON | `https://apollo.amazon.com/environments/ENV` |
| pipelines.amazon.com | JSON | `https://pipelines.amazon.com/pipelines/NAME` |

## Response Structure

```python
{
    "success": True/False,
    "url": "the URL that was fetched",
    "content": <content - dict for JSON, string for others>,
    "content_type": "json|markdown|html|text",
    "content_length": 12345,
    "timestamp": "2025-11-17T09:44:25.378929",
    "warnings": [],  # Non-fatal issues
    "metadata": {
        "fetch_duration_ms": 123
    },
    "error": "error message if success=False",
    "error_code": "ERROR_CATEGORY",
    "error_details": "detailed error information"
}
```

### Error Codes

- `MCP_ERROR`: Builder-mcp returned an error (e.g., invalid URL)
- `TIMEOUT`: Request took too long
- `SUBPROCESS_ERROR`: builder-mcp command failed
- `NOT_FOUND`: builder-mcp is not installed
- `PARSE_ERROR`: Failed to parse JSON response
- `EXTRACTION_FAILED`: Could not extract content from response
- `UNKNOWN`: Unexpected error

## API Reference

### Main Functions

#### `read_internal_website(url, timeout=30, debug=False)`

Fetch data from a single internal website.

**Parameters:**
- `url` (str): The internal website URL to fetch
- `timeout` (int): Timeout in seconds (default: 30)
- `debug` (bool): Enable debug logging (default: False)

**Returns:** `Dict[str, Any]` - Response dictionary

#### `read_internal_websites(urls, timeout=30, debug=False)`

Fetch data from multiple URLs sequentially.

**Parameters:**
- `urls` (List[str]): List of URLs to fetch
- `timeout` (int): Timeout in seconds per URL (default: 30)
- `debug` (bool): Enable debug logging (default: False)

**Returns:** `List[Dict[str, Any]]` - List of response dictionaries

### Helper Functions

#### `is_success(result)`

Check if a fetch result was successful.

**Returns:** `bool`

#### `get_content(result)`

Extract content from a result, or None if failed.

**Returns:** `Optional[Any]`

#### `has_warnings(result)`

Check if a result has any warnings.

**Returns:** `bool`

## Code Review Parsing

For code review specific parsing, use the separate `cr_parser` module:

```python
from read_internal_website import read_internal_website, is_success
from cr_parser import parse_cr_table, count_pending_approvals

# Fetch code reviews (markdown format)
result = read_internal_website("https://code.amazon.com/reviews/to-user/username")

if is_success(result) and result["content_type"] == "markdown":
    crs = parse_cr_table(result["content"])

    print(f"Found {len(crs)} code reviews")

    # Count pending approvals
    pending = count_pending_approvals(crs, "username")
    print(f"{pending} pending your approval")

    # Access CR data
    for cr in crs:
        print(f"{cr['ID']}: {cr.get('Summary', 'N/A')}")
```

## CLI Options

```
usage: read_internal_website.py [-h] [--debug] [--timeout TIMEOUT]
                                 [--batch BATCH]
                                 [--format {json,text,content-only}]
                                 [--output OUTPUT]
                                 [url]

positional arguments:
  url                   Any Amazon internal website URL

optional arguments:
  -h, --help            show this help message and exit
  --debug               Enable debug output
  --timeout TIMEOUT     Timeout in seconds (default: 30)
  --batch BATCH         File with URLs to fetch (one per line)
  --format {json,text,content-only}
                        Output format (default: json)
  --output OUTPUT       Save output to file
```

### Batch File Format

Create a text file with one URL per line. Lines starting with `#` are treated as comments.

```
# My test URLs
https://phonetool.amazon.com/users/user1
https://phonetool.amazon.com/users/user2
https://code.amazon.com/

# More URLs...
https://builderhub.corp.amazon.com/
```

## Examples

### Example 1: Fetch User Profile

```python
from read_internal_website import read_internal_website, is_success, get_content

result = read_internal_website("https://phonetool.amazon.com/users/snellin")

if is_success(result):
    content = get_content(result)
    print(f"Fetched {result['content_length']} chars of {result['content_type']}")
    print(content[:500])  # Print first 500 chars
```

### Example 2: Fetch Code Reviews

```python
result = read_internal_website("https://code.amazon.com/")

if is_success(result):
    data = get_content(result)
    print(f"Summary: {data['summary']}")
    print(f"Reviews: {len(data['reviews'])}")
```

### Example 3: Batch Fetch with Error Handling

```python
from read_internal_website import read_internal_websites

urls = [
    "https://phonetool.amazon.com/",
    "https://code.amazon.com/",
    "https://board.amazon.com/",  # This will error - needs board ID
]

results = read_internal_websites(urls)

for result in results:
    if is_success(result):
        print(f"✓ {result['url']}: {result['content_type']}, "
              f"{result['content_length']} chars")
    else:
        print(f"✗ {result['url']}: {result['error_code']} - "
              f"{result['error_details']}")
```

### Example 4: CLI Batch Processing

```bash
# Create batch file
cat > my_urls.txt << EOF
https://code.amazon.com/
https://phonetool.amazon.com/
https://builderhub.corp.amazon.com/
EOF

# Fetch all URLs
python3 read_internal_website.py --batch my_urls.txt --format text
```

Output:
```
📋 Fetching 3 URLs from my_urls.txt
✅ 3/3 succeeded
```

## Troubleshooting

### builder-mcp not found

```bash
toolbox install mcp-registry
mcp-registry install builder-mcp
```

### Timeouts

Increase the timeout for slow sites:

```python
result = read_internal_website(url, timeout=60)
```

### Invalid board.amazon.com URLs

board.amazon.com requires a specific board ID:

```python
# ✗ Wrong
result = read_internal_website("https://board.amazon.com/")

# ✓ Correct
result = read_internal_website("https://board.amazon.com/boards/BOARD-12345")
```

### MCP Errors

Check the `error_details` field for specific error messages:

```python
if not is_success(result):
    print(f"Error: {result['error_code']}")
    print(f"Details: {result['error_details']}")
```

## Development

### Running Tests

```bash
# Test with validation URLs
python3 read_internal_website.py https://code.amazon.com/ --format text
python3 read_internal_website.py https://phonetool.amazon.com/ --format text
python3 read_internal_website.py https://builderhub.corp.amazon.com/ --format text
```

### Debug Mode

Enable debug mode to see detailed request/response information:

```bash
python3 read_internal_website.py https://code.amazon.com/ --debug
```

## License

Internal Amazon tool - for Amazon employees only.

## Related Tools

- [cr_parser.py](cr_parser.py) - Code review specific parsing utilities
- [builder-mcp](https://builderhub.corp.amazon.com/docs/builder-mcp/) - MCP server for internal tools

## Support

For issues or questions:
1. Check this README
2. Try debug mode: `--debug`
3. Check builder-mcp documentation
4. File an issue or contact the tool maintainers
