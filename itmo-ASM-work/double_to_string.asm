global dbl2str

default rel
bits 64

; some constants
section .rdata
shift52_1		dq 10000000000000h
nan:			db "NaN", 0
inf:			db "Inf", 0
zero:			db "0.0e0", 0
ten:			dq 10
sign_char:		db "+-"
pow5iv_table:	dq 1, 2305843009213693952, 5955668970331000884, 1784059615882449851, 8982663654677661702, 1380349269358112757, 7286864317269821294, 2135987035920910082, 7005857020398200553, 1652639921975621497, 17965325103354776697, 1278668206209430417, 8928596168509315048, 1978643211784836272, 10075671573058298858, 1530901034580419511, 597001226353042382, 1184477304306571148, 1527430471115325346, 1832889850782397517, 12533209867169019542, 1418129833677084982, 5577825024675947042, 2194449627517475473, 11006974540203867551, 1697873161311732311, 10313493231639821582, 1313665730009899186, 12701016819766672773, 2032799256770390445
pow5iv_off_table: dd 54544554h, 04055545h, 10041000h, 00400414h, 40010000h, 41155555h, 00000454h, 00010044h, 40000000h, 44000041h, 50454450h, 55550054h, 51655554h, 40004000h, 01000001h, 00010500h, 51515411h, 05555554h, 00000000h
pow5_table:		dq 1, 5, 25, 125, 625, 3125, 15625, 78125, 390625, 1953125, 9765625, 48828125, 244140625, 1220703125, 6103515625, 30517578125, 152587890625, 762939453125, 3814697265625, 19073486328125, 95367431640625, 476837158203125, 2384185791015625, 11920928955078125, 59604644775390625, 298023223876953125

pow5_off_table:	dd 00000000h, 00000000h, 00000000h, 00000000h, 40000000h, 59695995h, 55545555h, 56555515h, 41150504h, 40555410h, 44555145h, 44504540h, 45555550h, 40004000h, 96440440h, 55565565h, 54454045h, 40154151h, 55559155h, 51405555h, 00000105h
pow5sp_table	dq 0, 1152921504606846976, 0, 1490116119384765625, 1032610780636961552, 1925929944387235853, 7910200175544436838, 1244603055572228341, 16941905809032713930, 1608611746708759036, 13024893955298202172, 2079081953128979843, 6607496772837067824, 1343575221513417750, 17332926989895652603, 1736530273035216783, 13037379183483547984, 2244412773384604712, 1605989338741628675, 1450417759929778918, 9630225068416591280, 1874621017369538693, 665883850346957067, 1211445438634777304, 14931890668723713708, 1565756531257009982

; some vars
section .data
sign:			db 0
matissa:		dq 0
exp:			dq 0
mask_matissa:	dq 000FFFFFFFFFFFFFh
mask_exp:		dq 7FF0000000000000h
tmp_str:		db "00000000000000000000000000000000000"
output			dq 0
vp:				dq 0
vr:				dq 0
vm:				dq 0
var:			dq 0
even:			db 0

section .code
; rcx - *double
; rdx - buffer
; free - r8-r11

dbl2str:
	push	rdi
	push	rsi

	mov		rdi, rdx
	mov		r8, [rcx]
	mov		r9, [rcx]
	mov		r10, [rcx]

	shr		r8, 63
	and		r9, [mask_matissa]
	shr		r10, 52
	and		r10, 7FFh
	
	mov		rax, r9
	or		rax, r10
	jz		simple_out

	cmp		r10, 7FFh
	je		simple_out

	mov		rcx, r10
	neg		rcx
	add		rcx, 1075

	;sub		r11, 1075

	cmp		rcx, 0
	jl		double_out

	cmp		rcx, 52
	jg		double_out			; 0<=(-exp + 1075)<=52

	mov		rax, 1
	shl		rax, cl		
	sub		rax, 1				;mask

	mov		r11, 10000000000000h
	or		r11, r9				; (1 << 52) | matissa
	and		rax, r11			; mask & (..)

	jnz		double_out

	shr		r11, cl				
	mov		r9, r11
	xor		r10, r10			;exp = 0
	jmp		integer_out

