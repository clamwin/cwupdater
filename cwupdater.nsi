; ClamWin NSIS/VPatch updater
;
; Copyright (c) 2008 Gianluigi Tiesi <sherpya@netfarm.it>
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU Library General Public
; License as published by the Free Software Foundation; either
; version 2 of the License, or (at your option) any later version.
;
; This library is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; Library General Public License for more details.
;
; You should have received a copy of the GNU Library General Public
; License along with this software; if not, write to the
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

; VPatch NSIS Plugin: Copyright (C) 2001-2008 Koen van de Sande / Van de Sande Productions
; please look at http://www.tibed.net/vpatch for licensing informations

;!define NOCHECK

SetCompressor /solid lzma
Name "ClamWin Free Antivirus Upgrade"
OutFile "cwupdater.exe"

!packhdr tmp.dat "upx --best tmp.dat"
XPStyle on
SetDateSave on
SetDatablockOptimize on
CRCCheck on
SilentInstall normal
ShowInstDetails show
InstallColors FF8080 000030
Icon "cwupdater.ico"
CompletedText "Done"

!include "MUI2.nsh"
!include "TextFunc.nsh"
!include "WinVer.nsh"

; VPatch macro definition
!macro VPatchFile PATCHDATA SOURCEFILE TEMPFILE
    vpatch::vpatchfile "${PATCHDATA}" "${SOURCEFILE}" "${TEMPFILE}"
    Pop $1
    StrCpy $1 $1 2
    StrCmp $1 "OK" ok_${SOURCEFILE}
    SetErrors
ok_${SOURCEFILE}:
    IfFileExists "${TEMPFILE}" +1 end_${SOURCEFILE}
    Delete "${SOURCEFILE}"
    Rename /REBOOTOK "${TEMPFILE}" "${SOURCEFILE}"
end_${SOURCEFILE}:
!macroend

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis.bmp"
!define MUI_ICON "cwupdater.ico"
!define MUI_ABORTWARNING

!insertmacro MUI_PAGE_LICENSE "License.rtf"
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Function StripEol
    Exch $0
    Push $1
    Push $2
    StrCpy $1 0
loop:
    IntOp $1 $1 + 1
    StrCpy $2 $0 1 $1
    StrCmp $2 $\r found
    StrCmp $2 $\n found
    StrCmp $2 "" end
    Goto loop
found:
    StrCpy $0 $0 $1
end:
    Pop $2
    Pop $1
    Exch $0
FunctionEnd

Function .onInit
        InitPluginsDir
        File /oname=$PLUGINSDIR\splash.bmp splash.bmp
        advsplash::show 1000 600 400 0x04025C $PLUGINSDIR\splash
        Pop $0 
        Delete $PLUGINSDIR\splash.bmp
FunctionEnd

Section "CwUpdater"
    Var /GLOBAL OutLookInstalled
    Var /GLOBAL DESTDIR
    Var /GLOBAL BINDIR
    Var /GLOBAL VERSTR
    Var /GLOBAL VER
    Var /GLOBAL OLDVERDW
    Var /GLOBAL VERDW
    Var /GLOBAL REGUNI

    StrCpy $REGUNI "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClamWin Free Antivirus_is1"

    ; Search for ClamWin installation path
    ClearErrors
    ReadRegStr $BINDIR HKLM Software\ClamWin "Path"
    IfErrors 0 version
    ReadRegStr $BINDIR HKCU Software\ClamWin "Path"
    IfErrors 0 version
    DetailPrint "Cannot find ClamWin Free Antivirus Installation, aborting..."
    Goto abort

version:
    ; Installed Version
    ClearErrors
    ReadRegDWORD $VER HKLM "Software\ClamWin" "Version"
    IfErrors 0 outlook
    ReadRegDWORD $VER HKCU "Software\ClamWin" "Version"
    IfErrors 0 outlook
    DetailPrint "Cannot find ClamWin Free Antivirus Version, aborting..."
    Goto abort

outlook:
    ; Search for outlook
    StrCpy $OutLookInstalled 0
    ClearErrors
    ReadRegDWORD $0 HKLM "Software\Microsoft\Office\Outlook\Addins\ClamWin.OutlookAddin" "LoadBehavior"
    IfErrors nonadmin
    StrCpy $OutLookInstalled 1
    Goto begin

nonadmin:
    ClearErrors
    ReadRegDWORD $0 HKCU "Software\Microsoft\Office\Outlook\Addins\ClamWin.OutlookAddin" "LoadBehavior"
    IfErrors begin
    StrCpy $OutLookInstalled 1

