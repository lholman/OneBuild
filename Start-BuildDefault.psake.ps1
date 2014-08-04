#*==========================================================================================
#* Requirements:
#* 1. Install PowerShell 2.0+ on local machine
#* 2. Execute from build.bat
#*==========================================================================================
#* Purpose: Performs the grunt of the psake based build of the  applications
#*==========================================================================================
#*==========================================================================================
#* SCRIPT BODY
#*==========================================================================================
Properties { 
	
	$msbuildPath = $p1
	$configMode = $p2
	$buildCounter = $p3
	$updateNuGetPackages = $p4
	$webDeployPackage = $p5
}

$ErrorActionPreference = 'Stop'
$DebugPreference = "Continue"

$basePath = Resolve-Path .

#As the 'OneBuild' NuGet package (and subsequently the modules location) location differs between versions we load it dynamically.
if ((Test-Path -path "$basePath\tools\powershell\modules" ) -eq $True)  
{
	$baseModulePath = "$basePath\tools\powershell\modules"
}else{
	#We order descending so that we can easily drop in a locally built version of OneBuild with an later version number (i.e. with a high buildCounter value) for testing.
	$baseModulePath = Get-ChildItem .\packages -Recurse | Where-Object {$_.Name -like 'OneBuild.*' -and $_.PSIsContainer -eq $True} | Sort-Object $_.FullName -Descending | Select-Object FullName -First 1 | foreach {$_.FullName}
	$baseModulePath = "$baseModulePath\tools\powershell\modules"
}
Write-Warning "Base module path: $baseModulePath"

$script:assemblyInformationalVersion = ""
$script:major = $null
$script:minor = $null
$script:versionNumberFileName = "VersionNumber.xml"

Task default -depends Invoke-Commit

#*================================================================================================
#* Purpose: Performs a full rebuild of the Visual Studio Solution, 
#* removing any previously built assemblies, setting the global build number, executing unit
#* tests and packaging the assemblies as a NuGet package
#*================================================================================================
Task Invoke-Commit -depends Invoke-Compile, Invoke-UnitTests, Invoke-AcceptanceTests, New-Packages, New-WebDeployPackages, Undo-CheckedOutFiles {
	

}

#*================================================================================================
#* Purpose: The final part of Invoke-Commit undoes the changes to the AssemblyInfo.cs made when 
#* we executed Set-Version
#* Pre-condition: We only run this in Debug mode as tf.exe stupidly returns a non-zero error code 
#* if there is nothing to undo checkout on. This is really only required within Development too.
#*================================================================================================
Task Undo-CheckedOutFiles -precondition { ($configMode -eq "Debug") } {
	
	Import-Module "$baseModulePath\Undo-TfsFileModifications.psm1"
	Undo-TfsFileModifications -fileName AssemblyInfo.cs
	Remove-Module Undo-TfsFileModifications
}

#*================================================================================================
#* Purpose: Generates a new Nuget ([packageName].[version].nupkg) and optional Symbols package 
#* ({packageName].[version].symbols.nupkg) by finding a relevant .nuspec file by convention.
#*================================================================================================
Task New-Packages -depends Set-VersionNumber -precondition { $webDeployPackage -eq $False } {

	if ($script:assemblyInformationalVersion -ne "")
	{
		$versionLabels = $script:assemblyInformationalVersion.Split(".")
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
#* This is intended to be an intermediate step to support the code base refactor work but prior
#* to more scalable automated deployment.
#*================================================================================================
Task New-WebDeployPackages -depends Set-VersionNumber -precondition { $webDeployPackage -eq $True } {

	if ($script:assemblyInformationalVersion -ne "")
	{
		$versionLabels = $script:assemblyInformationalVersion.Split(".")
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
Task Invoke-UnitTests {

	Import-Module "$baseModulePath\Invoke-NUnitTestsForAllProjects.psm1"
	Invoke-NUnitTestsForAllProjects
	Remove-Module Invoke-NUnitTestsForAllProjects
} 

#*================================================================================================
#* Purpose: Cleans and Rebuilds a Visual Studio solution file (identified by convention) to generate 
#* compiled .NET assemblies. 
#*================================================================================================
Task Invoke-Compile -depends Invoke-HardcoreClean, Set-VersionNumber, Update-NuGetPackages {

	Import-Module "$baseModulePath\New-CompiledSolution.psm1"
	New-CompiledSolution -configMode $configMode
	Remove-Module New-CompiledSolution
}

#*================================================================================================
#* Purpose: Sets the consistent build number of the form [major].[minor].[buildCounter].[revision]
#*================================================================================================
Task Set-VersionNumber -depends Read-MajorMinorVersionNumber {

	Import-Module "$baseModulePath\Set-BuildNumberWithTfsChangesetDetail.psm1"
	$script:assemblyInformationalVersion = Set-BuildNumberWithTfsChangesetDetail -major $script:major -minor $script:minor -buildCounter $buildCounter
	Remove-Module Set-BuildNumberWithTfsChangesetDetail
}

#*================================================================================================
#* Purpose: Reads the [major] and [minor] version numbers from the local VersionNumber.xml file.
#*================================================================================================
Task Read-MajorMinorVersionNumber -depends New-DefaultVersionNumberXmlFile -precondition { ($script:major -eq $null) -and ($script:minor -eq $null) } {

	if (Test-Path "$basePath\$($script:versionNumberFileName)")
	{
		#Retrieve the [major] and [minor] version numbers from the $($script:versionNumberFileName) file
		[xml]$x = Get-Content "$basePath\$($script:versionNumberFileName)"
		Write-Warning "$($script:versionNumberFileName) file found, reading to set [major] and [minor] version numbers."
		$script:major = $x.version.major
		Write-Warning "Setting [major] version number to: $($script:major)."
		$script:minor = $x.version.minor
		Write-Warning "Setting [minor] version number to: $($script:minor)."
		
	}else{
		Write-Error "No $basePath\$($script:versionNumberFileName) file found. Maybe you've forgotten to check it in?"
	}
}

#*================================================================================================
#* Purpose: Generates a default VersionNumber.xml file in the solution root folder, setting major = 0 
#* and minor = 1.
#* Pre-condition: Will only run if we're building Debug mode (locally) and VersionNumber.xml does **NOT** exist.
#*================================================================================================
Task New-DefaultVersionNumberXmlFile -precondition { ($configMode -eq "Debug") -and (!(Test-Path "$basePath\$($script:versionNumberFileName)")) } {

	Write-Warning "No $($script:versionNumberFileName) found at: $basePath, generating default $($script:versionNumberFileName) (major = 0 and minor = 1)."

	#Create root XML element
	$x = New-Object -TypeName xml
	$parent = $x.CreateElement("version")
	$parent.SetAttribute("major", 0)			
	$parent.SetAttribute("minor", 1)		
	
	#Save XML document to file.
	$x.AppendChild($parent)
	$x.Save("$basePath\$($script:versionNumberFileName)")
}

#*================================================================================================
#* Purpose: Does what msbuild/VS can't do consistently.  Aggressively and recursively deletes 
#* all /obj and /bin folders from the build path as well as the \BuildOutput folder.
#*================================================================================================
Task Invoke-HardcoreClean {

	Import-Module "$baseModulePath\Remove-FoldersRecursively.psm1"
	Remove-FoldersRecursively
	Remove-Module Remove-FoldersRecursively
}




