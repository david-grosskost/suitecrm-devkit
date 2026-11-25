# Pièges déjà rencontrés

À lire quand une vérification échoue ou qu'un comportement surprend : la plupart des erreurs ont déjà été vues. Ajouter ici chaque nouveau piège, avec sa cause et sa solution.

- PHPStan « Cannot access an offset on mixed » sur `$hook_array` : il manque l'annotation
  `@var` de logic-hook.md.
- Hook global déclaré avec `array $arguments` : SuiteCRM passe `null`, erreur fatale sur
  **chaque page** et conteneur qui redémarre en boucle. Toujours `mixed $arguments = null`.
- Première release en 0.2.0 au lieu de 0.1.0 : `.release-please-manifest.json` pas remis à
  `0.0.0`.
- Release qui échoue (« GitHub Actions is not permitted to create pull requests ») :
  réglage Actions du dépôt pas fait (étape 3 du SKILL.md).
- Merge impossible alors que tout est vert : la règle de `main` exige une approbation, que
  l'auteur ne peut pas se donner. La règle doit être à **0 approbation** (voir
  `docs/reglages-github.md` du devkit) ; d'ici là, un administrateur merge en contournant.
- Essai dans le core : « could not be found in any version » alors que la branche est
  poussée : le paquet porte encore le nom du modèle sur `main` (étape 3 du SKILL.md).
- `/docker-entrypoint.sh: exec: update: not found` : `composer.json` invalide (virgule
  finale) ; le vérifier avec
  `MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/app -w /app composer:2 composer validate --no-check-publish`.
- Champs créés mais panneau absent de la fiche : fiche en onglets, panneau absent de
  `tabDefs` (champs.md). Vérifier ce que renvoie l'API avant de chercher ailleurs.
- Un champ du panneau prend toute la ligne : case vide notée `(empty)` au lieu de
  `(filler)`.
- `Class "SuiteCrmExt\…" not found` dans les tests après un changement d'`autoload-dev` :
  autoload pas régénéré, `make composer@install`.
- Un commit parti alors qu'une vérification a échoué : enchaîner vérifications et commit sur
  une seule ligne, avec `&&`.
- Studio dans le navigateur : le modifier depuis SuiteCRM (Administration → Studio) ; un
  redémarrage de l'app déconnecte les sessions.
- PHPStan « Cannot access an offset on mixed » sur `$dictionary`, `$mod_strings` ou
  `$app_list_strings` : il manque le `@var` qui décrit chaque niveau du tableau.
- Contrôle de saisie qui bloque la fiche sans message : libellé dans `$mod_strings` au lieu
  de `$app_strings`. Qui ne se déclenche pas : `asyncValidators` mis dans `Ext/Vardefs`
  (controle-de-saisie.md) ; vérifier le `fieldDefinition` que renvoie l'API.
- « Une erreur s'est produite lors de l'enregistrement » sur toute sauvegarde : le hook
  utilise une classe que son fichier ne charge pas (logic-hook.md).
