---
name: nouvelle-extension
description: Guide la création ou la modification d'une extension SuiteCRM 8 (dépôt suitecrm-ext-<slug>, créé depuis suitecrm-extension-template), de l'entretien sur le besoin métier jusqu'à la pull request, y compris avec une personne sans connaissance technique. À utiliser quand on demande d'ajouter un comportement à SuiteCRM (« quand on enregistre un compte… », « ajouter un champ… », « corriger tel bug de SuiteCRM ») ou de changer une extension existante.
---

# Créer ou modifier une extension SuiteCRM

Principe : **le skill guide, la CI garantit.** Tu fais le travail technique ; la personne
décrit le besoin et valide le résultat. Les vérifications (`make …`, CI, relecture humaine)
ne se contournent jamais : si l'une échoue, on corrige, on ne la désactive pas.

Ce skill ne couvre que ce qui a été **réellement validé** sur une instance SuiteCRM. Un
type marqué « pas encore validé » plus bas : explique-le, propose de faire appel à un
développeur, ne l'improvise pas.

## 1. Comprendre le besoin (entretien)

Pose les questions une par une, en mots simples, et reformule à la fin :

1. **Quoi** : que doit-il se passer ? Demande un exemple concret (« quand Marie enregistre
   le compte Dupont SARL, alors… »).
2. **Où** : quel écran, quel module (comptes, contacts, opportunités…) ?
3. **Quand** : à l'enregistrement, à l'affichage, chaque nuit, à la connexion… ?
4. **Pour qui** : tous les utilisateurs, certains seulement ?
5. **Comment vérifier** : qu'est-ce qui prouvera que ça marche ? Ce sera le test.

Écris le besoin en 3 à 5 phrases métier : elles serviront à `extension.json`, au README et
à la pull request. Fais-les valider avant d'écrire du code.

## 2. Trier le besoin

| Le besoin… | Type | Statut |
|---|---|---|
| réagit à un événement (enregistrement, connexion, chaque requête) | `logic-hook` | **validé** (upstream-fixes) |
| ajoute des champs à un module existant (et leur panneau sur la fiche) | `fields` | **validé** (french-company-fields) |
| contrôle une saisie sur la fiche (message sous le champ, enregistrement refusé) | `logic-hook` + `fields` | **validé** (french-company-validation) |
| a un réglage modifiable par l'administrateur (page dans Administration) | `ui` | **validé** pour une page d'administration (opportunity-reminders) |
| change l'affichage de SuiteCRM 8 par un module Angular (format des montants, réglage de l'interface) | `ui` | **validé** (front-customizer) |
| ajoute un écran, un bouton ou un style à SuiteCRM 8 | `ui` | pas encore validé |
| tourne à heure fixe | `scheduler` | **validé** (opportunity-reminders) |
| traduit ou renomme des libellés | `lang` | **validé** avec des champs (french-company-fields) |

