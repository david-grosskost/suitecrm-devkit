# Paquet du Chargeur de module

À lire avant tout script d'installation, et quand `make package@scan` échoue.

Le paquet est **la seule façon dont une extension s'installe** : à la main sur n'importe quel
SuiteCRM 8 (Administration → Chargeur de module), ou par l'image de suitecrm-core, qui l'y
dépose et l'installe pour l'instance. `make package@build` fabrique le paquet dans
`build/<slug>-<version>.zip` (jamais commité) ; la CI le fabrique à chaque PR, et la release
le joint à la version sur GitHub.

- Il reprend les mêmes dossiers que l'image : `backend/`, `config/`, `public/` vont dans
  `extensions/<Nom>/`, `legacy/…` dans `custom/…`. Rien à déclarer : un fichier hors de ces
  dossiers n'est pas dans le paquet.
- Après la copie, le paquet lance la réparation rapide (le Chargeur de module ne crée pas
  les colonnes des nouveaux champs), puis `database/install.php`. `database/uninstall.php`
  tourne avant la désinstallation. Les seeders restent hors du paquet.
- **Mise à jour** (une version plus récente installée par-dessus) : le Chargeur de module
  ne désinstalle pas, il recopie les fichiers et relance la réparation rapide ;
  `database/install.php` **ne tourne pas à nouveau** (noté en base, table `config`,
  catégorie `extension_installed`), pour ne pas défaire ce que l'administrateur a changé
  depuis. La désinstallation efface cette note. Un changement de données à apporter par
  une nouvelle version ne passe donc pas par `install.php`. SuiteCRM ne reconnaît pas la
  mise à jour d'une version 0.x (bug de `UpgradeHistory::determineIfUpgrade`) : il
  l'installe comme un nouveau paquet ; le script généré retire alors la ligne de
  l'ancienne version de la liste des paquets installés. Le core fait cette mise à jour tout
  seul au démarrage de l'instance, pour les extensions déjà installées dont l'image apporte
  une version plus récente.
- **Le scanner du Chargeur de module** (désactivé par défaut dans SuiteCRM, mais certains
  hébergeurs l'activent) refuse tout le paquet pour un seul appel interdit, dans `legacy/`,
  `backend/`, `config/` ou `database/`, tests exclus. Les plus courants : les fonctions à
  callback (`array_map`, `array_filter`, `usort`, `call_user_func`…) → une boucle ; les appels
  `$fonction()` → une méthode ; `echo`, `exit`/`die` ; et les fonctions de fichiers
  (`file_get_contents`, `file_exists`, `is_file`, `mkdir`, `copy`, `rename`, `unlink`,
  `getimagesize`, `readfile`…) → passer par les classes de SuiteCRM. La liste complète est
  dans `ModuleInstall/ModuleScanner.php` de SuiteCRM. `make package@scan` (après
  `make package@build`) passe le paquet au vrai scanner, comme la CI à chaque PR.
- Le paquet n'accepte que la version mineure de SuiteCRM du module Angular (8.10.x).

Essai : dans https://suitecrm-core.dev.localhost, l'extension désinstallée
(`make extensions@uninstall SLUGS=<slug>`), Administration → Chargeur de module → Installer
sur sa ligne, que l'image y a déposée ; refaire l'exemple concret ; puis Désinstaller et
vérifier que tout est revenu comme avant. Pour s'assurer qu'elle s'installe aussi **sans
l'image**, téléverser le zip de `make package@build` sur un SuiteCRM 8 ordinaire.
