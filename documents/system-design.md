# Recipeek

## Architecture & Design Specification

Version: 1.0

---

# 1. Project Vision

Recipeek is a mobile-first digital recipe book for creating, organizing and viewing recipes as visual workflow charts.

The primary goal is to replace traditional paragraph-style recipes with an easier-to-follow visual representation while providing a clean editing experience.

---

# 2. Core Principles

- Mobile-first design.
- Reading mode is the default experience.
- Editing is explicit and visual (WYSIWYG).
- RecipeDocument is the single source of truth.
- The renderer is shared between reading and editing modes.
- The DSL exists only for import/export and serialization.

---

# 3. High-Level Architecture

```
RecipeBook
    │
    ├── Recipe Collection
    ├── Recipe Repository
    └── Recipe Editor
            │
            ▼
      RecipeDocument
            │
            ▼
       Layout Engine
            │
            ▼
         Renderer
```

---

# 4. Domain Model

## RecipeBook

Represents the user's complete recipe collection.

Contains:

- Recipes
- Categories
- Application settings

---

## RecipeEntry

Represents a recipe inside the collection.

Fields:

- id
- document
- createdAt
- updatedAt
- favorite
- categoryIds
- tags

---

## RecipeDocument

Represents one editable recipe.

Fields:

- title
- yield
- preparation rows
- workflow grid
- layout settings

RecipeDocument contains only information required to display and edit a recipe.

---

# 5. Application Flow

```
Launch App

↓

Recipe Collection

↓

Open Recipe

↓

Reading Mode

↓

Edit (optional)

↓

Save

↓

Back to Collection
```

The collection is the application's home screen.

Recipes open in reading mode by default.

Editing is entered explicitly.

---

# 6. User Interface

## Collection

- Browse recipes
- Search
- Sort
- Create recipe
- Duplicate
- Rename
- Delete
- Favorites
- Categories

---

## Reading Mode

Displays:

- Title
- Yield
- Preparation
- Workflow chart

Does not display editing controls.

---

## Editing Mode

Uses the same renderer with editing overlays.

Supports:

- Cell selection
- Row selection
- Column selection
- Context-sensitive action panel
- Undo / Redo

# 7. Editing Model

Editing is selection-based.

Supported selection types:

- Cell
- Row
- Column
- Preparation row
- Entire recipe

Selecting an element displays a context-sensitive action panel.

Supported operations:

- Edit text
- Merge
- Split
- Insert row
- Delete row
- Insert column
- Delete column
- Resize column
- Fit column to content

---

# 8. Layout & Rendering

Rendering is deterministic.

Pipeline:

```
RecipeDocument

↓

Layout Engine

↓

Renderer

↓

Screen / PNG / PDF
```

The Layout Engine calculates all geometry.

The Renderer only draws.

Reading and editing modes use the same renderer. Editing mode adds overlays such as selections and resize handles.

---

# 9. Persistence

The application stores a local RecipeBook.

Recipes are stored independently.

Repository responsibilities:

- List recipes
- Load recipe
- Save recipe
- Delete recipe
- Search recipes

The storage implementation should remain replaceable.

---

# 10. DSL

The DSL represents a single RecipeDocument.

It is used for:

- Import
- Export
- Sharing
- AI generation
- Testing

The DSL is not used as the application's internal data model.

The formal DSL syntax, validation rules, and internal model mapping are defined in `dsl-spec.md`.

Illustrative example:

```text
TITLE:
Banana Bread

YIELD:
10 servings

PREP:
1. Preheat oven
2. Grease pan

WIDTHS:
A: 250
B: fit
C: fit

A:
1. Flour
2. Sugar
3. Butter

B:
1. Mix dry
2-3. Cream butter

C:
2-3. Beat until fluffy
```

---

# 11. Roadmap

## Phase 1

- Flutter project setup
- RecipeBook
- RecipeDocument
- Renderer
- Reading mode

## Phase 2

- Visual editor
- Selection
- Action panel
- Editing
- Undo / Redo

## Phase 3

- Import / Export
- PNG export
- PDF export

## Phase 4

- Categories
- Favorites
- Search
- Polishing

---

# 12. Future Features

Possible future additions:

- Cloud synchronization
- User accounts
- Shared recipe collections
- Collaborative editing
- Themes
- AI recipe generation
- AI recipe conversion
- Shopping lists
- Meal planning

---

# 13. Guiding Rules

- RecipeBook represents the application.
- RecipeDocument represents one recipe.
- RecipeDocument is the single source of truth.
- The chart is the primary representation of a recipe.
- Reading mode is the default experience.
- Editing is visual and WYSIWYG.
- The renderer should remain independent of storage and editing.
- Keep the architecture simple and modular.
