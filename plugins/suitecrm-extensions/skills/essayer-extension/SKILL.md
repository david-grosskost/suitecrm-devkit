---
name: essayer-extension
description: Essaie une extension SuiteCRM 8 sur l'instance locale de suitecrm-core (Docker sur le poste) - installation par le Chargeur de module, exemple concret du besoin, test de régression, désinstallation - et rend un compte rendu. À utiliser avant une pull request d'extension, ou quand on demande « essaie / teste cette extension dans SuiteCRM ».
---

# Essayer une extension dans SuiteCRM

Il faut Docker, suitecrm-core et l'extension sur le poste (façons 1 et 2 du skill
`nouvelle-extension`). Sans Docker, dis-le et arrête-toi : l'essai se fera sur l'instance
de test de la pull request, ou par un développeur.

Façon 1 : tu lances les commandes. Façon 2 : tu les donnes une à une, la personne colle le
résultat, tu le lis.

Le détail des commandes est dans `../nouvelle-extension/references/essai-local.md` :
lis-le d'abord.

## 1. Préparer

- Le besoin : `docs/utilisation.md` de l'extension, ou l'entretien. Écris l'exemple concret
  à refaire (qui, quel écran, quelle saisie, quel résultat attendu).
- suitecrm-core à jour sur `main`, l'instance démarrée (`make app@start`), une sauvegarde
  (`make db@dump NAME=avant-<slug>`).
- Le paquet : `make package@build` dans l'extension, puis `make package@scan`.

## 2. Essayer

1. **Installer** par Administration → Chargeur de module (Claude in Chrome si disponible,
   sinon la personne, guidée écran par écran). Noter le message du script d'installation.
2. **L'exemple concret**, après Ctrl+F5 : faire la saisie, constater le résultat. Pour un
   cas d'erreur prévu (contrôle de saisie), le provoquer aussi.
3. **Ce qui ne doit pas changer** : un autre module, un enregistrement sans rapport.
4. **Le test de régression** dans suitecrm-core : `make test@regression`.
5. Avec des données de démo : `make db@seed`, et vérifier ce que l'extension remplit.
6. **Désinstaller** (même écran) et vérifier que tout est revenu comme avant ; puis
   `make db@restore` si l'essai a laissé des données.

Une erreur : `make app@logs`, la console du navigateur, puis
`../nouvelle-extension/references/pieges.md`. Ne corrige pas le code pendant l'essai : note,
et laisse la correction à la fabrication.

## 3. Compte rendu

En français, en mots simples :

- **Résultat** en une ligne : l'extension fait ce qui est demandé, ou non.
- Chaque étape : ce qui a été fait, ce qui a été vu (message, valeur, capture si utile).
- Les écarts, chacun avec ce qu'il faudrait corriger.
- Ce qui n'a pas pu être essayé, et pourquoi.

Ce compte rendu va dans la description de la pull request (« Comment c'est vérifié »).
