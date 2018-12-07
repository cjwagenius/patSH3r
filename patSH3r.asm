; vim: fdm=marker ft=nasm

; Defines & imports {{{
%define BUFSZ		1024

%define EOK		0x00
%define ESH3INIT	0x01
%define EMEMW		0x10
%define EFAIL		0xFF

%define ASM_NOOP	0x90
%define ASM_CALL	0xe8
%define ASM_JMP		0xe9
%define	ASM_RET		0xc3

%define CREWQ_WATCH	0x00
%define CREWQ_MACHI	0x05
%define CREWQ_TORPE	0x06
%define CREWQ_REPEA	0x08

%define OFFCR_BRIDG	0x00
%define OFFCR_ENGIN	0x02
%define	OFFCR_NAVIG	0x03
%define OFFCR_WEAPO	0x04
%define OFFCR_DIESE	0x05
%define OFFCR_ELECT	0x06
%define OFFCR_BTORP	0x07
%define OFFCR_BQUAR	0x08
%define OFFCR_SQUAR	0x09
%define	OFFCR_STORP	0x0a
%define OFFCR_REPEA	0x0b

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

; Addresses
%define SH3_SUNDEG	0x00541cf0 ; sun sin-angle to horizon (float)

; --- Win32 -------------------------------------------------------------------
%define DLL_ATTACH	0x01

extern _free
extern _realloc
extern _sprintf
extern _snprintf
extern _strstr

extern _GetCurrentProcess@0
extern _GetLastError@0
extern _LoadLibraryA@4
extern _MessageBoxA@16
extern _WriteProcessMemory@20

;}}}

