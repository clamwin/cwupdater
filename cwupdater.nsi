; ClamWin NSIS/VPatch updater
;
; Copyright (c) 2008-2009 Gianluigi Tiesi <sherpya@netfarm.it>
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
!define NOSPLASH

Caption "ClamWin Free Antivirus Updater"

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
!include "cWelcome.nsh"
!include "cUtils.nsh"

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_ICON "cwupdater.ico"
!define MUI_ABORTWARNING

Page custom cwelcome
!insertmacro MUI_PAGE_LICENSE "License.rtf"
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Function .onInit
        InitPluginsDir
!ifndef NOSPLASH
        File /oname=$PLUGINSDIR\splash.bmp splash.bmp
        advsplash::show 1000 600 400 0x04025C $PLUGINSDIR\splash
        Pop $0
        Delete $PLUGINSDIR\splash.bmp
!endif
FunctionEnd

Section "CwUpdater"
    Var /GLOBAL DESTDIR
    Var /GLOBAL BINDIR
    Var /GLOBAL TARGETV
    Var /GLOBAL NEWVERDW
    Var /GLOBAL NEWVERSZ
    Var /GLOBAL REGUNI
    Var /GLOBAL FD

    StrCpy $REGUNI "Software\Microsoft\Windows\CurrentVersion\Uninstall\ClamWin Free Antivirus_is1"

    ; Search for ClamWin installation path
    ClearErrors
    ReadRegStr $BINDIR HKLM Software\ClamWin "Path"
    IfErrors 0 begin
    ReadRegStr $BINDIR HKCU Software\ClamWin "Path"
    IfErrors 0 begin
    DetailPrint "Cannot find ClamWin Free Antivirus Installation, aborting..."
    Abort

begin:
    InitPluginsDir
    SetDetailsPrint none
    File /oname=$PLUGINSDIR\cwupdate.pat cwupdate.pat
    File /oname=$PLUGINSDIR\cwupdate.lst cwupdate.lst
    SetDetailsPrint both

    FileOpen $FD $PLUGINSDIR\cwupdate.lst r

    ; Target version
    FileRead $FD $TARGETV
    Push $TARGETV
    Call StripEol
    Pop $TARGETV

    ; New version DWORD
    FileRead $FD $NEWVERDW
    Push $NEWVERDW
    Call StripEol
    Pop $NEWVERDW

    ; New version String for Uninstaller
    FileRead $FD $NEWVERSZ
    Push $NEWVERSZ
    Call StripEol
    Pop $NEWVERSZ

    GetDllVersion "$BINDIR\ClamWin.exe" $R0 $R1
    IntOp $R2 $R0 / 0x00010000
    IntOp $R3 $R0 & 0x0000ffff
    IntOp $R4 $R1 / 0x00010000
    IntOp $R5 $R1 & 0x0000ffff
    StrCpy $R8 "$R2.$R3.$R4.$R5"

!ifndef NOCHECK
    ; Check if we have the correct version installed
    StrCmp $TARGETV $R8 versionok
    DetailPrint "Required version for this update is $TARGETV, found $R8"
    DetailPrint "You cannot upgrade your ClamWin Free Antivirus installation with this setup"
    DetailPrint "Please download the full installation from http://www.clamwin.com/download/"
    DetailPrint "Update unsuccessful."
    Abort
!endif

versionok:
    DetailPrint "Closing ClamWin and ClamTray..."
    SetDetailsPrint none

    ${CloseApp} "wxWindowClass" "ClamWin Free Antivirus"
    ${CloseApp} "#32770" "ClamWin Internet Update Status"
    ${CloseApp} "#32770" "ClamWin Preferences"
    ${CloseApp} "ClamWinTrayWindow" "ClamWin"

    SetDetailsPrint both

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

common:
    ; Common Files
    DetailPrint "Checking for Common additional files"
    SetDetailsPrint none
    File /nonfatal /r "missing\common\*"
    SetDetailsPrint both

    DetailPrint "Upgrading ClamWin Free Antivirus to version $NEWVERSZ ($NEWVERDW)"
    Loop:
        ClearErrors
        ; Read a line from the manifest
        FileRead $FD $1
        IfErrors loopend

        ; Strip end of line char
        Push $1
        Call StripEol
        Pop $1
        StrCpy $1 "$DESTDIR$1"

        ; Check if the destination file exists, if not skip the patch
        ; to avoid creating 0 sized files
        IfFileExists $1 gentemp
        DetailPrint "Skipping $1 since is not installed"
        Goto Loop

    gentemp:
        ; Generate a temp file in the app dir, this is better than
        ; using a temp file and renaming it on reboot (tmp can be cleaned)
        StrCpy $0 "$1.cwu"

        DetailPrint "Patching $1"

        ; PatchIt
        ClearErrors
        ${VPatchFile} "$PLUGINSDIR\cwupdate.pat" $1 $0
        Goto Loop
    loopend:
        FileClose $FD

    DetailPrint "Updating registry keys..."

    ClearErrors
    WriteRegDWORD HKLM "Software\ClamWin" "Version" $NEWVERDW
    IfErrors 0 reguni
    WriteRegDWORD HKCU "Software\ClamWin" "Version" $NEWVERDW
    IfErrors 0 reguni
    DetailPrint "Cannot update version key in the registry"

reguni:
    WriteRegStr HKLM "$REGUNI" "DisplayName" "ClamWin Free Antivirus $NEWVERSZ"
    IfErrors 0 regdone
    WriteRegStr HKCU "$REGUNI" "DisplayName" "ClamWin Free Antivirus $NEWVERSZ"
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
    DetailPrint "ClamWin Free Antivirus Upgraded to $NEWVERSZ"

SectionEnd
