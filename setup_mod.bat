@echo off
setlocal enabledelayedexpansion

echo RimWorld Mod Setup Script

:: Get user input
set /p modname="Enter Mod Name: "
set /p authorname="Enter Author Name: "
set /p packageid="Enter Package ID: "
set /p namespace="Enter Namespace: "
set /p newfoldername="Enter New Mod Folder Name: "

echo.
echo Creating new folder '%newfoldername%' and copying files...

:: Get the directory of the script
set "scriptDir=%~dp0"
:: Remove trailing backslash if present
if "%scriptDir:~-1%"=="\" set "scriptDir=%scriptDir:~0,-1%"

:: Define the destination directory (the new mod folder) relative to the script's parent directory
set "parentDir=%scriptDir%\.."
set "destDir=!parentDir!\!newfoldername!"

:: Create the new folder
mkdir "%destDir%"
if %errorlevel% neq 0 (
    echo Error creating directory "%destDir%". Exiting.
    exit /b %errorlevel%
)

:: Copy files from sourceDir to destDir, excluding setup_mod.bat and .git folder using robocopy /XF and /XD
echo robocopy "!scriptDir!" "%destDir%" /E /XF setup_mod.bat /XD .git
robocopy "!scriptDir!" "%destDir%" /E /XF setup_mod.bat /XD .git
if %errorlevel% geq 8 (
    echo Error during file copy. Exiting.
    exit /b %errorlevel%
)
echo Files copied to '%newfoldername%'.

echo.
echo Changing directory to '%newfoldername%'...
cd "%destDir%"
if %errorlevel% neq 0 (
    echo Error changing directory to "%destDir%". Exiting.
    exit /b %errorlevel%
)
echo Current directory: %cd%

echo.
echo Updating About.xml in '%newfoldername%'...
:: Use findstr and echo to replace content in About.xml
(for /f "usebackq delims=" %%l in ("About\About.xml") do (
    set "line=%%l"
    :: Check for specific tags and replace content
    if "!line:~1,6!"=="<name>" (
        echo 	^<name^>%modname%^</name^>
    ) else if "!line:~1,8!"=="<author>" (
        echo 	^<author^>%authorname%^</author^>
    ) else if "!line:~1,11!"=="<packageId>" (
        echo 	^<packageId^>%packageid%^</packageId^>
    ) else (
        echo !line!
    )
)) > About\About.xml.tmp
move /y About\About.xml.tmp About\About.xml > nul
if %errorlevel% neq 0 (
    echo Error updating About.xml. Exiting.
    exit /b %errorlevel%
)
echo About.xml updated.

echo.
echo Replacing 'ChangeName' with '%namespace%' in Source folder within '%newfoldername%'...

:: Find the Source directory within the new folder
set "sourceSubDir="
for /f "delims=" %%i in ('dir /s /b *.sln') do set "sourceSubDir=%%~dpi"
if not defined sourceSubDir (
    echo Error: .sln file not found in the new folder. Exiting.
    exit /b 1
)

:: Use findstr and echo to replace content in files within Source folder
for /r "%sourceSubDir%" %%f in (*.cs *.xml *.csproj *.sln) do (
    (for /f "usebackq delims=" %%l in ("%%f") do (
        set "line=%%l"
        set "line=!line:ChangeName=%namespace%!"
        echo !line!
    )) > "%%f.tmp"
    move /y "%%f.tmp" "%%f" > nul
    if %errorlevel% neq 0 (
        echo Error replacing namespace in "%%f". Exiting.
        exit /b %errorlevel%
    )
)
echo Content replacement complete.

echo.
echo Renaming files with 'ChangeName' in filename...
for /r "%sourceSubDir%" %%f in (*ChangeName*.*) do (
    set "filename=%%~nxf"
    set "newfilename=!filename:ChangeName=%namespace%!"
    ren "%%f" "!newfilename!"
    if %errorlevel% neq 0 (
        echo Error renaming file "%%f". Exiting.
        exit /b %errorlevel%
    )
)
echo File renaming complete.

echo.
echo Renaming folders with 'ChangeName' in folder name...
for /d /r "%sourceSubDir%" %%d in (*ChangeName*) do (
    set "foldername=%%~nxd"
    set "newfoldername=!foldername:ChangeName=%namespace%!"
    ren "%%d" "!newfoldername!"
    if %errorlevel% neq 0 (
        echo Error renaming folder "%%d". Exiting.
        exit /b %errorlevel%
    )
)
echo Folder renaming complete.

echo.
echo Replacing 'ModSourceTemplate' with '!namespace!' in tasks.json files...
for /f "delims=" %%f in ('dir /s /b tasks.json') do (
    echo Updating %%f
    (for /f "usebackq delims=" %%l in ("%%f") do (
        set "line=%%l"
        set "line=!line:ModSourceTemplate=%namespace%!"
        echo(!line!
    )) > "%%f.tmp"
    move /y "%%f.tmp" "%%f" > nul
    if %errorlevel% neq 0 (
        echo Error replacing 'ModSourceTemplate' in "%%f". Exiting.
        exit /b %errorlevel%
    )
)
echo tasks.json update complete.

echo.
echo Setup complete.