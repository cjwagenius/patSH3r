
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
extern _sprintf
extern _snprintf

extern _GetLastError@0
extern _MessageBoxA@16
extern _WriteProcessMemory@20

; --- patSH3r.asm -------------------------------------------------------------
; functions
extern _patch_mem
; variables
extern _hsie		; db, is this a hsie-patched exe?
extern _proc		; current process
extern _buf		; temporary buffer of size BUFSZ

; --- sh3.asm -----------------------------------------------------------------
; functions
extern _sh3_init	; init function
extern _fmgr_get_yn	; get yes/no from ini-file
extern _fmgr_get_int	; get integer from ini-file
extern _fmgr_get_dbl	; get double from ini-file
extern _fmgr_get_str	; get string from ini-file

; variables
extern _fmgrofs		; offset to filemanager.dll
extern _maincfg		; offset to main.cfg object

; --- patches.asm -------------------------------------------------------------
extern _ptc_version_init
extern _ptc_smartpo_init