;------------------------------double range------------------
double_out:
; r8 - sign
; r9 - matissa
; r10 - exp
; rdi - buffer
; rax, rcx, rdx, r11, rsi - free
; save rbx, rbp, r12-r15
	push	r12
	push	r13
	push	r14
	push	r15 
	push	rbx

	test	r9, 1	; matissa - even?
	setz	bl
	mov		byte [even], bl
	mov		byte [sign], r8b	;save sign
	mov		[output], rdi

	mov		r11, 1
	cmp		r10, 1
	jle		shift_set

	test	r9, r9
	jnz		shift_set
	xor		r11, r11

shift_set:
; r11 = matissa != 0 || exp <= 1
	test	r10, r10
	jne		exp_not_zero
	
	mov		r10, 1076
	neg		r10
	jmp		step3

exp_not_zero:
	sub		r10, 1077
	or		r9, qword [shift52_1] ; | (1<<52)

step3:
	cmp		r10, 0
	jl		exp_negate
	
; r8 - sign (free)
; r9 - m2 matissa
; r10 - e2 exp
; r12 - q = log10Pow2(e2) - (e2 > 3)
; r11 - shift
	xor		rcx, rcx
	mov		r12, r10
	cmp		r12, 3
	setg	cl

	imul	r12, 78913
	shr		r12, 18
	sub		r12, rcx

	mov		r15, r12	;i
	
;pow5iv:
; r15 - i
; optimize (i + 26 - 1) / 26 ; 26 - array size
	xor		rdx, rdx
	mov		eax, 4EC4EC4Fh
	mov		rcx, r15
	add		rcx, 25				
	mul		ecx
	shr		rdx, 3

	imul	rdi, rdx, 26	
	add		rdx, rdx
	mov		rax, rdx
	inc		rax 

	lea		rsi, [pow5iv_table] 
	lea		r13, [rsi + 8 * rax]
	lea		r14, [rsi + 8 * rdx]

	mov		rbx, rdi
	sub		rbx, r15			;offset
	jnz		pow5iv_with_off	

; offset == 0
	mov		r14, [r14]			; first
	mov		r13, [r13]			; second
	xchg	r13, r14
	jmp		pow5iv_exit

pow5iv_with_off:
	lea		rsi, [pow5_table]
	mov		r8, [rsi + rbx * 8] 

	mov		rax, [r13]
	mul		r8
	mov		rbx, rax
	mov		r13, rdx

	mov		rax, [r14]
	dec		rax
	mul		r8
	add		rbx, rdx
	mov		r14, rax

	cmp		rbx, rdx
	jae		pow5iv_no_over
	inc		r13

pow5iv_no_over:
	xor		r8, r8
	xor		rcx, rcx

	imul	r8, rdi, 1217359
	shr		r8, 19

	imul	rcx, r15, 1217359
	shr		rcx, 19
	sub		r8, rcx

	mov		rax, r15
	shr		rax, 4
	and		r15, 15

	lea		rsi, [pow5iv_off_table]
	mov		edi, [rsi + rax * 4]

	mov		rax, r15
	mov		rcx, r8
	shrd	r14, rbx, cl
	mov		rcx, rax
	add		rcx, rcx

	shr		rdi, cl
	mov		rcx, r8
	and		rdi, 3
	inc		rdi
	add		r14, rdi
	shrd	rbx, r13, cl
	xchg	rbx, r14
	xchg	r13, rbx

pow5iv_exit:
;duplicate - 1
; r9 - m2 matissa
; r10 - e2 exp -> mem
; r11 - shift
; r12 - q = ln10p5(-exp) - (-exp > 1)
; r13 - first
; r14 - second
	
	mov		r15, r12
	imul	r15, 1217359
	shr		r15, 19
	inc		r15

	add		r15, 124
	add		r15, r12
	sub		r15, r10

	mov		[exp], r12
	mov		[var], r12

;mul_shift
; r9 - matissa
; r11 - shift
; r13 - first
; r14 - second
; r15 - j
	lea		r12, [4 * r9]
	lea		r8, [r12 + 2]

;shift right
	mov		rax, r14		;second
	mul		r8
	mov		r10, rdx
	mov		rcx, rax

	mov		rax, r13		;first
	mul		r8
	lea		rax, [rdx + rcx]

	cmp		rax, rdx
	jae		shift_no_over_1_
	inc		r10

shift_no_over_1_:
	mov		rbx, r15
	sub		rbx, 64
	movzx	ecx, bl
	shrd	rax, r10, cl
	mov		[vp], rax

