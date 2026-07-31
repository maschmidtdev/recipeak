import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app/recipeek_app.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('renders the recipe collection shell', (WidgetTester tester) async {
    await tester.pumpWidget(const RecipeekApp());

    expect(find.text('Recipeek'), findsOneWidget);
    expect(find.text('Visual recipes, not walls of text.'), findsOneWidget);
    expect(find.text('My Recipes'), findsOneWidget);
    expect(find.text('Banana Nut Bread'), findsOneWidget);
    expect(find.text('New Recipe'), findsOneWidget);
  });

  testWidgets('creates a new draft recipe from the new recipe flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RecipeekApp());

    await tester.tap(find.text('New Recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Create Draft'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Roasted Tomatoes');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '2 jars',
    );
    await tester.tap(find.text('Create Draft'));
    await tester.pumpAndSettle();

    expect(find.text('Roasted Tomatoes'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
  });

  testWidgets('edits an existing recipe', (WidgetTester tester) async {
    await tester.pumpWidget(const RecipeekApp());

    await tester.tap(find.text('Banana Nut Bread'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Recipe'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Banana Bread Deluxe');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.text('Banana Bread Deluxe'), findsOneWidget);
    expect(find.text('Banana Nut Bread'), findsNothing);
  });

  testWidgets('deletes an existing recipe from the editor', (WidgetTester tester) async {
    await tester.pumpWidget(const RecipeekApp());

    await tester.tap(find.text('Weeknight Tomato Pasta'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Weeknight Tomato Pasta'), findsNothing);
  });
}
