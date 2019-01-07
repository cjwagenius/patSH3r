
; time.asm - time functions for patSH3r
;------------------------------------------------------------------------------
;

%define EPOCH_1995	788918400

struc tm
	.sec		resd	1
	.min		resd	1
	.hour		resd	1
	.mday		resd	1
	.mon		resd	1
	.year		resd	1
	.wday		resd	1
	.yday		resd	1
	.isdst		resd	1
endstruc

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

extern _mktime

global _gametime_to_secs
global _gametime_current

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

	push	ebp
	mov	ebp, esp
	sub	esp, 40

	mov	dword [esp + tm.isdst], -1	;
	mov	dword [esp + tm.year], 95	;
	mov	dword [esp + tm.mon], 1		;
	mov	dword [esp + tm.mday], 1	;
	mov	dword [esp + tm.hour], 0	;
	mov	dword [esp + tm.min], 0		;
	mov	dword [esp + tm.sec], 0		;
	push	esp				;
	call	_mktime				;
	add	esp, 4				; set new epoch --
	mov	[ebp - 4], eax			; (1995-01-01 00:00:00)

	mov	ax, [esi + dt.year]
	sub	ax, 1939
	add	ax, 95
	cwde
	mov	[esp + tm.year], eax
	mov	ax, [esi + dt.mon]
	cwde
	mov	[esp + tm.mon], eax
	mov	ax, [esi + dt.mday]
	cwde
	mov	[esp + tm.mday], eax
	mov	ax, [esi + dt.hour]
	cwde
	mov	[esp + tm.hour], eax
	mov	ax, [esi + dt.min]
	cwde
	mov	[esp + tm.min], eax
	mov	ax, [esi + dt.sec]
	cwde
	mov	[esp + tm.sec], eax
	
	push	esp
	call	_mktime
	add	esp, 4
	cmp	eax, 0
	jl	.exit

	sub	eax, dword [ebp - 4]		; secs since new epoch

	mov	esp, ebp
	pop	ebp

	.exit:
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
