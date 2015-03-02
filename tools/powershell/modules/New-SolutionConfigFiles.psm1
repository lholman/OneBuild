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
			$script:processGrandchildFolders = $false
		}	
	Process {
				Try {
						$basePath = Confirm-Path -path $path
						
						if (Test-Path "$basePath\_transformedConfig") {
							Write-Verbose "New-SolutionConfigFiles: Deleting existing parent '_transformedConfig folder and contents."
							Remove-Item "$basePath\_transformedConfig" -Recurse -Force
						}
						
				 		$projectConfigFolders = Get-ProjectConfigFolders -path $basePath

						if ($projectConfigFolders -eq $null)
						{
							Write-Warning "No configuration '_config' folders found, exiting without configuration  transformation."
							return
						}						
						
						$numberOfConfigPaths = $projectConfigFolders.Count 
						Write-Verbose "New-SolutionConfigFiles: Found $numberOfConfigPaths _config path(s)."
						
						ForEach ($projectConfigFolder in $projectConfigFolders)
						{
							New-TransformedConfigForProjectConfigFolder -path $projectConfigFolder							
						}
						
						if (Test-Path "$basePath\_transformedConfig\temp") {
							Write-Verbose "New-SolutionConfigFiles: Deleting existing temporary  '_transformedConfig\temp folder and contents."
							Remove-Item "$basePath\_transformedConfig\temp" -Recurse -Force
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

function Get-ProjectConfigFolders {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	#Convention: Get the full path to all _config folders under the supplied path. 
	return Get-ChildItem $path -recurse | Where-Object {$_.Name -eq '_config'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName}
}

function New-TransformedConfigForProjectConfigFolder {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	
	Write-Verbose "New-SolutionConfigFiles: Processing config transformations for $path."	
	$baseConfigPath = Get-BaseConfigFileForProjectConfigFolder -path $path
	
	$childTransformPaths = Get-ChildTransformPathsForProjectConfigFolder -path (Split-Path $baseConfigPath -Parent)
	if (-not($script:processGrandchildFolders))
	{
		return New-TransformChildTransformFoldersOnly -childTransformPaths $childTransformPaths
	}
	
	return New-TransformChildAndGrandchildTransformFolders -childTransformPaths $childTransformPaths
}

function New-TransformChildTransformFoldersOnly {
	Param(			
			[Parameter(Mandatory = $False )]
				[array]$childTransformPaths			
		)	

		ForEach($childTransformPath in $childTransformPaths){
			
			$outputTransformPath = $null
			$outputTransformPath = Set-TransformOutputPath -baseConfigPath $baseConfigPath -childTransformPath $childTransformPath

			Invoke-ConfigTransformation -sourceFile $baseConfigPath -transformFile $childTransformPath -outputFile $outputTransformPath
		}	
		return		
}

function New-TransformChildAndGrandchildTransformFolders {
	Param(			
			[Parameter(Mandatory = $False )]
				[array]$childTransformPaths			
		)	
		
		ForEach($childTransformPath in $childTransformPaths){
			
			$tempOutputTransformPath = $null
			$tempOutputTransformPath = Set-TransformOutputPath -baseConfigPath $baseConfigPath -childTransformPath $childTransformPath -useTempOutputPath $true

			Invoke-ConfigTransformation -sourceFile $baseConfigPath -transformFile $childTransformPath -outputFile $tempOutputTransformPath
			
			#Transform for each 'grandchild transform' file
			$childTransformFolder = (Get-Item $childTransformPath).DirectoryName
			$grandChildTransformFolders = Get-ChildItem $childTransformFolder | Where {$_.PSIsContainer -eq $true} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object

			ForEach ($grandChildTransformFolder in $grandChildTransformFolders) {
			
				$grandChildTransformPath = Get-ChildItem $grandChildTransformFolder | Where-Object {$_.Extension -eq '.xslt'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 

				$outputTransformPath = Set-TransformOutputPath -baseConfigPath $baseConfigPath -childTransformPath $grandChildTransformPath
				
				Invoke-ConfigTransformation -sourceFile $tempOutputTransformPath -transformFile $grandChildTransformPath -outputFile $outputTransformPath
			}
		}	
		return
}

function Set-TransformOutputPath {
	Param(			
			[Parameter(Mandatory = $True )]
				[string]$baseConfigPath,
			[Parameter(Mandatory = $True )]
				[string]$childTransformPath,
			[Parameter(Mandatory = $False )]
				[bool]$useTempOutputPath = $false				
	
		)	
		$transformedConfigFolder = "$basePath\_transformedConfig"
		if ($useTempOutputPath) {
			$transformedConfigFolder = Join-Path -path $transformedConfigFolder -childpath "temp"
			Write-Verbose "New-SolutionConfigFiles: Using temporary transformed output folder: $transformedConfigFolder"	
		}
				
		If (-not(Test-Path $transformedConfigFolder)) {
			New-Item -Path $transformedConfigFolder -Force -ItemType Directory | Out-Null
			Write-Verbose "New-SolutionConfigFiles: Created parent transform output folder: $transformedConfigFolder"
		}

		$outputFileName = (Get-Item $baseConfigPath).Name
		$outputFileParentFolder = (Get-Item $childTransformPath).DirectoryName
		$outputFileFolderParts = $outputFileParentFolder -Split "_config"
		
		$outputFolderFirstPart = Join-Path -path $transformedConfigFolder -childpath (Split-Path $outputFileFolderParts[0] -leaf)
		$outputFolder = Join-Path -path $outputFolderFirstPart -childpath $outputFileFolderParts[1]
		If (-not(Test-Path $outputFolder)) {
			New-Item -Path $outputFolder -Force -ItemType Directory | Out-Null
			Write-Verbose "New-SolutionConfigFiles: Created transform output folder: $outputFolder"
		}
		
		$output = Join-Path -path $outputFolder -childpath $outputFileName
		return $output
}

function Get-BaseConfigFileForProjectConfigFolder {
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

function Get-ChildTransformPathsForProjectConfigFolder {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[string]$path			
		)	

	$childTransformFolders = Get-ChildItem $path | Where {$_.PSIsContainer -eq $true} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object

	if (-not([bool]$childTransformFolders)) #Check IsNullOrEmpty
	{
		throw "No 'child transform' folders found under 'application' folder: $path, please add a new 'child transform' folder and transform file."
	}	
	
	$allChildFoldersHaveTransformFiles = $false
	$grandChildTransformFolderCount = 0
	$childTransformFolderCount = $childTransformFolders.Count
	$childTransformPaths = @()
	ForEach ($childTransformFolder in $childTransformFolders)
	{
		$childTransformPath = Get-ChildItem $childTransformFolder | Where-Object {$_.Extension -eq '.xslt'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 

		if (-not([bool]$childTransformPath)) #Check IsNullOrEmpty
		{
			throw "No child transform file found under 'child transform' folder: $childTransformFolder, please remove the 'child transform' folder or add a new 'child transform' file."
		}
		$childTransformPaths += $childTransformPath
	}
	$script:processGrandchildFolders = Confirm-GrandchildTransformFoldersExist -childTransformFolders $childTransformFolders
	
	return $childTransformPaths
}

function Confirm-GrandchildTransformFoldersExist {
	Param(			
			[Parameter(
				Mandatory = $False )]
				[array]$childTransformFolders			
		)	
		
		$grandChildTransformFoldersCount = 0
		$childTransformFolderCount = $childTransformFolders.Count
		ForEach ($childTransformFolder in $childTransformFolders)
		{
			#Check for 'grandchild transform' folders.
			$grandChildTransformFolders = Get-ChildItem $childTransformFolder | Where {$_.PSIsContainer -eq $true} | Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object

			if ([bool]$grandChildTransformFolders) #Check IsNullOrEmpty
			{	
				$grandChildTransformFoldersCount += $grandChildTransformFolders.Count
			}
			
			ForEach ($grandChildTransformFolder in $grandChildTransformFolders) {
			
				$grandChildTransformPath = Get-ChildItem $grandChildTransformFolder | Where-Object {$_.Extension -eq '.xslt'} |Sort-Object $_.FullName -Descending | foreach {$_.FullName} | Select-Object -First 1 

				if (-not([bool]$grandChildTransformPath)) #Check IsNullOrEmpty
				{
					
					throw "No 'grandchild transform' file found under 'grandchild transform' folder: $grandChildTransformFolder. All 'grandchild transform' folders must contain a 'grandchild transform' file. Please remove all 'grandchild transform' folders or add a new 'grandchild transform' file to the 'grandchild transform' folder: $grandChildTransformFolder."
				}
			}
		}

		if ($grandChildTransformFoldersCount -eq 0) {
			Write-Verbose "New-SolutionConfigFiles: No 'grandchild transform' folders found, continuing with 'child transform' only."
			return $false
		}
		
		if (($grandChildTransformFoldersCount -gt 0) -and ($grandChildTransformFoldersCount -lt $childTransformFolderCount)) {
			
			$childTransformFoldersWithoutGrandchildFoldersCount = $childTransformFolderCount - $grandChildTransformFoldersCount
			
			throw "The 'project config' folder: $path contains $grandChildTransformFoldersCount 'child transform' folders with 'grandchild transform' folders and $childTransformFoldersWithoutGrandchildFoldersCount without 'grandchild transform' folders. Either add or remove 'grandchild transform' folders with corresponding 'grandchild transform' files to make the 'project config' folder structure consistent."

		}
		
	return $true
}

function Invoke-ConfigTransformation {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$sourceFile,	
		[Parameter(Mandatory = $True )]
			[string]$transformFile,
		[Parameter(Mandatory = $True,
					HelpMessage="Please supply a full path")]
			[ValidateNotNullOrEmpty()] 
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