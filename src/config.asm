
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
fmgr_get_yn:		dd	0x00004730
fmgr_get_int:		dd	0x00004590
fmgr_get_dbl:		dd	0x00005610
fmgr_get_str:		dd	0x000059b0

inisec:			db	"PATSH3R", 0
str_smartpo:		db	"SmartPettyOfficer", 0


section .text ; ---------------------------------------------------------------

_config_init:

	mov	eax, [_fmgrofs]
	add	[fmgr_get_yn], eax
	add	[fmgr_get_int], eax
	add	[fmgr_get_dbl], eax
	add	[fmgr_get_str], eax

	push	2
	push	str_smartpo
	push	inisec
	mov	ecx, [_maincfg]
	call	[fmgr_get_yn]
	mov	[aaa], eax

	mov	al, EOK
	ret


