<?php

// Builds the Module Loader package of a SuiteCRM extension (see the
// architecture decisions, "Format des extensions"): the same files as the
// image of suitecrm-core installs (scripts/extensions.sh), for any SuiteCRM 8,
// Administration → Module Loader.
//
// - backend/, config/, public/ → extensions/<Name>/ (copy_core_extensions,
//   <Name>: the slug in PascalCase). The Module Loader then clears the cache
//   of SuiteCRM 8, which copies public/ to public/extensions/<Name>/ when it
//   rebuilds it;
// - legacy/… → custom/…, file by file (copy): uninstalled, each file is
//   taken out, or the one it replaced restored;
// - scripts/post_install.php (generated): Quick Repair, as Administration →
//   Repair does it (the Module Loader merges the extensions, but does not
//   create the columns of new fields), then database/install.php if any;
//   the message a script returns goes to the log of SuiteCRM;
// - scripts/pre_uninstall.php (generated), when there is a
//   database/uninstall.php: run before the files are taken out.
//
// Written to build/<slug>-<version>.zip, the version of
// .release-please-manifest.json. Run from the extension's root, by
// make package@build (in Docker).
//
// @usage php build.php <SuiteCRM version the Angular module is built against>

declare(strict_types=1);

const OUT = 'build';
// Directories of the SuiteCRM 8 layer, copied to extensions/<Name>/.
const CORE_DIRS = ['backend', 'config', 'public'];

/**
 * Stops with a message in French.
 */
function fail(string $message): never
{
    fwrite(STDERR, "package@build : $message\n");
    exit(1);
}

/**
 * Reads a JSON file as an object.
 *
 * @return array<mixed>
 */
function readJson(string $file): array
{
    $data = is_file($file) ? json_decode((string) file_get_contents($file), true) : null;
    if (!is_array($data)) {
        fail("$file absent ou invalide");
    }

    return $data;
}

/**
 * Lists the files under a directory, relative to it, sorted.
 *
 * @return list<string>
 */
function filesUnder(string $dir): array
{
    $files = [];
    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($iterator as $file) {
        if ($file instanceof SplFileInfo && $file->isFile() && $file->getFilename() !== '.gitkeep') {
            $files[] = str_replace('\\', '/', substr($file->getPathname(), strlen($dir) + 1));
        }
    }
    sort($files);

    return $files;
}

/**
 * PHP source of a value, as var_export writes it, indented by 4 spaces.
 */
function export(mixed $value): string
{
    return str_replace('  ', '    ', var_export($value, true));
}

$suitecrm = $argv[1] ?? '';
if (preg_match('/^(\d+)\.(\d+)\./', $suitecrm, $version) !== 1) {
    fail('version de SuiteCRM attendue en argument, par exemple 8.10.2');
}

$extension = readJson('extension.json');
$slug = is_string($extension['slug'] ?? null) ? $extension['slug'] : fail('extension.json : slug absent');
$name = is_string($extension['name'] ?? null) ? $extension['name'] : $slug;
$description = is_string($extension['description'] ?? null) ? $extension['description'] : '';
$release = is_file('.release-please-manifest.json') ? readJson('.release-please-manifest.json') : [];
$packageVersion = is_string($release['.'] ?? null) ? $release['.'] : '0.0.0';
$composer = readJson('composer.json');
$authors = is_array($composer['authors'] ?? null) ? $composer['authors'] : [];
$firstAuthor = is_array($authors[0] ?? null) ? $authors[0] : [];
$vendor = is_string($composer['name'] ?? null) ? explode('/', $composer['name'])[0] : '';
$author = is_string($firstAuthor['name'] ?? null) ? $firstAuthor['name'] : $vendor;
// Directory in extensions/: a PHP namespace segment (no hyphen), as
// suitecrm-core names it.
$namespace = str_replace(' ', '', ucwords(str_replace('-', ' ', $slug)));

// Files of the package: path in the zip → path in the extension.
$files = [];
$installdefs = ['id' => $slug];

foreach (CORE_DIRS as $dir) {
    if (is_dir($dir)) {
        foreach (filesUnder($dir) as $file) {
            $files["extension/$namespace/$dir/$file"] = "$dir/$file";
        }
    }
}
if (array_keys($files) !== []) {
    $installdefs['copy_core_extensions'] = [['from' => "<basepath>/extension/$namespace", 'to' => $namespace]];
}

