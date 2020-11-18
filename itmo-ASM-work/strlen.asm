global my_strlen	


section .code
my_strlen:
	xorps	xmm1, xmm1
	xorps	xmm0, xmm0
	mov		rax, rcx
	mov		rbx, rcx

	sub		rax, 16
loop:
	add		rax, 16
	pcmpistri xmm1, [rax], 8
	jnz		loop

	add		rax, rcx
	sub		rax, rbx
	ret

