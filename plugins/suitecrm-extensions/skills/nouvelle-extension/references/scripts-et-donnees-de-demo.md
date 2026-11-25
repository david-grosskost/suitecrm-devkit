# Scripts d'installation et données de démo

Validé (french-company-fields, opportunity-reminders, custom-theme). Ce qui se fait une fois à l'installation, ce qui se défait à la désinstallation, et les données de démo.

Lancés par le paquet du Chargeur de module (paquet.md), dans SuiteCRM, en administrateur, le
dossier courant étant `public/legacy` :

- **`database/install.php`** : une fois, après la réparation rapide de l'installation. Pour
  ce qui se fait une fois dans SuiteCRM : un panneau dans une mise en page de Studio, par
  exemple (`ParserFactory::getParser(MB_DETAILVIEW, '<Module>')`, modifier `$_viewdefs`,
  `handleSave(false)`). Une version suivante de l'extension ne le relance pas : le paquet
  note l'installation en base (table `config`, catégorie `extension_installed`).
- **`database/uninstall.php`** : à la désinstallation, avant que les fichiers soient retirés
  (SuiteCRM connaît encore les champs). Défaire ce qu'a fait l'installation, sans rien
  supprimer d'autre : retirer les champs de la mise en page où qu'ils soient, le panneau s'il
  est vide. Réinstallée, l'extension s'installe de nouveau. Les colonnes et leurs données
  restent en base.
- Les deux tournent **dans une fonction** : pas de variable attendue d'ailleurs, `global`
  pour celles de SuiteCRM (`$current_user`, `$sugar_config`), `return` pour s'arrêter.
- Un script **renvoie son message** (`return 'mon-slug : panneau ajouté.';`, `return` aussi
  pour s'arrêter plus tôt) et n'affiche rien : `echo` est refusé par le scanner du Chargeur de
  module (paquet.md). SuiteCRM le note dans son journal.
- **`database/seeders/<slug>/seeders.php`** : renvoie la liste des seeders de l'extension
  (contrat dans le `database/README.md` du core), chargés par `make db@seed` quand
  l'extension est installée. Pour compléter les comptes d'un autre seeder : `dependsOn()` le
  nomme, et `$seed->update($bean, $champs)` n'écrit **que les champs vides** (une valeur
  saisie en démo reste).
- **Scripts d'installation** : charger ses propres classes par `__DIR__`
  (`__DIR__ . '/../legacy/include/<slug>/…'` : le script tourne dans le paquet décompressé,
  `legacy/` est à côté), le code de SuiteCRM par `getcwd()`
  (`getcwd() . '/modules/ModuleBuilder/…'`) : PHPStan n'a pas SuiteCRM, un chemin écrit en
  dur échoue à l'analyse.
- **Seeders : jamais de chemin relatif vers `legacy/`.** Dans l'image, seuls les seeders sont
  copiés (`/usr/local/share/suitecrm/extensions/seeders/<slug>/`) : une classe de l'extension
  se charge là où le Chargeur de module l'a installée, le seed travaillant dans
  `public/legacy`, avec le chemin du dépôt en secours pour l'analyse :

  ```php
  $profile = 'custom/include/<slug>/<Classe>.php';
  require_once is_file($profile)
      ? $profile
      : __DIR__ . '/../../../legacy/include/<slug>/<Classe>.php';
  ```

  Sinon `make db@seed` échoue (« Failed opening required ») dès que l'extension est installée.
  Le test de régression de la CI, qui installe toutes les extensions et charge les données de
  démo, l'attrape.
- Ce que PHPStan ne connaît pas (Studio, seeders du core) : `tests/stubs/suitecrm.stub`,
  dans `scanFiles` de `phpstan.dist.neon`, avec `database` dans `paths`. Dans
  `composer.json`, `autoload-dev` fait pointer `SuiteCrmExt\<Namespace>\` vers
  `legacy/include/<slug>/` (puis `make composer@install` pour régénérer l'autoload).
