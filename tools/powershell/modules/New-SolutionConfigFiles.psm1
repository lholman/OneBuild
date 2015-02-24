function New-SolutionConfigFiles{
<#
 
.SYNOPSIS
    Identifies all _config paths under the given solution path.
.DESCRIPTION
    Identifies all _config paths under the given solution path
.PARAMETER path
	Optional. The full path to the Visual Studio Solution parent folder to look for _config folders in.  Defaults to the calling scripts path.	
.EXAMPLE 
	Import-Module New-SolutionConfigFiles
	Import the module
.EXAMPLE	
	Get-Command -Module New-SolutionConfigFiles
	List available functions
.EXAMPLE
	New-SolutionConfigFiles -basePath AssemblyInfo.cs
	Execute the module
#>
	[cmdletbinding()]
		Param(
			[Parameter(Mandatory = $False)]
				[string]
				$path					
			)
	Begin {
			$DebugPreference = "Continue"
			if (-not $PSBoundParameters.ContainsKey('Verbose'))
			{
				$VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
			}
		}	
	Process {
				Try {
						$basePath = Confirm-Path -path $path

				 		$configPaths = Get-ChildConfigFolders -path $basePath

						if ($configPaths -eq $null)
						{
							Write-Warning "No configuration '_config' folders found, exiting without configuration  transformation."
							return
						}						
						
						$numberOfConfigPaths = $configPaths.Count 
						Write-Verbose "New-SolutionConfigFiles: Found $numberOfConfigPaths _config path(s)."
						
						ForEach ($configPath in $configPaths)
						{
							New-ConfigTransformsForConfigPath -path $configPath							
						}
					
				} catch [Exception] {
					throw "An error occurred generating config files under path: $basePath. `r`n $_"
				}
				
			}
}

function Confirm-Path {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	Import-Module "$PSScriptRoot\Get-Path.psm1"
	Try {
		$path = Get-Path -path $path
		return $path
	}
	Catch {
		throw $_
	}
	Finally {
		Remove-Module Get-Path
	}
}

function Get-ChildConfigFolders {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	#Convention: Get the full path to all _config folders under the supplied path. 
	return Get-ChildItem $path -recurse | Where-Object {$_.Name -eq '_config'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName}
}

function New-ConfigTransformsForConfigPath {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	Write-Verbose "New-SolutionConfigFiles: Processing config transformations for $path."	
	$baseConfigPath = Get-BaseConfigFileForConfigPath -path $path
	
	$childTransformPaths = Get-ChildTransformPathsForConfigPath -path (Split-Path $baseConfigPath -Parent)

	ForEach($childTransformPath in $childTransformPaths){
		
		$outputTransformPath = Set-OutputPathFromBaselineConfigAndTransformPaths -baseConfigPath $baseConfigPath -childTransformPath $childTransformPath

		Invoke-ConfigTransformation -sourceFile $baseConfigPath -transformFile $childTransformPath -outputFile $outputTransformPath
	}
		
}

function Set-OutputPathFromBaselineConfigAndTransformPaths {
	Param(			
			[Parameter(Mandatory = $True )]
				[string]$baseConfigPath,
			[Parameter(Mandatory = $True )]
				[string]$childTransformPath							
		)	
		
		$transformedConfigFolder = "$basePath\_transformedConfig"
		If (-not(Test-Path $transformedConfigFolder)) {
			New-Item -Path $transformedConfigFolder -Force -ItemType Directory
			Write-Verbose "New-SolutionConfigFiles: Created transform output folder: $basePath\_transformedConfig"
		}

		$outputFileName = (Get-Item $baseConfigPath).Name
		$outputFolder = (Get-Item $childTransformPath).DirectoryName
		
		$outputFileFolderParts = $outputFolder -Split "_config"
		
		$outputFolder = Join-Path -path $transformedConfigFolder -childpath (Split-Path $outputFileFolderParts[0] -leaf)
		$outputFolder = Join-Path -path $outputFolder -childpath $outputFileFolderParts[1]
		
		If (-not(Test-Path $outputFolder)) {
			New-Item -Path $outputFolder -Force -ItemType Directory
			$outputFolder = (Resolve-Path $outputFolder)
			Write-Verbose "New-SolutionConfigFiles: Created transform output folder: $outputFolder"
		}
		return Join-Path -path $outputFolder -childpath $outputFileName
}

function Get-BaseConfigFileForConfigPath {
	Param(			
			[Parameter(Mandatory = $False )]
				[string]$path			
		)	
	
	if (-not(Test-Path "$path\application"))
	{
		throw "No 'application' folder found under path: $path, please remove the _config folder or add a child 'application' folder."
	}
	
	#Convention: Get the first .config file we find (ordered alphabetically) in the application folder. 
	$baseConfigPath = Get-ChildItem "$path\application" | Where-Object {$_.Extension -eq '.config'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1

	if ($baseConfigPath -eq $null)
	{
		throw "No base config file found under path: $path\application, please remove the '_config\application' folder or add a base config file."
	}	
	
	Write-Verbose "New-SolutionConfigFiles: Found base config file: $baseConfigPath"
	return $baseConfigPath
}

function Get-ChildTransformPathsForConfigPath {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	

	$childTransformFolders = Get-ChildItem $path | Where {$_.Attributes -eq 'Directory'} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object

	if (-not([bool]$childTransformFolders)) #Check IsNullOrEmpty
	{
		throw "No 'child transform' folders found under 'application' folder: $path, please add a new 'child transform' folder and transform file."
	}	
	
	$allChildFoldersHaveTransformFiles = $false
	$childTransformPaths = @()
	ForEach ($childTransformFolder in $childTransformFolders)
	{
		$childTransformPath = Get-ChildItem $childTransformFolder | Where-Object {$_.Extension -eq '.xslt'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 

		if (-not([bool]$childTransformPath)) #Check IsNullOrEmpty
		{
			throw "No child transform file found under 'child transform' folder: $childTransformFolder, please remove the 'child transform' folder or add a new 'child transform' file."
		}
		#Check for 'grandchild transform' folders.
		$grandChildTransformFolder = Get-ChildItem $childTransformFolder -attributes D | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1
		
		if ([bool]$grandChildTransformFolder) #Check IsNullOrEmpty
		{
			throw "A 'grandchild transform' folder: $grandChildTransformFolder was found under 'child transform' folder: $childTransformFolder, please remove any 'grandchild transform' folders."
		}
		$childTransformPaths += $childTransformPath
	}
	return $childTransformPaths
}

function Invoke-ConfigTransformation {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$sourceFile,	
		[Parameter(Mandatory = $True )]
			[string]$transformFile,
		[Parameter(Mandatory = $True )]
			[string]$outputFile			
	)
	
	Import-Module "$PSScriptRoot\New-TransformedConfigFile.psm1"
	Try {
		New-TransformedConfigFile -sourceFile $sourceFile -transformFile $transformFile -outputFile $outputFile
	}
	Catch {
		throw $_
	}
	Finally {
		Remove-Module New-TransformedConfigFile
	}

}

Export-ModuleMember -Function New-SolutionConfigFiles
