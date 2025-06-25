sudo chmod 775 "$PSHome/pwsh"
Set-PSResourceRepository -trusted psgallery
Install-PSResource Pester,Taskjob -Confirm:$false
dotnet publish --framework net9.0