---
name: nouvelle-extension
description: Guide la création ou la modification d'une extension SuiteCRM 8 (dépôt suitecrm-ext-<slug>, créé depuis suitecrm-extension-template), de l'entretien sur le besoin métier jusqu'à la pull request, y compris avec une personne sans connaissance technique. À utiliser quand on demande d'ajouter un comportement à SuiteCRM (« quand on enregistre un compte… », « ajouter un champ… », « corriger tel bug de SuiteCRM ») ou de changer une extension existante.
---

# Créer ou modifier une extension SuiteCRM

Principe : **le skill guide, la CI garantit.** Tu fais le travail technique ; la personne
décrit le besoin et valide le résultat. Les vérifications (`make …`, CI, relecture humaine)
ne se contournent jamais : si l'une échoue, on corrige, on ne la désactive pas.

Ce skill ne couvre que ce qui a été **réellement validé** sur une instance SuiteCRM. Un
type marqué « pas encore validé » plus bas : explique-le, propose de faire appel à un
développeur, ne l'improvise pas.

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

## 2. Trier le besoin

| Le besoin… | Type | Statut |
|---|---|---|
| réagit à un événement (enregistrement, connexion, chaque requête) | `logic-hook` | **validé** (upstream-fixes) |
| ajoute ou change des champs, un module | `fields` | pas encore validé |
| change l'interface (écran, bouton, style) | `ui` | pas encore validé |
| tourne à heure fixe | `scheduler` | pas encore validé |
| traduit ou renomme des libellés | `lang` | pas encore validé |

