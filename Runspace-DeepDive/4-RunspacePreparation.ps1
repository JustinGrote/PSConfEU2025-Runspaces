# Preparation is done using the InitialSessionState class. We build the
# InitialSessionState object and then pass it to the RunspaceFactory
$iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()

# Adding a function is through the SessionStateFunctionEntry class
$iss.Commands.Add(
    [System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new(
        "Test-Function",
        {
            param ($Foo)

            "Type of Foo '$Foo' is '$($Foo.GetType().Name)'"
        }
    ))
# $iss.Commands | ? Name -eq 'Test-Function'

$rs = [RunspaceFactory]::CreateRunspace($iss)
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript('Test-Function 123').Invoke()  # Type of Foo '123' is 'Int32'
$rs.Dispose()

# We can add a simple variable with the string value '123'
$iss.Variables.Add(
    [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
        "MyVar",
        "123",
        $null))
$rs = [RunspaceFactory]::CreateRunspace($iss)
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript('Test-Function $MyVar').Invoke()  # Type of Foo '123' is 'String'
$rs.Dispose()

# We can add more complex variables, like one with a type converter
# Other attributes like ValidateSet, ValidateRange, etc. can be used as well.
# This example replicated '[int]$MyVarWithAttribute = "456"'
class IntTypeConverterAttribute : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics] $engineIntrinsics, [object] $inputData) {
        return [int]$inputData
    }
}

$iss.Variables.Add(
    [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
        "MyVarWithAttribute",
        "456",
        $null,
        [System.Management.Automation.ScopedItemOptions]::None,
        @(
            [IntTypeConverterAttribute]::new()
        )))
$rs = [RunspaceFactory]::CreateRunspace($iss)
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Test-Function $MyVarWithAttribute
$MyVarWithAttribute = "789"
Test-Function $MyVarWithAttribute
'@).Invoke()
# Type of Foo '456' is 'Int32'
# Type of Foo '789' is 'Int32'
$rs.Dispose()

# Pre-importing a module in a runspace
$iss.ImportPSModule('Pester')
$rs = [RunspaceFactory]::CreateRunspace($iss)
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript('Get-Module -Name Pester').Invoke()
$rs.Dispose()

# You can also just pre-load the variables and functions as a PowerShell command
# The difference here is that it needs to be done on every runspace whereas
# the InitialSessionState is done as part of the runspace creation.
$rs = [RunspaceFactory]::CreateRunspace()
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Import-Module Pester

Function Test-Function {
    param ($Foo)

    "Type of Foo '$Foo' is '$($Foo.GetType().Name)'"
}

$MyVar = '123'
'@).Invoke()

$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Get-Module -Name Pester

Test-Function $MyVar
'@).Invoke()
$rs.Dispose()

# Resetting a runspace/sessionstate only affects the variables in the runspace
$rs = [RunspaceFactory]::CreateRunspace()
$rs.Open()
$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Function Test-RunspaceFunction { $args[0] }
$Global:GlobalVar = 'GlobalVar'
$script:ScriptVar = 'ScriptVar'
$LocalVar = 'LocalVar'
'@).Invoke()

# Test that the function and variables are present in the runspace
$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Test-RunspaceFunction foo

"Global '$Global:GlobalVar'"
"Script '$script:ScriptVar'"
"Local '$LocalVar'"
'@).Invoke()
# foo
# Global 'GlobalVar'
# Script 'ScriptVar'
# Local 'LocalVar'

# We can also retrieve it through the SessionStateProxy
$rs.SessionStateProxy.InvokeProvider.Item.Get('function:Test-RunspaceFunction')
$rs.SessionStateProxy.PSVariable.Get('GlobalVar')
$rs.SessionStateProxy.PSVariable.Get('ScriptVar')
$rs.SessionStateProxy.PSVariable.Get('LocalVar')

# Calling ResetRunspaceState() will remove all variables but keep the functions
$rs.ResetRunspaceState()
$ps = [PowerShell]::Create($rs)
$ps.AddScript(@'
Test-RunspaceFunction foo

"Global '$Global:GlobalVar'"
"Script '$script:ScriptVar'"
"Local '$LocalVar'"
'@).Invoke()
# foo
# Global ''
# Script ''
# Local ''
$rs.Dispose()

# CreateDefault2() only loads Microsoft.PowerShell.Core by default,
# whereas CreateDefault() loads all the modules shipped by PowerShell.
# Ultimately not too much of a different but worth noting.
$iisDefault = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspace = [RunspaceFactory]::CreateRunspace($iisDefault)
$runspace.Open()
$ps = [PowerShell]::Create($runspace)
$ps.AddScript('Get-Command -ListImported').Invoke() |
    Select-Object Name, Source |
    Sort-Object Source, Name |
    Format-Table
$ps.Dispose()
$runspace.Dispose()

$iisDefault2 = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
$runspace = [RunspaceFactory]::CreateRunspace($iisDefault2)
$runspace.Open()
$ps = [PowerShell]::Create($runspace)
$ps.AddScript('Get-Command -ListImported').Invoke() |
    Select-Object Name, Source |
    Sort-Object Source, Name |
    Format-Table
$ps.Dispose()
$runspace.Dispose()
