; vim: fdm=marker

%include "syms.asm"

%define DLL_ATTACH	0x01

section .bss ; ----------------------------------------------------------------

_proc		resd	1
_hsie		resb	1	; hsie-patched exe?
_buf		resb	1024


section .data ; ---------------------------------------------------------------

err_caption:	db	"patSH3r Error", 0
err_message:	db	"Failed with error code: %d", 0
ptc_init:	db	7, ASM_NOOP, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_RET

inisec:		db	"PATSH3R", 0
str_smartpo:	db	"SmarterPettyOfficers", 0
str_alertwo:	db	"AlertWatchOfficer", 0


section .text ; ---------------------------------------------------------------

global _DllMain

extern _GetCurrentProcess@0

; --- _DllMain {{{
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
	mov	[_proc], eax

	mov	eax, ptc_init ; insert patSH3r-init process
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
;
; initializes everything
;
; arguments:
;	-
;
; returns:
;	-
;
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
	mov	ecx, [_maincfg]
	call	[_fmgr_get_yn]
	cmp	al, 1
	jne	.pass_smartpo
	call	_ptc_smartpo_init
	cmp	al, EOK
	jne	.failure

	.pass_smartpo:
	push	dword 0		; _alertwo_init?
	push	str_alertwo
	push	inisec
	mov	ecx, [_maincfg]
	call	[_fmgr_get_yn]
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
	push	err_message
	push	BUFSZ
	push	_buf
	call	_snprintf
	add	esp, 12			; pop all args but error-code

	push	0x10 ; MB_ICONERROR
	push	err_caption
	push	_buf
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
	mov	edi, _buf
	mov	al, [eax]
	and	eax, 0xff	; from now on, eax will string length + 1
	mov	ecx, eax
	rep	movsb

	cmp	dword [esp], 0	;
	je	.write		; if no target address, don't append it
	push	eax
	mov	edi, _buf	;
	mov	ecx, eax	;
	mov	al, 0xcc	;
	repne	scasb		; find place-holder for target address
	dec	edi
	pop	eax

	mov	ecx, 4
	mov	esi, esp
	push	eax
	mov	eax, edi	   ; calculate op-codes before place-holder
	sub	eax, _buf	   ;
	add	eax, 4		   ; add pointer size
	sub	dword [esi], edx   ; make address relative to edx
	sub	dword [esi], eax   ;
	pop	eax
	rep	movsb

	.write:
	push	dword 0
	push	eax
	push	_buf
	push	edx
	push	dword [_proc]
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

