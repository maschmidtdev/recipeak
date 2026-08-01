import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dev_flags.dart';
import '../features/recipe_book/domain/recipe_summary.dart';
import '../features/recipe_document/domain/recipe_document.dart';

class AppStorageSnapshot {
  const AppStorageSnapshot({
    required this.recipes,
    required this.availableTags,
    required this.matchAllTags,
  });

  final List<RecipeSummary> recipes;
  final List<String> availableTags;
  final bool matchAllTags;
}

class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  static const _localeKey = 'app.locale';
  static const _productionSeedAssetPath = 'assets/seeds/production_recipes.json';

  String get _recipeStateKey =>
      'app.recipe_state.${kIsDevelopmentMode ? 'dev' : 'prod'}';

  Future<Locale?> loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);
    if (languageCode == null || languageCode.isEmpty) {
      return null;
    }
    return Locale(languageCode);
  }

  Future<void> saveLocale(Locale locale) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  Future<AppStorageSnapshot?> loadRecipeState() async {
    final preferences = await SharedPreferences.getInstance();
    final rawState = preferences.getString(_recipeStateKey);
    if (rawState == null || rawState.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawState);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final recipes = (decoded['recipes'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_recipeSummaryFromJson)
          .toList();
      final availableTags = (decoded['availableTags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
      final matchAllTags = decoded['matchAllTags'] as bool? ?? false;

      return AppStorageSnapshot(
        recipes: recipes,
        availableTags: availableTags,
        matchAllTags: matchAllTags,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRecipeState(AppStorageSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'recipes': [
        for (final recipe in snapshot.recipes) _recipeSummaryToJson(recipe),
      ],
      'availableTags': snapshot.availableTags,
      'matchAllTags': snapshot.matchAllTags,
    });
    await preferences.setString(_recipeStateKey, encoded);
  }

  Future<void> clearRecipeState() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_recipeStateKey);
  }

  Future<List<RecipeSummary>> loadProductionSeedRecipes() async {
    try {
      final rawJson = await rootBundle.loadString(_productionSeedAssetPath);
      final decoded = jsonDecode(rawJson);

      final recipeList = switch (decoded) {
        final Map<String, dynamic> map =>
          map['recipes'] as List<dynamic>? ?? const [],
        final List<dynamic> list => list,
        _ => const <dynamic>[],
      };

      return recipeList
          .whereType<Map<String, dynamic>>()
          .map(_recipeSummaryFromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Map<String, dynamic> _recipeSummaryToJson(RecipeSummary recipe) {
    return {
      'title': recipe.title,
      'description': recipe.description,
      'duration': recipe.duration,
      'yieldText': recipe.yieldText,
      'tags': recipe.tags,
      'isFavorite': recipe.isFavorite,
      'isDraft': recipe.isDraft,
      'document': _recipeDocumentToJson(recipe.document),
    };
  }

  RecipeSummary _recipeSummaryFromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      yieldText: json['yieldText'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isDraft: json['isDraft'] as bool? ?? false,
      document: _recipeDocumentFromJson(
        json['document'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> _recipeDocumentToJson(RecipeDocument document) {
    return {
      'prepRows': [
        for (final prepRow in document.prepRows) {'text': prepRow.text},
      ],
      'columns': [
        for (final column in document.columns)
          {
            'id': column.id,
            'widthSpec': _columnWidthSpecToJson(column.widthSpec),
            'cells': [
              for (final cell in column.cells)
                {
                  'startRow': cell.startRow,
                  'rowSpan': cell.rowSpan,
                  'columnSpan': cell.columnSpan,
                  'text': cell.text,
                },
            ],
          },
      ],
    };
  }

  RecipeDocument _recipeDocumentFromJson(Map<String, dynamic> json) {
    return RecipeDocument(
      prepRows: (json['prepRows'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((prepRow) => PrepRow(text: prepRow['text'] as String? ?? ''))
          .toList(),
      columns: (json['columns'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (column) => WorkflowColumn(
              id: column['id'] as String? ?? '',
              widthSpec: _columnWidthSpecFromJson(
                column['widthSpec'] as Map<String, dynamic>?,
              ),
              cells: (column['cells'] as List<dynamic>? ?? const [])
                  .whereType<Map<String, dynamic>>()
                  .map(
                    (cell) => WorkflowCell(
                      startRow: cell['startRow'] as int? ?? 1,
                      rowSpan: cell['rowSpan'] as int? ?? 1,
                      columnSpan: cell['columnSpan'] as int? ?? 1,
                      text: cell['text'] as String? ?? '',
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic>? _columnWidthSpecToJson(ColumnWidthSpec? widthSpec) {
    if (widthSpec == null) {
      return null;
    }

    return {
      'kind': widthSpec.kind.name,
      'logicalPixels': widthSpec.logicalPixels,
    };
  }

  ColumnWidthSpec? _columnWidthSpecFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final kind = json['kind'] as String? ?? '';
    switch (kind) {
      case 'fixed':
        final logicalPixels = (json['logicalPixels'] as num?)?.toDouble();
        if (logicalPixels == null) {
          return null;
        }
        return ColumnWidthSpec.fixed(logicalPixels);
      case 'fit':
        return const ColumnWidthSpec.fit();
      default:
        return null;
    }
  }
}
