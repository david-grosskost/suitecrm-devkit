# Fabriquer : logic hook

Type `logic-hook`, validé (upstream-fixes, french-company-validation). Réagir à un événement de SuiteCRM : enregistrement, connexion, chaque requête.

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
tests appellent directement. **SuiteCRM ne charge que le fichier déclaré dans le hook** :
les autres classes dont il se sert, ce fichier les charge lui-même
(`require_once __DIR__ . '/<Autre>.php';`), sinon chaque enregistrement plante. Les tests ne le
voient pas (l'autoload de Composer charge tout).

**Signature de la méthode : exactement celle avec laquelle SuiteCRM l'appelle.**

- Hook global (`application`, sans enregistrement) :
  `public function <methode>(string $event, mixed $arguments = null): void`
- Hook de module (avec enregistrement) :
  `public function <methode>(\SugarBean $bean, string $event, mixed $arguments = null): void`

**Les valeurs du `$bean` sont encodées en HTML** pendant l'enregistrement (`o&#039;brien`,
`dupont &amp; fils`). Pour transformer un texte (majuscules, nettoyage, découpage) :
décoder (`html_entity_decode($valeur, ENT_QUOTES, 'UTF-8')`), transformer, puis ré-encoder
(`htmlspecialchars($valeur, ENT_QUOTES, 'UTF-8')`) avant de le remettre dans le `$bean`.
Transformé tel quel, `&amp;` devient `&AMP;`, que plus rien ne décode. La classe pure
travaille sur le texte décodé ; le hook décode et ré-encode. Tester les deux formes.
