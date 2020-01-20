

@echo off
if "%OS%" == "Windows_NT" setlocal enableextensions enabledelayedexpansion



rem ---------------------------------------------------------------
rem Check for help command
rem ---------------------------------------------------------------

if /I "%1"=="help" goto showhelp
if /I "%1"=="-?" goto showhelp
if /I "%1"=="-h" goto showhelp
if /I "%1"=="-help" goto showhelp
if /I "%1"=="--help" goto showhelp
if /I "%1"=="/?" goto showhelp
if /I "%1"=="/h" goto showhelp
if /I "%1"=="/help" goto showhelp

goto continue

:showhelp
echo.
echo Usage: atlas-mvn [options]
echo.
echo Execute arbitrary Maven commands using the version of Maven bundled with the Atlassian Plugin SDK.
goto end

:continue

rem ---------------------------------------------------------------
rem Find absolute path to the program
rem ---------------------------------------------------------------

set PRGDIR=%~dp0
set CURRENTDIR=%cd%
cd /d %PRGDIR%..
set ATLAS_HOME=%cd%
cd /d %CURRENTDIR%


rem ---------------------------------------------------------------
rem Identify Maven location relative to script
rem ---------------------------------------------------------------

set M2_HOME=%ATLAS_HOME%\apache-maven-3.5.4
set MAVEN_EXECUTABLE="%M2_HOME%\bin\mvn.cmd"
set ATLAS_VERSION="8.0.16"
set AMPS_PLUGIN_VERSION="8.0.2"

if not "%ATLAS_MVN%"=="" set MAVEN_EXECUTABLE="%ATLAS_MVN%"


rem Check that the target executable exists

if not exist "!MAVEN_EXECUTABLE!" (
	echo Cannot find %MAVEN_EXECUTABLE%
	echo This file is needed to run this program
	goto end
)



rem ---------------------------------------------------------------
rem Transform Parameters into Maven Parameters
rem
rem NOTE: in DOS, all the 'else' statements must be on the same
rem line as the closing bracket for the 'if' statement.
rem ---------------------------------------------------------------

set ARGV=.%*
call :parse_argv
if ERRORLEVEL 1 (
  echo Cannot parse arguments
  endlocal
  exit /B 1
)

set MAVEN_OPTS=-Xmx768M %ATLAS_OPTS%
set MVN_PARAMS=-gs %M2_HOME%/conf/settings.xml

if exist pom.xml (
    echo [INFO] Project POM found
    for /F "delims=*" %%a in ('findstr "<amps.version>" pom.xml') do (set var="%%a")
    for /F "tokens=2 delims=>< " %%a in (!var!) do (set AMPS_PLUGIN_VERSION=%%a)
)


set ARGI = 0

:loopstart
set /a ARGI = !ARGI! + 1
set /a ARGN = !ARGI! + 1

call :getarg !ARGI! ARG
call :getarg !ARGN! ARGNEXT

if !ARGI! gtr %ARGC% (
  goto loopend
) else (
  set MVN_PARAMS=%MVN_PARAMS% %ARG%
  shift
  goto loopstart
)
:loopend

set AMPS_PLUGIN_VERSION_STRIPPED=%AMPS_PLUGIN_VERSION:"=%
set AMPS_PLUGIN_VERSION_STRIPPED=%AMPS_PLUGIN_VERSION_STRIPPED:'=%

if "%AMPS_PLUGIN_VERSION_STRIPPED%" LSS "8" (
    set MVN_PLUGIN=$oldMavenPluginName
)
if "%AMPS_PLUGIN_VERSION_STRIPPED%" GEQ "8" (
    set MVN_PLUGIN=$mavenPluginName
)

set MVN_COMMAND=
call set MVN_COMMAND=%%MVN_COMMAND:${mavenPluginName}=%MVN_PLUGIN%%%

rem ------------------------------------------------------------------------------------
rem Check for conflicts between Amps version and plugin artifact ID in plugin pom file
rem ------------------------------------------------------------------------------------

