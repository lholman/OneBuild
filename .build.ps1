<#
.Synopsis
	OneBuild build script invoked by Invoke-Build.

.Description
	OneBuild is a modular set of convention based .NET solution build scripts written in PowerShell, relying on Invoke-Build for task automation. See https://github.com/lholman/OneBuild form more details.
#>

[CmdletBinding()]
param(
	$msbuildPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe",
	$configMode = "Debug",
	$buildCounter = "999",
	$updateNuGetPackages = $false
)

$DebugPreference = "Continue"

if ((Test-Path -path "$BuildRoot\tools\powershell\modules" ) -eq $True)
{
	$baseModulePath = "$BuildRoot\tools\powershell\modules"
}else{
	#We order descending so that we can easily drop in a locally built version of OneBuild with a later version number (i.e. with a high buildCounter value) for testing.
	$baseModulePath = Get-ChildItem .\packages -Recurse | Where-Object {$_.Name -like 'OneBuild.*' -and $_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	$baseModulePath = "$baseModulePath\tools\powershell\modules"
}

function Enter-Build {
	Write-Output "Base module path: $baseModulePath"
}

$assemblyInformationalVersion = ""
$major = $null
$minor = $null
$versionNumberFileName = "VersionNumber.xml"

# Default task.
task . Invoke-Commit

#=================================================================================================
# Synopsis: Performs a full rebuild of the Visual Studio Solution, removing any previously built
# assemblies, setting a common build number, executing unit tests and packaging the assemblies
# as a NuGet package
#=================================================================================================
task Invoke-Commit Invoke-Compile, Invoke-UnitTests, New-Packages, Undo-CheckedOutFiles, {

}

#=================================================================================================
# Synopsis: The final part of Invoke-Commit undoes the changes to the AssemblyInfo.cs made when
# we executed Set-Version
# Pre-condition: We only run this in Debug mode as tf.exe returns a non-zero error code
# if there is nothing to undo checkout on. This is really only required within Development too.
#=================================================================================================
task Undo-CheckedOutFiles -If { ($configMode -eq "Debug") } {

	Import-Module "$baseModulePath\Undo-TfsFileModifications.psm1"
	Undo-TfsFileModifications -fileName AssemblyInfo.cs
	Remove-Module Undo-TfsFileModifications
}

#=================================================================================================
# Synopsis: Generates new Nuget ([packageName].[version].nupkg) and optional Symbols
# ({packageName].[version].symbols.nupkg) package(s) by passing all found .nuspec files.
#=================================================================================================
task New-Packages Set-VersionNumber, {

	if ($assemblyInformationalVersion -ne "")
	{
		$versionLabels = $assemblyInformationalVersion.Split(".")
		$nuGetPackageVersion = $versionLabels[0] + "." + $versionLabels[1] + "." + $versionLabels[2]
	}
	else
	{
		$nuGetPackageVersion = "$major.$minor.$buildCounter"
	}

	Write-Output "Will use version: $nuGetPackageVersion to build NuGet package"
	Import-Module "$baseModulePath\New-NuGetPackages.psm1"
	New-NuGetPackages -versionNumber $nuGetPackageVersion
	Remove-Module New-NuGetPackages
}

#=================================================================================================
# Synopsis: Executes all NUnit tests for compiled .NET assemblies matching a defined naming convention.
#=================================================================================================
task Invoke-UnitTests {

	Import-Module "$baseModulePath\Invoke-NUnitTestsForAllProjects.psm1"
	Invoke-NUnitTestsForAllProjects
	Remove-Module Invoke-NUnitTestsForAllProjects
}

#=================================================================================================
# Synopsis: Cleans and Rebuilds a Visual Studio solution file (identified by convention) to generate
# compiled .NET assemblies.
#=================================================================================================
task Invoke-Compile Invoke-HardcoreClean, Set-VersionNumber, {

	$errorCode = 0
	try {
		Import-Module "$baseModulePath\New-CompiledSolution.psm1"
		$errorCode = New-CompiledSolution -configMode $configMode
	}
	catch {
		throw
	}
	finally {
		Remove-Module New-CompiledSolution
	}
	assert ($errorCode -eq 0)
}

#=================================================================================================
# Synopsis: Sets the consistent build number of the form [major].[minor].[buildCounter].[revision]
#=================================================================================================
task Set-VersionNumber Read-MajorMinorVersionNumber, {

	Import-Module "$baseModulePath\Set-BuildNumberWithGitCommitDetail.psm1"
	$script:assemblyInformationalVersion = Set-BuildNumberWithGitCommitDetail -major $major -minor $minor -buildCounter $buildCounter
	Remove-Module Set-BuildNumberWithGitCommitDetail
}

#=================================================================================================
# Synopsis: Reads the [major] and [minor] version numbers from the local VersionNumber.xml file.
#=================================================================================================
task Read-MajorMinorVersionNumber -If { ($major -eq $null) -and ($minor -eq $null) } New-DefaultVersionNumberXmlFile, {

	if (Test-Path "$BuildRoot\$($versionNumberFileName)")
	{
		#Retrieve the [major] and [minor] version numbers from the $($versionNumberFileName) file
		[xml]$x = Get-Content "$BuildRoot\$($versionNumberFileName)"
		Write-Warning "$($versionNumberFileName) file found, reading to set [major] and [minor] version numbers."
		$script:major = $x.version.major
		Write-Warning "Setting [major] version number to: $($script:major)."
		$script:minor = $x.version.minor
		Write-Warning "Setting [minor] version number to: $($script:minor)."

	}else{
		Write-Error "No $BuildRoot\$($versionNumberFileName) file found. Maybe you've forgotten to check it in?"
	}
}

#=================================================================================================
# Synopsis: Generates a default VersionNumber.xml file in the solution root folder, setting major = 0
# and minor = 1.
# Pre-condition: Will only run if we're building Debug mode (locally) and VersionNumber.xml does **NOT** exist.
#=================================================================================================
task New-DefaultVersionNumberXmlFile -If { ($configMode -eq "Debug") -and (!(Test-Path "$BuildRoot\$($versionNumberFileName)")) } {

	Write-Warning "No $($versionNumberFileName) found at: $BuildRoot, generating default $($versionNumberFileName) (major = 0 and minor = 1)."

	#Create root XML element
	$x = New-Object -TypeName xml
	$parent = $x.CreateElement("version")
	$parent.SetAttribute("major", 0)
	$parent.SetAttribute("minor", 1)

	#Save XML document to file.
	$x.AppendChild($parent)
	$x.Save("$BuildRoot\$($versionNumberFileName)")
}

#=================================================================================================
# Synopsis: Does what msbuild/VS can't do consistently.  Aggressively and recursively deletes
# all /obj and /bin folders from the build path as well as the \BuildOutput folder.
#=================================================================================================
task Invoke-HardcoreClean {

	Import-Module "$baseModulePath\Remove-FoldersRecursively.psm1"
	Remove-FoldersRecursively -deleteIncludePath @("bin","obj","BuildOutput")
	Remove-Module Remove-FoldersRecursively
}

#=================================================================================================
# Synopsis: Runs the Pester (https://github.com/pester/Pester) based unit tests for OneBuild
#=================================================================================================
task Invoke-OneBuildUnitTests New-Packages, {
	
	#.\packages\invoke-build.2.9.12\tools\Invoke-Build.ps1 Invoke-OneBuildUnitTests .\.build.ps1
	
	$pesterPath = Get-ChildItem "$BuildRoot\packages" | Where-Object {$_.Name -like 'pester*'} | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	
	assert ($pesterPath -ne $Null) "No pester NuGet package found under $BuildRoot\packages, maybe try restoring all NuGet packages?"

	Import-Module "$pesterPath\tools\Pester.psm1"
	$result
	try {
		$result = Invoke-Pester -Path "$BuildRoot\tests" -PassThru
	}
	catch {
		throw
	}
	finally {
		Remove-Module Pester
	}
	assert ($result.FailedCount -eq 0)
}
