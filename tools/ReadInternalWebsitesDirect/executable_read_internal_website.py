#!/usr/bin/env python3

"""
read_internal_website.py

A generic Python module for fetching data from ANY Amazon internal website using builder-mcp.
Uses the correct JSON-RPC format to invoke the ReadInternalWebsites tool.

Supported websites include:
- code.amazon.com (code reviews, packages, etc.) - Returns JSON
- phonetool.amazon.com (user profiles) - Returns Markdown
- builderhub.corp.amazon.com (documentation) - Returns JSON
- board.amazon.com (boards - requires specific board ID) - Returns JSON
- w.amazon.com (wiki pages) - Returns HTML/Markdown
- quip-amazon.com (documents) - Returns Markdown/HTML
- issues.amazon.com, sim.amazon.com (tickets/tasks) - Returns JSON
- apollo.amazon.com (deployments) - Returns JSON
- pipelines.amazon.com (CI/CD) - Returns JSON
- And any other internal Amazon website

Usage:
    from read_internal_website import read_internal_website, is_success, get_content

    # Fetch any internal website
    data = read_internal_website("https://phonetool.amazon.com/users/username")

    # Check success and access content
    if is_success(data):
        content = get_content(data)
        print(f"Content type: {data['content_type']}")
        print(content)

    # Batch fetching
    from read_internal_website import read_internal_websites

    urls = [
        "https://phonetool.amazon.com/users/user1",
        "https://phonetool.amazon.com/users/user2"
    ]
    results = read_internal_websites(urls)
    for result in results:
        if is_success(result):
            print(f"✓ {result['url']}")

Note: For code review specific parsing, see cr_parser.py module.
"""

