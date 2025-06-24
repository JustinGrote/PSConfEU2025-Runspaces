Describe "Session State - Bound and Unbound ScriptBlocks" {
    It "Bound ScriptBlocks run in the same session state they are created in" {
        $runspaceId = [Runspace]::DefaultRunspace.Id
        $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        $someVar = 'in main runspace'

        $boundSbk = {
            [PSCustomObject]@{
                RunspaceId = [Runspace]::DefaultRunspace.Id
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                Variable = $someVar
            }
        }

        $res = & $boundSbk
        $res.RunspaceId | Should -Be $runspaceId
        $res.ThreadId | Should -Be $threadId
        $res.Variable | Should -Be 'in main runspace'

        $res = [PSCustomObject]@{ScriptBlock = $boundSbk} | ForEach-Object -Parallel {
            $someVar = 'from parallel'

            [PSCustomObject]@{
                RunspaceId = [Runspace]::DefaultRunspace.Id
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                Result = & $_.ScriptBlock
            }
        }

        $res.RunspaceId | Should -Not -Be $runspaceId
        $res.ThreadId | Should -Not -Be $threadId
        $res.Result.RunspaceId | Should -Be $res.RunspaceId
        $res.Result.ThreadId | Should -Be $res.ThreadId

        # While the runspace and thread are different from main, the session state
        # is the same as where thes scriptblock was created.
        $res.Result.Variable | Should -Be 'in main runspace'
    }

    It "Unbound ScriptBlocks run in the session state they are run in" {
        $runspaceId = [Runspace]::DefaultRunspace.Id
        $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
        $someVar = 'in main runspace'

        $unboundSbk = {
            [PSCustomObject]@{
                RunspaceId = [Runspace]::DefaultRunspace.Id
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                Variable = $someVar
            }
        }.Ast.GetScriptBlock()
        # [ScriptBlock]::Create(...) is another way to create an unbound scriptblock

        $res = & $unboundSbk
        $res.RunspaceId | Should -Be $runspaceId
        $res.ThreadId | Should -Be $threadId
        $res.Variable | Should -Be 'in main runspace'

        $res = [PSCustomObject]@{ScriptBlock = $unboundSbk} | ForEach-Object -Parallel {
            $someVar = 'from parallel'

            [PSCustomObject]@{
                RunspaceId = [Runspace]::DefaultRunspace.Id
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                Result = & $_.ScriptBlock
            }
        }

        $res.RunspaceId | Should -Not -Be $runspaceId
        $res.ThreadId | Should -Not -Be $threadId
        $res.Result.RunspaceId | Should -Be $res.RunspaceId
        $res.Result.ThreadId | Should -Be $res.ThreadId
        $res.Result.Variable | Should -Be 'from parallel'
    }

    It "Converts bound ScriptBlock to unbound to safely run it" {
        $someVar = 'in main runspace'
        $sbk = { $someVar }

        [PSCustomObject]@{ScriptBlock = $sbk} | ForEach-Object -Parallel {
            $someVar = 'from parallel'

            & $_.ScriptBlock.Ast.GetScriptBlock()
        } | Should -Be 'from parallel'
    }
}
