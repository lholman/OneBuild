param($installPath, $toolsPath, $package)

#Forces the Batch and PS scripts for executing OneBuild up to the root solution folder.
if (Test-Path "$toolsPath\temp")
{
	Copy-Item "$toolsPath\temp\*.*" -destination "$installPath\..\..\" -recurse
	Remove-Item "$toolsPath\temp\" -recurse 
}