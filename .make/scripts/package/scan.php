<?php

// The package scanner of SuiteCRM's Module Loader (ModuleScanner, the one an
// instance runs when moduleInstaller.packageScan is on), on the content of a
// Module Loader package: every file it refuses, and why. SuiteCRM's own
// translate() and logger are replaced by stand-ins that print the label keys
// (ML_INVALID_FUNCTION…), and its default settings are kept (no exemption).
// Run by scan.sh, from the extension's root (in Docker).
//
// @usage php scan.php <directory of ModuleScanner.php> <package zip>

declare(strict_types=1);

[, $scanner, $package] = $argv + [null, '', ''];
if (!is_file("$scanner/ModuleScanner.php") || !is_file($package)) {
    fwrite(STDERR, "package@scan : scanner ou paquet introuvable\n");
    exit(1);
}

require 'vendor/autoload.php';

// What ModuleScanner expects from SuiteCRM.
define('sugarEntry', true);
/** @return string The label key, as SuiteCRM shows it when it has no text. */
function translate(string $key, string $module = ''): string
{
    return $key;
}
$GLOBALS['sugar_config'] = [];
$GLOBALS['log'] = new class () {
    /** @param array<mixed> $arguments */
    public function __call(string $name, array $arguments): void {}
};
require "$scanner/ModuleScanner.php";

// The package as the Module Loader unpacks it.
$unpacked = sys_get_temp_dir() . '/package-scan-' . bin2hex(random_bytes(4));
(new PharData($package))->extractTo($unpacked);

$moduleScanner = new ModuleScanner();
$moduleScanner->scanDir($unpacked);
$issues = $moduleScanner->getIssues();
$files = is_array($issues['file'] ?? null) ? $issues['file'] : [];

$name = basename($package);
if ($files === []) {
    echo "  $name : le scanner du Chargeur de module n'a rien refusé.\n";
    exit(0);
}

fwrite(STDERR, "  $name : le scanner du Chargeur de module refuse " . count($files) . " fichier(s) :\n");
foreach ($files as $file => $reasons) {
    fwrite(STDERR, '    ' . substr((string) $file, strlen($unpacked) + 1) . "\n");
    foreach (array_unique(is_array($reasons) ? $reasons : [$reasons]) as $reason) {
        fwrite(STDERR, '      - ' . (is_string($reason) ? $reason : '?') . "\n");
    }
}
fwrite(STDERR, "  Règles et remplacements : skill nouvelle-extension, section 7 bis.\n");
exit(1);
