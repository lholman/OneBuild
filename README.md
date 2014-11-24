#OneBuild#

OneBuild is a modular set of convention based .NET solution build scripts written in PowerShell, relying on Invoke-Build for task automation. See https://github.com/lholman/OneBuild for more details.

[![Build status](https://ci.appveyor.com/api/projects/status/8pplvimhcbrdev0l/branch/master?svg=true)](https://ci.appveyor.com/project/lholman/onebuild/branch/master)

##Building with OneBuild##
OneBuild is shipped as a solution NuGet package, use it to build your solution by importing the NuGet package..

```Import-Module OneBuild```

<TODO: A few notes about managing solution level NuGet packages.>
<TODO: A few notes about Execution policies> 

Then simply run.. 

```
C:\>cd "Path to your solution"
C:\Path to your solution\>Build.bat
``` 

NuGet installs OneBuild and its dependencies in your $SolutionDir\Packages folder, copying the `Build.bat` bootstrap script to the root of the $SolutionDir

##How OneBuild works##
OneBuild is a modular set of .NET solution build scripts written in PowerShell. Following the proven Deployment Pipeline approach to software build and delivery OneBuild makes the Commit phase (versioning, compilation, unit testing and packaging of binaries) of a Deployment Pipeline a repeatable, deterministic and simple exercise. Being convention based and therefore requiring no configuration allows OneBuild to build any target .NET solution out of the box, assuming the solution follows some basic convention patterns. OneBuild is proud to rely on [Invoke-Build](https://github.com/nightroman/Invoke-Build) for task automation.

##Convention patterns##
* The OneBuild `Build.bat` bootstrap script must sit alongside the Visual Studio solution file(s) you intend to build. 
* To be executed with NUnit, NUnit test assemblies *must* 
	* Contain "nunit" (case-insensitive) in their assembly names. 
	* Be output into a common output folder named \bin, regardless of VS build configuration. <TODO: Guide on setting common output paths for all VS build configurations> 

##Early assumptions
* You use Git for version control (TFS support coming soon)
* The 3 part [Semantic Versioning](SemVer.org) style is used for all NuGet package versioning. For Git repos a global commit count (4th part) and the short commit Id (informational text) are added to the assembly versions. 
* You use NUnit for unit testing (Support for MSTest never coming ;), but other OSS test frameworks for sure.)
* You want to use NuGet for packaging up your assemblies

##Why OneBuild?##
There are a number of benefits of having a build process that can be run in its entirety on a local (developers) machine.

* **Fail earlier**. Catch more failed builds earlier on by changing fewer variables, i.e. don’t compile and build in a completely different way on your Continuous Integration (CI) server than your developers do on their development machines. 
* **Own a debuggable build process**. Building software is tricky, let me (or anyone) debug that process locally, so we don’t have to constantly break the CI builds to see things fail. 
* **Make the build process a first class citizen**. Yes, let’s put the build process under version control and treat it as code, I care about changes and versions… A LOT. Not to mention I want an easy way to clone that build process in to as many application branches as I want, without fudging configuration.
* **Improve quality**. If we treat the build process as code then we can also test it as part of its own pipeline: See our [Pester](https://github.com/nightroman/Invoke-Build) [unit tests here](https://github.com/lholman/OneBuild/tree/master/tests)   
* **Decouple yourself from the CI server vendor**. I love [TeamCity](http://jetbrains.com/teamcity), have a long running tempestuous relationship with Team Foundation Server (TFS), have had a few flings with [Jenkins](http://jenkinsci.com) and chatted up the likes of [AppVeyor](http://www.appveyor.com) and various other CI and build server products. The one thing they all have in common is they give you an inch, but allow you to take a mile. It is incredibly easy to use their "simple" out-the-box, add-on tasks, runners and plug-ins, however this means it is almost impossible to move to another CI server technology or run a build in its entirety locally. 


