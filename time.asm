; vim: ft=nasm fdm=marker fmr={{{,}}}
;
; This is free and unencumbered software released into the public domain.
; 
; Anyone is free to copy, modify, publish, use, compile, sell, or
; distribute this software, either in source code form or as a compiled
; binary, for any purpose, commercial or non-commercial, and by any
; means.
; 
; In jurisdictions that recognize copyright laws, the author or authors
; of this software dedicate any and all copyright interest in the
; software to the public domain. We make this dedication for the benefit
; of the public at large and to the detriment of our heirs and
; successors. We intend this dedication to be an overt act of
; relinquishment in perpetuity of all present and future rights to this
; software under copyright law.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
; OTHER DEALINGS IN THE SOFTWARE.
; 
; For more information, please refer to <http://unlicense.org/>
;
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
	;	we replace the year with 1995 instead. This 'cause 1995-,
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