import json
import subprocess
import sys
from typing import Dict, Any, Optional, Union, List
import logging
import re
from datetime import datetime
import time

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def read_internal_website(url: str, timeout: int = 30, debug: bool = False) -> Dict[str, Any]:
    """
    Fetch data from any Amazon internal website using builder-mcp.

    This is a generic function that works with ANY internal Amazon website.
    It returns the raw content fetched from the website, which can be:
    - HTML content from wiki pages
    - Markdown tables from code reviews
    - JSON data from API endpoints
    - Plain text from documentation
    - Any other format the website returns

    Args:
        url (str): The internal website URL to fetch
        timeout (int): Timeout in seconds for the builder-mcp call (default: 30)
        debug (bool): Enable debug logging (default: False)

    Returns:
        dict: JSON response with the following structure:
            {
                "success": True/False,
                "url": "the URL that was fetched",
                "content": <content - dict for JSON, string for others>,
                "content_type": "detected content type (html/markdown/json/text)",
                "content_length": number of characters,
                "timestamp": "ISO timestamp of fetch",
                "warnings": ["warning messages"],
                "metadata": {"fetch_duration_ms": 123},
                "error": "error message if success=False",
                "error_code": "error category if success=False",
                "debug_info": {...} if debug=True
            }

            Note: When content_type is "json", the content field will be a
            parsed JSON object (dict/list), not a string.

    Examples:
        >>> # Fetch a wiki page
        >>> data = read_internal_website("https://w.amazon.com/bin/view/Teams/MyTeam")
        >>> if data["success"]:
        >>>     print(f"Got {data['content_type']} content, {data['content_length']} chars")

        >>> # Fetch code reviews
        >>> data = read_internal_website("https://code.amazon.com/reviews/to-user/username")
        >>> if data["success"]:
        >>>     print(data["content"])  # Will be a markdown table

        >>> # Fetch documentation
        >>> data = read_internal_website("https://builderhub.corp.amazon.com/docs/some-doc")
        >>> if data["success"]:
        >>>     print(f"Content type: {data['content_type']}")
    """

    if debug:
        logger.setLevel(logging.DEBUG)

    start_time = time.time()

    # Build the correct JSON-RPC request
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "ReadInternalWebsites",
            "arguments": {
                "inputs": [url]
            }
        }
    }

    logger.debug(f"Request: {json.dumps(request)}")

    # Initialize response structure
    response_data = {
        "success": False,
        "url": url,
        "timestamp": datetime.now().isoformat(),
        "content": None,
        "content_type": None,
        "content_length": 0,
        "warnings": [],
        "metadata": {}
    }

    try:
        # Execute builder-mcp with the request using echo pipe (proven method)
        cmd = f"echo '{json.dumps(request)}' | builder-mcp"
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=timeout
        )

        logger.debug(f"Return code: {result.returncode}")
        logger.debug(f"Stdout length: {len(result.stdout)}")
        logger.debug(f"Stderr: {result.stderr}")

        if not result.stdout:
            response_data["error"] = "No response from builder-mcp"
            response_data["error_details"] = result.stderr if result.stderr else "Unknown error"
            return response_data

        # Parse the JSON-RPC response
        response = json.loads(result.stdout)

        # Extract the content from the nested structure
        content = extract_content(response)

        if content:
            # Check if MCP returned an error in the content
            if isinstance(content, dict) and content.get("status") == "error":
                response_data["success"] = False
                response_data["error"] = "MCP returned error"
                response_data["error_code"] = "MCP_ERROR"
                response_data["error_details"] = content.get("error", "Unknown MCP error")
                response_data["content"] = content  # Still include the error content
                response_data["content_type"] = "json"
                response_data["content_length"] = len(json.dumps(content))
            else:
                response_data["success"] = True

                # Determine content type first
                if isinstance(content, dict):
                    # Content is already a dict (JSON object)
                    response_data["content"] = content
                    response_data["content_type"] = "json"
                    # Calculate length from JSON string representation
                    response_data["content_length"] = len(json.dumps(content))
                else:
                    # Content is a string - detect type
                    response_data["content_type"] = detect_content_type(content)

                    # If it's JSON string, parse it to object
                    if response_data["content_type"] == "json":
                        try:
                            response_data["content"] = json.loads(content)
                            response_data["content_length"] = len(content)
                        except json.JSONDecodeError:
                            # If parsing fails, keep as string
                            response_data["content"] = content
                            response_data["content_length"] = len(content)
                            response_data["warnings"].append("Content detected as JSON but failed to parse")
                    else:
                        # For non-JSON content, keep as string
                        response_data["content"] = content
                        response_data["content_length"] = len(content)

            # Add metadata
            duration_ms = int((time.time() - start_time) * 1000)
            response_data["metadata"]["fetch_duration_ms"] = duration_ms

            # Add debug info if requested
            if debug:
                response_data["debug_info"] = {
                    "raw_response": response,
                    "return_code": result.returncode,
                    "stderr": result.stderr
                }
        else:
            response_data["error"] = "Failed to extract content from response"
            response_data["error_code"] = "EXTRACTION_FAILED"
            response_data["error_details"] = "Response structure not recognized"
            if debug:
                response_data["debug_info"] = {"raw_response": response}

        return response_data

    except subprocess.TimeoutExpired:
        response_data["error"] = f"Timeout after {timeout} seconds"
        response_data["error_code"] = "TIMEOUT"
        response_data["error_details"] = "builder-mcp took too long to respond"
        return response_data

    except subprocess.CalledProcessError as e:
        response_data["error"] = f"builder-mcp failed with exit code {e.returncode}"
        response_data["error_code"] = "SUBPROCESS_ERROR"
        response_data["error_details"] = str(e)
        return response_data

    except FileNotFoundError:
        response_data["error"] = "builder-mcp not found"
        response_data["error_code"] = "NOT_FOUND"
        response_data["error_details"] = "Install: toolbox install mcp-registry && mcp-registry install builder-mcp"
        return response_data

    except json.JSONDecodeError as e:
        response_data["error"] = "Failed to parse response as JSON"
        response_data["error_code"] = "PARSE_ERROR"
        response_data["error_details"] = str(e)
        if debug and 'result' in locals():
            response_data["debug_info"] = {"raw_output": result.stdout[:500]}
        return response_data

    except Exception as e:
        response_data["error"] = f"Unexpected error: {str(e)}"
        response_data["error_code"] = "UNKNOWN"
        response_data["error_details"] = str(e)
        return response_data


def detect_content_type(content: Union[str, dict]) -> str:
    """
    Detect the type of content based on patterns.

    Args:
        content (Union[str, dict]): The content to analyze

    Returns:
        str: Detected content type (html/markdown/json/text/unknown)
    """
    # Handle dict input - already JSON
    if isinstance(content, dict):
        return "json"

    # Handle list input - already JSON
    if isinstance(content, list):
        return "json"

    # Must be string at this point
    if not content or not isinstance(content, str):
        return "unknown"

    # Check for JSON string
    if content.strip().startswith('{') or content.strip().startswith('['):
        try:
            json.loads(content)
            return "json"
        except:
            pass

    # Check for HTML
    if '<html' in content.lower() or '<!doctype' in content.lower():
        return "html"
    if '<div' in content or '<p>' in content or '<h1' in content:
        return "html"

    # Check for Markdown table (common in code.amazon.com)
    if '|---|' in content and content.count('|') > 10:
        return "markdown"

    # Check for Markdown headers
    if content.startswith('#') or '\n#' in content:
        return "markdown"

    # Default to plain text
    return "text"