// Modules whose definitions the extension changes (legacy/Extension/modules/<Module>/).
$modules = [];
if (is_dir('legacy')) {
    $installdefs['copy'] = [];
    foreach (filesUnder('legacy') as $file) {
        $files["legacy/$file"] = "legacy/$file";
        $installdefs['copy'][] = ['from' => "<basepath>/legacy/$file", 'to' => "custom/$file"];
        if (preg_match('#^Extension/modules/([^/]+)/#', $file, $module) === 1) {
            $modules[$module[1]] = true;
        }
    }
}
$modules = array_keys($modules);

// The install scripts: their own files only, the seeders are for the demos.
$scripts = [];
foreach (['install', 'uninstall'] as $script) {
    if (is_file("database/$script.php")) {
        $files["database/$script.php"] = "database/$script.php";
        $scripts[$script] = true;
    }
}

$generated = [];
$header = "<?php\n\n// Generated by make package@build (suitecrm-devkit), run by the Module Loader\n// in public/legacy, as the administrator who installs the package.\n\n";
$generated['scripts/post_install.php'] = $header
    . "function post_install(): void\n{\n"
    . "    // Quick Repair, as Administration → Repair does it: the Module Loader\n"
    . "    // merges the extensions, but does not create the columns of new fields.\n"
    . "    // \"All modules\" is recognised by its label, in the current language.\n"
    . "    global \$mod_strings;\n"
    . "    require_once 'modules/Administration/QuickRepairAndRebuild.php';\n"
    . "    \$all = is_array(\$mod_strings) && is_string(\$mod_strings['LBL_ALL_MODULES'] ?? null) ? \$mod_strings['LBL_ALL_MODULES'] : 'All Modules';\n"
    . "    (new RepairAndClear())->repairAndClearAll(['clearAll'], [\$all], true, false);\n"
    . (isset($scripts['install']) ? ($modules === [] ? '' : "\n"
        . "    // Studio (database/install.php may change a layout) keeps the modules it\n"
        . "    // read earlier in this request, with their fields from before the\n"
        . "    // install: it would drop the new ones. Forgotten here, read again. The\n"
        . "    // core runs the script in its own process.\n"
        . "    require_once 'modules/ModuleBuilder/Module/StudioModuleFactory.php';\n"
        . "    \$studio = new class () extends StudioModuleFactory {\n"
        . "        public function forget(string \$module): void\n"
        . "        {\n"
        . "            unset(self::\$loadedMods[\$module]);\n"
        . "        }\n"
        . "    };\n"
        . "    foreach (['" . implode("', '", $modules) . "'] as \$module) {\n"
        . "        \$studio->forget(\$module);\n"
        . "    }\n")
        . "\n    // The script returns its message (echo is refused by the scanner):\n"
        . "    // kept in the log of SuiteCRM.\n"
        . "    \$message = require __DIR__ . '/../database/install.php';\n"
        . "    if (is_string(\$message)) {\n"
        . "        \$GLOBALS['log']->info(\$message);\n"
        . "    }\n" : '')
    . "}\n";
if (isset($scripts['uninstall'])) {
    $generated['scripts/pre_uninstall.php'] = $header
        . "function pre_uninstall(): void\n{\n"
        . "    \$message = require __DIR__ . '/../database/uninstall.php';\n"
        . "    if (is_string(\$message)) {\n"
        . "        \$GLOBALS['log']->info(\$message);\n"
        . "    }\n"
        . "}\n";
}

$manifest = [
    'name' => $name,
    'description' => $description,
    'author' => $author,
    'version' => $packageVersion,
    'published_date' => gmdate('Y-m-d'),
    'type' => 'module',
    'is_uninstallable' => true,
    // The minor version the Angular module is built against: another one
    // may not load it (shared Angular libraries).
    'acceptable_suitecrm_versions' => ['regex_matches' => ['^' . $version[1] . '\.' . $version[2] . '\.']],
];
$generated['manifest.php'] = "<?php\n\n// Generated by make package@build (suitecrm-devkit).\n\n"
    . '$manifest = ' . export($manifest) . ";\n\n"
    . '$installdefs = ' . export($installdefs) . ";\n";

// The zip, rebuilt from scratch. build/ ignores itself: nothing to add to the
// .gitignore of each extension.
if (!is_dir(OUT) && !mkdir(OUT, 0775, true)) {
    fail(OUT . '/ impossible à créer');
}
file_put_contents(OUT . '/.gitignore', "*\n");
$zip = OUT . "/$slug-$packageVersion.zip";
if (is_file($zip)) {
    unlink($zip);
}
$archive = new PharData($zip, 0, null, Phar::ZIP);
foreach ($generated as $path => $content) {
    $archive->addFromString($path, $content);
}
foreach ($files as $path => $source) {
    $archive->addFile($source, $path);
}

printf("  %s : %d fichiers (%s)\n", $zip, count($files) + count($generated), implode(', ', array_keys($generated)));