;shift left
	mov		r8, r12
	sub		r8, r11
	dec		r8

	mov		rax, r14		;second
	mul		r8
	mov		r10, rdx
	mov		rcx, rax

	mov		rax, r13		;first
	mul		r8
	lea		r8, [rdx + rcx]
	cmp		r8, rdx
	jae		shift_no_over_2_
	inc		r10

shift_no_over_2_:
	movzx	ecx, bl
	shrd	r8, r10, cl
	mov		[vm], r8

;shift center
	mov		rax, r14		;second
	mul		r12
	mov		r10, rdx
	mov		r8, rax

	mov		rax, r13		;first
	mul		r12
	lea		rax, [rdx + r8]
	cmp		rax, rdx
	jae		shift_no_over_3_
	inc		r10
	
shift_no_over_3_:
	shrd	rax, r10, cl
	xchg	r14, rax

; r9 - matissa
; r11 - shift
; r14 - vr
; r12 <- q
; r13 <- vm
; r15 <- vp
; r8 <- flags

	mov		r12, [var]
	mov		r13, [vm]
	mov		r15, [vp]
	
	xor		r8, r8

	cmp		r12, 21
	jg		step4

	lea		rbx, [4 * r9]
	mov		rcx, rbx
	
	mov		rax, 0CCCCCCCCCCCCCCCDh
	mul		rbx
	shr		rdx, 2
	lea		rax, [rdx + 4 * rdx]
	
	sub		rbx, rax	
	test	rbx, rbx
	jnz		exp_pos_check_even

; rcx - 4 * matissa
	xor		rbx, rbx
	dec		rbx
	mov		r10, 0CCCCCCCCCCCCCCCDh
	mov		r8, rcx

loop_div5_1:
	inc		rbx
	mov		rcx, r8
	mov		rax, r10
	mul		r8
	shr		rdx, 2

	mov		r8, rdx
	lea		eax, [r8 + r8 * 4]
	cmp		ecx, eax
	je		loop_div5_1

	xor		r8, r8
	cmp		rbx, r12
	setge	r8b
	shl		r8, 1
	jmp		step4

exp_pos_check_even:
	test	r9, 1	;matissa - even?
	jnz		exp_pos_not_even
	
	dec		rcx
	sub		rcx, r11
; rcx - 4 * matissa - 1 - shift

	xor		rbx, rbx
	dec		rbx
	mov		r10, 0CCCCCCCCCCCCCCCDh
	mov		r8, rcx

loop_div5_2:
	inc		rbx
	mov		rcx, r8
	mov		rax, r10
	mul		r8
	shr		rdx, 2

	mov		r8, rdx
	lea		eax, [r8 + r8 * 4]
	cmp		ecx, eax
	je		loop_div5_2

	xor		r8, r8
	cmp		rbx, r12
	setge	r8b
	jmp		step4

exp_pos_not_even:
	add		rcx, 2
; rcx - 4 * matissa + 2

	xor		rbx, rbx
	dec		rbx
	mov		r10, 0CCCCCCCCCCCCCCCDh
	mov		r8, rcx

loop_div5_3:
	inc		rbx
	mov		rcx, r8
	mov		rax, r10
	mul		r8
	shr		rdx, 2

	mov		r8, rdx
	lea		eax, [r8 + r8 * 4]
	cmp		ecx, eax
	je		loop_div5_3

	xor		r8, r8
	cmp		rbx, r12
	setge	r8b

	sub		r15, r8
	xor		r8, r8
	jmp		step4

exp_negate:
; r8 - sign (free)
; r9 - m2 matissa
; r10 - e2 exp
; r12 - q = log10pow5(-exp) - (-exp > 1)
; r11 - shift
	xor		rcx, rcx
	mov		r12, r10
	neg		r12
	cmp		r12, 1
	setg	cl
	imul	r12, 732923
	shr		r12, 20
	sub		r12, rcx
	
	mov		r15, r12
	add		r15, r10
	neg		r15			; i

;pow5
; r9-12 - busy
; r15 - i
; optimize (i + 25) / 26 ; 26 - array size
	xor		rdx, rdx
	mov		eax, 4EC4EC4Fh
	mov		rcx, r15
	mul		ecx
	shr		rdx, 3
	imul	rdi, rdx, 26	

	add		rdx, rdx
	mov		rax, rdx
	inc		rax 

	lea		rsi, [pow5sp_table] 
	lea		r13, [rsi + 8 * rax]
	lea		r14, [rsi + 8 * rdx]

	mov		rbx, r15
	sub		rbx, rdi			;offset
	jnz		pow5_with_off	

