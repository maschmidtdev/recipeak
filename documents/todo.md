# Recipeek TODO

## Product

- Refine the chart-first editor so common actions need fewer taps.
- Improve empty-state behavior for brand new recipes and nearly empty charts.
- Define the first-time user flow for creating a recipe from scratch.
- Refine the recipe values section after testing the new nutrition and cost table on real recipes.
- Decide how prominently partial recipe values should be shown when not all ingredient cells are linked.

## Localization

- Replace the temporary manual localization layer with generated Flutter `gen_l10n` once codegen is stable on this machine.
- Audit all visible strings in English and German after the latest ingredient, nutrition, and cost changes.
- Verify encoding stays correct across the whole local workflow, especially for German text and copied DSL content.

## Ingredients And Values

- Improve ingredient linking UX from ingredient-column cells, especially when a text cell already contains an amount.
- Add clearer validation for ingredient product fields used in calculations: amount, price, kcal, protein, carbs, and fat.
- Decide whether ingredient price should support currencies explicitly or stay as a simple numeric field for the MVP.
- Decide how to handle recipes that mix grams and milliliters in one values table.
- Consider showing linked ingredient status directly in the chart editor.
- Add tests for ingredient persistence and recipe value recalculation after editing an ingredient.

## Chart Editing

- Add better visual affordances for selected cells, merged cells, and empty slots.
- Support more structured editing of prep rows, workflow rows, and columns directly from the chart.
- Revisit unmerge behavior so complex merges can be restored more predictably.
- Add safeguards for destructive chart edits where accidental data loss is likely.

## DSL

- Keep round-tripping between structured edits and full-recipe DSL stable as the editor grows.
- Add stronger validation feedback for malformed metadata, ranges, overlaps, and unsupported structures.
- Replace plain DSL error strings with structured validation errors that can show chart context first, e.g. `Column B, rows 5-6`, and line numbers as secondary detail when useful.
- Decide whether pasted DSL should normalize formatting automatically on save.
- Decide whether app-specific state like `favorite` should remain part of the portable DSL long-term.
- Keep ingredient links portable by preserving both cell text and optional local ingredient metadata.

## Data And Persistence

- Decide on the long-term source of truth between stored DSL and stored structured document data.
- Add a migration strategy before changing the persisted recipe shape again.
- Decide whether users need a non-dev reset or restore-to-seed flow in production.

## Release Readiness

- Create the real Android release keystore and fill `mobile/android/key.properties`.
- Decide the first production versioning policy after `1.0.0+1`.
- Run a production build sanity pass.
- Finalize splash/launch assets and store-facing app metadata.
- Verify all dev-only controls stay hidden in production mode.
- Run a focused QA pass for create, edit, delete, persistence, locale switching, DSL import/export, ingredient linking, and recipe values.
- Add widget and parsing tests around the current MVP flows.
- Add a small release checklist for testing seeded production data on a clean install.
