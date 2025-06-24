@{
    RootModule = 'ModuleOld.psm1'
    ModuleVersion = '1.0.0'
    GUID = '1d788809-0f78-4232-a5e3-1d5e728cb1c8'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2025 Jordan Borean. All rights reserved.'
    Description = 'Example module that loads the Tomlyn 0.18.0 .NET assembly directly'
    PowerShellVersion = '5.1'
    DotNetFrameworkVersion = '4.7.2'
    FunctionsToExport = @('Get-TomlPropertyDisplayKind')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{}
    }
}
