function Set-BuildNumberWithTfsChangesetDetail{
<#
 
.SYNOPSIS
    A powershell module that sets the full build number ([major].[minor].[buildCounter].[revision]) in a consistent way for all applications.
.DESCRIPTION
    A powershell module that sets the full build number ([major].[minor].[buildCounter].[revision]) in a consistent way for all applications.
	Determines revision (Changeset) and branch information from Team Foundation Server, enumerates and updates all AssemblyInfo.cs files with the defined build number.  
	We purposefully only use TeamCity (or any other CI server) to generate the incrementing [buildCounter] part of the number.
.NOTES
  Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER major
	Optional. The major part of the desired build number {major}.{minor}.{buildCounter}.{revision}. Defaults to 1.
.PARAMETER minor
	Optional. The minor part of the desired build number {major}.{minor}.{buildCounter}.{revision}. Defaults to 0.
.PARAMETER buildCounter
	Optional. The buildCounter part of the desired build number {major}.{minor}.{buildCounter}.{revision}.  This is usually supplied by your CI tool of choice. Defaults to 0.
.PARAMETER tfsWorkspacePath
	Optional. The full local path to the Team Foundation Server (TFS) workspcae working folder. Defaults to the calling scripts path (using Resolve-Path .)
.PARAMETER tfsTeamProjectCollectionUrl
	Optional. The Url of the Team Foundation Server (TFS) Team Project Collection Url.  Defaults to 'http://gb-doc-svv-0382/"Personalisation Services Platform (PSP)"'
.PARAMETER tfPath
	Optional. The full path to the Team Foundation Server (TFS) tf.exe or TFS Every where tf.cmd.  Defaults to 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe'.
.PARAMETER sendTeamCityServiceMessage
	Optional. Instructs the module to send a TeamCity formatted service message containing the buildNumber, forcing TeamCity to use the generated buildNumber.  Defaults to $true
.EXAMPLE 
	Import-Module Set-BuildNumberWithTfsChangesetDetail
	Import the module
.EXAMPLE	
	Get-Command -Module Set-BuildNumberWithTfsChangesetDetail
	List available functions
.EXAMPLE
	Set-BuildNumberWithTfsChangesetDetail -major 2 -minor 4 -buildCounter 45678
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$major = 1,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$minor = 0,
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[string]$buildCounter = 0,	
			[Parameter(
				Position = 3,
				Mandatory = $False )]
				[string]$tfsWorkspacePath,
			[Parameter(
				Position = 4,
				Mandatory = $False )]
				[string]$tfsTeamProjectCollectionUrl = "http://gb-doc-svv-0382/Personalisation Services Platform (PSP)",				
			[Parameter(
				Position = 5,
				Mandatory = $False )]
				[string]$tfPath,	
			[Parameter(
				Position = 6,
				Mandatory = $False )]
				[string]$sendTeamCityServiceMessage = $true					
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {

			$Invocation = (Get-Variable MyInvocation -Scope 1).Value
			$basePath = Split-Path $Invocation.MyCommand.Path
				
			if ($tfsWorkspacePath -eq "")
			{
				$tfsWorkspacePath = Resolve-Path .
				Write-Host "Setting Team Foundation Server (TFS) Working folder path to the calling scripts path (using Resolve-Path .): $tfsWorkspacePath"
			}
			if ($tfPath -eq "")
			{
				$tfPath = "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"
			}
			Write-Warning "TF command path set to: $tfPath"
			
			#Set sensible defaults for revision and branchName in case we can't determine them
			$revision = "0"
			$branchName = "unknown"

			#Gets the latest TFS changeset number to use as the revision number, if unable to then use zero (0)
			if ((Test-Path -path $tfsWorkspacePath\TFSChangesetDetails.txt )) 
			{
				Remove-Item $tfsWorkspacePath\TFSChangesetDetails.txt -force
			}
			#Ensure we have accepted the TFS Team Explorer Everywhere licence agreement - http://msdn.microsoft.com/en-us/library/hh873092(v=vs.110).aspx
			#& $tfPath eula /accept
			
			#& $tfPath history $tfsWorkspacePath /recursive /stopafter:1 /format:detailed > $tfsWorkspacePath\TFSChangesetDetails.txt
			& $tfPath history $tfsWorkspacePath /r /noprompt /stopafter:1 /Version:T /format:detailed /collection:$tfsTeamProjectCollectionUrl > $tfsWorkspacePath\TFSChangesetDetails.txt

			#Gets information about the current mapping between the local workspace folders and the Team Foundation version control folders, allowing us
			#to rather crudely determine the TFS branch.  
			#FYI, TFS doesn't provide a sensible means to get the name of the current branch
			if ((Test-Path -path $tfsWorkspacePath\TFSWorkfoldDetails.txt )) 
			{
				Remove-Item $tfsWorkspacePath\TFSWorkfoldDetails.txt -force
			}
			& $tfPath workfold . /noprompt > $tfsWorkspacePath\TFSWorkfoldDetails.txt
			
			if ((Test-Path -path $tfsWorkspacePath\TFSChangesetDetails.txt )) 
			{
				#Here we're grabbing the TFS changeset number to use as the revision number
				$changeSetNumber = ((Get-Content "$tfsWorkspacePath\TFSChangesetDetails.txt" -encoding utf8 | Select-String "Changeset:") -replace "Changeset:", "").Trim()
				if ($changeSetNumber -ne "")
				{
					$revision = $changeSetNumber
				}
				
				Write-Host "Revision is: $revision"
			
				#if ((Test-Path -path $tfsWorkspacePath\TFSWorkfoldDetails.txt )) 
				#{
					#Here we're grabbing the TFS branch name to use in the AssemblyInformationalVersion
				#	$branchInformation = Get-Content "$tfsWorkspacePath\TFSWorkfoldDetails.txt" -encoding utf8 | Select-String " Scrum"
				#	$branchInformationSplit = $branchInformation -split ":"
				#	$spiltBranchName = $branchInformationSplit[0].Replace('$/ Scrum/', '').Trim()
					
				#	if ($spiltBranchName -ne $null -and $spiltBranchName -ne "")
				#	{
				#		$branchName = $spiltBranchName
				#	}

				#	Write-Host "BranchName is: $branchName"
				#}
				#else
				#{
				#	Write-Host "Unable to establish branch name from TFS, using unknown"
				#}	
				
			}
			else
			{
				Write-Host "Unable to establish changeset details from TFS, using 0 for revision number"
			}	

			#We always set AssemblyVersion to the Major and Minor build numbers only so as to reduce headaches with referencing assemblies. 
			#See http://stackoverflow.com/questions/64602/what-are-differences-between-assemblyversion-assemblyfileversion-and-assemblyin for more details	
			$assemblyVersion = [string]::Format("{0}.{1}.{2}.{3}", $major, $minor, "0", "0") #AssemblyVersion
			$assemblyFileVersion = [string]::Format("{0}.{1}.{2}.{3}", $major, $minor, $buildCounter, $revision) #AssemblyFileVersion
			$buildNumberInformational = [string]::Format("{0}.{1}.{2}.{3} ({4})", $major, $minor, $buildCounter, $revision, $branchName.ToLower()) #AssemblyInformationalVersion
			
			$newAssemblyVersion = 'AssemblyVersion("' + $assemblyVersion + '")'
			$newAssemblyFileVersion = 'AssemblyFileVersion("' + $assemblyFileVersion + '")'
			$newAssemblyInformationalVersion = 'AssemblyInformationalVersion("' + $($buildNumberInformational.ToLower()) + '")'	
			
			Write-Host "Assembly versioning set as follows.."
			Write-Host "$newAssemblyVersion"
			Write-Host "$newAssemblyFileVersion"
			Write-Host "$newAssemblyInformationalVersion"

			#Enumerate through all AssemblyInfo.cs files, updating the AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion accordingly, 
			#this can be subsequently reverted once the compilation is complete.
			$assemblyInfoFiles = Get-ChildItem $tfsWorkspacePath -recurse -include AssemblyInfo.cs
			if ($assemblyInfoFiles -eq $null)
			{
				Write-Warning "No AssemblyInfo.cs file(s) found to update..."
				return
			}
			ForEach ($assemblyInfoFile in $assemblyInfoFiles)
			{
				Try	{
				Write-Host "Updating $assemblyInfoFile with build number"
				(Get-Content $assemblyInfoFile -encoding utf8) | 
				%{ $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyVersion }  | 
				%{ $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyFileVersion } | 
				%{ $_ -replace 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}(( )(\(?)*[a-z]*(\)?))?"\)', $newAssemblyInformationalVersion } | Set-Content $assemblyInfoFile -force -encoding utf8
				}
				Catch [System.Exception]
				{
					Write-Warning "Error reading from/writing to assemblyinfo file(s): $assemblyInfoFile"
					#Get the script path, rather than the executing path and undo changes.
					Import-Module ".\$basePath\Undo-TfsFileModifications.psm1"
					Undo-TfsFileModifications -fileName AssemblyInfo.cs
					Remove-Module Undo-TfsFileModifications
				}
			}
			
			
		}
	End {
			if ($sendTeamCityServiceMessage -eq $true)
			{
				#Forces TeamCity to use a specific buildNumber (substituting in its build counter as we only use {0} in the TeamCity build number format
				#See http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-ReportingBuildNumber 
				#and http://youtrack.jetbrains.com/issue/TW-18455 for more details.
				Write-Host "##teamcity[buildNumber '$major.$minor.$buildCounter.$revision']" 
			}
			return $assemblyFileVersion
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUX9otEzug9FkDcDpIUthq3J1e
# YDmgggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNDAzMjcxNTM4MTJaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAyCSg/wCkjDGS
# Mv7A5OLubZZCxcRW2lSRerbfN8KE1EsAD3X7E/Jy6oOaH8h7+r83744v4TUmxQ23
# 9rptO5H2NPRl6+HpCapatTGHodCLYcdV+PbnfQP19g+2VgpOuzJc1ltTF+cQbzMY
# 8aLbt2njo3jPAgIT1cEx5j/+Hd96vqUCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYB
# BQUHAwMwXQYDVR0BBFYwVIAQvg+wxIsvFis5+YRLK6JQfqEuMCwxKjAoBgNVBAMT
# IVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQijjs33C86o9FovTA
# 2hbxiTAJBgUrDgMCHQUAA4GBAA1qfdSfmUXeXAvocTMh3arC5I4orm6mPWK2XdyU
# WdeVWKXRHg1ZTZY54OOYVc7Yl/VH90DvyxMbsJw+seyPkygAnXRg5gbgeWIT8/lT
# lgSnCbIm1g9Qx0tRKnyuKeRgB0rQ/cQehOmmPx8IH3tpIEfWctuA/V06W94T6Ot2
# 28sEMYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENl
# cnRpZmljYXRlIFJvb3QCEAcEngdt6Ue0TjjmDR6uGr4wCQYFKw4DAhoFAKB4MBgG
# CisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcC
# AQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYE
# FPcht9wkGuxVtvSGEnlhDXDOj6J/MA0GCSqGSIb3DQEBAQUABIGAchA+wPeU4ely
# 25om3O0cLvjyLGs8A7uGNBGRyHR2CGn/156GW7pn4U7NNFAjhYSaopQFvYAQKaZO
# mBFf65eUP889ULTtGgZhf4q/Jq6p2baah3tZ/QW9HZXwHaArdjahSkBz/6UVcUaL
# 4F5NHdmhjiImJaxEv2Nl+R/XyqJDiWo=
# SIG # End signature block
