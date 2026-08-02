import '../../recipe_document/domain/recipe_document.dart';

class RecipeSummary {
  const RecipeSummary({
    required this.title,
    required this.description,
    required this.duration,
    required this.yieldText,
    required this.document,
    this.tags = const [],
    this.isFavorite = false,
  });

  final String title;
  final String description;
  final String duration;
  final String yieldText;
  final RecipeDocument document;
  final List<String> tags;
  final bool isFavorite;

  RecipeSummary copyWith({
    String? title,
    String? description,
    String? duration,
    String? yieldText,
    RecipeDocument? document,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return RecipeSummary(
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      yieldText: yieldText ?? this.yieldText,
      document: document ?? this.document,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
