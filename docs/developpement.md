# Développement

Faire évoluer le devkit lui-même. Les commandes, les hooks et la CI du devkit sont les
siens : il se vérifie avec ce qu'il fournit aux projets (`ci.yml` appelle `checks.yml`
local).

## Ajouter une commande

Une commande `make <domaine>@<action>` lance `.make/scripts/<domaine>/<action>.sh`.

1. Écrire le script `.make/scripts/<domaine>/<action>.sh` (conventions ci-dessous).
2. Le déclarer dans `.make/<domaine>.mk` : la cible dans la ligne `.PHONY`, puis
   `<domaine>@<action>:` qui lance le script. Un nouveau domaine = un nouveau `.mk`, inclus
   automatiquement.
3. `make git@chmod` pour le rendre exécutable dans Git (sous Windows), puis
   `make quality@lint`.
4. L'ajouter à [Commandes](commandes.md).

Une commande propre à un projet va dans le `.make/<domaine>.mk` du projet, pas dans le
devkit (ex. `db@seed`, `extensions@install` dans suitecrm-core). Attention aux noms de
variables : un `.mk` du projet et un `.mk` du devkit sont inclus ensemble, deux variables
de même nom s'écrasent (ex. `DB_SCRIPTS` dans le core, `DB_DUMP_SCRIPTS` dans le devkit).

### Conventions des scripts

- En tête : à quoi sert le script, en anglais, puis `# @usage make <domaine>@<action> [PARAM=…]`.
- `set -euo pipefail`, puis `. "$(dirname "$0")/../lib.sh"`.
- `load_env <commande>` pour lire `.env.local` puis `.env` ; `require_app_env` pour
  réserver une commande à un environnement.
- Les commandes lancées passent par `run` (elles s'affichent), les messages par `info` et
  les erreurs par `die`, **en français**, avec la commande qui corrige : `die "app@start :
  réseau « proxy » absent — démarrer le reverse-proxy"`.
- Jamais de mot de passe affiché : les passer à Docker par leur nom (`-e ADMIN_PASSWORD`).
- Tout outil tourne dans Docker (PHP, Composer, Node.js, Playwright…) ou s'installe dans
  `.tools/bin/` en version fixée, avec vérification de son empreinte.
- Un script qui n'a pas de sens pour le projet s'arrête sans erreur, avec un message
  (`front@build` sans `app/`).

## Version et propagation

Le devkit n'a pas de release-please : une version est un **tag posé à la main** sur `main`,
après le merge des pull requests qu'elle contient.

```bash
git checkout main && git pull --ff-only
git tag -a v0.30.0 -m "v0.30.0: <ce qui change>"
git push origin v0.30.0
```

`feat` → version mineure (deuxième chiffre en 0.x), `fix` ou `docs` seuls → correctif.

Chaque projet nomme la version du devkit **deux fois, toujours ensemble** :

- `composer.json` : `"david-grosskost/suitecrm-devkit": "^0.30"` (en 0.x, `^0.29`
  n'accepte pas la 0.30) ;
- `.github/workflows/*.yml` : `…/workflows/checks.yml@v0.30.0`.

Dependabot (groupe `devkit`, chaque semaine) ouvre dans chaque projet une pull request qui
monte les deux d'un coup. Pour l'avoir tout de suite :

```bash
# dans le projet, sur une branche
sed -i 's#\^0.29"#^0.30"#' composer.json
sed -i 's#@v0.29.0#@v0.30.0#g' .github/workflows/*.yml
make composer@update PACKAGES="david-grosskost/suitecrm-devkit"
```

### Tester une modification avant la release

- **Un script** : depuis le projet, lancer directement celui de sa copie du devkit, à côté :
  `../suitecrm-devkit/.make/scripts/app/repair.sh`. Il lit le `.env` du projet.
- **Un workflow** : le projet peut l'appeler depuis une branche du devkit
  (`regression.yml@feat/ma-branche`), le temps de la mise au point. Repasser sur un tag
  avant de merger : la branche disparaît au merge.

## Le plugin Claude

Le plugin `suitecrm-extensions` vit dans `plugins/suitecrm-extensions/`, déclaré par
`.claude-plugin/marketplace.json`. À chaque changement, monter sa `version` dans
`plugins/suitecrm-extensions/.claude-plugin/plugin.json`. Voir son
[README](../plugins/suitecrm-extensions/README.md).
