@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "REPOSPEC=%~1"
set "BRANCH=%~2"

if not defined REPOSPEC (
    set /p "REPOSPEC=GitHub-Repo (owner/repo) oder Commit-URL: "
)

if not defined REPOSPEC goto :usage

for /f "usebackq tokens=1,* delims==" %%A in (`powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $inputSpec='%REPOSPEC%'; if([string]::IsNullOrWhiteSpace($inputSpec)){ exit 2 }; if($inputSpec -match '^https?://'){ $u=[uri]$inputSpec; $parts=$u.AbsolutePath.Trim('/').Split('/'); if($u.Host -ne 'github.com' -or $parts.Length -lt 4 -or $parts[2] -ne 'commit'){ exit 3 }; $owner=$parts[0]; $repo=$parts[1]; $sha=$parts[3]; if($sha.EndsWith('.patch')){ $sha=$sha.Substring(0, $sha.Length-6) }; Write-Output ('MODE=commit'); Write-Output ('OWNER=' + $owner); Write-Output ('REPO=' + $repo); Write-Output ('SHA=' + $sha) } else { $parts=$inputSpec.Split('/'); if($parts.Length -lt 2){ exit 4 }; Write-Output ('MODE=latest'); Write-Output ('OWNER=' + $parts[0]); Write-Output ('REPO=' + $parts[1]) }"`) do set "%%A=%%B"

if not defined OWNER goto :invalidrepo
if not defined REPO goto :invalidrepo

if not defined BRANCH set "BRANCH=main"
set "OUTDIR=%CD%\%REPO%-patch\%REPO%"

if not exist "%OUTDIR%" (
    mkdir "%OUTDIR%" >nul 2>&1
    if errorlevel 1 (
        echo Fehler: Zielordner konnte nicht erstellt werden: "%OUTDIR%"
        exit /b 1
    )
)

set "SAFE_BRANCH=%BRANCH:/=-%"

if /i "%MODE%"=="latest" (
    echo Ermittle neuesten Commit von %OWNER%/%REPO% auf Branch "%BRANCH%" ...
    for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $api='https://api.github.com/repos/%OWNER%/%REPO%/commits/%BRANCH%'; (Invoke-RestMethod -Uri $api -Headers @{ 'User-Agent'='github-commit2patch-bat' }).sha"`) do set "SHA=%%I"
) else (
    echo Nutze Commit aus URL: %SHA%
)

if not defined SHA (
    echo Fehler: Commit SHA konnte nicht ermittelt werden.
    echo Tipp: Pruefe owner/repo, Branch oder Commit-URL.
    exit /b 1
)

set "SHORTSHA=%SHA:~0,12%"
if /i "%MODE%"=="latest" (
    set "PATCHFILE=%OUTDIR%\%REPO%-%SAFE_BRANCH%-%SHORTSHA%.patch"
) else (
    set "PATCHFILE=%OUTDIR%\%REPO%-commit-%SHORTSHA%.patch"
)

echo Lade Patch herunter ...
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $url='https://github.com/%OWNER%/%REPO%/commit/%SHA%.patch'; Invoke-WebRequest -Uri $url -OutFile '%PATCHFILE%' -Headers @{ 'User-Agent'='github-commit2patch-bat' }"
if errorlevel 1 (
    echo Fehler: Patch konnte nicht heruntergeladen werden.
    exit /b 1
)

echo Fertig: "%PATCHFILE%"
exit /b 0

:invalidrepo
echo Fehler: Ungueltiges Repo-Format.
echo Bitte owner/repo oder eine GitHub Commit-URL angeben,
echo z.B. meetecho/janus-gateway oder https://github.com/owner/repo/commit/SHA
exit /b 1

:usage
echo Verwendung:
echo   %~nx0 [owner/repo ^| commit-url] [branch]
echo.
echo Beispiele:
echo   %~nx0 meetecho/janus-gateway
echo   %~nx0 meetecho/janus-gateway master
echo   %~nx0 https://github.com/ManfredAabye/janus-gateway/commit/3d933d01d2ccb2429f9a6e71502e5a65657042d7
exit /b 1