;offset == 0
	mov		r14, [r14]			; first
	mov		r13, [r13]			; second
	xchg	r13, r14
	jmp		pow5_exit

pow5_with_off:
	lea		rsi, [pow5_table]
	mov		r8, [rsi + rbx * 8] 

	mov		rax, [r13]
	mul		r8
	mov		rbx, rax
	mov		r13, rdx

	mov		rax, [r14]
	mul		r8
	add		rbx, rdx
	mov		r14, rax

	cmp		rbx, rdx
	jae		pow5_no_over
	inc		r13

pow5_no_over:
	xor		r8, r8
	xor		rcx, rcx

	imul	r8, rdi, 1217359
	shr		r8, 19

	imul	rcx, r15, 1217359
	shr		rcx, 19

	sub		rcx, r8
	mov		r8, rcx

	mov		rax, r15
	shr		rax, 4
	and		r15, 15

	xor		rdi, rdi
	lea		rsi, [pow5_off_table]
	mov		edi, [rsi + rax * 4]

	mov		rax, r15
	shrd	r14, rbx, cl
	mov		rcx, rax
	add		rcx, rcx

	shr		rdi, cl
	mov		rcx, r8
	and		rdi, 3
	add		r14, rdi
	shrd	rbx, r13, cl
	xchg	rbx, r14
	xchg	r13, rbx

pow5_exit:
; duplicate - 2
; r9 - m2 matissa
; r10 - e2 exp -> mem
; r11 - shift
; r12 - q = log10pow5(-exp) - (-exp > 1)
; r13 - first
; r14 - second
	
	mov		r15, r12
	add		r15, r10
	neg		r15			; i
	
	imul	r15, 1217359
	shr		r15, 19
	inc		r15
	
	sub		r15, 125	; k
	sub		r15, r12
	neg		r15			; j
	
	add		r10, r12
	mov		[exp], r10
	mov		[var], r12

;mul_shift:
; r9 - matissa
; r11 - shift
; r13 - first
; r14 - second
; r15 - j
	lea		r12, [4 * r9]
	lea		r8, [r12 + 2]

;shift right
	mov		rax, r14		;second
	mul		r8
	mov		r10, rdx
	mov		rcx, rax

	mov		rax, r13		;first
	mul		r8
	lea		rax, [rdx + rcx]

	cmp		rax, rdx
	jae		shift_no_over_1
	inc		r10

shift_no_over_1:
	mov		rbx, r15
	sub		rbx, 64
	movzx	ecx, bl
	shrd	rax, r10, cl
	mov		[vp], rax

;shift left
	mov		r8, r12
	sub		r8, r11
	dec		r8

	mov		rax, r14		;second
	mul		r8
	mov		r10, rdx
	mov		rcx, rax

	mov		rax, r13		;first
	mul		r8
	lea		r8, [rdx + rcx]

	cmp		r8, rdx
	jae		shift_no_over_2
	inc		r10

shift_no_over_2:
	movzx	ecx, bl
	shrd	r8, r10, cl
	mov		[vm], r8

;shift center
	mov		rax, r14		;second
	mul		r12
	mov		r10, rdx
	mov		r8, rax

	mov		rax, r13		;first
	mul		r12
	lea		rax, [rdx + r8]
	cmp		rax, rdx
	jae		shift_no_over_3
	inc		r10
	
shift_no_over_3:
	shrd	rax, r10, cl
	xchg	r14, rax

; r9 - matissa
; r11 - shift
; r14 - vr
; r12 <- q
; r13 <- vm
; r15 <- vp
; r8 <- flags
	
	mov		r12, [var]
	mov		r13, [vm]
	mov		r15, [vp]
	
	xor		r8, r8

	cmp		r12, 1
	jg		neg_exp_more_1

	mov		r8, 2
	test	r9, 1	;matissa - even?
	jnz		neg_exp_not_even
	or		r8, r11
	jmp		step4

neg_exp_not_even:
	dec		r15
	jmp		step4

