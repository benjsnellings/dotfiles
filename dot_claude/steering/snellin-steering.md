



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