; --- _DllMain {{{
global _DllMain

section .bss
exe_proc	resd	1
_hsie		resb	1	; hsie-patched exe?
buf		resb	1024

section .data
init_patch:	db	7, ASM_NOOP, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_RET

section .text
;
; patches sh3.exe to call _patSH3r_init later
;
; arguments:
;	[esp+4]		hinstance
;	[esp+8]		reason (DLL_ATTACH | DLL_DETACH)
;	[esp+12]	reserved
;
_DllMain:

	xor	eax, eax
	cmp	dword [esp+0x08], DLL_ATTACH	;
	jne	.teardown			; teardown if not attaching

	call	_GetCurrentProcess@0
	mov	[exe_proc], eax

	mov	eax, init_patch ; insert patSH3r-init process
	mov	ecx, _patSH3r_init
	mov	edx, 0x409821
	call	_patch_mem
	cmp	al, EOK
	jne	.failure

	cmp	byte [0x44b65a], 0x90 ; check if this is a hsie-patched exe
	sete	[_hsie]

	mov	al, EOK
	jmp	.exit

	.teardown:
	; basicly freeing allocated memory
	xor	ecx, ecx
	.next:
	cmp	ecx, [mallocs_len]
	jge	.fmalloc
	push	dword [mallocs+ecx*4]
	call	_free
	add	esp, 4
	inc	ecx
	jmp	.next
	.fmalloc;
	push	dword [mallocs]
	call	_free
	add	esp, 4
	mov	eax, EOK
	jmp	.exit

	.failure:
	call	_popup_error

	.exit:
	cmp	al, EOK
	sete	al

	ret
	
; }}}
; --- misc {{{
; --- memory functions {{{
section .data
mallocs:		dd	0
mallocs_mem:		dd	0
mallocs_len:		dd	0

section .text
malloc: ; {{{ ecx -> eax | T: edx

	push	ecx
	mov	ecx, [mallocs_len]
	inc	ecx
	cmp	ecx, dword [mallocs_mem]
	jb	.alloc

	; expand mallocs-array
	sub	esp, 4
	add	dword [mallocs_mem], 8
	mov	eax, [mallocs_mem]
	mov	edx, 4
	mul	edx
	mov	dword [esp], eax
	push	dword [mallocs]
	call	_realloc
	add	esp, 8
	mov	[mallocs], eax

	.alloc:
	; size already on stack
	push	dword 0
	call	_realloc
	add	esp, 4
	mov	ecx, dword [mallocs_len]
	mov	edx, dword [mallocs+ecx*4]
	mov	[edx], eax
	inc	dword [mallocs_len]

	pop	ecx
	ret

; }}}
free: ; {{{

	mov	eax, [mallocs_len]
	test	eax, eax
	jz	.exit
	mov	eax, [mallocs+eax*4]
	push	eax
	call	_free
	add	esp, 4

	.exit:
	ret

; }}}
; }}}
; }}}
; --- _patSH3r_init {{{
section .data
inisec:		db	"PATSH3R", 0

;
; initializes everything
;
; arguments:
;	-
;
; returns:
;	-
;
section .text
_patSH3r_init:

	call	_sh3_init
	cmp	al, EOK
	jne	.failure

	call	_ptc_version_init
	cmp	al, EOK
	jne	.failure

	call	_ptc_smartpo_init
	cmp	al, EOK
	jne	.failure

	call	_ptc_alertwo_init
	cmp	al, EOK
	jne	.failure

	call	_ptc_repairt_init
	cmp	al, EOK
	jne	.failure
	
	call	_ptc_nvision_init
	cmp	al, EOK
	jne	.failure

	call	_ptc_absbrig_init
	cmp	al, EOK
	jne	.failure

	ret

	.failure:
	call	_popup_error
	ret

; }}}
; --- _popup_error {{{
section .data
popup_error_cap:	db	"patSH3r Error", 0
popup_error_msg:	db	"Failed with error code: %d", 0

section .text
;
; Pops up a message-box which displays the error-code.
;
; arguments:
;	al	error-code
;
; returns:
;	eax	error-code
;
_popup_error:

	and	eax, EFAIL		;
	push	eax			; mask & push error-code
	push	popup_error_msg
	push	BUFSZ
	push	buf
	call	_snprintf
	add	esp, 12			; pop all args but error-code

	push	0x10 ; MB_ICONERROR
	push	popup_error_cap
	push	buf
	push	dword 0
	call	_MessageBoxA@16
	pop	eax			; restore error-code

	ret

; }}}
; --- _patch_mem {{{
;
; patches code in memory
;
; arguments:
;	eax	code-buffer
;	ecx	target address (for jmp/call) [opt]
;	edx	destination in memory
;
; returns:
;	eax	EOK on success
;	eax	EMEMW on failure
;
_patch_mem:

	pushf
	push	edi
	push	esi
	push	ecx
	cld
	mov	esi, eax
	inc	esi		; first byte is code length
	mov	edi, buf
	mov	al, [eax]
	and	eax, 0xff	; from now on, eax will string length + 1
	mov	ecx, eax
	rep	movsb

	cmp	dword [esp], 0	;
	je	.write		; if no target address, don't append it
	push	eax
	mov	edi, buf	;
	mov	ecx, eax	;
	mov	al, 0xcc	;
	repne	scasb		; find place-holder for target address
	dec	edi
	pop	eax

	mov	ecx, 4
	mov	esi, esp
	push	eax
	mov	eax, edi	   ; calculate op-codes before place-holder
	sub	eax, buf	   ;
	add	eax, 4		   ; add pointer size
	sub	dword [esi], edx   ; make address relative to edx
	sub	dword [esi], eax   ;
	pop	eax
	rep	movsb

	.write:
	push	dword 0
	push	eax
	push	buf
	push	edx
	push	dword [exe_proc]
	call	_WriteProcessMemory@20
	add	esp, 4		; pop ecx
	pop	esi
	pop	edi
	popf
	cmp	eax, 0
	je 	.failure

	mov	eax, EOK
	ret

	.failure:
	mov	eax, EMEMW
	ret

; }}}
; sh3 functions & variables {{{
section .data
sh3_crews:	dd	0x005f6238		; offset to the crew array
sh3_maincfg	dd	0x00544698		; handle to main.cfg
esimact:	dd	0
fmgrdll:	dd	0
esimact_fn	db	"EnvSim.act", 0
fmgrdll_fn:	db	"filemanager.dll", 0

; Config value functions
;
; arg 1: ini-section
; arg 2: config-value
; arg 3: default value
;
; C++ ini-object @ ecx
;
_sh3_cfg_yn		dd	0x00004730
_sh3_cfg_int		dd	0x00004590
_sh3_cfg_flt		dd	0x00004610
_sh3_cfg_str		dd	0x000059b0

; --- _sh3_mvcrew
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

	push	fmgrdll_fn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	mov	[fmgrdll], eax
	add	[_sh3_cfg_yn], eax
	add	[_sh3_cfg_int], eax
	add	[_sh3_cfg_flt], eax
	add	[_sh3_cfg_str], eax

	push	esimact_fn
	call	_LoadLibraryA@4
	cmp	eax, 0
	je	.failure
	mov	[esimact], eax

	mov	al, EOK
	ret

	.failure:
	mov	al, ESH3INIT
	ret


; }}}
; ptc {{{
; --- _ptc_version_init {{{
;
; background:
;	we want the current revision displayed at the title screen
;
; solution:
;	intercept program flow where sh3 sprintfs its version
;
; note:
;	if patching a hsie-patched exe, intercept his solution
;	instead
;
section .data
str_version:	db	10, "patSH3r r%i", 0
ptc_version:	db	6, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

section .text
_ptc_version_init:

	mov	eax, ptc_version
	mov	ecx, .sprntf
	cmp	byte [_hsie], 1
	je	.hsie
	mov	edx, 0x44b657
	jmp	.exit
	
	.hsie:
	mov	edx, 0x633007

	.exit:
	call	_patch_mem
	ret

	.sprntf:
	push	ebp
	mov	ebp, esp
	sub	esp, 4
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	dword [ebp+8]
	call	_sprintf
	add	esp, 16
	mov	dword [esp], eax
	add	dword [ebp+8], eax ; append sprintf
	push	dword PATSH3R_REV
	push	str_version
	push	dword [ebp+8]
	call	_sprintf
	add	esp, 12
	add	eax, dword [esp]
	mov	esp, ebp
	pop	ebp
	ret

; }}}
; --- _ptc_smartpo_init {{{
;
; background:
;	Petty-officers that don't have the machinery qual, doesn't
;	change engine compartments automatically
;
; solution:
;	remove qual-checks when necessary
;
section .data
ptc_smartpo_cfg:	db	"SmarterPettyOfficers", 0
ptc_smartpo_01:		db	4, 0x39, 0xc0, ASM_NOOP, ASM_NOOP
ptc_smartpo_02: 	db	4, ASM_NOOP, ASM_NOOP, ASM_NOOP, ASM_NOOP

section .text
_ptc_smartpo_init:

	; config-check
	push	dword 0			; push default 'No'
	push	ptc_smartpo_cfg
	push	inisec			; "PATSH3R"
	mov	ecx, [sh3_maincfg]
	call	[_sh3_cfg_yn]
	cmp	al, 1
	jne	.exit_ok

	; patch when moving group of crew between compartments
	mov	eax, ptc_smartpo_01
	mov	ecx, 0
	mov	edx, 0x41DB25
	call	_patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when moving group of crew between compartments
	mov	eax, ptc_smartpo_02
	mov	ecx, 0
	mov	edx, 0x42ac2e
	call	_patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when submerging
	mov	eax, ptc_smartpo_02
	mov	ecx, 0
	mov	edx, 0x4376f0
	call	_patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when surfacing
	mov	eax, ptc_smartpo_02
	mov	ecx, 0
	mov	edx, 0x4377de
	call	_patch_mem
	cmp	al, EOK
	jne	.failure

	.exit_ok:
	mov	eax, EOK
	.failure:
	ret

; }}}
; --- _ptc_alertwo_init {{{
;
; background:
;	when surfacing, the wo is still in the bunks
;
; solution:
;	check which WO has the least fatigue and move to bridge.
;
; note:
;	if patching a hsie-patched exe, intercept his solution
;	instead
;
section .data
ptc_alertwo_cfg:	db	"AlertWatchOfficer", 0
ptc_alertwo_rtn		dd	0x0042d097
ptc_alertwo		db	6, ASM_JMP, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

_ptc_alertwo_init:

	push	dword 0			; push default 'No'
	push	ptc_alertwo_cfg
	push	inisec			; push "PATSH3R"
	mov	ecx, [sh3_maincfg]
	call	[_sh3_cfg_yn]
	cmp	al, 1
	je	.go
	mov	al, EOK
	ret

	.go:
	mov	eax, ptc_alertwo
	mov	ecx, alertwo
	mov	edx, 0x0042d08f	; address of interception
	call	_patch_mem
	ret

alertwo:

	pushf
	pushad
	call	alertwo_findwo
	cmp	eax, -1
	je	.exit
	push	dword 0
	push	OFFCR_BRIDG
	push	eax
	mov	ecx, ebp
	call	[_sh3_mvcrew]

	.exit:
	popad
	popf
	mov	dword [esp + 0x0c], 0
	jmp	[ptc_alertwo_rtn]
	ret

alertwo_findwo:

	; find out which officer that are to be moved to bridge
	sub	esp, 10h
	mov	dword [esp + 00h], OFFCR_BQUAR
	mov	dword [esp + 04h], __float32__(1.0)
	mov	dword [esp + 08h], OFFCR_SQUAR
	mov	dword [esp + 0ch], __float32__(1.0)
	mov	ecx, 0

	.nxt_quart:
	mov	eax, crew_size
	mul	dword [esp + ecx * 08h]
	add	eax, [sh3_crews]
	mov	ebx, eax
	cmp	dword [ebx + crew.nrcomp], -1
	je	.quar_done
	cld
	push	ecx
	mov	ecx, [ebx + crew.nrqual]
	mov	edi, ebx
	add	edi, crew.quals
	mov	eax, CREWQ_WATCH
	repne scasd
	pop	ecx
	jnz	.quar_done
	mov	edi, [ebx + crew.fatigue]
	mov	dword [esp + ecx * 8 + 4], edi

	.quar_done:
	inc	ecx
	cmp	ecx, 1
	jle	.nxt_quart

	mov	eax, [esp + 00h]
	mov	ecx, [esp + 04h]
	cmp	ecx, [esp + 0ch]
	cmovg	eax, [esp + 08h]
	cmovg	ecx, [esp + 0ch]

	cmp	ecx, __float32__(1.0)
	jne	.exit
	mov	eax, -1

	.exit:
	add	esp, 10h
	ret

; }}}
; --- _ptc_repairt_init {{{
section .bss
ptc_repairt_fac:	resd	1

section .data
ptc_repairt_cfg:	db	"RepairTimeFactor", 0

section .text
_ptc_repairt_init:

	sub	esp, 4
	mov	dword [esp], 0		; push default 'off' (0.0)
	push	ptc_repairt_cfg
	push	inisec
	mov	ecx, [sh3_maincfg]
	call	[_sh3_cfg_flt]
	fldz
	fcomip	st0, st1
	jnz	.go
	fstp	st0
	jmp	.exit_ok

	.go:
	fstp	dword [ptc_repairt_fac]
	sub	esp, 8
	mov	[esp+4], dword ptc_repairt_fac
	lea	eax, [esp+4]
	mov	[esp], eax
	;mov	eax, ptc_repairt
	;mov	ecx, ptc_repairt_fac
	;mov	edx, 0x0041df6e
	push	0
	push	4
	push	dword [esp+8]
	push	0x0041df76
	push	dword [exe_proc]
	call	_WriteProcessMemory@20
	add	esp, 8
	test	eax, eax
	jz	.failure

	.exit_ok:
	mov	eax, EOK
	ret

	.failure:
	mov	eax, EMEMW
	ret

; }}}
; --- _ptc_nvision_init {{{
section .bss
ptc_nvision_fac:	resd	1

section .data
ptc_nvision:		db	7, ASM_JMP, 0xcc, 0xcc, 0xcc, 0xcc, \
				ASM_NOOP, ASM_NOOP
ptc_nvision_cfg:	db	"NightVisionFactor", 0
ptc_nvision_lhz:	dd	-0.2588 ; angle below horizon where light
					; disappear
section .text
_ptc_nvision_init:

	; config-check
	push	dword 0			; push default 'off' (0.0)
	push	ptc_nvision_cfg
	push	inisec
	mov	ecx, [sh3_maincfg]
	call	[_sh3_cfg_flt]
	fldz
	fcomip	st0, st1
	jnz	.go
	fstp	st0
	mov	eax, EOK
	ret

	.go:
	fstp	dword [ptc_nvision_fac]
	mov	eax, ptc_nvision
	mov	ecx, _nvision
	mov	edx, [esimact]		; base of EnvSim.act
	add	edx, 0x00003c06		; offset in EnvSim.act
	call	_patch_mem
	ret

_nvision:

	fld	dword [SH3_SUNDEG]	; load sun SIN(degree) vs horizon
	fldz				; load horizon (which is at 0 degrees)
	fcomip	st0, st1		; if sun above horizon
	jb	.daylight		;   then goto .daylight

	fld	dword [ptc_nvision_lhz]
	fcomip	st0, st1		; if sun below light_horizon
	ja	.night			;   then goto .night

	; The sun is still within the light horizon, so we'll calculate a
	; smooth transition of the fog-wall between daylight and pitch black.
	fld	dword [ptc_nvision_lhz]
	fdivp				; darkness% = sun_angle / light_horizon
	fld1
	fsub	dword [ptc_nvision_fac] ; (1 - night_vision_factor)
	fmulp			; (1/fog_factor) = darkness% * (1-nv_factor)
	fld1
	fxch
	fmulp				; invert fog_factor
	fadd	dword [ptc_nvision_fac]
	fmulp				; multiply with original value
	jmp	.exit

	.daylight:			; no more calculations necessary
	fstp	st0			; pop off sun_angle
	jmp	.exit

	.night:
	fstp	st0			; pop off sun_angle
	fld	dword [ptc_nvision_fac] ; push fog_factor on FPU for return
	fmulp				; multiply with original value
	jmp		.exit

	.exit:
	fstp	dword [ecx]
	fstp	st0
	ret	8

; }}}
; --- _ptc_absbrig_init {{{
section .data
absbear_msg		dd	0
absbear_fmt		db	" (%03.0f)",0
absbear_fmtsz		equ	$-(absbear_fmt+1)
absbear_dbl		db	"%03.0f",0
absbear_dblsz		equ	$-(absbear_dbl+1)
ptc_absbrig_cfg		db	"AbsoluteBearings",0
ptc_absbrig		db	6, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

section .text
_ptc_absbrig_init:

	push	0			; default 'No'
	push	ptc_absbrig_cfg
	push	inisec
	mov	ecx, [sh3_maincfg]
	call	[_sh3_cfg_yn]
	test	eax, eax
	jnz	.go
	ret

	.go:
	mov	eax, ptc_absbrig
	mov	ecx, _absbear
	mov	edx, 0x00513cbf
	call	_patch_mem
	ret


_absbear: ; dd buff, dd fmt, qd bearing, qd range

	push	ebp
	mov	ebp, esp
	push	esi
	push	edi

	cmp	dword [absbear_msg], 0
	jne	.init_done

	; originally, the watch officers string is formated
	; for two doubles (bearing & range). we got to modify
	; this string to handle absolute bearing too.
	; we do this by allocating a new string which we'll
	; insert the %-format in. we'll set it up the first
	; time this function is run

	sub	esp, 4
	mov	esi, [ebp+12]
	call	string_len
	inc	ecx			; len + '\0'
	mov	[esp], ecx
	add	ecx, absbear_fmtsz
	call	malloc
	mov	[absbear_msg], eax
	mov	edi, eax
	call	string_cpy
	mov	esi, absbear_dbl
	call	string_find
	; TODO: handle ecx = -1. this will crash later if "%03.0f" not found
	sub	[esp], ecx
	mov	esi, edi
	add	esi, ecx
	add	esi, absbear_dblsz
	;mov	eax, esi
	mov	edi, esi
	add	edi, absbear_fmtsz
	;xor	ecx, ecx
	call	string_cpy
	;mov	edi, eax
	mov	edi, esi
	mov	esi, absbear_fmt
	xor	ecx, ecx
	call	string_cpy
	add	esp, 4

	.init_done:
	; push (double) range on stack
	sub	esp, 8
	fld	qword [ebp+24]
	fstp	qword [esp]
	
	; calculate & push (double) absolute bearing on stack
	sub	esp, 8
	mov	eax, [0x00554698]
	add	eax, 100		; offset to heading
	fld	dword [eax]
	fadd	qword [ebp+16]		; heading + bearing
	push	dword 360
	fild	dword [esp]		; push 380 on FPU-stack
	add	esp, 4
	fxch
	fprem				; (heading + bearing) % 380
	fstp	qword [esp]
	fstp	st0

	; push (double) bearing on stack
	sub	esp, 8
	fld	qword [ebp+16]
	fstp	qword [esp]

	;push (char*) fmt and (char*) dst on stack
	push	dword [absbear_msg]
	;mov	eax, [ebp+12]
	;push	eax
	mov	eax, [ebp+8]
	push	eax

	call	_sprintf
	
	mov	esp, ebp
	pop	ebp
	ret

; }}}
; }}}

