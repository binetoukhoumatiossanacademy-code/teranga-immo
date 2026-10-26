// Alias de transition vers le nouveau design system.
//
// `green` et `sand` restent exportés pour ne pas casser les écrans pas
// encore migrés vers `design_system/` (parcours locataire, propriétaire,
// agence — prochaine phase de la refonte, validée séparément). Ils ne
// pointent plus vers le vert forêt de l'ancien thème : la palette
// vert/charbon a été entièrement retirée de l'application, y compris
// des écrans non encore redessinés.
//
// Nouveaux écrans : importer `design_system/design_system.dart` et ne
// plus utiliser `green` / `sand`.
import 'design_system/design_system.dart';

export 'design_system/design_system.dart';

@Deprecated('Utiliser TerangaColors.gold — conservé pour les écrans non encore migrés.')
const green = TerangaColors.gold;

@Deprecated('Utiliser TerangaColors.ivory — conservé pour les écrans non encore migrés.')
const sand = TerangaColors.ivory;
