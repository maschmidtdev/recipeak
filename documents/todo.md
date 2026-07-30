# Recipeak TODO

## Product

- Refine the chart-first recipe editor so common actions need fewer taps.
- Decide which advanced DSL operations stay exposed in the UI and which stay DSL-only.
- Improve empty-state behavior for brand new recipes and nearly empty charts.
- Define the first-time user flow for creating a recipe from scratch.

## Localization

- Replace the temporary manual localization layer with generated Flutter `gen_l10n` once codegen is stable on this machine.
- Expand localization coverage beyond the current test strings.
- Add proper German umlauts once encoding is handled consistently across the local workflow.
- Decide where a permanent language setting should live, if at all.

## Chart Editing

- Add better visual affordances for selected cells, merged cells, and empty slots.
- Support more structured editing of prep rows, workflow rows, and columns directly from the chart.
- Revisit unmerge behavior so complex merges can be restored more predictably.
- Add safeguards for destructive chart edits where accidental data loss is likely.

## DSL

- Keep round-tripping between chart edits and DSL stable as the editor grows.
- Add stronger validation feedback for malformed ranges, overlaps, and unsupported structures.
- Decide whether pasted DSL should normalize formatting automatically on save.

## Data And Persistence

- Replace in-memory sample and session state with persistent local storage.
- Decide on the long-term source of truth between stored DSL and stored document structure.
- Add migration strategy before changing the persisted recipe shape again.

## QA

- Test hot reload and restart behavior around locale switching and editor state.
- Run through Android emulator testing for create, edit, delete, merge, unmerge, and locale switching.
- Add widget and parsing tests around the current MVP flows.
