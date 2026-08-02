# Recipeek DSL Specification

Version: 1.1

---

# 1. Purpose

This document defines the text DSL used to import and export a complete recipe.

The DSL now covers:

- recipe metadata
- prep rows
- chart columns and cells
- optional explicit column widths

It is intended for:

- recipe sharing
- copy/paste import and export
- AI generation
- fixtures and tests
- advanced manual editing

The structured editor remains the primary editing model inside the app.

---

# 2. Recipe Model

A full DSL recipe can describe:

- `title`
- `description`
- `duration`
- `yield`
- `tags`
- `favorite`
- `prep` rows
- chart `widths`
- chart columns `A` through `Z`

The chart grid still uses a global workflow row index:

- rows start at `1`
- any column may define any row independently
- skipped rows are allowed
- missing cells are treated as empty cells
- the final workflow height is determined by the highest referenced row number

Version 1.1 supports rectangular cells:

- vertical spans across multiple rows
- horizontal spans across adjacent columns
- mixed row and column spans in the same cell

---

# 3. Top-Level Structure

Supported top-level entries:

- `title:`
- `description:`
- `duration:`
- `yield:`
- `tags:`
- `favorite:`
- `prep:`
- `widths:`
- column sections such as `A:`, `B:`, `C:`

Metadata entries use single-line `key: value` syntax.

Section headers use:

- `prep:`
- `widths:`
- `A:`
- `B:`
- etc.

Column identifiers:

- must be a single uppercase letter from `A` to `Z`
- must be unique
- are rendered in alphabetical order

Column section headers may also describe horizontal spans:

- `A:` defines cells starting in column `A`
- `B-D:` defines cells starting in column `B` and spanning through column `D`

---

# 4. Syntax

## Metadata

```text
title: Skillet Chickpea Curry
description: A weeknight chickpea curry with tomato, spinach, and warm spices.
duration: 35 min
yield: 4 servings
tags: Vegan, Dinner
favorite: true
```

Rules:

- metadata values are single-line text
- `tags` are comma-separated
- whitespace around tags is ignored
- duplicate tags should be collapsed
- `favorite` accepts `true` or `false`

## Prep rows

```text
prep:
- Set out a large skillet and a medium pot
- Warm oil over medium heat
```

## Widths

```text
widths:
B: 180
```

Supported width values:

- `fit`
- positive numeric logical pixels

Rules:

- omitting a width means the column uses the default auto-fit behavior
- `fit` is valid on import but usually omitted on export because it is the default
- use the `widths` section only when you want to force explicit widths

## Workflow columns

Single-row cells:

```text
B:
1. dice
2. mince
```

Merged cells:

```text
C:
2-4: cook until fragrant
```

Horizontal or rectangular merged cells:

```text
D-F:
1-7: simmer and finish
```

Rules:

- single rows use `row. text` or `row: text`
- merged cells use `start-end: text`
- a column range such as `D-F:` creates cells with a horizontal span
- row numbers must be positive integers
- ranges must be ascending
- overlapping row ranges in the same column are invalid
- rectangular cell ranges must not overlap any existing cell range

Cell text may continue on following lines if the continuation line is not a new DSL entry.

---

# 5. Example

```text
title: Skillet Chickpea Curry
description: A weeknight chickpea curry with tomato, spinach, and warm spices.
duration: 35 min
yield: 4 servings
tags: Vegan
favorite: true

prep:
- Set out a large skillet and a medium pot
- Warm oil over medium heat

A:
1. 240 g rice
2. 150 g onion
3. 12 g garlic
4. 35 g curry paste
5. 400 g tomatoes
6. 240 g chickpeas
7. 120 g spinach

B:
1. rinse + boil
2. dice
3. mince
4. stir in

C:
2-4: cook until fragrant
5: pour in
6: add in
7: stir in

D:
2-7: simmer until chickpeas are hot and spinach wilts

E:
1-7: serve over rice
```

This represents a complete recipe import/export payload, not just the chart body.

---

# 6. Validation Rules

Import must either succeed completely or fail with validation errors.

Invalid DSL must never be partially imported.

## Metadata rules

- all metadata entries are optional
- unknown top-level keys are invalid
- `favorite` must be a valid boolean
- `tags` may be empty

## Section rules

- section names must be recognized
- column identifiers must be unique uppercase letters
- width entries must not be duplicated
- width entries must only reference declared columns

## Row and merge rules

- overlapping cell ranges are invalid
- rows do not need to appear in column `A` first
- any column may define any row independently
- skipped row numbers are allowed
- missing cells are treated as empty cells
- row ranges must be continuous and ascending
- column ranges must be continuous and ascending
- vertical, horizontal, and mixed rectangular merges are supported

## Content rules

- empty prep text is invalid
- empty cell text is invalid

---

# 7. Export Rules

Export should be canonical and stable.

Recommended order:

1. `title`
2. `description`
3. `duration`
4. `yield`
5. `tags`
6. `favorite`
7. `prep`
8. `widths`
9. columns in alphabetical order

Recommended behavior:

- omit empty metadata entries
- omit `favorite` when false
- omit empty sections
- omit `widths` entries for columns using default `fit` behavior
- sort columns alphabetically
- sort cells by starting row within each column

---

# 8. Internal Mapping

Import from DSL should map to application data like this:

- `title` -> recipe title
- `description` -> recipe description
- `duration` -> recipe duration
- `yield` -> recipe yield/servings
- `tags` -> recipe tags
- `favorite` -> recipe favorite state
- `prep` -> `RecipeDocument.prepRows`
- column sections -> `RecipeDocument.columns`
- highest referenced row -> derived workflow row count

The chart remains a structured `RecipeDocument`, but the DSL now represents the entire recipe payload around it.

---

# 9. Version 1 Boundaries

Version 1 still does not include:

- nested sections
- inline styling
- explicit row heights
- formulas or references
- binary assets

Future versions can extend the metadata surface without changing the chart addressing model.
