#OneBuild#

OneBuild is a modular set of convention based .NET solution build scripts written in PowerShell, relying on Invoke-Build for task automation. See https://github.com/lholman/OneBuild for more details.

[![Build status](https://ci.appveyor.com/api/projects/status/8pplvimhcbrdev0l/branch/master?svg=true)](https://ci.appveyor.com/project/lholman/onebuild/branch/master)

##Building with OneBuild##
OneBuild is shipped as a solution NuGet package, use it to build your solution by installing the NuGet package..

```PM>Install-Package OneBuild```

<TODO: A few notes about managing solution level NuGet packages.>
<TODO: A few notes about Execution policies> 

Then simply run.. 

```
C:\>cd "Path to your solution"
C:\Path to your solution\>OneBuild.bat
``` 

NuGet installs OneBuild and its dependencies in your $SolutionDir\Packages folder, copying the `OneBuild.bat` bootstrap script to the root of the $SolutionDir

##How OneBuild works##
OneBuild is a modular set of .NET solution build scripts written in PowerShell. Following the proven Deployment Pipeline approach to software build and delivery, OneBuild makes the Commit phase (versioning, compilation, unit testing and packaging of binaries) of a Deployment Pipeline a repeatable, deterministic and simple exercise. Being convention based and therefore requiring no configuration allows OneBuild to build any target .NET solution out of the box, assuming the solution follows some basic convention patterns. OneBuild is proud to rely on [Invoke-Build](https://github.com/nightroman/Invoke-Build) for task automation.

##Options##

Using standard [Powershell and Invoke-Build script parameters](bootstrap) you can pass in values for the following. 

* `-task` - Optional. The name of the Invoke-Build task to execute, defaults to Invoke-Commit.
* `-configuration` - Optional. The .NET build configuration, `Debug` or `Release`, defaults to `Debug`.
* `-buildcounter` - Optional. The incrementing build counter often used within CI servers, generally forming the third part of a four part version number ([major].[minor].[buildCounter].[revision]), defaults to `999`.

##The build pipeline and convention##
Much of the logic within each phase of the build pipeline relies heavily on convention, thus no configuration. Adhere to the following convention and OneBuild should just work.  

###Execution###
* The OneBuild `OneBuild.bat` bootstrap script and Invoke-Build `OneBuild.build.ps1` build script *must* sit alongside the Visual Studio solution file(s) you intend to build. If you install with NuGet these are copied for you when executing `PM> Install-Package Nunit` 

###Invoke-UnitTests###
* To be executed with [NUnit](http://www.nunit.org/), NUnit test assemblies *must* 
	* Contain "nunit" (case-insensitive) in their assembly *and* directory names. 
	* Be output into a common output folder named \bin, regardless of Visual Studio build configuration. 

##Early assumptions
* You use Git for version control (TFS support coming soon)
* The 3 part [Semantic Versioning](SemVer.org) style is used for all NuGet package versioning. For Git repos a global commit count (4th part) and the short commit Id (informational text) are added to the assembly versions. 
* You use NUnit for unit testing (Support for MSTest never coming ;), but other OSS test frameworks for sure.)
* You want to use NuGet for packaging up your assemblies

##Why OneBuild?##
There are a number of benefits of having a build process that can be run in its entirety on a local (developers) machine. [I've written more about this before](http://lloydholman.co.uk/run-the-same-build-process-everywhere/) but here's a summary.

* **Fail earlier**. Catch more failed builds earlier on by changing fewer variables, i.e. don’t compile and build in a completely different way on your Continuous Integration (CI) server than your developers do on their development machines. 
* **Own a debuggable build process**. Building software is tricky, let me (or anyone) debug that process locally, so we don’t have to constantly break the CI builds to see things fail. 
* **Make the build process a first class citizen**. Yes, let’s put the build process under version control and treat it as code, I care about changes and versions… A LOT. Not to mention I want an easy way to clone that build process in to as many application branches as I want, without fudging configuration.
* **Improve quality**. If we treat the build process as code then we can also test it as part of its own pipeline: See our [Pester](https://github.com/nightroman/Invoke-Build) [unit tests here](https://github.com/lholman/OneBuild/tree/master/tests)   
* **Decouple yourself from the CI server vendor**. I love [TeamCity](http://jetbrains.com/teamcity), have a long running tempestuous relationship with Team Foundation Server (TFS), have had a few flings with [Jenkins](http://jenkinsci.com) and chatted up the likes of [AppVeyor](http://www.appveyor.com) and various other CI and build server products. The one thing they all have in common is they give you an inch, but allow you to take a mile. It is incredibly easy to use their "simple" out-the-box, add-on tasks, runners and plug-ins, however this means it is almost impossible to move to another CI server technology or run a build in its entirety locally. 

## Contributing to OneBuld

### Running OneBuild's Unit Tests

OneBuild uses Pester to run all of it's unit tests. These can be invoked by running

```
C:\Path_To_Your_OneBuild_Repository\> OneBuild.bat -task Invoke-OneBuildUnitTests
```

This will run all of the tests in the **.\tests\** folder that Pester can find. This is the same system that the build system will be using when building OneBuild.
