$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1","")
$baseModulePath = "$here\..\tools\powershell\modules"

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}

Describe "New-SolutionConfigFiles" {

	Context "When there is a [config] folder" {
	
		Import-Module "$baseModulePath\$sut"
		Mock -ModuleName $sut Get-ChildConfigFolders { return "solution.sln"}

		try {
			New-SolutionConfigFiles
		}
		catch {
			throw
		}
		finally {
			Remove-Module $sut
		}
		
		It "Should call Get-ChildConfigFolders to identify all [config] folders under path" {
            Assert-MockCalled Get-ChildConfigFolders -ModuleName $sut -Times 1
        }

	}
	
}

$module = Get-Module $sut
if ($module -ne $null)
{
	Remove-Module $sut
}