**Refuse et renvoie vers un développeur**, en expliquant pourquoi sans jargon :
modification du cœur de SuiteCRM ou de suitecrm-core, envoi de données hors de SuiteCRM,
secrets (mots de passe, clés d'API), droits et sécurité, ou un besoin qui ne rentre dans
aucun type.

## 3. Préparer le dépôt

Le dépôt a été créé depuis `suitecrm-extension-template`, nommé `suitecrm-ext-<slug>`.

- **Slug** : minuscules, chiffres et tirets, 40 caractères au plus, en anglais de préférence
  (`siret-validation`, `upstream-fixes`). Il préfixe tous les fichiers de l'extension.
- **Réglages GitHub** : un dépôt créé depuis le modèle n'en hérite pas. Un administrateur du
  dépôt doit, avant le premier merge :
  - dans Settings → Actions → General, cocher « Allow GitHub Actions to create and approve
    pull requests » (sinon pas de release) ;
  - dans Settings → Rules, importer la règle `main` du modèle (PR obligatoire, relecture du
    code owner, squash uniquement, checks `checks / commit-msg` et `checks / quality`) ;
  - dans Settings → General, cocher « Automatically delete head branches ».
- **Remplacer l'exemple**, dans une branche `feature/<ticket>/<description>` :
  - `extension.json` : `slug`, `name` (français), `description` (le besoin en mots métier,
    20 caractères au moins), `types`, `suitecrm` ;
  - `composer.json` : `name` en `david-grosskost/suitecrm-ext-<slug>`, `description`, et le
    namespace des tests dans `autoload-dev` ;
  - supprimer `legacy/include/exemple/`, `tests/ExempleTest.php` et `CHANGELOG.md` ;
  - `.release-please-manifest.json` : remettre `"."` à `"0.0.0"` (la première release sera
    0.1.0, pas la version du modèle) ;
  - `README.md` : ce que fait l'extension, en mots métier.
- **Version de SuiteCRM** (`suitecrm`) : `>=8.10 <9` pour un ajout ; pour un correctif de bug
  de SuiteCRM, la seule version mineure vérifiée (`>=8.10 <8.11`), à revérifier à chaque
  nouvelle version.

## 4. Fabriquer : logic hook (validé)

Deux fichiers, et la logique dans le second :

**La déclaration** : `legacy/Extension/<cible>/Ext/LogicHooks/<slug>.php`, où `<cible>` vaut
`application` (hooks globaux : `after_entry_point`, `after_login`…) ou `modules/<Module>`
(hooks d'un module : `before_save`, `after_save`…).

```php
<?php

// <Ce que fait le hook, en une phrase.>

$hook_version = 1;

/** @var array<string, list<array{int, string, string, string, string}>> $hook_array Set by SuiteCRM */
$hook_array['<evenement>'][] = [
    10,
    '<slug> : <description courte>',
    'custom/include/<slug>/<Classe>.php',
    'SuiteCrmExt\<Namespace>\<Classe>',
    '<methode>',
];
```

**La classe** : `legacy/include/<slug>/<Classe>.php`, namespace `SuiteCrmExt\<Namespace>`
(le slug en PascalCase : `upstream-fixes` → `UpstreamFixes`), `declare(strict_types=1)`,
`final class`. La méthode du hook ne fait qu'appeler des méthodes statiques pures, que les
tests appellent directement.

**Signature de la méthode : exactement celle avec laquelle SuiteCRM l'appelle.**

- Hook global (`application`, sans enregistrement) :
  `public function <methode>(string $event, mixed $arguments = null): void`
- Hook de module (avec enregistrement) :
  `public function <methode>(\SugarBean $bean, string $event, mixed $arguments = null): void`

## 5. Tester

Dans `tests/<Classe>Test.php`, namespace `SuiteCrmExt\<Namespace>\Tests` :

- les cas métier de l'entretien, un par ligne d'un `DataProvider`, avec un nom en français ;
- les cas limites (vide, espaces, valeur inattendue) ;
- **un test qui appelle la méthode du hook exactement comme SuiteCRM** : mêmes arguments,
  `null` compris.

## 6. Vérifier (local)

```bash
make extension@validate && make quality@lint && make quality@stan && make test@unit
```

Explique chaque échec en une phrase simple, corrige, relance. Ne désactive jamais une règle
et n'ajoute jamais d'exception pour faire passer une vérification : demande à un
développeur si tu bloques.

## 7. Essayer dans SuiteCRM (local)

Dans le dossier de suitecrm-core, sur sa propre branche, **sans commiter** :

1. Dans `composer.json`, ajouter le dépôt dans `repositories`
   (`{ "type": "vcs", "url": "https://github.com/david-grosskost/suitecrm-ext-<slug>", "no-api": true }`)
   et l'extension dans `require` (`"david-grosskost/suitecrm-ext-<slug>": "dev-<branche>"`),
   **sans virgule après la dernière ligne** ; pousser la branche de l'extension avant.
2. `make composer@update PACKAGES=david-grosskost/suitecrm-ext-<slug>`
3. Ajouter le slug à `EXTENSIONS` dans `.env.local` (séparés par des virgules, garder
   `upstream-fixes`), puis `make app@start && make app@logs` : on doit voir
   `activation (…<slug>…)` puis `Réparation rapide faite`.
4. Refaire l'exemple concret de l'entretien dans https://suitecrm-core.dev.localhost avec
   la personne.
5. Annuler : `git checkout -- composer.json composer.lock && make composer@install`, retirer
   le slug de `.env.local`, `make app@start`.

Si le conteneur redémarre en boucle après l'activation, c'est presque toujours une erreur
fatale PHP dans le hook (signature, fichier introuvable) : `make app@logs`.

## 8. Pull request

- Commit en anglais, Conventional Commits : `feat: <ce que fait l'extension>`
  (`fix: …` pour corriger). Le titre de la PR est le même : il devient le message sur `main`.
- Description de la PR : le besoin en mots métier, comment il a été vérifié (tests, essai
  local), et ce qu'il reste à faire.
- Un développeur relit avant le merge (squash). Après le merge, la PR de release ouvre la
  version ; la mergée pose le tag.
- Ensuite seulement, l'extension peut entrer dans le catalogue de suitecrm-core ou d'un projet
  client (`repositories`, `require` avec `^<version>`, `EXTENSIONS`) : c'est le travail d'un
  développeur.

## Pièges déjà rencontrés

- PHPStan « Cannot access an offset on mixed » sur `$hook_array` : il manque l'annotation
  `@var` de l'étape 4.
- Hook global déclaré avec `array $arguments` : SuiteCRM passe `null`, erreur fatale sur
  **chaque page** et conteneur qui redémarre en boucle. Toujours `mixed $arguments = null`.
- Première release en 0.2.0 au lieu de 0.1.0 : `.release-please-manifest.json` pas remis à
  `0.0.0`.
- Release qui échoue (« GitHub Actions is not permitted to create pull requests ») :
  réglage Actions du dépôt pas fait (étape 3).
- Merge impossible alors que tout est vert : la relecture obligatoire ; l'auteur ne peut pas
  s'approuver lui-même, un administrateur merge en contournant la règle.
