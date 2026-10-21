import 'package:flutter/material.dart';
import 'account_page.dart';
import 'account_service.dart';
import 'models/account_role.dart';
import 'models/announcement.dart';
import 'tenant_widgets.dart';

/// Parcours visuel propriétaire. Aucune opération d'annonce n'est simulée :
/// le dépôt public existant ne fournit pas encore le service de gestion privée.
class OwnerFlow extends StatefulWidget {
  const OwnerFlow({
    super.key,
    this.account,
    this.onAgency,
    this.onOwner,
    this.role = AccountRole.proprietaire,
  }) : assert(role == AccountRole.proprietaire || role == AccountRole.agence);
  final AccountController? account;
  final VoidCallback? onAgency, onOwner;
  final AccountRole role;
  @override
  State<OwnerFlow> createState() => _OwnerFlowState();
}

class _OwnerFlowState extends State<OwnerFlow> {
  String screen = 'auth';
  bool signup = false, busy = false, preview = false, obscure = true;
  String? message;
  final authForm = GlobalKey<FormState>();
  final draftForm = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{
    for (final key in [
      'agency',
      'name',
      'phone',
      'email',
      'password',
      'confirm',
      'region',
      'city',
      'district',
      'rent',
      'description',
    ])
      key: TextEditingController(),
  };
  HousingType housingType = HousingType.appartement;
  AvailabilityMode availability = AvailabilityMode.maintenant;
  int bedrooms = 1;
  bool furnished = false;
  DateTime? availableFrom;
  bool get authenticated => widget.account?.user != null;
  bool get agency => widget.role == AccountRole.agence;
  // L'accès au profil dépend du rôle confirmé par le serveur, jamais du choix visuel.
  bool get owner => widget.account?.profile?.role == widget.role;
  String get badge => agency ? 'Agence' : 'Propriétaire';
  static const missingTerms =
      'Les conditions d’utilisation officielles ne sont pas encore fournies. Leur acceptation et l’inscription Agence sont indisponibles.';
  String get unavailable => widget.account == null
      ? 'Supabase n’est pas configuré. Connexion, photos, envoi et gestion des annonces indisponibles.'
      : agency
      ? 'Le service de gestion des annonces Agence n’est pas encore raccordé. Aucun envoi, publication ou retrait ne peut être effectué.'
      : 'Le service de gestion des annonces Propriétaire n’est pas encore raccordé. Aucun envoi, publication ou retrait ne peut être effectué.';

  @override
  void initState() {
    super.initState();
    widget.account?.addListener(accountChanged);
    if (authenticated && owner) screen = 'home';
  }

  void accountChanged() {
    if (!mounted) return;
    setState(() {
      if (authenticated && owner && screen == 'auth') {
        screen = 'home';
        preview = false;
      }
      if (!authenticated && !preview) screen = 'auth';
    });
  }