goto :skipPrintErrors
:printErrors
	echo [ERROR] Invalid Atlassian maven plugin(s) detected: %~1
	echo [ERROR] Please update your plugin POM to use the %~2
	echo [ERROR] See go.atlassian.com/atlassdk-147 for more information
Exit/B 0
:skipPrintErrors

set PLUGIN_AMPS_PLUGIN_VERSION=0
if exist pom.xml (
	set MOJO=mvn
	set MOJO_MATCH=false
	set oldPlugins="<artifactId>maven-bamboo-plugin <artifactId>maven-confluence-plugin <artifactId>maven-crowd-plugin <artifactId>maven-fecru-plugin <artifactId>maven-jira-plugin <artifactId>maven-stash-plugin"
	set newPlugins="<artifactId>bamboo-maven-plugin <artifactId>confluence-maven-plugin <artifactId>crowd-maven-plugin <artifactId>fecru-maven-plugin <artifactId>jira-maven-plugin"
	for /F "delims=*" %%a in ('findstr !newPlugins! pom.xml') do (
		call set var="%%a"
		for /F "tokens=2,3 delims=>< " %%a in (!var!) do (
			if "%%a" EQU "artifactId" ( call set "NEW_PLUGIN_ARTIFACT_ID=%%b;%%NEW_PLUGIN_ARTIFACT_ID%%" )
			if "%%a" NEQ "artifactId" ( call set "NEW_PLUGIN_ARTIFACT_ID=%%a;%%NEW_PLUGIN_ARTIFACT_ID%%" )
		)
	)
	for /F "delims=*" %%a in ('findstr !oldPlugins! pom.xml') do (
		call set var="%%a"
		for /F "tokens=2,3 delims=>< " %%a in (!var!) do (
			if "%%a" EQU "artifactId" ( call set "OLD_PLUGIN_ARTIFACT_ID=%%b;%%OLD_PLUGIN_ARTIFACT_ID%%" )
			if "%%a" NEQ "artifactId" ( call set "OLD_PLUGIN_ARTIFACT_ID=%%a;%%OLD_PLUGIN_ARTIFACT_ID%%" )
		)
	)
	for /F "delims=*" %%a in ('findstr "<amps.version>" pom.xml') do (set var="%%a")
	for /F "tokens=3 delims=><. " %%a in (!var!) do (set PLUGIN_AMPS_PLUGIN_VERSION=%%a)
)

if "%NEW_PLUGIN_ARTIFACT_ID%" NEQ "" ( set "NEW_PLUGIN_ARTIFACT_ID=%NEW_PLUGIN_ARTIFACT_ID:;=&echo.%" )
if "%OLD_PLUGIN_ARTIFACT_ID%" NEQ "" ( set "OLD_PLUGIN_ARTIFACT_ID=%OLD_PLUGIN_ARTIFACT_ID:;=&echo.%" )

if "%MOJO:~0,4%" EQU "run" (
	set MOJO_MATCH=true
)
if "%MOJO:~0,6%" EQU "debug" (
	set MOJO_MATCH=true
)
if "%MOJO:~-13%" EQU "plugin-module" (
	set MOJO_MATCH=true
)

if exist pom.xml if "%MOJO_MATCH%" EQU "true" if %PLUGIN_AMPS_PLUGIN_VERSION% NEQ 0 (
	if %PLUGIN_AMPS_PLUGIN_VERSION% LSS 8 if "%NEW_PLUGIN_ARTIFACT_ID%" NEQ "" (
		call :printErrors "%NEW_PLUGIN_ARTIFACT_ID%" "old maven plugin name(s) for your product, or update to AMPS 8.0.0 or later"
		Exit/B 0
	)
	if %PLUGIN_AMPS_PLUGIN_VERSION% GEQ 8 if "%OLD_PLUGIN_ARTIFACT_ID%" NEQ "" (
		call :printErrors "%OLD_PLUGIN_ARTIFACT_ID%" "updated maven plugin name(s) for your product, or ensure you are using AMPS 6.x"
		Exit/B 0
	)
)

