echo on

rem Temporarily hardcoded:
set TARGET=Visual Studio 2019
set SHORTNAME=vs2019

rem Initialize Visual Studio variables
if "%TARGET%" == "Visual Studio 2017" call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars64.bat"
if "%TARGET%" == "Visual Studio 2019" call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

rem Installing tools
rem only for appveyor:
rem cinst unrar -y
rem cinst unzip -y
rem cinst innosetup -y

rem Installing UnrealIRCd dependencies
cd \projects
mkdir unrealircd-5-libs
cd unrealircd-5-libs
curl -fsS -o unrealircd-libraries-5-devel.zip https://www.unrealircd.org/files/dev/win/libs/unrealircd-libraries-5-devel.zip
unzip unrealircd-libraries-5-devel.zip
copy dlltool.exe \users\user\worker\unreal5-w10\build /y

rem for appveyor: cd \projects\unrealircd
cd \users\user\worker\unreal5-w10\build

rem Now the actual build
call extras\build-tests\windows\compilecmd\%SHORTNAME%.bat

rem The above command will fail, due to missing symbol file
rem However the symbol file can only be generated after the above command
rem So... we create the symbolfile...
nmake -f makefile.windows SYMBOLFILE

rem And we re-run the exact same command:
call extras\build-tests\windows\compilecmd\%SHORTNAME%.bat
if %ERRORLEVEL% NEQ 0 EXIT /B 1

rem Convert c:\dev to c:\projects\unrealircd-5-libs
rem TODO: should use environment variable in innosetup script?
sed -i "s/c:\\dev\\unrealircd-5-libs/c:\\projects\\unrealircd-5-libs/gi" src\windows\unrealinst.iss

rem Build installer file
"c:\Program Files (x86)\Inno Setup 5\iscc.exe" /Q- src\windows\unrealinst.iss
if %ERRORLEVEL% NEQ 0 EXIT /B 1

rem Show some proof
ren mysetup.exe unrealircd-dev-build.exe
dir unrealircd-dev-build.exe
sha256sum unrealircd-dev-build.exe

rem Kill any old instances, just to be sure
taskkill -im unrealircd.exe -f

start /WAIT mysetup /SILENT

rem Upload artifact
rem appveyor PushArtifact unrealircd-dev-build.exe
rem if %ERRORLEVEL% NEQ 0 EXIT /B 1

rem Install 'unrealircd-tests'
cd ..
rd /q/s unrealircd-tests
git clone https://github.com/unrealircd/unrealircd-tests.git
if %ERRORLEVEL% NEQ 0 EXIT /B 1
cd unrealircd-tests
dir

rem Not sure if this works... I think it launches an external window
rem and does not wait.
"C:\Program Files\Git\git-bash.exe" ./runwin
