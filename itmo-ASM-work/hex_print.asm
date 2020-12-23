global	_hex_print

section .data
tmp_num:	dd 0, 0, 0, 0, 0, 0, 0, 0
const_32:	db 32
sign:		db 0
filler:		db ' '

section .bss
tmp_str:	resb 32

section .code

_hex_print:
	pushad
	mov		byte [sign], 0
	mov		byte [filler], ' '

;read num
	mov		esi, [esp + 36 + 8]
	;mov		edi, tmp_num

	xor		eax, eax			;char buffer
	xor		ecx, ecx			

	xor		edx, edx			;data
	mov		cl, 8				;count block 4 bits each
	mov		ebp, 4				;count block 32 bits each 

	cmp		byte [esi], '-'
	jnz		loop_read
	inc		esi

loop_read:
	mov		al, byte [esi]
	test	al, al
	jz		end_read			;end str
	inc		esi

	cmp		al, '0'
	jb		end_read			;bad char
	cmp		al,	'9'
	ja		alpha
	sub		al, '0'
	jmp		continue_read

alpha:
	cmp		al, 'A'
	jb		end_read
	cmp		al, 'F'
	ja		betha
	sub		al, 'A'
	add		al, 10
	jmp		continue_read

betha:
	cmp		al, 'a'
	jb		end_read
	cmp		al, 'f'
	ja		end_read
	sub		al, 'a'
	add		al, 10

continue_read:
	shl		edx, 4
	or		edx, eax			;

	dec		cl
	test	cl, cl				;?already read 8 block (4 byte in total)
	jnz		loop_read

	mov		cl, 8
	mov		[tmp_num + ebp * 4], edx			;save data
	xor		edx, edx

	inc		ebp
	cmp		ebp, 8				;?already read 4 block (16 byte in total)
	jnz		loop_read

	mov		cl, 0
	dec		ebp
	mov		edx, [tmp_num + ebp * 4]

end_read:
	;cl  - shift
	;ebp - last block
	;edx - last data

	shl		cl, 2
	shl		edx, cl
	mov		[tmp_num + ebp * 4], edx

	xor		eax, eax
	xchg	al, cl
	div		byte [const_32]		; ah|al ==> cl|epb-al
	xchg	ah, cl
	sub		ebp, eax


	mov		esi, ebp
	
loop_shrd:

	mov		edx, [tmp_num + esi * 4]
	dec		esi
	mov		eax, [tmp_num + esi * 4]
	shrd	edx, eax, cl			; eax >> edx cl
	mov		[tmp_num + esi * 4 + 4], edx

	cmp		esi, 2
	jnz		loop_shrd
	
;determitating sign
	;ebp - last block

	mov		edi, tmp_num
	sub		ebp, 3
	shl		ebp, 2
	add		edi, ebp

	mov		esi, [esp + 36 + 8]
	cmp		byte [esi], '-'
	jnz		left_sign

	not		dword [edi + 12]
	add		dword [edi + 12], 1
	not		dword [edi + 8]
	adc		dword [edi + 8], 0
	not		dword [edi + 4]
	adc		dword [edi + 4], 0
	not		dword [edi]
	adc		dword [edi], 0

left_sign:
	test	dword [edi], (1 << 31)
	jz		convert_to_str

	mov		byte [sign], '-'

	not		dword [edi + 12]
	add		dword [edi + 12], 1
	not		dword [edi + 8]
	adc		dword [edi + 8], 0
	not		dword [edi + 4]
	adc		dword [edi + 4], 0
	not		dword [edi]
	adc		dword [edi], 0
	
convert_to_str:
	;esi - first block
	xor		ecx, ecx
	xchg	edi, esi
	mov		edi, tmp_str
	mov		ebx, 10
	
convert_loop:
	xor		edx, edx
	xor		ebp, ebp
	
