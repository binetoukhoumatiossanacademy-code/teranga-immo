import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'account_service.dart';
import 'annonces_repository.dart';
import 'home_shell.dart';
import 'teranga_theme.dart';

class TerangaApp extends StatelessWidget {
  const TerangaApp({
    super.key,
    this.repository,
    this.configurationError,
    this.account,
  });
  final AccountController? account;
  final AnnoncesRepository? repository;
  final String? configurationError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Teranga Immo',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      fontFamily: 'Poppins',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
      scaffoldBackgroundColor: sand,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(),
      ),
    ),
    home: HomeShell(
      account: account,
      repository: repository,
      configurationError: configurationError,
    ),
  );
}
