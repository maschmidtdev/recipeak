# Recipeek Tech Stack

Version: 1.0

---

# 1. Goals

The implementation stack should support:

- a mobile-first Flutter application
- deterministic chart layout and rendering
- explicit visual editing
- local-first persistence
- import and export of the Recipeek DSL
- PNG and PDF export
- a small, maintainable dependency surface

The stack should favor stable, well-supported tooling over cleverness.

---

# 2. Primary Stack

## Application framework

- Flutter
- Dart

Rationale:

- Flutter matches the existing roadmap
- It supports Android and iOS from one codebase
- Custom rendering is straightforward with `CustomPainter`, canvas APIs, and text layout primitives
- The same rendering foundation can later support desktop and web if needed

## Target platforms for version 1

- Android
- iOS

Desktop and web can remain secondary targets during development, but the product should be architected so core document, parser, layout, and renderer code stays platform-independent.

---

# 3. Recommended Package Set

## State management

- `flutter_riverpod`

Use it for:

- recipe collection state
- active document state
- editor selection state
- repository access
- import and export flows

Rationale:

- good testability
- explicit dependency flow
- no need for code generation in the initial version

## Local persistence

- `drift`
- `sqlite3_flutter_libs`
- `path_provider`
- `path`

Use `drift` with SQLite for:

- recipe metadata storage
- document persistence
- favorites, categories, and search indexing

Rationale:

- durable structured local storage
- good migration support
- strong fit for lists, filters, sorting, and future search features

Persistence recommendation:

- store `RecipeEntry` metadata in normalized tables
- store the canonical `RecipeDocument` payload as structured JSON text in SQLite
- optionally add derived searchable fields for title, tags, and category relationships

This keeps the schema simple while preserving flexibility as the document model evolves.

## Serialization

- `dart:convert`

Prefer manual JSON mapping or simple model serialization helpers before introducing code generation.

## Routing

- Flutter Navigator API for version 1

Do not introduce `go_router` unless navigation complexity grows beyond:

- collection screen
- reader screen
- editor screen
- import or settings flows

Version 1 does not need extra routing abstraction.

## PDF export

- `pdf`
- `printing` if device share and print workflows are needed early

Use the shared layout engine as the source of geometry. Do not create a separate PDF-only recipe layout model.

## Image export

- Flutter `dart:ui` image APIs

Use `PictureRecorder`, `Canvas`, and image encoding to produce PNG output from the same rendering pipeline.

## Utilities

- `collection`
- `meta`
- `uuid`
- `clock` for testable time handling if needed

Keep utility dependencies minimal.

---

# 4. Deliberate Non-Choices

Version 1 should avoid:

- `flutter_bloc`
- `freezed`
- `build_runner`
- `json_serializable`
- `go_router`
- remote backend SDKs

Reason:

- the project is still defining its core document, layout, and editor behavior
- code generation and extra abstractions add friction before the model stabilizes
- local-first architecture is the correct default for the current scope

These can be introduced later if the codebase proves it needs them.

---

# 5. Application Architecture

Recommended package structure inside `lib/`:

```text
lib/
  app/
  core/
  features/
    recipe_book/
    recipe_document/
    dsl/
    layout/
    rendering/
    editor/
    import_export/
```

Suggested responsibilities:

- `app/`
  - app bootstrap
  - theme
  - top-level navigation

- `core/`
  - shared utilities
  - ids
  - time
  - error types

- `features/recipe_book/`
  - recipe list models
  - repository interfaces
  - collection screen logic

- `features/recipe_document/`
  - `RecipeDocument`
  - document editing operations
  - document validation

- `features/dsl/`
  - parser
  - exporter
  - DSL validation errors

- `features/layout/`
  - deterministic layout engine
  - geometry output

- `features/rendering/`
  - chart renderer
  - prep row renderer
  - editing overlays

- `features/editor/`
  - selection model
  - command handlers
  - undo and redo

- `features/import_export/`
  - PNG export
  - PDF export
  - sharing

The critical architectural rule is:

- parser -> `RecipeDocument` -> layout engine -> renderer

The renderer should never parse DSL directly, and the editor should never depend on storage details.

---

# 6. Data and Storage Strategy

## Repository boundary

Define a repository interface early:

```text
RecipeRepository
- listRecipes()
- loadRecipe(id)
- saveRecipe(entry)
- deleteRecipe(id)
- searchRecipes(query)
```

The app should depend on this interface, not directly on SQLite or Drift APIs.

## Storage model

Recommended split:

- `recipe_entries` table for metadata
- `recipe_categories` and join tables for organization
- `recipe_documents` payload stored as JSON text

Store at minimum:

- id
- title
- yield text
- favorite
- createdAt
- updatedAt
- tags
- category relationships
- serialized `RecipeDocument`

This gives flexibility while keeping search and list queries efficient.

---

# 7. Rendering Stack

## Core rendering approach

Use:

- `CustomPainter`
- `Canvas`
- `TextPainter`

The layout engine should produce a geometry model such as:

```text
LaidOutRecipeDocument
- prepRowRects
- columnRects
- cellRects
- textLayouts
- totalSize
```

Then the renderer only paints from that output.

This preserves the design rule that layout computes geometry and rendering only draws.

## Editing overlays

Editing mode should add a separate overlay layer for:

- selected cell highlight
- selected row or column highlight
- resize handles
- insertion markers

Do not mix editing hit-testing logic into the paint-only renderer.

---

# 8. DSL Implementation Strategy

The DSL should be parsed with a small hand-written parser rather than a parser framework.

Rationale:

- the grammar is small
- validation is domain-specific
- error reporting needs to be explicit and source-oriented

Recommended components:

- line tokenizer
- section reader
- column entry parser
- validator
- exporter

The parser output should follow `dsl-spec.md`, then convert into `RecipeDocument`.

---

# 9. Testing Stack

- `flutter_test`
- `test`

Recommended test layers:

- unit tests for DSL parsing and validation
- unit tests for document editing operations
- unit tests for layout geometry
- widget tests for collection, reader, and editor interactions
- golden tests for recipe chart rendering

Golden testing recommendation:

- use Flutter golden tests directly first
- add `golden_toolkit` only if baseline golden management becomes painful

High-priority early tests:

- overlapping merge rejection
- sparse row handling
- canonical DSL export
- fit-width calculation
- merged-cell geometry

---

# 10. Build and Quality Tooling

Use:

- `flutter format`
- `flutter analyze`
- `flutter test`

Linting recommendation:

- enable `package:flutter_lints`
- keep custom linting light until implementation patterns stabilize

CI can be added after the first runnable Flutter app scaffold exists.

---

# 11. Initial Milestones

Recommended implementation order:

1. Create the Flutter app scaffold.
2. Define the core document model in Dart.
3. Implement DSL parse, validate, and export.
4. Implement the layout engine.
5. Implement the read-only renderer.
6. Add local persistence with Drift.
7. Build the collection screen and recipe reader flow.
8. Add editing state, selection, and document commands.
9. Add PNG and PDF export.

This order reduces risk by proving the core document-to-render pipeline before building the editor.

---

# 12. Version 1 Decisions

The version 1 implementation stack is:

- Flutter
- Dart
- `flutter_riverpod`
- `drift` with SQLite
- Flutter canvas rendering via `CustomPainter`
- hand-written DSL parser
- Flutter built-in test tools plus golden rendering tests

This stack is intentionally conservative. The difficult part of Recipeek is not backend infrastructure. It is getting the document model, layout engine, and editor behavior correct.
