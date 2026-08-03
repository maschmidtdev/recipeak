# Recipeek TODO

## Product

- Refine the chart-first editor so common actions need fewer taps.
- Improve empty-state behavior for brand new recipes and nearly empty charts.
- Define the first-time user flow for creating a recipe from scratch.
- Add a clearer user-facing import/export entry point for the full recipe DSL.

## Localization

- Replace the temporary manual localization layer with generated Flutter `gen_l10n` once codegen is stable on this machine.
- Audit all visible strings in English and German after the latest DSL and settings changes.
- Verify encoding stays correct across the whole local workflow, especially for German text and copied DSL content.

## Chart Editing

- Add better visual affordances for selected cells, merged cells, and empty slots.
- Support more structured editing of prep rows, workflow rows, and columns directly from the chart.
- Revisit unmerge behavior so complex merges can be restored more predictably.
- Add safeguards for destructive chart edits where accidental data loss is likely.

## DSL

- Keep round-tripping between structured edits and full-recipe DSL stable as the editor grows.
- Add stronger validation feedback for malformed metadata, ranges, overlaps, and unsupported structures.
- Decide whether pasted DSL should normalize formatting automatically on save.
- Decide whether app-specific state like `favorite` should remain part of the portable DSL long-term.

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
- Run a focused QA pass for create, edit, delete, persistence, locale switching, and DSL import/export.
- Add widget and parsing tests around the current MVP flows.
