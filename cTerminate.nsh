!define TO_MS 3000
!define SYNC_TERM 0x00100001

!include WinMessages.nsh

Function TerminateApp
    Pop $0 ; Class
    Pop $1 ; Title
    Push $0 ; Result
    DetailPrint "Searching for $0 $1"
    FindWindow $0 $0 $1
    DetailPrint "Result $0"
    IntCmp $0 0 done
    ; Window Handle in $0
    Push $1 ; process id
    Push $2 ; thread
    System::Call 'user32.dll::GetWindowThreadProcessId(i r0, *i .r1) i .r2'
    DetailPrint "Found $0 $1 $2"
    System::Call 'kernel32.dll::OpenProcess(i ${SYNC_TERM}, i 0, i r1) i .r2'
    SendMessage $0 ${WM_CLOSE} 0 0 /TIMEOUT=${TO_MS}
    System::Call 'kernel32.dll::WaitForSingleObject(i r2, i ${TO_MS}) i .r1'
    IntCmp $1 0 close
    System::Call 'kernel32.dll::CloseHandle(i r2) i .r1'
    Goto Done
  terminate:
    System::Call 'kernel32.dll::TerminateProcess(i r2, i 0) i .r1'
  close:
    System::Call 'kernel32.dll::CloseHandle(i r2) i .r1'
  done:
    Pop $2
    Pop $1
    Pop $0
FunctionEnd
