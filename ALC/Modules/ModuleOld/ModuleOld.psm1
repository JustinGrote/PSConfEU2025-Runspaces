using namespace System.Collections
using namespace System.IO
using namespace System.Reflection

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [IDictionary]
    $Settings = @{}
)

$ModuleName = [Path]::GetFileNameWithoutExtension($PSCommandPath)

. {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $AddAssemblyFallback
    )
} @Settings

$dotnetVersion = if ($IsCoreCLR) {
    'net8.0'
}
else {
    'net472'
}
$assemblyPath = [Path]::Combine($PSScriptRoot, 'bin', $dotnetVersion, "Tomlyn.dll")

if ($AddAssemblyFallback) {
    $existingTomlynAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GetName().Name -eq 'Tomlyn' } |
        Select-Object -First 1

    $resolveDelegate = [ResolveEventHandler]{
        param (
            [Object]$s,
            [ResolveEventArgs]$e
        )

        if ($e.Name -like '*Tomlyn.dll,*') {
            if ($existingTomlynAssembly) {
                Write-Host "$ModuleName - Using existing assembly: '$($existingTomlynAssembly.Location)'"
                $existingTomlynAssembly
            }
            else {
                Write-Host "$ModuleName - Loading assembly: '$($e.Name)'"
                [Assembly]::LoadFrom($assemblyPath)
            }
        }
    }
    [AppDomain]::CurrentDomain.add_AssemblyResolve($resolveDelegate)
}

Add-Type -Path $assemblyPath

if ($resolveDelegate) {
    [AppDomain]::CurrentDomain.remove_AssemblyResolve($resolveDelegate)
}

Function Get-TomlPropertyDisplayKind {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [string]
        $Value
    )

    [Tomlyn.Model.TomlPropertyDisplayKind]$Value
}

Export-ModuleMember -Function Get-TomlPropertyDisplayKind
