import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_storage_codec.dart';
import 'app_storage_snapshot.dart';
import 'dev_flags.dart';
import '../features/recipe_book/domain/recipe_summary.dart';

export 'app_storage_snapshot.dart';

class AppStorage {
  AppStorage._();

  static final AppStorage instance = AppStorage._();

  static const _localeKey = 'app.locale';
  static const _productionSeedAssetPath = 'assets/seeds/production_recipes.json';
  static const _codec = AppStorageCodec();

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

      return _codec.snapshotFromJson(decoded);
    } catch (error) {
      debugPrint('Failed to load persisted recipe state: $error');
      return null;
    }
  }

  Future<void> saveRecipeState(AppStorageSnapshot snapshot) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_codec.snapshotToJson(snapshot));
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
          .map(_codec.recipeSummaryFromJson)
          .toList();
    } catch (error) {
      debugPrint('Failed to load production seed recipes: $error');
      return const [];
    }
  }
}
