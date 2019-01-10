; vim: ft=nasm fdm=marker fmr={{{,}}}
;
; time.asm - time functions for patSH3r
;------------------------------------------------------------------------------
;

struc dt
	.year		resw	1
	.mon		resw	1
	.wday		resw	1
	.mday		resw	1
	.hour		resw	1
	.min		resw	1
	.sec		resw	1
	.msec		resw	1
endstruc

extern _SystemTimeToFileTime@8

global _gametime_to_secs
global _gametime_current

section .data ; ---------------------------------------------------------------
time_ft1939_h:	dd	0x017AF037 ; FILETIME high DWORD
time_ft1939_l:	dd	0xE1DF4000 ; FILETIME low  DWORD

section .text ; ---------------------------------------------------------------
_gametime_to_secs: ; {{{

	; converts in-game calendar time to seconds since 1939-01-01
	;
	; arguments:
	;	esi	pointer to a dt-structure (sh3 calendar structure)
	;
	; returns;
	;	eax	seconds since 1939-01-01 on success
	;		-1 on conversion failure (see mktime specs)
	;
	; notes:
	;	Since the year 1939 is out of range for epoch (time_t),
	;	we replace the year with 1995 instead. This since 1995-,
	;	2006, have the same calendars as the years 1939-1950.
	;	Then we subtract the in-game seconds with epoch 1995
	;	(1995-01-01 00:00:00) to get the equal amount of seconds
	;	passed since 1939-01-01 00:00:00 to in-game time.
	;
	; ---------------------------------------------------------------------
	;
	
	push	ecx
	push	edx
	sub	esp, 8

	push	esp
	push	esi
	call	_SystemTimeToFileTime@8

	mov	eax, [esp]
	sub	eax, [time_ft1939_l]
	mov	edx, [esp+4]
	sbb	edx, [time_ft1939_h]
	mov	ecx, 10000000
	div	ecx
	
	add	esp, 8
	pop	edx
	pop	ecx
	ret

; }}}
_gametime_current: ; {{{

	; returns address to dt-structure holding current in-game
	; time.
	;
	; arguments:
	;	none
	;
	; returns:
	;	esi	address to dt-structure
	;
	;----------------------------------------------------------------------

	mov	esi, [0x00554a88]
	add	esi, 0x82c
	ret

; }}}
