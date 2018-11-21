; vim: fdm=marker

%include "syms.asm"

;global _ptc_version_init

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
;	inserting cmp eax, eax at 0x41DB25 disables the qual-check
;
section .data
ptc_smartpo:	db	4, 0x39, 0xc0, ASM_NOOP, ASM_NOOP

section .text
_ptc_smartpo_init:

	mov	eax, ptc_smartpo
	mov	ecx, 0
	mov	edx, 0x41DB25
	call	_patch_mem

	ret

