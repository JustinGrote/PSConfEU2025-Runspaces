# Install-PSResource -Name dbatools, MSAL.PS -TrustRepository -Scope CurrentUser

# Works
Start-Job -ScriptBlock {
    Import-Module MSAL.PS -PassThru
} | Receive-Job -Wait -AutoRemoveJob

# Works
Start-Job -ScriptBlock {
    Import-Module dbatools -PassThru
} | Receive-Job -Wait -AutoRemoveJob

# Fails
Start-Job -ScriptBlock {
    Import-Module MSAL.PS
    Import-Module dbatools
} | Receive-Job -Wait -AutoRemoveJob

<#
Import-Module: Couldn't import .../Modules/dbatools.library/2024.4.12/core/lib/Microsoft.Data.SqlClient.dll |
Could not load file or assembly 'Microsoft.Identity.Client, Version=4.56.0.0, Culture=neutral, PublicKeyToken=0a613f4dd989e8ae'.
The located assembly's manifest definition does not match the assembly reference. (0x80131040)
#>

# What is happening here?
# 1. Importing MSAL.PS loads Microsoft.Identity.Client.dll 4.37.0.0 into the "Default" LoadContext
Start-Job -ScriptBlock {
    Import-Module MSAL.PS
    [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.Location -like '*Microsoft.Identity.Client.dll' } |
        ForEach-Object {
            $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_)
            [PSCustomObject]@{
                Name = $_.FullName
                Location = $_.Location
                ALC = $alc
            }
        }
} | Receive-Job -Wait -AutoRemoveJob

# 2. Importing dbatools also loads a copy of Microsoft.Data.SqlClient.dll 4.56.0.0 into the "Default" LoadContext
Start-Job -ScriptBlock {
    Import-Module dbatools
    [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.Location -like '*Microsoft.Identity.Client.dll' } |
        ForEach-Object {
            $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_)
            [PSCustomObject]@{
                Name = $_.FullName
                Location = $_.Location
                ALC = $alc
            }
        }
} | Receive-Job -Wait -AutoRemoveJob

# 3. Since .NET Core/5+ (pwsh), trying to import two copies of the same assembly into the same LoadContext fails
# and since dbatools relies on a newer version which cannot be satisfied by the older version it fails to load.

# A simple workaround is to change the assembly load order with dbatools going first
Start-Job -ScriptBlock {
    Import-Module dbatools

    # Ignores an interactive prompt to just load the assembly, not all modules have this
    Import-Module MSAL.PS -ArgumentList @{ 'dll.lenientLoading' = $true; 'dll.lenientLoadingPrompt' = $false }
    [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.Location -like '*Microsoft.Identity.Client.dll' } |
        ForEach-Object {
            $alc = [Runtime.Loader.AssemblyLoadContext]::GetLoadContext($_)
            [PSCustomObject]@{
                Name = $_.FullName
                Location = $_.Location
                ALC = $alc
            }
        }
} | Receive-Job -Wait -AutoRemoveJob

# WinPS (5.1) is not affected as .NET Framework can load multiple copies of the same assembly
# Note this example will only work if you are running on Windows.
Start-Job -ScriptBlock {
    Import-Module dbatools
    Import-Module MSAL.PS

    [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.Location -like '*Microsoft.Identity.Client.dll' } |
        ForEach-Object {
            [PSCustomObject]@{
                Name = $_.FullName
                Location = $_.Location
            }
        }
} -PSVersion 5.1 | Receive-Job -Wait -AutoRemoveJob
