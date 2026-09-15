$ErrorActionPreference = 'Stop'
$godotRuntime = 'C:\Users\cyh\.cache\heirloom-ledger\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godotRuntime)) { throw 'Godot runtime not found. Update the runtime path in run_checks.ps1.' }
$chapterChecks = @('test_game_core', 'test_dialogue_regressions', 'test_chapter', 'test_llm_local', 'test_chapter_ui', 'test_immersive_core', 'test_immersive_ui', 'test_profile_store')
foreach ($checkName in $chapterChecks) {
    Write-Host "Running $checkName"
    $checkOutput = & $godotRuntime --headless --path $PSScriptRoot -s "res://tests/$checkName.gd" 2>&1
    $checkExit = $LASTEXITCODE
    $checkOutput | ForEach-Object { Write-Host $_ }
    if ($checkExit -ne 0 -or ($checkOutput -join "`n") -match '(?m)^(SCRIPT ERROR:|ERROR:)' -or ($checkOutput -join "`n") -notmatch 'PASS:') {
        throw "$checkName failed (exit $checkExit or runtime error/missing PASS)."
    }
}
Write-Host 'All local checks passed. No external model calls were made.'
