@{
    RootModule = 'ScriptModule.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a63ef727-dc93-44c9-9a4a-6319f99c60dd'
    Author = 'Jordan and Justin'
    CompanyName = 'Community'
    Copyright = 'Do whatever you want'
    Description = 'Example script module for showing runspace isolation'
    PowerShellVersion = '7.5'
    FunctionsToExport = @(
        'Get-ComplexObject'
        'Get-ModuleValue'
        'Set-ModuleValue'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{}
    }
}
