<?php

// Checks a SuiteCRM extension against the format of the projects (see the
// architecture decisions, "Format des extensions"): its manifest
// (extension.json), its composer.json, and where its files are. Every problem
// is listed at once, in French, for the person who made the extension.
// Run from the extension's root, by make extension@validate (in Docker).
//
// @usage php validate.php

declare(strict_types=1);

const TYPES = ['logic-hook', 'fields', 'ui', 'scheduler', 'lang'];
// Kebab-case, starts with a letter: the prefix of every file of the extension.
const SLUG = '/^[a-z][a-z0-9]*(-[a-z0-9]+)*$/';
const SLUG_MAX = 40;
const KEYS = ['$schema', 'slug', 'name', 'description', 'types', 'suitecrm'];
// Top-level directories an extension may have, besides the repository files.
const DIRS = ['backend', 'config', 'legacy', 'database', 'tests'];

$errors = [];

/**
 * Reads a JSON file as an object.
 *
 * @param list<string> $errors
 *
 * @return array<string, mixed>|null
 */
function readJson(string $file, array &$errors): ?array
{
    if (!is_file($file)) {
        $errors[] = "$file absent";

        return null;
    }
    $data = json_decode((string) file_get_contents($file), true);
    if (!is_array($data) || array_is_list($data)) {
        $errors[] = "$file : JSON invalide (" . json_last_error_msg() . ')';

        return null;
    }

    /** @var array<string, mixed> $data */
    return $data;
}

/**
 * Lists the files under a directory, relative to it.
 *
 * @return list<string>
 */
function filesUnder(string $dir): array
{
    if (!is_dir($dir)) {
        return [];
    }
    $files = [];
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($iterator as $file) {
        if ($file instanceof SplFileInfo && $file->isFile() && $file->getFilename() !== '.gitkeep') {
            $files[] = substr($file->getPathname(), strlen($dir) + 1);
        }
    }
    sort($files);

    return $files;
}

// 1. The manifest.
$manifest = readJson('extension.json', $errors);
$slug = '';
if ($manifest !== null) {
    foreach (array_diff(array_keys($manifest), KEYS) as $key) {
        $errors[] = "extension.json : clé inconnue « $key » (clés possibles : " . implode(', ', array_slice(KEYS, 1)) . ')';
    }

    $slug = is_string($manifest['slug'] ?? null) ? $manifest['slug'] : '';
    if (preg_match(SLUG, $slug) !== 1 || strlen($slug) > SLUG_MAX) {
        $errors[] = 'extension.json : slug invalide « ' . $slug . ' » (minuscules, chiffres et tirets, '
            . SLUG_MAX . ' caractères au plus, ex. siret-validation)';
    }

    $name = $manifest['name'] ?? null;
    if (!is_string($name) || trim($name) === '') {
        $errors[] = 'extension.json : name manquant (le nom de l\'extension, en français)';
    }

    $description = $manifest['description'] ?? null;
    if (!is_string($description) || mb_strlen(trim($description)) < 20) {
        $errors[] = 'extension.json : description manquante ou trop courte (ce que fait l\'extension, en mots métier, 20 caractères au moins)';
    }

    $types = $manifest['types'] ?? null;
    if (!is_array($types) || $types === [] || !array_is_list($types)) {
        $errors[] = 'extension.json : types manquant (liste parmi ' . implode(', ', TYPES) . ')';
    } else {
        foreach ($types as $type) {
            if (!is_string($type) || !in_array($type, TYPES, true)) {
                $errors[] = 'extension.json : type inconnu « ' . (is_scalar($type) ? (string) $type : gettype($type))
                    . ' » (types possibles : ' . implode(', ', TYPES) . ')';
            }
        }
        if (count($types) !== count(array_unique($types, SORT_REGULAR))) {
            $errors[] = 'extension.json : un type est listé deux fois';
        }
    }

    $suitecrm = $manifest['suitecrm'] ?? null;
    if (!is_string($suitecrm) || trim($suitecrm) === '') {
        $errors[] = 'extension.json : suitecrm manquant (versions compatibles, ex. ">=8.10 <9")';
    } elseif (class_exists(Composer\Semver\VersionParser::class)) {
        try {
            (new Composer\Semver\VersionParser())->parseConstraints($suitecrm);
        } catch (UnexpectedValueException $e) {
            $errors[] = "extension.json : suitecrm « $suitecrm » n'est pas une contrainte de version valide (ex. \">=8.10 <9\")";
        }
    }
}

// 2. composer.json: the package name follows the slug.
$composer = readJson('composer.json', $errors);
if ($composer !== null) {
    if (($composer['type'] ?? null) !== 'suitecrm-extension') {
        $errors[] = 'composer.json : type doit valoir "suitecrm-extension"';
    }
    $package = is_string($composer['name'] ?? null) ? $composer['name'] : '';
    if ($slug !== '' && !str_ends_with($package, "/suitecrm-ext-$slug")) {
        $errors[] = "composer.json : name « $package » doit se terminer par /suitecrm-ext-$slug (le slug de extension.json)";
    }
}

// 3. Where the files are.
foreach (glob('*', GLOB_ONLYDIR) ?: [] as $dir) {
    if (!in_array($dir, [...DIRS, 'vendor'], true)) {
        $errors[] = "dossier « $dir » non prévu (dossiers possibles : " . implode(', ', DIRS) . ')';
    }
}

if ($slug !== '') {
    // Legacy layer: registrations in Extension/ (Quick Repair merges them),
    // named after the slug so that no two extensions write the same file;
    // their PHP classes in include/<slug>/.
    foreach (filesUnder('legacy') as $file) {
        $inExtension = str_starts_with($file, 'Extension/') && str_contains(basename($file), $slug);
        $inInclude = str_starts_with($file, "include/$slug/");
        if (!$inExtension && !$inInclude) {
            $errors[] = "legacy/$file : à ranger dans legacy/Extension/… avec le slug dans le nom du fichier "
                . "(ex. legacy/Extension/application/Ext/LogicHooks/$slug.php), ou dans legacy/include/$slug/";
        }
    }
}

if ($errors !== []) {
    fwrite(STDERR, "\n  Extension : problèmes à corriger\n\n");
    foreach ($errors as $error) {
        fwrite(STDERR, "    ✘ $error\n");
    }
    fwrite(STDERR, "\n");
    exit(1);
}

echo "  Extension « $slug » : format conforme.\n";
