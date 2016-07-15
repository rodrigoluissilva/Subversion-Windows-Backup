@ECHO OFF
::
:: Dump the changes from Subversion to a directory
::
:: Author: Rodrigo Luis Silva
::

:: Set the username and password to access you repository
SET SVNUSER=backup
SET SVNPASS=randompassword

:: Change to your repository directory
SET SVNREPODIR=C:\SVNRepositories\repo1

:: change to your repoditory URL
SET SVNREPOURL=svn://localhost/repo1

:: change to the destination directory
CD C:\SVNBackup\repo1\

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Prepare the Command Processor
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

:: Set variables
SET PATH=C:\Program Files\Subversion\bin;%PATH%
SET SVN=svn log --xml %SVNREPOURL% --non-interactive --no-auth-cache --username %SVNUSER% --password %SVNPASS%

:: create files
echo.>tmpBackupList.txt
echo.>tmpSVNRevisionsList.txt
echo.>tmpFindResult.txt

:: check existent backups
for /r %%x in (svndump-r*.dump) do echo "%%x" >> tmpBackupList.txt

:: Check revisions
for /f "tokens=2 delims==" %%A in (' "%SVN% | find "revision" " ') do (
    set "line=%%A"
    call set "line=echo.%%line:~1,-2%%"
    for /f "delims=" %%X in ('"echo."%%line%%""') do (
        %%~X >> tmpSVNRevisionsList.txt
    )
)

:: Compare list of revisions with the list of backups
for /f %%B in ('" type tmpSVNRevisionsList.txt | sort /+123456 "') do (
    findstr /c:"svndump-r%%B.dump" tmpBackupList.txt > tmpFindResult.txt
    IF NOT ERRORLEVEL 1 ( 
        rem echo Revision %%B Found.
    ) else (
        rem echo Revision %%B Not Found, doing a backup
        svnadmin dump %SVNREPODIR% --incremental --revision %%B > svndump-r%%B.dump
    )
)

:: Housekeeping
del tmpBackupList.txt
del tmpSVNRevisionsList.txt
del tmpFindResult.txt