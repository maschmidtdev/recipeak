# Recipeak DSL and Internal Model Specification

Version: 1.0

---

# 1. Purpose

This document defines:

- The text DSL used to represent a single recipe chart
- The validation rules for importing the DSL
- The internal `RecipeDocument` model used by the application

The DSL is an interchange format. It is used for import, export, sharing, AI generation, and testing. It is not the application's editing model.

---

# 2. Conceptual Model

A recipe chart consists of:

- Optional metadata such as title and yield
- Zero or more preparation rows shown above the chart
- Zero or more chart columns identified by unique uppercase letters
- Zero or more column width directives

The chart grid uses a global row index:

- Rows are numbered starting at `1`
- Any column may define any row independently
- Missing cells are treated as empty cells
- The final grid height is determined by the highest referenced row number in any column

Each chart cell is either:

- A single-row cell, or
- A vertically merged cell spanning a continuous row range within one column

Version 1 supports vertical merges only.

---

# 3. DSL Structure

The DSL represents one recipe document as a sequence of sections.

Supported top-level sections:

- `TITLE:`
- `YIELD:`
- `PREP:`
- `WIDTHS:`
- Column sections such as `A:`, `B:`, `C:`

Section names are case-sensitive in version 1 and should be written exactly as shown above.

Column identifiers:

- Must be a single uppercase letter from `A` to `Z`
- Must be unique
- Are rendered in alphabetical order regardless of declaration order

---

# 4. DSL Syntax

## Metadata sections

`TITLE:` and `YIELD:` each contain free text.

Example:

```text
TITLE:
Banana Nut Bread

YIELD:
about 10 servings
```

## Preparation section

`PREP:` contains a list of preparation rows displayed above the chart grid.

Each preparation row uses list syntax:

```text
PREP:
- Butter and flour a loaf pan
- Preheat oven to 180°C
```

Preparation rows are ordered exactly as written.

## Width section

`WIDTHS:` contains one optional width directive per column.

Example:

```text
WIDTHS:
A: 250
B: fit
C: fit
```

Supported width values:

- Positive integer logical pixels, for example `250`
- `fit`

If a column has no width entry, width is unspecified and must be resolved by the layout engine.

## Column sections

Each column section contains row-addressed cell entries.

Single-row syntax:

```text
B:
1: mash
2: melt
```

Merged-range syntax:

```text
C:
1-2: mash until smooth
```

Rules:

- Single rows use `row: text`
- Merged ranges use `start-end: text`
- Ranges must be continuous
- Ranges must be written from lowest to highest
- Row numbers must be positive integers

---

# 5. Example

```text
TITLE:
Banana Nut Bread

YIELD:
about 10 servings

PREP:
- Butter and flour a loaf pan
- Preheat oven to 180°C

WIDTHS:
A: 250
B: fit

A:
1: ingredient 1 300g
2: ingredient 2 100g

B:
1: mash
2: melt

C:
1-2: mash until smooth
```

This example means:

- Two preparation rows appear above the chart
- Column `A` has content in rows `1` and `2`
- Column `B` has content in rows `1` and `2`
- Column `C` has one vertically merged cell spanning rows `1` through `2`

---

# 6. Validation Rules

Import must either succeed completely or fail with validation errors. Invalid DSL must never be partially imported.

## Section rules

- Top-level section names must be recognized
- Column identifiers must be unique uppercase letters
- Column order in the rendered document follows alphabetical order
- `WIDTHS:` may only reference declared columns if strict import is enabled, or may define widths for future columns if permissive import is chosen

Recommended version 1 behavior:

- Require every width entry to reference a declared column

## Row and merge rules

- Overlapping row ranges within the same column are invalid
- Rows do not need to be introduced in column `A` first
- Any column may define any row independently
- Skipped row numbers are allowed
- Missing cells are treated as empty cells
- The final grid height is determined by the highest referenced row number
- Row ranges must be continuous and written from lowest to highest
- Only vertical merges are supported in version 1
- A merged range occupies all rows in that range within its column

## Width rules

- Explicit widths are stored as logical pixels
- `fit` sizes a column to its widest content, subject to minimum and maximum width constraints
- If no width is specified, the layout engine distributes available width evenly

## Content rules

- Empty text values should be rejected for chart cells
- Empty text values should be rejected for prep rows
- `TITLE:` and `YIELD:` may be omitted unless product requirements later make them mandatory

