@{
    RootModule = 'ModuleNew.psm1'
    ModuleVersion = '1.0.0'
    GUID = '9b069695-252f-4578-98f5-e339fcdb0e1e'
    Author = 'Jordan Borean'
    CompanyName = 'Community'
    Copyright = '(c) 2025 Jordan Borean. All rights reserved.'
    Description = 'Example module that loads the Tomlyn 0.19.0 .NET assembly directly'
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
