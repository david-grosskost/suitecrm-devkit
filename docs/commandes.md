# Commandes

`make` sans argument liste les commandes disponibles dans le projet : celles du devkit et
celles que le projet ajoute dans son `.make/*.mk` (par exemple `db@seed` ou
`extensions@install` dans suitecrm-core). Toutes suivent la forme `make <domaine>@<action>`
et affichent les commandes Docker qu'elles lancent.

Une commande qui n'a pas de sens pour le projet (par exemple `front@build` sans module
Angular, `test@unit` sans `phpunit.xml.dist`) s'arrête sans erreur, avec un message.

## Paramètres

Les paramètres se passent sur la ligne de commande : `make app@logs SERVICE=db`.

| Paramètre | Commandes | Rôle |
|---|---|---|
| `APP_ENV` | `app@*`, `db@dump`, `test@smoke` | `local` (défaut), `demo` ou `prod` ; enregistré dans `.env.local` à l'installation |
| `APP_HOST` | `app@install` | adresse de l'instance, obligatoire hors local |
| `SERVICE` | `app@logs` | service suivi : `app` (défaut), `db`, `cron`… |
| `PACKAGES` | `composer@update` | paquets à mettre à jour ; tous sans lui |
| `NAME` | `db@dump` | étiquette ajoutée au nom du dump |
| `FILE` | `db@restore` | dump à restaurer ; le plus récent sans lui |
| `IMAGE` | `security@image` | image Docker à scanner |
| `URL` | `security@zap` | adresse de l'instance à scanner |

Les réglages d'une instance vivent dans deux fichiers : `.env` (versionné : identité du
projet, `APP_SLUG`…) et `.env.local` (jamais versionné : environnement et mots de passe,
générés par `app@install`).

## app : l'instance SuiteCRM

| Commande | Rôle |
|---|---|
| `app@check` | vérifie que la machine peut faire tourner SuiteCRM (Docker, réseau du reverse-proxy…) et dit comment corriger chaque problème |
| `app@install` | installation complète, relançable sans risque : crée `.env.local` et ses mots de passe, active les hooks Git, démarre les conteneurs, installe SuiteCRM |
| `app@start` / `app@stop` / `app@restart` | démarre (en attendant que tout soit sain), arrête (les données restent), redémarre |
| `app@status` | état des conteneurs |
| `app@logs` | suit les logs d'un service (`SERVICE=app` par défaut) |
| `app@update` | récupère les images à jour, reconstruit l'image et recrée les conteneurs |
| `app@repair` | réparation rapide de SuiteCRM (comme Administration → Réparer → Réparation rapide et reconstruction), puis vidage du cache de SuiteCRM 8 |
| `app@config` | configuration Compose finale ; **affiche les mots de passe en clair** |

## db : la base de l'instance

| Commande | Rôle |
|---|---|
| `db@dump` | écrit la base dans `.tools/dumps/<slug>-<date>[-<NAME>].sql.gz` (jamais versionné) |
| `db@restore` | restaure un dump, **en local uniquement** : demande confirmation, fait d'abord un dump `before-restore`, puis vide le cache de SuiteCRM 8 |

Exemple, avant un essai risqué :

```bash
make db@dump NAME=avant-essai
# … essai …
make db@restore FILE=.tools/dumps/suitecrm-core-20261125-180105-avant-essai.sql.gz
```

## composer : les dépendances PHP

| Commande | Rôle |
|---|---|
| `composer@install` | installe exactement les versions de `composer.lock` |
| `composer@update` | met à jour dans les contraintes de `composer.json` et réécrit `composer.lock` |

## quality : la qualité du code

| Commande | Rôle |
|---|---|
| `quality@lint` | vérifie sans rien modifier : Dockerfiles (hadolint), style PHP (PHP-CS-Fixer), scripts (shellcheck) |
| `quality@fix` | corrige le style PHP sur place ; relire avec `git diff` avant de commiter |
| `quality@stan` | analyse statique PHPStan au niveau max |
| `quality@baseline` | enregistre les erreurs PHPStan actuelles comme tolérées ; jamais pour cacher une nouvelle erreur |

## test : les tests

| Commande | Rôle |
|---|---|
| `test@unit` | tests unitaires (PHPUnit) |
| `test@smoke` | l'instance répond, affiche sa page de connexion et accepte l'administrateur |
| `test@regression` | réparation rapide, puis parcours des écrans principaux en administrateur (local uniquement) |

Détails dans [Qualité et tests](qualite-et-tests.md).

## extension, package, front : les extensions

| Commande | Rôle |
|---|---|
| `extension@validate` | vérifie le format : manifeste `extension.json`, `composer.json`, place des fichiers |
| `package@build` | fabrique le paquet du Chargeur de module dans `build/<slug>-<version>.zip` |
| `package@scan` | passe le paquet au scanner du Chargeur de module de SuiteCRM |
| `front@build` | compile le module Angular de l'extension (`app/` → `public/`, versionné) |
| `front@check` | vérifie que `public/` correspond bien à `app/` (lancé par la CI) |

Détails dans [Extensions](extensions.md).

## security : la sécurité

| Commande | Rôle |
|---|---|
| `security@deps` | échoue si une dépendance PHP a une faille connue (`composer audit`) |
| `security@image` | scanne une image Docker (Trivy) ; échoue sur une faille critique corrigeable |
| `security@zap` | scan passif d'une instance en ligne (OWASP ZAP), sans rien attaquer |

## git : l'outillage du dépôt

| Commande | Rôle |
|---|---|
| `git@hooks` | active les hooks Git du devkit et installe leurs outils ; une fois par clone (`app@install` le fait) |
| `git@pr` | pousse la branche et ouvre sa pull request, titrée d'après le premier commit |
| `git@chmod` | marque les scripts comme exécutables dans Git (Windows perd ce droit) |
| `git@gh`, `git@gitleaks`, `git@shellcheck` | installent ces outils dans `.tools/bin/`, en version fixée et vérifiée |
