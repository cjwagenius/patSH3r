
%define BUFSZ		1024

%define EOK		0x00
%define ESH3INIT	0x01
%define EMEMW		0x10
%define EFAIL		0xFF

%define ASM_NOOP	0x90
%define ASM_CALL	0xe8
%define ASM_JMP		0xe9
%define	ASM_RET		0xc3

struc crew 
	.name		resb	52 ;   -(uses only 50)
	.index		resd	 1 ;  0-integer
	.nrcomp		resd	 1 ;  4-integer
	.renown		resd	 1 ;  8-float
	.patrols	resd	 1 ;  c-integer
	.type		resd	 1 ; 10-integer
	.grad		resd	 1 ; 14-integer
	.notused_a	resd	 1 ; 18 ? dword
	.morale		resd	 1 ; 1c-float
	.fatigue	resd	 1 ; 20-float
	.healthsts	resd	 1 ; 24-integer
	.waswounded	resd	 1 ; 28-integer
	.experience	resd	 1 ; 2c-float
	.rank		resd	 1 ; 30-integer
	.nrqual		resd	 1 ; 34-integer
	.quals		resd	 3 ; 38-integer
	.specability	resd	 1 ; 44-integer
	.medals		resd	 9 ; 48-integer
	.hitpoints	resd	 1 ; 6c-float
	.notused_b	resd	 1 ; 70 ? dword
	.notused_c	resd	 1 ; 74 ? dword
	.notused_d	resd	 1 ; 78 ? dword
	.headidx	resd	 1 ; 7c-integer
	.headtgaidx	resd	 1 ; 80-integer
	.bodyidx	resd	 1 ; 84-integer
	.bodytgaidx	resd	 1 ; 88-integer
	.hashelmet	resd	 1 ; 8c-integer
	.helmetidx	resd	 1 ; 90-integer
	.helmettgaidx	resd	 1 ; 94-integer
	.voiceIdx	resd	 1 ; 98-integer
	.prom		resb	 1 ; 9c-byte
	.medal		resb	 9 ; 9d-byte
	.qual		resb	 9 ; a6-byte
	.notused_e	resb	 1 ;
endstruc

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
extern _crewofs		; offset to crew-array pointer
extern _fmgrofs		; offset to filemanager.dll
extern _maincfg		; offset to main.cfg object

; --- patches.asm -------------------------------------------------------------
extern _ptc_version_init
extern _ptc_smartpo_init

