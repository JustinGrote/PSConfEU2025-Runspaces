Describe "Runspace do's and dont's" {

    It "ForEach-Object -Parallel has overhead, don't use for simple loops" {
        1..50 | ForEach-Object -Parallel { $_ }
    }

    It "Is faster to just use ForEach-Object for simple loops" {
        1..50 | ForEach-Object { $_ }
    }

    It "The output ordering is not deterministic with ForEach-Object -Parallel" {
        $res1 = 1..5 | ForEach-Object -Parallel {
            Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
            $_
        }

        $res2 = 1..5 | ForEach-Object -Parallel {
            Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
            $_
        }

        $res1 -join ' ' | Should -Not -Be ($res2 -join ' ')
    }

    It "Does not share internal module state - modules won't be imported" {
        $modulePath = Join-Path $PSScriptRoot 'ScriptModule'

        Import-Module -Name $modulePath -Force
        Get-ModuleValue | Should -Be 'default'

        {
            $ErrorActionPreference = 'Stop'

            1 | ForEach-Object -Parallel {
                Get-ModuleValue
            }
        } | Should -Throw -ExpectedMessage "The term 'Get-ModuleValue' is not recognized as a name of a cmdlet, function, script file, or executable program.*"
    }

    It "Does not share the internal module state after importing" {
        $modulePath = Join-Path $PSScriptRoot 'ScriptModule'

        Import-Module -Name $modulePath -Force
        Get-ModuleValue | Should -Be default
        Set-ModuleValue -Value test
        Get-ModuleValue | Should -Be test

        1 | ForEach-Object -Parallel {
            Import-Module -Name $using:modulePath
            Get-ModuleValue
        } | Should -Be default
    }

    It "Is not easily debuggable" {
        1..5 | ForEach-Object {
            $res = '1' + $_

            $res
        }

        1..5 | ForEach-Object -Parallel {
            $res = '1' + $_

            $res
        }
    }

    It "Cannot easily revert to non-parallel if using `$using:" {
        $var = 'test'
        1 | ForEach-Object -Parallel {
            $a = $using:var

            "$a - $_"
        } | Should -Be "test - 1"

        # Fails as $using: is not valid in normal circumstances
        $var = 'test'
        {
            1 | ForEach-Object {
                $a = $using:var

                "$a - $_"
            }
        } | Should -Throw -ExpectedMessage "A Using variable cannot be retrieved.*"
    }

    It "Is subject to race conditions if editing the same resource" {
        $file = Join-Path temp: test.txt
        Set-Content -Path $file -Value ''

        1..1000 | ForEach-Object -Parallel {
            $file = $using:file

            @(
                Get-Content $file
                "Testing value $_"
            ) | Set-Content -Path $file
        }

        (Get-Content $file | Measure-Object -Line).Lines | Should -Not -Be 1000
    }

    Context ".NET Tasks are an alternative to runspaces" {
        BeforeAll {
            $http = [System.Net.Http.HttpClient]::new()
        }
        AfterAll {
            $http.Dispose()
        }

        It "Runs a single task synchronously" {
            $getTask = $http.GetStringAsync('https://httpbin.org/base64/dGVzdCByZXN1bHQ=')
            while (-not $getTask.AsyncWaitHandle.WaitOne(200)) {}
            $getTask.GetAwaiter().GetResult() | Should -Be 'test result'
        }

        It "Uses a 7.6 feature PipelineStopToken to make it easier" -Skip:($PSVersionTable.PSVersion -lt '7.6') {
            & {
                [CmdletBinding()]
                param ()

                $http.GetStringAsync(
                    'https://httpbin.org/delay/5',
                    $PSCmdlet.PipelineStopToken).GetAwaiter().GetResult()
            }
        }

        It "Runs multiple tasks in parallel and waits for them to complete" {
            $tasks = [System.Threading.Tasks.Task[]]@(
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDE=')
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDI=')
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDM=')
            )
            $waitTask = [System.Threading.Tasks.Task]::WhenAll($tasks)
            while (-not $waitTask.AsyncWaitHandle.WaitOne(200)) {}
            $null = $waitTask.GetAwaiter().GetResult()

            $tasks[0].GetAwaiter().GetResult() | Should -Be 'Result 1'
            $tasks[1].GetAwaiter().GetResult() | Should -Be 'Result 2'
            $tasks[2].GetAwaiter().GetResult() | Should -Be 'Result 3'
        }

        It "Can also job-ify the tasks using 3rd party module TaskJob" {
            Import-Module -Name TaskJob

            @(
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDE=')
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDI=')
                $http.GetStringAsync('https://httpbin.org/base64/UmVzdWx0IDM=')
            ) | ConvertTo-TaskJob | Receive-Job -Wait | Should -Be @(
                'Result 1'
                'Result 2'
                'Result 3'
            )
        }

        It ".NET Tasks fail if you try and run a ScriptBlock as a delegate" {
            $task = [System.Threading.Tasks.Task]::Run([Action]{'foo'})
            while (-not $task.AsyncWaitHandle.WaitOne(200)) {}

            {
                $task.GetAwaiter().GetResult()
            } | Should -Throw -ExpectedMessage "*There is no Runspace available to run scripts in this thread*"
        }
    }
}

