; vim:fdm=marker:ft=nasm

%include "syms.asm"

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
	add	eax, [_crewofs]
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
