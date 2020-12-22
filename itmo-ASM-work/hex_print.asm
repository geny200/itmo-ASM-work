global	_hex_print

section .data
tmp_str:	resb 32
tmp_num:	dd 0, 0, 0, 0, 0, 0, 0
const_32:	db 32

section .code

_hex_print:
	pushad

;read num
	mov		esi, [esp + 36 + 8]
	mov		edi, tmp_num

	xor		ecx, ecx
	xor		edx, edx			;data
	mov		cl, 8				;count block 4 bits each
	mov		ebp, 3
	;mov		ebx, 4				;count block 32 bits each 

loop_read:
	movzx	eax, byte [esi]
	test	eax, eax
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
	mov		[edi + ebp * 4], edx			;save data
	xor		edx, edx

	inc		ebp
	cmp		ebp, 7				;?already read 4 block (16 byte in total)
	jnz		loop_read

	mov		cl, 0
	dec		ebp
	mov		edx, [edi + ebp * 4]

end_read:
	;cl  - shift
	;ebp - last block
	;edx - last data

	xor		eax, eax
	mov		eax, 4
	mul		cl
	xchg	al, cl

	shl		edx, cl
	mov		[edi + ebp * 4], edx

	xor		eax, eax
	xchg	al, cl
	div		byte [const_32]		; ah|al ==> cl|epb-al
	xchg	ah, cl
	sub		ebp, eax

	xor		eax, eax
	mov		esi, ebp
	
loop_shrd:

	mov		edx, [tmp_num + esi * 4]
	dec		esi
	mov		eax, [tmp_num + esi * 4]
	shrd	edx, eax, cl			; eax >> edx cl
	mov		[tmp_num + esi * 4 + 4], edx

	cmp		esi, 2
	jnz		loop_shrd
	
convert_to_str:
	;ebp - last block

	xor		ecx, ecx
	mov		esi, tmp_num
	sub		ebp, 3
	shl		ebp, 2
	add		esi, ebp
	
	mov		edi, [esp + 36]
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


	popad
	ret