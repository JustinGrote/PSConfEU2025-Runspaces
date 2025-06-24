# Create a new PowerShell instance
$script = {
	"Runspace: $([runspace]::DefaultRunspace.Id) Thread: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)"
	Start-Sleep 0.5
}
$ps = [PowerShell]::Create().AddScript($script)

$psReuseThread = [PowerShell]::Create().AddScript($script)
#Note: Legacy Options
$psReuseThread.Runspace.ThreadOptions = 'ReuseThread'

$psUseDefault = [PowerShell]::Create([runspace]::DefaultRunspace).AddScript($script)

# Run using our default runspace (which powers our terminal)
& $script | Write-Host -Fore Cyan
& $script | Write-Host -Fore Cyan

# Run using a new runspace. Will get a thread from threadpool for each invocation
$ps.Invoke() | Write-Host -Fore Green
$ps.Invoke() | Write-Host -Fore Green

# Run using a new runspace with ReuseThread option. Will reuse the same thread for both invocations
$psReuseThread.Invoke() | Write-Host -Fore Yellow
$psReuseThread.Invoke() | Write-Host -Fore Yellow

# Demo of foreach-parallel, difference of UseNewRunspace
1..6 | ForEach-Object -ThrottleLimit 2 -Parallel $script | Write-Host -Fore Blue
1..6 | ForEach-Object -ThrottleLimit 2 -UseNewRunspace -Parallel $script | Write-Host -Fore DarkCyan

# This won't work because we are using our default runspace already to "run" this script calling it (whoah, dudde).
Write-Host -Fore DarkRed 'This error is expected:'
Write-Host -Fore DarkRed '=========================================================='
$psUseDefault.Invoke() | Write-Host -Fore Magenta
Write-Host -Fore DarkRed '=========================================================='