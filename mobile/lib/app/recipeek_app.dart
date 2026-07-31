import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_storage.dart';
import 'theme/recipeek_theme.dart';
import '../features/recipe_book/presentation/recipe_collection_screen.dart';
import '../l10n/app_localizations.dart';

class RecipeekApp extends StatefulWidget {
  const RecipeekApp({super.key});

  @override
  State<RecipeekApp> createState() => _RecipeekAppState();
}

class _RecipeekAppState extends State<RecipeekApp> {
  Locale? _locale;
  bool _isLoadingLocale = true;

  @override
  void initState() {
    super.initState();
    _loadPersistedLocale();
  }

  Locale _resolvedDefaultLocale() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (deviceLocale.languageCode == 'de') {
      return const Locale('de');
    }
    return const Locale('en');
  }

  Future<void> _loadPersistedLocale() async {
    final persistedLocale = await AppStorage.instance.loadLocale();
    if (!mounted) {
      return;
    }

    setState(() {
      _locale = persistedLocale ?? _resolvedDefaultLocale();
      _isLoadingLocale = false;
    });
  }

  void _handleLocaleChanged(Locale locale) {
    setState(() {
      _locale = locale;
    });
    AppStorage.instance.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = _locale ?? _resolvedDefaultLocale();

    return MaterialApp(
      locale: activeLocale,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: RecipeekTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: _isLoadingLocale
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : RecipeCollectionScreen(
              localeOverride: activeLocale,
              onLocaleChanged: _handleLocaleChanged,
            ),
    );
  }
}
