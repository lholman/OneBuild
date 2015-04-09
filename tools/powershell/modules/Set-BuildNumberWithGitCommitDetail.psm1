function Set-BuildNumberWithGitCommitDetail{
<#
 
.SYNOPSIS
    A powershell module that sets the full build number ([major].[minor].[buildCounter].[revision]) in a consistent way for all, returning the AssemblyInformationalVersion to the calling process.
.DESCRIPTION
    A powershell module that sets the full build number ([major].[minor].[buildCounter].[revision]) in a consistent way for all applications, , returning the AssemblyInformationalVersion to the calling process.
	Determinses revision (commit) and branch information from Git, enumerates and updates all AssemblyInfo.cs files with the defined build number.  
	We purposefully only use TeamCity (or any other CI server) to generate the incrementing [buildCounter] part of the number.
.NOTES
	Requirements: Copy this module to any location found in $env:PSModulePath
.PARAMETER major
	Optional. The major part of the desired build number {major}.{minor}.{buildCounter}.{revision}. Defaults to 1.
.PARAMETER minor
	Optional. The minor part of the desired build number {major}.{minor}.{buildCounter}.{revision}. Defaults to 0.
.PARAMETER buildCounter
	Optional. The buildCounter part of the desired build number {major}.{minor}.{buildCounter}.{revision}.  This is usually supplied by your CI tool of choice. Defaults to 0.
.PARAMETER gitRepoPath
	Optional. The full local path to the Git repo. Defaults to the calling scripts path (using Resolve-Path .)
.PARAMETER gitPath
	Optional. For those of you who only install the portable versions of Git with the likes of 'Github for Windows' and 'Bitbucket SourceTree' then provide the full path to 'git.exe' or add the path to the PATH environment variable and use the default.  Defaults to 'git.exe', assuming the path to git.exe is in the PATH environment variable.
.PARAMETER sendTeamCityServiceMessage
	Optional. Instructs the module to send a TeamCity formatted service message containing the buildNumber, forcing TeamCity to use the generated buildNumber.  Defaults to $true
.EXAMPLE 
	Import-Module Set-BuildNumberWithGitCommitDetail
	Import the module
.EXAMPLE	
	Get-Command -Module Set-BuildNumberWithGitCommitDetail
	List available functions
.EXAMPLE
	Set-BuildNumberWithGitCommitDetail -major 2 -minor 4 -buildCounter 45678
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
				[string]$gitRepoPath,				
			[Parameter(
				Position = 4,
				Mandatory = $False )]
				[string]$gitPath = "",	
			[Parameter(
				Position = 5,
				Mandatory = $False )]
				[string]$sendTeamCityServiceMessage = $true					
			)
	Begin {
			$DebugPreference = "Continue"
		}	
	Process {
				
				if ($gitRepoPath -eq "")
				{
					$gitRepoPath = Resolve-Path .
					Write-Verbose "Setting Git repository path to the calling scripts path (using Resolve-Path .): $gitRepoPath"
				}
				
				$gitPath = Set-GitPath -gitPath $gitPath
				Test-Git -gitPath $gitPath			
				
				#Set sensible defaults for revision and branchName in case we can't determine them
				$revision = "0"
				$branchName = "unknown"
				$revision = Set-Revision -gitPath $gitPath
				
				Try	{		
						#Gets the latest Git commit identifier to use within the assembly informational version
						$gitCommitIdentifier = & $gitPath rev-parse --verify --short HEAD
						Write-Verbose "GitCommitIdentifier is: $gitCommitIdentifier"
						
						#Gets the current git branch name, if unable to then use "unknown"
						$branchName = & $gitPath rev-parse --symbolic-full-name --abbrev-ref HEAD
						Write-Verbose "BranchName is: $branchName"
					}
				Catch [System.Exception]
				{
					throw "Error performing Git operations using Git path: $gitPath and repository: $gitRepoPath `r`n $_.Exception.ToString()"
				}

				#We always set AssemblyVersion to the Major and Minor build numbers only, so as to reduce headaches with referencing assemblies. 
				#See http://stackoverflow.com/questions/64602/what-are-differences-between-assemblyversion-assemblyfileversion-and-assemblyin for more details	
				$assemblyVersion = [string]::Format("{0}.{1}.{2}.{3}", $major, $minor, "0", "0") #AssemblyVersion
				$assemblyFileVersion = [string]::Format("{0}.{1}.{2}.{3}", $major, $minor, $buildCounter, $revision) #AssemblyFileVersion
				$assemblyInformationalVersion = [string]::Format("{0}.{1}.{2}.{3} ({4} {5})", $major, $minor, $buildCounter, $revision, $branchName.ToLower(), $gitCommitIdentifier.ToLower()) #AssemblyInformationalVersion
				
				$newAssemblyVersion = 'AssemblyVersion("' + $assemblyVersion + '")'
				$newAssemblyFileVersion = 'AssemblyFileVersion("' + $assemblyFileVersion + '")'
				$newAssemblyInformationalVersion = 'AssemblyInformationalVersion("' + $($assemblyInformationalVersion.ToLower()) + '")'	
				
				Write-Verbose "Assembly versioning set as follows.."
				Write-Verbose "$newAssemblyVersion"
				Write-Verbose "$newAssemblyFileVersion"
				Write-Verbose "$newAssemblyInformationalVersion"

				#Enumerate through all AssemblyInfo.cs files, updating the AssemblyVersion, AssemblyFileVersion and AssemblyInformationalVersion accordingly, 
				#this is subsequently reverted within Invoke-CompileSolution once the compilation is complete.
				$assemblyInfoFiles = Get-ChildItem $gitRepoPath -recurse -include AssemblyInfo.cs,AssemblyInfo.vb
				ForEach ($assemblyInfoFile in $assemblyInfoFiles)
				{
					Try	{
						Write-Verbose "Updating $assemblyInfoFile with build number"
						(Get-Content $assemblyInfoFile -encoding utf8) | 
						%{ $_ -replace 'AssemblyVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyVersion }  | 
						%{ $_ -replace 'AssemblyFileVersion\("[0-9]+(\.([0-9]+|\*)){1,3}"\)', $newAssemblyFileVersion } | 
						%{ $_ -replace 'AssemblyInformationalVersion\("[0-9]+(\.([0-9]+|\*)){1,3}(( )(\(?)*[a-z0-9]*(\)?))?"\)', $newAssemblyInformationalVersion } | Set-Content $assemblyInfoFile -force -encoding utf8
					}
					Catch [System.Exception]
					{
						#Get the script path, rather than the executing path
						$Invocation = (Get-Variable MyInvocation -Scope 1).Value
						$basePath = Split-Path $Invocation.MyCommand.Path
						
						Write-Verbose "Undoing AssemblyInfo.cs file changes"
						Import-Module "$basePath\Undo-GitFileModifications.psm1"
						Undo-GitFileModifications -fileName AssemblyInfo.cs
						Remove-Module Undo-GitFileModifications
						
						throw "Error reading from/writing to file: $assemblyInfoFile, undoing local changes to all AssemblyInfo.cs file(s) `r`n $_.Exception.ToString()"
					}
				}
				
				if ($sendTeamCityServiceMessage -eq $true)
				{
					#Forces TeamCity to use a specific buildNumber (substituting in its build counter as we only use {0} in the TeamCity build number format
					#See http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-ReportingBuildNumber 
					#and http://youtrack.jetbrains.com/issue/TW-18455 for more details.
					Write-Host "##teamcity[buildNumber '$major.$minor.$buildCounter.$revision']" 
				}
				
		}
		End {
			return $assemblyInformationalVersion
		}
}

