global my_strlen	

section .code
my_strlen:
  xorps  xmm1, xmm1
  mov    rax, rcx
  mov    rdx, rcx
  sub    rax, 16
loop:
  add    rax, 16
  pcmpistri xmm1, [rax], 8
  jnz    loop

  add    rax, rcx
  sub    rax, rdx
  ret
