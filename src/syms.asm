
%define BUFSZ		1024

%define EOK		0x00
%define ESH3INIT	0x01
%define EMEMW		0x10
%define EFAIL		0xFF

%define ASM_NOOP	0x90
%define ASM_CALL	0xe8
%define ASM_JMP		0xe9
%define	ASM_RET		0xc3

; --- Win32 -------------------------------------------------------------------
extern _snprintf

extern _GetLastError@0
extern _MessageBoxA@16
extern _WriteProcessMemory@20

; --- patSH3r.asm -------------------------------------------------------------
; functions
extern _patch_mem
; variables
extern _proc		; current process
extern _buf		; temporary buffer of size BUFSZ

; --- config.asm --------------------------------------------------------------
extern _init_config

; --- sh3.asm -----------------------------------------------------------------
; functions
extern _init_sh3	; init function
; variables
extern _fmgrofs		; offset to filemanager.dll
