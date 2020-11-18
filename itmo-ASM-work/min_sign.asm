global _max_sbytes				

section .data
n_i:		db 32
n_neg:		dq 0x8080808080808080

section .code
extern	_printf2
_max_sbytes:
	mov		ebx, dword[esp + 4]
	mov		ecx, dword[esp + 8]
	sub		ecx, 8
	movq	mm1, qword[ecx + ebx]
	pxor	mm1, qword[n_neg]
loop:
	sub		ecx, 8
	movq	mm2, qword[ecx + ebx]
	pxor	mm2, qword[n_neg]
	psubsb	mm1, mm2
	paddsb  mm1, mm2

	jnz		loop

loop_unpack:
	movq	mm2, mm1	; mm1 - 8 bytes
	psrlq	mm1, 32

	psubsb	mm1, mm2
	paddsb  mm1, mm2

	movq	mm2, mm1	; mm1 - 8 bytes
	psrlq	mm1, 16

	psubsb	mm1, mm2
	paddsb  mm1, mm2

	movq	mm2, mm1	; mm1 - 8 bytes
	psrlq	mm1, 8

	psubsb	mm1, mm2
	paddsb  mm1, mm2

	; copy to eax 1 byte
	pxor	mm1, qword[n_neg]
	movd 	eax, mm1
	emms
	ret
