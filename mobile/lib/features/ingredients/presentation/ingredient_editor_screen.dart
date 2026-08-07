import 'dart:math';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../recipe_book/presentation/widgets/editor_form_widgets.dart';
import '../domain/ingredient_cell_text.dart';
import '../domain/ingredient_number_input.dart';
import '../domain/ingredient_product.dart';
import 'ingredient_tag_labels.dart';

class IngredientEditorScreen extends StatefulWidget {
  const IngredientEditorScreen({
    super.key,
    required this.initialIngredient,
    required this.availableTags,
  });

  final IngredientProduct initialIngredient;
  final List<String> availableTags;

  @override
  State<IngredientEditorScreen> createState() => _IngredientEditorScreenState();
}

class _IngredientEditorScreenState extends State<IngredientEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _priceController;
  late final TextEditingController _storeController;
  late final TextEditingController _kcalController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final Set<String> _selectedTags;
  late IngredientBaseUnit _baseUnit;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.initialIngredient;
    _nameController = TextEditingController(text: ingredient.name);
    _amountController = TextEditingController(
      text: normalizedIngredientAmount(ingredient.amount),
    );
    _priceController = TextEditingController(text: ingredient.price);
    _storeController = TextEditingController(text: ingredient.store);
    _kcalController = TextEditingController(text: _formatMacro(ingredient.kcal));
    _proteinController = TextEditingController(
      text: _formatMacro(ingredient.protein),
    );
    _carbsController = TextEditingController(text: _formatMacro(ingredient.carbs));
    _fatController = TextEditingController(text: _formatMacro(ingredient.fat));
    _baseUnit = ingredient.baseUnit;
    _selectedTags = {...ingredient.tags};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isNewIngredient = widget.initialIngredient.name.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isNewIngredient
              ? localizations.newIngredient
              : localizations.editIngredient,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            children: [
              FieldLabel(
                label: localizations.ingredientNameLabel,
                child: TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.ingredientNameHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.ingredientNameRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                label: localizations.ingredientAmountLabel,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.ingredientAmountHint,
                    suffixText: _baseUnit.storageValue,
                  ),
                  validator: (value) => _validateOptionalNumber(
                    value,
                    localizations,
                    IngredientNumberRule.positive,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                label: localizations.ingredientBaseUnitLabel,
                child: DropdownButtonFormField<IngredientBaseUnit>(
                  initialValue: _baseUnit,
                  decoration: InputDecoration(
                    hintText: localizations.ingredientBaseUnitLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: IngredientBaseUnit.grams,
                      child: Text(localizations.ingredientBaseUnitGrams),
                    ),
                    DropdownMenuItem(
                      value: IngredientBaseUnit.milliliters,
                      child: Text(localizations.ingredientBaseUnitMilliliters),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _baseUnit = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                label: localizations.ingredientPriceLabel,
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.ingredientPriceHint,
                  ),
                  validator: (value) => _validateOptionalNumber(
                    value,
                    localizations,
                    IngredientNumberRule.positive,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                label: localizations.ingredientStoreLabel,
                child: TextFormField(
                  controller: _storeController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: localizations.ingredientStoreHint,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.nutritionPer100Label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MacroField(
                      controller: _kcalController,
                      label: localizations.ingredientKcalLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroField(
                      controller: _proteinController,
                      label: localizations.ingredientProteinLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MacroField(
                      controller: _carbsController,
                      label: localizations.ingredientCarbsLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MacroField(
                      controller: _fatController,
                      label: localizations.ingredientFatLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                localizations.tagsTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in widget.availableTags)
                    FilterChip(
                      label: Text(ingredientTagLabel(localizations, tag)),
                      selected: _selectedTags.contains(tag),
                      showCheckmark: false,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(32, 12, 32, 20),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: Text(localizations.discard),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _saveIngredient,
                icon: const Icon(Icons.check),
                label: Text(localizations.save),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveIngredient() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      IngredientProduct(
        id: widget.initialIngredient.id.trim().isEmpty
            ? _newIngredientId()
            : widget.initialIngredient.id,
        name: _nameController.text.trim(),
        amount: normalizeIngredientNumberInput(_amountController.text),
        price: normalizeIngredientNumberInput(_priceController.text),
        store: _storeController.text.trim(),
        kcal: _parseMacro(_kcalController.text),
        protein: _parseMacro(_proteinController.text),
        carbs: _parseMacro(_carbsController.text),
        fat: _parseMacro(_fatController.text),
        baseUnit: _baseUnit,
        tags: [..._selectedTags]..sort(),
      ),
    );
  }

  String _newIngredientId() {
    return 'ingredient-${_uuidV4()}';
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return [
      hex.substring(0, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
      hex.substring(16, 20),
      hex.substring(20),
    ].join('-');
  }

  double _parseMacro(String value) {
    return parseIngredientNumberInput(value) ?? 0;
  }

  String _formatMacro(double value) {
    if (value == 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

String? _validateOptionalNumber(
  String? value,
  AppLocalizations localizations,
  IngredientNumberRule rule,
) {
  if (isValidOptionalIngredientNumber(value ?? '', rule: rule)) {
    return null;
  }
  return switch (rule) {
    IngredientNumberRule.positive => localizations.ingredientPositiveNumberError,
    IngredientNumberRule.nonNegative =>
      localizations.ingredientNonNegativeNumberError,
  };
}

class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) => _validateOptionalNumber(
        value,
        AppLocalizations.of(context),
        IngredientNumberRule.nonNegative,
      ),
    );
  }
}