def extract_content(response: Dict[str, Any]) -> Optional[str]:
    """
    Extract the actual content from the nested JSON-RPC response structure.

    Args:
        response (dict): The JSON-RPC response from builder-mcp

    Returns:
        str or None: The extracted content, or None if not found
    """

    try:
        # Handle JSON-RPC response structure
        if "result" in response and "content" in response["result"]:
            result_content = response["result"]["content"]

            # Handle array of content objects
            if isinstance(result_content, list):
                for item in result_content:
                    if isinstance(item, dict) and "text" in item:
                        # Parse the nested JSON in the text field
                        try:
                            nested = json.loads(item["text"])

                            # Handle builderhub-specific structure with processedContent
                            if isinstance(nested, dict) and "processedContent" in nested:
                                # For builderhub, return the entire structure as dict
                                # It will be converted to JSON string in the main function
                                return nested

                            # Handle other structures
                            if "content" in nested:
                                if isinstance(nested["content"], dict) and "content" in nested["content"]:
                                    content = nested["content"]["content"]
                                else:
                                    content = nested["content"]
                                # Clean up any markdown link artifacts
                                if isinstance(content, str):
                                    import re
                                    content = re.sub(r'\[([^\]]+)\]\[\d+\]', r'\1', content)
                                return content
                        except json.JSONDecodeError:
                            # If not JSON, return the text directly
                            return item["text"]

            # Handle direct content
            elif isinstance(result_content, dict) and "content" in result_content:
                return result_content["content"]
            elif isinstance(result_content, str):
                return result_content

        # Fallback: check for direct content field
        if "content" in response:
            if isinstance(response["content"], dict) and "content" in response["content"]:
                return response["content"]["content"]
            return response["content"]

    except Exception as e:
        logger.error(f"Error extracting content: {e}")

    return None


def read_internal_websites(urls: List[str], timeout: int = 30, debug: bool = False) -> List[Dict[str, Any]]:
    """
    Fetch multiple URLs sequentially.

    Args:
        urls (List[str]): List of internal website URLs to fetch
        timeout (int): Timeout in seconds for each fetch (default: 30)
        debug (bool): Enable debug logging (default: False)

    Returns:
        List[Dict[str, Any]]: List of response dictionaries, one per URL

    Example:
        >>> urls = [
        >>>     "https://phonetool.amazon.com/users/user1",
        >>>     "https://phonetool.amazon.com/users/user2"
        >>> ]
        >>> results = read_internal_websites(urls)
        >>> for result in results:
        >>>     if is_success(result):
        >>>         print(f"✓ {result['url']}")
    """
    return [read_internal_website(url, timeout, debug) for url in urls]


def is_success(result: Dict[str, Any]) -> bool:
    """
    Check if a fetch result was successful.

    Args:
        result (Dict[str, Any]): Result from read_internal_website()

    Returns:
        bool: True if fetch was successful, False otherwise

    Example:
        >>> data = read_internal_website("https://phonetool.amazon.com/")
        >>> if is_success(data):
        >>>     print("Fetch succeeded!")
    """
    return result.get("success", False)


def get_content(result: Dict[str, Any]) -> Optional[Any]:
    """
    Extract content from a result, or None if failed.

    Args:
        result (Dict[str, Any]): Result from read_internal_website()

    Returns:
        Optional[Any]: Content if successful, None if failed

    Example:
        >>> data = read_internal_website("https://phonetool.amazon.com/")
        >>> content = get_content(data)
        >>> if content:
        >>>     print(content)
    """
    return result.get("content") if is_success(result) else None


def has_warnings(result: Dict[str, Any]) -> bool:
    """
    Check if a result has any warnings.

    Args:
        result (Dict[str, Any]): Result from read_internal_website()

    Returns:
        bool: True if there are warnings, False otherwise

    Example:
        >>> data = read_internal_website("https://some-site.amazon.com/")
        >>> if has_warnings(data):
        >>>     print("Warnings:", data["warnings"])
    """
    return len(result.get("warnings", [])) > 0


