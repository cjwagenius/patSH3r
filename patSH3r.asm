; vim: fdm=marker ft=nasm

%include "sh3.inc"
%include "misc.inc"
%include "time.inc"
%include "string.inc"

extern _report_send	; report.asm

; Defines & imports {{{

%define EOK		0x00
%define ESH3INIT	0x01
%define EMEMW		0x10
%define EFAIL		0xFF

%define ASM_NOOP	0x90
%define ASM_CALL	0xe8
%define ASM_JMP		0xe9
%define	ASM_RET		0xc3


; Addresses
%define SH3_SUNDEG	0x00541cf0 ; sun sin-angle to horizon (float)

; --- Win32 -------------------------------------------------------------------
%define DLL_DETACH	0x00
%define DLL_ATTACH	0x01

extern _free
extern _realloc
extern _sprintf
extern _snprintf
extern _strstr

extern _DebugBreak@0
extern _GetCurrentProcess@0
extern _LoadLibraryA@4
extern _MessageBoxA@16
extern _WriteProcessMemory@20

;}}}

global _DllMain

section .bss ; ----------------------------------------------------------------
exeproc			resd	1	; sh3.exes process id (-1)

section .data
popup_error_cap:	db	"patSH3r Error", 0
popup_error_msg:	db	"Failed with error code: %d", 0
incept_init:		db	7, ASM_JMP, 0xcc, 0xcc, 0xcc, 0xcc, \
				   ASM_NOOP, ASM_NOOP
return_init		dd	0x405a82
inisec:			db	"PATSH3R", 0

