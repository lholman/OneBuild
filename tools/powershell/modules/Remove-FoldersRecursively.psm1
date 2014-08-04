function Remove-FoldersRecursively{
<#
 
.SYNOPSIS
    Recursively removes (deletes) all matching common .NET build folders from a supplied base folder path down.
.DESCRIPTION
    Recursively removes (deletes) all matching common .NET build folders from a supplied base folder path down, optionally allows passing of a custom list of folders to delete.
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER basePath
	Optional. The path to the root parent folder to execute the recursive remove from.  Defaults to the calling scripts path.
.PARAMETER deleteIncludePaths
	Optional. A string array separated list of folder names to remove recursively, any folders matching the names of the items in the list found below the basePath will be removed.  Defaults to @("bin","obj","BuildOutput")
.EXAMPLE 
	Import-Module Remove-FoldersRecursively
	Import the module
.EXAMPLE	
	Get-Command -Module Remove-FoldersRecursively
	List available functions
.EXAMPLE
	Remove-FoldersRecursively -deleteIncludePaths bin,obj,BuildOutput
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $False )]
				[string]$basePath,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[array]$deleteIncludePaths = @("bin","obj","BuildOutput")		
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					Write-Debug "Started"
					
					if ($basePath -eq "")
					{
						Write-Debug "Setting the basePath to the calling scripts path (using Resolve-Path .)"
						$basePath = Resolve-Path .
					}
					Get-ChildItem -Path $basePath -Include $deleteIncludePaths -Recurse | 
						#? { $_.psiscontainer -and $_.fullname -notmatch 'packages' } | #Uncomment to exclude a particular root folder
						foreach ($_) { 
							Write-Output "Cleaning: $_"
							Remove-Item $_ -Force -Recurse -ErrorAction SilentlyContinue		
						}	
				}
				catch [Exception] {
					throw "Error removing folders for supplied deleteIncludePaths: $deleteIncludePaths under path: $basePath `r`n $_.Exception.ToString()"
				}
		}
}
# SIG # Begin signature block
# MIIEMwYJKoZIhvcNAQcCoIIEJDCCBCACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8Yi9n6TK6NJBLFp+nEglIR3k
# OKGgggI9MIICOTCCAaagAwIBAgIQBwSeB23pR7ROOOYNHq4avjAJBgUrDgMCHQUA
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
# FO1w1CCOOug0cDHLX0NxWsOtZW2GMA0GCSqGSIb3DQEBAQUABIGASWHkRSe5amJM
# rN83pUxbbnbJKrk4kO64wqE/OJIh/vPcRxMxy/AHrp3PaePyLLrAqwgls26tXZEF
# xL7K2/ezbZtmwwGurcLa5v92x+7DTSMnVP8ETl8PBBY1DpFsfnFpUkQnfq/H+U+N
# KQTIh+BQ1ikhX/sdH27tFTTG9wI7gYU=
# SIG # End signature block
