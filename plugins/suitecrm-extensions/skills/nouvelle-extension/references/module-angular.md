# Module Angular de SuiteCRM 8

Type `ui`, validé (french-currency-format, custom-theme, pwa, login-background).

Exemples complets : `suitecrm-ext-french-currency-format` (le plus simple), `suitecrm-ext-custom-theme`. SuiteCRM 8 charge au démarrage de
l'interface le module Angular déjà compilé d'une extension (module federation) : **le front de
SuiteCRM n'est jamais recompilé**, ni dans le core ni sur le serveur.

- **`app/`** : les sources, copie de `extensions/defaultExt/app` de SuiteCRM-Core (la version
  de l'image), `defaultExt` renommé partout en `<Nom>`, le slug en PascalCase
  (`french-currency-format` → `FrenchCurrencyFormat`). Le code va dans `app/src/extension.module.ts`.
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
  les change pas. Pour l'affichage d'un type de champ, voir la surcharge ci-dessous ; sinon,
  le dire dans le README.

**Surcharger l'affichage legacy d'un type de champ** (exemple : `suitecrm-ext-french-currency-format`,
montants des dashlets) : SuiteCRM charge
`custom/include/SugarFields/Fields/<Type>/SugarField<Type>.php` à la place du sien et utilise
la classe `CustomSugarField<Type>` si elle existe. Dans l'extension :
`legacy/include/SugarFields/Fields/<Type>/SugarField<Type>.php` (seul chemin hors du slug
qu'accepte `extension@validate`), qui charge la classe de SuiteCRM
(`require_once getcwd() . '/include/SugarFields/Fields/<Type>/SugarField<Type>.php'`) et sa
logique (`require_once __DIR__ . '/../../../<slug>/<Classe>.php'`), puis déclare
`class CustomSugarField<Type> extends SugarField<Type>` qui ne fait qu'appeler cette logique
pure, testée. Une seule extension par type : le core refuse qu'une autre écrase le fichier.
La classe de SuiteCRM va dans `tests/stubs/suitecrm.stub` pour PHPStan.

Essai local (essai-local.md) : ouvrir la console du navigateur après Ctrl+F5 et vérifier que
`/extensions/<Nom>/remoteEntry.js` répond 200.
