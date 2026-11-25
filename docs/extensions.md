# Extensions

Une extension ajoute une fonctionnalité à SuiteCRM **sans jamais modifier son code** : elle
dépose ses propres fichiers aux emplacements que SuiteCRM prévoit pour ça. Chaque extension
est un dépôt `suitecrm-ext-<slug>`, créé depuis
[suitecrm-extension-template](https://github.com/david-grosskost/suitecrm-extension-template),
et un paquet Composer de type `suitecrm-extension`.

Une instance installe ses extensions par **Administration → Chargeur de module**, depuis
les paquets que l'image de suitecrm-core met à disposition (ou `make extensions@install
SLUGS="…"` dans le core).

Pour créer une extension avec Claude, même sans connaissance technique : le plugin
[`suitecrm-extensions`](../plugins/suitecrm-extensions/README.md).

## Le manifeste `extension.json`

```json
{
    "slug": "french-company-fields",
    "name": "Champs des entreprises françaises",
    "description": "Ajoute aux comptes le SIRET, le code NAF et la forme juridique.",
    "types": ["fields"],
    "suitecrm": ">=8.10 <9"
}
```

| Clé | Contenu |
|---|---|
| `slug` | identifiant en minuscules et tirets, **en anglais**, 40 caractères au plus : le préfixe de tous ses fichiers |
| `name` | nom, en français |
| `description` | ce que fait l'extension, en mots métier (20 caractères au moins) |
| `types` | parmi `logic-hook`, `fields`, `ui`, `scheduler`, `lang` |
| `suitecrm` | versions de SuiteCRM compatibles ; le build de l'image refuse une extension incompatible |

Le `name` de `composer.json` doit se terminer par `/suitecrm-ext-<slug>`.

## Où mettre quoi

| Dossier de l'extension | Copié dans SuiteCRM | Pour |
|---|---|---|
| `legacy/Extension/…` | `public/legacy/custom/Extension/…` | déclarations (hooks, champs, libellés, menus d'administration), assemblées à la réparation rapide ; **le slug dans chaque nom de fichier** |
| `legacy/include/<slug>/` | `public/legacy/custom/include/<slug>/` | les classes PHP : toute la logique, testée sans SuiteCRM |
| `legacy/themes/<Nom>/` | `public/legacy/custom/themes/<Nom>/` | un thème propre à l'extension |
| `backend/`, `config/` | `extensions/<Nom>/` | la couche SuiteCRM 8 (Symfony) ; `<Nom>` : le slug en PascalCase |
| `app/` → `public/` | `extensions/<Nom>/public/` | le module Angular : sources dans `app/`, module compilé dans `public/` (versionné) |
| `database/install.php`, `uninstall.php` | — | lancés à l'installation (une seule fois) et à la désinstallation |
| `database/seeders/<slug>/` | catalogue de l'image | données de démo, chargées par `make db@seed` |
| `tests/` | — | tests unitaires |

`make extension@validate` refuse un fichier rangé ailleurs : deux extensions ne peuvent
ainsi jamais écrire le même fichier. Seule exception, imposée par SuiteCRM : la surcharge
d'un type de champ (`legacy/include/SugarFields/Fields/<Type>/`), que le core refuse si deux
extensions surchargent le même type.

## Le paquet du Chargeur de module

```bash
make package@build    # build/<slug>-<version>.zip
make package@scan     # passe le paquet au scanner de SuiteCRM
```

Le paquet contient les fichiers de l'extension aux emplacements du tableau ci-dessus, plus
deux scripts générés :

- **`post_install.php`** : réparation rapide (le Chargeur de module assemble les extensions
  mais ne crée pas les colonnes des nouveaux champs), puis `database/install.php` **une
  seule fois**. Une mise à jour réinstalle le paquet par-dessus l'ancien : le script
  d'installation ne repasse pas, pour ne pas défaire ce que l'administrateur a changé depuis
  (un panneau retiré dans Studio, une tâche planifiée supprimée).
- **`pre_uninstall.php`** : `database/uninstall.php`, avant le retrait des fichiers.

La version du paquet est celle de `.release-please-manifest.json`. À chaque release, le
paquet est joint à la release GitHub, et l'image de suitecrm-core l'embarque dans son
catalogue.

Le scanner est celui de SuiteCRM : il refuse notamment les fonctions d'accès aux fichiers
et l'exécution de commandes. Une extension qui ne le passe pas ne s'installerait pas sur une
instance où le scan est actif.

## Le module Angular

Pour une extension qui modifie l'interface de SuiteCRM 8 (rail de navigation, thème,
application installable…) :

```bash
make front@build    # compile app/ dans public/, contre les sources de SuiteCRM 8.10.2
make front@check    # vérifie que public/ correspond à app/ (CI)
```

Le module est compilé contre les sources de la version de SuiteCRM de l'image
(`SUITECRM_VERSION` de `.make/scripts/lib.sh`) : un module compilé contre une autre version
peut ne pas se charger. `public/` est versionné, car l'image n'a pas Node.js.

Le premier build télécharge et prépare les sources de SuiteCRM (2,5 Go, dans le volume
Docker `suitecrm-front-<version>`) : quelques minutes, puis moins d'une minute les fois
suivantes.

## Les données de démo

Une extension peut remplir ses propres champs dans les données de démo :
`database/seeders/<slug>/seeders.php` renvoie une liste de seeders (interface `Seeder` de
suitecrm-core). `make db@seed` les lance après ceux du core, quand l'extension est
installée sur l'instance.

Dans l'image, **seuls les seeders** sont copiés (`/usr/local/share/suitecrm/extensions/seeders/<slug>/`) :
une classe de l'extension se charge là où le Chargeur de module l'a installée
(`custom/include/<slug>/…`, le seed travaille dans `public/legacy`), jamais par un chemin
relatif vers `legacy/` du dépôt.

## Version de SuiteCRM

À chaque nouvelle version mineure de SuiteCRM, vérifier chaque extension sur la nouvelle
version, puis élargir sa contrainte `suitecrm` : le build de l'image refuse une extension
qui ne la déclare pas compatible.