; Notes {{{
;
; TODO:
;	- when submerging/surfacing, if radio/sonar spot is empty; move
;         sonar/radio guy there
;
;	[sub(?)] : 0x00554698
;			: + 48 = hour of day (word)
;			; + 50 = minute of day (word)
;			: + 52 = time of day in seconds 
;			: + 84 = heading (float)
;			: + 88 = speed (float)

; Sub-depth : SH3Contr + 0x1f308?
;
;  Crew array (located at 0x5F6238)                            
;
;  The crew array contains information about all the crew. The total length
; of the array is not yet known. The indexes in the array are also positions
; in the u-boat and it's compartments.
;
;  When moving the crew manually (in game), the information in the source-
; index gets copied to the destination-index. If it's NOT an officer, the
; memory at the source index gets cleared (in some sence), otherwise only
; crew_s.nrComp will be set to a negative value. So the only reliable way to
; check if the slot is free/empty, is to check if crew_s.nrComp < 0.
;
; Indexes:
; 		0 WO
;		1 [Nothing ?]
;		2 CE
;		3 NO
;		4 WP
;		30 Helms 1
;		31 Helms 2
;		32 Helms 3
;
; Compartments:
; 					      Officer  		Type
; 	    Compartment		Index	       Index 	 	 II
; 	   ----------------------------------------------------------
; 	    Bridge		 13	 	 0		 4
;   	    Deck Casing		 17		 -		 -
; 	    Flak		 20		 -		 1
; 	    Sonar		 28		 -		 1
; 	    Radio		 29		 -		 1
; 	    Diesel Engines	 33		 5		 6
; 	    Electric Engines	 43		 6		 6
; 	    Bow Torpedo		 53		 7		10
; 	    Bow Quarters	 67		 8		13
; 	    Stern Quarters	 83		 9		 6
; 	    Stern Torpedo	 99		10		 -
;	    Repair		107		11		 8
;
; Repair len: IXB1, VII = 10 : XXI = 12
;

; }}}

%include "string.asm"