- Tâche planifiée qui tourne dès l'activation, et non à l'heure prévue : `catch_up` à `1`
  (l'heure du jour est déjà passée, SuiteCRM la rattrape). Mettre `0` (planificateur-et-administration.md).
- PHPStan « Call to an undefined method » sur une méthode de SuiteCRM (ex. `fetchByAssoc`,
  `mark_deleted`) : le stub du devkit ne la déclare pas. L'y ajouter avec la signature exacte de
  SuiteCRM, publier une version du devkit (tag), et demander cette version dans le
  `composer.json` de l'extension (`^0.21.3`) ; jamais d'exception dans PHPStan. Une classe
  absente du stub du devkit (ex. `SugarView`) peut aller dans `tests/stubs/` de l'extension.
- Un `require_once` d'un fichier de SuiteCRM en tête d'un fichier de classe : PHPStan l'exécute
  en chargeant la classe et échoue. Le mettre dans le script qui utilise la classe.
- Pour essayer une tâche planifiée sans attendre : passer son `job_interval` à
  `*::*::*::*::*` en base, attendre deux minutes, lire `job_queue` (`status` `done`,
  `resolution` `success`), puis remettre l'horaire. Garder le réglage réel pendant l'essai : un
  délai abaissé (1 jour) relance aussi tout le volume généré.
- Module Angular chargé (`remoteEntry.js` en 200) mais sans effet : le code est dans `init()`,
  que SuiteCRM 8.10 n'appelle pas. Le mettre dans le constructeur (module-angular.md).
- Montants « 67 300 00 € » (virgule décimale perdue) : locale `fr-FR` donnée au
  `CurrencyFormatter`. SuiteCRM remplace lui-même les séparateurs par ceux de l'utilisateur ;
  partir de la locale `en` et ne changer que le motif (`#,##0.00 ¤`).
- `make front@check` en échec alors que rien n'a changé : `public/` construit hors de
  `make front@build` (autre chemin, autre version de SuiteCRM). Le résultat dépend du chemin
  des sources : toujours construire avec `make front@build`.
- `front@build` : « angular.json introuvable » avant `build:core` : lancer
  `yarn merge-angular-json` d'abord (le script du devkit le fait).
- Sans `make git@pr` (gh pas connecté) : pousser la branche, puis ouvrir la PR sur GitHub
  (lien affiché par `git push`) en recopiant le titre du commit quand la branche en a plusieurs.
- Seeder qui écrit une date de modification passée (`date_modified`) : `save()` la remet à
  maintenant. Mettre `$bean->update_date_modified = false` avant `$seed->update(…)`, plutôt
  qu'un `UPDATE` SQL que le compte des enregistrements ne voit pas (devkit 0.23 pour PHPStan).
- Menu des modules vide dans toute l'interface après l'installation d'une extension, sans
  trace dans aucun log : un lien de l'administration **sans module**. SuiteCRM 8 convertit
  chaque lien de `$admin_group_header` (`RouteConverterHandler::convert`) et lève « No module
  defined » sur un lien sans `module=` ; rien ne l'attrape, la requête des métadonnées échoue
  entière. Une page d'administration est donc une **action du module Administration**
  (`./index.php?module=Administration&action=<Action>`, voir
  planificateur-et-administration.md), jamais un point d'entrée. Ce fichier ne contient que
  des tableaux (SuiteCRM le charge deux fois par `require`), et n'**affecte** jamais
  `$admin_option_defs` d'une autre extension : en ajouter, c'est tout. Exemple :
  `custom-theme`.
- Extension mise à jour, rien ne change dans le navigateur : `remoteEntry.js` est le seul
  fichier du module fédéré **sans empreinte dans son nom**, et Apache ne pose aucun
  `Cache-Control`. Le navigateur sert l'ancienne table des matières, donc l'ancien code.
  Ctrl+Shift+R pour essayer ; distinguer le cache du paquet en comparant
  `fetch(url)` et `fetch(url, {cache:'reload'})`.
- Icône ou élément ajouté à une entrée de menu qui disparaît à chaque changement d'écran :
  Angular **recrée tout le menu** (une entrée sur trente survit). Faire peindre par la
  feuille de style plutôt qu'ajouter : rien dans le balisage ne nomme le module, mais
  `:has(a[href*="return_module=X&"])` atteint les adresses de son sous-menu, et une règle
  par module s'applique dès que SuiteCRM dessine l'entrée.
- Libellé périmé sur une entrée de menu (le nom d'un module, le sous-menu d'un autre) :
  la décoration a vidé le lien pour y mettre son contenu. Angular réutilise ces éléments
  pour d'autres modules ; **ajouter autour** de ce qu'il écrit, jamais détruire, et comparer
  à chaque passe le module que l'entrée désigne pour refaire la décoration quand il change.
- Masquer un libellé avec `opacity: 0` lui laisse sa largeur : un centrage le compte encore.
  Le sortir du flux (`display: none`) quand la place manque.
- `repair.php` ou tout script PHP lancé sans `-u www-data` : le cache Symfony est recréé en
  root, Apache ne peut plus l'écrire, l'instance répond 500 **sans rien journaliser**.
  Vérifier avec `ls -ld cache cache/prod`, réparer avec un `chown -R www-data:www-data`.
- SuiteCRM n'affiche que huit modules dans son menu et replie le reste dans « Options », qui
  ne porte pas les sous-menus. Deux plafonds à lever : `default_max_tabs` côté historique
  (par `Configurator::handleOverride()` à l'installation) et `themes.navigation_tab_limits`
  côté SuiteCRM 8. Le second se surcharge **depuis l'extension** : SuiteCRM importe de
  lui-même `../extensions/*/config/services/*.yaml` et `config/packages/*.yaml`, donc rien
  du cœur n'est touché.
- `make extension@validate` : « dossier « docs » non prévu » : devkit antérieur à 0.29.1.
  Monter le devkit (`composer.json` `^0.29` et workflows `@v0.29.1`, ensemble).
- `make db@seed` : « Failed opening required '…/extensions/seeders/<slug>/…/legacy/…' » : le
  seeder charge une classe par un chemin relatif vers `legacy/`, absent de l'image (voir
  scripts-et-donnees-de-demo.md).
- `checks / commit-msg` en échec sur le titre de la pull request : plus de 72 caractères. Le
  raccourcir sur GitHub (le contrôle repart) ; viser 65, GitHub ajoute ` (#NN)` au merge.
- La pull request de release (« chore(main): release x.y.z ») ne lance pas sa CI : elle a été
  ouverte avec le jeton de GitHub Actions. **Approve workflows to run** dans la PR, puis la
  merger (dérogation administrateur, voir `docs/reglages-github.md` du devkit).
- Libellé encore en anglais alors qu'il est traduit dans l'extension : cache de SuiteCRM 8.
  `make app@repair` (réparation rapide et vidage de `cache/prod`), puis Ctrl+F5. Un texte écrit
  en dur dans un template Angular de SuiteCRM (« Back To Top » du pied de page) n'est pas un
  libellé : aucune traduction ne l'atteint.
- Une route de SuiteCRM 8 vers un écran historique respecte la casse de l'action :
  `#/administration/UpgradeWizard?view=module`, pas `upgradewizard` (page blanche).
- Chargeur de module : les deux listes se superposent, sans barre de défilement. Les tableaux
  (YUI) calculent leur hauteur à l'affichage ; affichés pendant que l'onglet n'était pas
  visible (navigateur piloté), ils la prennent nulle. F5 remet tout en place : un défaut de
  SuiteCRM, pas de l'extension.
- Nom affiché « DUPONT &AMP; FILS » après un hook qui met en majuscules : la valeur du `$bean`
  était encodée en HTML. Décoder, transformer, ré-encoder (logic-hook.md).
