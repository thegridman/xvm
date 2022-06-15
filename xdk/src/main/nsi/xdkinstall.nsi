!include "MUI2.nsh"
!include "logiclib.nsh"

; ----- installer setup ----------------------------------------------------------------------------

!ifndef SRC
!verbose push
!verbose 4
!error "SRC is required (location of XDK build contents)"
!verbose pop
!endif

!ifndef VER
!verbose push
!verbose 4
!error "VER is required (XDK version number)"
!verbose pop
!endif

!define NAME "XDK"
!define DESC "${NAME} ${VER}"

RequestExecutionLevel admin

; ----- UI setup -----------------------------------------------------------------------------------

Name "the Ecstasy development kit"
Outfile "xdkinstall.exe"

!ifndef MUI_ICON
!verbose push
!verbose 4
!error "MUI_ICON is required (path to the Ecstasy icon file)"
!verbose pop
!endif

!define MUI_HEADERIMAGE
!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE "${NAME} Setup"

!verbose push
!verbose 4
!echo "passed in: SRC=${SRC}, VER=${VER}, ICON=${MUI_ICON}"
!verbose pop

; ----- pages --------------------------------------------------------------------------------------

; Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Set UI language
!insertmacro MUI_LANGUAGE "English"

; directory selection
InstallDir $PROGRAMFILES64\xdk
InstallDirRegKey HKCU "Software\${NAME}" "Install_Dir"
DirText "Preparing to install the Ecstasy development kit (XDK) onto your computer."

; ----- install ------------------------------------------------------------------------------------

Section "-hidden app"
  SectionIn RO
  SetOutPath "$INSTDIR"
  File /r "${SRC}\*.*"
  SetOutPath "$INSTDIR\bin"
  CopyFiles $INSTDIR\bin\windows_launcher.exe $INSTDIR\bin\xec.exe
  CopyFiles $INSTDIR\bin\windows_launcher.exe $INSTDIR\bin\xtc.exe
  CopyFiles $INSTDIR\bin\windows_launcher.exe $INSTDIR\bin\xam.exe

  WriteRegStr HKLM "Software\${NAME}" "Install_Dir" $INSTDIR
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "DisplayName" "${NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}" "NoRepair" 1
  WriteUninstaller "$INSTDIR\uninstall.exe"

  nsExec::Exec 'echo %PATH% | find "$INSTDIR\bin"'
  Pop $0   ; gets result code
  ${If} $0 = 0
    EnVar::SetHKLM
    EnVar::AddValue "PATH" "$INSTDIR\bin"
    Pop $0
    ${If} $0 != 0
      MessageBox MB_OK "Unable to add $INSTDIR\bin to PATH"
    ${EndIf}
  ${EndIf}

  ClearErrors
  ReadRegStr $1 HKLM "SOFTWARE\JavaSoft\Java Development Kit" "CurrentVersion"
  IfErrors 0 Found
    MessageBox MB_OK "Install Java 17 (or later) to use the XDK"
  Found:
SectionEnd

; ----- uninstaller --------------------------------------------------------------------------------

Function un.RMDirUP
  !define RMDirUP '!insertmacro RMDirUPCall'

  !macro RMDirUPCall _PATH
    push '${_PATH}'
    Call un.RMDirUP
  !macroend

  ; $0 - current folder
  ClearErrors
  Exch $0
  RMDir "$0\.."
  IfErrors Skip
    ${RMDirUP} "$0\.."
  Skip:
  Pop $0
FunctionEnd

Section "Uninstall"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir /r "$INSTDIR"
  ${RMDirUP} "$INSTDIR"
  DeleteRegKey HKLM "Software\${NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${NAME}"

  nsExec::Exec 'echo %PATH% | find "$INSTDIR\bin"'
  Pop $0   ; gets result code
  ${If} $0 != 0
    EnVar::SetHKLM
    EnVar::DeleteValue "PATH" "$INSTDIR\bin"
    Pop $0
    ${If} $0 != 0
      MessageBox MB_OK "Unable to delete $INSTDIR\bin from PATH"
    ${EndIf}
  ${EndIf}
SectionEnd

