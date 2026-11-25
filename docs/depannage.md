# Dépannage

## Commandes

### `make: command not found` (Windows)

Installer make pour Git Bash : `winget install ezwinports.make`, puis rouvrir Git Bash.

### `Permission denied` en lançant une commande, ou commit refusé pour un script non exécutable

Windows ne garde pas le droit d'exécution des fichiers. Après avoir ajouté un script
(`git add`), lancer `make git@chmod`. Le hook `pre-commit` le fait aussi pour les scripts
du commit.

### `/usr/bin/env: 'bash\r': No such file or directory`

Le script a été enregistré avec des fins de ligne Windows. Le `.gitattributes` du dépôt
impose LF : `git add --renormalize .`, puis recommiter.

### `réseau « proxy » absent`

Le [reverse-proxy](https://github.com/david-grosskost/reverse-proxy) n'est pas démarré :
`make app@start` dans son dossier (ou `make app@install` la première fois).

## Composer et versions

### `composer@update` ne prend pas la nouvelle version du devkit

En 0.x, `^0.29` n'accepte que les 0.29.x. Monter la contrainte dans `composer.json`
(`^0.30`) en même temps que les `@v0.30.0` des workflows (voir
[Développement](developpement.md#version-et-propagation)).

## Commits et pull requests

### `commit-msg : première ligne trop longue (80 caractères, 72 maximum)`

Raccourcir le message. Pour une pull request, c'est son **titre** qui est vérifié (il
devient le message du commit sur `main`) : le modifier sur GitHub relance la vérification.
Viser 65 caractères, GitHub ajoutant ` (#NN)` au merge.

### La CI d'une pull request de release ne démarre pas

La pull request a été ouverte par le jeton de GitHub Actions, qui ne déclenche pas de
workflow. Cliquer sur **Approve workflows to run** dans la pull request, ou poser un
`RELEASE_TOKEN` (voir [Réglages GitHub](reglages-github.md#token-de-release)).

## Base et données de démo

### `db@seed` échoue

Le message dit quel seeder et quelle ligne. Cas déjà rencontré : un seeder d'extension qui
charge une classe par un chemin relatif vers `legacy/` du dépôt, absent de l'image (voir
[Extensions](extensions.md#les-données-de-démo)).

### `db@restore : commande réservée à l'environnement local`

Normal : restaurer une démo ou une production passe par les procédures du serveur, jamais
par cette commande.

## Tests

### `test@regression : ADMIN_PASSWORD absent de .env.local`

L'instance n'a pas été installée par `make app@install`, ou `.env.local` a été modifié.
Le mot de passe de l'administrateur doit y figurer.

### Les tests « fiche » du test de régression sont ignorés (`skipped`)

Le module n'a aucun enregistrement : charger les données de démo (`make db@seed` dans
suitecrm-core), puis relancer.

### Un écran du test de régression échoue

Le message nomme l'écran et la cause :

- `libellé non traduit : LBL_…` : un libellé manque en français ; l'ajouter dans
  l'extension concernée (ou dans french-locale) ;
- `erreur PHP : …` ou `HTTP 500` : regarder `make app@logs` et `public/legacy/suitecrm.log`
  dans le conteneur ;
- `toBeVisible … hidden` ou délai dépassé : l'écran n'a pas affiché ce qu'il devait ;
  l'ouvrir dans un navigateur pour voir.

## Module Angular

### Le premier `front@build` est très long

Il prépare les sources de SuiteCRM (2,5 Go) dans le volume Docker
`suitecrm-front-<version>` : quelques minutes la première fois, moins d'une minute ensuite.
Pour repartir de zéro : `docker volume rm suitecrm-front-<version>`.
