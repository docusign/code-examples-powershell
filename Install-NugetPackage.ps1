function Install-NugetPackage {
    param(
        [string] $packageName,
        [string] $targetVersion
    )

    # Install nuget package into GAC
    Install-Package $packageName `
        -Source https://www.nuget.org/api/v2 `
        -Provider nuget `
        -RequiredVersion $targetVersion

    # Opening the nupkg file as a zip file in memory
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    $zip = [System.IO.Compression.ZipFile]::Open((Get-Package $packageName).Source, "Read")
    # Create a memory stream to store the raw bytes
    $memStream = [System.IO.MemoryStream]::new()
    $reader = [System.IO.StreamReader]($zip.entries[2]).Open()
    $reader.BaseStream.CopyTo($memStream)
    # Saving the bytes from the memory stream as a byte array
    [byte[]]$bytes = $memStream.ToArray()

    # Load nuget assembly
    [System.Reflection.Assembly]::Load($bytes)

    # Disposing the used objects
    $reader.Close()
    $zip.Dispose()
}
