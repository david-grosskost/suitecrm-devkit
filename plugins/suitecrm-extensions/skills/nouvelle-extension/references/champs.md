# Fabriquer : champs

Type `fields`, validé (french-company-fields). Ajouter des champs à un module existant, et leur panneau sur la fiche.

Exemple complet : `suitecrm-ext-french-company-fields`. Trois couches :

**Les champs** : `legacy/Extension/modules/<Module>/Ext/Vardefs/<slug>.php`, une entrée
`$dictionary['<Objet>']['fields']['<champ>']` par champ (`<Objet>` au singulier :
`Account` pour le module `Accounts`). Préfixer les champs (`fr_siret`) : pas de collision
avec SuiteCRM ni avec Studio (`_c`). Les colonnes sont créées par la réparation rapide
(repairDatabase) à l'activation ; un index se déclare dans `$dictionary['<Objet>']['indices']`.
Annotation obligatoire pour PHPStan :

```php
/** @var array<string, array<string, array<mixed>>> $dictionary Set by SuiteCRM */
```

**Les libellés** : `legacy/Extension/modules/<Module>/Ext/Language/{fr_FR,en_us}.<slug>.php`
(`$mod_strings['LBL_…']`, dont celui du panneau), et les listes déroulantes dans
`legacy/Extension/application/Ext/Language/{fr_FR,en_us}.<slug>.php`
(`$app_list_strings['<liste>']`, première clé `''` pour « aucune valeur »). Chacun avec son
`@var`.

**Le panneau sur la fiche : écrit une fois dans la mise en page de Studio**, par le script
d'installation (scripts-et-donnees-de-demo.md). Il appartient ensuite à Studio : l'administrateur le déplace,
le renomme ou le supprime, il n'est jamais remis. Ne pas l'ajouter à la volée (couche
SuiteCRM 8, `ViewDefinitionMapper`) : Studio ne pourrait plus ni le retirer ni le
renommer, et des champs déplacés apparaîtraient deux fois.

- La logique dans une classe sans dépendance à SuiteCRM, `legacy/include/<slug>/`, testée
  seule (exemple : `StudioPanel`). Elle travaille sur le format de Studio pendant l'édition
  (`GridLayoutMetaDataParser::$_viewdefs`) : panneaux → lignes → noms de champs.
- Une case vide se note **`(filler)`** : `(empty)` est supprimé à l'enregistrement, et le
  champ voisin prend alors toute la ligne.
- Clé du panneau en majuscules (`LBL_FR_COMPANY_PANEL`), qui est aussi la clé de son titre
  dans les libellés du module.
- **Fiche en onglets** (`templateMeta.tabDefs` non vide, comme les Comptes) : y ajouter
  `['newTab' => true, 'panelDefault' => 'expanded']` pour le panneau. Sans `tabDefs`, ne rien
  y mettre : tous les panneaux s'affichent, et un onglet masquerait les autres.
- Ne rien ajouter si le panneau ou un de ses champs est déjà dans la mise en page (placé par
  Studio).