function Set-Revision {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$gitPath			
	)

	$gitLog = Get-GitLog -gitPath $gitPath
	if ($gitLog -eq "fatal: bad default revision 'HEAD'")
	{
		throw "Unable to determine revision number as no commits have been made to this Git repository, (use ""git add"" and ""git commit"") and try again."
	}
	
	#Gets a count of the commits to HEAD, this should give us an incrementing counter much like a revision number in more "classic" non-distributed source control systems 
	& $gitPath rev-list --count HEAD
	Write-Verbose "Setting revision number to: $revision"

}

function Set-GitPath {
	Param(			
		[Parameter(Mandatory = $False )]
			[string]$gitPath			
	)
	
	if ($gitPath -eq "")
	{
		$environmentPath = Get-EnvironmentPath
		if ($environmentPath -notlike "*git*")
		{
			throw "Unable to find Git defined within the Windows path environment variable. Either check Git is both installed and included in the Windows path environment (system) variable or provide the full path to 'git.exe' using the '$gitPath' variable and try again." 
		}
		$gitPath = "git.exe"
		Write-Verbose "Assuming (default) Git.exe is included in the Windows path environment variable: $gitPath"
		return $gitPath
	}
	else
	{
		if (Test-Path $path) 
		{
			return $gitPath
		}
		Write-Verbose "Git path set as: $gitPath"
	}					
	throw "Supplied path: $path does not exist"

}

function Test-Git {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$gitPath			
	)

	$gitStatus = Get-GitStatus -gitPath $gitPath
	if ($gitStatus -like "*Not a git repository*")
	{
		throw "The current path is not a git repository, try using (git init)"
	}
	
	return
}

function Get-GitLog {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$gitPath			
	)
	
	return & $gitpath log
}

function Get-GitStatus {
	Param(			
		[Parameter(Mandatory = $True )]
			[string]$gitPath			
	)
	
	return & $gitpath status
}

function Get-EnvironmentPath {
	
	return "$($env:Path)"

}

Export-ModuleMember -Function Set-BuildNumberWithGitCommitDetail