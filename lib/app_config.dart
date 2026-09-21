class AppConfig {
  const AppConfig({required this.url, required this.publishableKey});

  const AppConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      publishableKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  final String url;
  final String publishableKey;

  bool get isProvided => url.isNotEmpty || publishableKey.isNotEmpty;
  bool get isValid {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.isNotEmpty &&
        publishableKey.startsWith('sb_publishable_');
  }
}
