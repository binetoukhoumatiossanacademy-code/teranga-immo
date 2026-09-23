import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.account});
  final AccountController? account;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  final name = TextEditingController();
  final agency = TextEditingController();
  String mode = 'login', type = 'proprietaire';
  String? message;
  bool busy = false;
  AccountProfile? _shownProfile;
  String? _shownId;

  @override
  void initState() {
    super.initState();
    widget.account?.addListener(changed);
    sync();
  }

  void sync() {
    final account = widget.account;
    if (_shownId != account?.user?.id || _shownProfile != account?.profile) {
      _shownId = account?.user?.id;
      _shownProfile = account?.profile;
      final data =
          account?.profile ??
          AccountProfile.fromJson(account?.user?.userMetadata ?? {});
      name.text = data.name;
      agency.text = data.agency;
      type = data.type;
      password.clear();
      confirmation.clear();
      message = null;
      if (account?.user == null) mode = 'login';
    }
  }

  void changed() {
    if (mounted) setState(sync);
  }

  @override
  void dispose() {
    widget.account?.removeListener(changed);
    for (final controller in [email, password, confirmation, name, agency]) {
      controller.dispose();
    }
    super.dispose();
  }

  void switchMode(String value) => setState(() {
    mode = value;
    message = null;
    password.clear();
    confirmation.clear();
    form.currentState?.reset();
  });

  Future<void> perform(Future<void> Function() action, String success) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await action();
      if (mounted) setState(() => message = success);
    } on AuthException catch (error) {
      if (mounted)
        setState(
          () => message = switch (error.code) {
            'invalid_credentials' => 'Email ou mot de passe incorrect.',
            'email_not_confirmed' =>
              'Confirmez votre email avant de vous connecter.',
            'over_email_send_rate_limit' || 'over_request_rate_limit' =>
              'Trop de demandes. Patientez avant de réessayer.',
            'weak_password' => 'Choisissez un mot de passe plus robuste.',
            _ =>
              'Impossible de terminer cette action. Vérifiez les informations et réessayez.',
          },
        );
    } catch (_) {
      if (mounted)
        setState(
          () => message =
              'Service indisponible. Vérifiez votre connexion et réessayez.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    bool secret = false,
    bool isEmail = false,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: secret,
      enabled: !busy,
      autocorrect: !secret && !isEmail,
      enableSuggestions: !secret,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value ?? '';
        if (required && text.trim().isEmpty) return 'Ce champ est obligatoire.';
        if (label == 'Nom' && text.trim().length > 120)
          return '120 caractères maximum.';
        if (label == 'Nom de l’agence' && text.trim().length > 160)
          return '160 caractères maximum.';
        if (isEmail &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text.trim())) {
          return 'Saisissez une adresse email valide.';
        }
        if (secret &&
            label != 'Confirmer le mot de passe' &&
            (mode == 'signup' || widget.account!.recovering) &&
            text.length < 8) {
          return 'Utilisez au moins 8 caractères.';
        }
        if (label == 'Confirmer le mot de passe' && text != password.text) {
          return 'Les mots de passe ne correspondent pas.';
        }
        return null;
      },
    ),
  );

  List<Widget> profileFields() => [
    field('Nom', name),
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: type,
        decoration: const InputDecoration(labelText: 'Type de compte'),
        items: const [
          DropdownMenuItem(value: 'proprietaire', child: Text('Propriétaire')),
          DropdownMenuItem(value: 'agence', child: Text('Agence')),
        ],
        onChanged: busy ? null : (value) => setState(() => type = value!),
      ),
    ),
    if (type == 'agence') field('Nom de l’agence', agency),
  ];
  AccountProfile get value =>
      AccountProfile(name: name.text, type: type, agency: agency.text);

  Widget submit(String label, Future<void> Function() action, String success) =>
      FilledButton(
        onPressed: busy
            ? null
            : () {
                if (form.currentState!.validate()) perform(action, success);
              },
        child: Text(label),
      );

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    if (account == null)
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Les comptes nécessitent une connexion Supabase configurée.',
        ),
      );
    final signedIn = account.user != null;
    final recovery = signedIn && account.recovering;
    final title = recovery
        ? 'Nouveau mot de passe'
        : signedIn
        ? 'Mon profil'
        : switch (mode) {
            'signup' => 'Créer un compte',
            'forgot' => 'Mot de passe oublié',
            'confirm' => 'Confirmez votre email',
            _ => 'Se connecter',
          };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  if (account.loading || busy) const LinearProgressIndicator(),
                  if (account.message != null) ...[
                    Text(account.message!),
                    TextButton(
                      onPressed: busy ? null : account.refreshProfile,
                      child: const Text('Réessayer le chargement'),
                    ),
                  ],
                  if (recovery) ...[
                    field('Nouveau mot de passe', password, secret: true),
                    field(
                      'Confirmer le mot de passe',
                      confirmation,
                      secret: true,
                    ),
                    submit('Enregistrer le mot de passe', () async {
                      await account.changePassword(password.text);
                      password.clear();
                      confirmation.clear();
                    }, 'Votre mot de passe a été modifié.'),
                  ] else if (signedIn) ...[
                    Text(account.user!.email ?? ''),
                    const SizedBox(height: 16),
                    if (!account.loading && account.message == null) ...[
                      if (account.profile == null)
                        const Text(
                          'Complétez votre profil pour terminer votre inscription.',
                        ),
                      ...profileFields(),
                      submit(
                        'Enregistrer mon profil',
                        () => account.save(value),
                        'Profil enregistré.',
                      ),
                    ],
                  ] else ...[
                    if (mode == 'confirm')
                      const Text(
                        'Si votre inscription peut être effectuée, un email de confirmation vous sera envoyé. Ouvrez le lien, puis complétez votre profil.',
                      ),
                    field('Email', email, isEmail: true),
                    if (mode == 'login' || mode == 'signup')
                      field('Mot de passe', password, secret: true),
                    if (mode == 'signup') ...[
                      field(
                        'Confirmer le mot de passe',
                        confirmation,
                        secret: true,
                      ),
                      ...profileFields(),
                    ],
                    if (mode == 'login') ...[
                      submit('Se connecter', () async {
                        await account.gateway.signIn(
                          email.text.trim(),
                          password.text,
                        );
                        password.clear();
                      }, 'Connexion réussie.'),
                      TextButton(
                        onPressed: busy ? null : () => switchMode('signup'),
                        child: const Text('Créer un compte'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => switchMode('forgot'),
                        child: const Text('Mot de passe oublié ?'),
                      ),
                      TextButton(
                        onPressed: busy ? null : () => switchMode('confirm'),
                        child: const Text('Renvoyer la confirmation'),
                      ),
                    ],
                    if (mode == 'signup')
                      submit(
                        'Créer mon compte',
                        () async {
                          await account.gateway.signUp(
                            email.text.trim(),
                            password.text,
                            value,
                          );
                          password.clear();
                          confirmation.clear();
                          if (mounted) setState(() => mode = 'confirm');
                        },
                        'Consultez votre boîte email et les courriers indésirables.',
                      ),
                    if (mode == 'forgot')
                      submit(
                        'Envoyer le lien',
                        () => account.gateway.reset(email.text.trim()),
                        'Si un compte correspond à cet email, vous recevrez un lien de réinitialisation.',
                      ),
                    if (mode == 'confirm')
                      submit(
                        'Renvoyer l’email',
                        () => account.gateway.resend(email.text.trim()),
                        'Si une confirmation est nécessaire, un nouvel email vous sera envoyé.',
                      ),
                    if (mode != 'login')
                      TextButton(
                        onPressed: busy ? null : () => switchMode('login'),
                        child: const Text('Retour à la connexion'),
                      ),
                  ],
                  if (signedIn)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => perform(
                              account.gateway.signOut,
                              'Vous êtes déconnecté.',
                            ),
                      child: const Text('Se déconnecter'),
                    ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(message!, semanticsLabel: message),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'La consultation des annonces reste accessible sans compte.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
