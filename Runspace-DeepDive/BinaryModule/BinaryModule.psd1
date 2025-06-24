@{
    RootModule = 'src/bin/Release/net9.0/publish/BinaryModule.dll'
    ModuleVersion = '1.0.0'
    GUID = '0e568c83-d3df-4509-a680-917061661894'
    Author = 'Jordan and Justin'
    CompanyName = 'Community'
    Copyright = 'Do whatever you want'
    Description = 'Example binary module options for runspace scoped variables'
    PowerShellVersion = '7.5'
    FunctionsToExport = @()
    CmdletsToExport = @(
        'Get-RunspaceStore'
        'Get-StaticStore'
        'Get-ThreadLocalStore'
        'Reset-AllStores'
        'Set-RunspaceStore'
        'Set-StaticStore'
        'Set-ThreadLocalStore'
    )
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{}
    }
}
