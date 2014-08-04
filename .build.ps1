
<#
.Synopsis
	OneBuild build script invoked by Invoke-Build.

.Description
	TODO: Declare build parameters as standard script parameters. Parameters
	are specified directly for Invoke-Build if their names do not conflict.
	Otherwise or alternatively they are passed in as "-Parameters @{...}".
#>

# TODO: [CmdletBinding()] is optional but recommended for strict name checks.
[CmdletBinding()]
param(
)

# TODO: Move some properties to script param() in order to use as parameters.
 
	
$msbuildPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe"
$configMode = "Debug"
$buildCounter = "999"
$updateNuGetPackages = $false
$webDeployPackage = $false

$ErrorActionPreference = 'Stop'
$DebugPreference = "Continue"
$basePath = Resolve-Path .

if ((Test-Path -path "$basePath\tools\powershell\modules" ) -eq $True)  
{
	$baseModulePath = "$basePath\tools\powershell\modules"
}else{
	#We order descending so that we can easily drop in a locally built version of OneBuild with an later version number (i.e. with a high buildCounter value) for testing.
	$baseModulePath = Get-ChildItem .\packages -Recurse | Where-Object {$_.Name -like 'OneBuild.*' -and $_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	$baseModulePath = "$baseModulePath\tools\powershell\modules"
}

Write-Warning "Base module path: $baseModulePath"

$assemblyInformationalVersion = ""
$major = $null
$minor = $null
$versionNumberFileName = "VersionNumber.xml"

# TODO: Default task. If it is the first then any name can be used instead.
task . Invoke-Commit

#*================================================================================================
#* Purpose: Performs a full rebuild of the Visual Studio Solution, removing any previously built 
#* assemblies, setting a common build number, executing unit tests and packaging the assemblies 
#* as a NuGet package
#*================================================================================================
task Invoke-Commit Invoke-Compile, Invoke-UnitTests, New-Packages, New-WebDeployPackages, Undo-CheckedOutFiles, {
	

}

#*================================================================================================
#* Purpose: The final part of Invoke-Commit undoes the changes to the AssemblyInfo.cs made when 
#* we executed Set-Version
#* Pre-condition: We only run this in Debug mode as tf.exe returns a non-zero error code 
#* if there is nothing to undo checkout on. This is really only required within Development too.
#*================================================================================================
task Undo-CheckedOutFiles -If { ($configMode -eq "Debug") } {
	
	Import-Module "$baseModulePath\Undo-TfsFileModifications.psm1"
	Undo-TfsFileModifications -fileName AssemblyInfo.cs
	Remove-Module Undo-TfsFileModifications
}

#*================================================================================================
#* Purpose: Generates new Nuget ([packageName].[version].nupkg) and optional Symbols 
#* ({packageName].[version].symbols.nupkg) package(s) by passing all found .nuspec files.
#*================================================================================================
task New-Packages -If { $webDeployPackage -eq $False } Set-VersionNumber, {

	if ($assemblyInformationalVersion -ne "")
	{
		$versionLabels = $assemblyInformationalVersion.Split(".")
		$nuGetPackageVersion = $versionLabels[0] + "." + $versionLabels[1] + "." + $versionLabels[2]
	}
	else
	{
		$nuGetPackageVersion = "$major.$minor.$buildCounter"
	}
	
	Write-Host "Will use version: $nuGetPackageVersion to build NuGet package"
	Import-Module "$baseModulePath\New-NuGetPackage.psm1"
	New-NuGetPackage -versionNumber $nuGetPackageVersion
	Remove-Module New-NuGetPackage
}

#*================================================================================================
#* Purpose: Executes MSBuild.exe to create WebDeploy Package(s) for Visual Studio Web Projects 
#* matching a defined naming convention.
#*================================================================================================
task New-WebDeployPackages -If { $webDeployPackage -eq $True } Set-VersionNumber, {

	if ($assemblyInformationalVersion -ne "")
	{
		$versionLabels = $assemblyInformationalVersion.Split(".")
		$webDeployPackageVersion = $versionLabels[0] + "." + $versionLabels[1] + "." + $versionLabels[2]
	}
	else
	{
		$webDeployPackageVersion = "$major.$minor.$buildCounter"
	}
	
	Write-Host "Will use version: $webDeployPackageVersion to build NuGet package"
	
	Import-Module "$baseModulePath\New-WebDeployPackages.psm1"
	New-WebDeployPackages -configMode $configMode -version $webDeployPackageVersion
	Remove-Module New-WebDeployPackages
}

#*================================================================================================
#* Purpose: Executes all NUnit tests for compiled .NET assemblies matching a defined naming convention.
#*================================================================================================
task Invoke-UnitTests {

	Import-Module "$baseModulePath\Invoke-NUnitTestsForAllProjects.psm1"
	Invoke-NUnitTestsForAllProjects
	Remove-Module Invoke-NUnitTestsForAllProjects
}

#*================================================================================================
#* Purpose: Cleans and Rebuilds a Visual Studio solution file (identified by convention) to generate 
#* compiled .NET assemblies. 
#*================================================================================================
task Invoke-Compile Invoke-HardcoreClean, Set-VersionNumber, {

	Import-Module "$baseModulePath\New-CompiledSolution.psm1"
	New-CompiledSolution -configMode $configMode
	Remove-Module New-CompiledSolution
}

#*================================================================================================
#* Purpose: Sets the consistent build number of the form [major].[minor].[buildCounter].[revision]
#*================================================================================================
task Set-VersionNumber Read-MajorMinorVersionNumber, {

	Import-Module "$baseModulePath\Set-BuildNumberWithTfsChangesetDetail.psm1"
	$script:assemblyInformationalVersion = Set-BuildNumberWithTfsChangesetDetail -major $major -minor $minor -buildCounter $buildCounter
	Remove-Module Set-BuildNumberWithTfsChangesetDetail
}

#*================================================================================================
#* Purpose: Reads the [major] and [minor] version numbers from the local VersionNumber.xml file.
#*================================================================================================
task Read-MajorMinorVersionNumber -If { ($major -eq $null) -and ($minor -eq $null) } New-DefaultVersionNumberXmlFile, {

	if (Test-Path "$basePath\$($versionNumberFileName)")
	{
		#Retrieve the [major] and [minor] version numbers from the $($versionNumberFileName) file
		[xml]$x = Get-Content "$basePath\$($versionNumberFileName)"
		Write-Warning "$($versionNumberFileName) file found, reading to set [major] and [minor] version numbers."
		$script:major = $x.version.major
		Write-Warning "Setting [major] version number to: $($script:major)."
		$script:minor = $x.version.minor
		Write-Warning "Setting [minor] version number to: $($script:minor)."
		
	}else{
		Write-Error "No $basePath\$($versionNumberFileName) file found. Maybe you've forgotten to check it in?"
	}
}

#*================================================================================================
#* Purpose: Generates a default VersionNumber.xml file in the solution root folder, setting major = 0 
#* and minor = 1.
#* Pre-condition: Will only run if we're building Debug mode (locally) and VersionNumber.xml does **NOT** exist.
#*================================================================================================
task New-DefaultVersionNumberXmlFile -If { ($configMode -eq "Debug") -and (!(Test-Path "$basePath\$($versionNumberFileName)")) } {

	Write-Warning "No $($versionNumberFileName) found at: $basePath, generating default $($versionNumberFileName) (major = 0 and minor = 1)."

	#Create root XML element
	$x = New-Object -TypeName xml
	$parent = $x.CreateElement("version")
	$parent.SetAttribute("major", 0)			
	$parent.SetAttribute("minor", 1)		
	
	#Save XML document to file.
	$x.AppendChild($parent)
	$x.Save("$basePath\$($versionNumberFileName)")
}

#*================================================================================================
#* Purpose: Does what msbuild/VS can't do consistently.  Aggressively and recursively deletes 
#* all /obj and /bin folders from the build path as well as the \BuildOutput folder.
#*================================================================================================
task Invoke-HardcoreClean {

	Import-Module "$baseModulePath\Remove-FoldersRecursively.psm1"
	Remove-FoldersRecursively
	Remove-Module Remove-FoldersRecursively
}





