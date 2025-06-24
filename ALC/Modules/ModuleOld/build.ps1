'net472', 'net8.0' | ForEach-Object {
    dotnet publish --configuration Release --output "$PSScriptRoot/bin/$_" --framework $_ "$PSScriptRoot/src/ModuleOld.csproj"
}
