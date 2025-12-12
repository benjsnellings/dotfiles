# Spec Studio MCP Integration

## What is Spec Studio?

Spec Studio is Amazon's AI-powered code intelligence system that automatically generates comprehensive specifications from source code. It extracts and formalizes implicit knowledge about business logic, architectural decisions, and system dependencies.

**Website**: https://specs.harmony.a2z.com/

## When to Use Spec Studio

Use Spec Studio MCP tools when you need to:
- **Understand unfamiliar packages** - Accelerate onboarding to new codebases
- **Technical scoping** - Research components and dependencies for planning
- **Integration planning** - Discover API contracts and integration points
- **Legacy code analysis** - Generate documentation for undocumented code
- **Bootstrap AI docs** - Pull context for Pippin designs and other AI-generated artifacts

## Quick Reference: All 10 MCP Tools

| Tool | Purpose | Key Parameter(s) |
|------|---------|------------------|
| `spec_studio_semantic_search` | Natural language search across all specs | `queryText` |
| `get-all-packages` | Browse/discover packages | `search?`, `pageSize?` |
| `get-package-metadata` | Package info + available files | `packageName` |
| `get-package-by-name` | Quick package lookup (basic info) | `packageName` |
| `get-package-feature` | Retrieve actual spec content | `packageName`, `artifactPath?` |
| `get-specification-doc` | Get main specification directly | `packageName` |
| `find-spec-revisions` | Browse revision history | `packageName`, `pageNumber?`, `sortOrder?` |
| `get-revision-metadata` | Detailed revision info | `packageName`, `revisionId` |
| `search-collections` | Find multi-package collections | `searchString?` |
| `get-collection-metadata` | Collection details | `collectionId` |

## Tool Selection Guide

**Start here based on your goal:**

```
Need to understand a specific package?
├── Know the package name → get-package-metadata → get-specification-doc
└── Don't know → get-all-packages (with search) → then above

Need to find something across all specs?
└── spec_studio_semantic_search (natural language query)

Need historical versions?
└── find-spec-revisions → get-revision-metadata → get-package-feature with revisionId

Need multi-package system context?
└── search-collections → get-collection-metadata
```

## Common Workflow Patterns

### Pattern 1: Understanding an Unfamiliar Package
```
1. get-package-metadata(packageName: "MyPackage")
   → Returns: package ID, branch, available files, revision info

2. get-specification-doc(packageName: "MyPackage")
   → Returns: main specification.md content

3. get-package-feature(packageName: "MyPackage", artifactPath: "docs/specific-feature.md")
   → Returns: specific feature documentation
```

### Pattern 2: Searching for Implementation Patterns
```
1. spec_studio_semantic_search(queryText: "How does authentication work in X?")
   → Returns: relevant content snippets with package/file locations

2. get-package-feature(packageName: <from results>, ...)
   → Returns: full context for the matched content
```

### Pattern 3: Comparing Package Versions
```
1. find-spec-revisions(packageName: "MyPackage")
   → Returns: list of all revisions with dates and statuses

2. get-revision-metadata(packageName: "MyPackage", revisionId: "rev-123")
   → Returns: detailed info about specific revision

3. get-package-feature(packageName: "MyPackage", revisionId: "rev-123", ...)
   → Returns: content from that specific revision
```

## Package Structure

Spec Studio packages use a hierarchical structure with a `docs/` folder:
- **File access**: Use `artifactPath` parameter (e.g., `"docs/system-overview.md"`)
- **Default spec**: `docs/specification.md`
- **Common files**: `docs/system-overview.md`, `docs/api-reference.md`, etc.
- **Additional data**: Analyzer metadata, code graph data

**Tip**: Use `get-package-metadata` first to see available files in the package.

## Important Limitations

1. **Read-only**: Cannot generate new specs via MCP - use the UI at https://specs.harmony.a2z.com/
2. **Pre-generated only**: Packages must already have specs generated in Spec Studio
3. **Status matters**: Only packages with SUCCESS or PARTIAL_SUCCESS status work
4. **Package name required**: Most tools need the exact Brazil package name

## Key URLs

- **Spec Studio UI**: https://specs.harmony.a2z.com/
- **MCP Integration Docs**: https://specs.harmony.a2z.com/resources/mcp-server
- **About Spec Studio**: https://specs.harmony.a2z.com/resources/about
- **Roadmap**: https://specs.harmony.a2z.com/resources/roadmap

## Detailed Documentation

For complete parameter schemas, example outputs, and advanced workflows, see:
`@steering/spec-studio-comprehensive.md`
