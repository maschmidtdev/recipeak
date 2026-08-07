import '../features/recipe_book/domain/recipe_summary.dart';
import '../features/ingredients/domain/ingredient_cell_text.dart';
import '../features/ingredients/domain/ingredient_product.dart';
import '../features/recipe_document/domain/recipe_document.dart';
import 'app_storage_snapshot.dart';

class AppStorageCodec {
  const AppStorageCodec();

  Map<String, dynamic> snapshotToJson(AppStorageSnapshot snapshot) {
    return {
      'recipes': [
        for (final recipe in snapshot.recipes) recipeSummaryToJson(recipe),
      ],
      'availableTags': snapshot.availableTags,
      'matchAllTags': snapshot.matchAllTags,
      'ingredients': [
        for (final ingredient in snapshot.ingredients)
          ingredientProductToJson(ingredient),
      ],
      'availableIngredientTags': snapshot.availableIngredientTags,
    };
  }

  AppStorageSnapshot snapshotFromJson(Map<String, dynamic> json) {
    final recipes = (json['recipes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(recipeSummaryFromJson)
        .toList();
    final availableTags = (json['availableTags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final matchAllTags = json['matchAllTags'] as bool? ?? false;
    final ingredients = (json['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .indexed
        .map(
          (entry) => ingredientProductFromJson(
            entry.$2,
            fallbackIndex: entry.$1,
          ),
        )
        .toList();
    final availableIngredientTags =
        (json['availableIngredientTags'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList();

    return AppStorageSnapshot(
      recipes: recipes,
      availableTags: availableTags,
      matchAllTags: matchAllTags,
      ingredients: ingredients,
      availableIngredientTags: availableIngredientTags,
    );
  }

  Map<String, dynamic> ingredientProductToJson(IngredientProduct ingredient) {
    return {
      'id': ingredient.id,
      'name': ingredient.name,
      'amount': normalizedIngredientAmount(ingredient.amount),
      'price': ingredient.price,
      'store': ingredient.store,
      'kcal': ingredient.kcal,
      'protein': ingredient.protein,
      'carbs': ingredient.carbs,
      'fat': ingredient.fat,
      'baseUnit': ingredient.baseUnit.storageValue,
      'tags': ingredient.tags,
    };
  }

  IngredientProduct ingredientProductFromJson(
    Map<String, dynamic> json, {
    int fallbackIndex = 0,
  }) {
    final name = json['name'] as String? ?? '';
    final rawAmount = json['amount'] as String? ?? '';
    final amount = normalizedIngredientAmount(rawAmount);
    final store = json['store'] as String? ?? '';
    return IngredientProduct(
      id: json['id'] as String? ??
          _legacyIngredientId(
            name: name,
            amount: rawAmount,
            store: store,
            index: fallbackIndex,
          ),
      name: name,
      amount: amount,
      price: json['price'] as String? ?? '',
      store: store,
      kcal: (json['kcal'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      baseUnit: _ingredientBaseUnitFromJson(json['baseUnit'], rawAmount),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  IngredientBaseUnit _ingredientBaseUnitFromJson(
    Object? value,
    String fallbackAmount,
  ) {
    return switch (value) {
      'ml' => IngredientBaseUnit.milliliters,
      'g' => IngredientBaseUnit.grams,
      _ => fallbackAmount.trim().toLowerCase().endsWith('ml')
          ? IngredientBaseUnit.milliliters
          : IngredientBaseUnit.grams,
    };
  }

  String _legacyIngredientId({
    required String name,
    required String amount,
    required String store,
    required int index,
  }) {
    final raw = [name, amount, store, index.toString()].join('-');
    final slug = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return 'legacy-${slug.isEmpty ? index.toString() : slug}';
  }

  Map<String, dynamic> recipeSummaryToJson(RecipeSummary recipe) {
    return {
      'title': recipe.title,
      'description': recipe.description,
      'duration': recipe.duration,
      'yieldText': recipe.yieldText,
      'tags': recipe.tags,
      'isFavorite': recipe.isFavorite,
      'document': recipeDocumentToJson(recipe.document),
    };
  }

  RecipeSummary recipeSummaryFromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      yieldText: json['yieldText'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      document: recipeDocumentFromJson(
        json['document'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  Map<String, dynamic> recipeDocumentToJson(RecipeDocument document) {
    return {
      'prepRows': [
        for (final prepRow in document.prepRows) {'text': prepRow.text},
      ],
      'columns': [
        for (final column in document.columns)
          {
            'id': column.id,
            'widthSpec': columnWidthSpecToJson(column.widthSpec),
            'cells': [
              for (final cell in column.cells)
                {
                  'startRow': cell.startRow,
                  'rowSpan': cell.rowSpan,
                  'columnSpan': cell.columnSpan,
                  'text': cell.text,
                  if (cell.ingredientProductId != null)
                    'ingredientProductId': cell.ingredientProductId,
                  if (cell.ingredientAmount.isNotEmpty)
                    'ingredientAmount': cell.ingredientAmount,
                },
            ],
          },
      ],
    };
  }

  RecipeDocument recipeDocumentFromJson(Map<String, dynamic> json) {
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
              widthSpec: columnWidthSpecFromJson(
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
                      ingredientProductId: cell['ingredientProductId'] as String?,
                      ingredientAmount: normalizedIngredientAmount(
                        cell['ingredientAmount'] as String? ?? '',
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic>? columnWidthSpecToJson(ColumnWidthSpec? widthSpec) {
    if (widthSpec == null) {
      return null;
    }

    return {
      'kind': widthSpec.kind.name,
      'logicalPixels': widthSpec.logicalPixels,
    };
  }

  ColumnWidthSpec? columnWidthSpecFromJson(Map<String, dynamic>? json) {
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
