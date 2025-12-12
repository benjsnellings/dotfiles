# Spec Studio MCP Integration - Comprehensive Guide

This is the detailed reference for Spec Studio MCP tools. For a quick overview, see `@steering/spec-studio-steering.md`.

---

## Table of Contents

1. [What is Spec Studio?](#what-is-spec-studio)
2. [Tool Reference](#tool-reference)
3. [Package Structure](#package-structure)
4. [Collections Feature](#collections-feature)
5. [Workflow Examples](#workflow-examples)
6. [Troubleshooting](#troubleshooting)

---

## What is Spec Studio?

Spec Studio is Amazon's AI-powered code intelligence system developed by the StoreGen team. It analyzes Amazon code packages to automatically generate comprehensive specifications that capture:

- **Business logic** - How the code implements business requirements
- **Architectural decisions** - Design patterns and structural choices
- **System dependencies** - Internal and external service integrations
- **API contracts** - Interface definitions and data flows

### Mission
Preserve and share critical engineering knowledge across Amazon's distributed systems, enabling:
- Faster onboarding for new team members
- Better cross-team coordination
- Improved system understanding
- Maintained engineering velocity during team transitions

### Key URLs
| Resource | URL |
|----------|-----|
| Spec Studio UI | https://specs.harmony.a2z.com/ |
| About Page | https://specs.harmony.a2z.com/resources/about |
| MCP Integration | https://specs.harmony.a2z.com/resources/mcp-server |
| Product Roadmap | https://specs.harmony.a2z.com/resources/roadmap |

---

## Tool Reference

### 1. spec_studio_semantic_search

**Purpose**: Search the Spec Studio knowledge base using natural language queries.

**Parameters**:
```typescript
{
  queryText: string  // Required - The search query text
}
```

**Returns**: Ranked results with content excerpts, relevance scores, and source locations (packageId, packageName, branch, revisionId, featureName).

**Example**:
```json
{
  "queryText": "How does authentication work in the OrderService?"
}
```

**Output includes**:
- `rank` - Result ranking
- `score` - Relevance score
- `title` - Document title
- `author` - Document author
- `content` - Matched content excerpt
- `location.packageName` - Source package
- `location.branch` - Source branch
- `location.featureName` - Source file
- `location.revisionId` - Revision ID

**Best for**: Finding relevant documentation when you don't know which package contains the information.

---

### 2. get-all-packages

**Purpose**: Retrieve and browse specification packages with pagination, search, and sorting.

**Parameters**:
```typescript
{
  search?: string                           // Filter by name (case-insensitive)
  nextToken?: string                        // Pagination token from previous response
  pageSize?: number                         // Items per page (1-200, default: 100)
  sortAttribute?: 'updatedAt' | 'name'      // Sort field
  sortOrder?: 'asc' | 'desc'                // Sort direction (default: desc)
}
```

**Returns**: List of packages with ID, name, description, creator, branch, creation date, and target package count.

**Example - Search for packages**:
```json
{
  "search": "OrderService",
  "pageSize": 20
}
```

**Example - Browse all packages**:
```json
{
  "pageSize": 50,
  "sortAttribute": "updatedAt",
  "sortOrder": "desc"
}
```

**Best for**: Package discovery, finding packages by name pattern.

---

### 3. get-package-metadata

**Purpose**: Retrieve comprehensive package metadata including latest valid revision.

**Parameters**:
```typescript
{
  packageName: string  // Required - Package name to search for
}
```

**Returns**:
- Package ID
- Package name
- Branch
- Revision ID (latest valid)
- Status
- Available files list

**Example**:
```json
{
  "packageName": "MyServicePackage"
}
```

**Best for**: Getting revision ID and available files before retrieving content. Essential first step.

---

### 4. get-package-by-name

**Purpose**: Quick package lookup for basic information.

**Parameters**:
```typescript
{
  packageName: string  // Required - Package name to retrieve
}
```

**Returns**: Core package details (ID, name, branch, creator, description, timestamps).

**Example**:
```json
{
  "packageName": "MyServicePackage"
}
```

**Best for**: Quick lookups when you only need basic info, not file lists or revision details.

**Note**: Provides intelligent suggestions if exact match not found.

---

### 5. get-package-feature

**Purpose**: Retrieve feature content and documentation from specification packages.

**Parameters**:
```typescript
{
  packageName: string       // Required - Package name
  packageId?: string        // Optional - Skip name-to-ID lookup if known
  revisionId?: string       // Optional - Specific revision (default: latest valid)
  artifactPath?: string     // Path to file (e.g., "docs/system-overview.md")
}
```

**Example**:
```json
{
  "packageName": "MyServicePackage",
  "artifactPath": "docs/api-reference.md"
}
```

**Best for**: Retrieving actual specification content after discovering files via `get-package-metadata`.

---

### 6. get-specification-doc

**Purpose**: Retrieve the main specification document directly (convenience wrapper).

**Parameters**:
```typescript
{
  packageName: string    // Required - Package name
  packageId?: string     // Optional - Skip name-to-ID lookup
  revisionId?: string    // Optional - Specific revision
}
```

**Returns**: Main specification.md content with package metadata header.

**Example**:
```json
{
  "packageName": "MyServicePackage"
}
```

**Best for**: Quick access to the main specification without needing to know the file structure.

---

### 7. find-spec-revisions

**Purpose**: List all historical revisions for a package with filtering and sorting.

**Parameters**:
```typescript
{
  packageName: string                    // Required - Package name
  pageNumber?: number                    // Page number (default: 1)
  pageSize?: number                      // Items per page (1-100, default: 50)
  sortOrder?: 'asc' | 'desc'             // Sort direction (default: desc - newest first)
}
```

**Returns** per revision:
- Revision ID
- Spec Package ID
- Status
- Creator
- Branch
- Created date
- File count
- Git commit ID

**Example**:
```json
{
  "packageName": "MyServicePackage",
  "sortOrder": "desc"
}
```

**Best for**: Tracking package evolution, accessing historical versions, audit purposes.

---

### 8. get-revision-metadata

**Purpose**: Get detailed metadata for a specific revision.

**Parameters**:
```typescript
{
  packageName: string   // Required - Package name
  revisionId: string    // Required - Specific revision ID
}
```

**Returns**:
- Full revision details
- Status
- Branch
- Creator
- Created date
- Git commit ID
- Documentation paths
- Analyzer results
- Code graph path

**Example**:
```json
{
  "packageName": "MyServicePackage",
  "revisionId": "abc123-def456"
}
```

**Best for**: Deep inspection of a specific revision, accessing analyzer metadata.

---

### 9. search-collections

**Purpose**: Search for collections (multi-package documentation groups).

**Parameters**:
```typescript
{
  searchString?: string                  // Filter by name (case-insensitive)
  searchMode?: 'prefix' | 'includes'     // Search mode
  creator?: string                       // Filter by creator
  sortBy?: 'updatedAt' | 'name'          // Sort field
  sortOrder?: 'asc' | 'desc'             // Sort direction
  pageSize?: number                      // Items per page
  nextToken?: string                     // Pagination token
}
```

**Returns**: List of collections with ID, name, description, creator, timestamps.

**Example**:
```json
{
  "searchString": "OrderSystem",
  "searchMode": "includes"
}
```

**Best for**: Finding documentation that spans multiple packages.

---

### 10. get-collection-metadata

**Purpose**: Retrieve collection details and linked elements.

**Parameters**:
```typescript
{
  collectionId: string  // Required - Collection ID
}
```

**Returns**:
- Collection ID
- Name
- Description
- Creator
- Collection type
- Created/updated timestamps
- Linked elements (packages and sub-collections)

**Example**:
```json
{
  "collectionId": "abc123-collection-id"
}
```

**Best for**: Understanding what packages are grouped together in a collection.

---

## Package Structure

Spec Studio packages use a hierarchical structure with a `docs/` folder:

- **Access method**: `artifactPath` parameter
- **Default file**: `docs/specification.md`
- **Common files**: `docs/system-overview.md`, `docs/api-reference.md`, etc.
- **Additional data**: Analyzer metadata, code graph data

### Discovering Available Files
1. Call `get-package-metadata` with the package name
2. Check the available files list in the response
3. Use `get-package-feature` with the `artifactPath` for the file you want

---

## Collections Feature

Collections allow grouping multiple packages into a single documentation set, useful for understanding entire systems.

### When to Use Collections
- Understanding microservice architectures
- Documenting system boundaries
- Cross-team coordination

### Collection Workflow
```
1. search-collections(searchString: "MySystem")
   → Find relevant collections

2. get-collection-metadata(collectionId: "...")
   → See linked packages

3. For each package:
   get-package-metadata → get-specification-doc
```

---

## Workflow Examples

### Example 1: New Team Member Onboarding

**Scenario**: You joined a team and need to understand the OrderService package.

```
Step 1: Get package overview
→ get-package-metadata(packageName: "OrderService")
   Returns: Package with 12 files including docs/system-overview.md

Step 2: Read main specification
→ get-specification-doc(packageName: "OrderService")
   Returns: High-level architecture and business logic

Step 3: Dive into specific areas
→ get-package-feature(packageName: "OrderService", artifactPath: "docs/api-reference.md")
   Returns: Detailed API documentation

Step 4: Explore related functionality
→ spec_studio_semantic_search(queryText: "How does OrderService handle payment validation?")
   Returns: Relevant sections across all available specs
```

### Example 2: Integration Planning

**Scenario**: You need to integrate with an unfamiliar service.

```
Step 1: Search for the service
→ get-all-packages(search: "PaymentGateway")
   Returns: List of matching packages

Step 2: Get metadata for the right one
→ get-package-metadata(packageName: "PaymentGatewayService")
   Returns: Available documentation files

Step 3: Read integration-relevant docs
→ get-package-feature(packageName: "PaymentGatewayService", artifactPath: "docs/api-reference.md")
   Returns: API contracts and integration points
```

### Example 3: Debugging Historical Issue

**Scenario**: A bug was introduced sometime last month, need to compare versions.

```
Step 1: Find revisions
→ find-spec-revisions(packageName: "MyService", sortOrder: "desc")
   Returns: List of all revisions with dates

Step 2: Compare specific revision
→ get-revision-metadata(packageName: "MyService", revisionId: "rev-from-last-month")
   Returns: Details about that revision

Step 3: Read historical spec
→ get-package-feature(packageName: "MyService", revisionId: "rev-from-last-month", artifactPath: "docs/specification.md")
   Returns: Spec content from that point in time
```

---

## Troubleshooting

### "Package not found"
- Verify the exact Brazil package name
- Check if spec has been generated at https://specs.harmony.a2z.com/
- Try `get-all-packages` with a search term to find similar names

### "No results" from semantic search
- Try broader query terms
- Check if the packages you expect are in Spec Studio
- Some packages may not have been indexed yet

### "Unable to retrieve content"
- Check if the revision has SUCCESS or PARTIAL_SUCCESS status
- Verify the file path is correct using `get-package-metadata`
- Use `get-package-metadata` first to see available files

### Package returning empty files
- Check `get-package-metadata` output for actual file paths
- Paths typically start with `docs/`
- Ensure you're using `artifactPath` parameter

### Collections not returning expected packages
- Collections must be manually created in the UI
- Not all packages are part of collections
- Search by creator if you know who created the collection
