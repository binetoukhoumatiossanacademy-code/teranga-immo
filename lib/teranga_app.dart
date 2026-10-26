import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'account_service.dart';
import 'annonces_repository.dart';
import 'design_system/design_system.dart';
import 'home_shell.dart';

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
    theme: buildTerangaTheme(),
    home: HomeShell(
      account: account,
      repository: repository,
      configurationError: configurationError,
    ),
  );
}
