; ClamWin NSIS/VPatch updater - welcome page
; this code is mainly from nsis nsDialogs example
;
; Copyright (c) 2009 Gianluigi Tiesi <sherpya@netfarm.it>
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

Function HideControls
    LockWindow on
    GetDlgItem $0 $HWNDPARENT 1028
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1256
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1035
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1037
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1038
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1039
    ShowWindow $0 ${SW_HIDE}

    GetDlgItem $0 $HWNDPARENT 1045
    ShowWindow $0 ${SW_NORMAL}
    LockWindow off
FunctionEnd

Function ShowControls
    LockWindow on
    GetDlgItem $0 $HWNDPARENT 1028
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1256
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1035
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1037
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1038
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1039
    ShowWindow $0 ${SW_NORMAL}

    GetDlgItem $0 $HWNDPARENT 1045
    ShowWindow $0 ${SW_HIDE}
    LockWindow off
FunctionEnd

Var DIALOG
Var HEADLINE
Var TEXT
Var IMAGECTL
Var IMAGE
Var HEADLINE_FONT

Function cwelcome
    nsDialogs::Create /NOUNLOAD 1044
    Pop $DIALOG

    nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS}|${SS_BITMAP} 0 0 0 109u 193u ""
    Pop $IMAGECTL

    File /oname=$PLUGINSDIR\cwelcome.bmp "cwelcome.bmp"
    StrCpy $0 $PLUGINSDIR\cwelcome.bmp
    System::Call 'user32::LoadImage(i 0, t r0, i ${IMAGE_BITMAP}, i 0, i 0, i ${LR_LOADFROMFILE}) i.s'
    Pop $IMAGE

    SendMessage $IMAGECTL ${STM_SETIMAGE} ${IMAGE_BITMAP} $IMAGE

    nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 120u 10u -130u 40u "ClamWin Free Antivirus Incremental Updater"
    Pop $HEADLINE

    CreateFont $HEADLINE_FONT "$(^Font)" "14" "700"
    SendMessage $HEADLINE ${WM_SETFONT} $HEADLINE_FONT 0

    nsDialogs::CreateControl /NOUNLOAD STATIC ${WS_VISIBLE}|${WS_CHILD}|${WS_CLIPSIBLINGS} 0 120u 52u -130u -32u "This setup will follow you while updating ClamWin to the latest version available..."
    Pop $TEXT

    SetCtlColors $DIALOG "" 0xffffff
    SetCtlColors $HEADLINE "" 0xffffff
    SetCtlColors $TEXT "" 0xffffff

    Call HideControls
    nsDialogs::Show
    System::Call gdi32::DeleteObject(i$IMAGE)
    Delete $PLUGINSDIR\cwelcome.bmp
    Call ShowControls
FunctionEnd
