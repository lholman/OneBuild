function Undo-TfsFileModifications{
<#
 
.SYNOPSIS
    Given a filename will attempt to recursively undo modifications to that file within the supplied TFS workspace
.DESCRIPTION
    Given a filename will attempt to recursively undo modifications to that file within the supplied TFS workspace

.NOTES
  Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER fileName
	Optional. The file to undo changes for.  Note this module acts recursively so undoes modifications all files matching the supplied name.
.PARAMETER tfsTeamProjectCollectionUrl
	Optional. The Url of the Team Foundation Server (TFS) Team Project Collection Url.  Defaults to 'http://gb-doc-svv-0382/Personalisation Services Platform (PSP)'
.PARAMETER tfPath
	Optional. The full path to the Team Foundation Server (TFS) tf.exe or TFS Every where tf.cmd.  Defaults to 'C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe'.
.EXAMPLE 
	Import-Module Undo-TfsFileModifications
	Import the module
.EXAMPLE	
	Get-Command -Module Undo-TfsFileModifications
	List available functions
.EXAMPLE
	Undo-TfsFileModifications -fileName AssemblyInfo.cs
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $True )]
				[string]$fileName,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$tfsTeamProjectCollectionUrl = "http://gb-doc-svv-0382/Personalisation Services Platform (PSP)",				
			[Parameter(
				Position = 2,
				Mandatory = $False )]
				[string]$tfPath
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				$Invocation = (Get-Variable MyInvocation -Scope 1).Value
				$basePath = Split-Path $Invocation.MyCommand.Path
			
				if ($tfPath -eq "")
				{
					$tfPath = "C:\Program Files (x86)\Microsoft Visual Studio 11.0\Common7\IDE\tf.exe"
				}
				Write-Warning "TF command path set to: $tfPath"
				
				Try 
				{

					Write-Host "Undoing all TFS file modifications to $fileName files"
					#Performs a TFS undo on the specified fileName
					#Annoyingly we can't pass in a path to tf.exe undo (unlike with tf.exe history), thankfully a modules executing path is that of the calling script so this *should* always work. 
					
					#We only run this in Debug mode as tf.exe stupidly returns a non-zero error code if there is nothing to undo checkout on.
					& $tfPath undo $fileName /recursive /noprompt /collection:$tfsTeamProjectCollectionUrl
				}
				catch [Exception] {
					$result = "There was an error attempting to undo $fileName. `r`n $_.Exception.ToString()"
				}
		}
	End {
			return $result | Format-Table 
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUln/Kjfv0T5QbiIrcUj9hY4Ww
# 4zagggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
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
# FKzbzRFxwr1rvts/Z4PVS4beHqJaMA0GCSqGSIb3DQEBAQUABIGAajK2kdnZVNqH
# Nokk/LekFfYFryeIgEkDrwPhfsAeYf7btbGmyvNTLsrli0JbE2w4gQM3TuiVNGad
# 4LNTMQxyavG0CoYnK2U7etX5F1u0T4aMuJbhuvh5qaqMJmxVDfq3K+Hwy1riCf7h
# OQr2i4jS2eQkauyKxg1nTVpO1g/sQSQ=
# SIG # End signature block
