import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/recipe_collection_filters.dart';
import '../../domain/recipe_summary.dart';

enum CollectionMenuAction {
  settings,
  tags,
  backups,
  about,
}

class CollectionMenuSheet extends StatelessWidget {
  const CollectionMenuSheet({
    super.key,
    required this.onSelectAction,
  });

  final ValueChanged<CollectionMenuAction> onSelectAction;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuTile(
              icon: Icons.settings_outlined,
              title: localizations.settingsTitle,
              onTap: () => onSelectAction(CollectionMenuAction.settings),
            ),
            _MenuTile(
              icon: Icons.sell_outlined,
              title: localizations.tagsTitle,
              onTap: () => onSelectAction(CollectionMenuAction.tags),
            ),
            _MenuTile(
              icon: Icons.backup_outlined,
              title: localizations.backupsTitle,
              onTap: () => onSelectAction(CollectionMenuAction.backups),
            ),
            _MenuTile(
              icon: Icons.info_outline,
              title: localizations.aboutTitle,
              onTap: () => onSelectAction(CollectionMenuAction.about),
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionSettingsSheet extends StatefulWidget {
  const CollectionSettingsSheet({
    super.key,
    required this.locale,
    required this.matchAllTags,
    required this.showResetToSeed,
    required this.onLocaleChanged,
    required this.onMatchAllTagsChanged,
    required this.onResetToSeed,
  });

  final Locale locale;
  final bool matchAllTags;
  final bool showResetToSeed;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<bool> onMatchAllTagsChanged;
  final Future<void> Function() onResetToSeed;

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
            _SheetTitle(
              icon: Icons.settings_outlined,
              title: localizations.settingsTitle,
            ),
            if (widget.showResetToSeed) ...[
              const SizedBox(height: 12),
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
            ],
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
          ],
        ),
      ),
    );
  }
}

class CollectionBackupsSheet extends StatelessWidget {
  const CollectionBackupsSheet({
    super.key,
    required this.onBackupIngredients,
    required this.onExportIngredients,
    required this.onImportIngredients,
  });

  final Future<void> Function() onBackupIngredients;
  final Future<void> Function() onExportIngredients;
  final Future<void> Function() onImportIngredients;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              icon: Icons.backup_outlined,
              title: localizations.backupsTitle,
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.backup_outlined,
              title: localizations.backupIngredientsLabel,
              subtitle: localizations.backupIngredientsDescription,
              onTap: () async {
                Navigator.of(context).pop();
                await onBackupIngredients();
              },
            ),
            _MenuTile(
              icon: Icons.upload_outlined,
              title: localizations.exportIngredientsLabel,
              subtitle: localizations.exportIngredientsDescription,
              onTap: () async {
                Navigator.of(context).pop();
                await onExportIngredients();
              },
            ),
            _MenuTile(
              icon: Icons.download_outlined,
              title: localizations.importIngredientsLabel,
              subtitle: localizations.importIngredientsDescription,
              onTap: () async {
                Navigator.of(context).pop();
                await onImportIngredients();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionTagsSheet extends StatelessWidget {
  const CollectionTagsSheet({
    super.key,
    required this.availableTagCountBuilder,
    required this.onAddTag,
    required this.onOpenTagManager,
  });

  final int Function() availableTagCountBuilder;
  final Future<bool> Function() onAddTag;
  final Future<void> Function() onOpenTagManager;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              icon: Icons.sell_outlined,
              title: localizations.tagsTitle,
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.add,
              title: localizations.addTagLabel,
              subtitle: localizations.tagsAvailableCountLabel(
                availableTagCountBuilder(),
              ),
              onTap: () async {
                await onAddTag();
              },
            ),
            _MenuTile(
              icon: Icons.edit_outlined,
              title: localizations.editDeleteTagsLabel,
              subtitle: localizations.renameOrRemoveTags,
              onTap: onOpenTagManager,
            ),
          ],
        ),
      ),
    );
  }
}

class CollectionAboutSheet extends StatelessWidget {
  const CollectionAboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle(
              icon: Icons.info_outline,
              title: localizations.aboutTitle,
            ),
            const SizedBox(height: 12),
            Text(localizations.localDataNotice),
          ],
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final FutureOr<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () {
        onTap();
      },
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
            _SheetTitle(
              icon: Icons.sell_outlined,
              title: localizations.deleteTagTitle,
            ),
            const SizedBox(height: 12),
            if (widget.availableTags.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD7CCBE)),
                ),
                child: Text(localizations.noTagsAvailableToDelete),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in sortedTags(widget.availableTags))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(widget.tagLabelBuilder(context, tag)),
                        subtitle: Text(
                          localizations.tagUsageCountLabel(tagUsage[tag] ?? 0),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: localizations.edit,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final changed = await widget.onRenameTag(tag);
                                if (changed && mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                            IconButton(
                              tooltip: localizations.deleteTagLabel,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final deleted = await widget.onDeleteTag(tag);
                                if (deleted && mounted) {
                                  setState(() {});
                                }
                              },
                            ),
                          ],
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