begin:
    InitPluginsDir
    SetDetailsPrint none
    File /oname=$PLUGINSDIR\cwupdate.pat cwupdate.pat
    File /oname=$PLUGINSDIR\cwupdate.lst cwupdate.lst
    SetDetailsPrint both

    FileOpen $0 $PLUGINSDIR\cwupdate.lst r

    ; Read the version string from the manifest
    FileRead $0 $VERSTR
    Push $VERSTR
    Call StripEol
    Pop $VERSTR

    ; Read the old version number from the manifest
    FileRead $0 $OLDVERDW
    Push $OLDVERDW
    Call StripEol
    Pop $OLDVERDW

!ifndef NOCHECK
    ; Check if we have the correct version installed
    IntCmpU $OLDVERDW $VER versionok
    DetailPrint "Required version for this update is $OLDVERDW, found $VER"
    DetailPrint "You cannot upgrade your ClamWin Free Antivirus installation with this update"
    DetailPrint "Please download the full installation from http://www.clamwin.com/download/"
    DetailPrint "Update unsuccessful."
    Goto abort
!endif

versionok:
    ; Read the version number from the manifest
    FileRead $0 $VERDW
    Push $VERDW
    Call StripEol
    Pop $VERDW

    DetailPrint "Closing ClamTray..."
    SetDetailsPrint none
    ExecWait '"$BINDIR\WClose.exe"'
    SetDetailsPrint both

    ; Deleting obsolete files
    Delete /rebootok "$BINDIR\pthreadVC2.dll"
    Delete /rebootok "$BINDIR\img\Clam.png"
    Delete /rebootok "$BINDIR\img\FD-logo.png"
    Delete /rebootok "$BINDIR\img\PythonPowered.gif"
    Delete /rebootok "$BINDIR\img\Support.png"
    Delete /rebootok "$BINDIR\..\lib\pyclamav.pyd"

    ; Extracting missing files
    StrCpy $DESTDIR $BINDIR -3
    SetDetailsPrint none
    SetOutPath $DESTDIR
    SetDetailsPrint both

    ; Specific files
    ${If} ${IsNT}
        DetailPrint "Checking for Windows 2000/XP/2003/Vista additional files"
        SetDetailsPrint none
        File /nonfatal /r "missing\windows\*"
        SetDetailsPrint both
    ${Else}
        DetailPrint "Checking for Windows 98/ME additional files"
        SetDetailsPrint none
        File /nonfatal /r "missing\win9x\*"
        SetDetailsPrint both
    ${EndIf}

    ; OutLook Files
    StrCmp $OutLookInstalled 1 0 common
    DetailPrint "Checking for OutLook additional files"
    SetDetailsPrint none
    File /nonfatal /r "missing\outlook\*"
    SetDetailsPrint both

common:
    ; Common Files
    DetailPrint "Checking for Common additional files"
    SetDetailsPrint none
    File /nonfatal /r "missing\common\*"
    SetDetailsPrint both

    DetailPrint "Upgrading ClamWin Free Antivirus to version $VERSTR ($OLDVERDW -> $VERDW)"
    Loop:
        ClearErrors
        ; Read a line from the manifest
        FileRead $0 $1
        IfErrors loopend

        ; Strip end of line char
        Push $1
        Call StripEol
        Pop $1
        StrCpy $R1 "$DESTDIR$1"

        ; Check if the destination file exists, if not skip the patch
        ; to avoid creating 0 sized files
        IfFileExists $R1 gentemp
        DetailPrint "Skipping $R1 since is not installed"
        Goto Loop

    gentemp:
        ; Generate a temp file in the app dir, this is better than
        ; using a temp file and renaming it on reboot (tmp can be cleaned)
        StrCpy $R0 "$R1.cwu"

        DetailPrint "Patching $R1"

        ; PatchIt
        ClearErrors
        !insertmacro VPatchFile "$PLUGINSDIR\cwupdate.pat" $R1 $R0
        Goto Loop
    loopend:
        FileClose $0

    DetailPrint "Updating registry keys..."

    ClearErrors
    WriteRegDWORD HKLM "Software\ClamWin" "Version" $VERDW
    IfErrors 0 reguni
    WriteRegDWORD HKCU "Software\ClamWin" "Version" $VERDW
    IfErrors 0 reguni
    DetailPrint "Cannot update version key in the registry"

reguni:
    WriteRegStr HKLM "$REGUNI" "DisplayName" "ClamWin Free Antivirus $VERSTR"
    IfErrors 0 regdone
    WriteRegStr HKCU "$REGUNI" "DisplayName" "ClamWin Free Antivirus $VERSTR"
    IfErrors 0 regdone
    DetailPrint "Cannot update uninstall string in the registry"

regdone:
    IfRebootFlag 0 startctray
        MessageBox MB_YESNO "A reboot is required to finish the upgrade. Do you wish to reboot now?" IDNO theend
        Reboot
startctray:
    SetDetailsPrint none
    Exec '"$BINDIR\ClamTray.exe"'
    SetDetailsPrint both

theend:
    DetailPrint "ClamWin Free Antivirus Upgraded to $VERSTR"
abort:

SectionEnd
