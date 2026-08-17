import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe_collection_filters.dart';
import '../../domain/recipe_summary.dart';

class CollectionSettingsSheet extends StatefulWidget {
  const CollectionSettingsSheet({
    super.key,
    required this.locale,
    required this.matchAllTags,
    required this.availableTagCountBuilder,
    required this.showResetToSeed,
    required this.onLocaleChanged,
    required this.onMatchAllTagsChanged,
    required this.onResetToSeed,
    required this.onBackupIngredients,
    required this.onExportIngredients,
    required this.onImportIngredients,
    required this.onAddTag,
    required this.onOpenTagManager,
  });

  final Locale locale;
  final bool matchAllTags;
  final int Function() availableTagCountBuilder;
  final bool showResetToSeed;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<bool> onMatchAllTagsChanged;
  final Future<void> Function() onResetToSeed;
  final Future<void> Function() onBackupIngredients;
  final Future<void> Function() onExportIngredients;
  final Future<void> Function() onImportIngredients;
  final Future<bool> Function() onAddTag;
  final Future<void> Function() onOpenTagManager;

  @override
  State<CollectionSettingsSheet> createState() =>
      _CollectionSettingsSheetState();
}

class _CollectionSettingsSheetState extends State<CollectionSettingsSheet> {
  late bool _matchAllTags;

  @override
  void initState() {
    super.initState();
    _matchAllTags = widget.matchAllTags;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showResetToSeed) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restart_alt),
                title: Text(localizations.resetToSeedLabel),
                subtitle: Text(localizations.resetToSeedDescription),
                onTap: () async {
                  Navigator.of(context).pop();
                  await widget.onResetToSeed();
                },
              ),
              const SizedBox(height: 8),
            ],
            Text(
              localizations.settingsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.languageLabel,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD7CCBE)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: widget.locale,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(16),
                  items: [
                    DropdownMenuItem<Locale>(
                      value: const Locale('en'),
                      child: Text(localizations.englishLanguage),
                    ),
                    DropdownMenuItem<Locale>(
                      value: const Locale('de'),
                      child: Text(localizations.germanLanguage),
                    ),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      widget.onLocaleChanged(locale);
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localizations.ingredientsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.backup_outlined),
              title: Text(localizations.backupIngredientsLabel),
              subtitle: Text(localizations.backupIngredientsDescription),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.onBackupIngredients();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_outlined),
              title: Text(localizations.exportIngredientsLabel),
              subtitle: Text(localizations.exportIngredientsDescription),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.onExportIngredients();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_outlined),
              title: Text(localizations.importIngredientsLabel),
              subtitle: Text(localizations.importIngredientsDescription),
              onTap: () async {
                Navigator.of(context).pop();
                await widget.onImportIngredients();
              },
            ),
            const SizedBox(height: 16),
            Text(
              localizations.tagsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.tagMatchingLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(localizations.matchAnyLabel),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(localizations.matchAllLabel),
                ),
              ],
              selected: {_matchAllTags},
              onSelectionChanged: (selection) {
                setState(() {
                  _matchAllTags = selection.first;
                });
                widget.onMatchAllTagsChanged(_matchAllTags);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add),
              title: Text(localizations.addTagLabel),
              subtitle: Text(
                localizations.tagsAvailableCountLabel(
                  widget.availableTagCountBuilder(),
                ),
              ),
              onTap: () async {
                final added = await widget.onAddTag();
                if (added && mounted) {
                  setState(() {});
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline),
              title: Text(localizations.editDeleteTagsLabel),
              subtitle: Text(localizations.renameOrRemoveTags),
              onTap: () async {
                await widget.onOpenTagManager();
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TagManagerSheet extends StatefulWidget {
  const TagManagerSheet({
    super.key,
    required this.availableTags,
    required this.recipes,
    required this.tagLabelBuilder,
    required this.onRenameTag,
    required this.onDeleteTag,
  });

  final Set<String> availableTags;
  final List<RecipeSummary> recipes;
  final String Function(BuildContext context, String tag) tagLabelBuilder;
  final Future<bool> Function(String tag) onRenameTag;
  final Future<bool> Function(String tag) onDeleteTag;

  @override
  State<TagManagerSheet> createState() => _TagManagerSheetState();
}

class _TagManagerSheetState extends State<TagManagerSheet> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final tagUsage = tagUsageCounts(
      availableTags: widget.availableTags,
      recipes: widget.recipes,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.deleteTagTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.availableTags.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  localizations.noTagsAvailableToDelete,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5E675F),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in sortedTags(widget.availableTags))
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3DACD)),
                        ),
                        child: ListTile(
                          title: Text(widget.tagLabelBuilder(context, tag)),
                          subtitle: Text(
                            localizations.recipesCountLabel(tagUsage[tag] ?? 0),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final renamed = await widget.onRenameTag(tag);
                                  if (renamed && mounted) {
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: localizations.edit,
                              ),
                              IconButton(
                                onPressed: () async {
                                  final deleted = await widget.onDeleteTag(tag);
                                  if (deleted && mounted) {
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(Icons.delete_outline),
                                tooltip: localizations.delete,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
