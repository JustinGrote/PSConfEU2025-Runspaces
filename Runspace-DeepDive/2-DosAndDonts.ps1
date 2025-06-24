# Slide 3* - Runspace Dos and Don'ts

# Using ForEach-Object -Parallel has some overhead, will be slower if doing
# simple operations compared to just ForEach-Object.
Measure-Command {
    1..50 | ForEach-Object { $_ }
} | Select-Object -ExpandProperty TotalSeconds

Measure-Command {
    1..50 | ForEach-Object -Parallel { $_ }
} | Select-Object -ExpandProperty TotalSeconds

# The ordering is not deterministic, it will output in the order it
# finishes.
1..5 | ForEach-Object -Parallel {
    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
    $_
}

# No shared module state - some modules won't work in parallel
# Is there something builtin to test this locally?

# It is harder to debug ForEach-Object -Parallel, you cannot use breakpoints
# in VSCod.
1..5 | ForEach-Object {
    $res = '1' + $_

    $res
}

1..5 | ForEach-Object -Parallel {
    $res = '1' + $_

    $res
}

# The difficulty of debugging is compounded by the fact that you cannot easily
# remove the -Parallel part if the scriptblock has a $using: variable in it.
$var = 'test'
1 | ForEach-Object -Parallel {
    $a = $using:var

    "$a - $_"
}

# Fails as $using: is not valid in normal circumstances
$var = 'test'
1 | ForEach-Object {
    $a = $using:var

    "$a - $_"
}

# Running code in parallel leads to race conditions, if interacting with a
# single resource, like a file, it can lead to data corruption. In this example
# not all 100 lines are writtent to the file.
Remove-Item test.txt -ErrorAction Ignore
1..100 | ForEach-Object -Parallel {
    @(
        if (Test-Path test.txt) { Get-Content test.txt }
        "Testing value $_"
    ) | Set-Content test.txt
    # Add-Content "Testing value $_" -Path test.txt
}
Get-Content test.txt | Measure-Object -Line

# .NET Tasks are an alternative, it has no runspace overhead but is more complex.
$http = [System.Net.Http.HttpClient]::new()

# Single task run synchronously
$getTask = $http.GetStringAsync('https://httpbin.org/base64/dGVzdCByZXN1bHQ=')
while (-not $getTask.AsyncWaitHandle.WaitOne(200)) {}
$getTask.GetAwaiter().GetResult()

# New feature in pwsh 7.6 makes this easier to use - $PSCmdlet.PipelineStopToken
# Removes the need for the AsyncWaitHandle.WaitOne loop
& {
    [CmdletBinding()]
    param ()

    $http = [System.Net.Http.HttpClient]::new()
    $http.GetStringAsync(
        'https://httpbin.org/delay/5',
        $PSCmdlet.PipelineStopToken).GetAwaiter().GetResult()
}

# Can run multiple tasks in parallel and wait for them to complete
$tasks = [System.Threading.Tasks.Task[]]@(
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDE=')
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDI=')
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDM=')
)
$waitTask = [System.Threading.Tasks.Task]::WhenAll($tasks)
while (-not $waitTask.AsyncWaitHandle.WaitOne(200)) {}
$null = $waitTask.GetAwaiter().GetResult()

$tasks[0].GetAwaiter().GetResult()
$tasks[1].GetAwaiter().GetResult()
$tasks[2].GetAwaiter().GetResult()

# Can also job-ify the tasks using 3rd party module TaskJob
Import-Module -Name TaskJob
@(
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDE=')
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDI=')
    $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDM=')
) | ConvertTo-TaskJob | Receive-Job -Wait

# ScriptBlocks add more complications, their behaviour is different
# depending on whether they are bound or unbound. Bound scriptblocks
# are run with the SessionState of the runspace they are created in,
# unbound scriptblocks are run in the session state of the runspace
# they are run in. Running a bound scriptblock in a different runspace
# can lead to unexpected results and failures.
$someVar = 'in main runspace'
$boundSbk = { "Bound ScriptBlock RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'" }
$unboundSbk = [ScriptBlock]::Create($boundSbk.ToString())

"Main RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'"
@(
    [PSCustomObject]@{
        Task = 'Bound ScriptBlock'
        ScriptBlock = $boundSbk
    }
    [PSCustomObject]@{
        Task = 'Unbound ScriptBlock'
        ScriptBlock = $unboundSbk
    }
) | ForEach-Object -Parallel {
    $someVar = 'from parallel'

    Write-Host "Starting $($_.Task) RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'"
    & $_.ScriptBlock
}

# Instead you are better off re-creating the ScriptBlock in the runspace you are running
# it in. This can be done with $sbk.Ast.GetScriptBlock() or by using [ScriptBlock]::Create($sbk)
$someVar = 'in main runspace'
$boundSbk = { "Bound ScriptBlock RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'" }

"Main RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'"
@(
    [PSCustomObject]@{
        Task = 'Bound ScriptBlock'
        ScriptBlock = $boundSbk
    }
) | ForEach-Object -Parallel {
    $someVar = 'from parallel'

    Write-Host "Starting $($_.Task) RunspaceId $([Runspace]::DefaultRunspace.Id) - Variable '$someVar'"
    & $_.ScriptBlock.Ast.GetScriptBlock()
}
