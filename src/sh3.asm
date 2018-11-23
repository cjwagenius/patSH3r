
%include "syms.asm"

extern _LoadLibraryA@4

section .bss ; ----------------------------------------------------------------

_fmgrofs	resd	1 ; offset to filemanager.dll


section .data ; ---------------------------------------------------------------

_crewofs	dd	0x005f6238
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

; --- sh3_mvcrew
;
; moves a crew member from one index to another.
;
; arguments:
;	1	from idx
;	2	to idx
;
; returns:
;	-
;
_sh3_mvcrew		dd	0x00428370

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