neg_exp_more_1:
	cmp		r12, 63
	jge		step4
	
	mov		rax, 1
	mov		rcx, r12
	shl		rax, cl
	sub		rax, 1			;mask

	lea		rbx, [4 * r9]	;4 * mantissa
	test	rbx, rax
	setz	r8b
	shl		r8, 1
	
step4:
; r8 <- flags
; r13 - vm
; r14 - vr
; r15 - vp
	test	r8, r8
	jz		no_flags
	mov		rsi, r8
; rsi - flags
; r9 - cnt
; r10 - vm div
; r11 - vr div
; r12 - vp div
; r13 - vm
; r14 - vr
; r15 - vp
; rdi - last dig
	xor		rdi, rdi
	xor		rbx, rbx
	xor		r9, r9
	mov		r8, 0CCCCCCCCCCCCCCCDh

loop_div10_range_flag_1:
	mov		rax, r8
	mul		r15
	shr		rdx, 3
	mov		r12, rdx

	mov		rax, r8
	mul		r13
	shr		rdx, 3
	mov		r10, rdx

	cmp		r12, r10
	jle		exit_div10_range_flag_1
	inc		r9

	mov		r15, r12

	lea		rax, [r10 + 4 * r10]
	add		rax, rax
	sub		r13, rax
	setz	bl
	or		bl, 2
	and		rsi, rbx

	test	rdi, rdi
	setz	bl
	shl		bl, 1
	or		bl, 1
	and		rsi, rbx

	mov		r13, r10

	mov		rax, r8
	mul		r14
	shr		rdx, 3
	mov		r11, rdx

	lea		rax, [r11 + 4 * r11]
	add		rax, rax
	sub		r14, rax
	mov		rdi, r14

	mov		r14, r11
	jmp		loop_div10_range_flag_1

exit_div10_range_flag_1:
	test	rsi, 1
	jz		no_flag_vm_set

; rsi - flags
; r9 - cnt
; r10 - vm div
; r11 - vr div
; r12 - vp div
; r13 - vm
; r14 - vr
; r15 - vp
; rdi - last dig
	xor		rbx, rbx

loop_div10_range_flag_vm:

	mov		rax, r8
	mul		r13
	shr		rdx, 3
	mov		r10, rdx

	lea		rax, [r10 + 4 * r10]
	add		rax, rax
	sub		r13, rax

	test	r13, r13
	jnz		exit_div10_range_flag_vm
	inc		r9

	mov		rax, r8
	mul		r15
	shr		rdx, 3
	mov		r12, rdx

	mov		r15, r12
	mov		r13, r10

	test	rdi, rdi
	setz	bl
	shl		bl, 1
	or		bl, 1
	and		rsi, rbx

	mov		rax, r8
	mul		r14
	shr		rdx, 3
	mov		r11, rdx

	lea		rax, [r11 + 4 * r11]
	add		rax, rax
	sub		r14, rax
	mov		rdi, r14

	mov		r14, r11
	jmp		loop_div10_range_flag_vm

exit_div10_range_flag_vm:
	
no_flag_vm_set:
; rsi - flags
; r9 - cnt
; r10 - vm div
; r11 - vr div
; r12 - vp div
; r13 - vm
; r14 - vr
; r15 - vp
; rdi - last dig
	xor		rax, rax
	xor		rbx, rbx
	xor		rcx, rcx
	xor		rdx, rdx

	test	r14, 1
	setz	bl

	cmp		rdi, 5
	sete	al

	test	rsi, 2
	setnz	cl

	and		al, cl
	and		al, bl
	sub		rdi, rax

	xchg	r10, r9	
	xchg	r9, r14
; rsi - flags
; r9 - vr
; r10 - cnt
; rdi - last dig
	
	cmp		rdi, 5
	setge	al

	cmp		r9, r13
	sete	bl

	test	byte [even], 1
	setnz	cl

	test	rsi, 1
	setnz	dl

	or		cl, dl
	and		cl, bl
	or		al, cl

	add		r9, rax

	add		r10, [exp]
	jmp		exp_no_load

no_flags
; r10 - vm div
; r11 - vr div
; r12 - vp div
; r13 - vm
; r14 - vr
; r15 - vp
	;mov		r9, r14
	;jmp		end_double
	xor		rbx, rbx
	xor		r9, r9
	mov		r8, 0CCCCCCCCCCCCCCCDh

