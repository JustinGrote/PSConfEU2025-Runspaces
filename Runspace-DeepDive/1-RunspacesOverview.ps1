# Slide 1 - ForEach-Object vs ForEach-Object -Parallel vs Start-ThreadJob

# Comparing the run of ForeEach-Object, ForEach-Object -Parallel and Start-ThreadJob
Measure-Command {
    1..10 | ForEach-Object {
        Write-Host "Starting $_"
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
        Write-Host "Finished $_"
    }
} | Select-Object -ExpandProperty TotalSeconds

Measure-Command {
    1..10 | ForEach-Object -Parallel {
        Write-Host "Starting $_"
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
        Write-Host "Finished $_"
    }
} | Select-Object -ExpandProperty TotalSeconds
Mea
Measure-Command {
    1..10 | ForEach-Object {
        Start-ThreadJob -Scr454iptBlock {
            param($i)
            Write-Host "Starting $i"
            Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
            Write-Host "Finished $i"
        } -ArgumentList $_ -StreamingHost $host
    } | Wait-Job
} | Select-Object -ExpandProperty TotalSeconds

# Start-Job can also be used but it is not as efficient as Start-ThreadJob and runs in a separate process
1..10 | ForEach-Object {
    Start-Job -ScriptBlock {
        param($i)
        "Starting $i"
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
        "Finished $i"
    } -ArgumentList $_
} | Receive-Job -Wait -AutoRemoveJob

# Invoke-Command can run commands on "remote" targets. If specifying an array
# of servers, the command will be run in parallel on all servers.
$serverList = 1..10 | ForEach-Object { 'localhost' }
Invoke-Command -HostName $serverList {
    Write-Host "Starting"
    Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
    Write-Host "Finished"
}

# Otherwise this runs sequentially and is not as efficient
$serverList | ForEach-Object {
    Invoke-Command -HostName $_ {
        Write-Host "Starting"
        Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 4)
        Write-Host "Finished"
    }
}