**Refuse et renvoie vers un développeur**, en expliquant pourquoi sans jargon :
modification du cœur de SuiteCRM ou de suitecrm-core, envoi de données hors de SuiteCRM,
secrets (mots de passe, clés d'API), droits et sécurité, ou un besoin qui ne rentre dans
aucun type.

## 3. Préparer le dépôt

Le dépôt a été créé depuis `suitecrm-extension-template`, nommé `suitecrm-ext-<slug>`.

- **Slug** : minuscules, chiffres et tirets, 40 caractères au plus, **exclusivement en
  anglais** (`siret-validation`, `french-company-fields`), comme le nom du dépôt et du
  paquet. Il préfixe tous les fichiers de l'extension.
- **Réglages GitHub** : un dépôt créé depuis le modèle n'en hérite pas. Un administrateur du
  dépôt doit, avant le premier merge :
  - dans Settings → Actions → General, cocher « Allow GitHub Actions to create and approve
    pull requests » (sinon pas de release) ;
  - dans Settings → Rules, importer la règle `main` du modèle (PR obligatoire, relecture du
    code owner, squash uniquement, checks `checks / commit-msg` et `checks / quality`) ;
  - dans Settings → General, cocher « Automatically delete head branches ».
- **Renommer le paquet sur `main` d'abord**, dans une petite PR à part
  (`chore: rename the package`) : dans `composer.json`, `name` en
  `david-grosskost/suitecrm-ext-<slug>` et `description`. Composer prend le nom du paquet sur
  la branche par défaut : tant que `main` s'appelle encore `suitecrm-ext-exemple`, l'essai
  dans le core (étape 7) répond « could not be found in any version ». Mettre exactement le
  même texte que dans la branche de travail, pour éviter un conflit au merge. Le check
  `extension@validate` de cette PR échoue (le slug de `extension.json` est encore `exemple`) :
  c'est attendu, l'administrateur la fusionne en contournant la règle ; la PR suivante remet
  tout en ordre.
- Dependabot ouvre aussitôt une PR qui passe le devkit à sa dernière version (composer.json et
  workflows ensemble) : la fusionner d'abord.
- **Remplacer l'exemple**, dans une branche `feature/<ticket>/<description>` :
  - `extension.json` : `slug`, `name` (français), `description` (le besoin en mots métier,
    20 caractères au moins), `types`, `suitecrm` ;
  - `composer.json` : `name` en `david-grosskost/suitecrm-ext-<slug>`, `description`, et le
    namespace des tests dans `autoload-dev` ;
  - supprimer `legacy/include/exemple/`, `tests/ExempleTest.php` et `CHANGELOG.md` ;
  - `.release-please-manifest.json` : remettre `"."` à `"0.0.0"` (la première release sera
    0.1.0, pas la version du modèle) ;
  - `README.md` : ce que fait l'extension, en mots métier.
- **Version de SuiteCRM** (`suitecrm`) : `>=8.10 <9` pour un ajout ; pour un correctif de bug
  de SuiteCRM, la seule version mineure vérifiée (`>=8.10 <8.11`), à revérifier à chaque
  nouvelle version.

## 4. Fabriquer : logic hook (validé)

Deux fichiers, et la logique dans le second :

**La déclaration** : `legacy/Extension/<cible>/Ext/LogicHooks/<slug>.php`, où `<cible>` vaut
`application` (hooks globaux : `after_entry_point`, `after_login`…) ou `modules/<Module>`
(hooks d'un module : `before_save`, `after_save`…).

```php
<?php

// <Ce que fait le hook, en une phrase.>

$hook_version = 1;

/** @var array<string, list<array{int, string, string, string, string}>> $hook_array Set by SuiteCRM */
$hook_array['<evenement>'][] = [
    10,
    '<slug> : <description courte>',
    'custom/include/<slug>/<Classe>.php',
    'SuiteCrmExt\<Namespace>\<Classe>',
    '<methode>',
];
```

**La classe** : `legacy/include/<slug>/<Classe>.php`, namespace `SuiteCrmExt\<Namespace>`
(le slug en PascalCase : `upstream-fixes` → `UpstreamFixes`), `declare(strict_types=1)`,
`final class`. La méthode du hook ne fait qu'appeler des méthodes statiques pures, que les
tests appellent directement. **SuiteCRM ne charge que le fichier déclaré dans le hook** :
les autres classes dont il se sert, ce fichier les charge lui-même
(`require_once __DIR__ . '/<Autre>.php';`), sinon chaque enregistrement plante. Les tests ne le
voient pas (l'autoload de Composer charge tout).

**Signature de la méthode : exactement celle avec laquelle SuiteCRM l'appelle.**

- Hook global (`application`, sans enregistrement) :
  `public function <methode>(string $event, mixed $arguments = null): void`
- Hook de module (avec enregistrement) :
  `public function <methode>(\SugarBean $bean, string $event, mixed $arguments = null): void`

## 4 bis. Fabriquer : champs (validé)

Exemple complet : `suitecrm-ext-french-company-fields`. Trois couches :

**Les champs** : `legacy/Extension/modules/<Module>/Ext/Vardefs/<slug>.php`, une entrée
`$dictionary['<Objet>']['fields']['<champ>']` par champ (`<Objet>` au singulier :
`Account` pour le module `Accounts`). Préfixer les champs (`fr_siret`) : pas de collision
avec SuiteCRM ni avec Studio (`_c`). Les colonnes sont créées par la réparation rapide
(repairDatabase) à l'activation ; un index se déclare dans `$dictionary['<Objet>']['indices']`.
Annotation obligatoire pour PHPStan :

```php
/** @var array<string, array<string, array<mixed>>> $dictionary Set by SuiteCRM */
```

**Les libellés** : `legacy/Extension/modules/<Module>/Ext/Language/{fr_FR,en_us}.<slug>.php`
(`$mod_strings['LBL_…']`, dont celui du panneau), et les listes déroulantes dans
`legacy/Extension/application/Ext/Language/{fr_FR,en_us}.<slug>.php`
(`$app_list_strings['<liste>']`, première clé `''` pour « aucune valeur »). Chacun avec son
`@var`.

**Le panneau sur la fiche : écrit une fois dans la mise en page de Studio**, par le script
d'installation (étape 4 ter). Il appartient ensuite à Studio : l'administrateur le déplace,
le renomme ou le supprime, il n'est jamais remis. Ne pas l'ajouter à la volée (couche
SuiteCRM 8, `ViewDefinitionMapper`) : Studio ne pourrait plus ni le retirer ni le
renommer, et des champs déplacés apparaîtraient deux fois.

- La logique dans une classe sans dépendance à SuiteCRM, `legacy/include/<slug>/`, testée
  seule (exemple : `StudioPanel`). Elle travaille sur le format de Studio pendant l'édition
  (`GridLayoutMetaDataParser::$_viewdefs`) : panneaux → lignes → noms de champs.
- Une case vide se note **`(filler)`** : `(empty)` est supprimé à l'enregistrement, et le
  champ voisin prend alors toute la ligne.
- Clé du panneau en majuscules (`LBL_FR_COMPANY_PANEL`), qui est aussi la clé de son titre
  dans les libellés du module.
- **Fiche en onglets** (`templateMeta.tabDefs` non vide, comme les Comptes) : y ajouter
  `['newTab' => true, 'panelDefault' => 'expanded']` pour le panneau. Sans `tabDefs`, ne rien
  y mettre : tous les panneaux s'affichent, et un onglet masquerait les autres.
- Ne rien ajouter si le panneau ou un de ses champs est déjà dans la mise en page (placé par
  Studio).

## 4 ter. Scripts d'installation et données de démo (validé)

Lancés par le core (`scripts/extension-script.php`), dans SuiteCRM, en administrateur, le
dossier courant étant `public/legacy` :

- **`database/install.php`** : une fois, après la réparation rapide de la première
  activation (le core note `.extensions/<slug>.installed`). Pour ce qui se fait une fois dans
  SuiteCRM : un panneau dans une mise en page de Studio, par exemple
  (`ParserFactory::getParser(MB_DETAILVIEW, '<Module>')`, modifier `$_viewdefs`,
  `handleSave(false)`). Une version suivante de l'extension ne le relance pas.
- **`database/uninstall.php`** : à la désactivation, avant que les fichiers soient retirés
  (SuiteCRM connaît encore les champs). Défaire ce qu'a fait l'installation, sans rien
  supprimer d'autre : retirer les champs de la mise en page où qu'ils soient, le panneau s'il
  est vide. Réactivée, l'extension s'installe de nouveau. Les colonnes et leurs données
  restent en base.
- **`database/seeders/<slug>/seeders.php`** : renvoie la liste des seeders de l'extension
  (contrat dans le `database/README.md` du core), chargés par `make db@seed` quand
  l'extension est active. Pour compléter les comptes d'un autre seeder : `dependsOn()` le
  nomme, et `$seed->update($bean, $champs)` n'écrit **que les champs vides** (une valeur
  saisie en démo reste).
- Charger ses propres classes par `__DIR__` (`__DIR__ . '/../legacy/include/<slug>/…'`), le
  code de SuiteCRM par `getcwd()` (`getcwd() . '/modules/ModuleBuilder/…'`) : PHPStan
  n'a pas SuiteCRM, un chemin écrit en dur échoue à l'analyse.
- Ce que PHPStan ne connaît pas (Studio, seeders du core) : `tests/stubs/suitecrm.stub`,
  dans `scanFiles` de `phpstan.dist.neon`, avec `database` dans `paths`. Dans
  `composer.json`, `autoload-dev` fait pointer `SuiteCrmExt\<Namespace>\` vers
  `legacy/include/<slug>/` (puis `make composer@install` pour régénérer l'autoload).

## 4 quater. Contrôler une saisie sur la fiche (validé)

Exemple complet : `suitecrm-ext-french-company-validation`. Deux niveaux, mêmes règles
(fonctions pures dans `legacy/include/<slug>/`) :

- **Pendant la saisie (SuiteCRM 8)** : un `asyncValidator` sur le champ, que la fiche appelle
  avant d'enregistrer ; tant qu'il répond une erreur, la fiche refuse l'enregistrement et
  affiche le message sous le champ.
  - L'ajouter par un `FieldDefinitionMapperInterface` (`backend/FieldDefinitions/`,
    `getModule()` `'default'`, module reconnu par `strtolower($definition->getId())`), qui
    ajoute `asyncValidators['<slug>'] = ['key' => '<processus>', 'params' => […]]` aux champs
    voulus. **Pas dans les fichiers de champs** (`Ext/Vardefs`) : l'ordre de fusion des
    extensions n'est pas garanti, l'ajout est perdu.
  - Le processus : un `ProcessHandlerInterface` (`backend/Process/`, `getProcessType()` = la
    clé). Il reçoit `options['value']` et `options['params']` ; en erreur :
    `setStatus('error')` et `setData(['errors' => ['startLabelKey' => '<LBL_…>']])`.
  - **Le message dans `$app_strings`** (`legacy/Extension/application/Ext/Language/`) : la
    fiche ne le cherche que là, pas dans les libellés du module (sinon, message vide).
  - Classes SuiteCRM 8 enregistrées et taguées par le core, sans fichier de services.
- **À chaque enregistrement (toute voie : import, API, workflow)** : un hook `before_save`
  qui nettoie la saisie (`$bean->{$champ} = …`) et refuse en levant une exception. SuiteCRM 8
  n'affiche alors qu'un message générique (« Une erreur s'est produite… ») : c'est le dernier
  rempart, la fiche a déjà prévenu l'utilisateur.
- Une extension qui complète celle d'une autre (ici les champs de french-company-fields) ne
  fait rien quand l'autre n'est pas active (champs absents) : le dire dans le README.

## 4 quinquies. Tâche planifiée et page d'administration (validé)

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

## 4 sexies. Module Angular de SuiteCRM 8 (validé)

Exemple complet : `suitecrm-ext-front-customizer`. SuiteCRM 8 charge au démarrage de
l'interface le module Angular déjà compilé d'une extension (module federation) : **le front de
SuiteCRM n'est jamais recompilé**, ni dans le core ni sur le serveur.

- **`app/`** : les sources, copie de `extensions/defaultExt/app` de SuiteCRM-Core (la version
  de l'image), `defaultExt` renommé partout en `<Nom>`, le slug en PascalCase
  (`front-customizer` → `FrontCustomizer`). Le code va dans `app/src/extension.module.ts`.
- **`public/`** : le module compilé, **commité**. `make front@build` le construit (Docker,
  Node 22, sources de SuiteCRM gardées dans le volume `suitecrm-front-<version>` : quelques
  minutes la première fois, moins d'une ensuite). La CI (`make front@check`) reconstruit et
  échoue si `public/` ne correspond pas à `app/` : reconstruire et commiter `public/` à chaque
  changement d'`app/`. `app/` et `public/` vont ensemble (`extension@validate`).
- **`config/extension.php`** : déclare le module à SuiteCRM. Ajouter une entrée
  `$extensions['<Nom>']` au paramètre `extensions` du conteneur, avec
  `'remoteEntry' => '../extensions/<Nom>/remoteEntry.js'`, `'remoteName' => '<Nom>'`,
  `'enabled' => true`. Le core copie `public/` dans `extensions/<Nom>/public/`, et SuiteCRM le
  recopie dans `public/extensions/<Nom>/` en reconstruisant son cache.
- **Le travail se fait dans le constructeur de `ExtensionModule`** : SuiteCRM 8.10 n'appelle
  jamais son `init()`. Les services de SuiteCRM s'injectent par le constructeur
  (`import {…} from 'core'`, bibliothèque partagée). Un `console.info('<slug> : chargé…')`
  permet de vérifier le chargement dans la console du navigateur.
- Test PHP : `config/extension.php` déclare bien le module (`tests/ExtensionConfigTest.php`,
  avec un stub du `Container` de Symfony dans `tests/stubs/`).
- **Limite** : les pages de l'ancienne interface affichées dans SuiteCRM 8 (dashlets de
  l'accueil, pages d'administration) sont faites par le legacy en PHP : le module Angular ne
  les change pas. Le dire dans le README.

Essai local (étape 7) : ouvrir la console du navigateur après Ctrl+F5 et vérifier que
`/extensions/<Nom>/remoteEntry.js` répond 200.

## 5. Tester

Dans `tests/<Classe>Test.php`, namespace `SuiteCrmExt\<Namespace>\Tests` :

- les cas métier de l'entretien, un par ligne d'un `DataProvider`, avec un nom en français ;
- les cas limites (vide, espaces, valeur inattendue) ;
- **un test qui appelle la méthode du hook exactement comme SuiteCRM** : mêmes arguments,
  `null` compris ;
- pour des champs : les définitions (vardefs, libellés dans les deux langues, chaque option
  de liste traduite) et le panneau dans la mise en page de Studio : ajout avec et sans
  onglets, rien si un champ est déjà placé, retrait où que Studio ait mis les champs ;
- pour un seeder : ce qu'il calcule (fonctions pures), et qu'il ne remplace jamais une valeur.

## 6. Vérifier (local)

```bash
make extension@validate && make quality@lint && make quality@stan && make test@unit
```

Avec un module Angular (`app/`), ajouter `make front@check` (il reconstruit `public/`).

Explique chaque échec en une phrase simple, corrige, relance. Ne désactive jamais une règle
et n'ajoute jamais d'exception pour faire passer une vérification : demande à un
développeur si tu bloques.

## 7. Essayer dans SuiteCRM (local)

Dans le dossier de suitecrm-core, sur sa propre branche, **sans commiter** :

1. Dans `composer.json`, ajouter le dépôt dans `repositories`
   (`{ "type": "vcs", "url": "https://github.com/david-grosskost/suitecrm-ext-<slug>", "no-api": true }`)
   et l'extension dans `require` (`"david-grosskost/suitecrm-ext-<slug>": "dev-<branche>"`),
   **sans virgule après la dernière ligne** ; pousser la branche de l'extension avant.
2. `make composer@update PACKAGES=david-grosskost/suitecrm-ext-<slug>`
3. Ajouter le slug à `EXTENSIONS` dans `.env.local` (séparés par des virgules, garder
   `upstream-fixes`), puis `make app@start && make app@logs` : on doit voir
   `activation (…<slug>…)` puis `Réparation rapide faite`.
4. Refaire l'exemple concret de l'entretien dans https://suitecrm-core.dev.localhost avec
   la personne (recharger avec Ctrl+F5). Pour des champs, vérifier aussi les colonnes :
   `MSYS_NO_PATHCONV=1 docker exec suitecrm-core-db sh -c 'mariadb -u"$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" -e "SHOW COLUMNS FROM <table> LIKE \"<prefixe>_%\""'`.
   Sous Git Bash, toute commande `docker` avec un chemin commençant par `/` prend le
   préfixe `MSYS_NO_PATHCONV=1`.
5. Annuler : `git checkout -- composer.json composer.lock && make composer@install`, retirer
   le slug de `.env.local`, `make app@start`.

Si le conteneur redémarre en boucle après l'activation, c'est presque toujours une erreur
fatale PHP dans le hook (signature, fichier introuvable) : `make app@logs`.

## 8. Pull request

- Commit en anglais, Conventional Commits : `feat: <ce que fait l'extension>`
  (`fix: …` pour corriger). Le titre de la PR est le même : il devient le message sur `main`.
  GitHub propose le message du commit quand la branche n'en a qu'un, sinon le nom de la
  branche (refusé par `checks / commit-msg`). **`make git@pr`** pousse la branche et ouvre la PR
  avec le titre du premier commit (ou affiche l'adresse de celle déjà ouverte). Une fois par
  poste : `make git@gh` (installe gh dans `.tools/`), puis la personne se connecte elle-même
  avec `.tools/bin/gh auth login` : jamais de jeton dans la conversation.
- Description de la PR : le besoin en mots métier, comment il a été vérifié (tests, essai
  local), et ce qu'il reste à faire.
- Un développeur relit avant le merge (squash). Après le merge, la PR de release ouvre la
  version ; la mergée pose le tag.
- Ensuite seulement, l'extension peut entrer dans le catalogue de suitecrm-core ou d'un projet
  client (`repositories`, `require` avec `^<version>`, `EXTENSIONS`) : c'est le travail d'un
  développeur. La branche de travail est supprimée au merge : `dev-<branche>` ne résout plus,
  passer à `^<version>`. Une extension métier s'active instance par instance
  (`EXTENSIONS` dans le `.env.local` de l'instance), pas par défaut dans le core.
- Déployer une instance (workflow Deploy, Run workflow) : choisir **le tag** de la release
  dans « Use workflow from ». Avec `main`, le déploiement est ignoré (« Skipped »).

## Pièges déjà rencontrés

- PHPStan « Cannot access an offset on mixed » sur `$hook_array` : il manque l'annotation
  `@var` de l'étape 4.
- Hook global déclaré avec `array $arguments` : SuiteCRM passe `null`, erreur fatale sur
  **chaque page** et conteneur qui redémarre en boucle. Toujours `mixed $arguments = null`.
- Première release en 0.2.0 au lieu de 0.1.0 : `.release-please-manifest.json` pas remis à
  `0.0.0`.
- Release qui échoue (« GitHub Actions is not permitted to create pull requests ») :
  réglage Actions du dépôt pas fait (étape 3).
- Merge impossible alors que tout est vert : la relecture obligatoire ; l'auteur ne peut pas
  s'approuver lui-même, un administrateur merge en contournant la règle.
- Essai dans le core : « could not be found in any version » alors que la branche est
  poussée : le paquet porte encore le nom du modèle sur `main` (étape 3).
- `/docker-entrypoint.sh: exec: update: not found` : `composer.json` invalide (virgule
  finale) ; le vérifier avec
  `MSYS_NO_PATHCONV=1 docker run --rm -v "$PWD":/app -w /app composer:2 composer validate --no-check-publish`.
- Champs créés mais panneau absent de la fiche : fiche en onglets, panneau absent de
  `tabDefs` (étape 4 bis). Vérifier ce que renvoie l'API avant de chercher ailleurs.
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
  (étape 4 quater) ; vérifier le `fieldDefinition` que renvoie l'API.
- « Une erreur s'est produite lors de l'enregistrement » sur toute sauvegarde : le hook
  utilise une classe que son fichier ne charge pas (étape 4).
- Tâche planifiée qui tourne dès l'activation, et non à l'heure prévue : `catch_up` à `1`
  (l'heure du jour est déjà passée, SuiteCRM la rattrape). Mettre `0` (étape 4 quinquies).
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
  que SuiteCRM 8.10 n'appelle pas. Le mettre dans le constructeur (étape 4 sexies).
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
