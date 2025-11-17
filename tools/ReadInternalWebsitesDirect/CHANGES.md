# Refactoring Changes

## Summary

Refactored `read_internal_website.py` from CR-specific tool to generic internal website fetcher.

## Files Changed

### Modified
- **read_internal_website.py** - Main module, removed CR-specific code, added new features

### Created
- **cr_parser.py** - New module for CR-specific utilities
- **README.md** - Comprehensive documentation
- **VALIDATION_REPORT.md** - Test results and validation
- **test_urls.txt** - Sample batch file for testing

## Breaking Changes

### Removed from read_internal_website.py
- ❌ `parse_cr_table()` function → Moved to `cr_parser.py`
- ❌ `--parse-cr` CLI flag → Use `cr_parser.py` module instead
- ❌ CR-specific examples in CLI help

### Migration Guide

**Before:**
```python
from read_internal_website import read_internal_website, parse_cr_table

data = read_internal_website("https://code.amazon.com/reviews/to-user/user")
if data["success"] and data["content_type"] == "markdown":
    crs = parse_cr_table(data["content"])
```

**After:**
```python
from read_internal_website import read_internal_website, is_success
from cr_parser import parse_cr_table

data = read_internal_website("https://code.amazon.com/reviews/to-user/user")
if is_success(data) and data["content_type"] == "markdown":
    crs = parse_cr_table(data["content"])
```

**CLI Before:**
```bash
python3 read_internal_website.py https://code.amazon.com/reviews/to-user/user --parse-cr
```

**CLI After:**
```python
# Use Python API instead
from read_internal_website import read_internal_website
from cr_parser import parse_cr_table

data = read_internal_website("https://code.amazon.com/reviews/to-user/user")
crs = parse_cr_table(data["content"])
```

## New Features

### 1. Enhanced Error Detection
```python
{
    "error": "MCP returned error",
    "error_code": "MCP_ERROR",  # NEW
    "error_details": "Invalid Board URL..."
}
```

**Error Codes:**
- `MCP_ERROR` - Builder-mcp returned error
- `TIMEOUT` - Request timeout
- `SUBPROCESS_ERROR` - Command failed
- `NOT_FOUND` - builder-mcp not installed
- `PARSE_ERROR` - JSON parse failure
- `EXTRACTION_FAILED` - Content extraction failure
- `UNKNOWN` - Unexpected error

### 2. Warnings Field
```python
{
    "warnings": [  # NEW
        "Content detected as JSON but failed to parse"
    ]
}
```

### 3. Metadata Field
```python
{
    "metadata": {  # NEW
        "fetch_duration_ms": 2184
    }
}
```

### 4. Batch Processing
```python
# NEW Function
from read_internal_website import read_internal_websites

urls = ["https://phonetool.amazon.com/", "https://code.amazon.com/"]
results = read_internal_websites(urls)
```

**CLI:**
```bash
python3 read_internal_website.py --batch urls.txt
```

### 5. Helper Functions
```python
from read_internal_website import is_success, get_content, has_warnings

result = read_internal_website(url)

# NEW - Cleaner API
if is_success(result):
    content = get_content(result)
    if has_warnings(result):
        print(result["warnings"])
```

### 6. Multiple Output Formats
```bash
# JSON (default)
python3 read_internal_website.py https://phonetool.amazon.com/

# Text summary
python3 read_internal_website.py https://phonetool.amazon.com/ --format text

# Content only (pipeable)
python3 read_internal_website.py https://phonetool.amazon.com/ --format content-only
```

### 7. Improved Content Type Detection
```python
# Now handles dict input
def detect_content_type(content: Union[str, dict]) -> str:
    if isinstance(content, dict):
        return "json"
    # ... string detection
```

## Response Structure Changes

### Before
```python
{
    "success": True/False,
    "url": "...",
    "content": ...,
    "content_type": "...",
    "content_length": 123,
    "timestamp": "...",
    "error": "...",           # if failed
    "debug_info": {...}       # if debug=True
}
```

### After
```python
{
    "success": True/False,
    "url": "...",
    "content": ...,
    "content_type": "...",
    "content_length": 123,
    "timestamp": "...",
    "warnings": [],           # NEW - always present
    "metadata": {             # NEW - always present
        "fetch_duration_ms": 123
    },
    "error": "...",           # if failed
    "error_code": "...",      # NEW - if failed
    "error_details": "...",   # renamed from error_details
    "debug_info": {...}       # if debug=True
}
```

## Validation Results

### Sites Tested
- ✅ code.amazon.com - JSON (107KB)
- ✅ phonetool.amazon.com - Markdown (23KB)
- ✅ builderhub.corp.amazon.com - JSON (10KB)
- ⚠️ board.amazon.com - MCP_ERROR (expected)

### Test Results
- ✅ All content types detected correctly
- ✅ Error detection working
- ✅ New fields populated correctly
- ✅ Helper functions working
- ✅ Batch mode working
- ✅ CLI enhancements working

## Documentation

### New Files
- **README.md** - User guide with examples
- **VALIDATION_REPORT.md** - Detailed test results
- **cr_parser.py** - Docstrings and examples

### Updated
- **read_internal_website.py** - Module docstring with new examples

## Backward Compatibility

### Compatible (No Changes Needed)
✅ Basic usage:
```python
from read_internal_website import read_internal_website
result = read_internal_website(url)
if result["success"]:
    print(result["content"])
```

✅ CLI basic usage:
```bash
python3 read_internal_website.py https://code.amazon.com/
```

### Incompatible (Migration Required)
❌ Using `parse_cr_table()` from main module:
```python
# OLD
from read_internal_website import parse_cr_table

# NEW
from cr_parser import parse_cr_table
```

❌ Using `--parse-cr` CLI flag:
```bash
# OLD
python3 read_internal_website.py URL --parse-cr

# NEW - Use Python API
python3 -c "from read_internal_website import *; from cr_parser import *; ..."
```

❌ Using `--content-only` CLI flag:
```bash
# OLD
python3 read_internal_website.py URL --content-only

# NEW
python3 read_internal_website.py URL --format content-only
```

## Performance

No significant performance impact:
- Fetch times: ~2.6s average (same as before)
- Added metadata collection: <1ms overhead
- New error detection: <1ms overhead

## Next Steps

### Recommended
1. Update any scripts using `parse_cr_table()` to import from `cr_parser`
2. Replace `--content-only` with `--format content-only`
3. Test with your specific URLs to ensure compatibility

### Optional
1. Try new helper functions for cleaner code
2. Use batch mode for multiple URLs
3. Explore text format for human-readable output

## Questions?

- See [README.md](README.md) for usage examples
- See [VALIDATION_REPORT.md](VALIDATION_REPORT.md) for detailed test results
- Check module docstrings for API reference
