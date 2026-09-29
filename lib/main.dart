import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_service.dart';
import 'annonces_repository.dart';
import 'app_config.dart';
import 'teranga_app.dart';

export 'detail_page.dart' show DetailPage;
export 'home_art.dart' show HomeArt;
export 'home_shell.dart' show HomeShell;
export 'teranga_app.dart' show TerangaApp;
export 'teranga_theme.dart' show green, sand;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig.fromEnvironment();
  if (!config.isProvided) {
    runApp(const TerangaApp());
    return;
  }
  if (!config.isValid) {
    runApp(
      const TerangaApp(
        configurationError: 'Configuration Supabase incomplète ou invalide.',
      ),
    );
    return;
  }
  try {
    final callbackUri = Uri.base;
    final recoveryLink =
        callbackUri.queryParameters['auth'] == 'recovery' ||
        callbackUri.fragment.contains('type=recovery');
    await Supabase.initialize(
      url: config.url,
      publishableKey: config.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        persistSession: true,
        autoRefreshToken: true,
      ),
    );
    runApp(
      TerangaApp(
        repository: SupabaseAnnoncesRepository(Supabase.instance.client),
        account: AccountController(
          SupabaseAccountGateway(
            Supabase.instance.client,
            redirectUrl: callbackUri.toString().split(RegExp(r'[?#]')).first,
          ),
          recovering: recoveryLink,
        ),
      ),
    );
  } catch (_) {
    runApp(
      const TerangaApp(
        configurationError:
            'Impossible de démarrer la connexion. Veuillez relancer l’application.',
      ),
    );
  }
}
