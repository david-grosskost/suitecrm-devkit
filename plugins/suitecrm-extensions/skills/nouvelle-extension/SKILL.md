---
name: nouvelle-extension
description: Guide la création ou la modification d'une extension SuiteCRM 8 (dépôt suitecrm-ext-<slug>, créé depuis suitecrm-extension-template), de l'entretien sur le besoin métier jusqu'à la pull request, y compris avec une personne sans connaissance technique, avec ou sans Docker sur son poste. À utiliser quand on demande d'ajouter un comportement à SuiteCRM (« quand on enregistre un compte… », « ajouter un champ… », « corriger tel bug de SuiteCRM ») ou de changer une extension existante.
---

# Créer ou modifier une extension SuiteCRM

Principe : **le skill guide, la CI garantit.** Tu fais le travail technique ; la personne
décrit le besoin et valide le résultat. Les vérifications (`make …`, CI, relecture) ne se
contournent jamais : si l'une échoue, on corrige, on ne la désactive pas.

Ce skill ne couvre que ce qui a été **réellement validé** sur une instance SuiteCRM. Un
besoin qui ne rentre dans aucun type validé : explique-le, propose de faire appel à un
développeur, ne l'improvise pas.

Parle en français, en mots métier, sans jargon. Code, commentaires et commits en anglais ;
textes vus par l'utilisateur en français.

Les détails de chaque étape sont dans `references/` : ne lis que ceux dont le besoin a
besoin, au moment où tu en as besoin.

## 0. La façon de travailler

Avant tout, établis laquelle des trois s'applique (demande-le si tu ne peux pas le voir) :

| Façon | Qui lance les commandes | Vérifications locales | Essai dans SuiteCRM |
|---|---|---|---|
| **1. Claude lance** : Claude Code, ou l'application reliée au poste avec un terminal | toi, sur le poste | toutes (étape 6) | oui (étape 7) |
| **2. La personne lance** : application Claude, Docker et le devkit sur son poste | la personne, dans Git Bash | toutes, par elle | oui, par elle |
| **3. Sans Docker** : application Claude seule | toi, dans ton espace de travail | celles sans Docker | non : la CI et le relecteur |

- **Façon 2** : donne **une commande à la fois**, dans un bloc à copier, en disant avant ce
  qu'elle fait et ce que la personne doit voir. Demande-lui de coller le résultat ; lis-le
  toi-même plutôt que de lui faire interpréter. Pour écrire des fichiers sur son poste, une
  commande qui écrit le fichier entier (`cat > fichier <<'EOF'`) vaut mieux qu'une
  modification à faire à la main.
- **Façon 3** : clone le dépôt dans ton espace de travail, travaille sur une branche, lance
  ce qui ne demande pas Docker (étape 6), pousse la branche et ouvre la pull request.
  Préviens la personne au départ : l'extension ne sera essayée dans SuiteCRM qu'après la
  pull request, par un développeur ou l'instance de test de la PR.
- Avant toute commande `make`, le dépôt doit être à jour :
  `git checkout main && git pull --ff-only && git checkout -b <branche>` (s'arrêter si le
  `pull` échoue).

## 1. Comprendre le besoin (entretien)

Pose les questions une par une, en mots simples, et reformule à la fin :

1. **Quoi** : que doit-il se passer ? Demande un exemple concret (« quand Marie enregistre
   le compte Dupont SARL, alors… »).
2. **Où** : quel écran, quel module (comptes, contacts, opportunités…) ?
3. **Quand** : à l'enregistrement, à l'affichage, chaque nuit, à la connexion… ?
4. **Pour qui** : tous les utilisateurs, certains seulement ?
5. **Comment vérifier** : qu'est-ce qui prouvera que ça marche ? Ce sera le test.

Écris le besoin en 3 à 5 phrases métier : elles serviront à `extension.json`, au README et
à la pull request. Fais-les valider avant d'écrire du code.

Avant de créer une extension, regarde si une extension existante fait déjà une partie du
besoin (les dépôts `suitecrm-ext-*` de david-grosskost sur GitHub, dont les exemples du
tableau ci-dessous) : la modifier vaut souvent mieux.

## 2. Trier le besoin

| Le besoin… | Type | À lire | Exemple |
|---|---|---|---|
| réagit à un événement (enregistrement, connexion, chaque requête) | `logic-hook` | `references/logic-hook.md` | upstream-fixes |
| ajoute des champs à un module existant (et leur panneau sur la fiche) | `fields` | `references/champs.md` | french-company-fields |
| contrôle une saisie sur la fiche (message sous le champ, enregistrement refusé) | `logic-hook` + `fields` | `references/controle-de-saisie.md` | french-company-validation |
| tourne à heure fixe | `scheduler` | `references/planificateur-et-administration.md` | opportunity-reminders |
| a un réglage modifiable par l'administrateur (page dans Administration) | `ui` | `references/planificateur-et-administration.md` | opportunity-reminders, login-background |
| change l'affichage de SuiteCRM 8 (format, style, comportement de l'interface) | `ui` | `references/module-angular.md` | french-currency-format, custom-theme, pwa |
| traduit ou renomme des libellés | `lang` | `references/champs.md` (libellés) | french-locale |
| fait quelque chose une fois à l'installation, ou apporte des données de démo | tous | `references/scripts-et-donnees-de-demo.md` | french-company-fields |

