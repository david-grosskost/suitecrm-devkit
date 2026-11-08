# Plugin Claude `suitecrm-extensions`

Le savoir-faire pour créer et faire évoluer les extensions SuiteCRM 8, utilisable par
n'importe qui dans l'entreprise, y compris sans connaissance technique. Il vit ici, dans
suitecrm-devkit, et pas dans chaque extension : une correction du plugin profite à tout le
monde, quel que soit le nombre d'extensions.

| Contenu | Rôle |
|---|---|
| skill `nouvelle-extension` | de l'entretien sur le besoin métier à la pull request |

À venir : un agent relecteur (examine la pull request sans avoir vu sa fabrication) et un
agent testeur (essaie l'extension sur une instance locale).

## Installer (Claude Code)

```text
/plugin marketplace add david-grosskost/suitecrm-devkit
/plugin install suitecrm-extensions@suitecrm-devkit
```

Mettre à jour : `/plugin marketplace update suitecrm-devkit`.

## Faire évoluer

- Chaque extension réalisée ajoute au skill son type, son exemple et ses pièges : il ne
  couvre que des cas réellement validés sur une instance SuiteCRM.
- Monter `version` dans `.claude-plugin/plugin.json` à chaque changement (0.x : `minor` pour
  un nouveau type ou une nouvelle étape, `patch` pour une précision ou un piège).
