# Tâche planifiée et page d'administration

Types `scheduler` et `ui`, validé (opportunity-reminders, pwa, login-background, custom-theme).

Exemple complet : `suitecrm-ext-opportunity-reminders`.

**La tâche planifiée** : `legacy/Extension/modules/Schedulers/Ext/ScheduledTasks/<slug>.php`
ajoute le nom d'une fonction à `$job_strings` (`/** @var list<string> $job_strings */`) et
la déclare (`if (!function_exists(…))`, signature `function <nom>(mixed $job = null): bool`).
La fonction charge sa classe (`require_once getcwd() . '/custom/include/<slug>/<Classe>.php'`)
et renvoie `true` (succès dans `job_queue`). Son nom dans la liste « Tâche » du planificateur :
`$mod_strings['LBL_<NOM EN MAJUSCULES>']` dans
`legacy/Extension/modules/Schedulers/Ext/Language/`. Le cron du core
(`bin/console schedulers:run`, chaque minute) l'appelle en administrateur.

- **La ligne du planificateur** (Administration → Planificateur) : créée par
  `database/install.php` (bean `Schedulers` : `job` = `function::<nom>`, `job_interval`
  `minute::heure::jour::mois::jour de semaine` à l'heure de l'administrateur, `status`
  `Active`, **`catch_up` `0`**), supprimée par `database/uninstall.php` (`mark_deleted`).
  Ne rien créer si une ligne non supprimée a déjà ce `job` : elle appartient à
  l'administrateur, qui peut changer l'horaire ou la rendre inactive.
- Lire des lignes en base : `$db->query()` puis `$db->fetchByAssoc($result, false)` (valeurs
  telles que stockées, déjà encodées en HTML : `d&#039;essais`).

**Un réglage** : dans la table des réglages de SuiteCRM, sans fichier de configuration.
`BeanFactory::newBean('Administration')`, `retrieveSettings('<categorie>', true)` puis
`$admin->settings['<categorie>_<cle>']` pour lire, `saveSetting('<categorie>', '<cle>', $valeur)`
pour écrire. Toujours une valeur par défaut quand rien de valide n'est enregistré.

**La page d'administration** (legacy, s'affiche dans SuiteCRM 8) :

- l'entrée : `legacy/Extension/modules/Administration/Ext/Administration/<slug>.php` ajoute un
  groupe à `$admin_group_header` (`[titre, '', false, $admin_option_defs, description, icône]`,
  lien `./index.php?module=Administration&action=<Action>`) ; libellés dans
  `legacy/Extension/modules/Administration/Ext/Language/` ;
- l'action : `legacy/Extension/modules/Administration/Ext/ActionFileMap/<slug>.php`
  (`$action_file_map['<action en minuscules>'] = 'custom/include/<slug>/<Page>.php'`) : le
  contrôleur charge ce fichier, `$mod_strings` contenant les libellés d'Administration ;
- le fichier vérifie `is_admin($current_user)` (sinon `sugar_die`), traite le formulaire, puis
  affiche dans la page de SuiteCRM (en-tête, styles) par une sous-classe de `SugarView` dont
  `display()` écrit le HTML : `new <Vue>(…)`, `->init()`, `->process()`. Charger
  `getcwd() . '/include/MVC/View/SugarView.php'` dans ce fichier, **pas** dans celui de la
  classe ;
- la logique (ce que fait le formulaire, le HTML échappé) dans une classe pure, testée.

Un bouton « lancer maintenant » sur la page sert en démo : on n'attend pas l'heure prévue.