convert_div_loop:
	mov		eax, [esi + ebp * 4]
	div		ebx
	mov		[esi + ebp * 4], eax

	inc		ebp
	cmp		ebp, 4
	jnz		convert_div_loop

	add		dl, '0'
	mov		[edi + ecx], dl
	inc		ecx
	
	mov		eax, [esi]
	or		eax, [esi + 4]
	or		eax, [esi + 8]
	or		eax, [esi + 12]
	jnz		convert_loop

read_flag:
	;ecx - lenght
	mov		edx, 10
	xor		eax, eax
	xor		ebx, ebx				;bh '-'; bl ' ' 
	xor		ebp, ebp				;ebp - weight
			
	mov		esi, [esp + 36 + 4]
	
read_flag_loop:
	mov		al, byte [esi]
	test	al, al
	jz		read_flag_end			;end str
	inc		esi

	cmp		al, '-'
	jnz		case_2	
	mov		bh, 1
	jmp		read_flag_loop
case_2:
	cmp		al, '+'
	jnz		case_3
	cmp		byte [sign], 0
	jnz		read_flag_loop
	mov		byte [sign], '+'
	jmp		read_flag_loop
case_3:
	cmp		al, ' '
	jnz		case_4
	mov		bl, 1
	jmp		read_flag_loop
case_4:
	cmp		al, '0'
	jnz		case_5
	mov		byte [filler], '0'
	jmp		read_flag_loop

case_5:
	cmp		al, '0'
	jb		read_flag_end			;bad char
	cmp		al,	'9'
	ja		read_flag_end			;bad char
	sub		al, '0'
	xchg	ebp, eax
	mul		dl
	add		ebp, eax				;ebp - weight

	mov		al, byte [esi]
	test	al, al
	inc		esi
	jnz		case_5


read_flag_end:
	;ecx - lenght
	;ebp - weight
	;ebx bh '-'; bl ' ' 

	xor		eax, eax
	sub		ebp, ecx

	mov		esi, tmp_str
	mov		edi, [esp + 36]
	cmp		bh, 1
	jnz		print_right_num

;print_left_num
	mov		byte [filler], ' '		; bh? filler = ' '
	call	print_prefix
	sub		ebp, eax
	call	print_num

	cmp		ebp, 0
	jle		exit
	xchg	ebp, ecx
	call	print_fill
	jmp		exit

print_right_num:
	cmp		byte [filler], '0'
	jnz		print_right_num_sp
	call	print_prefix
	sub		ebp, eax

	cmp		ebp, 0
	jle		print_right_num_num
	xchg	ebp, ecx
	call	print_fill
	xchg	ebp, ecx
print_right_num_num:
	call	print_num
	jmp		exit

print_right_num_sp:
	cmp		byte [sign], 0
	jz		print_right_num_sp_s
	mov		eax, 1
print_right_num_sp_s:
	or		al, bl
	sub		ebp, eax
	
	cmp		ebp, 0
	jle		print_right_num_sp_prefix
	xchg	ebp, ecx
	call	print_fill
	call	print_prefix
	xchg	ebp, ecx
	call	print_num
	jmp		exit

print_right_num_sp_prefix:
	call	print_prefix
	call	print_num
	jmp		exit

	
print_num:
	
	;ecx - lenght
	mov		al, byte [esi + ecx - 1] 
	mov		byte [edi], al

	inc		edi
	dec		ecx
	test	ecx, ecx
	jnz		print_num
	ret

print_fill:
	;ecx - lenght	
	mov		al, byte [filler] 
print_fill_loop:
	mov		byte [edi], al
	inc		edi
	dec		ecx
	test	ecx, ecx
	jnz		print_fill_loop
	ret

print_prefix:
	;edi - output
	;ecx - lenght
	;ebp - weight
	;ebx bh '-'; bl ' '
	xor		eax, eax

	cmp		byte [sign], 0
	jz		print_sp
	mov		dl, byte [sign]
	mov		byte [edi], dl
	inc		edi
	inc		eax
	ret 
print_sp:
	test	bl, bl
	jz		skip_sp
	mov		byte [edi], ' '
	inc		edi
	inc		eax
skip_sp:
	ret


exit:
	popad
	ret