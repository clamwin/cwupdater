!define TO_MS 15000
!define SYNC_TERM 0x00100001

!include WinMessages.nsh

Function TerminateApp
    Pop $0 ; Class
    Pop $1 ; Title
    Push $0 ; window handle
    Push $1 ; thread id
    Push $2 ; process handle
    ;DetailPrint "Searching for $0 $1"
    FindWindow $0 $0 $1
    ;DetailPrint "Result $0"
    IntCmp $0 0 done
    System::Call 'user32.dll::GetWindowThreadProcessId(i r0, *i .r1) i .r2'
    ;DetailPrint "GetWindowThreadProcessId $0 $1 $2"
    System::Call 'kernel32.dll::OpenProcess(i ${SYNC_TERM}, i 0, i r1) i .r2'
    SendMessage $0 ${WM_CLOSE} 0 0 /TIMEOUT=${TO_MS}
    System::Call 'kernel32.dll::WaitForSingleObject(i r2, i ${TO_MS}) i .r1'
    IntCmp $1 0 close
    System::Call 'kernel32.dll::TerminateProcess(i r2, i 0) i .r1'
  close:
    System::Call 'kernel32.dll::CloseHandle(i r2) i .r1'
  done:
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

!define _ReadRegStr "!insertmacro _ReadRegStr"
!macro _ReadRegStr RESULT KEY SUBKEY
    ClearErrors
    ReadRegStr ${RESULT} HKLM "${KEY}" "${SUBKEY}"
    IfErrors 0 +2
    ReadRegStr ${RESULT} HKCU "${KEY}" "${SUBKEY}"
!macroend

!define _WriteRegStr "!insertmacro _WriteRegStr"
!macro _WriteRegStr KEY SUBKEY VALUE
    ClearErrors
    WriteRegStr HKLM "${KEY}" "${SUBKEY}" "${VALUE}"
    IfErrors 0 +2
    WriteRegStr HKCU "${KEY}" "${SUBKEY}" "${VALUE}"
!macroend

!define _ReadRegDWORD "!insertmacro _ReadRegDWORD"
!macro _ReadRegDWORD RESULT KEY SUBKEY
    ClearErrors
    ReadRegDWORD ${RESULT} HKLM "${KEY}" "${SUBKEY}"
    IfErrors 0 +2
    ReadRegDWORD ${RESULT} HKCU "${KEY}" "${SUBKEY}"
!macroend

!define _WriteRegDWORD "!insertmacro _WriteRegDWORD"
!macro _WriteRegDWORD KEY SUBKEY VALUE
    ClearErrors
    WriteRegDWORD HKLM "${KEY}" "${SUBKEY}" "${VALUE}"
    IfErrors 0 +2
    WriteRegDWORD HKCU "${KEY}" "${SUBKEY}" "${VALUE}"
!macroend

!define CloseApp "!insertmacro CloseApp"
!macro CloseApp ClassName Title
    Push "${Title}"
    Push "${ClassName}"
    Call TerminateApp
!macroend

!define VPatchFile "!insertmacro VPatchFile"
!macro VPatchFile PATCHDATA SOURCEFILE TEMPFILE
    Push ${PATCHDATA}
    Push ${SOURCEFILE}
    Push ${TEMPFILE}
    Call VPatchFile
!macroend

Function VPatchFile
    Pop $0 ; TEMPFILE
    Pop $1 ; SOURCEFILE
    Pop $2 ; PATCHDATA
    vpatch::vpatchfile $2 $1 $0
    Pop $3 ; Result
    StrCpy $3 $3 2
    StrCmp $3 "OK" ok_$1
    SetErrors
ok_$1:
    IfFileExists $0 +1 end_$1
    Delete $1
    Rename /REBOOTOK $0 $1
end_$1:
FunctionEnd

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
