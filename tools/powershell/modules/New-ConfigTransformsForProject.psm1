function New-ConfigTransformsForProject{
<#
 
.SYNOPSIS
    Given the base path to a Visual Studio project this method will generate environment specific application configuration transformations for any environment transforms found matching the convention.
.DESCRIPTION
    Given the base path to a Visual Studio project this method will generate environment specific application configuration transformations for any environment transforms found matching the convention.
.PARAMETER projectBasePath
	Required. The full path to the Visual Studio (VS) Project path containing [IisConfiguration] folder in its root
.PARAMETER configFileName
	Optional.  The filename of the config file the transformations should be applied for.  Note, this should NOT contain .config file extension. Defaults to Web
.PARAMETER environments
	Required. A single dimension string array containing all environment names the transformations should be applied for
.EXAMPLE 
	Import-Module New-ConfigTransformsForProject
	Import the module
.EXAMPLE	
	Get-Command -Module New-ConfigTransformsForProject
	List available functions
.EXAMPLE
	New-ConfigTransformsForProject -projectBasePath AssemblyInfo.cs
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(
				Position = 0,
				Mandatory = $True )]
				[string]$projectBasePath,
			[Parameter(
				Position = 1,
				Mandatory = $False )]
				[string]$configFileName = "Web",
			[Parameter(
				Position = 2,
				Mandatory = $True )]
				[array]$environments				
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				Try 
				{
					Write-Verbose "Starting: New-ConfigTransformsForProject"
					
					#Get the script path, rather than the executing path
					$Invocation = (Get-Variable MyInvocation -Scope 1).Value
					$basePath = Split-Path $Invocation.MyCommand.Path
					
					Import-Module "$basePath\Transform-ConfigFile.psm1"
					
					#Iterate through all config transformations for the provided project path
					
					#TODO Need to do some GCH goodness here to find all [config] folders in the current solution
					
					foreach($environment in $environments)
					{
						$environmentPath = "$projectBasePath\`[Configuration`]\Transforms\$environment"
						if (!(Test-Path -LiteralPath $environmentPath))
						{
							throw "Environment path: $environmentPath does not exist."
						}
						
						Write-Verbose "Processing config transforms for environment: $environment"
						if (!(Test-Path -LiteralPath "$environmentPath\$configFileName.$environment.config" ))
						{
							throw "File $environmentPath\$configFileName.$environment.config does not exist, please follow the convention. http://lholman.github.io/OneBuild/conventions.html"
						}
						Transform-ConfigFile -projectBasePath "$projectBasePath" -environment $environment -configFileName $configFileName -localName $server

					}
				}
				catch [Exception] {
					throw "An unexpected error occurred in Transform-ConfigFile.ps1, with error message: `r`n $_"
				}
				finally {
				
					Remove-Module Transform-ConfigFile
					Write-Verbose "END: New-ConfigTransformsForProject"
				}
		}
Export-ModuleMember -Function New-ConfigTransformsForProject
}
