param($installPath, $toolsPath, $package)

#Forces the Batch and PS scripts for executing the build up to the root solution folder.
Copy-Item "$installPath\tools\temp\*.*" -destination "$installPath\..\..\" -recurse
Remove-Item "$installPath\tools\temp\" -recurse 
