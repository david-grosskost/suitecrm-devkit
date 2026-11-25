---
name: relire-extension
description: Relit une pull request d'extension SuiteCRM 8 (dépôt suitecrm-ext-<slug>) comme un développeur qui n'a pas vu sa fabrication, et rend un avis classé (bloquant, à corriger, remarque) en mots simples. À utiliser après le skill nouvelle-extension, avant le merge, ou quand on demande « relis cette PR / cette extension ».
---

# Relire une extension SuiteCRM

Tu relis **sans avoir vu la fabrication** : ne te fie ni à la conversation qui a produit le
code, ni à la description de la pull request. Pars du besoin écrit, puis du code. Si tu as
toi-même écrit ce code dans cette conversation, dis-le en tête de l'avis : un développeur
devra relire aussi.

Tu ne modifies rien : tu rends un avis. Les corrections se font ensuite, dans la pull
request.

## 1. Rassembler

- La pull request : titre, description, fichiers changés (`git diff main...HEAD`, ou la page
  « Files changed » sur GitHub), état de la CI.
- `extension.json`, `README.md`, `docs/`, le `CLAUDE.md` du dépôt.
- Les références du skill `nouvelle-extension` qui correspondent aux types de l'extension
  (`../nouvelle-extension/references/` : le type, `paquet.md`, `pieges.md`) : ce sont les
  règles validées.

## 2. Vérifier, dans cet ordre

**Le besoin.** Le code fait-il ce que disent la description et `docs/utilisation.md`, ni
plus, ni moins ? Un comportement non décrit est un défaut, même utile.

**Les interdits** (bloquant, renvoyer à un développeur) :
- un fichier qui remplace ou modifie SuiteCRM au lieu d'ajouter (hors des emplacements du
  tableau « Où mettre quoi ») ;
- des données envoyées hors de SuiteCRM (appel HTTP, e-mail à des tiers) ;
- un secret dans le code, les tests ou la description ;
- un changement de droits, de rôles ou de sécurité.

**Ce qui casse une instance** (bloquant) :
- signature de hook différente de la référence (`mixed $arguments = null`) ;
- classe utilisée sans être chargée par son fichier ;
- fonction ou classe déclarée dans `legacy/Extension/` sans garde (`function_exists`) ;
- lien d'administration sans `module=` (menu vide dans toute l'interface) ;
- affectation de `$admin_option_defs` ou d'un tableau partagé au lieu d'un ajout ;
- seeder qui charge une classe par un chemin relatif vers `legacy/` ;
- appel refusé par le scanner du Chargeur de module (`array_map`, `array_filter`, `echo`,
  fonctions de fichiers…) dans `legacy/`, `backend/`, `config/` ou `database/` ;
- `install.php` qui écrase ce que l'administrateur a pu changer, ou `uninstall.php` qui
  supprime plus que ce que l'installation a fait.

**La qualité** (à corriger) :
- logique dans les fichiers de déclaration au lieu de `legacy/include/<slug>/` ;
- cas métier de l'entretien absents des tests, test du hook qui n'appelle pas comme
  SuiteCRM ;
- libellé manquant dans une des deux langues, texte visible en anglais ;
- documentation qui ne dit plus vrai, lien cassé entre pages ;
- titre de PR au-delà de 65 caractères, commit hors Conventional Commits.

**Les remarques** : lisibilité, nommage, simplifications. Pas de goût personnel présenté
comme une règle.

Pour chaque point, vérifie dans le code avant de l'écrire : cite le fichier et la ligne. Un
doute non vérifié n'est pas un défaut ; écris-le comme une question.

## 3. Rendre l'avis

En français, pour une personne qui n'est pas forcément développeur :

1. **Verdict** en une ligne : prête à fusionner, à corriger, ou à renvoyer vers un
   développeur.
2. **Bloquant**, puis **À corriger**, puis **Remarques** : pour chacun, le fichier et la
   ligne, ce qui ne va pas en une phrase simple, ce qui arriverait sur une instance, la
   correction proposée.
3. **Ce qui n'a pas pu être vérifié** (essai dans SuiteCRM non fait, CI pas encore passée).

Si la personne le demande, publie l'avis en commentaire de la pull request (avec son
accord, et sans approuver la PR à la place d'un humain).