  @override
  void dispose() {
    widget.account?.removeListener(accountChanged);
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void go(String value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      screen = value;
      message = null;
    });
  }

  bool get desktop => MediaQuery.sizeOf(context).width >= 900;

  Widget responsiveSections(List<Widget> first, List<Widget> second) {
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (!desktop) return column([...first, ...second]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: column(first)),
        const SizedBox(width: 32),
        Expanded(child: column(second)),
      ],
    );
  }

  Widget action(
    String label,
    VoidCallback? callback, {
    bool secondary = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 360 : double.infinity),
        child: SizedBox(
          width: double.infinity,
          child: secondary
              ? OutlinedButton(onPressed: callback, child: Text(label))
              : FilledButton(
                  style: tenantPrimaryStyle(),
                  onPressed: callback,
                  child: Text(label),
                ),
        ),
      ),
    ),
  );
  Widget title(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 25,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: tenantGreen,
      ),
    ),
  );
  Widget input(
    String key,
    String label, {
    bool required = true,
    bool password = false,
    int lines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey('owner-$key'),
      controller: fields[key],
      obscureText: password && obscure,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: password
            ? IconButton(
                tooltip: 'Afficher ou masquer le mot de passe',
                onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              )
            : null,
      ),
      validator: (value) {
        final v = value?.trim() ?? '';
        if (required && v.isEmpty) return 'Champ obligatoire';
        if (key == 'agency' && v.length > 160) return '160 caractères maximum';
        if (key == 'name' && v.length > 120) return '120 caractères maximum';
        if (key == 'email' &&
            !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v))
          return 'Adresse e-mail invalide';
        if (key == 'password' && signup && v.length < 8)
          return '8 caractères minimum';
        if (key == 'confirm' && value != fields['password']!.text)
          return 'Les mots de passe ne correspondent pas';
        if (key == 'rent' && (int.tryParse(v) ?? 0) <= 0)
          return 'Indiquez un montant entier positif';
        return null;
      },
    ),
  );
  Future<void> authenticate() async {
    if (agency && signup) return;
    if (!authForm.currentState!.validate() || widget.account == null || busy)
      return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final gateway = widget.account!.gateway;
      if (signup) {
        await gateway.signUp(
          fields['email']!.text.trim(),
          fields['password']!.text,
          name: fields['name']!.text.trim(),
          role: widget.role,
          agencyName: agency ? fields['agency']!.text.trim() : null,
          phoneWhatsApp: fields['phone']!.text.trim(),
        );
        if (mounted)
          setState(
            () => message =
                'Demande traitée par le serveur. Vérifiez votre e-mail pour confirmer votre inscription.',
          );
      } else {
        await gateway.signIn(
          fields['email']!.text.trim(),
          fields['password']!.text,
        );
        await widget.account!.refreshProfile();
        if (mounted && !owner)
          setState(
            () => message =
                'Votre profil $badge n’est pas disponible. Consultez votre compte ou réessayez.',
          );
      }
      accountChanged();
    } catch (_) {
      if (mounted)
        setState(
          () => message =
              'Impossible de terminer la demande. Vérifiez vos informations et votre connexion.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget auth() => Form(
    key: authForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (agency) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Bienvenue dans votre\nespace agence',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: tenantGreen,
              ),
            ),
          ),
          const Text(
            'Trouvez. Valorisez. Ensemble.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4E5261), fontSize: 13),
          ),
          const SizedBox(height: 18),
        ] else
          title('Bienvenue dans votre espace propriétaire'),
        const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 56,
            child: Divider(color: tenantGold, thickness: 3),
          ),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Se connecter')),
            ButtonSegment(value: true, label: Text('S’inscrire')),
          ],
          selected: {signup},
          onSelectionChanged: busy
              ? null
              : (value) => setState(() {
                  signup = value.first;
                  message = null;
                  authForm.currentState?.reset();
                }),
        ),
        const SizedBox(height: 22),
        if (signup) ...[
          if (agency) input('agency', 'Nom de l’agence'),
          input(
            'name',
            agency ? 'Nom et prénom du responsable' : 'Nom et prénom',
          ),
          input(
            'phone',
            agency ? 'Téléphone / WhatsApp' : 'Téléphone',
            keyboard: TextInputType.phone,
          ),
        ],
        input('email', 'E-mail', keyboard: TextInputType.emailAddress),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'La connexion existante utilise votre adresse e-mail.',
            style: TextStyle(fontSize: 11),
          ),
        ),
        input('password', 'Mot de passe', password: true),
        if (signup)
          input('confirm', 'Confirmer le mot de passe', password: true),
        if (!signup)
          TextButton(
            onPressed: widget.account == null ? null : () => go('forgot'),
            child: const Text('Mot de passe oublié ?'),
          ),
        if (agency && signup) ...[
          Row(
            children: [
              const Checkbox(value: false, onChanged: null),
              const Text('J’accepte les ', style: TextStyle(fontSize: 11)),
              Flexible(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Conditions d’utilisation'),
                      content: const Text(missingTerms),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                  child: const Text(
                    'conditions d’utilisation',
                    style: TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const TenantNotice(missingTerms, warning: true),
        ],
        if (widget.account == null) TenantNotice(unavailable),
        if (message != null) TenantNotice(message!, warning: true),
        if (busy) const Center(child: CircularProgressIndicator()),
        action(
          signup
              ? (agency ? 'Créer le compte de l’agence' : 'Créer mon compte')
              : 'Se connecter',
          widget.account == null || busy || agency && signup
              ? null
              : authenticate,
        ),
        TextButton(
          onPressed: () {
            preview = true;
            go('home');
          },
          child: const Text('Consulter les écrans sans connexion'),
        ),
        const SizedBox(height: 18),
        Text(
          agency ? 'Vous êtes propriétaire ?' : 'Vous êtes une agence ?',
          textAlign: TextAlign.center,
        ),
        TextButton(
          onPressed: agency ? widget.onOwner : widget.onAgency,
          child: Text(
            agency
                ? 'Accéder à l’espace Propriétaire →'
                : 'Accéder à l’espace Agence',
          ),
        ),
        if (agency)
          Image.asset(
            'assets/homes/agency_reference_footer.png',
            height: 110,
            fit: BoxFit.contain,
            semanticLabel: 'Décor urbain original de la maquette Agence',
          ),
      ],
    ),
  );
  Widget tile(
    IconData icon,
    String label,
    String target, {
    bool primary = false,
    bool enabled = true,
  }) => Card(
    color: primary
        ? (enabled ? tenantGreen : tenantGreen.withValues(alpha: .42))
        : Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.all(18),
      leading: Icon(icon, color: primary ? Colors.white : tenantGreen),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: primary ? Colors.white : tenantGreen,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: primary ? Colors.white : tenantGreen,
      ),
      onTap: enabled ? () => go(target) : null,
    ),
  );
  Widget home() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title(
        owner
            ? 'Bonjour ${widget.account!.profile!.name}'
            : 'Espace Propriétaire',
      ),
      const Text('Gérez vos logements simplement.'),
      const SizedBox(height: 22),
      responsiveSections(
        [
          tile(
            Icons.add_home_outlined,
            'Proposer un logement',
            'draft',
            primary: true,
          ),
          tile(Icons.home_work_outlined, 'Mes annonces', 'list'),
        ],
        [
          const SizedBox(height: 22),
          const Text(
            'Mes annonces récentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TenantNotice(unavailable),
          action('Voir toutes mes annonces', () => go('list'), secondary: true),
        ],
      ),
    ],
  );
  Widget agencyTile(
    IconData icon,
    String label,
    String description,
    String target,
  ) => Expanded(
    child: Card(
      color: Colors.white,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: () => go(target),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 45, color: tenantGreen),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: tenantInk,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.chevron_right, color: tenantGreen),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget agencyHome() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 18),
      Text(
        owner
            ? widget.account!.profile!.agencyName!
            : 'Espace Agence immobilière',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
      title('Gérez vos logements\nsimplement'),
      responsiveSections(
        [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                agencyTile(
                  Icons.add_home_outlined,
                  'Proposer un logement',
                  'Ajoutez un logement à mettre en location.',
                  'draft',
                ),
                agencyTile(
                  Icons.description_outlined,
                  'Mes annonces',
                  'Consultez et suivez vos annonces.',
                  'list',
                ),
              ],
            ),
          ),
        ],
        [
          const SizedBox(height: 18),
          const Text(
            'Annonces récentes',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: tenantInk,
            ),
          ),
          const SizedBox(height: 12),
          TenantNotice(unavailable),
          action(
            'Voir toutes mes annonces →',
            () => go('list'),
            secondary: true,
          ),
        ],
      ),
    ],
  );
  Widget agencyProfile() {
    final profile = owner ? widget.account!.profile : null;
    final initials = profile?.agencyName
        ?.split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title('Mon profil'),
        responsiveSections(
          [
            Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFD9EEE3),
                child: initials == null
                    ? const Icon(Icons.apartment, color: tenantGreen, size: 40)
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: tenantGreen,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              profile?.agencyName ?? 'Aucune agence connectée',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: tenantInk,
              ),
            ),
            const SizedBox(height: 20),
            agencyProfileField('Responsable', profile?.name),
            agencyProfileField('Téléphone / WhatsApp', profile?.phoneWhatsApp),
            agencyProfileField(
              'E-mail',
              owner ? widget.account!.user!.email : null,
            ),
          ],
          [
            tile(
              Icons.person_outline,
              'Modifier les informations',
              'account',
              enabled: owner,
            ),
            tile(
              Icons.lock_outline,
              'Changer le mot de passe',
              'password',
              enabled: owner,
            ),
            action(
              'Aide et assistance',
              () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Aide et assistance'),
                  content: const Text(
                    'Aucun contact d’assistance officiel n’est configuré dans l’application.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ),
              secondary: true,
            ),
            action(
              'Se déconnecter',
              authenticated ? signOutAgency : null,
              secondary: true,
            ),
            if (!owner) TenantNotice(unavailable),
            if (message != null) TenantNotice(message!, warning: true),
          ],
        ),
      ],
    );
  }

  Widget agencyProfileField(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'Non renseigné',
          style: const TextStyle(color: tenantInk),
        ),
      ],
    ),
  );
  Future<void> signOutAgency() async {
    try {
      await widget.account!.gateway.signOut();
      if (mounted) {
        preview = false;
        go('auth');
      }
    } catch (_) {
      if (mounted)
        setState(() => message = 'La déconnexion n’a pas pu être confirmée.');
    }
  }

  Widget section(IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: tenantGreen, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: tenantGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget photoSlots() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Container(
              height: 62,
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                border: Border.all(color: const Color(0xFFE3E7EA)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
      ],
    ),
  );
  Widget photos() => Container(
    height: 135,
    margin: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: tenantGreen,
          ),
          SizedBox(height: 8),
          Text('Photos du logement'),
          Text('Ajout de photos indisponible', style: TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
  Widget chips<T>(
    String label,
    List<T> values,
    T selected,
    String Function(T) text,
    void Function(T) select,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      Wrap(
        spacing: 8,
        children: [
          for (final value in values)
            ChoiceChip(
              label: Text(text(value)),
              selected: value == selected,
              onSelected: (_) => setState(() => select(value)),
            ),
        ],
      ),
      const SizedBox(height: 14),
    ],
  );
  Widget draft() => Form(
    key: draftForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title('Proposer un logement'),
        responsiveSections(
          [
            section(Icons.camera_alt_outlined, 'Photos du logement'),
            photos(),
            photoSlots(),
            section(Icons.location_on_outlined, 'Où se trouve le logement ?'),
            input('region', 'Région'),
            input('city', 'Ville'),
            input('district', 'Quartier'),
          ],
          [
            section(Icons.home_outlined, 'Le logement'),
            chips(
              'Type de logement',
              HousingType.values,
              housingType,
              (v) => v.databaseValue,
              (v) => housingType = v,
            ),
            chips(
              'Nombre de chambres',
              [1, 2, 3, 4, 5],
              bedrooms,
              (v) => v == 5 ? '5+' : '$v',
              (v) => bedrooms = v,
            ),
            chips(
              'Ameublement',
              [false, true],
              furnished,
              (v) => v ? 'Meublé' : 'Non meublé',
              (v) => furnished = v,
            ),
            input(
              'rent',
              'Prix mensuel (FCFA)',
              keyboard: TextInputType.number,
            ),
            section(Icons.description_outlined, 'Description'),
            input('description', 'Description', lines: 4),
            section(Icons.calendar_month_outlined, 'Disponibilité'),
            chips(
              'Disponibilité',
              AvailabilityMode.values,
              availability,
              (v) => v == AvailabilityMode.maintenant
                  ? 'Maintenant'
                  : 'À partir d’une date',
              (v) => availability = v,
            ),
            if (availability == AvailabilityMode.date)
              OutlinedButton(
                onPressed: () async {
                  final now = DateUtils.dateOnly(DateTime.now());
                  final date = await showDatePicker(
                    context: context,
                    initialDate: availableFrom ?? now,
                    firstDate: now,
                    lastDate: DateTime(now.year + 5),
                  );
                  if (mounted && date != null)
                    setState(() => availableFrom = date);
                },
                child: Text(
                  availableFrom == null
                      ? 'Choisir une date'
                      : '${availableFrom!.day}/${availableFrom!.month}/${availableFrom!.year}',
                ),
              ),
          ],
        ),
        if (message != null) TenantNotice(message!, warning: true),
        action('Continuer', () {
          if (!draftForm.currentState!.validate()) return;
          if (availability == AvailabilityMode.date && availableFrom == null) {
            setState(() => message = 'Choisissez une date de disponibilité.');
            return;
          }
          go('review');
        }),
        const TenantNotice(
          'Votre annonce ne sera pas publiée immédiatement. Teranga Immo la contrôlera avant sa mise en ligne.',
          warning: true,
        ),
        const SizedBox(height: 10),
        const Text(
          'Brouillon local non sauvegardé : quitter ce parcours efface les informations saisies.',
          style: TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Vérifiez votre annonce'),
      const Text(
        'Vérifiez les informations avant de les envoyer à Teranga Immo.',
      ),
      responsiveSections(
        [photos(), photoSlots()],
        [
          title('${fields['rent']!.text} FCFA / mois'),
          Text(
            '${fields['district']!.text}, ${fields['city']!.text}, ${fields['region']!.text}',
          ),
          const SizedBox(height: 12),
          Text(
            '${housingType.databaseValue} · $bedrooms chambre(s) · ${furnished ? 'Meublé' : 'Non meublé'}',
          ),
          const SizedBox(height: 14),
          Text(
            availability == AvailabilityMode.maintenant
                ? 'Disponible maintenant'
                : 'Disponible le ${availableFrom!.day}/${availableFrom!.month}/${availableFrom!.year}',
          ),
          const SizedBox(height: 20),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(fields['description']!.text),
          const SizedBox(height: 20),
          const Text(
            'Contact pour cette annonce',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            owner
                ? widget.account!.profile!.phoneWhatsApp ??
                      widget.account!.user!.email ??
                      'Contact non renseigné'
                : 'Connectez-vous pour renseigner votre contact.',
          ),
          const SizedBox(height: 20),
        ],
      ),
      const TenantNotice(
        'Annonce non publiée · contrôle non commencé',
        warning: true,
      ),
      const SizedBox(height: 12),
      TenantNotice(unavailable),
      action('Modifier', () => go('draft'), secondary: true),
      action('Envoyer à Teranga Immo', null),
      TextButton(
        onPressed: () => go('confirmation'),
        child: const Text('Consulter l’état de l’envoi'),
      ),
    ],
  );
  Widget confirmation() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 25),
      const Icon(Icons.description_outlined, color: tenantGreen, size: 85),
      title('Aucun envoi confirmé'),
      const Text('Votre annonce n’a pas été envoyée à Teranga Immo.'),
      const SizedBox(height: 18),
      TenantNotice(unavailable, warning: true),
      action('Voir mes annonces', () => go('list')),
      action('Retour à l’accueil', () => go('home'), secondary: true),
    ],
  );
  Widget listings() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Mes annonces'),
      responsiveSections(
        [
          const Text('Suivez et gérez vos logements.'),
          action('Proposer un logement', () => go('draft')),
        ],
        [
          const SizedBox(height: 20),
          const Icon(Icons.home_work_outlined, size: 64, color: tenantGreen),
          const SizedBox(height: 12),
          const Text('Aucune annonce chargée', textAlign: TextAlign.center),
          const SizedBox(height: 18),
          TenantNotice(unavailable),
          action(
            'Correction demandée : état indisponible',
            () => go('corrections'),
            secondary: true,
          ),
          action(
            'Gérer mon annonce : état indisponible',
            () => go('manage'),
            secondary: true,
          ),
        ],
      ),
    ],
  );
  Widget corrections() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Correction demandée'),
      const TenantNotice(
        'Aucune demande de correction de l’administration n’a été chargée.',
        warning: true,
      ),
      const SizedBox(height: 20),
      const Text(
        'À corriger',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      TenantNotice(unavailable),
      const SizedBox(height: 15),
      const Text(
        'Après correction et nouvel envoi confirmé, votre annonce sera de nouveau soumise au contrôle de Teranga Immo.',
      ),
      action('Corriger mon annonce', null),
      action('Retour à mes annonces', () => go('list'), secondary: true),
    ],
  );
  Widget manage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Gérer mon annonce'),
      const TenantNotice(
        'Sélectionnez une annonce chargée depuis le serveur pour consulter son état.',
      ),
      const SizedBox(height: 16),
      const Text(
        'La publication et le retrait restent soumis à l’administration. Aucune annonce ne peut être publiée ou retirée depuis cet écran sans confirmation du serveur.',
      ),
      action('Demander le retrait', null),
      action('Retour à mes annonces', () => go('list'), secondary: true),
    ],
  );
  Widget profile() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      title('Mon profil'),
      responsiveSections(
        [
          const Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFE6F1E7),
              child: Icon(Icons.person_outline, color: tenantGreen, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            owner ? widget.account!.profile!.name : 'Aucun compte connecté',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Text('Propriétaire', textAlign: TextAlign.center),
          const SizedBox(height: 15),
          if (owner) ...[
            Text(
              widget.account!.profile!.phoneWhatsApp ??
                  'Téléphone non renseigné',
            ),
            Text(widget.account!.user!.email ?? 'E-mail non renseigné'),
          ],
        ],
        [
          tile(Icons.edit_outlined, 'Modifier mes informations', 'account'),
          tile(Icons.lock_outline, 'Changer mon mot de passe', 'password'),
          action(
            'Se déconnecter',
            authenticated
                ? () async {
                    try {
                      await widget.account!.gateway.signOut();
                      if (mounted) {
                        preview = false;
                        go('auth');
                      }
                    } catch (_) {
                      if (mounted)
                        setState(
                          () => message =
                              'La déconnexion n’a pas pu être confirmée.',
                        );
                    }
                  }
                : null,
            secondary: true,
          ),
          if (message != null) TenantNotice(message!, warning: true),
          action(
            'Aide et assistance',
            () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Aide et assistance'),
                content: const Text(
                  'Aucun contact d’assistance officiel n’est configuré dans l’application.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
            secondary: true,
          ),
        ],
      ),
    ],
  );
  Widget passwordPage({bool reset = false}) => Form(
    key: authForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title(reset ? 'Mot de passe oublié' : 'Changer mon mot de passe'),
        if (reset)
          input('email', 'E-mail', keyboard: TextInputType.emailAddress)
        else ...[
          input('password', 'Nouveau mot de passe', password: true),
          input('confirm', 'Confirmer le mot de passe', password: true),
        ],
        if (widget.account == null) TenantNotice(unavailable),
        if (message != null) TenantNotice(message!),
        action(
          reset
              ? 'Envoyer le lien de récupération'
              : 'Enregistrer le mot de passe',
          widget.account == null || busy
              ? null
              : () async {
                  if (!authForm.currentState!.validate()) return;
                  if (!reset && fields['password']!.text.length < 8) {
                    setState(() => message = '8 caractères minimum');
                    return;
                  }
                  setState(() {
                    busy = true;
                    message = null;
                  });
                  try {
                    if (reset) {
                      await widget.account!.gateway.reset(
                        fields['email']!.text.trim(),
                      );
                    } else {
                      await widget.account!.changePassword(
                        fields['password']!.text,
                      );
                    }
                    if (mounted)
                      setState(
                        () => message = reset
                            ? 'Demande traitée. Si cette adresse correspond à un compte, consultez votre e-mail.'
                            : 'Votre mot de passe a été modifié.',
                      );
                  } catch (_) {
                    if (mounted)
                      setState(
                        () => message =
                            'La demande n’a pas pu être confirmée par le serveur.',
                      );
                  } finally {
                    if (mounted) setState(() => busy = false);
                  }
                },
        ),
        action('Retour', () => go(reset ? 'auth' : 'profile'), secondary: true),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final mainPage = ['home', 'draft', 'list', 'profile'].contains(screen);
    final body = switch (screen) {
      'auth' => auth(),
      'forgot' => passwordPage(reset: true),
      'password' => passwordPage(),
      'home' => agency ? agencyHome() : home(),
      'draft' => draft(),
      'review' => review(),
      'confirmation' => confirmation(),
      'list' => listings(),
      'corrections' => corrections(),
      'manage' => manage(),
      'profile' => agency ? agencyProfile() : profile(),
      _ => AccountPage(account: widget.account, initialRole: widget.role),
    };
    final selectedIndex = switch (screen) {
      'draft' || 'review' => 1,
      'list' || 'corrections' || 'manage' || 'confirmation' => 2,
      'profile' || 'account' || 'password' => 3,
      _ => 0,
    };
    return Scaffold(
      backgroundColor: tenantBackground,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop && screen != 'auth' && screen != 'forgot')
            SafeArea(
              child: NavigationRail(
                backgroundColor: tenantBackground,
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (index) =>
                    go(['home', 'draft', 'list', 'profile'][index]),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    label: Text('Accueil'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.add_circle_outline),
                    label: Text('Proposer'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.home_work_outlined),
                    label: Text('Mes annonces'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    label: Text('Profil'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width < 700
                        ? 440
                        : 1240,
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('owner-scroll-$screen'),
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (screen != 'auth' && !mainPage)
                              IconButton(
                                tooltip: 'Retour',
                                onPressed: () => go(switch (screen) {
                                  'review' => 'draft',
                                  'forgot' => 'auth',
                                  'account' || 'password' => 'profile',
                                  _ => 'list',
                                }),
                                icon: const Icon(Icons.arrow_back),
                              ),
                            Image.asset(
                              'assets/brand/logo_original.png',
                              width: 76,
                              height: 76,
                              semanticLabel: 'Logo original Teranga Immo',
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F1E7),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: tenantGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (preview && screen != 'auth')
                          const TenantNotice(
                            'Aperçu sans connexion. Aucun compte ni aucune annonce n’a été créé.',
                          ),
                        if (desktop &&
                            [
                              'auth',
                              'forgot',
                              'password',
                              'account',
                              'confirmation',
                              'corrections',
                              'manage',
                            ].contains(screen))
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 640),
                              child: body,
                            ),
                          )
                        else
                          body,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (desktop || screen == 'auth' || screen == 'forgot')
          ? null
          : SafeArea(
              top: false,
              child: Align(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width < 700
                        ? 440
                        : 1240,
                  ),
                  child: NavigationBar(
                    selectedIndex: switch (screen) {
                      'draft' || 'review' => 1,
                      'list' ||
                      'corrections' ||
                      'manage' ||
                      'confirmation' => 2,
                      'profile' || 'account' || 'password' => 3,
                      _ => 0,
                    },
                    onDestinationSelected: (index) =>
                        go(['home', 'draft', 'list', 'profile'][index]),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home_outlined),
                        label: 'Accueil',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.add_circle_outline),
                        label: 'Proposer',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.home_work_outlined),
                        label: 'Mes annonces',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline),
                        label: 'Profil',
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
