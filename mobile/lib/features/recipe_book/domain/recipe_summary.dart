import '../../recipe_document/domain/recipe_document.dart';

class RecipeSummary {
  const RecipeSummary({
    required this.title,
    required this.description,
    required this.duration,
    required this.yieldText,
    required this.document,
    this.isFavorite = false,
    this.isDraft = false,
  });

  final String title;
  final String description;
  final String duration;
  final String yieldText;
  final RecipeDocument document;
  final bool isFavorite;
  final bool isDraft;

  RecipeSummary copyWith({
    String? title,
    String? description,
    String? duration,
    String? yieldText,
    RecipeDocument? document,
    bool? isFavorite,
    bool? isDraft,
  }) {
    return RecipeSummary(
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      yieldText: yieldText ?? this.yieldText,
      document: document ?? this.document,
      isFavorite: isFavorite ?? this.isFavorite,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
