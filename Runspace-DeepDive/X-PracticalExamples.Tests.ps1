using namespace System.Management.Automation

Describe "Practical parallel examples" {
    Context "CPU Bound Operations" {
        BeforeAll {
            $ProgressPreference = 'Ignore'
        }

        BeforeEach {
            $buffer = [byte[]]::new(1MB)
            $rng = [Random]::new()

            $testFiles = for ($i = 0; $i -lt 10; $i++) {
                $psPath = Join-Path -Path TestDrive: -ChildPath "test-$i.bin"
                $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($psPath)
                $file = [IO.File]::Create($path)

                for ($j = 0; $j -lt 50; $j++) {
                    $rng.NextBytes($buffer)
                    $file.Write($buffer)
                }

                $file.Dispose()
                $path
            }
        }

        It "Compresses sequentially" {
            $testFiles | ForEach-Object {
                $destPath = "$_-sequential.zip"
                Compress-Archive -LiteralPath $_ -DestinationPath $destPath
            }
        }

        It "Compresses in parallel" {
            $testFiles | ForEach-Object -Parallel {
                $destPath = "$_-parallel.zip"
                Compress-Archive -LiteralPath $_ -DestinationPath $destPath
            }
        }
    }

    Context "IO Bound Operations" {
        BeforeAll {
            $noInput = [PSDataCollection[object]]::new()
            $noInput.Complete()
            $settings = [PSInvocationSettings]@{
                Host = $Host
            }

            $ps = [PowerShell]::Create()
            $ps.AddCommand("$PSScriptRoot/TestWebServer.ps1").AddParameter('Port', 8080)
            $webTask = $ps.BeginInvoke($noInput, $settings, $null, $null)

            $url = "http://localhost:8080"
            while ($true) {
                try {
                    Invoke-WebRequest -Uri "$url/" | Out-Null
                    break
                }
                catch {
                    if ($webTask.IsCompleted) {
                        $null = $ps.EndInvoke($webTask)
                        foreach ($err in $ps.Streams.Error) {
                            throw $err
                        }

                        throw  # In case there wasn't an error throw the connection failure.
                    }

                    Start-Sleep -Milliseconds 300
                }
            }
        }

        AfterAll {
            Invoke-WebRequest -Uri "$url/shutdown" | Out-Null
            $null = $ps.EndInvoke($webTask)
            $ps.Dispose()
        }

        It "Sends requests sequentially" {
            1..10 | ForEach-Object {
                $sleep = Get-Random -Minimum 1 -Maximum 4
                Invoke-WebRequest -Uri "$url/id=$_&delay=$sleep" | Out-Null
            }
        }

        It "Sends requests in parallel" {
            1..10 | ForEach-Object -Parallel {
                $sleep = Get-Random -Minimum 1 -Maximum 4
                Invoke-WebRequest -Uri "$using:url/id=$_&delay=$sleep" | Out-Null
            }
        }
    }
}
