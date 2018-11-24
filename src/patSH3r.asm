; vim: fdm=marker

%include "syms.asm"

global _DllMain


; --- _DllMain {{{
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
	jne	.exit				; exit if not attaching

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

	.failure:
	call	_popup_error

	.exit:
	cmp	al, EOK
	sete	al

	ret
	
; }}}

; --- _patSH3r_init {{{
section .data
inisec:		db	"PATSH3R", 0
str_smartpo:	db	"SmarterPettyOfficers", 0
str_alertwo:	db	"AlertWatchOfficer", 0
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

	push	dword 0		; _smartpo_init?
	push	str_smartpo
	push	inisec
	mov	ecx, [maincfg]
	call	[_sh3_cfg_yn]
	cmp	al, 1
	jne	.pass_smartpo
	call	_ptc_smartpo_init
	cmp	al, EOK
	jne	.failure

	.pass_smartpo:
	push	dword 0		; _alertwo_init?
	push	str_alertwo
	push	inisec
	mov	ecx, [maincfg]
	call	[_sh3_cfg_yn]
	cmp	al, 1
	jne	.pass_alertwo
	call	_ptc_alertwo_init
	cmp	al, EOK
	jne	.failure

	.pass_alertwo:

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

; sh3 {{{
section .data
crew_array:	dd	0x005f6238		; offset to the crew array
maincfg		dd	0x00544698		; handle to main.cfg
fmgrdll:	dd	0
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
_sh3_cfg_dbl		dd	0x00005610
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
	add	[_sh3_cfg_dbl], eax
	add	[_sh3_cfg_str], eax

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
;	remove qual-check
;
section .data
ptc_smartpo_01:	db	4, 0x39, 0xc0, ASM_NOOP, ASM_NOOP
ptc_smartpo_02: db	4, ASM_NOOP, ASM_NOOP, ASM_NOOP, ASM_NOOP

section .text
_ptc_smartpo_init:

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

	mov	eax, EOK
	ret

	.failure:
	ret

; }}}
; --- _ptc_alertwo_init {{{
;
; grad check surfacing @ 0x004376e0
; 
;
section .data
alertwo_rtnaddr		dd	0x0042d097
ptc_alertwo		db	6, ASM_JMP, 0xcc, 0xcc, 0xcc, 0xcc, ASM_NOOP

_ptc_alertwo_init:

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
	jmp	[alertwo_rtnaddr]
	ret

alertwo_findwo:

	sub	esp, 10h
	mov	dword [esp + 00h], OFFCR_BQUAR
	mov	dword [esp + 04h], __float32__(1.0)
	mov	dword [esp + 08h], OFFCR_SQUAR
	mov	dword [esp + 0ch], __float32__(1.0)
	mov	ecx, 0

	.nxt_quart:
	mov	eax, crew_size
	mul	dword [esp + ecx * 08h]
	add	eax, [crew_array]
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
; }}}
