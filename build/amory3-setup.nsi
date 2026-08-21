Unicode true
RequestExecutionLevel admin
SetCompressor /SOLID lzma
SetCompressorDictSize 32

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

!define PRODUCT_NAME "AMORY 3"
!define PRODUCT_VERSION "3.0.0"
!define PRODUCT_PUBLISHER "AMORY"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\AMORY3"

Name "${PRODUCT_NAME}"
Caption "AMORY 3 Offline Windows Installer"
OutFile "AMORY_3_Setup_Offline_x64.exe"
InstallDir "$PROGRAMDATA\AMORY3"
BrandingText "AMORY 3 Offline Windows Installer"
ShowInstDetails show
ShowUninstDetails show
XPStyle on

!define MUI_ABORTWARNING
!define MUI_ICON "staging\app\public\amory.ico"
!define MUI_UNICON "staging\app\public\amory.ico"
!define MUI_WELCOMEPAGE_TITLE "AMORY 3"
!define MUI_WELCOMEPAGE_TEXT "Setup will install AMORY 3 on this computer.$\r$\n$\r$\nNode.js and MySQL prerequisites must already be installed. Setup will not download any prerequisites.$\r$\n$\r$\nClick Next to continue."
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Run AMORY 3"
!define MUI_FINISHPAGE_RUN_FUNCTION LaunchAMORY
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP|MB_OK "AMORY 3 requires 64-bit Windows."
    Abort
  ${EndIf}
FunctionEnd

Section "AMORY 3" SEC01
  SectionIn RO
  SetShellVarContext all
  SetOutPath "$INSTDIR\App"
  File /r "staging\app\*.*"

  DetailPrint "Configuring AMORY 3 local MySQL instance..."
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$INSTDIR\App\Configure-AMORY3.ps1"'
  Pop $0
  ${If} $0 != 0
    MessageBox MB_ICONSTOP|MB_OK "AMORY 3 configuration failed.$\r$\n$\r$\nSee: $INSTDIR\Logs"
    Abort
  ${EndIf}

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\AMORY 3"
  CreateShortCut "$SMPROGRAMS\AMORY 3\AMORY 3.lnk" "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$INSTDIR\App\Start-AMORY3.ps1"' "$INSTDIR\App\public\amory.ico"
  CreateShortCut "$DESKTOP\AMORY 3.lnk" "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$INSTDIR\App\Start-AMORY3.ps1"' "$INSTDIR\App\public\amory.ico"

  SetRegView 64
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayName" "${PRODUCT_NAME}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\App\public\amory.ico"
  WriteRegStr HKLM "${PRODUCT_UNINST_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "NoRepair" 1
SectionEnd

Function LaunchAMORY
  ExecShell "open" "powershell.exe" '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$INSTDIR\App\Start-AMORY3.ps1"'
FunctionEnd

Section "Uninstall"
  SetShellVarContext all
  nsExec::ExecToLog 'schtasks.exe /Delete /TN "AMORY3-Backend" /F'
  nsExec::ExecToLog 'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Stop-Service AMORY3-MySQL -Force -ErrorAction SilentlyContinue"'
  nsExec::ExecToLog 'sc.exe delete AMORY3-MySQL'
  Delete "$DESKTOP\AMORY 3.lnk"
  RMDir /r "$SMPROGRAMS\AMORY 3"
  RMDir /r "$INSTDIR\App"
  Delete "$INSTDIR\Uninstall.exe"
  SetRegView 64
  DeleteRegKey HKLM "${PRODUCT_UNINST_KEY}"
  MessageBox MB_ICONINFORMATION|MB_OK "AMORY 3 application files were removed.$\r$\nYour database and backups remain in $INSTDIR."
SectionEnd