rem ---------------------------------------------------------------
rem Executing Maven
rem ---------------------------------------------------------------

echo Executing: %MAVEN_EXECUTABLE% %MVN_COMMAND% %MVN_PARAMS%
%MAVEN_EXECUTABLE% %MVN_COMMAND% %MVN_PARAMS%

rem ---------------------------------------------------------------
rem (AMPS-197) The batch routines below for correct handling 
rem parameters containing of = and ; are from Skypher's excellent 
rem blog: 
rem http://skypher.com/index.php/2010/08/17/batch-command-line-arguments/
rem ---------------------------------------------------------------

:parse_argv
  SET PARSE_ARGV_ARG=[]
  SET PARSE_ARGV_END=FALSE
  SET PARSE_ARGV_INSIDE_QUOTES=FALSE
  SET /A ARGC = 0
  SET /A PARSE_ARGV_INDEX=1
  :PARSE_ARGV_LOOP
  CALL :PARSE_ARGV_CHAR !PARSE_ARGV_INDEX! "%%ARGV:~!PARSE_ARGV_INDEX!,1%%"
  IF ERRORLEVEL 1 (
    EXIT /B 1
  )
  IF !PARSE_ARGV_END! == TRUE (
    EXIT /B 0
  )
  SET /A PARSE_ARGV_INDEX=!PARSE_ARGV_INDEX! + 1
  GOTO :PARSE_ARGV_LOOP
 
  :PARSE_ARGV_CHAR
    IF ^%~2 == ^" (
      SET PARSE_ARGV_END=FALSE
      SET PARSE_ARGV_ARG=.%PARSE_ARGV_ARG:~1,-1%%~2.
      IF !PARSE_ARGV_INSIDE_QUOTES! == TRUE (
        SET PARSE_ARGV_INSIDE_QUOTES=FALSE
      ) ELSE (
        SET PARSE_ARGV_INSIDE_QUOTES=TRUE
      )
      EXIT /B 0
    )
    IF %2 == "" (
      IF !PARSE_ARGV_INSIDE_QUOTES! == TRUE (
        EXIT /B 1
      )
      SET PARSE_ARGV_END=TRUE
    ) ELSE IF NOT "%~2!PARSE_ARGV_INSIDE_QUOTES!" == " FALSE" (
      SET PARSE_ARGV_ARG=[%PARSE_ARGV_ARG:~1,-1%%~2]
      EXIT /B 0
    )
    IF NOT !PARSE_ARGV_INDEX! == 1 (
      SET /A ARGC = !ARGC! + 1
      SET ARG!ARGC!=%PARSE_ARGV_ARG:~1,-1%
      IF ^%PARSE_ARGV_ARG:~1,1% == ^" (
        SET ARG!ARGC!_=%PARSE_ARGV_ARG:~2,-2%
        SET ARG!ARGC!Q=%PARSE_ARGV_ARG:~1,-1%
      ) ELSE (
        SET ARG!ARGC!_=%PARSE_ARGV_ARG:~1,-1%
        SET ARG!ARGC!Q="%PARSE_ARGV_ARG:~1,-1%"
      )
      SET PARSE_ARGV_ARG=[]
      SET PARSE_ARGV_INSIDE_QUOTES=FALSE
    )
    EXIT /B 0

:getarg
  SET %2=!ARG%1!
  SET %2_=!ARG%1_!
  SET %2Q=!ARG%1Q!
  EXIT /B 0

:getargs
  SET %3=
  FOR /L %%I IN (%1,1,%2) DO (
    IF %%I == %1 (
      SET %3=!ARG%%I!
    ) ELSE (
      SET %3=!%3! !ARG%%I!
    )
  )
  EXIT /B 0


:end



