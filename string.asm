; vim: ft=nasm fdm=marker

section .text
string_chr: ; {{{ str: esi, char: eax -> offset: ecx
	;
	; Searches the string @ esi for the char in eax
	; Returns the offset in string where found, or -1 in ecx
	;
	push	edi
	test	ecx, ecx
	jnz	.chr
	call	string_len
	.chr:
	mov	edi, esi
	repne scasb
	mov	ecx, edi
	sub	ecx, esi
	dec	ecx
	pop	edi

; }}}
string_cmp: ; {{{ edi, esi, ecx -> eax, ecx
	push	esi
	push	edi
	test	ecx, ecx
	jnz	.cmp
	call	string_len
	.cmp:
	rep cmpsb
	mov	ecx, edi
	sub	ecx, [esp]
	dec	ecx
	xor	eax, eax
	mov	al, [edi-1]
	sub	al, [esi-1]
	cbw
	cwde
	pop	edi
	pop	esi
	ret

; }}}
string_cpy: ; {{{ edi, esi, ecx -> len: ecx
	push	esi
	push	edi
	sub	esp, 4
	mov	[esp], edi
	test	ecx, ecx
	jnz	.setup
	call	string_len
	.setup:
	cld
	cmp	edi, esi
	jle	.cpy
	push	esi
	add	esi, ecx
	cmp	edi, esi
	pop	esi
	jg	.cpy
	add	[esp], ecx
	add	esi, ecx
	dec	esi
	add	edi, ecx
	dec	edi
	std

	.cpy:
	rep movsb
	cmp	edi, [esp]
	jg	.exit
	xchg	edi, [esp]
	dec	edi
	.exit:
	sub	edi, [esp]
	mov	ecx, edi
	add	esp, 4
	pop	edi
	pop	esi
	ret
; }}}
string_find: ; {{{ edi, esi, ecx -> ecx
	push	esi
	push	edi
	push	eax
	sub	esp, 8
	call	string_len
	mov	[esp], ecx
	mov	esi, edi
	call	string_len
	sub	ecx, [esp]
	.shr:
	mov	esi, [esp+16]
	mov	al, [esi]
	repne scasb
	test	ecx, ecx
	jnz	.next
	dec	ecx
	jmp	.exit

	.next:
	mov	[esp+4], ecx
	mov	ecx, [esp]
	dec	edi
	mov	[esp], edi
	call	string_cmp
	test	eax, eax
	jz	.found
	mov	edi, [esp]
	inc	edi
	mov	ecx, [esp+4]
	test	ecx, ecx
	jnz	.shr
	jmp	.exit
	.found:
	mov	ecx, edi
	sub	ecx, [esp+12]
	.exit:
	add	esp, 8
	pop	eax
	pop	edi
	pop	esi
	ret

; }}}
string_len: ; {{{ esi -> ecx
	push	edi
	push	eax
	mov	edi, esi
	mov	ecx, -1
	xor	eax, eax
	cld
	repne scasb
	add	ecx, 2		; don't count -1 & '\0'
	sub	eax, ecx
	mov	ecx, eax
	pop	eax
	pop	edi
	ret
; }}}
