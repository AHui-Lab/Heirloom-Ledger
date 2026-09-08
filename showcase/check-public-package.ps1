$ErrorActionPreference = 'Stop'

$publicRoot = (Resolve-Path (Join-Path $PSScriptRoot '.')).Path
$requiredFiles = @(
    'index.html',
    'README.md',
    'PORTFOLIO_CASE_STUDY.md',
    'VIDEO_DEMO_SCRIPT.md',
    'assets/01-dialogue.png',
    'assets/02-market.png',
    'assets/03-appraisal.png',
    'assets/04-night.png',
    'assets/05-notebook.png'
)

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($relativePath in $requiredFiles) {
    $candidate = Join-Path $publicRoot $relativePath
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $failures.Add("missing: $relativePath")
    }
}

$textExtensions = @('.html', '.md', '.ps1')
$textFiles = Get-ChildItem -LiteralPath $publicRoot -Recurse -File |
    Where-Object {
        ($textExtensions -contains $_.Extension.ToLowerInvariant()) -and
        $_.Name -notin @('README.md', 'check-public-package.ps1')
    }
$forbiddenPatterns = @(
    'api[_-]?key',
    'authorization',
    'bearer\s+[A-Za-z0-9._-]+',
    'password',
    'secret',
    'C:\\Users\\',
    'user://',
    'deepseek',
    'openai\.com',
    'api\.kimi',
    'llm_diagnostics',
    'chapter_save\.json'
)

foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($pattern in $forbiddenPatterns) {
        if ($content -match $pattern) {
            $failures.Add("forbidden pattern '$pattern' in $($file.FullName.Substring($publicRoot.Length + 1))")
        }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "PASS: public showcase package contains required files and no forbidden secret/config markers."
