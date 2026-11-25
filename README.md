# suitecrm-devkit

Outillage partagé par tous les projets SuiteCRM : [suitecrm-core](https://github.com/david-grosskost/suitecrm-core),
les projets clients et les extensions (`suitecrm-ext-*`). Il apporte, à la même version
partout :

- les **commandes `make`** (installer, démarrer, réparer, sauvegarder la base, tester…) ;
- les **hooks Git** (format des commits, secrets, scripts) et les outils qu'ils utilisent ;
- les **règles de qualité** (PHP-CS-Fixer, PHPStan niveau max, signatures des classes SuiteCRM) ;
- les **workflows GitHub Actions** réutilisables (vérifications, test de régression,
  release, déploiement, données de démo, scan de sécurité) ;
- la **fabrication des paquets** d'extension pour le Chargeur de module ;
- les **tests navigateur** (smoke test, test de régression) ;
- le **plugin Claude** [`suitecrm-extensions`](plugins/suitecrm-extensions/README.md), qui
  guide la création d'une extension, même sans connaissance technique.

## Créer une extension avec Claude

Avant tout dépôt d'extension, installer le plugin une fois par poste. Dans Claude Code, dans
la zone de saisie (pas dans un terminal) :

```text
/plugin marketplace add david-grosskost/suitecrm-devkit
/plugin install suitecrm-extensions@suitecrm-devkit
```

Puis décrire le besoin en mots métier (« je voudrais que… ») : le skill `nouvelle-extension`
mène l'entretien et la suite. Dans l'application Claude, le plugin s'ajoute au catalogue de
l'organisation (voir le [README du plugin](plugins/suitecrm-extensions/README.md)).

Une correction faite ici profite à tous les projets : ils la reçoivent en montant la
version du devkit.

## Utilisation dans un projet

Le devkit n'est pas cloné à côté des projets : chacun l'installe avec Composer, dans
`vendor/david-grosskost/suitecrm-devkit`, à la version de son `composer.json`.

```bash
git clone https://github.com/david-grosskost/<projet>.git
cd <projet>
make            # installe le devkit (Composer dans Docker), puis liste les commandes
```

Seuls Docker, Git, `make` et `bash` sont nécessaires (Git Bash sous Windows,
`winget install ezwinports.make`) : PHP, Composer, Node.js et les navigateurs de test
tournent dans des conteneurs.

## Documentation

| Page | Contenu |
|---|---|
| [Commandes](docs/commandes.md) | toutes les commandes `make`, par domaine, avec leurs paramètres |
| [Qualité et tests](docs/qualite-et-tests.md) | hooks Git, lint, PHPStan, tests unitaires, smoke test, test de régression |
| [Workflows GitHub](docs/workflows.md) | vérifications, régression, release, déploiement, données de démo, scan ZAP |
| [Extensions](docs/extensions.md) | format d'une extension, paquet du Chargeur de module, module Angular, données de démo |
| [Réglages GitHub](docs/reglages-github.md) | règles de `main` et des tags, token de release, options à poser sur chaque dépôt |
| [Développement](docs/developpement.md) | faire évoluer le devkit : conventions des scripts, versions, propagation aux projets |
| [Dépannage](docs/depannage.md) | erreurs connues et leurs solutions |
