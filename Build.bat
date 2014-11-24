@echo off
  
powershell -NoProfile -ExecutionPolicy bypass -command ".\packages\invoke-build.2.9.12\tools\Invoke-Build.ps1 Invoke-OneBuildUnitTests .\.build.ps1"
