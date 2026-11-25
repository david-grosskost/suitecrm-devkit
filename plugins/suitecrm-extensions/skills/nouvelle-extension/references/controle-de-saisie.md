# Contrôler une saisie sur la fiche

Types `logic-hook` + `fields`, validé (french-company-validation).

Exemple complet : `suitecrm-ext-french-company-validation`. Deux niveaux, mêmes règles
(fonctions pures dans `legacy/include/<slug>/`) :

- **Pendant la saisie (SuiteCRM 8)** : un `asyncValidator` sur le champ, que la fiche appelle
  avant d'enregistrer ; tant qu'il répond une erreur, la fiche refuse l'enregistrement et
  affiche le message sous le champ.
  - L'ajouter par un `FieldDefinitionMapperInterface` (`backend/FieldDefinitions/`,
    `getModule()` `'default'`, module reconnu par `strtolower($definition->getId())`), qui
    ajoute `asyncValidators['<slug>'] = ['key' => '<processus>', 'params' => […]]` aux champs
    voulus. **Pas dans les fichiers de champs** (`Ext/Vardefs`) : l'ordre de fusion des
    extensions n'est pas garanti, l'ajout est perdu.
  - Le processus : un `ProcessHandlerInterface` (`backend/Process/`, `getProcessType()` = la
    clé). Il reçoit `options['value']` et `options['params']` ; en erreur :
    `setStatus('error')` et `setData(['errors' => ['startLabelKey' => '<LBL_…>']])`.
  - **Le message dans `$app_strings`** (`legacy/Extension/application/Ext/Language/`) : la
    fiche ne le cherche que là, pas dans les libellés du module (sinon, message vide).
  - Classes SuiteCRM 8 enregistrées et taguées par le core, sans fichier de services.
- **À chaque enregistrement (toute voie : import, API, workflow)** : un hook `before_save`
  qui nettoie la saisie (`$bean->{$champ} = …`) et refuse en levant une exception. SuiteCRM 8
  n'affiche alors qu'un message générique (« Une erreur s'est produite… ») : c'est le dernier
  rempart, la fiche a déjà prévenu l'utilisateur.
- Une extension qui complète celle d'une autre (ici les champs de french-company-fields) ne
  fait rien quand l'autre n'est pas active (champs absents) : le dire dans le README.
