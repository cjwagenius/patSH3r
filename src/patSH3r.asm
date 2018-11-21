
%include "syms.asm"

%define DLL_ATTACH	0x01

extern _GetCurrentProcess@0

section .bss ; ----------------------------------------------------------------

_proc		resd	1
_hsie		resb	1	; hsie-patched exe?
_buf		resb	1024


section .data ; ---------------------------------------------------------------

err_caption:	db	"patSH3r Error", 0
err_message:	db	"Failed with error code: %d", 0
ptc_init:	db	7, ASM_NOOP, ASM_CALL, 0xcc, 0xcc, 0xcc, 0xcc, ASM_RET


section .text ; ---------------------------------------------------------------

global _DllMain

_DllMain:

	xor	eax, eax
	cmp	dword [esp+0x08], DLL_ATTACH ; exit if not attaching
	jne	.exit

	call	_GetCurrentProcess@0
	mov	[_proc], eax

	; insert init process
	mov	eax, ptc_init
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
	

_patSH3r_init:

	call	_sh3_init
	cmp	al, EOK
	jne	.failure

	call	_config_init
	cmp	al, EOK
	jne	.failure

	ret

	.failure:
	call	_popup_error
	ret


_popup_error:

	and	eax, EFAIL		;
	push	eax			; mask & push error code
	push	err_message
	push	BUFSZ
	push	_buf
	call	_snprintf
	add	esp, 0x0c		; pop all args but error code

	push	0x10 ; MB_ICONERROR
	push	err_caption
	push	_buf
	push	dword 0
	call	_MessageBoxA@16
	pop	eax			; restore error code

	ret


_patch_mem:

	; patch memory
	;
	; arguments:
	;	eax	buffer
	;	ecx	target address (for jmp/call) [opt]
	;	edx	destination in memory
	;

	pushf
	push	edi
	push	esi
	push	ecx
	cld
	mov	esi, eax
	inc	esi		; first byte is string length
	mov	edi, _buf
	mov	al, [eax]
	inc	al
	and	eax, 0xff	; from now on, eax will string length + 1
	mov	ecx, eax
	rep	movsb

	cmp	dword [esp], 0	; if no target address, don't append it
	je	.write
	push	eax
	mov	edi, _buf	; find place-holder for pointer
	mov	ecx, eax
	mov	al, 0xcc
	repne	scasb
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


