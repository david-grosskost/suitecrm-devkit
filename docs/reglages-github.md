# Réglages GitHub d'un dépôt

À appliquer **à la création de chaque dépôt** (core, extension, projet client), une fois
pour toutes. Ce qui est dans les fichiers du dépôt (workflows, Dependabot) arrive tout seul
depuis le modèle ; ce qui est ci-dessous vit dans les réglages GitHub et ne se copie pas.

Le propriétaire du dépôt est le seul à pouvoir les poser.

## Règle sur `main`

**Settings → Rules → Rulesets → New ruleset → New branch ruleset**, nommée `main`.

- **Enforcement status** : `Active`.
- **Target branches** : `Include default branch`.
- Cocher :
  - **Require a pull request before merging**, avec **0 approbation exigée** et sans
    relecture CODEOWNERS (voir ci-dessous).
  - **Require status checks to pass** → ajouter `checks / commit-msg` et `checks / quality`.
  - **Block force pushes** (`non_fast_forward`) — l'historique ne se réécrit pas.
  - **Restrict deletions** — `main` ne se supprime pas par accident.

Ces deux contrôles n'apparaissent dans la liste qu'après avoir tourné au moins une fois :
ouvre une première pull request, puis reviens les ajouter.

### Zéro approbation, et pourquoi

Exiger une approbation paraît plus sûr, mais sur un dépôt tenu par une seule personne c'est
l'inverse : on ne peut pas approuver sa propre pull request, donc **plus rien ne se
fusionne** — et la seule issue est d'ajouter une dérogation, qui emporte alors *tous* les
contrôles de la règle, y compris la CI. C'est exactement ce qui est arrivé aux premières
extensions : elles exigeaient une approbation, la dérogation a été ajoutée pour débloquer,
et des pull requests de release sont passées sans qu'aucun contrôle ne tourne, sans que
personne ne s'en aperçoive.

Avec 0 approbation, la règle reste utilisable seul **et** mord vraiment : pull request
obligatoire, CI verte obligatoire. Le jour où une deuxième personne travaille sur le dépôt,
on monte le compteur à 1 et on retire la dérogation.

### La dérogation qui reste, et jusqu'à quand

**Bypass list** : le rôle **Repository admin**, en mode **Pull requests** uniquement.

Elle n'existe que pour une raison : release-please crée sa pull request de version avec le
jeton par défaut de GitHub Actions, et GitHub ne déclenche aucun workflow sur une pull
request créée par ce jeton — pour éviter les boucles. Les contrôles ne se posent donc
jamais sur une PR de release, qui resterait bloquée indéfiniment.

Les dépôts qui ont un `RELEASE_TOKEN` (ci-dessous) n'ont pas ce problème et **ne doivent
pas avoir de dérogation du tout**.

Jamais le mode **Always** : il autorise aussi les pushes directs sur `main`.

Cette dérogation disparaît le jour où une **GitHub App** remplace les jetons personnels :
installée une fois sur l'organisation, elle fabrique à la volée un jeton de courte durée
pour chaque dépôt, les workflows se déclenchent normalement, et plus aucun secret n'est à
recopier. C'est le bon moment pour la mettre en place : au passage sur le GitHub de
l'entreprise. Sur un compte personnel elle n'apporte rien, sa clé privée devant être
recopiée dans chaque dépôt.

## Règle sur les tags de version

**New ruleset → New tag ruleset**, nommée `tags`.

- **Target tags** : `Include` → `v*`.
- Cocher **Block force pushes** et **Restrict updates** : une version publiée ne bouge
  plus. Un tag posé par erreur se supprime, il ne se déplace pas.

## Token de release

Les dépôts qui publient une version (core, extensions, projets clients) ont besoin d'un
secret nommé `RELEASE_TOKEN` : **Settings → Secrets and variables → Actions → New
repository secret**.

C'est un *fine-grained personal access token* sur ce dépôt, avec les permissions
`Contents: Read and write` et `Pull requests: Read and write`. Il sert à release-please,
dont les pull requests doivent déclencher la CI — ce que le token par défaut de GitHub
Actions ne permet pas.

Ce token se crée et se colle **dans l'interface de GitHub uniquement** : jamais dans un
fichier, un commit ou une conversation.

## Actions

**Settings → Actions → General** :

- **Workflow permissions** : `Read repository contents and packages permissions`. Chaque
  workflow demande lui-même ce dont il a besoin.
- **Allow GitHub Actions to create and approve pull requests** : coché, pour release-please.

## Divers

- **Settings → General → Pull Requests** : ne garder que **Allow squash merging**, avec
  *Default to pull request title*. Une pull request = un commit sur `main`, dont le titre
  devient le message — c'est ce que lit release-please. Un merge commit ou un rebase
  ferait arriver sur `main` des messages qu'il ne sait pas lire, et la version suivante
  sortirait fausse, ou pas du tout. En une commande :

  ```bash
  gh api repos/david-grosskost/<depot> -X PATCH \
    -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
    -F delete_branch_on_merge=true --jq '.name + " : regle"'
  ```
- **Automatically delete head branches** : coché.
- **Settings → Code security** : activer **Dependabot alerts** et **Dependabot security
  updates**.

## Vérifier un dépôt existant

```bash
gh api repos/david-grosskost/<depot>/rulesets --jq '.[] | {name, target, enforcement}'
gh api repos/david-grosskost/<depot> --jq '{squash: .allow_squash_merge, merge: .allow_merge_commit, rebase: .allow_rebase_merge, suppression: .delete_branch_on_merge}'
```

La première commande doit montrer deux règles `active`, une `branch` et une `tag` ; la
seconde, `squash: true` et les deux autres à `false`.
