# Secrets travel through anonymous stdio pipes, never command-line arguments.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Console]::InputEncoding = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
try {
    Add-Type -AssemblyName System.Security
    $requestData = [Console]::ReadLine() | ConvertFrom-Json
    $profileRoot = [IO.Path]::GetFullPath([string]$requestData.root)
    $profileName = [string]$requestData.name
    if ($profileName -notin @('api_profile.dpapi', 'test_api_profile.dpapi')) { throw 'invalid target' }
    $profilePath = [IO.Path]::GetFullPath([IO.Path]::Combine($profileRoot, $profileName))
    if ([IO.Path]::GetDirectoryName($profilePath) -ne $profileRoot.TrimEnd('\')) { throw 'invalid root' }
    $entropy = [Text.Encoding]::UTF8.GetBytes('HeirloomLedger/profile/v1')
    switch ([string]$requestData.op) {
        'save' {
            $plainBytes = [Text.Encoding]::UTF8.GetBytes(($requestData.profile | ConvertTo-Json -Compress -Depth 12))
            $protectedBytes = [Security.Cryptography.ProtectedData]::Protect($plainBytes, $entropy, [Security.Cryptography.DataProtectionScope]::CurrentUser)
            [IO.Directory]::CreateDirectory($profileRoot) | Out-Null
            [IO.File]::WriteAllBytes($profilePath + '.tmp', $protectedBytes)
            if ([IO.File]::Exists($profilePath)) { [IO.File]::Replace($profilePath + '.tmp', $profilePath, $null) }
            else { [IO.File]::Move($profilePath + '.tmp', $profilePath) }
            [Array]::Clear($plainBytes, 0, $plainBytes.Length)
            [Console]::WriteLine('{"ok":true}')
        }
        'load' {
            if (-not [IO.File]::Exists($profilePath)) { [Console]::WriteLine('{"ok":false,"error":"missing"}'); exit 0 }
            $plainBytes = [Security.Cryptography.ProtectedData]::Unprotect([IO.File]::ReadAllBytes($profilePath), $entropy, [Security.Cryptography.DataProtectionScope]::CurrentUser)
            $profileData = [Text.Encoding]::UTF8.GetString($plainBytes) | ConvertFrom-Json
            [Console]::WriteLine((@{ok=$true; profile=$profileData} | ConvertTo-Json -Compress -Depth 12))
            [Array]::Clear($plainBytes, 0, $plainBytes.Length)
        }
        'forget' {
            if ([IO.File]::Exists($profilePath)) { [IO.File]::Delete($profilePath) }
            [Console]::WriteLine('{"ok":true}')
        }
        default { throw 'invalid operation' }
    }
} catch {
    # Exception objects can contain input data: return a fixed safe error only.
    [Console]::WriteLine('{"ok":false,"error":"protected_storage_failed"}')
    exit 1
}
