$script:InternalValue = 'default'

Function Get-ComplexObject {
    [OutputType([System.IO.DirectoryInfo])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Path
    )

    Get-Item -LiteralPath $Path
}

Function Get-ModuleValue {
    [OutputType([string])]
    [CmdletBinding()]
    param ()

    $script:InternalValue
}

Function Set-ModuleValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $script:InternalValue = $Value
}

Export-ModuleMember -Function Get-ComplexObject, Get-ModuleValue, Set-ModuleValue
