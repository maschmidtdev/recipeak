import 'package:flutter/material.dart';

import 'theme/recipeak_theme.dart';
import '../features/recipe_book/presentation/recipe_collection_screen.dart';

class RecipeakApp extends StatelessWidget {
  const RecipeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipeak',
      debugShowCheckedModeBanner: false,
      theme: RecipeakTheme.light(),
      home: const RecipeCollectionScreen(),
    );
  }
}
