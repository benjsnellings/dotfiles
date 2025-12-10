# Obsidian Vault Agent Guidelines

This document provides comprehensive guidance for agents working with the Obsidian notebook located at `/Volumes/workplace/Obsidian/Amazon`. Following these guidelines ensures consistency, prevents data loss, and maintains the integrity of the knowledge management system.

## Table of Contents

1. [Obsidian Core Concepts](#obsidian-core-concepts)
2. [Vault Structure](#vault-structure)
3. [Metadata Conventions](#metadata-conventions)
4. [File Naming Conventions](#file-naming-conventions)
5. [Organization Patterns](#organization-patterns)
6. [Plugin-Specific Guidelines](#plugin-specific-guidelines)
7. [Agent Modification Rules](#agent-modification-rules)
8. [Linking Strategy](#linking-strategy)
9. [Maintenance Guidelines](#maintenance-guidelines)
10. [Amazon-Specific Context](#amazon-specific-context)

---

## Obsidian Core Concepts

### What is Obsidian?

Obsidian is a local-first, markdown-based knowledge management system that stores all notes as plain text `.md` files. The key differentiator is its powerful linking system and graph-based relationship visualization.

### Key Concepts

**Vault**
- A vault is a folder on the local filesystem containing markdown files and a `.obsidian` configuration directory
- Each vault is independent with its own settings, plugins, and themes
- All data remains local unless explicitly synced via plugins

**Wikilinks**
- Syntax: `[[Note Name]]` creates bidirectional links between notes
- Aliases: `[[Note Name|display text]]` shows custom text while maintaining the link
- Backlinks: Automatically tracked; every linked note knows what links to it
- Graph View: Visualizes relationships between notes as an interactive network

**Frontmatter**
- YAML metadata block at the top of each note enclosed in `---` delimiters
- Contains structured data: dates, IDs, types, tags, custom fields
- Used by plugins for querying, filtering, and automation

**Tags**
- Syntax: `#tag-name` or nested `#category/subcategory`
- Hierarchical and searchable
- Used for categorization and filtering in queries

**Templates**
- Reusable note structures with variables
- Support date insertion, cursor positioning, user prompts
- Enhanced with Templater plugin for advanced logic

---

## Vault Structure

### Current Directory Organization

```
/Volumes/workplace/Obsidian/Amazon/
├── .obsidian/              # Configuration (DO NOT MODIFY)
├── Daily/                  # Daily notes with temporal structure
│   └── YYYY/
│       └── MM-MonthName/
│           └── YYYY-MM-DD-DayName.md
├── Projects/               # Active and archived projects
│   ├── Archive/
│   ├── Dimensional Pipelines/
│   ├── Rust/
│   └── Auth by Default/
├── Golden Path/            # Golden path guidance materials
│   ├── Web Services/
│   ├── Apollo Containers/
│   ├── Unit Test/
│   └── Random Docs/
├── Interviews/             # Interview tracking and feedback
│   ├── BRIT/
│   ├── Feedback/
│   └── Questions/
├── 1_1s/                   # One-on-one meeting notes by person
│   ├── Craig/
│   ├── Greg/
│   ├── Ian/
│   └── Sam/
├── Tempates/               # Note templates (typo in original)
├── ToBeSorted/             # Capture area for new/unsorted notes
├── QUIP/                   # Amazon Quip document integration
├── Codes and More/         # Code snippets and references
├── DevCon/                 # Developer conference materials
└── 三 Archive 三/          # Archived content
```

### Folder Purposes

- **Daily/**: Timestamped daily notes for journaling, todos, and daily captures
- **Projects/**: Project-specific notes with meeting notes, plans, and status
- **Golden Path/**: Amazon Golden Path program documentation and reviews
- **Interviews/**: Interview questions, feedback, and candidate tracking
- **1_1s/**: Regular one-on-one meeting notes organized by person
- **Tempates/**: Reusable note templates (note: typo from "Templates")
- **ToBeSorted/**: Default location for new notes; triage regularly
- **QUIP/**: Imported or linked Amazon Quip documents
- **三 Archive 三/**: Long-term storage for completed/inactive content

### Storage Patterns

**Temporal Structure** (Daily Notes)
- Year → Month → Day hierarchy
- Format: `Daily/2025/11-November/2025-11-11-Monday.md`
- Automatic creation via daily notes plugin

**Categorical Structure** (Projects, Golden Path)
- Category → Subcategory → Note
- Format: `Projects/ProjectName/(MM.DD.YY) Description.md`

**Hybrid Approach**
- Combines temporal and categorical organization
- New notes start in ToBeSorted
- Organized during regular triage sessions

---

## Metadata Conventions

### Required Frontmatter Fields

Every note (except daily notes) should include:

```yaml
---
id: unique-identifier
created_date: YYYY-MM-DD
updated_date: YYYY-MM-DD
type: note|project|reference|meeting|daily
---
```

### Recommended Additional Fields

```yaml
---
status: draft|active|completed|archived
tags: [tag1, tag2]
related: [[Related Note 1]], [[Related Note 2]]
---
```

### Optional Amazon-Specific Fields

```yaml
---
quip: https://quip-amazon.com/DOCID
sim: https://issues.amazon.com/issues/ISSUE-ID
---
```

### Daily Note Frontmatter

Daily notes use a simplified structure:

```yaml
---
created: YYYY-MM-DD HH:MM
---
tags:: [[+Daily Notes]]
```

### Field Definitions

- **id**: Unique identifier (often filename or generated ID)
- **created_date**: Date note was first created (ISO 8601: YYYY-MM-DD)
- **updated_date**: Date note was last modified (ISO 8601: YYYY-MM-DD)
- **type**: Category of note (note, project, reference, meeting, daily)
- **status**: Lifecycle stage (draft, active, completed, archived)
- **tags**: Array or list of categorization tags
- **related**: Wikilinks to related notes for explicit relationships
- **quip**: Link to associated Amazon Quip document
- **sim**: Link to Amazon SIM issue or ticket

### YAML Syntax Rules

- Delimiters: Must use `---` at start and end
- Dates: ISO 8601 format (YYYY-MM-DD) without quotes
- Strings: Can be quoted or unquoted; use quotes if special characters present
- Arrays: `[item1, item2]` or YAML list format with `-` prefix
- Wikilinks: Can be embedded in values for `related` field

---

## File Naming Conventions

### General Rules

1. **Descriptive Names**: Use clear, search-friendly names (50-80 characters max)
2. **Consistent Casing**: Use Title Case or lowercase-with-hyphens
3. **Avoid Special Characters**: Use spaces, hyphens, or underscores; avoid `/ \ : * ? " < > |`
4. **Date Prefixes**: For timestamped notes only (meetings, events)
5. **No Version Numbers**: Use frontmatter updated_date instead

### Specific Patterns

**Daily Notes** (Auto-Generated)
```
YYYY-MM-DD-DayName.md
Example: 2025-11-11-Monday.md
```

**Meeting Notes**
```
(MM.DD.YY) Description.md
Example: (11.11.24) Craig 1-1.md
```

**Project Notes** (No Date Prefix)
```
Descriptive Title.md
Example: Auth by Default Roadmap.md
```

**Reference Notes**
```
Topic - Subtopic.md
Example: Apollo - Container Deployment.md
```

### Date Prefix Formats

The vault uses two formats; prefer the first for consistency:
- **Preferred**: `(MM.DD.YY)` - Parentheses, two-digit year
- **Alternate**: `[MM.DD.YY]` - Brackets, two-digit year

**Rationale**: Parentheses visually distinguish dates from content while maintaining sortability.

---

## Organization Patterns

### Daily Notes Workflow

**Location**: `Daily/YYYY/MM-MonthName/YYYY-MM-DD-DayName.md`

**Template Structure**:
```markdown
---
created: YYYY-MM-DD HH:MM
---
tags:: [[+Daily Notes]]

## ToDo
- [ ] Task item

## Notes
- Note item

## Notes created today
```dataview
List FROM "" WHERE file.cday = date("YYYY-MM-DD") SORT file.ctime ASC
```

## Notes last modified today
```dataview
List FROM "" WHERE file.mday = date("YYYY-MM-DD") SORT file.mtime ASC
```
```

**Usage**:
- Created automatically by Daily Notes plugin
- Captures todos, journal entries, and ephemeral notes
- Dataview queries surface notes created/modified today
- Links to previous/next days for navigation

### Project Notes Workflow

**Location**: `Projects/[ProjectName]/`

**Structure**:
```markdown
---
id: project-name
created_date: YYYY-MM-DD
updated_date: YYYY-MM-DD
type: project
status: active
---

# Project Name

## Overview
Brief description

## Goals
- Goal 1
- Goal 2

## Status
Current state and blockers

## Meeting Notes
- [[(MM.DD.YY) Meeting Topic]]

## Action Items
- [ ] Action item with owner

## Related
- [[Related Note 1]]
- [[Related Note 2]]
```

**Archival**: When completed, move to `Projects/Archive/[ProjectName]/`

### Meeting Notes Workflow

**Filename**: `(MM.DD.YY) [Person or Topic].md`

**Location**:
- `1_1s/[PersonName]/` for one-on-ones
- `Projects/[ProjectName]/` for project meetings
- `ToBeSorted/` initially if unclear

**Structure**:
```markdown
---
id: meeting-description-date
created_date: YYYY-MM-DD
updated_date: YYYY-MM-DD
type: meeting
---

# (MM.DD.YY) Meeting Title

## Attendees
- Person 1
- Person 2

## Notes
- Discussion point 1
- Discussion point 2

## Action Items
- [ ] Action item (@owner)

## Links
- [[Related Project]]
- [SIM Issue](https://issues.amazon.com/issues/ISSUE-123)
```

### ToBeSorted Queue Management

**Purpose**:
- Capture area for new notes before organization
- Reduces friction in note creation
- Prevents analysis paralysis about where notes belong

**Rules**:
- Default location for new notes (configured in settings)
- Review and organize weekly
- Keep queue under 20 notes
- Move notes to appropriate folders during triage

**Triage Workflow**:
1. Review note content and type
2. Assign appropriate folder based on category
3. Verify metadata is complete
4. Add relevant tags and links
5. Move to destination folder

---

## Plugin-Specific Guidelines

### Dataview (Query Engine)

**Purpose**: Database-like queries over note metadata and content

**Common Query Pattern** (in Daily Notes):
```dataview
List FROM "" WHERE file.cday = date("2025-11-11") SORT file.ctime ASC
```

**Query Components**:
- `List/Table/Task`: Output format
- `FROM ""`: Source (empty string = entire vault)
- `WHERE`: Filter condition
- `file.cday`: File creation date
- `file.mday`: File modification date
- `SORT`: Ordering

**Agent Rules**:
- **DON'T** modify existing Dataview query blocks
- **DO** preserve Dataview syntax if copying templates
- **DON'T** break queries by removing required frontmatter fields

### Tasks Plugin (Task Management)

**Purpose**: Track action items across vault with due dates and priorities

**Syntax**:
```markdown
- [ ] Task description
- [ ] Task with due date 📅 YYYY-MM-DD
- [ ] High priority task 🔼
- [ ] Low priority task 🔽
- [x] Completed task ✅ YYYY-MM-DD
```

**Features**:
- Automatic aggregation of tasks across notes
- Due date tracking and overdue detection
- Priority levels with emoji indicators
- Recurring tasks support

**Agent Rules**:
- **DO** use consistent task format with checkboxes
- **DO** add due dates to time-sensitive tasks
- **DON'T** use non-standard checkbox formats
- **DO** mark tasks complete with `[x]` when done

### Templater (Advanced Templates)

**Purpose**: Create dynamic templates with JavaScript logic, prompts, and variables

**Location**: `Tempates/` folder (note typo from original)

**Common Variables**:
```javascript
<% tp.date.now("YYYY-MM-DD") %>         // Current date
<% tp.date.now("YYYY-MM-DD HH:mm") %>   // Current datetime
<% tp.file.title %>                      // File title
<% tp.file.cursor() %>                   // Cursor position after template insertion
<% await tp.system.prompt("Field:") %>  // User input prompt
```

**Agent Rules**:
- **DON'T** modify templates in `Tempates/` folder without explicit instruction
- **DO** use templates when creating new notes of specific types
- **DO** respect cursor positioning in templates
- **DON'T** break Templater syntax (e.g., `<% %>` delimiters)

### Auto Note Mover (Automatic Organization)

**Purpose**: Automatically move notes to folders based on tags or rules

**Current Rules**:
- Notes with `#archive` tag → Move to `三 Archive 三/`
- Notes with `#interview` tag → Move to `Interviews/Feedback/`
- Triggers on note creation or tag addition

**Agent Rules**:
- **DO** use `#archive` tag to mark notes for archival
- **DON'T** manually move notes that have Auto Note Mover triggers
- **DO** allow automatic processing to complete
- **DON'T** create conflicting folder structures

### QuickAdd (Quick Capture & Macros)

**Purpose**: Rapid note creation and automated workflows via macros

**Features**:
- Quick capture to ToBeSorted
- Archive macro for moving notes
- User scripts for automation
- AI integration capability

**Agent Rules**:
- **DON'T** modify QuickAdd configurations
- **DO** use standard note creation instead of triggering macros
- **DON'T** interfere with user scripts

---

## Agent Modification Rules

### ✅ DO (Strongly Encouraged)

1. **DO** update `updated_date` in frontmatter whenever modifying a note
2. **DO** preserve existing note structure and section headers
3. **DO** use wikilinks for internal cross-references: `[[Note Name]]`
4. **DO** place new notes in `ToBeSorted/` initially unless folder is obvious
5. **DO** maintain consistent markdown formatting (proper heading hierarchy: H1 → H2 → H3)
6. **DO** respect existing metadata fields and their structure
7. **DO** add context-relevant tags to notes
8. **DO** use descriptive wikilink aliases: `[[Note Name|readable text]]` for better context
9. **DO** keep action items in consistent format: `- [ ] Action description`
10. **DO** verify that wikilinks point to existing notes or note the link as intentionally forward-referencing
11. **DO** maintain ISO 8601 date format (YYYY-MM-DD) in all metadata
12. **DO** read existing notes in a folder to understand conventions before creating similar notes
13. **DO** preserve Dataview queries and Tasks plugin syntax
14. **DO** respect folder purposes (e.g., Daily/ for daily notes only)
15. **DO** maintain consistent line length and readable formatting

### ❌ DON'T (Explicitly Prohibited)

1. **DON'T** modify or delete the `.obsidian/` directory or any of its contents
2. **DON'T** change plugin configurations without explicit user instruction
3. **DON'T** move, rename, or modify historical notes (past dates in Daily/)
4. **DON'T** create new top-level folders without user discussion
5. **DON'T** change frontmatter field names (only modify values)
6. **DON'T** remove existing wikilinks or backlinks without review
7. **DON'T** create notes with contradictory metadata (e.g., type mismatch)
8. **DON'T** modify Templater templates in `Tempates/` folder without instruction
9. **DON'T** delete or modify Dataview query blocks
10. **DON'T** create deeply nested folder structures (max 3-4 levels)
11. **DON'T** create notes in the vault root (use ToBeSorted instead)
12. **DON'T** use inconsistent date formats (always YYYY-MM-DD)
13. **DON'T** break YAML frontmatter syntax (unclosed delimiters, invalid structure)
14. **DON'T** create circular link dependencies unintentionally
15. **DON'T** delete notes; archive them instead using `#archive` tag

### Specific Modification Scenarios

#### When Adding Content to Existing Note

**DO**:
- Update `updated_date` to current date
- Maintain existing section structure
- Add new sections logically (at appropriate hierarchy level)
- Preserve existing wikilinks and references

**DON'T**:
- Remove or replace existing content without confirmation
- Change the note's primary purpose or type
- Break existing section structure
- Remove frontmatter fields

#### When Creating New Note

**DO**:
- Include complete frontmatter with all required fields
- Use appropriate template if available
- Place in ToBeSorted unless destination is clear
- Use consistent date prefix if timestamped note
- Verify similar notes for naming conventions

**DON'T**:
- Create in vault root directory
- Omit required frontmatter fields
- Use inconsistent naming compared to similar notes
- Create duplicate notes (search first)

#### When Linking Between Notes

**DO**:
- Use wikilinks for internal notes: `[[Note Name]]`
- Use standard markdown links for external URLs: `[text](url)`
- Use aliases for better readability: `[[Note|readable text]]`
- Verify note exists before creating link (or note it's forward-referencing)

**DON'T**:
- Mix wikilink and markdown link styles for internal notes
- Create broken links without noting them
- Use absolute file paths in links
- Remove backlink references

#### When Modifying Metadata

**DO**:
- Preserve existing frontmatter structure
- Only update field values, not field names
- Maintain YAML syntax correctness
- Update `updated_date` to current date

**DON'T**:
- Add non-standard fields without documentation
- Change field names (breaks queries and templates)
- Use invalid YAML syntax
- Remove required fields

#### When Archiving Content

**DO**:
- Add `#archive` tag if Auto Note Mover is configured
- Move to `Projects/Archive/` for project-specific content
- Move to `三 Archive 三/` for general archived content
- Maintain original structure in archive
- Update status to `archived` in frontmatter

**DON'T**:
- Permanently delete notes
- Archive notes without updating metadata
- Break wikilinks by moving archived notes
- Archive current/active content

---

## Linking Strategy

### Internal Links (Wikilinks)

**Basic Syntax**:
```markdown
[[Note Name]]
```

**With Alias**:
```markdown
[[Note Name|Display Text]]
```

**With Section**:
```markdown
[[Note Name#Section Heading]]
```

**Examples**:
```markdown
See [[Projects/Auth by Default/Roadmap]] for details.
As discussed [[1_1s/Craig/(11.05.24) Weekly Sync|last week]].
Review [[Golden Path/Web Services/Meeting Notes#Action Items]].
```

### External Links (Standard Markdown)

**Syntax**:
```markdown
[Link Text](https://url.com)
```

**Examples**:
```markdown
[SIM Issue P129406383](https://issues.amazon.com/issues/P129406383)
[Quip Doc](https://quip-amazon.com/ABC123)
[AWS Console](https://console.aws.amazon.com/)
```

### Temporal References

**Full Path for Date-Based Notes**:
```markdown
[[Daily/2025/11-November/2025-11-11-Monday]]
[[Daily/2025/11-November/2025-11-11-Monday|Yesterday]]
```

**Rationale**: Full path ensures link remains valid even if daily note structure changes.

### Link Organization Best Practices

1. **Strategic Linking**: Link when conceptual relationship exists, not everywhere
2. **Bidirectional Value**: Wikilinks create automatic backlinks; use intentionally
3. **Alias for Context**: Use aliases to make links readable in sentence flow
4. **Verify Targets**: Check that linked notes exist or note forward-reference intent
5. **Avoid Link Rot**: Use meaningful, stable note titles

---

## Maintenance Guidelines

### Weekly Maintenance

**ToBeSorted Queue Processing**:
1. Review all notes in ToBeSorted/
2. Read content and determine appropriate folder
3. Verify metadata is complete and accurate
4. Add relevant tags and cross-references
5. Move to destination folder
6. Target: Keep queue under 20 notes

**Task Review**:
1. Check overdue tasks in Tasks plugin
2. Update task statuses and due dates
3. Close completed tasks with `[x]`
4. Reschedule or remove stale tasks

### Monthly Maintenance

**Project Status Review**:
1. Review active projects in Projects/ folder
2. Update project status in notes
3. Archive completed projects to Projects/Archive/
4. Update `status` field in frontmatter

**Link Health Check**:
1. Identify broken wikilinks (shown in graph view)
2. Update or remove broken links
3. Verify important cross-references are maintained

### Quarterly Maintenance

**Folder Structure Review**:
1. Assess folder organization effectiveness
2. Identify consolidation opportunities (similar content in multiple places)
3. Consider creating new top-level folders if needed
4. Document any structural changes

**Archive Cleanup**:
1. Review archived content for continued relevance
2. Consider permanent deletion of obsolete content (rare)
3. Verify archive folder organization

### Annual Maintenance

**Historical Archive**:
1. Review previous year's daily notes
2. Archive to `Daily/[YEAR]/` or compress
3. Extract important content to permanent notes
4. Verify year-over-year continuity

**Metadata Audit**:
1. Check metadata consistency across vault
2. Update deprecated frontmatter fields
3. Standardize tags and naming conventions
4. Run Dataview queries to identify inconsistencies

---

## Amazon-Specific Context

### Integration with Amazon Tools

**Quip Plugin**:
- Imports or syncs Amazon Quip documents into vault
- Store in `QUIP/` folder
- Link using frontmatter: `quip: https://quip-amazon.com/DOCID`
- Bidirectional sync may be enabled

**SIM Issue Linking**:
- Reference tickets using full URLs: `https://issues.amazon.com/issues/ISSUE-ID`
- Add to frontmatter: `sim: https://issues.amazon.com/issues/ISSUE-ID`
- Embed in meeting notes and project notes for traceability

**Code Review References**:
- Link to code reviews: `https://code.amazon.com/reviews/CR-12345678`
- Track in project notes for context
- Document decisions made in CRs

### Amazon Workflow Alignment

**Projects Folder**:
- Aligns with Amazon project structure
- Includes runbooks, pipelines, service development
- Tracks OPs (Operational Priorities)

**Golden Path Folder**:
- Documents Amazon's Golden Path recommendations
- Review notes for GP compliance
- Meeting notes from GP working group
- Best practices and standards

**Interviews Folder**:
- Bar Raiser and interview feedback
- BRIT (Bar Raiser In Training) materials
- Interview questions bank
- Internal transfer tracking

**1:1s Folder**:
- Regular one-on-ones with manager and reports
- Action item tracking from sync meetings
- Career development discussions
- Performance feedback documentation

### Amazon Terminology

- **SIM**: Service Incident Management (ticketing system)
- **Quip**: Amazon's collaborative document platform
- **CR**: Code Review
- **OPs**: Operational Priorities
- **BRIT**: Bar Raiser In Training
- **Golden Path**: Amazon's recommended development practices
- **Runbook**: Operational procedures documentation

---

## Summary: Critical Rules for Agents

### Top 10 Agent Rules

1. **NEVER** modify the `.obsidian/` directory
2. **ALWAYS** update `updated_date` when modifying notes
3. **ALWAYS** use wikilinks `[[Note Name]]` for internal references
4. **ALWAYS** include complete frontmatter in new notes
5. **NEVER** move or modify historical daily notes (past dates)
6. **ALWAYS** place new notes in ToBeSorted initially
7. **NEVER** remove existing wikilinks without confirmation
8. **ALWAYS** maintain consistent heading hierarchy
9. **NEVER** create notes in vault root directory
10. **ALWAYS** preserve Dataview queries and Tasks syntax

### When in Doubt

- **Read similar existing notes** to understand conventions
- **Ask the user** before making structural changes
- **Preserve existing patterns** rather than inventing new ones
- **Default to ToBeSorted** if note destination is unclear
- **Maintain metadata consistency** above all else

---

## Troubleshooting Common Issues

### Broken Wikilinks

**Symptom**: Links show as unresolved in graph view or with different formatting

**Resolution**:
1. Verify target note exists
2. Check spelling and case sensitivity
3. Ensure note is in expected folder
4. Update link if note was renamed
5. Use `[[Full/Path/To/Note|Alias]]` if ambiguous

### Metadata Parsing Errors

**Symptom**: Frontmatter doesn't display correctly or breaks queries

**Resolution**:
1. Verify `---` delimiters are present and balanced
2. Check YAML syntax (colons, indentation, quotes)
3. Ensure date fields use ISO 8601 format
4. Validate array syntax for tags/lists
5. Remove special characters from field values

### Dataview Query Failures

**Symptom**: Query block shows error or returns no results

**Resolution**:
1. Verify required frontmatter fields exist
2. Check date format matches query (ISO 8601)
3. Ensure `WHERE` clause syntax is correct
4. Test with simpler query to isolate issue
5. Don't modify query syntax; fix note metadata instead

### Auto Note Mover Not Triggering

**Symptom**: Tagged notes don't move to expected folders

**Resolution**:
1. Verify correct tag syntax (e.g., `#archive` not `# archive`)
2. Check Auto Note Mover plugin is enabled
3. Ensure rule matches note properties
4. Allow time for automatic processing
5. Manually move if urgent; don't fight automation

---

## Version History

- **2025-11-11**: Initial creation based on comprehensive vault analysis
- Future updates will be documented here

---

## Additional Resources

- [Obsidian Official Help](https://help.obsidian.md/)
- [Dataview Plugin Documentation](https://blacksmithgu.github.io/obsidian-dataview/)
- [Tasks Plugin Documentation](https://publish.obsidian.md/tasks/)
- [Templater Plugin Documentation](https://silentvoid13.github.io/Templater/)

---

**Note**: This guidance file takes precedence when working with the Obsidian notebook at `/Volumes/workplace/Obsidian/Amazon`. When conflicts arise between this guidance and other steering files, prioritize these Obsidian-specific rules for vault operations.
