Describe "Ways of persisting data and how it affects runspaces" {
    BeforeAll {
        $ModulePath = "$PSScriptRoot/BinaryModule"
        Import-Module -Name $ModulePath -Force
        Reset-AllStores
    }

    It "Static field persists across all runspaces" {
        Get-StaticStore | Should -Be StaticStoreDefault
        Set-StaticStore NewStaticStore

        Get-StaticStore | Should -Be NewStaticStore

        # Notice that another runspace has the new value and not the default
        1 | ForEach-Object -Parallel {
            Import-Module -Name $using:ModulePath

            Get-StaticStore
        } | Should -Be NewStaticStore
    }

    It "Thread local storage is not safe for scoping to a runspace" {
        Get-ThreadLocalStore | Should -Be ThreadLocalStoreDefault
        Set-ThreadLocalStore NewThreadLocalStore

        Get-ThreadLocalStore | Should -Be NewThreadLocalStore

        Write-Host "Default Runspace ID $([Runspace]::DefaultRunspace.Id) - Thread ID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Blue

        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        $iss.ImportPSModulesFromPath($ModulePath)
        $runspace = [RunspaceFactory]::CreateRunspace($Host, $iss)
        $runspace.Open()
        try {

            # We check that the TLS value has the default and set a new one for
            # the thread the runspace is using.
            $ps = [PowerShell]::Create($runspace)
            $ps.AddScript({
                Write-Host "Parallel Runspace ID $([Runspace]::DefaultRunspace.Id) - Thread ID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)" -ForegroundColor Yellow
                Get-ThreadLocalStore
                Set-ThreadLocalStore NewParallelThreadLocalStore
            }).Invoke()[0] | Should -Be ThreadLocalStoreDefault
            $ps.Streams.Error | Out-Host

            $ps.Commands.Clear()

            # This demonstrates that even though we are using the same runspace
            # it could run on another thread so the TLS value is not what we
            # would expect.
            while ($true) {
                $res = $ps.AddScript({
                    $res = Get-ThreadLocalStore

                    Write-Host "Parallel Runspace ID $([Runspace]::DefaultRunspace.Id) - Thread ID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId) - Result: $res"  -ForegroundColor Green
                    $res
                }).Invoke()
                if ($res -eq 'NewParallelThreadLocalStore') {
                    continue
                }

                $res | Should -Be ThreadLocalStoreDefault
                break
            }
        }
        finally {
            $runspace.Dispose()
        }
    }

    It "Runspace storage is not shared across runspaces" {
        Get-RunspaceStore | Should -Be RunspaceStoreDefault
        Set-RunspaceStore NewRunspaceStore

        Get-RunspaceStore | Should -Be NewRunspaceStore

        Write-Host "Default Runspace ID: $([Runspace]::DefaultRunspace.Id)" -ForegroundColor Blue
        1 | ForEach-Object -Parallel {
            Import-Module -Name $using:ModulePath

            Write-Host "Parallel Runspace ID: $([Runspace]::DefaultRunspace.Id)" -ForegroundColor Yellow
            Get-RunspaceStore

            Set-RunspaceStore OtherRunspaceStore
        } | Should -Be RunspaceStoreDefault

        # This is still not affected by the other parallel runspace
        Get-RunspaceStore | Should -Be NewRunspaceStore
    }
}
