<#
.Synopsis
	OneBuild build script invoked by Invoke-Build.

.Description
	OneBuild is a modular set of convention based .NET solution build scripts written in PowerShell, relying on Invoke-Build for task automation. See https://github.com/lholman/OneBuild form more details.
#>

[CmdletBinding()]
param(
	$configuration = "Debug",
	$buildCounter = "999",
	$testName = "*"
)

$DebugPreference = "SilentlyContinue"
$WarningPreference = "Continue"

if ($PSBoundParameters.ContainsKey('Verbose'))
{
	$VerbosePreference = "Continue"
}

if ((Test-Path -path "$BuildRoot\tools\powershell\modules" ) -eq $True)
{
	$baseModulePath = "$BuildRoot\tools\powershell\modules"
}else{
	#We order descending so that we can easily drop in a locally built version of OneBuild with a later version number (i.e. with a high buildCounter value) for testing.
	$baseModulePath = Get-ChildItem .\packages -Recurse | Where-Object {$_.Name -like 'OneBuild.*' -and $_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	$baseModulePath = "$baseModulePath\tools\powershell\modules"
}

function Enter-Build {

	#Checks Windows Operating System bitness for compatibility with OneBuild.
	Import-Module "$baseModulePath\Confirm-WindowsBitness.psm1"
	Confirm-WindowsBitness -verbose
	Remove-Module Confirm-WindowsBitness

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
task Invoke-Commit Invoke-Compile, Invoke-UnitTests, New-Packages, {

}

#=================================================================================================
# Synopsis: Generates new Nuget ([packageName].[version].nupkg) and optional Symbols
# ({packageName].[version].symbols.nupkg) package(s) by passing all found .nuspec files.
#=================================================================================================
task New-Packages Set-VersionNumber, {

	try {
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
	}
	catch {
		throw
	}
	finally {
		Remove-Module New-NuGetPackages
	}	
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

	try {
		Import-Module "$baseModulePath\New-CompiledSolution.psm1"
		New-CompiledSolution -configMode $configuration
	}
	catch {
		throw $_
	}
	finally {
		Remove-Module New-CompiledSolution
	}
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
		Write-Output "$($versionNumberFileName) file found, reading to set [major] and [minor] version numbers."
		$script:major = $x.version.major
		Write-Output "Setting [major] version number to: $($script:major)."
		$script:minor = $x.version.minor
		Write-Output "Setting [minor] version number to: $($script:minor)."

	}else{
		throw "No $BuildRoot\$($versionNumberFileName) file found. Maybe you've forgotten to check it in?"
	}
}

#=================================================================================================
# Synopsis: Generates a default VersionNumber.xml file in the solution root folder, setting major = 0
# and minor = 1.
# Pre-condition: Will only run if we're building Debug mode (locally) and VersionNumber.xml does **NOT** exist.
#=================================================================================================
task New-DefaultVersionNumberXmlFile -If { ($configuration -eq "Debug") -and (!(Test-Path "$BuildRoot\$($versionNumberFileName)")) } {

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
# Pre-condition: Will only run dependent tasks if we're not building in Debug mode (locally).
#=================================================================================================
task Invoke-OneBuildUnitTests {
	
	$pesterPath = Get-ChildItem "$BuildRoot\packages" | Where-Object {$_.Name -like 'pester*'} | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	
	assert ($pesterPath -ne $Null) "No pester NuGet package found under $BuildRoot\packages, maybe try restoring all NuGet packages?"

	Import-Module "$pesterPath\tools\Pester.psm1"
	$result
	try {
		$result = Invoke-Pester -Path "$BuildRoot\tests\" -TestName $testName -PassThru -OutputXml $BuildRoot\TestResult.xml
		assert ($result.FailedCount -eq 0) "$($result.FailedCount) OneBuild unit test(s) failed."
	}
	catch {
		throw
	}
	finally {
		Remove-Module Pester
	}
}

task BeforeInvoke-OneBuildUnitTests -Before Invoke-OneBuildUnitTests -If {($configuration -ne "Debug")} Invoke-HardcoreClean, New-Packages, {

}

