
%include "syms.asm"

extern _LoadLibraryA@4

section .bss ; ----------------------------------------------------------------

_fmgrofs	resd	1 ; offset to filemanager.dll


section .data ; ---------------------------------------------------------------

fmgrfn:		db	"filemanager.dll", 0

_maincfg		dd	0x00544698 ; handle to main.cfg

; Config value functions
;
; arg 1: ini-section
; arg 2: config-value
; arg 3: default value
;
; C++ ini-object @ ecx
;
_fmgr_get_yn		dd	0x00004730
_fmgr_get_int		dd	0x00004590
_fmgr_get_dbl		dd	0x00005610
_fmgr_get_str		dd	0x000059b0


section .text ; ---------------------------------------------------------------

_sh3_init:

	push	fmgrfn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	mov	[_fmgrofs], eax
	add	[_fmgr_get_yn], eax
	add	[_fmgr_get_int], eax
	add	[_fmgr_get_dbl], eax
	add	[_fmgr_get_str], eax

	mov	al, EOK
	ret

	.failure:
	mov	al, ESH3INIT
	ret