---

# 7. Validation Error Model

Validation errors should be clear, deterministic, and tied to the DSL source.

Each error should include:

- Error code
- Human-readable message
- Section or column identifier when applicable
- Source line number when available

Recommended error codes:

- `unknown_section`
- `duplicate_column`
- `invalid_column_identifier`
- `invalid_row_reference`
- `invalid_row_range`
- `overlapping_range`
- `duplicate_width`
- `unknown_width_column`
- `invalid_width_value`
- `empty_cell_text`
- `empty_prep_text`

Example messages:

- `Column C contains overlapping ranges 2-4 and 4-5.`
- `Range 5-3 is invalid. Row ranges must be ascending.`
- `WIDTHS entry for column D is invalid because column D is not declared.`

---

# 8. Parsing Output

Parsing the DSL should produce a neutral parsed representation before application-level validation and document construction.

Suggested parsed structure:

```text
ParsedRecipeDsl
- title: String?
- yieldText: String?
- prepRows: List<String>
- widthEntries: Map<ColumnId, ParsedWidthSpec>
- columns: Map<ColumnId, List<ParsedCellEntry>>

ParsedCellEntry
- startRow: int
- endRow: int
- text: String
```

This makes it easy to:

- validate overlaps
- sort columns alphabetically
- derive grid height
- convert into the internal document model

---

# 9. Internal Application Model

The application should edit a structured `RecipeDocument`, not raw DSL text.

Suggested model:

```text
RecipeDocument
- title: String?
- yieldText: String?
- prepRows: List<PrepRow>
- columns: List<WorkflowColumn>
- rowCount: int
- layoutSettings: LayoutSettings

PrepRow
- text: String

WorkflowColumn
- id: ColumnId
- widthSpec: ColumnWidthSpec?
- cells: List<WorkflowCell>

WorkflowCell
- startRow: int
- rowSpan: int
- text: String

ColumnWidthSpec
- kind: fixed | fit
- logicalPixels: int?

LayoutSettings
- minColumnWidth: double
- maxColumnWidth: double
- defaultRowHeight: double
- prepRowHeight: double
- cellPadding: EdgeInsets-like value
```

Derived invariants:

- `rowCount` equals the highest occupied row across all columns, or `0` if there are no chart cells
- `WorkflowCell.rowSpan` is always at least `1`
- A cell occupies rows `startRow` through `startRow + rowSpan - 1`
- Cells within one column must not overlap
- Columns are stored in alphabetical order

This model keeps the document renderer-friendly while remaining independent from the DSL text format.

---

# 10. Import Mapping

Import from DSL to `RecipeDocument` should follow this mapping:

- `TITLE:` -> `RecipeDocument.title`
- `YIELD:` -> `RecipeDocument.yieldText`
- `PREP:` items -> `RecipeDocument.prepRows`
- Column sections -> `RecipeDocument.columns`
- `rowCount` -> highest referenced row number
- `start-end: text` -> `WorkflowCell(startRow=start, rowSpan=end-start+1, text=text)`
- width directives -> `WorkflowColumn.widthSpec`

---

# 11. Export Rules

Export should produce a canonical and stable DSL form.

Recommended export behavior:

- Emit sections in this order: `TITLE`, `YIELD`, `PREP`, `WIDTHS`, columns
- Emit columns in alphabetical order
- Emit cell entries in ascending row order within each column
- Emit a single-row cell as `n: text`
- Emit a merged cell as `start-end: text`
- Omit optional sections that contain no data

Canonical export makes version control, testing, and AI round-tripping simpler.

---

# 12. Layout Implications

The layout engine should derive presentation from `RecipeDocument`, not from the raw DSL.

Layout behavior for version 1:

- Prep rows are full-width rows above the workflow grid
- Workflow rows share a global row index across all columns
- Fixed-width columns use their logical pixel value
- `fit` columns measure widest content and clamp to min and max constraints
- Unspecified columns divide the remaining available width evenly
- Vertically merged cells are rendered as one rectangle spanning multiple row heights

---

# 13. Version 1 Boundaries

Version 1 does not include:

- Horizontal merges
- Nested sections
- Styling directives inside the DSL
- Explicit row height directives
- Non-letter column identifiers
- Formula-like references between cells

These may be added later without changing the core row-addressed column model.
