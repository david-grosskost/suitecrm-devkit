# Workflows GitHub

Le devkit publie des workflows **réutilisables** : chaque projet les appelle depuis son
`.github/workflows/`, à la version du devkit de son `composer.json`.

```yaml
jobs:
  checks:
    uses: david-grosskost/suitecrm-devkit/.github/workflows/checks.yml@v0.29.0
```

Ils lancent les mêmes commandes `make` que sur un poste. Le détail de chaque paramètre est
en tête du fichier du workflow.

| Workflow | Quand | Ce qu'il fait |
|---|---|---|
| `checks.yml` | chaque pull request | format des commits et du titre, contrôles des hooks sur tous les fichiers, lint, PHPStan, format d'extension, paquet et scanner, module Angular, tests unitaires, failles des dépendances |
| `regression.yml` | chaque pull request (core, projets clients) | installe le reverse-proxy, une instance neuve avec **toutes** les extensions de l'image et les données de démo, puis `make test@regression` |
| `release.yml` | chaque push sur `main` | release-please tient à jour la pull request de version ; à son merge : tag, release GitHub, image Docker scannée puis publiée sur GHCR, paquet d'extension joint à la release |
| `deploy.yml` | à la demande, ou après une release | déploie une version sur un serveur en SSH ; sauvegarde le serveur avant, lance le smoke test après, remet la version précédente en cas d'échec |
| `seed.yml` | à la demande | charge les données de démo dans une démo déployée ; refusé en production |
| `zap.yml` | planifié (hebdomadaire) | scan passif OWASP ZAP d'une instance en ligne ; échoue sur une alerte à haut risque |

## Contrôles obligatoires

La règle de `main` de chaque dépôt exige que les contrôles passent avant le merge (voir
[Réglages GitHub](reglages-github.md)) :

| Dépôt | Contrôles exigés |
|---|---|
| extension, devkit | `checks / commit-msg`, `checks / quality` |
| suitecrm-core, projet client | les mêmes, plus `regression / regression` |

## Test de régression dans la CI

`regression.yml` installe tout comme sur un poste, sur le runner :

1. clone de [reverse-proxy](https://github.com/david-grosskost/reverse-proxy) et
   `make app@install` (Traefik, certificat local, réseau `proxy`) ;
2. `make` puis `make app@install` dans le projet : image construite, SuiteCRM installé,
   mots de passe générés ;
3. installation de **toutes** les extensions du catalogue de l'image (`packages.php install`),
   pas seulement celles installées d'office ;
4. `make db@seed` (désactivable : `with: { seed: false }`) ;
5. `make test@regression`.

En cas d'échec, les dernières lignes des logs du conteneur et de `suitecrm.log` sont
affichées. Compter 10 à 15 minutes.

## Release

Une release se fait en mergeant la pull request « chore(main): release x.y.z » que
release-please ouvre et tient à jour. Sa version vient des commits depuis la précédente
(`feat` → mineure, `fix` → correctif ; en 0.x, `feat` monte le deuxième chiffre).

Sans `RELEASE_TOKEN`, cette pull request est ouverte avec le jeton de GitHub Actions : sa
CI ne démarre qu'après **Approve workflows to run**, et la règle de `main` demande une
dérogation pour la merger (voir [Réglages GitHub](reglages-github.md)).

Le devkit lui-même ne passe pas par release-please : ses versions sont des tags posés à la
main (voir [Développement](developpement.md)).

## Déploiement

`deploy.yml` copie dans `/srv/suitecrm/<APP_SLUG>` du serveur les fichiers Compose, `.env`
et `.env.local.example` de la release, avec `deploy/server.sh` du devkit, puis lance
`server.sh deploy`. Le serveur n'a besoin que de Docker : ni Git ni le devkit n'y sont
installés. Les mots de passe sont générés sur le serveur au premier déploiement et ne le
quittent jamais.

Réglages attendus : environnement GitHub (`demo` ou `production`, avec relecteur obligatoire
pour la production) portant `APP_SLUG` et `APP_HOST` ; au niveau du dépôt, le secret
`DEPLOY_SSH_KEY` et les variables `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KNOWN_HOSTS`.
