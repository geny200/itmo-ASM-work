global _arctang					; float arctang(float x, uint32_t n)

section .code
_arctang:							
	mov		ecx, dword[esp + 8] ; st5 - cnt
	fld		dword [esp + 4]     ; st4 - res
	fld1						; st3 - i
	fld1						; st2 - 2
	fadd	st0, st0
	fld		st2 			    ; st1 - x^2
	fmul	st0, st0
	fld		st3					; st0 - x^2n

	test	ecx, ecx			; cnt == 0
	jz		end_teilor			; 
teilor:
	call	mul_with_dive		; push (local = (x^2n *= x^2) / (i += 2))
	fchs						; local = -local
	fadd	st5, st0			; res += local
	fcomp							; pop (local)

	call	mul_with_dive		; push (local = (x^2n *= x^2) / (i += 2))
	fadd	st5, st0			; res += local
	fcomp						; pop (local)

	sub		ecx, 2
	jnz		teilor				; if (cnt != 0) go to teilor


end_teilor:
	fcompp						; clean FPU stack
	fcompp
	xor		eax, eax
	ret

mul_with_dive:
	fmul	st0, st1			; st0 (x^2n) *= x^2

	fxch	st2
	fadd	st3, st0			; st3 (i) += 2
	fxch	st2

	fldz						; st0 (local) = 0
	fadd	st0, st1			; st0 (local) = x^2n
	fdiv	st0, st4			; st0 (local) /= i
	ret