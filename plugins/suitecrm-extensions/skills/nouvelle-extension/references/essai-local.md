# Essayer dans SuiteCRM (local)

Pour les façons de travailler 1 et 2 (Docker et suitecrm-core sur le poste). Avec la
façon 3, sauter cette étape : le dire dans la pull request, la CI et le relecteur prennent
le relais.

Façon 1 : lancer les commandes. Façon 2 : les donner une à une à la personne, dans un bloc
à copier, et lui demander de coller le résultat ; lui dire avant chaque commande ce qu'elle
doit voir.

## Avant l'essai

Dans le dossier de suitecrm-core, l'instance démarrée (`make app@start`) :

```bash
make db@dump NAME=avant-<slug>
```

On pourra revenir à l'état d'avant l'essai avec `make db@restore`.

## Le plus simple : installer le paquet

1. Dans l'extension : `make package@build` → `build/<slug>-<version>.zip`.
2. Dans https://suitecrm-core.dev.localhost, **Administration → Chargeur de module** :
   **Choisir un fichier**, **Télécharger**, puis **Installer** sur sa ligne. C'est exactement
   ce que fera un administrateur, et ce que fait l'image (réparation rapide, script
   d'installation).
3. Recharger avec Ctrl+F5, puis refaire avec la personne l'exemple concret de l'entretien.
4. Dans suitecrm-core : `make test@regression` (réparation rapide, puis parcours des écrans
   principaux ; il échoue sur une erreur JavaScript, PHP ou serveur, ou un libellé brut).
5. Pour des données de démo : `make db@seed`, puis vérifier ce que remplit l'extension.
6. Désinstaller (même écran), vérifier que tout est revenu comme avant, puis
   `make db@restore` si l'essai a laissé des données.

Après une correction : refaire le paquet, désinstaller, réinstaller. Une installation
par-dessus une version de **même numéro** ne relance pas tout.

## Libellés seulement : copier et réparer

Pour un changement qui ne touche que des fichiers de `legacy/Extension/` (libellés, listes),
sans repasser par le paquet :

```bash
MSYS_NO_PATHCONV=1 docker cp legacy/Extension/. suitecrm-core-app:/var/www/html/public/legacy/custom/Extension/
MSYS_NO_PATHCONV=1 docker exec suitecrm-core-app chown -R www-data:www-data /var/www/html/public/legacy/custom/Extension
cd ../suitecrm-core && make app@repair
```

## Dans l'image, comme sur une instance déployée

Pour vérifier le chemin complet (catalogue de l'image, installation d'office, mise à jour au
démarrage), dans suitecrm-core, sur sa propre branche, **sans commiter** :

1. Dans `composer.json`, ajouter le dépôt dans `repositories`
   (`{ "type": "vcs", "url": "https://github.com/david-grosskost/suitecrm-ext-<slug>", "no-api": true }`)
   et l'extension dans `require` (`"david-grosskost/suitecrm-ext-<slug>": "dev-<branche>"`),
   **sans virgule après la dernière ligne** ; pousser la branche de l'extension avant.
2. `make composer@update PACKAGES=david-grosskost/suitecrm-ext-<slug>`
3. `make app@update` (l'image et son catalogue sont refabriqués), puis
   `make extensions@install SLUGS=<slug>` ; `make extensions@list` doit la montrer installée.
4. Refaire l'exemple concret, puis `make test@regression`.
5. Annuler : `make extensions@uninstall SLUGS=<slug>`, puis
   `git checkout -- composer.json composer.lock && make composer@install && make app@update`.

Une extension déjà installée n'est reprise que si le catalogue apporte un **numéro de version
plus récent** : une branche de travail garde le même. Désinstaller puis réinstaller.

## Vérifications utiles

- Colonnes d'un champ :
  `MSYS_NO_PATHCONV=1 docker exec suitecrm-core-db sh -c 'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb -uroot "$MARIADB_DATABASE" -e "SHOW COLUMNS FROM <table> LIKE \"<prefixe>_%\""'`
- Module Angular : console du navigateur après Ctrl+F5, `/extensions/<Nom>/remoteEntry.js`
  doit répondre 200.
- Conteneur qui redémarre en boucle, page 500 : `make app@logs` (souvent une erreur fatale
  dans un hook).
- Sous Git Bash, toute commande `docker` avec un chemin commençant par `/` prend le préfixe
  `MSYS_NO_PATHCONV=1`.