section .text ; ---------------------------------------------------------------
_DllMain: ; {{{

	; patches sh3.exe to call patSH3r_init later if attaching
	; tearsdown and frees allocated memory on detach
	;
	; arguments:
	;	[ebp+ 8]	hinstance
	;	[ebp+12]	reason (DLL_ATTACH | DLL_DETACH)
	;	[ebp+16]	reserved
	;
	; returns:
	;	1	on success
	;	0	on failure
	;
	; ---------------------------------------------------------------------

	push	ebp
	mov	ebp, esp
	push	esi
	push	edi

	mov	eax, EOK			; if thread, at least say 'ok'
	cmp	dword [ebp+12], DLL_ATTACH
	jg	.exit			
	;call	_DebugBreak@0
	cmp	dword [ebp+12], DLL_DETACH
	je	.detach

	cmp	byte [0x44b65a], 0x90 		; if this is a hsie-exe, then
	je	.exit				; bail

	call	_GetCurrentProcess@0		;
	mov	[exeproc], eax			; used by WriteProcessMemory

	mov	esi, incept_init		;
	mov	edi, 0x405a7b			;
	mov	eax, init			; patch patSH3rs init-function
	call	patch_mem			; to run later while loading
	cmp	eax, EOK
	jne	.failure

	mov	eax, EOK				;
	jmp	.exit				; first setup done

	.detach: ; ------------------------------------------------------------
	;xor	ecx, ecx			; XXX: disabled since not used
	;.next_ptr:				;      currently
	;cmp	ecx, [mallocs_len]		;
	;jge	.fmallocs			;
	;push	dword [mallocs+ecx*4]		;
	;call	_free				;
	;add	esp, 4				;
	;inc	ecx				;
	;jmp	.next_ptr			; free allocated memory blocks
	;.fmallocs:
	;push	dword [mallocs]			;
	;call	_free				;
	;add	esp, 4				; free memory pointer-array
	mov	eax, EOK
	jmp	.exit

	.failure: ; -----------------------------------------------------------
	call	popup_error

	.exit: ; --------------------------------------------------------------
	not	eax

	pop	edi
	pop	esi
	mov	esp, ebp
	pop	ebp
	ret
	
; }}}
init: ; {{{

	; initializes everything
	;
	; arguments:
	;	-
	;
	; returns:
	;	-
	; ---------------------------------------------------------------------

	pushad
	call	_sh3_init
	cmp	al, EOK
	jne	.failure

	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_secexist]
	test	al, al
	jz	.exit

	mov	ebx, patches
	.next:
	call	[ebx]
	cmp	al, EOK
	jne	.failure
	add	ebx, 4
	cmp	dword [ebx], 0
	loopne	.next
	jmp	.exit

	.failure:
	call	popup_error

	.exit:
	popad
	mov	eax, dword [ebx]
	push	dword 0x402
	jmp	[return_init]

; }}}
; sh3 functions & variables {{{
section .data
esimact:	dd	0
esimact_fn	db	"EnvSim.act", 0

; --- _sh3_get_closest_ship
;
; returns pointer to the closest ship
;
; arguments:
;	int   type
;	void *ptr
;
; returns:
;	void *ptr
;
_sh3_get_closest_ship:	dd	0x00513d20

; --- _sh3_get_message
;
; gets message id from [en|de]_menu.txt
;
; arguments:
;	int	message_id
;
; returns:
;	char*	message_string
;
_sh3_get_message:	dd	0x004ca800

section .text ; ---------------------------------------------------------------
_sh3_init:

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
; --- misc {{{
section .data
ini_plrset:		dd	0x005fed58	; playersettings.cfg
str_plrsub:		db	"PLAYER_SUBMARINE"
str_type		db	"ClassName"
str_name		db	"UnitName"
; --- popup_error {{{
section .text
popup_error:

	; Pops up a message-box which displays the error-code.
	;
	; arguments:
	;	al	error-code
	;
	; returns:
	;	eax	error-code
	;
	; ---------------------------------------------------------------------

	and	eax, EFAIL		;
	push	eax			; mask & push error-code
	push	popup_error_msg
	push	BUFSZ
	push	_buf
	call	_snprintf
	add	esp, 12			; pop all args but error-code

	push	0x10 ; MB_ICONERROR
	push	popup_error_cap
	push	_buf
	push	dword 0
	call	_MessageBoxA@16
	pop	eax			; restore error-code

	ret

; }}}
; --- patch_mem {{{
patch_mem:
	;
	; patches code in memory
	;
	; arguments:
	;	esi	code-_buffer
	;	eax	target address (for jmp/call) [opt]
	;	edi	destination in memory
	;
	; returns:
	;	eax	EOK on success
	;	eax	EMEMW on failure
	;
	; ---------------------------------------------------------------------

	push	ecx
	push	ebp
	mov	ebp, esp
	sub	esp, 12

	mov	[ebp-12], eax
	mov	[ebp- 8], esi
	mov	[ebp- 4], edi
	xor	ecx, ecx
	mov	cl, [esi]		;
	inc	esi			; first byte is code length
	mov	edi, _buf
	call	_string_cpy
	cmp	dword [ebp-12], 0	;
	je	.write			; if no target address, write as is

	mov	eax, 0xcc		;
	mov	esi, _buf		;
	call	_string_chr		; find place-holder for target address
	
	mov	eax, [ebp-12]
	sub	eax, ecx
	sub	eax, 4
	sub	eax, [ebp-4]
	mov	[ebp-12], eax

	add	edi, ecx
	mov	ecx, 4
	lea	esi, [ebp-12]
	call	_string_cpy

	.write:
	xor	eax, eax
	mov	ecx, [ebp-8]
	mov	al, [ecx]
	push	dword 0
	push	eax 
	push	_buf
	push	dword [ebp-4]
	push	dword [exeproc]
	call	_WriteProcessMemory@20

	mov	edi, [ebp-4]
	mov	esi, [ebp-8]
	mov	esp, ebp
	pop	ebp
	pop	ecx
	cmp	eax, 0
	je 	.failure

	mov	eax, EOK
	ret

	.failure:
	mov	eax, EMEMW
	ret

; }}}
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
; --- Patches {{{
section .data
patches:	dd	_ptc_version_init, \
			_ptc_smartpo_init, \
			_ptc_alertwo_init, \
			_ptc_repairt_init, \
			_ptc_nvision_init, \
			_ptc_absbrig_init, \
			_ptc_trgtrpt_init, \
			_ptc_report_init, \
			0

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

	push	esi
	push	edi
	mov	esi, ptc_version
	mov	eax, .sprntf
	mov	edi, 0x44b657
	call	patch_mem
	pop	edi
	pop	esi
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

	push	ecx
	; config-check
	push	dword 0			; push default 'No'
	push	ptc_smartpo_cfg
	push	inisec			; "PATSH3R"
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_yn]
	cmp	al, 1
	jne	.exit_ok

	; patch when moving group of crew between compartments
	mov	esi, ptc_smartpo_01
	mov	eax, 0
	mov	edi, 0x41DB25
	call	patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when moving group of crew between compartments
	mov	esi, ptc_smartpo_02
	mov	eax, 0
	mov	edi, 0x42ac2e
	call	patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when submerging
	mov	esi, ptc_smartpo_02
	mov	eax, 0
	mov	edi, 0x4376f0
	call	patch_mem
	cmp	al, EOK
	jne	.failure

	; patch when surfacing
	mov	esi, ptc_smartpo_02
	mov	eax, 0
	mov	edi, 0x4377de
	call	patch_mem
	cmp	al, EOK
	jne	.failure

	.exit_ok:
	mov	eax, EOK
	.failure:
	pop	ecx
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
ptc_alertwo_rtn		dd	0x42d097
ptc_alertwo		db	6, ASM_JMP, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

section .text
_ptc_alertwo_init:

	push	esi
	push	edi
	push	dword 0			; push default 'No'
	push	ptc_alertwo_cfg
	push	inisec			; push "PATSH3R"
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_yn]
	cmp	al, 1
	je	.go
	mov	al, EOK
	jmp	.exit

	.go:
	mov	esi, ptc_alertwo
	mov	eax, alertwo
	mov	edi, 0x42d08f	; address of interception
	call	patch_mem

	.exit:
	pop	edi
	pop	esi
	ret

alertwo:

	pushf
	pushad
	call	alertwo_findwo
	cmp	eax, -1
	je	.exit
	mov	esi, eax
	mov	edi, OFFCR_BRIDG
	mov	ecx, ebp
	call	_sh3_mvcrew

	.exit:
	popad
	popf
	mov	dword [esp+0x0c], 0
	jmp	[ptc_alertwo_rtn]
	ret

alertwo_findwo:

	; find out which officer that are to be moved to bridge
	sub	esp, 10h
	mov	dword [esp+00h], OFFCR_BQUAR
	mov	dword [esp+04h], __float32__(1.0)
	mov	dword [esp+08h], OFFCR_SQUAR
	mov	dword [esp+0ch], __float32__(1.0)
	mov	ecx, 0

	.nxt_quart:
	mov	eax, crew_size
	mul	dword [esp+ecx*08h]
	add	eax, SH3_CREWARR
	mov	ebx, eax
	cmp	dword [ebx+crew.nrcomp], -1
	je	.quar_done
	cld
	push	ecx
	mov	ecx, [ebx+crew.nrqual]
	mov	edi, ebx
	add	edi, crew.quals
	mov	eax, CREWQ_WATCH
	repne scasd
	pop	ecx
	jnz	.quar_done
	mov	edi, [ebx+crew.fatigue]
	mov	dword [esp+ecx*8+4], edi

	.quar_done:
	inc	ecx
	cmp	ecx, 1
	jle	.nxt_quart

	mov	eax, [esp+00h]
	mov	ecx, [esp+04h]
	cmp	ecx, [esp+0ch]
	cmovg	eax, [esp+08h]
	cmovg	ecx, [esp+0ch]

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
	mov	ecx, SH3_MAINCFG
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
	push	0
	push	4
	push	dword [esp+8]
	push	0x0041df76
	push	dword [exeproc]
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

	push	esi
	push	edi
	; config-check
	push	dword 0			; push default 'off' (0.0)
	push	ptc_nvision_cfg
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_flt]
	fldz
	fcomip	st0, st1
	jnz	.go
	fstp	st0
	mov	eax, EOK
	jmp	.exit

	.go:
	fstp	dword [ptc_nvision_fac]
	mov	esi, ptc_nvision
	mov	eax, _nvision
	mov	edi, [esimact]		; base of EnvSim.act
	add	edi, 0x00003c06		; offset in EnvSim.act
	call	patch_mem

	.exit:
	pop	edi
	pop	esi
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
ptc_absbrig_cfg		db	"TrueBearings",0
ptc_absbrig		db	6, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

section .text
_ptc_absbrig_init:

	push	0			; default 'No'
	push	ptc_absbrig_cfg
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_yn]
	test	eax, eax
	jnz	.go
	ret

	.go:
	mov	esi, ptc_absbrig
	mov	eax, _absbear_wo
	mov	edi, 0x00513cbf
	call	patch_mem
	cmp	eax, EOK
	jne	.exit

	mov	esi, ptc_absbrig
	mov	eax, _absbear_so
	mov	edi, 0x00513c66
	call	patch_mem

	.exit:
	ret


calc_abs_bearing:

	; converts relative bearings to absolute (true) bearings
	;
	; arguments:
	;	st0	relative bearing
	;
	; returns:
	;	st0	absolute bearing
	;
	; ---------------------------------------------------------------------
	push	eax
	mov	eax, [0x00554698]       ;
	add	eax, 100		; offset to subs heading
	fld	dword [eax]		;
	faddp				; bearing + heading (st1)
	push	dword 360		;
	fild	dword [esp]		; push 380 on FPU-stack
	add	esp, 4
	fxch
	fprem				; (heading + bearing) % 360
	fxch
	fstp	st0
	pop	eax
	ret


_absbear_wo: ; +8 _buff, +12 fmt, +16 bearing, +24 range

	push	ebp
	mov	ebp, esp

	; push (double) range on stack
	sub	esp, 8
	fld	qword [ebp+24]
	fstp	qword [esp]
	
	; calculate & push (double) absolute bearing on stack
	sub	esp, 8
	fld	qword [ebp+16]
	call	calc_abs_bearing
	fstp	qword [esp]

	; push (double) bearing on stack
	sub	esp, 8
	fld	qword [ebp+16]
	fstp	qword [esp]

	;push (char*) fmt and (char*) dst on stack
	mov	eax, [ebp+12]
	push	eax
	mov	eax, [ebp+8]
	push	eax

	call	_sprintf

	mov	esp, ebp
	pop	ebp
	ret


_absbear_so: ; [ +8 _buf, +12 fmt, +16 type, +20 speed, +24 aspect, +28 bearing, +36 range ]

	push	ebp
	mov	ebp, esp

	push	dword [ebp+36]		; push range
	sub	esp, 16
	fld	qword [ebp+28]
	fst	qword [esp]
	call	calc_abs_bearing
	fstp	qword [esp+ 8]
	push	dword [ebp+24]
	push	dword [ebp+20]
	push	dword [ebp+16]
	push	dword [ebp+12]
	push	dword [ebp+ 8]

	call	_sprintf

	mov	esp, ebp
	pop	ebp
	ret

; }}}
; --- _ptc_trgtrpt_init {{{
section .bss
ptc_trgtrpt_active		resb	1
ptc_trgtrpt_wo_msg		resd	1
ptc_trgtrpt_so_msg		resd	1

section .data
ptc_trgtrpt		db	5, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc
ptc_trgtrpt_cfg		db	"TargetReporting", 0
ptc_trgtrpt_cwo		db	"TargetReportingMessageWO", 0
ptc_trgtrpt_cso		db	"TargetReportingMessageSO", 0

section .text
_ptc_trgtrpt_init:

	push	0			; default 'No'
	push	ptc_trgtrpt_cfg
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_yn]
	test	eax, eax
	jnz	.go
	ret

	.go:
	mov	esi, ptc_trgtrpt
	mov	eax, trgtrpt_get_ship
	mov	edi, 0x0051441d
	call	patch_mem
	cmp	eax, EOK
	jnz	.exit

	mov	esi, ptc_trgtrpt
	mov	eax, trgtrpt_get_message
	mov	edi, 0x00513cb4
	call	patch_mem
	cmp	eax, EOK
	jnz	.exit

	mov	esi, ptc_trgtrpt
	mov	eax, trgtrpt_get_message
	mov	edi, 0x00513c36
	call	patch_mem
	cmp	eax, EOK
	jnz	.exit

	push	0
	push	ptc_trgtrpt_cwo
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_int]
	mov	[ptc_trgtrpt_wo_msg], eax

	push	0
	push	ptc_trgtrpt_cso
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_int]
	mov	[ptc_trgtrpt_so_msg], eax

	mov	eax, EOK

	.exit:
	ret

trgtrpt_get_so_target:

	; returns a pointer to the ship pointed to by the hydrophone
	; eax. or null if none is targeted.
	; ---------------------------------------------------------------------

	mov	eax, [0x005546c4]
	add	eax, 32
	mov	eax, [eax]
	add	eax, 24
	mov	eax, [eax]
	ret

trgtrpt_get_ship: ; +8 type, +12 *ptr

	; this function intercepts the find_closest_target-function
	;
	; if this is WO reporting and a ship is targeted with USO or
	; periscope, (or SO reporting while targeting a ship with 
	; the hydrophone). Then return a pointer to that ship, or
	; else just continue to the find_closest_target-function
	; ---------------------------------------------------------------------

	mov	eax, [esp+4]
	xor	eax, SENSOR_VISUAL
	test	eax, eax
	jnz	.try_hydro

	mov	eax, [0x005547e8]
	test	eax, eax
	jz	.closest_ship
	jmp	.exit
	
	.try_hydro:
	mov	eax, [esp+4]
	xor	eax, SENSOR_HYDRO
	test	eax, eax
	jnz	.closest_ship
	call	trgtrpt_get_so_target
	test	eax, eax
	jnz	.exit

	.closest_ship:
	jmp	[_sh3_get_closest_ship]

	.exit:
	ret	8

trgtrpt_get_message: ; +4 msg_num

	; this function intercepts the SH3 get_message-function
	;
	; if a ship is targeted by WO or SO and they are reporting
	; a ship, the msg_num gets replaced with the one given in
	; either TargetReportingMessageWO or TargetReportingMessageSO
	; before moving ahead to the original get_message-function
	; ---------------------------------------------------------------------

	; check if this is the watch officer reporting on ship?
	cmp	dword [esp+4], 4616
	jnz	.sonar                ; not wo, try sonar instead?
	cmp	dword [0x005547e8], 0 ; is a ship targeted with USO or peri?
	jz	.exit
	cmp	dword [ptc_trgtrpt_wo_msg], 0
	jz	.exit
	mov	eax, dword [ptc_trgtrpt_wo_msg]
	mov	dword [esp+4], eax
	jmp	.exit

	; check if this is the sonar guy reporting on ship?
	.sonar:
	cmp	dword [esp+4], 4912 ; nearest sond contact
	je	.report
	cmp	dword [esp+4], 4922 ; nearest warship
	jne	.exit

	.report:
	call	trgtrpt_get_so_target ;
	test	eax, eax              ; is a ship targeted with hydrophone?
	jz	.exit
	cmp	dword [ptc_trgtrpt_so_msg], 0
	jz	.exit
	mov	eax, dword [ptc_trgtrpt_so_msg]
	mov	dword [esp+4], eax

	.exit:
	jmp	[_sh3_get_message]

; }}}
; --- _ptc_report_init {{{
section .data
ptc_report:		db	6, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_RET
ptc_report_cfg:		db	"Patsh3rBDU", 0
ptc_report_rsm		dd	0x004b79c0

section .text
_ptc_report_init:

	push	0	; default 'No'
	push	ptc_report_cfg
	push	inisec
	mov	ecx, SH3_MAINCFG
	call	[_sh3_cfg_yn]
	test	eax, eax
	jz	.exit

	mov	esi, ptc_report
	mov	edi, 0x00514273
	mov	eax, _report_send
	call	patch_mem

	.exit:
	ret

report_inception:

	push	ecx
	call	_report_send
	pop	ecx
	jmp	[ptc_report_rsm]	; resume program flow

; }}}
; }}}

; Notes {{{
;
; TODO:
;	- when submerging/surfacing, if radio/sonar spot is empty; move
;         sonar/radio guy there
;
;	Patrol report procedure: 0x004b79c0
;
;	0x005f5f60		: Captains name?
;	0x00554694		: linked list of known ships (i.e. not unknown)?
;	0x005547e8		: visual targeted ship
;
;	[sub(?)] : 0x00554698
;			: +  48 = hour of day (word)
;			; +  50 = minute of day (word)
;			: +  52 = time of day in seconds 
;			: + 100 = heading (float)
;			: + 104 = speed (float)
;			: + 244 = pointer to coordinates
;				+   8 = Longitud
;				+  16 = Latitud
;
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
; Ranks:
;
;	00	Seaman
;	01	Senior Seaman
;	02	Chief Seaman
;	03	Warrant Officer
;	04	Senior Warrant Officer
;	05	Chief Sr. W. Officer
;	06	Sub-Lieutenant
;	
;	10	Lieutenant Jr.
;	11	Lieutenant Sr.
;	12	Lieutenant Commander
;	13	Commander


; }}}