loop_div10_range:
	mov		rax, r8
	mul		r15
	shr		rdx, 3
	mov		r12, rdx

	mov		rax, r8
	mul		r13
	shr		rdx, 3
	mov		r10, rdx

	cmp		r12, r10
	jle		exit_div10_range
	inc		r9

	mov		r15, r12
	mov		r13, r10

	mov		rax, r8
	mul		r14
	shr		rdx, 3
	mov		r11, rdx

	lea		rax, [r11 + 4 * r11]
	add		rax, rax
	sub		r14, rax
	cmp		r14, 5
	setge	bl

	mov		r14, r11
	jmp		loop_div10_range
exit_div10_range:
	
	xchg	r10, r9	
	xchg	r9, r14
	
	cmp		r9, r13
	sete	bl
	add		r9, rbx

	add		r10, [exp]
	jmp		exp_no_load

end_double:
	mov		r10, [exp]

exp_no_load:
	mov		r8, [sign]
	mov		rdi, [output]

	pop		rbx
	pop		r15
	pop		r14
	pop		r13
	pop		r12 

	jmp print_integer


;----------------------------print -------------------------------
print_sign:
; rax - free
; r8 - sign
; rdi - buffer
	lea		rax, [sign_char]
	mov		al, byte [r8 + rax]
	mov		byte [rdi], al
	inc		rdi
	ret

print_int:
; r8 - free (sign)
; r9 - matissa
; r10 - exp
; rdi - buffer
; rax, r11, rcx - free
; Optimized division by 10
	lea		rsi, [tmp_str]
	xchg	rsi, rdi

div_loop:
	inc		r10			;inc exp
	mov		rax, 0CCCCCCCCCCCCCCCDh
	mul		r9
	shr		rdx, 3

	mov		rax, rdx
	shl		rax, 2
	lea		rcx, [rax + rdx]

	mov		rax, r9
	add		rcx, rcx
	sub		rax, rcx
	add		al, '0' 
	mov		byte [rdi], al
	inc		rdi

	mov		r9, rdx
	test	rdx, rdx
	jne		div_loop

	xchg	rsi, rdi
	xchg	rsi, rcx
	
	lea		rsi, [tmp_str]
	sub		rcx, rsi

print_int_reverse:
	mov		al, byte [rsi + rcx - 1]
	mov		byte [rdi], al
	inc		rdi
	dec		rcx
	test	rcx, rcx
	jnz		print_int_reverse
	ret

; ---------------------------- integer -----------------------
integer_out:			
delete_zeroes:
	mov		rax, r9
	xor		rdx, rdx
	div		qword [ten]

	test	rdx, rdx
	jnz		print_integer
	inc		r10
	xchg	r9, rax
	jmp		delete_zeroes

print_integer:
; r8 - sign
; r9 - int
; r10 - exp
; rdi - buffer
;print_matissa
	call	print_sign
	mov		byte [rdi], byte '0'
	mov		byte [rdi + 1], byte '.'
	add		rdi, 2
	call	print_int
; r9 - free (matissa)
;print_exp
	mov		byte [rdi], byte 'e'
	inc		rdi
	xchg	r10, r9
	cmp		r9, 0
	jl		neg_exp
	call	print_int
	jmp		zero_end

neg_exp:
	mov		byte [rdi], byte '-'
	inc		rdi
	neg		r9
	call	print_int
zero_end:

	mov		byte [rdi], 0
	pop		rsi
	pop		rdi
	xor		rax, rax
	ret
	
; ---------------------------- simple -----------------------
simple_out:
	push	rbx
;NaN
	cmp		r9, 0
	je		simple_out_sign
	lea		rbx, [nan]
	mov		rcx, 4
	jmp		simple_exit

simple_out_sign:
	call	print_sign

simple_out_inf:
;Inf
	cmp		r10, 0
	je		simple_out_0
	lea		rbx, [inf]
	mov		rcx, 4
	jmp		simple_exit

simple_out_0:
;0.0e0
	lea		rbx, [zero]
	mov		rcx, 6

simple_exit:
	call	copy_str
	pop		rbx
	pop		rsi
	pop		rdi
	xor		rax, rax
	ret

copy_str:
copy_loop:
	mov		rax, [rbx + rcx - 1]
	mov		[rdi + rcx - 1], rax
	sub		rcx, 1
	jnz		copy_loop
	ret
