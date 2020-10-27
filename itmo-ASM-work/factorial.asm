global _fact				; void fact(uint32_t x)

section .data
f_print:	db "double num: %f;", 10, 0

section .code
extern	_printf2
_fact:
	mov		ebx, dword[esp + 4]
	fld1
	fld1
	fld1
fact:
	fmul	st1, st0
	fadd	st0, st2
	sub		ebx, 1
	jnz		fact

	ffree	st2
	fcomp	
	sub		esp, 8

	fstp	qword [esp]

	push	f_print
	call	_printf2
	add		esp, 12
	xor		eax, eax

	ret