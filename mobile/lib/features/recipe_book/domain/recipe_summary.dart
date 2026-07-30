class RecipeSummary {
  const RecipeSummary({
    required this.title,
    required this.description,
    required this.duration,
    required this.yieldText,
    this.isFavorite = false,
    this.isDraft = false,
  });

  final String title;
  final String description;
  final String duration;
  final String yieldText;
  final bool isFavorite;
  final bool isDraft;

  RecipeSummary copyWith({
    String? title,
    String? description,
    String? duration,
    String? yieldText,
    bool? isFavorite,
    bool? isDraft,
  }) {
    return RecipeSummary(
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      yieldText: yieldText ?? this.yieldText,
      isFavorite: isFavorite ?? this.isFavorite,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
