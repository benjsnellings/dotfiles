#!/usr/bin/env python3

"""
cr_parser.py

Code Review specific utilities for parsing code.amazon.com data.
This module contains specialized parsers for Code Review (CR) data structures.

Usage:
    from cr_parser import parse_cr_table

    # Parse markdown table from code.amazon.com/reviews/*
    data = read_internal_website("https://code.amazon.com/reviews/to-user/username")
    if data["success"] and data["content_type"] == "markdown":
        crs = parse_cr_table(data["content"])
"""


def parse_cr_table(content: str) -> list:
    """
    Parse a markdown table of code reviews into structured data.

    This is a specialized parser for code.amazon.com CR tables.
    Use this ONLY when you know the content is from code.amazon.com/reviews/*.

    Args:
        content (str): Markdown table content from code.amazon.com

    Returns:
        list: List of CR dictionaries with fields like ID, Author, Summary, etc.

    Example:
        >>> from read_internal_website import read_internal_website
        >>> from cr_parser import parse_cr_table
        >>>
        >>> data = read_internal_website("https://code.amazon.com/reviews/to-user/username")
        >>> if data["success"] and data["content_type"] == "markdown":
        >>>     crs = parse_cr_table(data["content"])
        >>>     for cr in crs:
        >>>         print(f"{cr['ID']}: {cr.get('Summary', 'N/A')}")
    """

    if not content or "|" not in content:
        return []

    lines = content.strip().split('\n')
    headers = []
    rows = []

    for line in lines:
        if line.startswith('|---'):
            continue
        if line.startswith('|'):
            parts = [p.strip() for p in line.split('|')]
            parts = parts[1:-1] if parts else []  # Remove empty first and last elements

            if not headers:
                headers = parts
            elif parts and len(parts) >= len(headers):
                row_dict = {}
                for i, header in enumerate(headers):
                    if i < len(parts):
                        row_dict[header] = parts[i]
                # Add URL if we have an ID
                if 'ID' in row_dict:
                    row_dict['URL'] = f"https://code.amazon.com/reviews/{row_dict['ID']}"
                rows.append(row_dict)

    return rows


def count_pending_approvals(crs: list, username: str) -> int:
    """
    Count how many CRs are pending approval from a specific user.

    Args:
        crs (list): List of parsed CRs from parse_cr_table()
        username (str): Username to check for pending approvals

    Returns:
        int: Number of CRs pending approval from this user

    Example:
        >>> crs = parse_cr_table(markdown_content)
        >>> pending = count_pending_approvals(crs, "myusername")
        >>> print(f"You have {pending} CRs to review")
    """
    pending = [cr for cr in crs if f"__ {username}" in cr.get("Approved by", "")]
    return len(pending)
