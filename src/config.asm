
%include "syms.asm"

section .data ; ---------------------------------------------------------------

_maincfg:		dd	0x00544698 ; handle to main.cfg

; Config value functions
;
; arg 1: ini-section
; arg 2: config-value
; arg 3: default value
;
; C++ ini-object @ ecx
;
fmgr_get_bool:		dd	0x000047b0
fmgr_get_int:		dd	0x00004590
fmgr_get_dbl:		dd	0x00005610
fmgr_get_str:		dd	0x000059b0


section .text ; ---------------------------------------------------------------

_init_config:

	mov	eax, [_fmgrofs]
	add	[fmgr_get_bool], eax
	add	[fmgr_get_int], eax
	add	[fmgr_get_dbl], eax
	add	[fmgr_get_str], eax

	;push	ecx
	;push	50
	;push	_gen
	;push	_sound
	;mov	ecx, [_iniobj]
	;call	[fmgr_get_int]
	;mov	[_aaa], eax
	;pop	ecx

	mov	al, EOK

	ret