def main():
    """
    Command-line interface for the read_internal_website function.
    Works with ANY Amazon internal website.
    """

    import argparse

    parser = argparse.ArgumentParser(
        description="Fetch data from ANY Amazon internal website using builder-mcp",
        epilog="""
Examples:
  %(prog)s https://phonetool.amazon.com/users/username
  %(prog)s https://code.amazon.com/reviews/to-user/username
  %(prog)s https://builderhub.corp.amazon.com/docs/brazil/
  %(prog)s https://quip-amazon.com/DOCID
  %(prog)s https://board.amazon.com/boards/BOARD-ID
  %(prog)s --batch urls.txt --format json

Batch file format (one URL per line):
  https://phonetool.amazon.com/users/user1
  https://phonetool.amazon.com/users/user2
  https://code.amazon.com/
        """
    )
    parser.add_argument("url", nargs="?", help="Any Amazon internal website URL")
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout in seconds (default: 30)")
    parser.add_argument("--batch", help="File with URLs to fetch (one per line)")
    parser.add_argument("--format", choices=["json", "text", "content-only"], default="json",
                        help="Output format (default: json)")
    parser.add_argument("--output", help="Save output to file")

    args = parser.parse_args()

    # Validate arguments
    if not args.url and not args.batch:
        parser.error("Either url or --batch must be provided")

    # Fetch the data
    if args.batch:
        # Batch mode - read URLs from file
        try:
            with open(args.batch, 'r') as f:
                urls = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        except FileNotFoundError:
            print(f"❌ Batch file not found: {args.batch}", file=sys.stderr)
            sys.exit(1)

        print(f"📋 Fetching {len(urls)} URLs from {args.batch}", file=sys.stderr)
        results = read_internal_websites(urls, timeout=args.timeout, debug=args.debug)

        # Summary to stderr
        success_count = sum(1 for r in results if is_success(r))
        print(f"✅ {success_count}/{len(results)} succeeded", file=sys.stderr)

        # Output results
        if args.format == "content-only":
            for result in results:
                if is_success(result):
                    content = get_content(result)
                    if result["content_type"] == "json":
                        print(json.dumps(content, indent=2))
                    else:
                        print(content)
                    print("---")  # Separator
        else:
            output_json = json.dumps(results, indent=2)
            if args.output:
                with open(args.output, 'w') as f:
                    f.write(output_json)
                print(f"📁 JSON saved to {args.output}", file=sys.stderr)
            else:
                print(output_json)

    else:
        # Single URL mode
        result = read_internal_website(args.url, timeout=args.timeout, debug=args.debug)

        if is_success(result):
            # Print status to stderr so stdout can be piped
            print(f"✅ Successfully fetched from {args.url}", file=sys.stderr)
            print(f"📊 Content type: {result['content_type']}, Length: {result['content_length']} chars", file=sys.stderr)

            if has_warnings(result):
                print(f"⚠️  Warnings: {', '.join(result['warnings'])}", file=sys.stderr)

            # Output handling
            if args.format == "content-only":
                # Output just the content for piping to other tools
                content = get_content(result)
                if result["content_type"] == "json":
                    # For JSON content, output as formatted JSON string
                    print(json.dumps(content, indent=2))
                else:
                    # For other content types, output as-is
                    print(content)
            elif args.format == "text":
                # Text summary format
                print(f"URL: {result['url']}")
                print(f"Status: {'Success' if is_success(result) else 'Failed'}")
                print(f"Content Type: {result['content_type']}")
                print(f"Content Length: {result['content_length']} chars")
                print(f"Fetch Duration: {result['metadata'].get('fetch_duration_ms', 'N/A')} ms")
                if has_warnings(result):
                    print(f"Warnings: {', '.join(result['warnings'])}")
            else:
                # Full JSON structure (default)
                output_json = json.dumps(result, indent=2)

                if args.output:
                    with open(args.output, 'w') as f:
                        f.write(output_json)
                    print(f"📁 JSON saved to {args.output}", file=sys.stderr)
                else:
                    print(output_json)
        else:
            print(f"❌ Error: {result.get('error', 'Unknown error')}", file=sys.stderr)
            if "error_code" in result:
                print(f"Error Code: {result['error_code']}", file=sys.stderr)
            if "error_details" in result:
                print(f"Details: {result['error_details']}", file=sys.stderr)

            # Still output the JSON for debugging unless content-only
            if args.format != "content-only":
                print(json.dumps(result, indent=2))

            sys.exit(1)


if __name__ == "__main__":
    main()