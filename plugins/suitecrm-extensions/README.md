# Plugin Claude `suitecrm-extensions`

Le savoir-faire pour créer et faire évoluer les extensions SuiteCRM 8, utilisable par
n'importe qui dans l'entreprise, y compris sans connaissance technique. Il vit ici, dans
suitecrm-devkit, et pas dans chaque extension : une correction du plugin profite à tout le
monde, quel que soit le nombre d'extensions.

| Contenu | Rôle |
|---|---|
| skill `nouvelle-extension` | de l'entretien sur le besoin métier à la pull request ; ses `references/` détaillent chaque type d'extension, le paquet, l'essai local et les pièges connus |
| skill `relire-extension` | relit une pull request sans avoir vu sa fabrication, avis classé (bloquant, à corriger, remarque) |
| skill `essayer-extension` | essaie l'extension sur l'instance locale de suitecrm-core et rend un compte rendu |
| agent `relecteur` | Claude Code : lance `relire-extension` dans un contexte neuf |
| agent `testeur` | Claude Code : lance `essayer-extension` dans un contexte neuf |

Les agents n'existent que dans Claude Code ; dans l'application Claude, les skills font le
même travail. La relecture garde son intérêt si elle se fait dans une **nouvelle
conversation** : le relecteur ne doit pas avoir vu la fabrication.

## Trois façons de travailler

Le skill `nouvelle-extension` s'adapte au poste de la personne :

| Façon | Pour qui | Vérifications | Essai dans SuiteCRM |
|---|---|---|---|
| 1. Claude lance les commandes | Claude Code, ou application reliée au poste avec un terminal | toutes | oui |
| 2. La personne lance les commandes | application Claude, Docker et le devkit installés | toutes | oui |
| 3. Sans Docker | application Claude seule | format et syntaxe ; le reste par la CI | non : après la pull request |

L'essai sans Docker attend une instance de test par pull request (à venir).

## Installer

Claude Code :

```text
/plugin marketplace add david-grosskost/suitecrm-devkit
/plugin install suitecrm-extensions@suitecrm-devkit
```

Mettre à jour : `/plugin marketplace update suitecrm-devkit`.

Application Claude : un administrateur de l'organisation ajoute le plugin au catalogue de
l'organisation, depuis ce dépôt ; chacun l'active ensuite pour lui.

## Faire évoluer

- Chaque extension réalisée ajoute au skill son type, son exemple et ses pièges, dans
  `skills/nouvelle-extension/references/` : il ne couvre que des cas réellement validés sur
  une instance SuiteCRM. Le `SKILL.md` reste court : le déroulé, et quelle référence lire.
- Monter `version` dans `.claude-plugin/plugin.json` à chaque changement (0.x : `minor` pour
  un nouveau type, un skill ou une étape, `patch` pour une précision ou un piège).
