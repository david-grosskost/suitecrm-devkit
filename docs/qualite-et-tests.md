# Qualité et tests

Les mêmes contrôles tournent sur le poste (hooks Git, commandes `make`) et dans la CI
([workflows](workflows.md)) : ce qui passe en local passe en CI, et inversement.

## Hooks Git

Activés par `make git@hooks`, une fois par clone (`make app@install` le fait). Dans un
projet, Git pointe vers `vendor/david-grosskost/suitecrm-devkit/.githooks` : les hooks
évoluent avec la version du devkit, sans rien recopier.

| Hook | Contrôle |
|---|---|
| `commit-msg` | message au format [Conventional Commits](https://www.conventionalcommits.org/fr/) (`feat: …`, `fix: …`), première ligne de 72 caractères au plus |
| `pre-commit` | lance tous les contrôles de `.githooks/pre-commit.d/` et refuse le commit si l'un échoue |
| `post-merge` | après un `pull`, signale ce qui reste à faire à la main : réglage ajouté à `.env.example`, conteneurs à recréer ; ne bloque jamais |

Contrôles de `pre-commit` :

| Contrôle | Refuse |
|---|---|
| `secrets.sh` | un secret dans les changements (clé d'API, jeton, clé privée, mot de passe), détecté par gitleaks |
| `sensitive-files.sh` | un fichier sensible ajouté de force : `.env.local`, clés privées, certificats |
| `scripts.sh` | un script cassé (première ligne, marqueurs de conflit) ; rend exécutable un script qui ne l'est pas (Windows perd ce droit) |
| `shellcheck.sh` | un script shell avec un bug ou une construction risquée |

La CI relance les mêmes contrôles sur **tous** les fichiers (`--all`) : un commit fait
sans les hooks (interface web, autre clone) est rattrapé.

## Format des commits

Les messages de commit et les titres de pull request suivent Conventional Commits, en
anglais : `feat: add db@dump and db@restore commands`. Le titre d'une pull request devient
le message du commit sur `main` (squash) : release-please le lit pour calculer la version
suivante (`feat` → mineure, `fix` → correctif) et écrire le `CHANGELOG.md`.

72 caractères au plus pour la première ligne : avec le ` (#NN)` qu'ajoute GitHub au merge,
viser 65.

## Lint et analyse statique

```bash
make quality@lint    # hadolint, PHP-CS-Fixer (sans rien modifier), shellcheck
make quality@fix     # corrige le style PHP sur place
make quality@stan    # PHPStan, niveau max
```

Les réglages communs sont dans `config/` du devkit : `php-cs-fixer.php`, `phpstan.neon` et
`suitecrm.stub`, les signatures des classes de SuiteCRM utilisées par les extensions
(SuiteCRM n'est pas installé dans une extension). Chaque projet les inclut depuis son
`.php-cs-fixer.dist.php` et son `phpstan.dist.neon`.

PHPStan ne s'applique qu'au code du projet, jamais à SuiteCRM lui-même. Une signature de
SuiteCRM qui manque se déclare dans `config/suitecrm.stub` du devkit (utile à tous) ou dans
`tests/stubs/` du projet (propre à lui).

## Tests unitaires

```bash
make test@unit
```

PHPUnit, avec le `phpunit.xml.dist` du projet. La logique d'une extension vit dans des
classes testables sans SuiteCRM (`legacy/include/<slug>/`) : les hooks ne font que les
appeler.

## Smoke test

```bash
make test@smoke                  # l'instance locale
make test@smoke APP_ENV=demo     # une instance en ligne (APP_HOST de .env.local)
```

Trois vérifications : l'instance répond, affiche sa page de connexion, et accepte
l'administrateur (si `ADMIN_USER` et `ADMIN_PASSWORD` sont connus). Lancé après chaque
déploiement : un échec remet la version précédente.

## Test de régression

```bash
make test@regression
```

Pour une instance **locale** seulement. Lance d'abord `app@repair`, puis parcourt en
administrateur :

- la liste, une fiche et le formulaire de création des Comptes, des Contacts et des Affaires ;
- l'Administration ;
- le Chargeur de module.

Chaque écran doit afficher son contenu (un tableau, le nom de la fiche, le bouton
« Sauvegarder »…) et échoue sur :

- une erreur JavaScript non interceptée ;
- une réponse HTTP 5xx ;
- une erreur PHP affichée dans la page (`Fatal error`, `Warning: … on line …`) ;
- une clé de libellé brute (`LBL_…`, `LNK_…`), signe d'une traduction cassée.

Les écrans historiques, affichés dans une iframe, sont vérifiés aussi. Les simples erreurs
de console sont notées sans faire échouer le test : SuiteCRM en produit lui-même.

Sans enregistrement dans un module, le test de sa fiche est ignoré : charger les données
de démo (`make db@seed` dans suitecrm-core).

Dans la CI, le workflow `regression.yml` installe une instance neuve avec **toutes** les
extensions de l'image avant de lancer ce test : c'est lui qui attrape une extension qui en
casse une autre.

### Fonctionnement

Les deux suites (`tests/smoke/`, `tests/regression/`) sont lancées par la fonction
`playwright_run` de `.make/scripts/lib.sh`, dans l'image officielle de Playwright
(navigateurs inclus) : rien n'est installé sur le poste ni écrit dans le projet. Quand le
reverse-proxy tourne sur la machine, le navigateur passe directement par Traefik sur le
réseau `proxy` ; en local, le certificat mkcert n'étant pas reconnu dans le conteneur, les
erreurs HTTPS y sont ignorées.

Ajouter un écran : un `test(...)` de plus dans `tests/regression/regression.spec.ts`, avec
un contrôle de ce qu'il doit afficher (sans quoi une page blanche passerait), puis
`expectClean(page, '<nom de l'écran>')`.

## Sécurité

```bash
make security@deps                                   # failles connues des dépendances PHP
make security@image IMAGE=ghcr.io/<compte>/<projet>:1.2.0   # failles de l'image Docker
make security@zap URL=https://demo.example.com      # scan passif d'une instance en ligne
```