Toute extension s'installe par un paquet du Chargeur de module : lis `references/paquet.md`
dès qu'elle a un script d'installation ou du PHP au-delà des déclarations (le scanner du
Chargeur de module refuse certaines fonctions).

**Refuse et renvoie vers un développeur**, en expliquant pourquoi sans jargon : modification
du cœur de SuiteCRM ou de suitecrm-core, envoi de données hors de SuiteCRM (API externe,
e-mail automatique à des tiers), secrets (mots de passe, clés d'API), droits et sécurité, ou
un besoin qui ne rentre dans aucun type.

## 3. Préparer le dépôt

Pour une extension existante : cloner, brancher depuis `main` à jour, passer à l'étape 4.

Pour une nouvelle : un développeur (ou la personne, sur GitHub) crée le dépôt depuis
`suitecrm-extension-template`, nommé `suitecrm-ext-<slug>`.

- **Slug** : minuscules, chiffres et tirets, 40 caractères au plus, **en anglais**
  (`french-company-validation`, `opportunity-reminders`), comme le nom du dépôt et du
  paquet. Il préfixe tous les fichiers de l'extension.
- **Réglages GitHub** : un dépôt créé depuis le modèle n'en hérite pas. Le propriétaire les
  pose avant le premier merge, en suivant `docs/reglages-github.md` du devkit : Actions
  autorisées à créer des pull requests (sinon pas de release), règle `main` (pull request
  obligatoire, 0 approbation, checks `checks / commit-msg` et `checks / quality`, squash),
  suppression automatique des branches fusionnées. Tu ne peux pas les poser : demande-les.
- **Renommer le paquet sur `main` d'abord**, dans une petite PR à part
  (`chore: rename the package`) : dans `composer.json`, `name` en
  `david-grosskost/suitecrm-ext-<slug>` et `description`. Composer prend le nom du paquet sur
  la branche par défaut : tant que `main` s'appelle encore `suitecrm-ext-exemple`, l'essai
  dans le core répond « could not be found in any version ». Mettre exactement le même texte
  que dans la branche de travail, pour éviter un conflit au merge. Le check
  `extension@validate` de cette PR échoue (le slug de `extension.json` est encore `exemple`) :
  c'est attendu, l'administrateur la fusionne en contournant la règle.
- Dependabot ouvre aussitôt une PR qui passe le devkit à sa dernière version (composer.json
  et workflows ensemble) : la fusionner d'abord.
- **Remplacer l'exemple**, dans une branche `feature/<ticket>/<description>` :
  - `extension.json` : `slug`, `name` (français), `description` (le besoin en mots métier,
    20 caractères au moins), `types`, `suitecrm` ;
  - `composer.json` : `name`, `description`, et le namespace des tests dans `autoload-dev` ;
  - supprimer `legacy/include/exemple/`, `tests/ExempleTest.php` et `CHANGELOG.md` (celui du
    modèle) ; vérifier que `.release-please-manifest.json` vaut `"0.0.0"` (première release
    en 0.1.0).
- **Version de SuiteCRM** (`suitecrm`) : `>=8.10 <9` pour un ajout ; pour un correctif de bug
  de SuiteCRM, la seule version mineure vérifiée (`>=8.10 <8.11`), à revérifier à chaque
  nouvelle version.

## 4. Fabriquer

Lis la ou les références du tri (étape 2) et suis-les. Règles communes :

- **Le slug dans chaque nom de fichier** de `legacy/Extension/` ; toute la logique dans des
  classes de `legacy/include/<slug>/`, sans dépendance à SuiteCRM, testables seules. Les
  fichiers de déclaration ne font que déclarer.
- **Jamais rien hors des emplacements prévus** (tableau « Où mettre quoi » du `CLAUDE.md` du
  dépôt) : `make extension@validate` le refuse.
- Les fichiers de `legacy/Extension/` ne contiennent que des tableaux : SuiteCRM les charge
  parfois plusieurs fois, par `require` et non `require_once`. Jamais de fonction ni de
  classe déclarée sans `if (!function_exists(…))`.
- Chaque libellé dans les deux langues (`fr_FR` et `en_us`), avec son `@var` pour PHPStan.

## 5. Tester

Dans `tests/<Classe>Test.php`, namespace `SuiteCrmExt\<Namespace>\Tests` :

- les cas métier de l'entretien, un par ligne d'un `DataProvider`, avec un nom en français ;
- les cas limites (vide, espaces, valeur inattendue) ;
- **un test qui appelle la méthode du hook exactement comme SuiteCRM** : mêmes arguments,
  `null` compris ;
- pour des champs : les définitions (vardefs, libellés dans les deux langues, chaque option
  de liste traduite) et le panneau dans la mise en page de Studio : ajout avec et sans
  onglets, rien si un champ est déjà placé, retrait où que Studio ait mis les champs ;
- pour un seeder : ce qu'il calcule (fonctions pures), et qu'il ne remplace jamais une
  valeur.

## 6. Vérifier

**Façons 1 et 2**, dans le dossier de l'extension :

```bash
make extension@validate && make quality@lint && make quality@stan && make test@unit
```

Avec un module Angular (`app/`), ajouter `make front@check`. Avec un script d'installation
ou du PHP chargé par SuiteCRM : `make package@build && make package@scan`.

**Façon 3**, dans ton espace de travail (PHP y est, Docker non) :

- le format : cloner `https://github.com/david-grosskost/suitecrm-devkit` à côté et lancer
  `php ../suitecrm-devkit/.make/scripts/extension/validate.php` depuis le dossier de
  l'extension ;
- la syntaxe : `php -l` sur chaque fichier PHP modifié ;
- les tests, le style et PHPStan, si Composer peut installer les dépendances
  (`composer install`) ; sinon, la CI de la pull request les fera : dis-le.

Explique chaque échec en une phrase simple, corrige, relance. N'ajoute jamais d'exception
pour faire passer une vérification : demande à un développeur si tu bloques. Les pièges
connus sont dans `references/pieges.md` : lis-le dès qu'une vérification échoue de façon
inattendue.

## 7. Essayer dans SuiteCRM

Façons 1 et 2 seulement : lance le skill `essayer-extension` (ou l'agent `testeur` dans
Claude Code), qui suit `references/essai-local.md` et rend un compte rendu. Il refait
l'exemple concret de l'entretien avec la personne, puis le test de régression
(`make test@regression` dans suitecrm-core), qui parcourt les écrans principaux avec toutes
les extensions installées.

Façon 3 : sauter, et l'écrire dans la pull request (« pas essayée dans SuiteCRM »).

## 8. Documenter

Le `README.md` et `docs/` suivent le plan du modèle (`suitecrm-extension-template`) :

- `README.md` : la fiche (ce que fait l'extension, types, version de SuiteCRM), comment
  l'installer, le tableau des pages de `docs/` ;
- `docs/utilisation.md` : pour l'utilisateur et l'administrateur, en mots métier, avec
  l'exemple de l'entretien ;
- `docs/fonctionnement.md` : comment elle s'y prend, ce qu'elle ne fait pas, ses limites ;
- `docs/developpement.md` : les fichiers, les tests, comment l'essayer ;
- `docs/depannage.md` si des problèmes connus existent.

Toute pull request qui change le comportement met ces pages à jour : ce qu'elles disent doit
rester vrai. Les liens entre pages se vérifient (fichier existant, ancre existante).

## 9. Pull request

- Commit en anglais, Conventional Commits : `feat: <ce que fait l'extension>` (`fix: …` pour
  corriger, `docs: …` pour la documentation seule). Le titre de la PR est le même et devient
  le message sur `main` : **65 caractères au plus** (`checks / commit-msg` refuse au-delà de
  72, et GitHub ajoute ` (#NN)`).
- Enchaîner vérifications et commit sur une seule ligne avec `&&` : un commit ne part pas
  après un échec.
- **`make git@pr`** pousse la branche et ouvre la PR avec le titre du premier commit. Une fois
  par poste : `make git@gh`, puis la personne se connecte elle-même avec
  `.tools/bin/gh auth login` : jamais de jeton dans la conversation. Sans gh : pousser, puis
  ouvrir la PR sur GitHub par le lien qu'affiche `git push`.
- Description : le besoin en mots métier, comment il a été vérifié (tests, essai local ou
  « pas essayée dans SuiteCRM »), ce qu'il reste à faire.
- **Relecture** : lance le skill `relire-extension` (ou l'agent `relecteur` dans Claude
  Code) sur la pull request, qui la relit sans avoir vu sa fabrication. Corrige ce qu'il
  signale de bloquant, puis un développeur relit et fusionne (squash).
- Après le merge, la PR de release (« chore(main): release x.y.z ») ouvre la version ; sa
  fusion pose le tag. Elle demande parfois **Approve workflows to run** avant que sa CI ne
  tourne (`references/pieges.md`).
- Ensuite seulement, l'extension peut entrer dans le catalogue de suitecrm-core ou d'un
  projet client (`repositories`, `require` avec `^<version>`) : c'est le travail d'un
  développeur. Y entrer la rend **disponible** sur toutes les instances, pas installée : une
  extension métier s'installe instance par instance (Chargeur de module, ou
  `make extensions@install SLUGS=<slug>`). Seules les extensions obligatoires
  (`required-extensions` dans le `composer.json` du core) sont installées d'office.
- Déployer une instance (workflow Deploy, Run workflow) : choisir **le tag** de la release
  dans « Use workflow from ». Avec `main`, le déploiement est ignoré (« Skipped »).

## Après coup

Un piège rencontré, un type nouveau validé : ajoute-le à `references/` (dans le devkit,
`plugins/suitecrm-extensions/`) dans une pull request, et monte la version du plugin. Le
skill ne vaut que ce qu'il a appris.
