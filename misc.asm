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

%include "misc.inc"

section .bss ; ----------------------------------------------------------------
_buf:			resb	BUFSZ	; general working buffer

; --- memory functions {{{
;
; memory allocations are stored in an array that will be freed at exit. The
; array works like a LIFO-stack. Allocations are being appended to the array,
; while freeing are always being always done to the last item in the array.
;
;		   ! Does not handle memory allocation error !
;
extern _free
extern _realloc

section .data
mallocs:		dd	0 ; array of memory allocations
mallocs_mem:		dd	0 ; num pointers allocated for 'mallocs'
mallocs_len:		dd	0 ; num pointer used in 'mallocs'

section .text
malloc: ; {{{ In: ecx = size_to_allocate, Out: eax = pointer
	;
	; allocates new memory.
	; 
	push	edx
	push	ecx
	mov	ecx, [mallocs_len]
	inc	ecx
	cmp	ecx, dword [mallocs_mem]	; if mallocs_mem doesn't need
	jb	.alloc				; to be expanded

	; expand mallocs-array
	add	dword [mallocs_mem], 8
	mov	eax, [mallocs_mem]
	mov	edx, 4
	mul	edx
	push	eax
	push	dword [mallocs]
	call	_realloc
	add	esp, 8
	mov	[mallocs], eax

	.alloc:
	; size already on stack, so we don't have to push it
	push	dword 0
	call	_realloc
	add	esp, 4
	mov	ecx, dword [mallocs_len]
	mov	ecx, dword [mallocs+ecx*4]
	mov	[ecx], eax
	inc	dword [mallocs_len]
	add	esp, 4	; removed popped ecx

	pop	edx
	ret

; }}}
free: ; {{{ In: None, Out: none
      ;
      ; frees the last made allocation
      ;
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

