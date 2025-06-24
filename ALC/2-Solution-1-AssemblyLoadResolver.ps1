$moduleRoot = if (-not $PSScriptRoot) {
    Join-Path $pwd "Modules"
}
else {
    Join-Path $PSSCriptRoot "Modules"
}

& "$moduleRoot/ModuleNew/build.ps1"
& "$moduleRoot/ModuleOld/build.ps1"

# Importing normally just works as expected
Start-Job -ScriptBlock {
    Import-Module "$using:moduleRoot/ModuleNew"

    @{
        NoInline = Get-TomlPropertyDisplayKind NoInline
        InlineTable = Get-TomlPropertyDisplayKind InlineTable
    }
} | Receive-Job -Wait -AutoRemoveJob

# Both of these fail to import the second module as expected due to the assembly conflict
Start-Job -ScriptBlock {
    Import-Module "$using:moduleRoot/ModuleOld"
    Import-Module "$using:moduleRoot/ModuleNew"
} | Receive-Job -Wait -AutoRemoveJob

Start-Job -ScriptBlock {
    Import-Module "$using:moduleRoot/ModuleNew"
    Import-Module "$using:moduleRoot/ModuleOld"
} | Receive-Job -Wait -AutoRemoveJob

# This works by loading the second module with a custom resolver.
# The NoInline property also works as expected as the newer assembly is loaded first.
Start-Job -ScriptBlock {
    Import-Module "$using:moduleRoot/ModuleNew" -ArgumentList @{
        AddAssemblyFallback = $true
    } -Prefix ModuleNew
    Import-Module "$using:moduleRoot/ModuleOld" -ArgumentList @{
        AddAssemblyFallback = $true
    } -Prefix ModuleOld

    $asm = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GetName().Name -eq 'Tomlyn' } |
        Select-Object -ExpandProperty Location

    @{
        TomlynLocation = $asm
        ModuleNew = Get-ModuleNewTomlPropertyDisplayKind NoInline
        ModuleOld = Get-ModuleOldTomlPropertyDisplayKind InlineTable
    }
} | Receive-Job -Wait -AutoRemoveJob

# The dangers of this approach is that we could rely on features not present in the older
# version. For example NoLine was added in Tomlyn 0.19.0 so this imports but will fail
# at runtime.
Start-Job -ScriptBlock {
    Import-Module "$using:moduleRoot/ModuleOld" -ArgumentList @{
        AddAssemblyFallback = $true
    } -Prefix ModuleOld
    Import-Module "$using:moduleRoot/ModuleNew" -ArgumentList @{
        AddAssemblyFallback = $true
    } -Prefix ModuleNew

    $asm = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GetName().Name -eq 'Tomlyn' } |
        Select-Object -ExpandProperty Location

    @{
        TomlynLocation = $asm
        ModuleNew = Get-ModuleNewTomlPropertyDisplayKind NoInline -ErrorAction Continue
        ModuleOld = Get-ModuleOldTomlPropertyDisplayKind InlineTable
    }
} | Receive-Job -Wait -AutoRemoveJob
