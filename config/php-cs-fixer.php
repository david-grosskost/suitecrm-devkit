<?php

// Shared PHP-CS-Fixer configuration of the SuiteCRM projects.
// A project's .php-cs-fixer.dist.php only returns this file:
//   return require __DIR__ . '/vendor/david-grosskost/suitecrm-devkit/config/php-cs-fixer.php';

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = Finder::create()
    ->in(getcwd())
    ->exclude(['vendor', '.tools', 'node_modules']);

return (new Config())
    ->setRules(['@PER-CS' => true])
    ->setFinder($finder)
    ->setCacheFile(getcwd() . '/.php-cs-fixer.cache');
