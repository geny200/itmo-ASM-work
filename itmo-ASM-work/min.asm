global _min_ubytes				; 

section .data
n_i:		db 32

section .code
extern	_printf2
_min_ubytes:
	mov		ebx, dword[esp + 4]
	mov		ecx, dword[esp + 8]
	sub		ecx, 8
	movq	mm1, qword[ecx + ebx]


loop:
	sub		ecx, 8
	movq	mm2, qword[ecx + ebx]
	movq	mm0, mm1
	pcmpgtb mm0, mm2
	pand	mm1, mm0
	pandn	mm0, mm2
	por 	mm1, mm0

	jnz		loop

	mov		ecx, dword[n_i]
loop_unpack:
	movq	mm2, mm1	; mm1 - 8 bytes
	movq	mm0, mm1	; mm0 = mm2 = mm1
	psrlq	mm1, 32

	pcmpgtb mm0, mm1	; mm0 = mask
	pand	mm2, mm0	
	pandn	mm0, mm1
	por		mm2, mm0	; combine

	movq	mm1, mm2	; mm1 - 8 bytes
	movq	mm0, mm1	; mm0 = mm2 = mm1
	psrlq	mm1, 16

	pcmpgtb mm0, mm1	; mm0 = mask
	pand	mm2, mm0	
	pandn	mm0, mm1
	por		mm2, mm0	; combine

	movq	mm1, mm2	; mm1 - 8 bytes
	movq	mm0, mm1	; mm0 = mm2 = mm1
	psrlq	mm1, 8

	pcmpgtb mm0, mm1	; mm0 = mask
	pand	mm2, mm0	
	pandn	mm0, mm1
	por		mm2, mm0	; combine

	; copy to eax 1 byte
	movd 	eax, mm1
	emms
	ret
