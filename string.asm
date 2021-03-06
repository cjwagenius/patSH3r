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

global _string_chr
global _string_cmp
global _string_cpy
global _string_find
global _string_len

section .text
_string_chr: ; {{{ str: esi, char: eax -> offset: ecx
	;
	; Searches the string @ esi for the char in eax
	; Returns the offset in string where found, or -1 in ecx
	;
	push	edi
	test	ecx, ecx
	jnz	.chr
	call	_string_len
	.chr:
	mov	edi, esi
	repne scasb
	mov	ecx, edi
	sub	ecx, esi
	dec	ecx
	pop	edi
	ret

; }}}
_string_cmp: ; {{{ edi, esi, ecx -> eax, ecx
	push	esi
	push	edi
	test	ecx, ecx
	jnz	.cmp
	call	_string_len
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
_string_cpy: ; {{{ edi, esi, ecx -> len: ecx
	push	esi
	push	edi
	sub	esp, 4
	mov	[esp], edi
	test	ecx, ecx
	jnz	.setup
	call	_string_len
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
_string_find: ; {{{ edi, esi, ecx -> ecx
	push	esi
	push	edi
	push	eax
	sub	esp, 8
	call	_string_len
	mov	[esp], ecx
	mov	esi, edi
	call	_string_len
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
	call	_string_cmp
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
_string_len: ; {{{ esi -> ecx

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
