
obj/user/testvm:     file format elf32-i386


Disassembly of section .text:

40000100 <start>:
// Start entrypoint - this is where the kernel (or our parent process)
// starts us running when we are initially loaded into a new process.
	.globl start
start:

	call	main	// run the program
40000100:	e8 6f 2a 00 00       	call   40002b74 <main>
	pushl	%eax	// use with main's return value as exit status
40000105:	50                   	push   %eax
        movl	$SYS_RET, %eax
40000106:	b8 03 00 00 00       	mov    $0x3,%eax
        int	$T_SYSCALL
4000010b:	cd 30                	int    $0x30
1:	jmp 1b
4000010d:	eb fe                	jmp    4000010d <start+0xd>
4000010f:	90                   	nop

40000110 <fork>:


// Fork a child process, returning 0 in the child and 1 in the parent.
int
fork(int cmd, uint8_t child)
{
40000110:	55                   	push   %ebp
40000111:	89 e5                	mov    %esp,%ebp
40000113:	57                   	push   %edi
40000114:	56                   	push   %esi
40000115:	53                   	push   %ebx
40000116:	81 ec 9c 02 00 00    	sub    $0x29c,%esp
4000011c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000011f:	88 85 74 fd ff ff    	mov    %al,-0x28c(%ebp)
	// Set up the register state for the child
	struct procstate ps;
	memset(&ps, 0, sizeof(ps));
40000125:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
4000012c:	00 
4000012d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000134:	00 
40000135:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
4000013b:	89 04 24             	mov    %eax,(%esp)
4000013e:	e8 a5 35 00 00       	call   400036e8 <memset>

	// Use some assembly magic to propagate registers to child
	// and generate an appropriate starting eip
	int isparent;
	asm volatile(
40000143:	89 b5 7c fd ff ff    	mov    %esi,-0x284(%ebp)
40000149:	89 bd 78 fd ff ff    	mov    %edi,-0x288(%ebp)
4000014f:	89 ad 80 fd ff ff    	mov    %ebp,-0x280(%ebp)
40000155:	89 a5 bc fd ff ff    	mov    %esp,-0x244(%ebp)
4000015b:	c7 85 b0 fd ff ff 6a 	movl   $0x4000016a,-0x250(%ebp)
40000162:	01 00 40 
40000165:	b8 01 00 00 00       	mov    $0x1,%eax
4000016a:	89 45 cc             	mov    %eax,-0x34(%ebp)
		  "=m" (ps.tf.esp),
		  "=m" (ps.tf.eip),
		  "=a" (isparent)
		:
		: "ebx", "ecx", "edx");
	if (!isparent)
4000016d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
40000171:	75 07                	jne    4000017a <fork+0x6a>
		return 0;	// in the child
40000173:	b8 00 00 00 00       	mov    $0x0,%eax
40000178:	eb 5c                	jmp    400001d6 <fork+0xc6>

	// Fork the child, copying our entire user address space into it.
	ps.tf.regs.eax = 0;	// isparent == 0 in the child
4000017a:	c7 85 94 fd ff ff 00 	movl   $0x0,-0x26c(%ebp)
40000181:	00 00 00 
	sys_put(cmd | SYS_REGS | SYS_COPY, child, &ps, ALLVA, ALLVA, ALLSIZE);
40000184:	0f b6 85 74 fd ff ff 	movzbl -0x28c(%ebp),%eax
4000018b:	8b 55 08             	mov    0x8(%ebp),%edx
4000018e:	81 ca 00 10 02 00    	or     $0x21000,%edx
40000194:	89 55 e4             	mov    %edx,-0x1c(%ebp)
40000197:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
4000019b:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
400001a1:	89 45 dc             	mov    %eax,-0x24(%ebp)
400001a4:	c7 45 d8 00 00 00 40 	movl   $0x40000000,-0x28(%ebp)
400001ab:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
400001b2:	c7 45 d0 00 00 00 b0 	movl   $0xb0000000,-0x30(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400001b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400001bc:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400001bf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
400001c2:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
400001c6:	8b 75 d8             	mov    -0x28(%ebp),%esi
400001c9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
400001cc:	8b 4d d0             	mov    -0x30(%ebp),%ecx
400001cf:	cd 30                	int    $0x30

	return 1;
400001d1:	b8 01 00 00 00       	mov    $0x1,%eax
}
400001d6:	81 c4 9c 02 00 00    	add    $0x29c,%esp
400001dc:	5b                   	pop    %ebx
400001dd:	5e                   	pop    %esi
400001de:	5f                   	pop    %edi
400001df:	5d                   	pop    %ebp
400001e0:	c3                   	ret    

400001e1 <join>:

void
join(int cmd, uint8_t child, int trapexpect)
{
400001e1:	55                   	push   %ebp
400001e2:	89 e5                	mov    %esp,%ebp
400001e4:	57                   	push   %edi
400001e5:	56                   	push   %esi
400001e6:	53                   	push   %ebx
400001e7:	81 ec ac 02 00 00    	sub    $0x2ac,%esp
400001ed:	8b 45 0c             	mov    0xc(%ebp),%eax
400001f0:	88 85 74 fd ff ff    	mov    %al,-0x28c(%ebp)
	// Wait for the child and retrieve its CPU state.
	// If merging, leave the highest 4MB containing the stack unmerged,
	// so that the stack acts as a "thread-private" memory area.
	struct procstate ps;
	sys_get(cmd | SYS_REGS, child, &ps, ALLVA, ALLVA, ALLSIZE-PTSIZE);
400001f6:	0f b6 85 74 fd ff ff 	movzbl -0x28c(%ebp),%eax
400001fd:	8b 55 08             	mov    0x8(%ebp),%edx
40000200:	80 ce 10             	or     $0x10,%dh
40000203:	89 55 e4             	mov    %edx,-0x1c(%ebp)
40000206:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
4000020a:	8d 85 78 fd ff ff    	lea    -0x288(%ebp),%eax
40000210:	89 45 dc             	mov    %eax,-0x24(%ebp)
40000213:	c7 45 d8 00 00 00 40 	movl   $0x40000000,-0x28(%ebp)
4000021a:	c7 45 d4 00 00 00 40 	movl   $0x40000000,-0x2c(%ebp)
40000221:	c7 45 d0 00 00 c0 af 	movl   $0xafc00000,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000228:	8b 45 e4             	mov    -0x1c(%ebp),%eax
4000022b:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000022e:	8b 5d dc             	mov    -0x24(%ebp),%ebx
40000231:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
40000235:	8b 75 d8             	mov    -0x28(%ebp),%esi
40000238:	8b 7d d4             	mov    -0x2c(%ebp),%edi
4000023b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
4000023e:	cd 30                	int    $0x30

	// Make sure the child exited with the expected trap number
	if (ps.tf.trapno != trapexpect) {
40000240:	8b 95 a8 fd ff ff    	mov    -0x258(%ebp),%edx
40000246:	8b 45 10             	mov    0x10(%ebp),%eax
40000249:	39 c2                	cmp    %eax,%edx
4000024b:	74 59                	je     400002a6 <join+0xc5>
		cprintf("  eip  0x%08x\n", ps.tf.eip);
4000024d:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40000253:	89 44 24 04          	mov    %eax,0x4(%esp)
40000257:	c7 04 24 80 3b 00 40 	movl   $0x40003b80,(%esp)
4000025e:	e8 e6 2b 00 00       	call   40002e49 <cprintf>
		cprintf("  esp  0x%08x\n", ps.tf.esp);
40000263:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40000269:	89 44 24 04          	mov    %eax,0x4(%esp)
4000026d:	c7 04 24 8f 3b 00 40 	movl   $0x40003b8f,(%esp)
40000274:	e8 d0 2b 00 00       	call   40002e49 <cprintf>
		panic("join: unexpected trap %d, expecting %d\n",
40000279:	8b 85 a8 fd ff ff    	mov    -0x258(%ebp),%eax
4000027f:	8b 55 10             	mov    0x10(%ebp),%edx
40000282:	89 54 24 10          	mov    %edx,0x10(%esp)
40000286:	89 44 24 0c          	mov    %eax,0xc(%esp)
4000028a:	c7 44 24 08 a0 3b 00 	movl   $0x40003ba0,0x8(%esp)
40000291:	40 
40000292:	c7 44 24 04 50 00 00 	movl   $0x50,0x4(%esp)
40000299:	00 
4000029a:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400002a1:	e8 12 29 00 00       	call   40002bb8 <debug_panic>
			ps.tf.trapno, trapexpect);
	}
}
400002a6:	81 c4 ac 02 00 00    	add    $0x2ac,%esp
400002ac:	5b                   	pop    %ebx
400002ad:	5e                   	pop    %esi
400002ae:	5f                   	pop    %edi
400002af:	5d                   	pop    %ebp
400002b0:	c3                   	ret    

400002b1 <gentrap>:

void
gentrap(int trap)
{
400002b1:	55                   	push   %ebp
400002b2:	89 e5                	mov    %esp,%ebp
400002b4:	83 ec 28             	sub    $0x28,%esp
	int bounds[2] = { 1, 3 };
400002b7:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
400002be:	c7 45 f4 03 00 00 00 	movl   $0x3,-0xc(%ebp)
	switch (trap) {
400002c5:	8b 45 08             	mov    0x8(%ebp),%eax
400002c8:	83 f8 30             	cmp    $0x30,%eax
400002cb:	77 2e                	ja     400002fb <gentrap+0x4a>
400002cd:	8b 04 85 e8 3b 00 40 	mov    0x40003be8(,%eax,4),%eax
400002d4:	ff e0                	jmp    *%eax
	case T_DIVIDE:
		asm volatile("divl %0,%0" : : "r" (0));
400002d6:	b8 00 00 00 00       	mov    $0x0,%eax
400002db:	f7 f0                	div    %eax
	case T_BRKPT:
		asm volatile("int3");
400002dd:	cc                   	int3   
	case T_OFLOW:
		asm volatile("addl %0,%0; into" : : "r" (0x70000000));
400002de:	b8 00 00 00 70       	mov    $0x70000000,%eax
400002e3:	01 c0                	add    %eax,%eax
400002e5:	ce                   	into   
	case T_BOUND:
		asm volatile("boundl %0,%1" : : "r" (0), "m" (bounds[0]));
400002e6:	b8 00 00 00 00       	mov    $0x0,%eax
400002eb:	62 45 f0             	bound  %eax,-0x10(%ebp)
	case T_ILLOP:
		asm volatile("ud2");	// guaranteed to be undefined
400002ee:	0f 0b                	ud2    
	case T_GPFLT:
		asm volatile("lidt %0" : : "m" (trap));
400002f0:	0f 01 5d 08          	lidtl  0x8(%ebp)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400002f4:	b8 03 00 00 00       	mov    $0x3,%eax
400002f9:	cd 30                	int    $0x30
	case T_SYSCALL:
		sys_ret();
	default:
		panic("unknown trap %d", trap);
400002fb:	8b 45 08             	mov    0x8(%ebp),%eax
400002fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
40000302:	c7 44 24 08 d6 3b 00 	movl   $0x40003bd6,0x8(%esp)
40000309:	40 
4000030a:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
40000311:	00 
40000312:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000319:	e8 9a 28 00 00       	call   40002bb8 <debug_panic>

4000031e <trapcheck>:
	}
}

static void
trapcheck(int trapno)
{
4000031e:	55                   	push   %ebp
4000031f:	89 e5                	mov    %esp,%ebp
40000321:	83 ec 18             	sub    $0x18,%esp
	// cprintf("trapcheck %d\n", trapno);
	if (!fork(SYS_START, 0)) { gentrap(trapno); }
40000324:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000032b:	00 
4000032c:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000333:	e8 d8 fd ff ff       	call   40000110 <fork>
40000338:	85 c0                	test   %eax,%eax
4000033a:	75 0b                	jne    40000347 <trapcheck+0x29>
4000033c:	8b 45 08             	mov    0x8(%ebp),%eax
4000033f:	89 04 24             	mov    %eax,(%esp)
40000342:	e8 6a ff ff ff       	call   400002b1 <gentrap>
	join(0, 0, trapno);
40000347:	8b 45 08             	mov    0x8(%ebp),%eax
4000034a:	89 44 24 08          	mov    %eax,0x8(%esp)
4000034e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000355:	00 
40000356:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000035d:	e8 7f fe ff ff       	call   400001e1 <join>
}
40000362:	c9                   	leave  
40000363:	c3                   	ret    

40000364 <cputsfaultchild>:
	if (!fork(SYS_START, 0)) \
		{ volatile int *p = (volatile int*)(va); \
		  *p = 0xdeadbeef; sys_ret(); } \
	join(0, 0, T_PGFLT);

static void cputsfaultchild(int arg) {
40000364:	55                   	push   %ebp
40000365:	89 e5                	mov    %esp,%ebp
40000367:	53                   	push   %ebx
40000368:	83 ec 10             	sub    $0x10,%esp
	sys_cputs((char*)arg);
4000036b:	8b 45 08             	mov    0x8(%ebp),%eax
4000036e:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000371:	b8 00 00 00 00       	mov    $0x0,%eax
40000376:	8b 55 f8             	mov    -0x8(%ebp),%edx
40000379:	89 d3                	mov    %edx,%ebx
4000037b:	cd 30                	int    $0x30
}
4000037d:	83 c4 10             	add    $0x10,%esp
40000380:	5b                   	pop    %ebx
40000381:	5d                   	pop    %ebp
40000382:	c3                   	ret    

40000383 <loadcheck>:
		sys_ret(); } \
	join(0, 0, T_PGFLT);

void
loadcheck()
{
40000383:	55                   	push   %ebp
40000384:	89 e5                	mov    %esp,%ebp
40000386:	83 ec 28             	sub    $0x28,%esp
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
40000389:	c7 45 f4 a0 5c 00 40 	movl   $0x40005ca0,-0xc(%ebp)
40000390:	eb 5c                	jmp    400003ee <loadcheck+0x6b>
		if (*p != 0) cprintf("%x %d\n", p, *p);
40000392:	8b 45 f4             	mov    -0xc(%ebp),%eax
40000395:	0f b6 00             	movzbl (%eax),%eax
40000398:	84 c0                	test   %al,%al
4000039a:	74 20                	je     400003bc <loadcheck+0x39>
4000039c:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000039f:	0f b6 00             	movzbl (%eax),%eax
400003a2:	0f b6 c0             	movzbl %al,%eax
400003a5:	89 44 24 08          	mov    %eax,0x8(%esp)
400003a9:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003ac:	89 44 24 04          	mov    %eax,0x4(%esp)
400003b0:	c7 04 24 ac 3c 00 40 	movl   $0x40003cac,(%esp)
400003b7:	e8 8d 2a 00 00       	call   40002e49 <cprintf>
		assert(*p == 0);
400003bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
400003bf:	0f b6 00             	movzbl (%eax),%eax
400003c2:	84 c0                	test   %al,%al
400003c4:	74 24                	je     400003ea <loadcheck+0x67>
400003c6:	c7 44 24 0c b3 3c 00 	movl   $0x40003cb3,0xc(%esp)
400003cd:	40 
400003ce:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400003d5:	40 
400003d6:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
400003dd:	00 
400003de:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400003e5:	e8 ce 27 00 00       	call   40002bb8 <debug_panic>
void
loadcheck()
{
	// Simple ELF loading test: make sure bss is mapped but cleared
	uint8_t *p;
	for (p = edata; p < end; p++) {
400003ea:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
400003ee:	81 7d f4 c8 7d 00 40 	cmpl   $0x40007dc8,-0xc(%ebp)
400003f5:	72 9b                	jb     40000392 <loadcheck+0xf>
		if (*p != 0) cprintf("%x %d\n", p, *p);
		assert(*p == 0);
	}

	cprintf("testvm: loadcheck passed\n");
400003f7:	c7 04 24 d0 3c 00 40 	movl   $0x40003cd0,(%esp)
400003fe:	e8 46 2a 00 00       	call   40002e49 <cprintf>
}
40000403:	c9                   	leave  
40000404:	c3                   	ret    

40000405 <forkcheck>:

// Check forking of simple child processes and trap redirection (once more)
void
forkcheck()
{
40000405:	55                   	push   %ebp
40000406:	89 e5                	mov    %esp,%ebp
40000408:	83 ec 18             	sub    $0x18,%esp
	// Our first copy-on-write test: fork and execute a simple child.
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
4000040b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000412:	00 
40000413:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000041a:	e8 f1 fc ff ff       	call   40000110 <fork>
4000041f:	85 c0                	test   %eax,%eax
40000421:	75 0c                	jne    4000042f <forkcheck+0x2a>
40000423:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
4000042a:	e8 82 fe ff ff       	call   400002b1 <gentrap>
	join(0, 0, T_SYSCALL);
4000042f:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40000436:	00 
40000437:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000043e:	00 
4000043f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000446:	e8 96 fd ff ff       	call   400001e1 <join>

	// Re-check trap handling and reflection from child processes
	trapcheck(T_DIVIDE);
4000044b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000452:	e8 c7 fe ff ff       	call   4000031e <trapcheck>
	trapcheck(T_BRKPT);
40000457:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
4000045e:	e8 bb fe ff ff       	call   4000031e <trapcheck>
	trapcheck(T_OFLOW);
40000463:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
4000046a:	e8 af fe ff ff       	call   4000031e <trapcheck>
	trapcheck(T_BOUND);
4000046f:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
40000476:	e8 a3 fe ff ff       	call   4000031e <trapcheck>
	trapcheck(T_ILLOP);
4000047b:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
40000482:	e8 97 fe ff ff       	call   4000031e <trapcheck>
	trapcheck(T_GPFLT);
40000487:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
4000048e:	e8 8b fe ff ff       	call   4000031e <trapcheck>

	// Make sure we can run several children using the same stack area
	// (since each child should get a separate logical copy)
	if (!fork(SYS_START, 0)) gentrap(T_SYSCALL);
40000493:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000049a:	00 
4000049b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004a2:	e8 69 fc ff ff       	call   40000110 <fork>
400004a7:	85 c0                	test   %eax,%eax
400004a9:	75 0c                	jne    400004b7 <forkcheck+0xb2>
400004ab:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
400004b2:	e8 fa fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 1)) gentrap(T_DIVIDE);
400004b7:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400004be:	00 
400004bf:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004c6:	e8 45 fc ff ff       	call   40000110 <fork>
400004cb:	85 c0                	test   %eax,%eax
400004cd:	75 0c                	jne    400004db <forkcheck+0xd6>
400004cf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400004d6:	e8 d6 fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 2)) gentrap(T_BRKPT);
400004db:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
400004e2:	00 
400004e3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400004ea:	e8 21 fc ff ff       	call   40000110 <fork>
400004ef:	85 c0                	test   %eax,%eax
400004f1:	75 0c                	jne    400004ff <forkcheck+0xfa>
400004f3:	c7 04 24 03 00 00 00 	movl   $0x3,(%esp)
400004fa:	e8 b2 fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 3)) gentrap(T_OFLOW);
400004ff:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
40000506:	00 
40000507:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000050e:	e8 fd fb ff ff       	call   40000110 <fork>
40000513:	85 c0                	test   %eax,%eax
40000515:	75 0c                	jne    40000523 <forkcheck+0x11e>
40000517:	c7 04 24 04 00 00 00 	movl   $0x4,(%esp)
4000051e:	e8 8e fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 4)) gentrap(T_BOUND);
40000523:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
4000052a:	00 
4000052b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000532:	e8 d9 fb ff ff       	call   40000110 <fork>
40000537:	85 c0                	test   %eax,%eax
40000539:	75 0c                	jne    40000547 <forkcheck+0x142>
4000053b:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
40000542:	e8 6a fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 5)) gentrap(T_ILLOP);
40000547:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
4000054e:	00 
4000054f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000556:	e8 b5 fb ff ff       	call   40000110 <fork>
4000055b:	85 c0                	test   %eax,%eax
4000055d:	75 0c                	jne    4000056b <forkcheck+0x166>
4000055f:	c7 04 24 06 00 00 00 	movl   $0x6,(%esp)
40000566:	e8 46 fd ff ff       	call   400002b1 <gentrap>
	if (!fork(SYS_START, 6)) gentrap(T_GPFLT);
4000056b:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
40000572:	00 
40000573:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000057a:	e8 91 fb ff ff       	call   40000110 <fork>
4000057f:	85 c0                	test   %eax,%eax
40000581:	75 0c                	jne    4000058f <forkcheck+0x18a>
40000583:	c7 04 24 0d 00 00 00 	movl   $0xd,(%esp)
4000058a:	e8 22 fd ff ff       	call   400002b1 <gentrap>
	join(0, 0, T_SYSCALL);
4000058f:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40000596:	00 
40000597:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000059e:	00 
4000059f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005a6:	e8 36 fc ff ff       	call   400001e1 <join>
	join(0, 1, T_DIVIDE);
400005ab:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
400005b2:	00 
400005b3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400005ba:	00 
400005bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005c2:	e8 1a fc ff ff       	call   400001e1 <join>
	join(0, 2, T_BRKPT);
400005c7:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
400005ce:	00 
400005cf:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
400005d6:	00 
400005d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005de:	e8 fe fb ff ff       	call   400001e1 <join>
	join(0, 3, T_OFLOW);
400005e3:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
400005ea:	00 
400005eb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
400005f2:	00 
400005f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400005fa:	e8 e2 fb ff ff       	call   400001e1 <join>
	join(0, 4, T_BOUND);
400005ff:	c7 44 24 08 05 00 00 	movl   $0x5,0x8(%esp)
40000606:	00 
40000607:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
4000060e:	00 
4000060f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000616:	e8 c6 fb ff ff       	call   400001e1 <join>
	join(0, 5, T_ILLOP);
4000061b:	c7 44 24 08 06 00 00 	movl   $0x6,0x8(%esp)
40000622:	00 
40000623:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
4000062a:	00 
4000062b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000632:	e8 aa fb ff ff       	call   400001e1 <join>
	join(0, 6, T_GPFLT);
40000637:	c7 44 24 08 0d 00 00 	movl   $0xd,0x8(%esp)
4000063e:	00 
4000063f:	c7 44 24 04 06 00 00 	movl   $0x6,0x4(%esp)
40000646:	00 
40000647:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000064e:	e8 8e fb ff ff       	call   400001e1 <join>

	// Check that kernel address space is inaccessible to user code
	readfaulttest(0);
40000653:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000065a:	00 
4000065b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000662:	e8 a9 fa ff ff       	call   40000110 <fork>
40000667:	85 c0                	test   %eax,%eax
40000669:	75 0e                	jne    40000679 <forkcheck+0x274>
4000066b:	b8 00 00 00 00       	mov    $0x0,%eax
40000670:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000672:	b8 03 00 00 00       	mov    $0x3,%eax
40000677:	cd 30                	int    $0x30
40000679:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000680:	00 
40000681:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000688:	00 
40000689:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000690:	e8 4c fb ff ff       	call   400001e1 <join>
	readfaulttest(VM_USERLO-4);
40000695:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000069c:	00 
4000069d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006a4:	e8 67 fa ff ff       	call   40000110 <fork>
400006a9:	85 c0                	test   %eax,%eax
400006ab:	75 0e                	jne    400006bb <forkcheck+0x2b6>
400006ad:	b8 fc ff ff 3f       	mov    $0x3ffffffc,%eax
400006b2:	8b 00                	mov    (%eax),%eax
400006b4:	b8 03 00 00 00       	mov    $0x3,%eax
400006b9:	cd 30                	int    $0x30
400006bb:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400006c2:	00 
400006c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006ca:	00 
400006cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400006d2:	e8 0a fb ff ff       	call   400001e1 <join>
	readfaulttest(VM_USERHI);
400006d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400006de:	00 
400006df:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400006e6:	e8 25 fa ff ff       	call   40000110 <fork>
400006eb:	85 c0                	test   %eax,%eax
400006ed:	75 0e                	jne    400006fd <forkcheck+0x2f8>
400006ef:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
400006f4:	8b 00                	mov    (%eax),%eax
400006f6:	b8 03 00 00 00       	mov    $0x3,%eax
400006fb:	cd 30                	int    $0x30
400006fd:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000704:	00 
40000705:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000070c:	00 
4000070d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000714:	e8 c8 fa ff ff       	call   400001e1 <join>
	readfaulttest(0-4);
40000719:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000720:	00 
40000721:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000728:	e8 e3 f9 ff ff       	call   40000110 <fork>
4000072d:	85 c0                	test   %eax,%eax
4000072f:	75 0e                	jne    4000073f <forkcheck+0x33a>
40000731:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
40000736:	8b 00                	mov    (%eax),%eax
40000738:	b8 03 00 00 00       	mov    $0x3,%eax
4000073d:	cd 30                	int    $0x30
4000073f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000746:	00 
40000747:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000074e:	00 
4000074f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000756:	e8 86 fa ff ff       	call   400001e1 <join>

	cprintf("testvm: forkcheck passed\n");
4000075b:	c7 04 24 ea 3c 00 40 	movl   $0x40003cea,(%esp)
40000762:	e8 e2 26 00 00       	call   40002e49 <cprintf>
}
40000767:	c9                   	leave  
40000768:	c3                   	ret    

40000769 <protcheck>:

// Check for proper virtual memory protection
void
protcheck()
{
40000769:	55                   	push   %ebp
4000076a:	89 e5                	mov    %esp,%ebp
4000076c:	57                   	push   %edi
4000076d:	56                   	push   %esi
4000076e:	53                   	push   %ebx
4000076f:	81 ec cc 01 00 00    	sub    $0x1cc,%esp
	// Copyin/copyout protection:
	// make sure we can't use cputs/put/get data in kernel space
	cputsfaulttest(0);
40000775:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000077c:	00 
4000077d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000784:	e8 87 f9 ff ff       	call   40000110 <fork>
40000789:	85 c0                	test   %eax,%eax
4000078b:	75 20                	jne    400007ad <protcheck+0x44>
4000078d:	c7 85 4c fe ff ff 00 	movl   $0x0,-0x1b4(%ebp)
40000794:	00 00 00 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000797:	b8 00 00 00 00       	mov    $0x0,%eax
4000079c:	8b 95 4c fe ff ff    	mov    -0x1b4(%ebp),%edx
400007a2:	89 d3                	mov    %edx,%ebx
400007a4:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400007a6:	b8 03 00 00 00       	mov    $0x3,%eax
400007ab:	cd 30                	int    $0x30
400007ad:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400007b4:	00 
400007b5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007bc:	00 
400007bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400007c4:	e8 18 fa ff ff       	call   400001e1 <join>
	cputsfaulttest(VM_USERLO-1);
400007c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400007d0:	00 
400007d1:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400007d8:	e8 33 f9 ff ff       	call   40000110 <fork>
400007dd:	85 c0                	test   %eax,%eax
400007df:	75 20                	jne    40000801 <protcheck+0x98>
400007e1:	c7 85 50 fe ff ff ff 	movl   $0x3fffffff,-0x1b0(%ebp)
400007e8:	ff ff 3f 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400007eb:	b8 00 00 00 00       	mov    $0x0,%eax
400007f0:	8b 95 50 fe ff ff    	mov    -0x1b0(%ebp),%edx
400007f6:	89 d3                	mov    %edx,%ebx
400007f8:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400007fa:	b8 03 00 00 00       	mov    $0x3,%eax
400007ff:	cd 30                	int    $0x30
40000801:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000808:	00 
40000809:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000810:	00 
40000811:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000818:	e8 c4 f9 ff ff       	call   400001e1 <join>
	cputsfaulttest(VM_USERHI);
4000081d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000824:	00 
40000825:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000082c:	e8 df f8 ff ff       	call   40000110 <fork>
40000831:	85 c0                	test   %eax,%eax
40000833:	75 20                	jne    40000855 <protcheck+0xec>
40000835:	c7 85 54 fe ff ff 00 	movl   $0xf0000000,-0x1ac(%ebp)
4000083c:	00 00 f0 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
4000083f:	b8 00 00 00 00       	mov    $0x0,%eax
40000844:	8b 95 54 fe ff ff    	mov    -0x1ac(%ebp),%edx
4000084a:	89 d3                	mov    %edx,%ebx
4000084c:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000084e:	b8 03 00 00 00       	mov    $0x3,%eax
40000853:	cd 30                	int    $0x30
40000855:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000085c:	00 
4000085d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000864:	00 
40000865:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000086c:	e8 70 f9 ff ff       	call   400001e1 <join>
	cputsfaulttest(~0);
40000871:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000878:	00 
40000879:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000880:	e8 8b f8 ff ff       	call   40000110 <fork>
40000885:	85 c0                	test   %eax,%eax
40000887:	75 20                	jne    400008a9 <protcheck+0x140>
40000889:	c7 85 58 fe ff ff ff 	movl   $0xffffffff,-0x1a8(%ebp)
40000890:	ff ff ff 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000893:	b8 00 00 00 00       	mov    $0x0,%eax
40000898:	8b 95 58 fe ff ff    	mov    -0x1a8(%ebp),%edx
4000089e:	89 d3                	mov    %edx,%ebx
400008a0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400008a2:	b8 03 00 00 00       	mov    $0x3,%eax
400008a7:	cd 30                	int    $0x30
400008a9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400008b0:	00 
400008b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008b8:	00 
400008b9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400008c0:	e8 1c f9 ff ff       	call   400001e1 <join>
	putfaulttest(0);
400008c5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400008cc:	00 
400008cd:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400008d4:	e8 37 f8 ff ff       	call   40000110 <fork>
400008d9:	85 c0                	test   %eax,%eax
400008db:	75 6c                	jne    40000949 <protcheck+0x1e0>
400008dd:	c7 85 70 fe ff ff 00 	movl   $0x1000,-0x190(%ebp)
400008e4:	10 00 00 
400008e7:	66 c7 85 6e fe ff ff 	movw   $0x0,-0x192(%ebp)
400008ee:	00 00 
400008f0:	c7 85 68 fe ff ff 00 	movl   $0x0,-0x198(%ebp)
400008f7:	00 00 00 
400008fa:	c7 85 64 fe ff ff 00 	movl   $0x0,-0x19c(%ebp)
40000901:	00 00 00 
40000904:	c7 85 60 fe ff ff 00 	movl   $0x0,-0x1a0(%ebp)
4000090b:	00 00 00 
4000090e:	c7 85 5c fe ff ff 00 	movl   $0x0,-0x1a4(%ebp)
40000915:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000918:	8b 85 70 fe ff ff    	mov    -0x190(%ebp),%eax
4000091e:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000921:	8b 9d 68 fe ff ff    	mov    -0x198(%ebp),%ebx
40000927:	0f b7 95 6e fe ff ff 	movzwl -0x192(%ebp),%edx
4000092e:	8b b5 64 fe ff ff    	mov    -0x19c(%ebp),%esi
40000934:	8b bd 60 fe ff ff    	mov    -0x1a0(%ebp),%edi
4000093a:	8b 8d 5c fe ff ff    	mov    -0x1a4(%ebp),%ecx
40000940:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000942:	b8 03 00 00 00       	mov    $0x3,%eax
40000947:	cd 30                	int    $0x30
40000949:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000950:	00 
40000951:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000958:	00 
40000959:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000960:	e8 7c f8 ff ff       	call   400001e1 <join>
	putfaulttest(VM_USERLO-1);
40000965:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000096c:	00 
4000096d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000974:	e8 97 f7 ff ff       	call   40000110 <fork>
40000979:	85 c0                	test   %eax,%eax
4000097b:	75 6c                	jne    400009e9 <protcheck+0x280>
4000097d:	c7 85 88 fe ff ff 00 	movl   $0x1000,-0x178(%ebp)
40000984:	10 00 00 
40000987:	66 c7 85 86 fe ff ff 	movw   $0x0,-0x17a(%ebp)
4000098e:	00 00 
40000990:	c7 85 80 fe ff ff ff 	movl   $0x3fffffff,-0x180(%ebp)
40000997:	ff ff 3f 
4000099a:	c7 85 7c fe ff ff 00 	movl   $0x0,-0x184(%ebp)
400009a1:	00 00 00 
400009a4:	c7 85 78 fe ff ff 00 	movl   $0x0,-0x188(%ebp)
400009ab:	00 00 00 
400009ae:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
400009b5:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400009b8:	8b 85 88 fe ff ff    	mov    -0x178(%ebp),%eax
400009be:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400009c1:	8b 9d 80 fe ff ff    	mov    -0x180(%ebp),%ebx
400009c7:	0f b7 95 86 fe ff ff 	movzwl -0x17a(%ebp),%edx
400009ce:	8b b5 7c fe ff ff    	mov    -0x184(%ebp),%esi
400009d4:	8b bd 78 fe ff ff    	mov    -0x188(%ebp),%edi
400009da:	8b 8d 74 fe ff ff    	mov    -0x18c(%ebp),%ecx
400009e0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400009e2:	b8 03 00 00 00       	mov    $0x3,%eax
400009e7:	cd 30                	int    $0x30
400009e9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400009f0:	00 
400009f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400009f8:	00 
400009f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000a00:	e8 dc f7 ff ff       	call   400001e1 <join>
	putfaulttest(VM_USERHI);
40000a05:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a0c:	00 
40000a0d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000a14:	e8 f7 f6 ff ff       	call   40000110 <fork>
40000a19:	85 c0                	test   %eax,%eax
40000a1b:	75 6c                	jne    40000a89 <protcheck+0x320>
40000a1d:	c7 85 a0 fe ff ff 00 	movl   $0x1000,-0x160(%ebp)
40000a24:	10 00 00 
40000a27:	66 c7 85 9e fe ff ff 	movw   $0x0,-0x162(%ebp)
40000a2e:	00 00 
40000a30:	c7 85 98 fe ff ff 00 	movl   $0xf0000000,-0x168(%ebp)
40000a37:	00 00 f0 
40000a3a:	c7 85 94 fe ff ff 00 	movl   $0x0,-0x16c(%ebp)
40000a41:	00 00 00 
40000a44:	c7 85 90 fe ff ff 00 	movl   $0x0,-0x170(%ebp)
40000a4b:	00 00 00 
40000a4e:	c7 85 8c fe ff ff 00 	movl   $0x0,-0x174(%ebp)
40000a55:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000a58:	8b 85 a0 fe ff ff    	mov    -0x160(%ebp),%eax
40000a5e:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000a61:	8b 9d 98 fe ff ff    	mov    -0x168(%ebp),%ebx
40000a67:	0f b7 95 9e fe ff ff 	movzwl -0x162(%ebp),%edx
40000a6e:	8b b5 94 fe ff ff    	mov    -0x16c(%ebp),%esi
40000a74:	8b bd 90 fe ff ff    	mov    -0x170(%ebp),%edi
40000a7a:	8b 8d 8c fe ff ff    	mov    -0x174(%ebp),%ecx
40000a80:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000a82:	b8 03 00 00 00       	mov    $0x3,%eax
40000a87:	cd 30                	int    $0x30
40000a89:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000a90:	00 
40000a91:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000a98:	00 
40000a99:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000aa0:	e8 3c f7 ff ff       	call   400001e1 <join>
	putfaulttest(~0);
40000aa5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000aac:	00 
40000aad:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000ab4:	e8 57 f6 ff ff       	call   40000110 <fork>
40000ab9:	85 c0                	test   %eax,%eax
40000abb:	75 6c                	jne    40000b29 <protcheck+0x3c0>
40000abd:	c7 85 b8 fe ff ff 00 	movl   $0x1000,-0x148(%ebp)
40000ac4:	10 00 00 
40000ac7:	66 c7 85 b6 fe ff ff 	movw   $0x0,-0x14a(%ebp)
40000ace:	00 00 
40000ad0:	c7 85 b0 fe ff ff ff 	movl   $0xffffffff,-0x150(%ebp)
40000ad7:	ff ff ff 
40000ada:	c7 85 ac fe ff ff 00 	movl   $0x0,-0x154(%ebp)
40000ae1:	00 00 00 
40000ae4:	c7 85 a8 fe ff ff 00 	movl   $0x0,-0x158(%ebp)
40000aeb:	00 00 00 
40000aee:	c7 85 a4 fe ff ff 00 	movl   $0x0,-0x15c(%ebp)
40000af5:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40000af8:	8b 85 b8 fe ff ff    	mov    -0x148(%ebp),%eax
40000afe:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40000b01:	8b 9d b0 fe ff ff    	mov    -0x150(%ebp),%ebx
40000b07:	0f b7 95 b6 fe ff ff 	movzwl -0x14a(%ebp),%edx
40000b0e:	8b b5 ac fe ff ff    	mov    -0x154(%ebp),%esi
40000b14:	8b bd a8 fe ff ff    	mov    -0x158(%ebp),%edi
40000b1a:	8b 8d a4 fe ff ff    	mov    -0x15c(%ebp),%ecx
40000b20:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000b22:	b8 03 00 00 00       	mov    $0x3,%eax
40000b27:	cd 30                	int    $0x30
40000b29:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000b30:	00 
40000b31:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b38:	00 
40000b39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000b40:	e8 9c f6 ff ff       	call   400001e1 <join>
	getfaulttest(0);
40000b45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000b4c:	00 
40000b4d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000b54:	e8 b7 f5 ff ff       	call   40000110 <fork>
40000b59:	85 c0                	test   %eax,%eax
40000b5b:	75 6c                	jne    40000bc9 <protcheck+0x460>
40000b5d:	c7 85 d0 fe ff ff 00 	movl   $0x1000,-0x130(%ebp)
40000b64:	10 00 00 
40000b67:	66 c7 85 ce fe ff ff 	movw   $0x0,-0x132(%ebp)
40000b6e:	00 00 
40000b70:	c7 85 c8 fe ff ff 00 	movl   $0x0,-0x138(%ebp)
40000b77:	00 00 00 
40000b7a:	c7 85 c4 fe ff ff 00 	movl   $0x0,-0x13c(%ebp)
40000b81:	00 00 00 
40000b84:	c7 85 c0 fe ff ff 00 	movl   $0x0,-0x140(%ebp)
40000b8b:	00 00 00 
40000b8e:	c7 85 bc fe ff ff 00 	movl   $0x0,-0x144(%ebp)
40000b95:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000b98:	8b 85 d0 fe ff ff    	mov    -0x130(%ebp),%eax
40000b9e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000ba1:	8b 9d c8 fe ff ff    	mov    -0x138(%ebp),%ebx
40000ba7:	0f b7 95 ce fe ff ff 	movzwl -0x132(%ebp),%edx
40000bae:	8b b5 c4 fe ff ff    	mov    -0x13c(%ebp),%esi
40000bb4:	8b bd c0 fe ff ff    	mov    -0x140(%ebp),%edi
40000bba:	8b 8d bc fe ff ff    	mov    -0x144(%ebp),%ecx
40000bc0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000bc2:	b8 03 00 00 00       	mov    $0x3,%eax
40000bc7:	cd 30                	int    $0x30
40000bc9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000bd0:	00 
40000bd1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000bd8:	00 
40000bd9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000be0:	e8 fc f5 ff ff       	call   400001e1 <join>
	getfaulttest(VM_USERLO-1);
40000be5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000bec:	00 
40000bed:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000bf4:	e8 17 f5 ff ff       	call   40000110 <fork>
40000bf9:	85 c0                	test   %eax,%eax
40000bfb:	75 6c                	jne    40000c69 <protcheck+0x500>
40000bfd:	c7 85 e8 fe ff ff 00 	movl   $0x1000,-0x118(%ebp)
40000c04:	10 00 00 
40000c07:	66 c7 85 e6 fe ff ff 	movw   $0x0,-0x11a(%ebp)
40000c0e:	00 00 
40000c10:	c7 85 e0 fe ff ff ff 	movl   $0x3fffffff,-0x120(%ebp)
40000c17:	ff ff 3f 
40000c1a:	c7 85 dc fe ff ff 00 	movl   $0x0,-0x124(%ebp)
40000c21:	00 00 00 
40000c24:	c7 85 d8 fe ff ff 00 	movl   $0x0,-0x128(%ebp)
40000c2b:	00 00 00 
40000c2e:	c7 85 d4 fe ff ff 00 	movl   $0x0,-0x12c(%ebp)
40000c35:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000c38:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
40000c3e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000c41:	8b 9d e0 fe ff ff    	mov    -0x120(%ebp),%ebx
40000c47:	0f b7 95 e6 fe ff ff 	movzwl -0x11a(%ebp),%edx
40000c4e:	8b b5 dc fe ff ff    	mov    -0x124(%ebp),%esi
40000c54:	8b bd d8 fe ff ff    	mov    -0x128(%ebp),%edi
40000c5a:	8b 8d d4 fe ff ff    	mov    -0x12c(%ebp),%ecx
40000c60:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000c62:	b8 03 00 00 00       	mov    $0x3,%eax
40000c67:	cd 30                	int    $0x30
40000c69:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000c70:	00 
40000c71:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c78:	00 
40000c79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000c80:	e8 5c f5 ff ff       	call   400001e1 <join>
	getfaulttest(VM_USERHI);
40000c85:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000c8c:	00 
40000c8d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000c94:	e8 77 f4 ff ff       	call   40000110 <fork>
40000c99:	85 c0                	test   %eax,%eax
40000c9b:	75 6c                	jne    40000d09 <protcheck+0x5a0>
40000c9d:	c7 85 00 ff ff ff 00 	movl   $0x1000,-0x100(%ebp)
40000ca4:	10 00 00 
40000ca7:	66 c7 85 fe fe ff ff 	movw   $0x0,-0x102(%ebp)
40000cae:	00 00 
40000cb0:	c7 85 f8 fe ff ff 00 	movl   $0xf0000000,-0x108(%ebp)
40000cb7:	00 00 f0 
40000cba:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40000cc1:	00 00 00 
40000cc4:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40000ccb:	00 00 00 
40000cce:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40000cd5:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000cd8:	8b 85 00 ff ff ff    	mov    -0x100(%ebp),%eax
40000cde:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000ce1:	8b 9d f8 fe ff ff    	mov    -0x108(%ebp),%ebx
40000ce7:	0f b7 95 fe fe ff ff 	movzwl -0x102(%ebp),%edx
40000cee:	8b b5 f4 fe ff ff    	mov    -0x10c(%ebp),%esi
40000cf4:	8b bd f0 fe ff ff    	mov    -0x110(%ebp),%edi
40000cfa:	8b 8d ec fe ff ff    	mov    -0x114(%ebp),%ecx
40000d00:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000d02:	b8 03 00 00 00       	mov    $0x3,%eax
40000d07:	cd 30                	int    $0x30
40000d09:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000d10:	00 
40000d11:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d18:	00 
40000d19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000d20:	e8 bc f4 ff ff       	call   400001e1 <join>
	getfaulttest(~0);
40000d25:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000d2c:	00 
40000d2d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000d34:	e8 d7 f3 ff ff       	call   40000110 <fork>
40000d39:	85 c0                	test   %eax,%eax
40000d3b:	75 6c                	jne    40000da9 <protcheck+0x640>
40000d3d:	c7 85 18 ff ff ff 00 	movl   $0x1000,-0xe8(%ebp)
40000d44:	10 00 00 
40000d47:	66 c7 85 16 ff ff ff 	movw   $0x0,-0xea(%ebp)
40000d4e:	00 00 
40000d50:	c7 85 10 ff ff ff ff 	movl   $0xffffffff,-0xf0(%ebp)
40000d57:	ff ff ff 
40000d5a:	c7 85 0c ff ff ff 00 	movl   $0x0,-0xf4(%ebp)
40000d61:	00 00 00 
40000d64:	c7 85 08 ff ff ff 00 	movl   $0x0,-0xf8(%ebp)
40000d6b:	00 00 00 
40000d6e:	c7 85 04 ff ff ff 00 	movl   $0x0,-0xfc(%ebp)
40000d75:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40000d78:	8b 85 18 ff ff ff    	mov    -0xe8(%ebp),%eax
40000d7e:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40000d81:	8b 9d 10 ff ff ff    	mov    -0xf0(%ebp),%ebx
40000d87:	0f b7 95 16 ff ff ff 	movzwl -0xea(%ebp),%edx
40000d8e:	8b b5 0c ff ff ff    	mov    -0xf4(%ebp),%esi
40000d94:	8b bd 08 ff ff ff    	mov    -0xf8(%ebp),%edi
40000d9a:	8b 8d 04 ff ff ff    	mov    -0xfc(%ebp),%ecx
40000da0:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000da2:	b8 03 00 00 00       	mov    $0x3,%eax
40000da7:	cd 30                	int    $0x30
40000da9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000db0:	00 
40000db1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000db8:	00 
40000db9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000dc0:	e8 1c f4 ff ff       	call   400001e1 <join>

warn("here");
40000dc5:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000dcc:	40 
40000dcd:	c7 44 24 04 dd 00 00 	movl   $0xdd,0x4(%esp)
40000dd4:	00 
40000dd5:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000ddc:	e8 45 1e 00 00       	call   40002c26 <debug_warn>
	// Check that unused parts of user space are also inaccessible
	readfaulttest(VM_USERLO+PTSIZE);
40000de1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000de8:	00 
40000de9:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000df0:	e8 1b f3 ff ff       	call   40000110 <fork>
40000df5:	85 c0                	test   %eax,%eax
40000df7:	75 0e                	jne    40000e07 <protcheck+0x69e>
40000df9:	b8 00 00 40 40       	mov    $0x40400000,%eax
40000dfe:	8b 00                	mov    (%eax),%eax
40000e00:	b8 03 00 00 00       	mov    $0x3,%eax
40000e05:	cd 30                	int    $0x30
40000e07:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e0e:	00 
40000e0f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e16:	00 
40000e17:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e1e:	e8 be f3 ff ff       	call   400001e1 <join>
warn("here");
40000e23:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000e2a:	40 
40000e2b:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
40000e32:	00 
40000e33:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000e3a:	e8 e7 1d 00 00       	call   40002c26 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE);
40000e3f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e46:	00 
40000e47:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000e4e:	e8 bd f2 ff ff       	call   40000110 <fork>
40000e53:	85 c0                	test   %eax,%eax
40000e55:	75 0e                	jne    40000e65 <protcheck+0x6fc>
40000e57:	b8 00 00 c0 ef       	mov    $0xefc00000,%eax
40000e5c:	8b 00                	mov    (%eax),%eax
40000e5e:	b8 03 00 00 00       	mov    $0x3,%eax
40000e63:	cd 30                	int    $0x30
40000e65:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000e6c:	00 
40000e6d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000e74:	00 
40000e75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000e7c:	e8 60 f3 ff ff       	call   400001e1 <join>
warn("here");
40000e81:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000e88:	40 
40000e89:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
40000e90:	00 
40000e91:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000e98:	e8 89 1d 00 00       	call   40002c26 <debug_warn>
	readfaulttest(VM_USERHI-PTSIZE*2);
40000e9d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ea4:	00 
40000ea5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000eac:	e8 5f f2 ff ff       	call   40000110 <fork>
40000eb1:	85 c0                	test   %eax,%eax
40000eb3:	75 0e                	jne    40000ec3 <protcheck+0x75a>
40000eb5:	b8 00 00 80 ef       	mov    $0xef800000,%eax
40000eba:	8b 00                	mov    (%eax),%eax
40000ebc:	b8 03 00 00 00       	mov    $0x3,%eax
40000ec1:	cd 30                	int    $0x30
40000ec3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000eca:	00 
40000ecb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000ed2:	00 
40000ed3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000eda:	e8 02 f3 ff ff       	call   400001e1 <join>
warn("here");
40000edf:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000ee6:	40 
40000ee7:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
40000eee:	00 
40000eef:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000ef6:	e8 2b 1d 00 00       	call   40002c26 <debug_warn>
	cputsfaulttest(VM_USERLO+PTSIZE);
40000efb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f02:	00 
40000f03:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f0a:	e8 01 f2 ff ff       	call   40000110 <fork>
40000f0f:	85 c0                	test   %eax,%eax
40000f11:	75 20                	jne    40000f33 <protcheck+0x7ca>
40000f13:	c7 85 1c ff ff ff 00 	movl   $0x40400000,-0xe4(%ebp)
40000f1a:	00 40 40 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f1d:	b8 00 00 00 00       	mov    $0x0,%eax
40000f22:	8b 95 1c ff ff ff    	mov    -0xe4(%ebp),%edx
40000f28:	89 d3                	mov    %edx,%ebx
40000f2a:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000f2c:	b8 03 00 00 00       	mov    $0x3,%eax
40000f31:	cd 30                	int    $0x30
40000f33:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000f3a:	00 
40000f3b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f42:	00 
40000f43:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000f4a:	e8 92 f2 ff ff       	call   400001e1 <join>
warn("here");
40000f4f:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000f56:	40 
40000f57:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
40000f5e:	00 
40000f5f:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000f66:	e8 bb 1c 00 00       	call   40002c26 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE);
40000f6b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000f72:	00 
40000f73:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000f7a:	e8 91 f1 ff ff       	call   40000110 <fork>
40000f7f:	85 c0                	test   %eax,%eax
40000f81:	75 20                	jne    40000fa3 <protcheck+0x83a>
40000f83:	c7 85 20 ff ff ff 00 	movl   $0xefc00000,-0xe0(%ebp)
40000f8a:	00 c0 ef 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000f8d:	b8 00 00 00 00       	mov    $0x0,%eax
40000f92:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
40000f98:	89 d3                	mov    %edx,%ebx
40000f9a:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40000f9c:	b8 03 00 00 00       	mov    $0x3,%eax
40000fa1:	cd 30                	int    $0x30
40000fa3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40000faa:	00 
40000fab:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fb2:	00 
40000fb3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40000fba:	e8 22 f2 ff ff       	call   400001e1 <join>
warn("here");
40000fbf:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40000fc6:	40 
40000fc7:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
40000fce:	00 
40000fcf:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40000fd6:	e8 4b 1c 00 00       	call   40002c26 <debug_warn>
	cputsfaulttest(VM_USERHI-PTSIZE*2);
40000fdb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40000fe2:	00 
40000fe3:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40000fea:	e8 21 f1 ff ff       	call   40000110 <fork>
40000fef:	85 c0                	test   %eax,%eax
40000ff1:	75 20                	jne    40001013 <protcheck+0x8aa>
40000ff3:	c7 85 24 ff ff ff 00 	movl   $0xef800000,-0xdc(%ebp)
40000ffa:	00 80 ef 
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
40000ffd:	b8 00 00 00 00       	mov    $0x0,%eax
40001002:	8b 95 24 ff ff ff    	mov    -0xdc(%ebp),%edx
40001008:	89 d3                	mov    %edx,%ebx
4000100a:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000100c:	b8 03 00 00 00       	mov    $0x3,%eax
40001011:	cd 30                	int    $0x30
40001013:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000101a:	00 
4000101b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001022:	00 
40001023:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000102a:	e8 b2 f1 ff ff       	call   400001e1 <join>
warn("here");
4000102f:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
40001036:	40 
40001037:	c7 44 24 04 ea 00 00 	movl   $0xea,0x4(%esp)
4000103e:	00 
4000103f:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001046:	e8 db 1b 00 00       	call   40002c26 <debug_warn>
	putfaulttest(VM_USERLO+PTSIZE);
4000104b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001052:	00 
40001053:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000105a:	e8 b1 f0 ff ff       	call   40000110 <fork>
4000105f:	85 c0                	test   %eax,%eax
40001061:	75 6c                	jne    400010cf <protcheck+0x966>
40001063:	c7 85 3c ff ff ff 00 	movl   $0x1000,-0xc4(%ebp)
4000106a:	10 00 00 
4000106d:	66 c7 85 3a ff ff ff 	movw   $0x0,-0xc6(%ebp)
40001074:	00 00 
40001076:	c7 85 34 ff ff ff 00 	movl   $0x40400000,-0xcc(%ebp)
4000107d:	00 40 40 
40001080:	c7 85 30 ff ff ff 00 	movl   $0x0,-0xd0(%ebp)
40001087:	00 00 00 
4000108a:	c7 85 2c ff ff ff 00 	movl   $0x0,-0xd4(%ebp)
40001091:	00 00 00 
40001094:	c7 85 28 ff ff ff 00 	movl   $0x0,-0xd8(%ebp)
4000109b:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
4000109e:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
400010a4:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400010a7:	8b 9d 34 ff ff ff    	mov    -0xcc(%ebp),%ebx
400010ad:	0f b7 95 3a ff ff ff 	movzwl -0xc6(%ebp),%edx
400010b4:	8b b5 30 ff ff ff    	mov    -0xd0(%ebp),%esi
400010ba:	8b bd 2c ff ff ff    	mov    -0xd4(%ebp),%edi
400010c0:	8b 8d 28 ff ff ff    	mov    -0xd8(%ebp),%ecx
400010c6:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400010c8:	b8 03 00 00 00       	mov    $0x3,%eax
400010cd:	cd 30                	int    $0x30
400010cf:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400010d6:	00 
400010d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400010de:	00 
400010df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400010e6:	e8 f6 f0 ff ff       	call   400001e1 <join>
warn("here");
400010eb:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
400010f2:	40 
400010f3:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
400010fa:	00 
400010fb:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001102:	e8 1f 1b 00 00       	call   40002c26 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE);
40001107:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000110e:	00 
4000110f:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001116:	e8 f5 ef ff ff       	call   40000110 <fork>
4000111b:	85 c0                	test   %eax,%eax
4000111d:	75 6c                	jne    4000118b <protcheck+0xa22>
4000111f:	c7 85 54 ff ff ff 00 	movl   $0x1000,-0xac(%ebp)
40001126:	10 00 00 
40001129:	66 c7 85 52 ff ff ff 	movw   $0x0,-0xae(%ebp)
40001130:	00 00 
40001132:	c7 85 4c ff ff ff 00 	movl   $0xefc00000,-0xb4(%ebp)
40001139:	00 c0 ef 
4000113c:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
40001143:	00 00 00 
40001146:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
4000114d:	00 00 00 
40001150:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
40001157:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
4000115a:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
40001160:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001163:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
40001169:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
40001170:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
40001176:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
4000117c:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
40001182:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001184:	b8 03 00 00 00       	mov    $0x3,%eax
40001189:	cd 30                	int    $0x30
4000118b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001192:	00 
40001193:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000119a:	00 
4000119b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400011a2:	e8 3a f0 ff ff       	call   400001e1 <join>
warn("here");
400011a7:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
400011ae:	40 
400011af:	c7 44 24 04 ee 00 00 	movl   $0xee,0x4(%esp)
400011b6:	00 
400011b7:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400011be:	e8 63 1a 00 00       	call   40002c26 <debug_warn>
	putfaulttest(VM_USERHI-PTSIZE*2);
400011c3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400011ca:	00 
400011cb:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400011d2:	e8 39 ef ff ff       	call   40000110 <fork>
400011d7:	85 c0                	test   %eax,%eax
400011d9:	75 6c                	jne    40001247 <protcheck+0xade>
400011db:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
400011e2:	10 00 00 
400011e5:	66 c7 85 6a ff ff ff 	movw   $0x0,-0x96(%ebp)
400011ec:	00 00 
400011ee:	c7 85 64 ff ff ff 00 	movl   $0xef800000,-0x9c(%ebp)
400011f5:	00 80 ef 
400011f8:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
400011ff:	00 00 00 
40001202:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
40001209:	00 00 00 
4000120c:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
40001213:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40001216:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
4000121c:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000121f:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
40001225:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
4000122c:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
40001232:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
40001238:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
4000123e:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001240:	b8 03 00 00 00       	mov    $0x3,%eax
40001245:	cd 30                	int    $0x30
40001247:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000124e:	00 
4000124f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001256:	00 
40001257:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000125e:	e8 7e ef ff ff       	call   400001e1 <join>
warn("here");
40001263:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
4000126a:	40 
4000126b:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
40001272:	00 
40001273:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000127a:	e8 a7 19 00 00       	call   40002c26 <debug_warn>
	getfaulttest(VM_USERLO+PTSIZE);
4000127f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001286:	00 
40001287:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000128e:	e8 7d ee ff ff       	call   40000110 <fork>
40001293:	85 c0                	test   %eax,%eax
40001295:	75 60                	jne    400012f7 <protcheck+0xb8e>
40001297:	c7 45 84 00 10 00 00 	movl   $0x1000,-0x7c(%ebp)
4000129e:	66 c7 45 82 00 00    	movw   $0x0,-0x7e(%ebp)
400012a4:	c7 85 7c ff ff ff 00 	movl   $0x40400000,-0x84(%ebp)
400012ab:	00 40 40 
400012ae:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
400012b5:	00 00 00 
400012b8:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
400012bf:	00 00 00 
400012c2:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
400012c9:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400012cc:	8b 45 84             	mov    -0x7c(%ebp),%eax
400012cf:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400012d2:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
400012d8:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
400012dc:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
400012e2:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
400012e8:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
400012ee:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400012f0:	b8 03 00 00 00       	mov    $0x3,%eax
400012f5:	cd 30                	int    $0x30
400012f7:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400012fe:	00 
400012ff:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001306:	00 
40001307:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000130e:	e8 ce ee ff ff       	call   400001e1 <join>
warn("here");
40001313:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
4000131a:	40 
4000131b:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
40001322:	00 
40001323:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000132a:	e8 f7 18 00 00       	call   40002c26 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE);
4000132f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001336:	00 
40001337:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000133e:	e8 cd ed ff ff       	call   40000110 <fork>
40001343:	85 c0                	test   %eax,%eax
40001345:	75 48                	jne    4000138f <protcheck+0xc26>
40001347:	c7 45 9c 00 10 00 00 	movl   $0x1000,-0x64(%ebp)
4000134e:	66 c7 45 9a 00 00    	movw   $0x0,-0x66(%ebp)
40001354:	c7 45 94 00 00 c0 ef 	movl   $0xefc00000,-0x6c(%ebp)
4000135b:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
40001362:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
40001369:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001370:	8b 45 9c             	mov    -0x64(%ebp),%eax
40001373:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001376:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
40001379:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
4000137d:	8b 75 90             	mov    -0x70(%ebp),%esi
40001380:	8b 7d 8c             	mov    -0x74(%ebp),%edi
40001383:	8b 4d 88             	mov    -0x78(%ebp),%ecx
40001386:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001388:	b8 03 00 00 00       	mov    $0x3,%eax
4000138d:	cd 30                	int    $0x30
4000138f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001396:	00 
40001397:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000139e:	00 
4000139f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400013a6:	e8 36 ee ff ff       	call   400001e1 <join>
warn("here");
400013ab:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
400013b2:	40 
400013b3:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
400013ba:	00 
400013bb:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400013c2:	e8 5f 18 00 00       	call   40002c26 <debug_warn>
	getfaulttest(VM_USERHI-PTSIZE*2);
400013c7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400013ce:	00 
400013cf:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400013d6:	e8 35 ed ff ff       	call   40000110 <fork>
400013db:	85 c0                	test   %eax,%eax
400013dd:	75 48                	jne    40001427 <protcheck+0xcbe>
400013df:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
400013e6:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
400013ec:	c7 45 ac 00 00 80 ef 	movl   $0xef800000,-0x54(%ebp)
400013f3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
400013fa:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
40001401:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001408:	8b 45 b4             	mov    -0x4c(%ebp),%eax
4000140b:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000140e:	8b 5d ac             	mov    -0x54(%ebp),%ebx
40001411:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
40001415:	8b 75 a8             	mov    -0x58(%ebp),%esi
40001418:	8b 7d a4             	mov    -0x5c(%ebp),%edi
4000141b:	8b 4d a0             	mov    -0x60(%ebp),%ecx
4000141e:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001420:	b8 03 00 00 00       	mov    $0x3,%eax
40001425:	cd 30                	int    $0x30
40001427:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000142e:	00 
4000142f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001436:	00 
40001437:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000143e:	e8 9e ed ff ff       	call   400001e1 <join>
warn("here");
40001443:	c7 44 24 08 04 3d 00 	movl   $0x40003d04,0x8(%esp)
4000144a:	40 
4000144b:	c7 44 24 04 f6 00 00 	movl   $0xf6,0x4(%esp)
40001452:	00 
40001453:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000145a:	e8 c7 17 00 00       	call   40002c26 <debug_warn>

	// Check that our text segment is mapped read-only
	writefaulttest((int)start);
4000145f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001466:	00 
40001467:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000146e:	e8 9d ec ff ff       	call   40000110 <fork>
40001473:	85 c0                	test   %eax,%eax
40001475:	75 1d                	jne    40001494 <protcheck+0xd2b>
40001477:	c7 85 44 fe ff ff 00 	movl   $0x40000100,-0x1bc(%ebp)
4000147e:	01 00 40 
40001481:	8b 85 44 fe ff ff    	mov    -0x1bc(%ebp),%eax
40001487:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
4000148d:	b8 03 00 00 00       	mov    $0x3,%eax
40001492:	cd 30                	int    $0x30
40001494:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000149b:	00 
4000149c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014a3:	00 
400014a4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400014ab:	e8 31 ed ff ff       	call   400001e1 <join>
	writefaulttest((int)etext-4);
400014b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014b7:	00 
400014b8:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400014bf:	e8 4c ec ff ff       	call   40000110 <fork>
400014c4:	85 c0                	test   %eax,%eax
400014c6:	75 21                	jne    400014e9 <protcheck+0xd80>
400014c8:	b8 75 3b 00 40       	mov    $0x40003b75,%eax
400014cd:	83 e8 04             	sub    $0x4,%eax
400014d0:	89 85 48 fe ff ff    	mov    %eax,-0x1b8(%ebp)
400014d6:	8b 85 48 fe ff ff    	mov    -0x1b8(%ebp),%eax
400014dc:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400014e2:	b8 03 00 00 00       	mov    $0x3,%eax
400014e7:	cd 30                	int    $0x30
400014e9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400014f0:	00 
400014f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400014f8:	00 
400014f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001500:	e8 dc ec ff ff       	call   400001e1 <join>
	getfaulttest((int)start);
40001505:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000150c:	00 
4000150d:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001514:	e8 f7 eb ff ff       	call   40000110 <fork>
40001519:	85 c0                	test   %eax,%eax
4000151b:	75 49                	jne    40001566 <protcheck+0xdfd>
4000151d:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001522:	c7 45 cc 00 10 00 00 	movl   $0x1000,-0x34(%ebp)
40001529:	66 c7 45 ca 00 00    	movw   $0x0,-0x36(%ebp)
4000152f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
40001532:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
40001539:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
40001540:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001547:	8b 45 cc             	mov    -0x34(%ebp),%eax
4000154a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000154d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
40001550:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
40001554:	8b 75 c0             	mov    -0x40(%ebp),%esi
40001557:	8b 7d bc             	mov    -0x44(%ebp),%edi
4000155a:	8b 4d b8             	mov    -0x48(%ebp),%ecx
4000155d:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000155f:	b8 03 00 00 00       	mov    $0x3,%eax
40001564:	cd 30                	int    $0x30
40001566:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000156d:	00 
4000156e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001575:	00 
40001576:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000157d:	e8 5f ec ff ff       	call   400001e1 <join>
	getfaulttest((int)etext-4);
40001582:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001589:	00 
4000158a:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001591:	e8 7a eb ff ff       	call   40000110 <fork>
40001596:	85 c0                	test   %eax,%eax
40001598:	75 4c                	jne    400015e6 <protcheck+0xe7d>
4000159a:	b8 75 3b 00 40       	mov    $0x40003b75,%eax
4000159f:	83 e8 04             	sub    $0x4,%eax
400015a2:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
400015a9:	66 c7 45 e2 00 00    	movw   $0x0,-0x1e(%ebp)
400015af:	89 45 dc             	mov    %eax,-0x24(%ebp)
400015b2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
400015b9:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
400015c0:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400015c7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
400015ca:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400015cd:	8b 5d dc             	mov    -0x24(%ebp),%ebx
400015d0:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
400015d4:	8b 75 d8             	mov    -0x28(%ebp),%esi
400015d7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
400015da:	8b 4d d0             	mov    -0x30(%ebp),%ecx
400015dd:	cd 30                	int    $0x30
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400015df:	b8 03 00 00 00       	mov    $0x3,%eax
400015e4:	cd 30                	int    $0x30
400015e6:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400015ed:	00 
400015ee:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400015f5:	00 
400015f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400015fd:	e8 df eb ff ff       	call   400001e1 <join>

	cprintf("testvm: protcheck passed\n");
40001602:	c7 04 24 09 3d 00 40 	movl   $0x40003d09,(%esp)
40001609:	e8 3b 18 00 00       	call   40002e49 <cprintf>
}
4000160e:	81 c4 cc 01 00 00    	add    $0x1cc,%esp
40001614:	5b                   	pop    %ebx
40001615:	5e                   	pop    %esi
40001616:	5f                   	pop    %edi
40001617:	5d                   	pop    %ebp
40001618:	c3                   	ret    

40001619 <memopcheck>:

// Test explicit memory management operations
void
memopcheck(void)
{
40001619:	55                   	push   %ebp
4000161a:	89 e5                	mov    %esp,%ebp
4000161c:	57                   	push   %edi
4000161d:	56                   	push   %esi
4000161e:	53                   	push   %ebx
4000161f:	81 ec 5c 02 00 00    	sub    $0x25c,%esp
	// Test page permission changes
	void *va = (void*)VM_USERLO+PTSIZE+PAGESIZE;
40001625:	c7 85 b0 fd ff ff 00 	movl   $0x40401000,-0x250(%ebp)
4000162c:	10 40 40 
	readfaulttest(va);
4000162f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001636:	00 
40001637:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000163e:	e8 cd ea ff ff       	call   40000110 <fork>
40001643:	85 c0                	test   %eax,%eax
40001645:	75 0f                	jne    40001656 <memopcheck+0x3d>
40001647:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
4000164d:	8b 00                	mov    (%eax),%eax
4000164f:	b8 03 00 00 00       	mov    $0x3,%eax
40001654:	cd 30                	int    $0x30
40001656:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000165d:	00 
4000165e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001665:	00 
40001666:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000166d:	e8 6f eb ff ff       	call   400001e1 <join>
40001672:	c7 85 ec fd ff ff 00 	movl   $0x300,-0x214(%ebp)
40001679:	03 00 00 
4000167c:	66 c7 85 ea fd ff ff 	movw   $0x0,-0x216(%ebp)
40001683:	00 00 
40001685:	c7 85 e4 fd ff ff 00 	movl   $0x0,-0x21c(%ebp)
4000168c:	00 00 00 
4000168f:	c7 85 e0 fd ff ff 00 	movl   $0x0,-0x220(%ebp)
40001696:	00 00 00 
40001699:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
4000169f:	89 85 dc fd ff ff    	mov    %eax,-0x224(%ebp)
400016a5:	c7 85 d8 fd ff ff 00 	movl   $0x1000,-0x228(%ebp)
400016ac:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400016af:	8b 85 ec fd ff ff    	mov    -0x214(%ebp),%eax
400016b5:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400016b8:	8b 9d e4 fd ff ff    	mov    -0x21c(%ebp),%ebx
400016be:	0f b7 95 ea fd ff ff 	movzwl -0x216(%ebp),%edx
400016c5:	8b b5 e0 fd ff ff    	mov    -0x220(%ebp),%esi
400016cb:	8b bd dc fd ff ff    	mov    -0x224(%ebp),%edi
400016d1:	8b 8d d8 fd ff ff    	mov    -0x228(%ebp),%ecx
400016d7:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// should be readable now
400016d9:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
400016df:	8b 00                	mov    (%eax),%eax
400016e1:	85 c0                	test   %eax,%eax
400016e3:	74 24                	je     40001709 <memopcheck+0xf0>
400016e5:	c7 44 24 0c 23 3d 00 	movl   $0x40003d23,0xc(%esp)
400016ec:	40 
400016ed:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400016f4:	40 
400016f5:	c7 44 24 04 09 01 00 	movl   $0x109,0x4(%esp)
400016fc:	00 
400016fd:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001704:	e8 af 14 00 00       	call   40002bb8 <debug_panic>
	writefaulttest(va);			// but not writable
40001709:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001710:	00 
40001711:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001718:	e8 f3 e9 ff ff       	call   40000110 <fork>
4000171d:	85 c0                	test   %eax,%eax
4000171f:	75 1f                	jne    40001740 <memopcheck+0x127>
40001721:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001727:	89 85 c4 fd ff ff    	mov    %eax,-0x23c(%ebp)
4000172d:	8b 85 c4 fd ff ff    	mov    -0x23c(%ebp),%eax
40001733:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001739:	b8 03 00 00 00       	mov    $0x3,%eax
4000173e:	cd 30                	int    $0x30
40001740:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001747:	00 
40001748:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000174f:	00 
40001750:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001757:	e8 85 ea ff ff       	call   400001e1 <join>
4000175c:	c7 85 04 fe ff ff 00 	movl   $0x700,-0x1fc(%ebp)
40001763:	07 00 00 
40001766:	66 c7 85 02 fe ff ff 	movw   $0x0,-0x1fe(%ebp)
4000176d:	00 00 
4000176f:	c7 85 fc fd ff ff 00 	movl   $0x0,-0x204(%ebp)
40001776:	00 00 00 
40001779:	c7 85 f8 fd ff ff 00 	movl   $0x0,-0x208(%ebp)
40001780:	00 00 00 
40001783:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001789:	89 85 f4 fd ff ff    	mov    %eax,-0x20c(%ebp)
4000178f:	c7 85 f0 fd ff ff 00 	movl   $0x1000,-0x210(%ebp)
40001796:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001799:	8b 85 04 fe ff ff    	mov    -0x1fc(%ebp),%eax
4000179f:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400017a2:	8b 9d fc fd ff ff    	mov    -0x204(%ebp),%ebx
400017a8:	0f b7 95 02 fe ff ff 	movzwl -0x1fe(%ebp),%edx
400017af:	8b b5 f8 fd ff ff    	mov    -0x208(%ebp),%esi
400017b5:	8b bd f4 fd ff ff    	mov    -0x20c(%ebp),%edi
400017bb:	8b 8d f0 fd ff ff    	mov    -0x210(%ebp),%ecx
400017c1:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// should be writable now
400017c3:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
400017c9:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
400017cf:	c7 85 1c fe ff ff 00 	movl   $0x100,-0x1e4(%ebp)
400017d6:	01 00 00 
400017d9:	66 c7 85 1a fe ff ff 	movw   $0x0,-0x1e6(%ebp)
400017e0:	00 00 
400017e2:	c7 85 14 fe ff ff 00 	movl   $0x0,-0x1ec(%ebp)
400017e9:	00 00 00 
400017ec:	c7 85 10 fe ff ff 00 	movl   $0x0,-0x1f0(%ebp)
400017f3:	00 00 00 
400017f6:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
400017fc:	89 85 0c fe ff ff    	mov    %eax,-0x1f4(%ebp)
40001802:	c7 85 08 fe ff ff 00 	movl   $0x1000,-0x1f8(%ebp)
40001809:	10 00 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000180c:	8b 85 1c fe ff ff    	mov    -0x1e4(%ebp),%eax
40001812:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001815:	8b 9d 14 fe ff ff    	mov    -0x1ec(%ebp),%ebx
4000181b:	0f b7 95 1a fe ff ff 	movzwl -0x1e6(%ebp),%edx
40001822:	8b b5 10 fe ff ff    	mov    -0x1f0(%ebp),%esi
40001828:	8b bd 0c fe ff ff    	mov    -0x1f4(%ebp),%edi
4000182e:	8b 8d 08 fe ff ff    	mov    -0x1f8(%ebp),%ecx
40001834:	cd 30                	int    $0x30
	sys_get(SYS_PERM, 0, NULL, NULL, va, PAGESIZE);	// revoke all perms
	readfaulttest(va);
40001836:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000183d:	00 
4000183e:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001845:	e8 c6 e8 ff ff       	call   40000110 <fork>
4000184a:	85 c0                	test   %eax,%eax
4000184c:	75 0f                	jne    4000185d <memopcheck+0x244>
4000184e:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001854:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001856:	b8 03 00 00 00       	mov    $0x3,%eax
4000185b:	cd 30                	int    $0x30
4000185d:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001864:	00 
40001865:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000186c:	00 
4000186d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001874:	e8 68 e9 ff ff       	call   400001e1 <join>
40001879:	c7 85 34 fe ff ff 00 	movl   $0x300,-0x1cc(%ebp)
40001880:	03 00 00 
40001883:	66 c7 85 32 fe ff ff 	movw   $0x0,-0x1ce(%ebp)
4000188a:	00 00 
4000188c:	c7 85 2c fe ff ff 00 	movl   $0x0,-0x1d4(%ebp)
40001893:	00 00 00 
40001896:	c7 85 28 fe ff ff 00 	movl   $0x0,-0x1d8(%ebp)
4000189d:	00 00 00 
400018a0:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
400018a6:	89 85 24 fe ff ff    	mov    %eax,-0x1dc(%ebp)
400018ac:	c7 85 20 fe ff ff 00 	movl   $0x1000,-0x1e0(%ebp)
400018b3:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400018b6:	8b 85 34 fe ff ff    	mov    -0x1cc(%ebp),%eax
400018bc:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400018bf:	8b 9d 2c fe ff ff    	mov    -0x1d4(%ebp),%ebx
400018c5:	0f b7 95 32 fe ff ff 	movzwl -0x1ce(%ebp),%edx
400018cc:	8b b5 28 fe ff ff    	mov    -0x1d8(%ebp),%esi
400018d2:	8b bd 24 fe ff ff    	mov    -0x1dc(%ebp),%edi
400018d8:	8b 8d 20 fe ff ff    	mov    -0x1e0(%ebp),%ecx
400018de:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0xdeadbeef);	// readable again
400018e0:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
400018e6:	8b 00                	mov    (%eax),%eax
400018e8:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400018ed:	74 24                	je     40001913 <memopcheck+0x2fa>
400018ef:	c7 44 24 0c 3c 3d 00 	movl   $0x40003d3c,0xc(%esp)
400018f6:	40 
400018f7:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400018fe:	40 
400018ff:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
40001906:	00 
40001907:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000190e:	e8 a5 12 00 00       	call   40002bb8 <debug_panic>
	writefaulttest(va);				// but not writable
40001913:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000191a:	00 
4000191b:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001922:	e8 e9 e7 ff ff       	call   40000110 <fork>
40001927:	85 c0                	test   %eax,%eax
40001929:	75 1f                	jne    4000194a <memopcheck+0x331>
4000192b:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001931:	89 85 c8 fd ff ff    	mov    %eax,-0x238(%ebp)
40001937:	8b 85 c8 fd ff ff    	mov    -0x238(%ebp),%eax
4000193d:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001943:	b8 03 00 00 00       	mov    $0x3,%eax
40001948:	cd 30                	int    $0x30
4000194a:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001951:	00 
40001952:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001959:	00 
4000195a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001961:	e8 7b e8 ff ff       	call   400001e1 <join>
40001966:	c7 85 4c fe ff ff 00 	movl   $0x700,-0x1b4(%ebp)
4000196d:	07 00 00 
40001970:	66 c7 85 4a fe ff ff 	movw   $0x0,-0x1b6(%ebp)
40001977:	00 00 
40001979:	c7 85 44 fe ff ff 00 	movl   $0x0,-0x1bc(%ebp)
40001980:	00 00 00 
40001983:	c7 85 40 fe ff ff 00 	movl   $0x0,-0x1c0(%ebp)
4000198a:	00 00 00 
4000198d:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001993:	89 85 3c fe ff ff    	mov    %eax,-0x1c4(%ebp)
40001999:	c7 85 38 fe ff ff 00 	movl   $0x1000,-0x1c8(%ebp)
400019a0:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400019a3:	8b 85 4c fe ff ff    	mov    -0x1b4(%ebp),%eax
400019a9:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400019ac:	8b 9d 44 fe ff ff    	mov    -0x1bc(%ebp),%ebx
400019b2:	0f b7 95 4a fe ff ff 	movzwl -0x1b6(%ebp),%edx
400019b9:	8b b5 40 fe ff ff    	mov    -0x1c0(%ebp),%esi
400019bf:	8b bd 3c fe ff ff    	mov    -0x1c4(%ebp),%edi
400019c5:	8b 8d 38 fe ff ff    	mov    -0x1c8(%ebp),%ecx
400019cb:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);

	// Test SYS_ZERO with SYS_GET
	va = (void*)VM_USERLO+PTSIZE;	// 4MB-aligned
400019cd:	c7 85 b0 fd ff ff 00 	movl   $0x40400000,-0x250(%ebp)
400019d4:	00 40 40 
400019d7:	c7 85 64 fe ff ff 00 	movl   $0x10000,-0x19c(%ebp)
400019de:	00 01 00 
400019e1:	66 c7 85 62 fe ff ff 	movw   $0x0,-0x19e(%ebp)
400019e8:	00 00 
400019ea:	c7 85 5c fe ff ff 00 	movl   $0x0,-0x1a4(%ebp)
400019f1:	00 00 00 
400019f4:	c7 85 58 fe ff ff 00 	movl   $0x0,-0x1a8(%ebp)
400019fb:	00 00 00 
400019fe:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001a04:	89 85 54 fe ff ff    	mov    %eax,-0x1ac(%ebp)
40001a0a:	c7 85 50 fe ff ff 00 	movl   $0x400000,-0x1b0(%ebp)
40001a11:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001a14:	8b 85 64 fe ff ff    	mov    -0x19c(%ebp),%eax
40001a1a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001a1d:	8b 9d 5c fe ff ff    	mov    -0x1a4(%ebp),%ebx
40001a23:	0f b7 95 62 fe ff ff 	movzwl -0x19e(%ebp),%edx
40001a2a:	8b b5 58 fe ff ff    	mov    -0x1a8(%ebp),%esi
40001a30:	8b bd 54 fe ff ff    	mov    -0x1ac(%ebp),%edi
40001a36:	8b 8d 50 fe ff ff    	mov    -0x1b0(%ebp),%ecx
40001a3c:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);		// should be inaccessible again
40001a3e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a45:	00 
40001a46:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001a4d:	e8 be e6 ff ff       	call   40000110 <fork>
40001a52:	85 c0                	test   %eax,%eax
40001a54:	75 0f                	jne    40001a65 <memopcheck+0x44c>
40001a56:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001a5c:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001a5e:	b8 03 00 00 00       	mov    $0x3,%eax
40001a63:	cd 30                	int    $0x30
40001a65:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001a6c:	00 
40001a6d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001a74:	00 
40001a75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001a7c:	e8 60 e7 ff ff       	call   400001e1 <join>
40001a81:	c7 85 7c fe ff ff 00 	movl   $0x300,-0x184(%ebp)
40001a88:	03 00 00 
40001a8b:	66 c7 85 7a fe ff ff 	movw   $0x0,-0x186(%ebp)
40001a92:	00 00 
40001a94:	c7 85 74 fe ff ff 00 	movl   $0x0,-0x18c(%ebp)
40001a9b:	00 00 00 
40001a9e:	c7 85 70 fe ff ff 00 	movl   $0x0,-0x190(%ebp)
40001aa5:	00 00 00 
40001aa8:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001aae:	89 85 6c fe ff ff    	mov    %eax,-0x194(%ebp)
40001ab4:	c7 85 68 fe ff ff 00 	movl   $0x1000,-0x198(%ebp)
40001abb:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001abe:	8b 85 7c fe ff ff    	mov    -0x184(%ebp),%eax
40001ac4:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001ac7:	8b 9d 74 fe ff ff    	mov    -0x18c(%ebp),%ebx
40001acd:	0f b7 95 7a fe ff ff 	movzwl -0x186(%ebp),%edx
40001ad4:	8b b5 70 fe ff ff    	mov    -0x190(%ebp),%esi
40001ada:	8b bd 6c fe ff ff    	mov    -0x194(%ebp),%edi
40001ae0:	8b 8d 68 fe ff ff    	mov    -0x198(%ebp),%ecx
40001ae6:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001ae8:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001aee:	8b 00                	mov    (%eax),%eax
40001af0:	85 c0                	test   %eax,%eax
40001af2:	74 24                	je     40001b18 <memopcheck+0x4ff>
40001af4:	c7 44 24 0c 23 3d 00 	movl   $0x40003d23,0xc(%esp)
40001afb:	40 
40001afc:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40001b03:	40 
40001b04:	c7 44 24 04 19 01 00 	movl   $0x119,0x4(%esp)
40001b0b:	00 
40001b0c:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001b13:	e8 a0 10 00 00       	call   40002bb8 <debug_panic>
	writefaulttest(va);			// but not writable
40001b18:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b1f:	00 
40001b20:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001b27:	e8 e4 e5 ff ff       	call   40000110 <fork>
40001b2c:	85 c0                	test   %eax,%eax
40001b2e:	75 1f                	jne    40001b4f <memopcheck+0x536>
40001b30:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001b36:	89 85 cc fd ff ff    	mov    %eax,-0x234(%ebp)
40001b3c:	8b 85 cc fd ff ff    	mov    -0x234(%ebp),%eax
40001b42:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001b48:	b8 03 00 00 00       	mov    $0x3,%eax
40001b4d:	cd 30                	int    $0x30
40001b4f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001b56:	00 
40001b57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001b5e:	00 
40001b5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001b66:	e8 76 e6 ff ff       	call   400001e1 <join>
40001b6b:	c7 85 94 fe ff ff 00 	movl   $0x10000,-0x16c(%ebp)
40001b72:	00 01 00 
40001b75:	66 c7 85 92 fe ff ff 	movw   $0x0,-0x16e(%ebp)
40001b7c:	00 00 
40001b7e:	c7 85 8c fe ff ff 00 	movl   $0x0,-0x174(%ebp)
40001b85:	00 00 00 
40001b88:	c7 85 88 fe ff ff 00 	movl   $0x0,-0x178(%ebp)
40001b8f:	00 00 00 
40001b92:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001b98:	89 85 84 fe ff ff    	mov    %eax,-0x17c(%ebp)
40001b9e:	c7 85 80 fe ff ff 00 	movl   $0x400000,-0x180(%ebp)
40001ba5:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001ba8:	8b 85 94 fe ff ff    	mov    -0x16c(%ebp),%eax
40001bae:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001bb1:	8b 9d 8c fe ff ff    	mov    -0x174(%ebp),%ebx
40001bb7:	0f b7 95 92 fe ff ff 	movzwl -0x16e(%ebp),%edx
40001bbe:	8b b5 88 fe ff ff    	mov    -0x178(%ebp),%esi
40001bc4:	8b bd 84 fe ff ff    	mov    -0x17c(%ebp),%edi
40001bca:	8b 8d 80 fe ff ff    	mov    -0x180(%ebp),%ecx
40001bd0:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001bd2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001bd9:	00 
40001bda:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001be1:	e8 2a e5 ff ff       	call   40000110 <fork>
40001be6:	85 c0                	test   %eax,%eax
40001be8:	75 0f                	jne    40001bf9 <memopcheck+0x5e0>
40001bea:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001bf0:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001bf2:	b8 03 00 00 00       	mov    $0x3,%eax
40001bf7:	cd 30                	int    $0x30
40001bf9:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001c00:	00 
40001c01:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001c08:	00 
40001c09:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001c10:	e8 cc e5 ff ff       	call   400001e1 <join>
40001c15:	c7 85 ac fe ff ff 00 	movl   $0x700,-0x154(%ebp)
40001c1c:	07 00 00 
40001c1f:	66 c7 85 aa fe ff ff 	movw   $0x0,-0x156(%ebp)
40001c26:	00 00 
40001c28:	c7 85 a4 fe ff ff 00 	movl   $0x0,-0x15c(%ebp)
40001c2f:	00 00 00 
40001c32:	c7 85 a0 fe ff ff 00 	movl   $0x0,-0x160(%ebp)
40001c39:	00 00 00 
40001c3c:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001c42:	89 85 9c fe ff ff    	mov    %eax,-0x164(%ebp)
40001c48:	c7 85 98 fe ff ff 00 	movl   $0x1000,-0x168(%ebp)
40001c4f:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001c52:	8b 85 ac fe ff ff    	mov    -0x154(%ebp),%eax
40001c58:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001c5b:	8b 9d a4 fe ff ff    	mov    -0x15c(%ebp),%ebx
40001c61:	0f b7 95 aa fe ff ff 	movzwl -0x156(%ebp),%edx
40001c68:	8b b5 a0 fe ff ff    	mov    -0x160(%ebp),%esi
40001c6e:	8b bd 9c fe ff ff    	mov    -0x164(%ebp),%edi
40001c74:	8b 8d 98 fe ff ff    	mov    -0x168(%ebp),%ecx
40001c7a:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ | SYS_WRITE, 0, NULL, NULL, va, PAGESIZE);
	*(volatile int*)va = 0xdeadbeef;	// writable now
40001c7c:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001c82:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
40001c88:	c7 85 c4 fe ff ff 00 	movl   $0x10000,-0x13c(%ebp)
40001c8f:	00 01 00 
40001c92:	66 c7 85 c2 fe ff ff 	movw   $0x0,-0x13e(%ebp)
40001c99:	00 00 
40001c9b:	c7 85 bc fe ff ff 00 	movl   $0x0,-0x144(%ebp)
40001ca2:	00 00 00 
40001ca5:	c7 85 b8 fe ff ff 00 	movl   $0x0,-0x148(%ebp)
40001cac:	00 00 00 
40001caf:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001cb5:	89 85 b4 fe ff ff    	mov    %eax,-0x14c(%ebp)
40001cbb:	c7 85 b0 fe ff ff 00 	movl   $0x400000,-0x150(%ebp)
40001cc2:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001cc5:	8b 85 c4 fe ff ff    	mov    -0x13c(%ebp),%eax
40001ccb:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001cce:	8b 9d bc fe ff ff    	mov    -0x144(%ebp),%ebx
40001cd4:	0f b7 95 c2 fe ff ff 	movzwl -0x13e(%ebp),%edx
40001cdb:	8b b5 b8 fe ff ff    	mov    -0x148(%ebp),%esi
40001ce1:	8b bd b4 fe ff ff    	mov    -0x14c(%ebp),%edi
40001ce7:	8b 8d b0 fe ff ff    	mov    -0x150(%ebp),%ecx
40001ced:	cd 30                	int    $0x30
	sys_get(SYS_ZERO, 0, NULL, NULL, va, PTSIZE);
	readfaulttest(va);			// gone again
40001cef:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001cf6:	00 
40001cf7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001cfe:	e8 0d e4 ff ff       	call   40000110 <fork>
40001d03:	85 c0                	test   %eax,%eax
40001d05:	75 0f                	jne    40001d16 <memopcheck+0x6fd>
40001d07:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001d0d:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001d0f:	b8 03 00 00 00       	mov    $0x3,%eax
40001d14:	cd 30                	int    $0x30
40001d16:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001d1d:	00 
40001d1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001d25:	00 
40001d26:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001d2d:	e8 af e4 ff ff       	call   400001e1 <join>
40001d32:	c7 85 dc fe ff ff 00 	movl   $0x300,-0x124(%ebp)
40001d39:	03 00 00 
40001d3c:	66 c7 85 da fe ff ff 	movw   $0x0,-0x126(%ebp)
40001d43:	00 00 
40001d45:	c7 85 d4 fe ff ff 00 	movl   $0x0,-0x12c(%ebp)
40001d4c:	00 00 00 
40001d4f:	c7 85 d0 fe ff ff 00 	movl   $0x0,-0x130(%ebp)
40001d56:	00 00 00 
40001d59:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001d5f:	89 85 cc fe ff ff    	mov    %eax,-0x134(%ebp)
40001d65:	c7 85 c8 fe ff ff 00 	movl   $0x1000,-0x138(%ebp)
40001d6c:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001d6f:	8b 85 dc fe ff ff    	mov    -0x124(%ebp),%eax
40001d75:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001d78:	8b 9d d4 fe ff ff    	mov    -0x12c(%ebp),%ebx
40001d7e:	0f b7 95 da fe ff ff 	movzwl -0x126(%ebp),%edx
40001d85:	8b b5 d0 fe ff ff    	mov    -0x130(%ebp),%esi
40001d8b:	8b bd cc fe ff ff    	mov    -0x134(%ebp),%edi
40001d91:	8b 8d c8 fe ff ff    	mov    -0x138(%ebp),%ecx
40001d97:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, va, PAGESIZE);
	assert(*(volatile int*)va == 0);	// and zeroed
40001d99:	8b 85 b0 fd ff ff    	mov    -0x250(%ebp),%eax
40001d9f:	8b 00                	mov    (%eax),%eax
40001da1:	85 c0                	test   %eax,%eax
40001da3:	74 24                	je     40001dc9 <memopcheck+0x7b0>
40001da5:	c7 44 24 0c 23 3d 00 	movl   $0x40003d23,0xc(%esp)
40001dac:	40 
40001dad:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40001db4:	40 
40001db5:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
40001dbc:	00 
40001dbd:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001dc4:	e8 ef 0d 00 00       	call   40002bb8 <debug_panic>

	// Test SYS_COPY with SYS_GET - pull residual stuff out of child 0
	void *sva = (void*)VM_USERLO;
40001dc9:	c7 85 b4 fd ff ff 00 	movl   $0x40000000,-0x24c(%ebp)
40001dd0:	00 00 40 
	void *dva = (void*)VM_USERLO+PTSIZE;
40001dd3:	c7 85 b8 fd ff ff 00 	movl   $0x40400000,-0x248(%ebp)
40001dda:	00 40 40 
40001ddd:	c7 85 f4 fe ff ff 00 	movl   $0x20000,-0x10c(%ebp)
40001de4:	00 02 00 
40001de7:	66 c7 85 f2 fe ff ff 	movw   $0x0,-0x10e(%ebp)
40001dee:	00 00 
40001df0:	c7 85 ec fe ff ff 00 	movl   $0x0,-0x114(%ebp)
40001df7:	00 00 00 
40001dfa:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
40001e00:	89 85 e8 fe ff ff    	mov    %eax,-0x118(%ebp)
40001e06:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001e0c:	89 85 e4 fe ff ff    	mov    %eax,-0x11c(%ebp)
40001e12:	c7 85 e0 fe ff ff 00 	movl   $0x400000,-0x120(%ebp)
40001e19:	00 40 00 
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001e1c:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
40001e22:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001e25:	8b 9d ec fe ff ff    	mov    -0x114(%ebp),%ebx
40001e2b:	0f b7 95 f2 fe ff ff 	movzwl -0x10e(%ebp),%edx
40001e32:	8b b5 e8 fe ff ff    	mov    -0x118(%ebp),%esi
40001e38:	8b bd e4 fe ff ff    	mov    -0x11c(%ebp),%edi
40001e3e:	8b 8d e0 fe ff ff    	mov    -0x120(%ebp),%ecx
40001e44:	cd 30                	int    $0x30
	sys_get(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	assert(memcmp(sva, dva, etext - start) == 0);
40001e46:	ba 75 3b 00 40       	mov    $0x40003b75,%edx
40001e4b:	b8 00 01 00 40       	mov    $0x40000100,%eax
40001e50:	89 d1                	mov    %edx,%ecx
40001e52:	29 c1                	sub    %eax,%ecx
40001e54:	89 c8                	mov    %ecx,%eax
40001e56:	89 44 24 08          	mov    %eax,0x8(%esp)
40001e5a:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001e60:	89 44 24 04          	mov    %eax,0x4(%esp)
40001e64:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
40001e6a:	89 04 24             	mov    %eax,(%esp)
40001e6d:	e8 e6 19 00 00       	call   40003858 <memcmp>
40001e72:	85 c0                	test   %eax,%eax
40001e74:	74 24                	je     40001e9a <memopcheck+0x881>
40001e76:	c7 44 24 0c 60 3d 00 	movl   $0x40003d60,0xc(%esp)
40001e7d:	40 
40001e7e:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40001e85:	40 
40001e86:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
40001e8d:	00 
40001e8e:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40001e95:	e8 1e 0d 00 00       	call   40002bb8 <debug_panic>
	writefaulttest(dva);
40001e9a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ea1:	00 
40001ea2:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001ea9:	e8 62 e2 ff ff       	call   40000110 <fork>
40001eae:	85 c0                	test   %eax,%eax
40001eb0:	75 1f                	jne    40001ed1 <memopcheck+0x8b8>
40001eb2:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001eb8:	89 85 d0 fd ff ff    	mov    %eax,-0x230(%ebp)
40001ebe:	8b 85 d0 fd ff ff    	mov    -0x230(%ebp),%eax
40001ec4:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40001eca:	b8 03 00 00 00       	mov    $0x3,%eax
40001ecf:	cd 30                	int    $0x30
40001ed1:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001ed8:	00 
40001ed9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ee0:	00 
40001ee1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001ee8:	e8 f4 e2 ff ff       	call   400001e1 <join>
	readfaulttest(dva + PTSIZE-4);
40001eed:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001ef4:	00 
40001ef5:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40001efc:	e8 0f e2 ff ff       	call   40000110 <fork>
40001f01:	85 c0                	test   %eax,%eax
40001f03:	75 14                	jne    40001f19 <memopcheck+0x900>
40001f05:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001f0b:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40001f10:	8b 00                	mov    (%eax),%eax
40001f12:	b8 03 00 00 00       	mov    $0x3,%eax
40001f17:	cd 30                	int    $0x30
40001f19:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40001f20:	00 
40001f21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40001f28:	00 
40001f29:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40001f30:	e8 ac e2 ff ff       	call   400001e1 <join>

	// Test SYS_ZERO with SYS_PUT
	void *dva2 = (void*)VM_USERLO+PTSIZE*2;
40001f35:	c7 85 bc fd ff ff 00 	movl   $0x40800000,-0x244(%ebp)
40001f3c:	00 80 40 
40001f3f:	c7 85 0c ff ff ff 00 	movl   $0x10000,-0xf4(%ebp)
40001f46:	00 01 00 
40001f49:	66 c7 85 0a ff ff ff 	movw   $0x0,-0xf6(%ebp)
40001f50:	00 00 
40001f52:	c7 85 04 ff ff ff 00 	movl   $0x0,-0xfc(%ebp)
40001f59:	00 00 00 
40001f5c:	c7 85 00 ff ff ff 00 	movl   $0x0,-0x100(%ebp)
40001f63:	00 00 00 
40001f66:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001f6c:	89 85 fc fe ff ff    	mov    %eax,-0x104(%ebp)
40001f72:	c7 85 f8 fe ff ff 00 	movl   $0x400000,-0x108(%ebp)
40001f79:	00 40 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40001f7c:	8b 85 0c ff ff ff    	mov    -0xf4(%ebp),%eax
40001f82:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
40001f85:	8b 9d 04 ff ff ff    	mov    -0xfc(%ebp),%ebx
40001f8b:	0f b7 95 0a ff ff ff 	movzwl -0xf6(%ebp),%edx
40001f92:	8b b5 00 ff ff ff    	mov    -0x100(%ebp),%esi
40001f98:	8b bd fc fe ff ff    	mov    -0x104(%ebp),%edi
40001f9e:	8b 8d f8 fe ff ff    	mov    -0x108(%ebp),%ecx
40001fa4:	cd 30                	int    $0x30
40001fa6:	c7 85 24 ff ff ff 00 	movl   $0x20000,-0xdc(%ebp)
40001fad:	00 02 00 
40001fb0:	66 c7 85 22 ff ff ff 	movw   $0x0,-0xde(%ebp)
40001fb7:	00 00 
40001fb9:	c7 85 1c ff ff ff 00 	movl   $0x0,-0xe4(%ebp)
40001fc0:	00 00 00 
40001fc3:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40001fc9:	89 85 18 ff ff ff    	mov    %eax,-0xe8(%ebp)
40001fcf:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40001fd5:	89 85 14 ff ff ff    	mov    %eax,-0xec(%ebp)
40001fdb:	c7 85 10 ff ff ff 00 	movl   $0x400000,-0xf0(%ebp)
40001fe2:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40001fe5:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
40001feb:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40001fee:	8b 9d 1c ff ff ff    	mov    -0xe4(%ebp),%ebx
40001ff4:	0f b7 95 22 ff ff ff 	movzwl -0xde(%ebp),%edx
40001ffb:	8b b5 18 ff ff ff    	mov    -0xe8(%ebp),%esi
40002001:	8b bd 14 ff ff ff    	mov    -0xec(%ebp),%edi
40002007:	8b 8d 10 ff ff ff    	mov    -0xf0(%ebp),%ecx
4000200d:	cd 30                	int    $0x30
	sys_put(SYS_ZERO, 0, NULL, NULL, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2);
4000200f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002016:	00 
40002017:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000201e:	e8 ed e0 ff ff       	call   40000110 <fork>
40002023:	85 c0                	test   %eax,%eax
40002025:	75 0f                	jne    40002036 <memopcheck+0xa1d>
40002027:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
4000202d:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
4000202f:	b8 03 00 00 00       	mov    $0x3,%eax
40002034:	cd 30                	int    $0x30
40002036:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
4000203d:	00 
4000203e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002045:	00 
40002046:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
4000204d:	e8 8f e1 ff ff       	call   400001e1 <join>
	readfaulttest(dva2 + PTSIZE-4);
40002052:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002059:	00 
4000205a:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002061:	e8 aa e0 ff ff       	call   40000110 <fork>
40002066:	85 c0                	test   %eax,%eax
40002068:	75 14                	jne    4000207e <memopcheck+0xa65>
4000206a:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40002070:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002075:	8b 00                	mov    (%eax),%eax
40002077:	b8 03 00 00 00       	mov    $0x3,%eax
4000207c:	cd 30                	int    $0x30
4000207e:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002085:	00 
40002086:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000208d:	00 
4000208e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002095:	e8 47 e1 ff ff       	call   400001e1 <join>
4000209a:	c7 85 3c ff ff ff 00 	movl   $0x300,-0xc4(%ebp)
400020a1:	03 00 00 
400020a4:	66 c7 85 3a ff ff ff 	movw   $0x0,-0xc6(%ebp)
400020ab:	00 00 
400020ad:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
400020b4:	00 00 00 
400020b7:	c7 85 30 ff ff ff 00 	movl   $0x0,-0xd0(%ebp)
400020be:	00 00 00 
400020c1:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
400020c7:	89 85 2c ff ff ff    	mov    %eax,-0xd4(%ebp)
400020cd:	c7 85 28 ff ff ff 00 	movl   $0x400000,-0xd8(%ebp)
400020d4:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400020d7:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
400020dd:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400020e0:	8b 9d 34 ff ff ff    	mov    -0xcc(%ebp),%ebx
400020e6:	0f b7 95 3a ff ff ff 	movzwl -0xc6(%ebp),%edx
400020ed:	8b b5 30 ff ff ff    	mov    -0xd0(%ebp),%esi
400020f3:	8b bd 2c ff ff ff    	mov    -0xd4(%ebp),%edi
400020f9:	8b 8d 28 ff ff ff    	mov    -0xd8(%ebp),%ecx
400020ff:	cd 30                	int    $0x30
	sys_get(SYS_PERM | SYS_READ, 0, NULL, NULL, dva2, PTSIZE);
	assert(*(volatile int*)dva2 == 0);
40002101:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40002107:	8b 00                	mov    (%eax),%eax
40002109:	85 c0                	test   %eax,%eax
4000210b:	74 24                	je     40002131 <memopcheck+0xb18>
4000210d:	c7 44 24 0c 85 3d 00 	movl   $0x40003d85,0xc(%esp)
40002114:	40 
40002115:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
4000211c:	40 
4000211d:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
40002124:	00 
40002125:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000212c:	e8 87 0a 00 00       	call   40002bb8 <debug_panic>
	assert(*(volatile int*)(dva2+PTSIZE-4) == 0);
40002131:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40002137:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
4000213c:	8b 00                	mov    (%eax),%eax
4000213e:	85 c0                	test   %eax,%eax
40002140:	74 24                	je     40002166 <memopcheck+0xb4d>
40002142:	c7 44 24 0c a0 3d 00 	movl   $0x40003da0,0xc(%esp)
40002149:	40 
4000214a:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002151:	40 
40002152:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
40002159:	00 
4000215a:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002161:	e8 52 0a 00 00       	call   40002bb8 <debug_panic>
40002166:	c7 85 54 ff ff ff 00 	movl   $0x20000,-0xac(%ebp)
4000216d:	00 02 00 
40002170:	66 c7 85 52 ff ff ff 	movw   $0x0,-0xae(%ebp)
40002177:	00 00 
40002179:	c7 85 4c ff ff ff 00 	movl   $0x0,-0xb4(%ebp)
40002180:	00 00 00 
40002183:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
40002189:	89 85 48 ff ff ff    	mov    %eax,-0xb8(%ebp)
4000218f:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40002195:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)
4000219b:	c7 85 40 ff ff ff 00 	movl   $0x400000,-0xc0(%ebp)
400021a2:	00 40 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
400021a5:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
400021ab:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
400021ae:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
400021b4:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
400021bb:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
400021c1:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
400021c7:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
400021cd:	cd 30                	int    $0x30
400021cf:	c7 85 6c ff ff ff 00 	movl   $0x20000,-0x94(%ebp)
400021d6:	00 02 00 
400021d9:	66 c7 85 6a ff ff ff 	movw   $0x0,-0x96(%ebp)
400021e0:	00 00 
400021e2:	c7 85 64 ff ff ff 00 	movl   $0x0,-0x9c(%ebp)
400021e9:	00 00 00 
400021ec:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
400021f2:	89 85 60 ff ff ff    	mov    %eax,-0xa0(%ebp)
400021f8:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
400021fe:	89 85 5c ff ff ff    	mov    %eax,-0xa4(%ebp)
40002204:	c7 85 58 ff ff ff 00 	movl   $0x400000,-0xa8(%ebp)
4000220b:	00 40 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000220e:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
40002214:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002217:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
4000221d:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
40002224:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
4000222a:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
40002230:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
40002236:	cd 30                	int    $0x30

	// Test SYS_COPY with SYS_PUT
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	assert(memcmp(sva, dva2, etext - start) == 0);
40002238:	ba 75 3b 00 40       	mov    $0x40003b75,%edx
4000223d:	b8 00 01 00 40       	mov    $0x40000100,%eax
40002242:	89 d1                	mov    %edx,%ecx
40002244:	29 c1                	sub    %eax,%ecx
40002246:	89 c8                	mov    %ecx,%eax
40002248:	89 44 24 08          	mov    %eax,0x8(%esp)
4000224c:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40002252:	89 44 24 04          	mov    %eax,0x4(%esp)
40002256:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
4000225c:	89 04 24             	mov    %eax,(%esp)
4000225f:	e8 f4 15 00 00       	call   40003858 <memcmp>
40002264:	85 c0                	test   %eax,%eax
40002266:	74 24                	je     4000228c <memopcheck+0xc73>
40002268:	c7 44 24 0c c8 3d 00 	movl   $0x40003dc8,0xc(%esp)
4000226f:	40 
40002270:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002277:	40 
40002278:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
4000227f:	00 
40002280:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002287:	e8 2c 09 00 00       	call   40002bb8 <debug_panic>
	writefaulttest(dva2);
4000228c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002293:	00 
40002294:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000229b:	e8 70 de ff ff       	call   40000110 <fork>
400022a0:	85 c0                	test   %eax,%eax
400022a2:	75 1f                	jne    400022c3 <memopcheck+0xcaa>
400022a4:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
400022aa:	89 85 d4 fd ff ff    	mov    %eax,-0x22c(%ebp)
400022b0:	8b 85 d4 fd ff ff    	mov    -0x22c(%ebp),%eax
400022b6:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
400022bc:	b8 03 00 00 00       	mov    $0x3,%eax
400022c1:	cd 30                	int    $0x30
400022c3:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
400022ca:	00 
400022cb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022d2:	00 
400022d3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
400022da:	e8 02 df ff ff       	call   400001e1 <join>
	readfaulttest(dva2 + PTSIZE-4);
400022df:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400022e6:	00 
400022e7:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
400022ee:	e8 1d de ff ff       	call   40000110 <fork>
400022f3:	85 c0                	test   %eax,%eax
400022f5:	75 14                	jne    4000230b <memopcheck+0xcf2>
400022f7:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
400022fd:	05 fc ff 3f 00       	add    $0x3ffffc,%eax
40002302:	8b 00                	mov    (%eax),%eax
40002304:	b8 03 00 00 00       	mov    $0x3,%eax
40002309:	cd 30                	int    $0x30
4000230b:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002312:	00 
40002313:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000231a:	00 
4000231b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002322:	e8 ba de ff ff       	call   400001e1 <join>

	// Hide an easter egg and make sure it survives the two copies
	sva = (void*)VM_USERLO; dva = sva+PTSIZE; dva2 = dva+PTSIZE;
40002327:	c7 85 b4 fd ff ff 00 	movl   $0x40000000,-0x24c(%ebp)
4000232e:	00 00 40 
40002331:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
40002337:	05 00 00 40 00       	add    $0x400000,%eax
4000233c:	89 85 b8 fd ff ff    	mov    %eax,-0x248(%ebp)
40002342:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
40002348:	05 00 00 40 00       	add    $0x400000,%eax
4000234d:	89 85 bc fd ff ff    	mov    %eax,-0x244(%ebp)
	uint32_t ofs = PTSIZE-PAGESIZE;
40002353:	c7 85 c0 fd ff ff 00 	movl   $0x3ff000,-0x240(%ebp)
4000235a:	f0 3f 00 
	sys_get(SYS_PERM|SYS_READ|SYS_WRITE, 0, NULL, NULL, sva+ofs, PAGESIZE);
4000235d:	8b 85 c0 fd ff ff    	mov    -0x240(%ebp),%eax
40002363:	8b 95 b4 fd ff ff    	mov    -0x24c(%ebp),%edx
40002369:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000236c:	c7 45 84 00 07 00 00 	movl   $0x700,-0x7c(%ebp)
40002373:	66 c7 45 82 00 00    	movw   $0x0,-0x7e(%ebp)
40002379:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
40002380:	00 00 00 
40002383:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
4000238a:	00 00 00 
4000238d:	89 85 74 ff ff ff    	mov    %eax,-0x8c(%ebp)
40002393:	c7 85 70 ff ff ff 00 	movl   $0x1000,-0x90(%ebp)
4000239a:	10 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000239d:	8b 45 84             	mov    -0x7c(%ebp),%eax
400023a0:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400023a3:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
400023a9:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
400023ad:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
400023b3:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
400023b9:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
400023bf:	cd 30                	int    $0x30
	*(volatile int*)(sva+ofs) = 0xdeadbeef;	// should be writable now
400023c1:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
400023c7:	03 85 c0 fd ff ff    	add    -0x240(%ebp),%eax
400023cd:	c7 00 ef be ad de    	movl   $0xdeadbeef,(%eax)
	sys_get(SYS_PERM, 0, NULL, NULL, sva+ofs, PAGESIZE);
400023d3:	8b 85 c0 fd ff ff    	mov    -0x240(%ebp),%eax
400023d9:	8b 95 b4 fd ff ff    	mov    -0x24c(%ebp),%edx
400023df:	8d 04 02             	lea    (%edx,%eax,1),%eax
400023e2:	c7 45 9c 00 01 00 00 	movl   $0x100,-0x64(%ebp)
400023e9:	66 c7 45 9a 00 00    	movw   $0x0,-0x66(%ebp)
400023ef:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
400023f6:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
400023fd:	89 45 8c             	mov    %eax,-0x74(%ebp)
40002400:	c7 45 88 00 10 00 00 	movl   $0x1000,-0x78(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
40002407:	8b 45 9c             	mov    -0x64(%ebp),%eax
4000240a:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
4000240d:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
40002410:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
40002414:	8b 75 90             	mov    -0x70(%ebp),%esi
40002417:	8b 7d 8c             	mov    -0x74(%ebp),%edi
4000241a:	8b 4d 88             	mov    -0x78(%ebp),%ecx
4000241d:	cd 30                	int    $0x30
	readfaulttest(sva+ofs);			// hide it
4000241f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002426:	00 
40002427:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
4000242e:	e8 dd dc ff ff       	call   40000110 <fork>
40002433:	85 c0                	test   %eax,%eax
40002435:	75 15                	jne    4000244c <memopcheck+0xe33>
40002437:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
4000243d:	03 85 c0 fd ff ff    	add    -0x240(%ebp),%eax
40002443:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002445:	b8 03 00 00 00       	mov    $0x3,%eax
4000244a:	cd 30                	int    $0x30
4000244c:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002453:	00 
40002454:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000245b:	00 
4000245c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002463:	e8 79 dd ff ff       	call   400001e1 <join>
40002468:	c7 45 b4 00 00 02 00 	movl   $0x20000,-0x4c(%ebp)
4000246f:	66 c7 45 b2 00 00    	movw   $0x0,-0x4e(%ebp)
40002475:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
4000247c:	8b 85 b4 fd ff ff    	mov    -0x24c(%ebp),%eax
40002482:	89 45 a8             	mov    %eax,-0x58(%ebp)
40002485:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
4000248b:	89 45 a4             	mov    %eax,-0x5c(%ebp)
4000248e:	c7 45 a0 00 00 40 00 	movl   $0x400000,-0x60(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
40002495:	8b 45 b4             	mov    -0x4c(%ebp),%eax
40002498:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
4000249b:	8b 5d ac             	mov    -0x54(%ebp),%ebx
4000249e:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
400024a2:	8b 75 a8             	mov    -0x58(%ebp),%esi
400024a5:	8b 7d a4             	mov    -0x5c(%ebp),%edi
400024a8:	8b 4d a0             	mov    -0x60(%ebp),%ecx
400024ab:	cd 30                	int    $0x30
400024ad:	c7 45 cc 00 00 02 00 	movl   $0x20000,-0x34(%ebp)
400024b4:	66 c7 45 ca 00 00    	movw   $0x0,-0x36(%ebp)
400024ba:	c7 45 c4 00 00 00 00 	movl   $0x0,-0x3c(%ebp)
400024c1:	8b 85 b8 fd ff ff    	mov    -0x248(%ebp),%eax
400024c7:	89 45 c0             	mov    %eax,-0x40(%ebp)
400024ca:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
400024d0:	89 45 bc             	mov    %eax,-0x44(%ebp)
400024d3:	c7 45 b8 00 00 40 00 	movl   $0x400000,-0x48(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
400024da:	8b 45 cc             	mov    -0x34(%ebp),%eax
400024dd:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
400024e0:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
400024e3:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
400024e7:	8b 75 c0             	mov    -0x40(%ebp),%esi
400024ea:	8b 7d bc             	mov    -0x44(%ebp),%edi
400024ed:	8b 4d b8             	mov    -0x48(%ebp),%ecx
400024f0:	cd 30                	int    $0x30
	sys_put(SYS_COPY, 0, NULL, sva, dva, PTSIZE);
	sys_get(SYS_COPY, 0, NULL, dva, dva2, PTSIZE);
	readfaulttest(dva2+ofs);		// stayed hidden?
400024f2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400024f9:	00 
400024fa:	c7 04 24 10 00 00 00 	movl   $0x10,(%esp)
40002501:	e8 0a dc ff ff       	call   40000110 <fork>
40002506:	85 c0                	test   %eax,%eax
40002508:	75 15                	jne    4000251f <memopcheck+0xf06>
4000250a:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
40002510:	03 85 c0 fd ff ff    	add    -0x240(%ebp),%eax
40002516:	8b 00                	mov    (%eax),%eax
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002518:	b8 03 00 00 00       	mov    $0x3,%eax
4000251d:	cd 30                	int    $0x30
4000251f:	c7 44 24 08 0e 00 00 	movl   $0xe,0x8(%esp)
40002526:	00 
40002527:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000252e:	00 
4000252f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
40002536:	e8 a6 dc ff ff       	call   400001e1 <join>
	sys_get(SYS_PERM|SYS_READ, 0, NULL, NULL, dva2+ofs, PAGESIZE);
4000253b:	8b 85 c0 fd ff ff    	mov    -0x240(%ebp),%eax
40002541:	8b 95 bc fd ff ff    	mov    -0x244(%ebp),%edx
40002547:	8d 04 02             	lea    (%edx,%eax,1),%eax
4000254a:	c7 45 e4 00 03 00 00 	movl   $0x300,-0x1c(%ebp)
40002551:	66 c7 45 e2 00 00    	movw   $0x0,-0x1e(%ebp)
40002557:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
4000255e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
40002565:	89 45 d4             	mov    %eax,-0x2c(%ebp)
40002568:	c7 45 d0 00 10 00 00 	movl   $0x1000,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
4000256f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
40002572:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
40002575:	8b 5d dc             	mov    -0x24(%ebp),%ebx
40002578:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
4000257c:	8b 75 d8             	mov    -0x28(%ebp),%esi
4000257f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
40002582:	8b 4d d0             	mov    -0x30(%ebp),%ecx
40002585:	cd 30                	int    $0x30
	assert(*(volatile int*)(dva2+ofs) == 0xdeadbeef);	// survived?
40002587:	8b 85 bc fd ff ff    	mov    -0x244(%ebp),%eax
4000258d:	03 85 c0 fd ff ff    	add    -0x240(%ebp),%eax
40002593:	8b 00                	mov    (%eax),%eax
40002595:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000259a:	74 24                	je     400025c0 <memopcheck+0xfa7>
4000259c:	c7 44 24 0c f0 3d 00 	movl   $0x40003df0,0xc(%esp)
400025a3:	40 
400025a4:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400025ab:	40 
400025ac:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
400025b3:	00 
400025b4:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400025bb:	e8 f8 05 00 00       	call   40002bb8 <debug_panic>

	cprintf("testvm: memopcheck passed\n");
400025c0:	c7 04 24 19 3e 00 40 	movl   $0x40003e19,(%esp)
400025c7:	e8 7d 08 00 00       	call   40002e49 <cprintf>
}
400025cc:	81 c4 5c 02 00 00    	add    $0x25c,%esp
400025d2:	5b                   	pop    %ebx
400025d3:	5e                   	pop    %esi
400025d4:	5f                   	pop    %edi
400025d5:	5d                   	pop    %ebp
400025d6:	c3                   	ret    

400025d7 <pqsort>:

#define swapints(a,b) ({ int t = (a); (a) = (b); (b) = t; })

void
pqsort(int *lo, int *hi)
{
400025d7:	55                   	push   %ebp
400025d8:	89 e5                	mov    %esp,%ebp
400025da:	83 ec 38             	sub    $0x38,%esp
	if (lo >= hi)
400025dd:	8b 45 08             	mov    0x8(%ebp),%eax
400025e0:	3b 45 0c             	cmp    0xc(%ebp),%eax
400025e3:	0f 83 25 01 00 00    	jae    4000270e <pqsort+0x137>
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
400025e9:	8b 45 08             	mov    0x8(%ebp),%eax
400025ec:	8b 00                	mov    (%eax),%eax
400025ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	int *l = lo+1, *h = hi;
400025f1:	8b 45 08             	mov    0x8(%ebp),%eax
400025f4:	83 c0 04             	add    $0x4,%eax
400025f7:	89 45 e8             	mov    %eax,-0x18(%ebp)
400025fa:	8b 45 0c             	mov    0xc(%ebp),%eax
400025fd:	89 45 ec             	mov    %eax,-0x14(%ebp)
	while (l <= h) {
40002600:	eb 42                	jmp    40002644 <pqsort+0x6d>
		if (*l < pivot)
40002602:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002605:	8b 00                	mov    (%eax),%eax
40002607:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
4000260a:	7d 06                	jge    40002612 <pqsort+0x3b>
			l++;
4000260c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
40002610:	eb 32                	jmp    40002644 <pqsort+0x6d>
		else if (*h > pivot)
40002612:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002615:	8b 00                	mov    (%eax),%eax
40002617:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
4000261a:	7e 06                	jle    40002622 <pqsort+0x4b>
			h--;
4000261c:	83 6d ec 04          	subl   $0x4,-0x14(%ebp)
40002620:	eb 22                	jmp    40002644 <pqsort+0x6d>
		else
			swapints(*h, *l), l++, h--;
40002622:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002625:	8b 00                	mov    (%eax),%eax
40002627:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000262a:	8b 45 e8             	mov    -0x18(%ebp),%eax
4000262d:	8b 10                	mov    (%eax),%edx
4000262f:	8b 45 ec             	mov    -0x14(%ebp),%eax
40002632:	89 10                	mov    %edx,(%eax)
40002634:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002637:	8b 55 f0             	mov    -0x10(%ebp),%edx
4000263a:	89 10                	mov    %edx,(%eax)
4000263c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
40002640:	83 6d ec 04          	subl   $0x4,-0x14(%ebp)
	if (lo >= hi)
		return;

	int pivot = *lo;	// yeah, bad way to choose pivot...
	int *l = lo+1, *h = hi;
	while (l <= h) {
40002644:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002647:	3b 45 ec             	cmp    -0x14(%ebp),%eax
4000264a:	76 b6                	jbe    40002602 <pqsort+0x2b>
		else if (*h > pivot)
			h--;
		else
			swapints(*h, *l), l++, h--;
	}
	swapints(*lo, l[-1]);
4000264c:	8b 45 08             	mov    0x8(%ebp),%eax
4000264f:	8b 00                	mov    (%eax),%eax
40002651:	89 45 f4             	mov    %eax,-0xc(%ebp)
40002654:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002657:	83 e8 04             	sub    $0x4,%eax
4000265a:	8b 10                	mov    (%eax),%edx
4000265c:	8b 45 08             	mov    0x8(%ebp),%eax
4000265f:	89 10                	mov    %edx,(%eax)
40002661:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002664:	8d 50 fc             	lea    -0x4(%eax),%edx
40002667:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000266a:	89 02                	mov    %eax,(%edx)

	// Now recursively sort the two halves in parallel subprocesses
	if (!fork(SYS_START | SYS_SNAP, 0)) {
4000266c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002673:	00 
40002674:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
4000267b:	e8 90 da ff ff       	call   40000110 <fork>
40002680:	85 c0                	test   %eax,%eax
40002682:	75 1c                	jne    400026a0 <pqsort+0xc9>
		pqsort(lo, l-2);
40002684:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002687:	83 e8 08             	sub    $0x8,%eax
4000268a:	89 44 24 04          	mov    %eax,0x4(%esp)
4000268e:	8b 45 08             	mov    0x8(%ebp),%eax
40002691:	89 04 24             	mov    %eax,(%esp)
40002694:	e8 3e ff ff ff       	call   400025d7 <pqsort>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
40002699:	b8 03 00 00 00       	mov    $0x3,%eax
4000269e:	cd 30                	int    $0x30
		sys_ret();
	}
	if (!fork(SYS_START | SYS_SNAP, 1)) {
400026a0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400026a7:	00 
400026a8:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
400026af:	e8 5c da ff ff       	call   40000110 <fork>
400026b4:	85 c0                	test   %eax,%eax
400026b6:	75 1c                	jne    400026d4 <pqsort+0xfd>
		pqsort(h+1, hi);
400026b8:	8b 45 ec             	mov    -0x14(%ebp),%eax
400026bb:	8d 50 04             	lea    0x4(%eax),%edx
400026be:	8b 45 0c             	mov    0xc(%ebp),%eax
400026c1:	89 44 24 04          	mov    %eax,0x4(%esp)
400026c5:	89 14 24             	mov    %edx,(%esp)
400026c8:	e8 0a ff ff ff       	call   400025d7 <pqsort>
400026cd:	b8 03 00 00 00       	mov    $0x3,%eax
400026d2:	cd 30                	int    $0x30
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
400026d4:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026db:	00 
400026dc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400026e3:	00 
400026e4:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400026eb:	e8 f1 da ff ff       	call   400001e1 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
400026f0:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400026f7:	00 
400026f8:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400026ff:	00 
40002700:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002707:	e8 d5 da ff ff       	call   400001e1 <join>
4000270c:	eb 01                	jmp    4000270f <pqsort+0x138>

void
pqsort(int *lo, int *hi)
{
	if (lo >= hi)
		return;
4000270e:	90                   	nop
		pqsort(h+1, hi);
		sys_ret();
	}
	join(SYS_MERGE, 0, T_SYSCALL);
	join(SYS_MERGE, 1, T_SYSCALL);
}
4000270f:	c9                   	leave  
40002710:	c3                   	ret    

40002711 <matmult>:
	{149128, 54805, 130652, 140309, 157630, 99208, 115657, 106951},
	{136163, 42930, 132817, 154486, 107399, 83659, 100339, 80010}};

void
matmult(int a[8][8], int b[8][8], int r[8][8])
{
40002711:	55                   	push   %ebp
40002712:	89 e5                	mov    %esp,%ebp
40002714:	83 ec 38             	sub    $0x38,%esp
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
40002717:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
4000271e:	e9 9b 00 00 00       	jmp    400027be <matmult+0xad>
		for (j = 0; j < 8; j++) {
40002723:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
4000272a:	e9 81 00 00 00       	jmp    400027b0 <matmult+0x9f>
			int child = i*8 + j;
4000272f:	8b 45 e0             	mov    -0x20(%ebp),%eax
40002732:	c1 e0 03             	shl    $0x3,%eax
40002735:	03 45 e4             	add    -0x1c(%ebp),%eax
40002738:	89 45 ec             	mov    %eax,-0x14(%ebp)
			if (!fork(SYS_START | SYS_SNAP, child)) {
4000273b:	8b 45 ec             	mov    -0x14(%ebp),%eax
4000273e:	0f b6 c0             	movzbl %al,%eax
40002741:	89 44 24 04          	mov    %eax,0x4(%esp)
40002745:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
4000274c:	e8 bf d9 ff ff       	call   40000110 <fork>
40002751:	85 c0                	test   %eax,%eax
40002753:	75 57                	jne    400027ac <matmult+0x9b>
				int sum = 0;	// in child: compute cell i,j
40002755:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
				for (k = 0; k < 8; k++)
4000275c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
40002763:	eb 28                	jmp    4000278d <matmult+0x7c>
					sum += a[i][k] * b[k][j];
40002765:	8b 45 e0             	mov    -0x20(%ebp),%eax
40002768:	c1 e0 05             	shl    $0x5,%eax
4000276b:	03 45 08             	add    0x8(%ebp),%eax
4000276e:	8b 55 e8             	mov    -0x18(%ebp),%edx
40002771:	8b 0c 90             	mov    (%eax,%edx,4),%ecx
40002774:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002777:	c1 e0 05             	shl    $0x5,%eax
4000277a:	03 45 0c             	add    0xc(%ebp),%eax
4000277d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
40002780:	8b 04 90             	mov    (%eax,%edx,4),%eax
40002783:	0f af c1             	imul   %ecx,%eax
40002786:	01 45 f0             	add    %eax,-0x10(%ebp)
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
			int child = i*8 + j;
			if (!fork(SYS_START | SYS_SNAP, child)) {
				int sum = 0;	// in child: compute cell i,j
				for (k = 0; k < 8; k++)
40002789:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
4000278d:	83 7d e8 07          	cmpl   $0x7,-0x18(%ebp)
40002791:	7e d2                	jle    40002765 <matmult+0x54>
					sum += a[i][k] * b[k][j];
				r[i][j] = sum;
40002793:	8b 45 e0             	mov    -0x20(%ebp),%eax
40002796:	c1 e0 05             	shl    $0x5,%eax
40002799:	03 45 10             	add    0x10(%ebp),%eax
4000279c:	8b 55 e4             	mov    -0x1c(%ebp),%edx
4000279f:	8b 4d f0             	mov    -0x10(%ebp),%ecx
400027a2:	89 0c 90             	mov    %ecx,(%eax,%edx,4)
400027a5:	b8 03 00 00 00       	mov    $0x3,%eax
400027aa:	cd 30                	int    $0x30
{
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
400027ac:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
400027b0:	83 7d e4 07          	cmpl   $0x7,-0x1c(%ebp)
400027b4:	0f 8e 75 ff ff ff    	jle    4000272f <matmult+0x1e>
matmult(int a[8][8], int b[8][8], int r[8][8])
{
	int i,j,k;

	// Fork off a thread to compute each cell in the result matrix
	for (i = 0; i < 8; i++)
400027ba:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
400027be:	83 7d e0 07          	cmpl   $0x7,-0x20(%ebp)
400027c2:	0f 8e 5b ff ff ff    	jle    40002723 <matmult+0x12>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
400027c8:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
400027cf:	eb 41                	jmp    40002812 <matmult+0x101>
		for (j = 0; j < 8; j++) {
400027d1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
400027d8:	eb 2e                	jmp    40002808 <matmult+0xf7>
			int child = i*8 + j;
400027da:	8b 45 e0             	mov    -0x20(%ebp),%eax
400027dd:	c1 e0 03             	shl    $0x3,%eax
400027e0:	03 45 e4             	add    -0x1c(%ebp),%eax
400027e3:	89 45 f4             	mov    %eax,-0xc(%ebp)
			join(SYS_MERGE, child, T_SYSCALL);
400027e6:	8b 45 f4             	mov    -0xc(%ebp),%eax
400027e9:	0f b6 c0             	movzbl %al,%eax
400027ec:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400027f3:	00 
400027f4:	89 44 24 04          	mov    %eax,0x4(%esp)
400027f8:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400027ff:	e8 dd d9 ff ff       	call   400001e1 <join>
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
		for (j = 0; j < 8; j++) {
40002804:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
40002808:	83 7d e4 07          	cmpl   $0x7,-0x1c(%ebp)
4000280c:	7e cc                	jle    400027da <matmult+0xc9>
				sys_ret();
			}
		}

	// Now go back and merge in the results of all our children
	for (i = 0; i < 8; i++)
4000280e:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
40002812:	83 7d e0 07          	cmpl   $0x7,-0x20(%ebp)
40002816:	7e b9                	jle    400027d1 <matmult+0xc0>
		for (j = 0; j < 8; j++) {
			int child = i*8 + j;
			join(SYS_MERGE, child, T_SYSCALL);
		}
}
40002818:	c9                   	leave  
40002819:	c3                   	ret    

4000281a <mergecheck>:

void
mergecheck()
{
4000281a:	55                   	push   %ebp
4000281b:	89 e5                	mov    %esp,%ebp
4000281d:	83 ec 18             	sub    $0x18,%esp
	// Simple merge test: two children write two adjacent variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = 0xdeadbeef; sys_ret(); }
40002820:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002827:	00 
40002828:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
4000282f:	e8 dc d8 ff ff       	call   40000110 <fork>
40002834:	85 c0                	test   %eax,%eax
40002836:	75 11                	jne    40002849 <mergecheck+0x2f>
40002838:	c7 05 a0 5c 00 40 ef 	movl   $0xdeadbeef,0x40005ca0
4000283f:	be ad de 
40002842:	b8 03 00 00 00       	mov    $0x3,%eax
40002847:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = 0xabadcafe; sys_ret(); }
40002849:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002850:	00 
40002851:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002858:	e8 b3 d8 ff ff       	call   40000110 <fork>
4000285d:	85 c0                	test   %eax,%eax
4000285f:	75 11                	jne    40002872 <mergecheck+0x58>
40002861:	c7 05 c0 7d 00 40 fe 	movl   $0xabadcafe,0x40007dc0
40002868:	ca ad ab 
4000286b:	b8 03 00 00 00       	mov    $0x3,%eax
40002870:	cd 30                	int    $0x30
	assert(x == 0); assert(y == 0);
40002872:	a1 a0 5c 00 40       	mov    0x40005ca0,%eax
40002877:	85 c0                	test   %eax,%eax
40002879:	74 24                	je     4000289f <mergecheck+0x85>
4000287b:	c7 44 24 0c 40 43 00 	movl   $0x40004340,0xc(%esp)
40002882:	40 
40002883:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
4000288a:	40 
4000288b:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
40002892:	00 
40002893:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000289a:	e8 19 03 00 00       	call   40002bb8 <debug_panic>
4000289f:	a1 c0 7d 00 40       	mov    0x40007dc0,%eax
400028a4:	85 c0                	test   %eax,%eax
400028a6:	74 24                	je     400028cc <mergecheck+0xb2>
400028a8:	c7 44 24 0c 47 43 00 	movl   $0x40004347,0xc(%esp)
400028af:	40 
400028b0:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400028b7:	40 
400028b8:	c7 44 24 04 d0 01 00 	movl   $0x1d0,0x4(%esp)
400028bf:	00 
400028c0:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400028c7:	e8 ec 02 00 00       	call   40002bb8 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
400028cc:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028d3:	00 
400028d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
400028db:	00 
400028dc:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400028e3:	e8 f9 d8 ff ff       	call   400001e1 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
400028e8:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
400028ef:	00 
400028f0:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
400028f7:	00 
400028f8:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
400028ff:	e8 dd d8 ff ff       	call   400001e1 <join>
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
40002904:	a1 a0 5c 00 40       	mov    0x40005ca0,%eax
40002909:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
4000290e:	74 24                	je     40002934 <mergecheck+0x11a>
40002910:	c7 44 24 0c 4e 43 00 	movl   $0x4000434e,0xc(%esp)
40002917:	40 
40002918:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
4000291f:	40 
40002920:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002927:	00 
40002928:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000292f:	e8 84 02 00 00       	call   40002bb8 <debug_panic>
40002934:	a1 c0 7d 00 40       	mov    0x40007dc0,%eax
40002939:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
4000293e:	74 24                	je     40002964 <mergecheck+0x14a>
40002940:	c7 44 24 0c 5e 43 00 	movl   $0x4000435e,0xc(%esp)
40002947:	40 
40002948:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
4000294f:	40 
40002950:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
40002957:	00 
40002958:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
4000295f:	e8 54 02 00 00       	call   40002bb8 <debug_panic>

	// A Rube Goldberg approach to swapping two variables
	if (!fork(SYS_START | SYS_SNAP, 0)) { x = y; sys_ret(); }
40002964:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
4000296b:	00 
4000296c:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
40002973:	e8 98 d7 ff ff       	call   40000110 <fork>
40002978:	85 c0                	test   %eax,%eax
4000297a:	75 11                	jne    4000298d <mergecheck+0x173>
4000297c:	a1 c0 7d 00 40       	mov    0x40007dc0,%eax
40002981:	a3 a0 5c 00 40       	mov    %eax,0x40005ca0
40002986:	b8 03 00 00 00       	mov    $0x3,%eax
4000298b:	cd 30                	int    $0x30
	if (!fork(SYS_START | SYS_SNAP, 1)) { y = x; sys_ret(); }
4000298d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002994:	00 
40002995:	c7 04 24 10 00 04 00 	movl   $0x40010,(%esp)
4000299c:	e8 6f d7 ff ff       	call   40000110 <fork>
400029a1:	85 c0                	test   %eax,%eax
400029a3:	75 11                	jne    400029b6 <mergecheck+0x19c>
400029a5:	a1 a0 5c 00 40       	mov    0x40005ca0,%eax
400029aa:	a3 c0 7d 00 40       	mov    %eax,0x40007dc0
400029af:	b8 03 00 00 00       	mov    $0x3,%eax
400029b4:	cd 30                	int    $0x30
	assert(x == 0xdeadbeef); assert(y == 0xabadcafe);
400029b6:	a1 a0 5c 00 40       	mov    0x40005ca0,%eax
400029bb:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
400029c0:	74 24                	je     400029e6 <mergecheck+0x1cc>
400029c2:	c7 44 24 0c 4e 43 00 	movl   $0x4000434e,0xc(%esp)
400029c9:	40 
400029ca:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
400029d1:	40 
400029d2:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
400029d9:	00 
400029da:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
400029e1:	e8 d2 01 00 00       	call   40002bb8 <debug_panic>
400029e6:	a1 c0 7d 00 40       	mov    0x40007dc0,%eax
400029eb:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
400029f0:	74 24                	je     40002a16 <mergecheck+0x1fc>
400029f2:	c7 44 24 0c 5e 43 00 	movl   $0x4000435e,0xc(%esp)
400029f9:	40 
400029fa:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002a01:	40 
40002a02:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
40002a09:	00 
40002a0a:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002a11:	e8 a2 01 00 00       	call   40002bb8 <debug_panic>
	join(SYS_MERGE, 0, T_SYSCALL);
40002a16:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a1d:	00 
40002a1e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002a25:	00 
40002a26:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a2d:	e8 af d7 ff ff       	call   400001e1 <join>
	join(SYS_MERGE, 1, T_SYSCALL);
40002a32:	c7 44 24 08 30 00 00 	movl   $0x30,0x8(%esp)
40002a39:	00 
40002a3a:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
40002a41:	00 
40002a42:	c7 04 24 00 00 03 00 	movl   $0x30000,(%esp)
40002a49:	e8 93 d7 ff ff       	call   400001e1 <join>
	assert(y == 0xdeadbeef); assert(x == 0xabadcafe);
40002a4e:	a1 c0 7d 00 40       	mov    0x40007dc0,%eax
40002a53:	3d ef be ad de       	cmp    $0xdeadbeef,%eax
40002a58:	74 24                	je     40002a7e <mergecheck+0x264>
40002a5a:	c7 44 24 0c 6e 43 00 	movl   $0x4000436e,0xc(%esp)
40002a61:	40 
40002a62:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002a69:	40 
40002a6a:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002a71:	00 
40002a72:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002a79:	e8 3a 01 00 00       	call   40002bb8 <debug_panic>
40002a7e:	a1 a0 5c 00 40       	mov    0x40005ca0,%eax
40002a83:	3d fe ca ad ab       	cmp    $0xabadcafe,%eax
40002a88:	74 24                	je     40002aae <mergecheck+0x294>
40002a8a:	c7 44 24 0c 7e 43 00 	movl   $0x4000437e,0xc(%esp)
40002a91:	40 
40002a92:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002a99:	40 
40002a9a:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
40002aa1:	00 
40002aa2:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002aa9:	e8 0a 01 00 00       	call   40002bb8 <debug_panic>

	// Parallel quicksort with recursive processes!
	// (though probably not very efficient on arrays this small)
	pqsort(&randints[0], &randints[256-1]);
40002aae:	c7 44 24 04 9c 5a 00 	movl   $0x40005a9c,0x4(%esp)
40002ab5:	40 
40002ab6:	c7 04 24 a0 56 00 40 	movl   $0x400056a0,(%esp)
40002abd:	e8 15 fb ff ff       	call   400025d7 <pqsort>
	assert(memcmp(randints, sortints, 256*sizeof(int)) == 0);
40002ac2:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
40002ac9:	00 
40002aca:	c7 44 24 04 40 3e 00 	movl   $0x40003e40,0x4(%esp)
40002ad1:	40 
40002ad2:	c7 04 24 a0 56 00 40 	movl   $0x400056a0,(%esp)
40002ad9:	e8 7a 0d 00 00       	call   40003858 <memcmp>
40002ade:	85 c0                	test   %eax,%eax
40002ae0:	74 24                	je     40002b06 <mergecheck+0x2ec>
40002ae2:	c7 44 24 0c 90 43 00 	movl   $0x40004390,0xc(%esp)
40002ae9:	40 
40002aea:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002af1:	40 
40002af2:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
40002af9:	00 
40002afa:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002b01:	e8 b2 00 00 00       	call   40002bb8 <debug_panic>

	// Parallel matrix multiply, one child process per result matrix cell
	matmult(ma, mb, mr);
40002b06:	c7 44 24 08 c0 7c 00 	movl   $0x40007cc0,0x8(%esp)
40002b0d:	40 
40002b0e:	c7 44 24 04 a0 5b 00 	movl   $0x40005ba0,0x4(%esp)
40002b15:	40 
40002b16:	c7 04 24 a0 5a 00 40 	movl   $0x40005aa0,(%esp)
40002b1d:	e8 ef fb ff ff       	call   40002711 <matmult>
	assert(sizeof(mr) == sizeof(int)*8*8);
	assert(sizeof(mc) == sizeof(int)*8*8);
	assert(memcmp(mr, mc, sizeof(mr)) == 0);
40002b22:	c7 44 24 08 00 01 00 	movl   $0x100,0x8(%esp)
40002b29:	00 
40002b2a:	c7 44 24 04 40 42 00 	movl   $0x40004240,0x4(%esp)
40002b31:	40 
40002b32:	c7 04 24 c0 7c 00 40 	movl   $0x40007cc0,(%esp)
40002b39:	e8 1a 0d 00 00       	call   40003858 <memcmp>
40002b3e:	85 c0                	test   %eax,%eax
40002b40:	74 24                	je     40002b66 <mergecheck+0x34c>
40002b42:	c7 44 24 0c c4 43 00 	movl   $0x400043c4,0xc(%esp)
40002b49:	40 
40002b4a:	c7 44 24 08 bb 3c 00 	movl   $0x40003cbb,0x8(%esp)
40002b51:	40 
40002b52:	c7 44 24 04 e6 01 00 	movl   $0x1e6,0x4(%esp)
40002b59:	00 
40002b5a:	c7 04 24 c8 3b 00 40 	movl   $0x40003bc8,(%esp)
40002b61:	e8 52 00 00 00       	call   40002bb8 <debug_panic>

	cprintf("testvm: mergecheck passed\n");
40002b66:	c7 04 24 e4 43 00 40 	movl   $0x400043e4,(%esp)
40002b6d:	e8 d7 02 00 00       	call   40002e49 <cprintf>
}
40002b72:	c9                   	leave  
40002b73:	c3                   	ret    

40002b74 <main>:

int
main()
{
40002b74:	55                   	push   %ebp
40002b75:	89 e5                	mov    %esp,%ebp
40002b77:	83 e4 f0             	and    $0xfffffff0,%esp
40002b7a:	83 ec 10             	sub    $0x10,%esp
	cprintf("testvm: in main()\n");
40002b7d:	c7 04 24 ff 43 00 40 	movl   $0x400043ff,(%esp)
40002b84:	e8 c0 02 00 00       	call   40002e49 <cprintf>

	loadcheck();
40002b89:	e8 f5 d7 ff ff       	call   40000383 <loadcheck>
	forkcheck();
40002b8e:	e8 72 d8 ff ff       	call   40000405 <forkcheck>
	protcheck();
40002b93:	e8 d1 db ff ff       	call   40000769 <protcheck>
	memopcheck();
40002b98:	e8 7c ea ff ff       	call   40001619 <memopcheck>
	mergecheck();
40002b9d:	e8 78 fc ff ff       	call   4000281a <mergecheck>

	cprintf("testvm: all tests completed successfully!\n");
40002ba2:	c7 04 24 14 44 00 40 	movl   $0x40004414,(%esp)
40002ba9:	e8 9b 02 00 00       	call   40002e49 <cprintf>
	return 0;
40002bae:	b8 00 00 00 00       	mov    $0x0,%eax
}
40002bb3:	c9                   	leave  
40002bb4:	c3                   	ret    
40002bb5:	90                   	nop
40002bb6:	90                   	nop
40002bb7:	90                   	nop

40002bb8 <debug_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: <message>", then causes a breakpoint exception.
 */
void
debug_panic(const char *file, int line, const char *fmt,...)
{
40002bb8:	55                   	push   %ebp
40002bb9:	89 e5                	mov    %esp,%ebp
40002bbb:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	va_start(ap, fmt);
40002bbe:	8d 45 10             	lea    0x10(%ebp),%eax
40002bc1:	83 c0 04             	add    $0x4,%eax
40002bc4:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Print the panic message
	if (argv0)
40002bc7:	a1 c4 7d 00 40       	mov    0x40007dc4,%eax
40002bcc:	85 c0                	test   %eax,%eax
40002bce:	74 15                	je     40002be5 <debug_panic+0x2d>
		cprintf("%s: ", argv0);
40002bd0:	a1 c4 7d 00 40       	mov    0x40007dc4,%eax
40002bd5:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bd9:	c7 04 24 40 44 00 40 	movl   $0x40004440,(%esp)
40002be0:	e8 64 02 00 00       	call   40002e49 <cprintf>
	cprintf("user panic at %s:%d: ", file, line);
40002be5:	8b 45 0c             	mov    0xc(%ebp),%eax
40002be8:	89 44 24 08          	mov    %eax,0x8(%esp)
40002bec:	8b 45 08             	mov    0x8(%ebp),%eax
40002bef:	89 44 24 04          	mov    %eax,0x4(%esp)
40002bf3:	c7 04 24 45 44 00 40 	movl   $0x40004445,(%esp)
40002bfa:	e8 4a 02 00 00       	call   40002e49 <cprintf>
	vcprintf(fmt, ap);
40002bff:	8b 45 10             	mov    0x10(%ebp),%eax
40002c02:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002c05:	89 54 24 04          	mov    %edx,0x4(%esp)
40002c09:	89 04 24             	mov    %eax,(%esp)
40002c0c:	e8 cf 01 00 00       	call   40002de0 <vcprintf>
	cprintf("\n");
40002c11:	c7 04 24 5b 44 00 40 	movl   $0x4000445b,(%esp)
40002c18:	e8 2c 02 00 00       	call   40002e49 <cprintf>
40002c1d:	b8 03 00 00 00       	mov    $0x3,%eax
40002c22:	cd 30                	int    $0x30

	sys_ret();
	while(1)
		;
40002c24:	eb fe                	jmp    40002c24 <debug_panic+0x6c>

40002c26 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
40002c26:	55                   	push   %ebp
40002c27:	89 e5                	mov    %esp,%ebp
40002c29:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
40002c2c:	8d 45 10             	lea    0x10(%ebp),%eax
40002c2f:	83 c0 04             	add    $0x4,%eax
40002c32:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("user warning at %s:%d: ", file, line);
40002c35:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c38:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c3c:	8b 45 08             	mov    0x8(%ebp),%eax
40002c3f:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c43:	c7 04 24 5d 44 00 40 	movl   $0x4000445d,(%esp)
40002c4a:	e8 fa 01 00 00       	call   40002e49 <cprintf>
	vcprintf(fmt, ap);
40002c4f:	8b 45 10             	mov    0x10(%ebp),%eax
40002c52:	8b 55 f4             	mov    -0xc(%ebp),%edx
40002c55:	89 54 24 04          	mov    %edx,0x4(%esp)
40002c59:	89 04 24             	mov    %eax,(%esp)
40002c5c:	e8 7f 01 00 00       	call   40002de0 <vcprintf>
	cprintf("\n");
40002c61:	c7 04 24 5b 44 00 40 	movl   $0x4000445b,(%esp)
40002c68:	e8 dc 01 00 00       	call   40002e49 <cprintf>
	va_end(ap);
}
40002c6d:	c9                   	leave  
40002c6e:	c3                   	ret    

40002c6f <debug_dump>:

// Dump a block of memory as 32-bit words and ASCII bytes
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
40002c6f:	55                   	push   %ebp
40002c70:	89 e5                	mov    %esp,%ebp
40002c72:	56                   	push   %esi
40002c73:	53                   	push   %ebx
40002c74:	81 ec a0 00 00 00    	sub    $0xa0,%esp
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
40002c7a:	8b 45 14             	mov    0x14(%ebp),%eax
40002c7d:	03 45 10             	add    0x10(%ebp),%eax
40002c80:	89 44 24 10          	mov    %eax,0x10(%esp)
40002c84:	8b 45 10             	mov    0x10(%ebp),%eax
40002c87:	89 44 24 0c          	mov    %eax,0xc(%esp)
40002c8b:	8b 45 0c             	mov    0xc(%ebp),%eax
40002c8e:	89 44 24 08          	mov    %eax,0x8(%esp)
40002c92:	8b 45 08             	mov    0x8(%ebp),%eax
40002c95:	89 44 24 04          	mov    %eax,0x4(%esp)
40002c99:	c7 04 24 78 44 00 40 	movl   $0x40004478,(%esp)
40002ca0:	e8 a4 01 00 00       	call   40002e49 <cprintf>
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002ca5:	8b 45 14             	mov    0x14(%ebp),%eax
40002ca8:	83 c0 0f             	add    $0xf,%eax
40002cab:	83 e0 f0             	and    $0xfffffff0,%eax
40002cae:	89 45 14             	mov    %eax,0x14(%ebp)
40002cb1:	e9 b4 00 00 00       	jmp    40002d6a <debug_dump+0xfb>
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
40002cb6:	8b 45 10             	mov    0x10(%ebp),%eax
40002cb9:	89 45 ec             	mov    %eax,-0x14(%ebp)
		for (i = 0; i < 16; i++)
40002cbc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
40002cc3:	eb 46                	jmp    40002d0b <debug_dump+0x9c>
			buf[i] = isprint(c[i]) ? c[i] : '.';
40002cc5:	8b 55 e8             	mov    -0x18(%ebp),%edx
40002cc8:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002ccb:	03 45 ec             	add    -0x14(%ebp),%eax
40002cce:	0f b6 00             	movzbl (%eax),%eax
40002cd1:	0f b6 c0             	movzbl %al,%eax
40002cd4:	89 45 f4             	mov    %eax,-0xc(%ebp)
static gcc_inline int isalnum(int c)	{ return isalpha(c) || isdigit(c); }
static gcc_inline int iscntrl(int c)	{ return c < ' '; }
static gcc_inline int isblank(int c)	{ return c == ' ' || c == '\t'; }
static gcc_inline int isspace(int c)	{ return c == ' '
						|| (c >= '\t' && c <= '\r'); }
static gcc_inline int isprint(int c)	{ return c >= ' ' && c <= '~'; }
40002cd7:	83 7d f4 1f          	cmpl   $0x1f,-0xc(%ebp)
40002cdb:	7e 0d                	jle    40002cea <debug_dump+0x7b>
40002cdd:	83 7d f4 7e          	cmpl   $0x7e,-0xc(%ebp)
40002ce1:	7f 07                	jg     40002cea <debug_dump+0x7b>
40002ce3:	b8 01 00 00 00       	mov    $0x1,%eax
40002ce8:	eb 05                	jmp    40002cef <debug_dump+0x80>
40002cea:	b8 00 00 00 00       	mov    $0x0,%eax
40002cef:	85 c0                	test   %eax,%eax
40002cf1:	74 0b                	je     40002cfe <debug_dump+0x8f>
40002cf3:	8b 45 e8             	mov    -0x18(%ebp),%eax
40002cf6:	03 45 ec             	add    -0x14(%ebp),%eax
40002cf9:	0f b6 00             	movzbl (%eax),%eax
40002cfc:	eb 05                	jmp    40002d03 <debug_dump+0x94>
40002cfe:	b8 2e 00 00 00       	mov    $0x2e,%eax
40002d03:	88 44 15 84          	mov    %al,-0x7c(%ebp,%edx,1)
		char buf[100];

		// ASCII bytes
		int i; 
		const uint8_t *c = ptr;
		for (i = 0; i < 16; i++)
40002d07:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
40002d0b:	83 7d e8 0f          	cmpl   $0xf,-0x18(%ebp)
40002d0f:	7e b4                	jle    40002cc5 <debug_dump+0x56>
			buf[i] = isprint(c[i]) ? c[i] : '.';
		buf[16] = 0;
40002d11:	c6 45 94 00          	movb   $0x0,-0x6c(%ebp)

		// Hex words
		const uint32_t *v = ptr;
40002d15:	8b 45 10             	mov    0x10(%ebp),%eax
40002d18:	89 45 f0             	mov    %eax,-0x10(%ebp)

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
40002d1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002d1e:	83 c0 0c             	add    $0xc,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002d21:	8b 18                	mov    (%eax),%ebx
			ptr, v[0], v[1], v[2], v[3], buf);
40002d23:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002d26:	83 c0 08             	add    $0x8,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002d29:	8b 08                	mov    (%eax),%ecx
			ptr, v[0], v[1], v[2], v[3], buf);
40002d2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002d2e:	83 c0 04             	add    $0x4,%eax

		// Hex words
		const uint32_t *v = ptr;

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
40002d31:	8b 10                	mov    (%eax),%edx
40002d33:	8b 45 f0             	mov    -0x10(%ebp),%eax
40002d36:	8b 00                	mov    (%eax),%eax
40002d38:	8d 75 84             	lea    -0x7c(%ebp),%esi
40002d3b:	89 74 24 18          	mov    %esi,0x18(%esp)
40002d3f:	89 5c 24 14          	mov    %ebx,0x14(%esp)
40002d43:	89 4c 24 10          	mov    %ecx,0x10(%esp)
40002d47:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002d4b:	89 44 24 08          	mov    %eax,0x8(%esp)
40002d4f:	8b 45 10             	mov    0x10(%ebp),%eax
40002d52:	89 44 24 04          	mov    %eax,0x4(%esp)
40002d56:	c7 04 24 a1 44 00 40 	movl   $0x400044a1,(%esp)
40002d5d:	e8 e7 00 00 00       	call   40002e49 <cprintf>
void
debug_dump(const char *file, int line, const void *ptr, int size)
{
	cprintf("user dump at %s:%d of memory %08x-%08x:\n",
		file, line, ptr, ptr + size);
	for (size = (size+15) & ~15; size > 0; size -= 16, ptr += 16) {
40002d62:	83 6d 14 10          	subl   $0x10,0x14(%ebp)
40002d66:	83 45 10 10          	addl   $0x10,0x10(%ebp)
40002d6a:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
40002d6e:	0f 8f 42 ff ff ff    	jg     40002cb6 <debug_dump+0x47>

		// Print each line atomically to avoid async mixing
		cprintf("%08x: %08x %08x %08x %08x %s",
			ptr, v[0], v[1], v[2], v[3], buf);
	}
}
40002d74:	81 c4 a0 00 00 00    	add    $0xa0,%esp
40002d7a:	5b                   	pop    %ebx
40002d7b:	5e                   	pop    %esi
40002d7c:	5d                   	pop    %ebp
40002d7d:	c3                   	ret    
40002d7e:	90                   	nop
40002d7f:	90                   	nop

40002d80 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
40002d80:	55                   	push   %ebp
40002d81:	89 e5                	mov    %esp,%ebp
40002d83:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
40002d86:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d89:	8b 00                	mov    (%eax),%eax
40002d8b:	8b 55 08             	mov    0x8(%ebp),%edx
40002d8e:	89 d1                	mov    %edx,%ecx
40002d90:	8b 55 0c             	mov    0xc(%ebp),%edx
40002d93:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
40002d97:	8d 50 01             	lea    0x1(%eax),%edx
40002d9a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002d9d:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
40002d9f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002da2:	8b 00                	mov    (%eax),%eax
40002da4:	3d ff 00 00 00       	cmp    $0xff,%eax
40002da9:	75 24                	jne    40002dcf <putch+0x4f>
		b->buf[b->idx] = 0;
40002dab:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dae:	8b 00                	mov    (%eax),%eax
40002db0:	8b 55 0c             	mov    0xc(%ebp),%edx
40002db3:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
40002db8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dbb:	83 c0 08             	add    $0x8,%eax
40002dbe:	89 04 24             	mov    %eax,(%esp)
40002dc1:	e8 2a 0b 00 00       	call   400038f0 <cputs>
		b->idx = 0;
40002dc6:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dc9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
40002dcf:	8b 45 0c             	mov    0xc(%ebp),%eax
40002dd2:	8b 40 04             	mov    0x4(%eax),%eax
40002dd5:	8d 50 01             	lea    0x1(%eax),%edx
40002dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ddb:	89 50 04             	mov    %edx,0x4(%eax)
}
40002dde:	c9                   	leave  
40002ddf:	c3                   	ret    

40002de0 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
40002de0:	55                   	push   %ebp
40002de1:	89 e5                	mov    %esp,%ebp
40002de3:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
40002de9:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
40002df0:	00 00 00 
	b.cnt = 0;
40002df3:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
40002dfa:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
40002dfd:	b8 80 2d 00 40       	mov    $0x40002d80,%eax
40002e02:	8b 55 0c             	mov    0xc(%ebp),%edx
40002e05:	89 54 24 0c          	mov    %edx,0xc(%esp)
40002e09:	8b 55 08             	mov    0x8(%ebp),%edx
40002e0c:	89 54 24 08          	mov    %edx,0x8(%esp)
40002e10:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
40002e16:	89 54 24 04          	mov    %edx,0x4(%esp)
40002e1a:	89 04 24             	mov    %eax,(%esp)
40002e1d:	e8 72 03 00 00       	call   40003194 <vprintfmt>

	b.buf[b.idx] = 0;
40002e22:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
40002e28:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
40002e2f:	00 
	cputs(b.buf);
40002e30:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
40002e36:	83 c0 08             	add    $0x8,%eax
40002e39:	89 04 24             	mov    %eax,(%esp)
40002e3c:	e8 af 0a 00 00       	call   400038f0 <cputs>

	return b.cnt;
40002e41:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
40002e47:	c9                   	leave  
40002e48:	c3                   	ret    

40002e49 <cprintf>:

int
cprintf(const char *fmt, ...)
{
40002e49:	55                   	push   %ebp
40002e4a:	89 e5                	mov    %esp,%ebp
40002e4c:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
40002e4f:	8d 45 08             	lea    0x8(%ebp),%eax
40002e52:	83 c0 04             	add    $0x4,%eax
40002e55:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
40002e58:	8b 45 08             	mov    0x8(%ebp),%eax
40002e5b:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002e5e:	89 54 24 04          	mov    %edx,0x4(%esp)
40002e62:	89 04 24             	mov    %eax,(%esp)
40002e65:	e8 76 ff ff ff       	call   40002de0 <vcprintf>
40002e6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
40002e6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
40002e70:	c9                   	leave  
40002e71:	c3                   	ret    
40002e72:	90                   	nop
40002e73:	90                   	nop

40002e74 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
40002e74:	55                   	push   %ebp
40002e75:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40002e77:	8b 45 08             	mov    0x8(%ebp),%eax
40002e7a:	8b 40 18             	mov    0x18(%eax),%eax
40002e7d:	83 e0 02             	and    $0x2,%eax
40002e80:	85 c0                	test   %eax,%eax
40002e82:	74 1c                	je     40002ea0 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
40002e84:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e87:	8b 00                	mov    (%eax),%eax
40002e89:	8d 50 08             	lea    0x8(%eax),%edx
40002e8c:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e8f:	89 10                	mov    %edx,(%eax)
40002e91:	8b 45 0c             	mov    0xc(%ebp),%eax
40002e94:	8b 00                	mov    (%eax),%eax
40002e96:	83 e8 08             	sub    $0x8,%eax
40002e99:	8b 50 04             	mov    0x4(%eax),%edx
40002e9c:	8b 00                	mov    (%eax),%eax
40002e9e:	eb 47                	jmp    40002ee7 <getuint+0x73>
	else if (st->flags & F_L)
40002ea0:	8b 45 08             	mov    0x8(%ebp),%eax
40002ea3:	8b 40 18             	mov    0x18(%eax),%eax
40002ea6:	83 e0 01             	and    $0x1,%eax
40002ea9:	84 c0                	test   %al,%al
40002eab:	74 1e                	je     40002ecb <getuint+0x57>
		return va_arg(*ap, unsigned long);
40002ead:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eb0:	8b 00                	mov    (%eax),%eax
40002eb2:	8d 50 04             	lea    0x4(%eax),%edx
40002eb5:	8b 45 0c             	mov    0xc(%ebp),%eax
40002eb8:	89 10                	mov    %edx,(%eax)
40002eba:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ebd:	8b 00                	mov    (%eax),%eax
40002ebf:	83 e8 04             	sub    $0x4,%eax
40002ec2:	8b 00                	mov    (%eax),%eax
40002ec4:	ba 00 00 00 00       	mov    $0x0,%edx
40002ec9:	eb 1c                	jmp    40002ee7 <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
40002ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ece:	8b 00                	mov    (%eax),%eax
40002ed0:	8d 50 04             	lea    0x4(%eax),%edx
40002ed3:	8b 45 0c             	mov    0xc(%ebp),%eax
40002ed6:	89 10                	mov    %edx,(%eax)
40002ed8:	8b 45 0c             	mov    0xc(%ebp),%eax
40002edb:	8b 00                	mov    (%eax),%eax
40002edd:	83 e8 04             	sub    $0x4,%eax
40002ee0:	8b 00                	mov    (%eax),%eax
40002ee2:	ba 00 00 00 00       	mov    $0x0,%edx
}
40002ee7:	5d                   	pop    %ebp
40002ee8:	c3                   	ret    

40002ee9 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
40002ee9:	55                   	push   %ebp
40002eea:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
40002eec:	8b 45 08             	mov    0x8(%ebp),%eax
40002eef:	8b 40 18             	mov    0x18(%eax),%eax
40002ef2:	83 e0 02             	and    $0x2,%eax
40002ef5:	85 c0                	test   %eax,%eax
40002ef7:	74 1c                	je     40002f15 <getint+0x2c>
		return va_arg(*ap, long long);
40002ef9:	8b 45 0c             	mov    0xc(%ebp),%eax
40002efc:	8b 00                	mov    (%eax),%eax
40002efe:	8d 50 08             	lea    0x8(%eax),%edx
40002f01:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f04:	89 10                	mov    %edx,(%eax)
40002f06:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f09:	8b 00                	mov    (%eax),%eax
40002f0b:	83 e8 08             	sub    $0x8,%eax
40002f0e:	8b 50 04             	mov    0x4(%eax),%edx
40002f11:	8b 00                	mov    (%eax),%eax
40002f13:	eb 47                	jmp    40002f5c <getint+0x73>
	else if (st->flags & F_L)
40002f15:	8b 45 08             	mov    0x8(%ebp),%eax
40002f18:	8b 40 18             	mov    0x18(%eax),%eax
40002f1b:	83 e0 01             	and    $0x1,%eax
40002f1e:	84 c0                	test   %al,%al
40002f20:	74 1e                	je     40002f40 <getint+0x57>
		return va_arg(*ap, long);
40002f22:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f25:	8b 00                	mov    (%eax),%eax
40002f27:	8d 50 04             	lea    0x4(%eax),%edx
40002f2a:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f2d:	89 10                	mov    %edx,(%eax)
40002f2f:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f32:	8b 00                	mov    (%eax),%eax
40002f34:	83 e8 04             	sub    $0x4,%eax
40002f37:	8b 00                	mov    (%eax),%eax
40002f39:	89 c2                	mov    %eax,%edx
40002f3b:	c1 fa 1f             	sar    $0x1f,%edx
40002f3e:	eb 1c                	jmp    40002f5c <getint+0x73>
	else
		return va_arg(*ap, int);
40002f40:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f43:	8b 00                	mov    (%eax),%eax
40002f45:	8d 50 04             	lea    0x4(%eax),%edx
40002f48:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f4b:	89 10                	mov    %edx,(%eax)
40002f4d:	8b 45 0c             	mov    0xc(%ebp),%eax
40002f50:	8b 00                	mov    (%eax),%eax
40002f52:	83 e8 04             	sub    $0x4,%eax
40002f55:	8b 00                	mov    (%eax),%eax
40002f57:	89 c2                	mov    %eax,%edx
40002f59:	c1 fa 1f             	sar    $0x1f,%edx
}
40002f5c:	5d                   	pop    %ebp
40002f5d:	c3                   	ret    

40002f5e <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
40002f5e:	55                   	push   %ebp
40002f5f:	89 e5                	mov    %esp,%ebp
40002f61:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
40002f64:	eb 1a                	jmp    40002f80 <putpad+0x22>
		st->putch(st->padc, st->putdat);
40002f66:	8b 45 08             	mov    0x8(%ebp),%eax
40002f69:	8b 08                	mov    (%eax),%ecx
40002f6b:	8b 45 08             	mov    0x8(%ebp),%eax
40002f6e:	8b 50 04             	mov    0x4(%eax),%edx
40002f71:	8b 45 08             	mov    0x8(%ebp),%eax
40002f74:	8b 40 08             	mov    0x8(%eax),%eax
40002f77:	89 54 24 04          	mov    %edx,0x4(%esp)
40002f7b:	89 04 24             	mov    %eax,(%esp)
40002f7e:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
40002f80:	8b 45 08             	mov    0x8(%ebp),%eax
40002f83:	8b 40 0c             	mov    0xc(%eax),%eax
40002f86:	8d 50 ff             	lea    -0x1(%eax),%edx
40002f89:	8b 45 08             	mov    0x8(%ebp),%eax
40002f8c:	89 50 0c             	mov    %edx,0xc(%eax)
40002f8f:	8b 45 08             	mov    0x8(%ebp),%eax
40002f92:	8b 40 0c             	mov    0xc(%eax),%eax
40002f95:	85 c0                	test   %eax,%eax
40002f97:	79 cd                	jns    40002f66 <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
40002f99:	c9                   	leave  
40002f9a:	c3                   	ret    

40002f9b <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
40002f9b:	55                   	push   %ebp
40002f9c:	89 e5                	mov    %esp,%ebp
40002f9e:	53                   	push   %ebx
40002f9f:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
40002fa2:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
40002fa6:	79 18                	jns    40002fc0 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
40002fa8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002faf:	00 
40002fb0:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fb3:	89 04 24             	mov    %eax,(%esp)
40002fb6:	e8 f5 06 00 00       	call   400036b0 <strchr>
40002fbb:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002fbe:	eb 2c                	jmp    40002fec <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
40002fc0:	8b 45 10             	mov    0x10(%ebp),%eax
40002fc3:	89 44 24 08          	mov    %eax,0x8(%esp)
40002fc7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
40002fce:	00 
40002fcf:	8b 45 0c             	mov    0xc(%ebp),%eax
40002fd2:	89 04 24             	mov    %eax,(%esp)
40002fd5:	e8 da 08 00 00       	call   400038b4 <memchr>
40002fda:	89 45 f0             	mov    %eax,-0x10(%ebp)
40002fdd:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
40002fe1:	75 09                	jne    40002fec <putstr+0x51>
		lim = str + maxlen;
40002fe3:	8b 45 10             	mov    0x10(%ebp),%eax
40002fe6:	03 45 0c             	add    0xc(%ebp),%eax
40002fe9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
40002fec:	8b 45 08             	mov    0x8(%ebp),%eax
40002fef:	8b 40 0c             	mov    0xc(%eax),%eax
40002ff2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
40002ff5:	8b 55 f0             	mov    -0x10(%ebp),%edx
40002ff8:	89 cb                	mov    %ecx,%ebx
40002ffa:	29 d3                	sub    %edx,%ebx
40002ffc:	89 da                	mov    %ebx,%edx
40002ffe:	8d 14 10             	lea    (%eax,%edx,1),%edx
40003001:	8b 45 08             	mov    0x8(%ebp),%eax
40003004:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
40003007:	8b 45 08             	mov    0x8(%ebp),%eax
4000300a:	8b 40 18             	mov    0x18(%eax),%eax
4000300d:	83 e0 10             	and    $0x10,%eax
40003010:	85 c0                	test   %eax,%eax
40003012:	75 32                	jne    40003046 <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
40003014:	8b 45 08             	mov    0x8(%ebp),%eax
40003017:	89 04 24             	mov    %eax,(%esp)
4000301a:	e8 3f ff ff ff       	call   40002f5e <putpad>
	while (str < lim) {
4000301f:	eb 25                	jmp    40003046 <putstr+0xab>
		char ch = *str++;
40003021:	8b 45 0c             	mov    0xc(%ebp),%eax
40003024:	0f b6 00             	movzbl (%eax),%eax
40003027:	88 45 f7             	mov    %al,-0x9(%ebp)
4000302a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
4000302e:	8b 45 08             	mov    0x8(%ebp),%eax
40003031:	8b 08                	mov    (%eax),%ecx
40003033:	8b 45 08             	mov    0x8(%ebp),%eax
40003036:	8b 50 04             	mov    0x4(%eax),%edx
40003039:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
4000303d:	89 54 24 04          	mov    %edx,0x4(%esp)
40003041:	89 04 24             	mov    %eax,(%esp)
40003044:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
40003046:	8b 45 0c             	mov    0xc(%ebp),%eax
40003049:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000304c:	72 d3                	jb     40003021 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
4000304e:	8b 45 08             	mov    0x8(%ebp),%eax
40003051:	89 04 24             	mov    %eax,(%esp)
40003054:	e8 05 ff ff ff       	call   40002f5e <putpad>
}
40003059:	83 c4 24             	add    $0x24,%esp
4000305c:	5b                   	pop    %ebx
4000305d:	5d                   	pop    %ebp
4000305e:	c3                   	ret    

4000305f <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
4000305f:	55                   	push   %ebp
40003060:	89 e5                	mov    %esp,%ebp
40003062:	53                   	push   %ebx
40003063:	83 ec 24             	sub    $0x24,%esp
40003066:	8b 45 10             	mov    0x10(%ebp),%eax
40003069:	89 45 f0             	mov    %eax,-0x10(%ebp)
4000306c:	8b 45 14             	mov    0x14(%ebp),%eax
4000306f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
40003072:	8b 45 08             	mov    0x8(%ebp),%eax
40003075:	8b 40 1c             	mov    0x1c(%eax),%eax
40003078:	89 c2                	mov    %eax,%edx
4000307a:	c1 fa 1f             	sar    $0x1f,%edx
4000307d:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40003080:	77 4e                	ja     400030d0 <genint+0x71>
40003082:	3b 55 f4             	cmp    -0xc(%ebp),%edx
40003085:	72 05                	jb     4000308c <genint+0x2d>
40003087:	3b 45 f0             	cmp    -0x10(%ebp),%eax
4000308a:	77 44                	ja     400030d0 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
4000308c:	8b 45 08             	mov    0x8(%ebp),%eax
4000308f:	8b 40 1c             	mov    0x1c(%eax),%eax
40003092:	89 c2                	mov    %eax,%edx
40003094:	c1 fa 1f             	sar    $0x1f,%edx
40003097:	89 44 24 08          	mov    %eax,0x8(%esp)
4000309b:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000309f:	8b 45 f0             	mov    -0x10(%ebp),%eax
400030a2:	8b 55 f4             	mov    -0xc(%ebp),%edx
400030a5:	89 04 24             	mov    %eax,(%esp)
400030a8:	89 54 24 04          	mov    %edx,0x4(%esp)
400030ac:	e8 5f 08 00 00       	call   40003910 <__udivdi3>
400030b1:	89 44 24 08          	mov    %eax,0x8(%esp)
400030b5:	89 54 24 0c          	mov    %edx,0xc(%esp)
400030b9:	8b 45 0c             	mov    0xc(%ebp),%eax
400030bc:	89 44 24 04          	mov    %eax,0x4(%esp)
400030c0:	8b 45 08             	mov    0x8(%ebp),%eax
400030c3:	89 04 24             	mov    %eax,(%esp)
400030c6:	e8 94 ff ff ff       	call   4000305f <genint>
400030cb:	89 45 0c             	mov    %eax,0xc(%ebp)
400030ce:	eb 1b                	jmp    400030eb <genint+0x8c>
	else if (st->signc >= 0)
400030d0:	8b 45 08             	mov    0x8(%ebp),%eax
400030d3:	8b 40 14             	mov    0x14(%eax),%eax
400030d6:	85 c0                	test   %eax,%eax
400030d8:	78 11                	js     400030eb <genint+0x8c>
		*p++ = st->signc;			// output leading sign
400030da:	8b 45 08             	mov    0x8(%ebp),%eax
400030dd:	8b 40 14             	mov    0x14(%eax),%eax
400030e0:	89 c2                	mov    %eax,%edx
400030e2:	8b 45 0c             	mov    0xc(%ebp),%eax
400030e5:	88 10                	mov    %dl,(%eax)
400030e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
400030eb:	8b 45 08             	mov    0x8(%ebp),%eax
400030ee:	8b 40 1c             	mov    0x1c(%eax),%eax
400030f1:	89 c1                	mov    %eax,%ecx
400030f3:	89 c3                	mov    %eax,%ebx
400030f5:	c1 fb 1f             	sar    $0x1f,%ebx
400030f8:	8b 45 f0             	mov    -0x10(%ebp),%eax
400030fb:	8b 55 f4             	mov    -0xc(%ebp),%edx
400030fe:	89 4c 24 08          	mov    %ecx,0x8(%esp)
40003102:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
40003106:	89 04 24             	mov    %eax,(%esp)
40003109:	89 54 24 04          	mov    %edx,0x4(%esp)
4000310d:	e8 2e 09 00 00       	call   40003a40 <__umoddi3>
40003112:	05 c0 44 00 40       	add    $0x400044c0,%eax
40003117:	0f b6 10             	movzbl (%eax),%edx
4000311a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000311d:	88 10                	mov    %dl,(%eax)
4000311f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
40003123:	8b 45 0c             	mov    0xc(%ebp),%eax
}
40003126:	83 c4 24             	add    $0x24,%esp
40003129:	5b                   	pop    %ebx
4000312a:	5d                   	pop    %ebp
4000312b:	c3                   	ret    

4000312c <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
4000312c:	55                   	push   %ebp
4000312d:	89 e5                	mov    %esp,%ebp
4000312f:	83 ec 58             	sub    $0x58,%esp
40003132:	8b 45 0c             	mov    0xc(%ebp),%eax
40003135:	89 45 c0             	mov    %eax,-0x40(%ebp)
40003138:	8b 45 10             	mov    0x10(%ebp),%eax
4000313b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
4000313e:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40003141:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
40003144:	8b 45 08             	mov    0x8(%ebp),%eax
40003147:	8b 55 14             	mov    0x14(%ebp),%edx
4000314a:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
4000314d:	8b 45 c0             	mov    -0x40(%ebp),%eax
40003150:	8b 55 c4             	mov    -0x3c(%ebp),%edx
40003153:	89 44 24 08          	mov    %eax,0x8(%esp)
40003157:	89 54 24 0c          	mov    %edx,0xc(%esp)
4000315b:	8b 45 f4             	mov    -0xc(%ebp),%eax
4000315e:	89 44 24 04          	mov    %eax,0x4(%esp)
40003162:	8b 45 08             	mov    0x8(%ebp),%eax
40003165:	89 04 24             	mov    %eax,(%esp)
40003168:	e8 f2 fe ff ff       	call   4000305f <genint>
4000316d:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
40003170:	8b 55 f4             	mov    -0xc(%ebp),%edx
40003173:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40003176:	89 d1                	mov    %edx,%ecx
40003178:	29 c1                	sub    %eax,%ecx
4000317a:	89 c8                	mov    %ecx,%eax
4000317c:	89 44 24 08          	mov    %eax,0x8(%esp)
40003180:	8d 45 d6             	lea    -0x2a(%ebp),%eax
40003183:	89 44 24 04          	mov    %eax,0x4(%esp)
40003187:	8b 45 08             	mov    0x8(%ebp),%eax
4000318a:	89 04 24             	mov    %eax,(%esp)
4000318d:	e8 09 fe ff ff       	call   40002f9b <putstr>
}
40003192:	c9                   	leave  
40003193:	c3                   	ret    

40003194 <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
40003194:	55                   	push   %ebp
40003195:	89 e5                	mov    %esp,%ebp
40003197:	53                   	push   %ebx
40003198:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
4000319b:	8d 55 c8             	lea    -0x38(%ebp),%edx
4000319e:	b9 00 00 00 00       	mov    $0x0,%ecx
400031a3:	b8 20 00 00 00       	mov    $0x20,%eax
400031a8:	89 c3                	mov    %eax,%ebx
400031aa:	83 e3 fc             	and    $0xfffffffc,%ebx
400031ad:	b8 00 00 00 00       	mov    $0x0,%eax
400031b2:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
400031b5:	83 c0 04             	add    $0x4,%eax
400031b8:	39 d8                	cmp    %ebx,%eax
400031ba:	72 f6                	jb     400031b2 <vprintfmt+0x1e>
400031bc:	01 c2                	add    %eax,%edx
400031be:	8b 45 08             	mov    0x8(%ebp),%eax
400031c1:	89 45 c8             	mov    %eax,-0x38(%ebp)
400031c4:	8b 45 0c             	mov    0xc(%ebp),%eax
400031c7:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
400031ca:	eb 17                	jmp    400031e3 <vprintfmt+0x4f>
			if (ch == '\0')
400031cc:	85 db                	test   %ebx,%ebx
400031ce:	0f 84 52 03 00 00    	je     40003526 <vprintfmt+0x392>
				return;
			putch(ch, putdat);
400031d4:	8b 45 0c             	mov    0xc(%ebp),%eax
400031d7:	89 44 24 04          	mov    %eax,0x4(%esp)
400031db:	89 1c 24             	mov    %ebx,(%esp)
400031de:	8b 45 08             	mov    0x8(%ebp),%eax
400031e1:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
400031e3:	8b 45 10             	mov    0x10(%ebp),%eax
400031e6:	0f b6 00             	movzbl (%eax),%eax
400031e9:	0f b6 d8             	movzbl %al,%ebx
400031ec:	83 fb 25             	cmp    $0x25,%ebx
400031ef:	0f 95 c0             	setne  %al
400031f2:	83 45 10 01          	addl   $0x1,0x10(%ebp)
400031f6:	84 c0                	test   %al,%al
400031f8:	75 d2                	jne    400031cc <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
400031fa:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
40003201:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
40003208:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
4000320f:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
40003216:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
4000321d:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
40003224:	eb 04                	jmp    4000322a <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
40003226:	90                   	nop
40003227:	eb 01                	jmp    4000322a <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
40003229:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
4000322a:	8b 45 10             	mov    0x10(%ebp),%eax
4000322d:	0f b6 00             	movzbl (%eax),%eax
40003230:	0f b6 d8             	movzbl %al,%ebx
40003233:	89 d8                	mov    %ebx,%eax
40003235:	83 45 10 01          	addl   $0x1,0x10(%ebp)
40003239:	83 e8 20             	sub    $0x20,%eax
4000323c:	83 f8 58             	cmp    $0x58,%eax
4000323f:	0f 87 b1 02 00 00    	ja     400034f6 <vprintfmt+0x362>
40003245:	8b 04 85 d8 44 00 40 	mov    0x400044d8(,%eax,4),%eax
4000324c:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
4000324e:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003251:	83 c8 10             	or     $0x10,%eax
40003254:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
40003257:	eb d1                	jmp    4000322a <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
40003259:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
40003260:	eb c8                	jmp    4000322a <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
40003262:	8b 45 dc             	mov    -0x24(%ebp),%eax
40003265:	85 c0                	test   %eax,%eax
40003267:	79 bd                	jns    40003226 <vprintfmt+0x92>
				st.signc = ' ';
40003269:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
40003270:	eb b8                	jmp    4000322a <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
40003272:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003275:	83 e0 08             	and    $0x8,%eax
40003278:	85 c0                	test   %eax,%eax
4000327a:	75 07                	jne    40003283 <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
4000327c:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
40003283:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
4000328a:	8b 55 d8             	mov    -0x28(%ebp),%edx
4000328d:	89 d0                	mov    %edx,%eax
4000328f:	c1 e0 02             	shl    $0x2,%eax
40003292:	01 d0                	add    %edx,%eax
40003294:	01 c0                	add    %eax,%eax
40003296:	01 d8                	add    %ebx,%eax
40003298:	83 e8 30             	sub    $0x30,%eax
4000329b:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
4000329e:	8b 45 10             	mov    0x10(%ebp),%eax
400032a1:	0f b6 00             	movzbl (%eax),%eax
400032a4:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
400032a7:	83 fb 2f             	cmp    $0x2f,%ebx
400032aa:	7e 21                	jle    400032cd <vprintfmt+0x139>
400032ac:	83 fb 39             	cmp    $0x39,%ebx
400032af:	7f 1f                	jg     400032d0 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
400032b1:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
400032b5:	eb d3                	jmp    4000328a <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
400032b7:	8b 45 14             	mov    0x14(%ebp),%eax
400032ba:	83 c0 04             	add    $0x4,%eax
400032bd:	89 45 14             	mov    %eax,0x14(%ebp)
400032c0:	8b 45 14             	mov    0x14(%ebp),%eax
400032c3:	83 e8 04             	sub    $0x4,%eax
400032c6:	8b 00                	mov    (%eax),%eax
400032c8:	89 45 d8             	mov    %eax,-0x28(%ebp)
400032cb:	eb 04                	jmp    400032d1 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
400032cd:	90                   	nop
400032ce:	eb 01                	jmp    400032d1 <vprintfmt+0x13d>
400032d0:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
400032d1:	8b 45 e0             	mov    -0x20(%ebp),%eax
400032d4:	83 e0 08             	and    $0x8,%eax
400032d7:	85 c0                	test   %eax,%eax
400032d9:	0f 85 4a ff ff ff    	jne    40003229 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
400032df:	8b 45 d8             	mov    -0x28(%ebp),%eax
400032e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
400032e5:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
400032ec:	e9 39 ff ff ff       	jmp    4000322a <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
400032f1:	8b 45 e0             	mov    -0x20(%ebp),%eax
400032f4:	83 c8 08             	or     $0x8,%eax
400032f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
400032fa:	e9 2b ff ff ff       	jmp    4000322a <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
400032ff:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003302:	83 c8 04             	or     $0x4,%eax
40003305:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
40003308:	e9 1d ff ff ff       	jmp    4000322a <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
4000330d:	8b 55 e0             	mov    -0x20(%ebp),%edx
40003310:	8b 45 e0             	mov    -0x20(%ebp),%eax
40003313:	83 e0 01             	and    $0x1,%eax
40003316:	84 c0                	test   %al,%al
40003318:	74 07                	je     40003321 <vprintfmt+0x18d>
4000331a:	b8 02 00 00 00       	mov    $0x2,%eax
4000331f:	eb 05                	jmp    40003326 <vprintfmt+0x192>
40003321:	b8 01 00 00 00       	mov    $0x1,%eax
40003326:	09 d0                	or     %edx,%eax
40003328:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
4000332b:	e9 fa fe ff ff       	jmp    4000322a <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
40003330:	8b 45 14             	mov    0x14(%ebp),%eax
40003333:	83 c0 04             	add    $0x4,%eax
40003336:	89 45 14             	mov    %eax,0x14(%ebp)
40003339:	8b 45 14             	mov    0x14(%ebp),%eax
4000333c:	83 e8 04             	sub    $0x4,%eax
4000333f:	8b 00                	mov    (%eax),%eax
40003341:	8b 55 0c             	mov    0xc(%ebp),%edx
40003344:	89 54 24 04          	mov    %edx,0x4(%esp)
40003348:	89 04 24             	mov    %eax,(%esp)
4000334b:	8b 45 08             	mov    0x8(%ebp),%eax
4000334e:	ff d0                	call   *%eax
			break;
40003350:	e9 cb 01 00 00       	jmp    40003520 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
40003355:	8b 45 14             	mov    0x14(%ebp),%eax
40003358:	83 c0 04             	add    $0x4,%eax
4000335b:	89 45 14             	mov    %eax,0x14(%ebp)
4000335e:	8b 45 14             	mov    0x14(%ebp),%eax
40003361:	83 e8 04             	sub    $0x4,%eax
40003364:	8b 00                	mov    (%eax),%eax
40003366:	89 45 f4             	mov    %eax,-0xc(%ebp)
40003369:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
4000336d:	75 07                	jne    40003376 <vprintfmt+0x1e2>
				s = "(null)";
4000336f:	c7 45 f4 d1 44 00 40 	movl   $0x400044d1,-0xc(%ebp)
			putstr(&st, s, st.prec);
40003376:	8b 45 d8             	mov    -0x28(%ebp),%eax
40003379:	89 44 24 08          	mov    %eax,0x8(%esp)
4000337d:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003380:	89 44 24 04          	mov    %eax,0x4(%esp)
40003384:	8d 45 c8             	lea    -0x38(%ebp),%eax
40003387:	89 04 24             	mov    %eax,(%esp)
4000338a:	e8 0c fc ff ff       	call   40002f9b <putstr>
			break;
4000338f:	e9 8c 01 00 00       	jmp    40003520 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
40003394:	8d 45 14             	lea    0x14(%ebp),%eax
40003397:	89 44 24 04          	mov    %eax,0x4(%esp)
4000339b:	8d 45 c8             	lea    -0x38(%ebp),%eax
4000339e:	89 04 24             	mov    %eax,(%esp)
400033a1:	e8 43 fb ff ff       	call   40002ee9 <getint>
400033a6:	89 45 e8             	mov    %eax,-0x18(%ebp)
400033a9:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
400033ac:	8b 45 e8             	mov    -0x18(%ebp),%eax
400033af:	8b 55 ec             	mov    -0x14(%ebp),%edx
400033b2:	85 d2                	test   %edx,%edx
400033b4:	79 1a                	jns    400033d0 <vprintfmt+0x23c>
				num = -(intmax_t) num;
400033b6:	8b 45 e8             	mov    -0x18(%ebp),%eax
400033b9:	8b 55 ec             	mov    -0x14(%ebp),%edx
400033bc:	f7 d8                	neg    %eax
400033be:	83 d2 00             	adc    $0x0,%edx
400033c1:	f7 da                	neg    %edx
400033c3:	89 45 e8             	mov    %eax,-0x18(%ebp)
400033c6:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
400033c9:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
400033d0:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
400033d7:	00 
400033d8:	8b 45 e8             	mov    -0x18(%ebp),%eax
400033db:	8b 55 ec             	mov    -0x14(%ebp),%edx
400033de:	89 44 24 04          	mov    %eax,0x4(%esp)
400033e2:	89 54 24 08          	mov    %edx,0x8(%esp)
400033e6:	8d 45 c8             	lea    -0x38(%ebp),%eax
400033e9:	89 04 24             	mov    %eax,(%esp)
400033ec:	e8 3b fd ff ff       	call   4000312c <putint>
			break;
400033f1:	e9 2a 01 00 00       	jmp    40003520 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
400033f6:	8d 45 14             	lea    0x14(%ebp),%eax
400033f9:	89 44 24 04          	mov    %eax,0x4(%esp)
400033fd:	8d 45 c8             	lea    -0x38(%ebp),%eax
40003400:	89 04 24             	mov    %eax,(%esp)
40003403:	e8 6c fa ff ff       	call   40002e74 <getuint>
40003408:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
4000340f:	00 
40003410:	89 44 24 04          	mov    %eax,0x4(%esp)
40003414:	89 54 24 08          	mov    %edx,0x8(%esp)
40003418:	8d 45 c8             	lea    -0x38(%ebp),%eax
4000341b:	89 04 24             	mov    %eax,(%esp)
4000341e:	e8 09 fd ff ff       	call   4000312c <putint>
			break;
40003423:	e9 f8 00 00 00       	jmp    40003520 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			putint(&st, getuint(&st, &ap), 8);
40003428:	8d 45 14             	lea    0x14(%ebp),%eax
4000342b:	89 44 24 04          	mov    %eax,0x4(%esp)
4000342f:	8d 45 c8             	lea    -0x38(%ebp),%eax
40003432:	89 04 24             	mov    %eax,(%esp)
40003435:	e8 3a fa ff ff       	call   40002e74 <getuint>
4000343a:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
40003441:	00 
40003442:	89 44 24 04          	mov    %eax,0x4(%esp)
40003446:	89 54 24 08          	mov    %edx,0x8(%esp)
4000344a:	8d 45 c8             	lea    -0x38(%ebp),%eax
4000344d:	89 04 24             	mov    %eax,(%esp)
40003450:	e8 d7 fc ff ff       	call   4000312c <putint>
			break;
40003455:	e9 c6 00 00 00       	jmp    40003520 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
4000345a:	8d 45 14             	lea    0x14(%ebp),%eax
4000345d:	89 44 24 04          	mov    %eax,0x4(%esp)
40003461:	8d 45 c8             	lea    -0x38(%ebp),%eax
40003464:	89 04 24             	mov    %eax,(%esp)
40003467:	e8 08 fa ff ff       	call   40002e74 <getuint>
4000346c:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
40003473:	00 
40003474:	89 44 24 04          	mov    %eax,0x4(%esp)
40003478:	89 54 24 08          	mov    %edx,0x8(%esp)
4000347c:	8d 45 c8             	lea    -0x38(%ebp),%eax
4000347f:	89 04 24             	mov    %eax,(%esp)
40003482:	e8 a5 fc ff ff       	call   4000312c <putint>
			break;
40003487:	e9 94 00 00 00       	jmp    40003520 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
4000348c:	8b 45 0c             	mov    0xc(%ebp),%eax
4000348f:	89 44 24 04          	mov    %eax,0x4(%esp)
40003493:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
4000349a:	8b 45 08             	mov    0x8(%ebp),%eax
4000349d:	ff d0                	call   *%eax
			putch('x', putdat);
4000349f:	8b 45 0c             	mov    0xc(%ebp),%eax
400034a2:	89 44 24 04          	mov    %eax,0x4(%esp)
400034a6:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
400034ad:	8b 45 08             	mov    0x8(%ebp),%eax
400034b0:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
400034b2:	8b 45 14             	mov    0x14(%ebp),%eax
400034b5:	83 c0 04             	add    $0x4,%eax
400034b8:	89 45 14             	mov    %eax,0x14(%ebp)
400034bb:	8b 45 14             	mov    0x14(%ebp),%eax
400034be:	83 e8 04             	sub    $0x4,%eax
400034c1:	8b 00                	mov    (%eax),%eax
400034c3:	ba 00 00 00 00       	mov    $0x0,%edx
400034c8:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
400034cf:	00 
400034d0:	89 44 24 04          	mov    %eax,0x4(%esp)
400034d4:	89 54 24 08          	mov    %edx,0x8(%esp)
400034d8:	8d 45 c8             	lea    -0x38(%ebp),%eax
400034db:	89 04 24             	mov    %eax,(%esp)
400034de:	e8 49 fc ff ff       	call   4000312c <putint>
			break;
400034e3:	eb 3b                	jmp    40003520 <vprintfmt+0x38c>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
400034e5:	8b 45 0c             	mov    0xc(%ebp),%eax
400034e8:	89 44 24 04          	mov    %eax,0x4(%esp)
400034ec:	89 1c 24             	mov    %ebx,(%esp)
400034ef:	8b 45 08             	mov    0x8(%ebp),%eax
400034f2:	ff d0                	call   *%eax
			break;
400034f4:	eb 2a                	jmp    40003520 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
400034f6:	8b 45 0c             	mov    0xc(%ebp),%eax
400034f9:	89 44 24 04          	mov    %eax,0x4(%esp)
400034fd:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
40003504:	8b 45 08             	mov    0x8(%ebp),%eax
40003507:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
40003509:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
4000350d:	eb 04                	jmp    40003513 <vprintfmt+0x37f>
4000350f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003513:	8b 45 10             	mov    0x10(%ebp),%eax
40003516:	83 e8 01             	sub    $0x1,%eax
40003519:	0f b6 00             	movzbl (%eax),%eax
4000351c:	3c 25                	cmp    $0x25,%al
4000351e:	75 ef                	jne    4000350f <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
40003520:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
40003521:	e9 bd fc ff ff       	jmp    400031e3 <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
40003526:	83 c4 44             	add    $0x44,%esp
40003529:	5b                   	pop    %ebx
4000352a:	5d                   	pop    %ebp
4000352b:	c3                   	ret    

4000352c <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
4000352c:	55                   	push   %ebp
4000352d:	89 e5                	mov    %esp,%ebp
4000352f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
40003532:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
40003539:	eb 08                	jmp    40003543 <strlen+0x17>
		n++;
4000353b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
4000353f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003543:	8b 45 08             	mov    0x8(%ebp),%eax
40003546:	0f b6 00             	movzbl (%eax),%eax
40003549:	84 c0                	test   %al,%al
4000354b:	75 ee                	jne    4000353b <strlen+0xf>
		n++;
	return n;
4000354d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40003550:	c9                   	leave  
40003551:	c3                   	ret    

40003552 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
40003552:	55                   	push   %ebp
40003553:	89 e5                	mov    %esp,%ebp
40003555:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
40003558:	8b 45 08             	mov    0x8(%ebp),%eax
4000355b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
4000355e:	8b 45 0c             	mov    0xc(%ebp),%eax
40003561:	0f b6 10             	movzbl (%eax),%edx
40003564:	8b 45 08             	mov    0x8(%ebp),%eax
40003567:	88 10                	mov    %dl,(%eax)
40003569:	8b 45 08             	mov    0x8(%ebp),%eax
4000356c:	0f b6 00             	movzbl (%eax),%eax
4000356f:	84 c0                	test   %al,%al
40003571:	0f 95 c0             	setne  %al
40003574:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003578:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
4000357c:	84 c0                	test   %al,%al
4000357e:	75 de                	jne    4000355e <strcpy+0xc>
		/* do nothing */;
	return ret;
40003580:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
40003583:	c9                   	leave  
40003584:	c3                   	ret    

40003585 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
40003585:	55                   	push   %ebp
40003586:	89 e5                	mov    %esp,%ebp
40003588:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
4000358b:	8b 45 08             	mov    0x8(%ebp),%eax
4000358e:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
40003591:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
40003598:	eb 21                	jmp    400035bb <strncpy+0x36>
		*dst++ = *src;
4000359a:	8b 45 0c             	mov    0xc(%ebp),%eax
4000359d:	0f b6 10             	movzbl (%eax),%edx
400035a0:	8b 45 08             	mov    0x8(%ebp),%eax
400035a3:	88 10                	mov    %dl,(%eax)
400035a5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
400035a9:	8b 45 0c             	mov    0xc(%ebp),%eax
400035ac:	0f b6 00             	movzbl (%eax),%eax
400035af:	84 c0                	test   %al,%al
400035b1:	74 04                	je     400035b7 <strncpy+0x32>
			src++;
400035b3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
400035b7:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
400035bb:	8b 45 f8             	mov    -0x8(%ebp),%eax
400035be:	3b 45 10             	cmp    0x10(%ebp),%eax
400035c1:	72 d7                	jb     4000359a <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
400035c3:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
400035c6:	c9                   	leave  
400035c7:	c3                   	ret    

400035c8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
400035c8:	55                   	push   %ebp
400035c9:	89 e5                	mov    %esp,%ebp
400035cb:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
400035ce:	8b 45 08             	mov    0x8(%ebp),%eax
400035d1:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
400035d4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400035d8:	74 2f                	je     40003609 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
400035da:	eb 13                	jmp    400035ef <strlcpy+0x27>
			*dst++ = *src++;
400035dc:	8b 45 0c             	mov    0xc(%ebp),%eax
400035df:	0f b6 10             	movzbl (%eax),%edx
400035e2:	8b 45 08             	mov    0x8(%ebp),%eax
400035e5:	88 10                	mov    %dl,(%eax)
400035e7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400035eb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
400035ef:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400035f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400035f7:	74 0a                	je     40003603 <strlcpy+0x3b>
400035f9:	8b 45 0c             	mov    0xc(%ebp),%eax
400035fc:	0f b6 00             	movzbl (%eax),%eax
400035ff:	84 c0                	test   %al,%al
40003601:	75 d9                	jne    400035dc <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
40003603:	8b 45 08             	mov    0x8(%ebp),%eax
40003606:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
40003609:	8b 55 08             	mov    0x8(%ebp),%edx
4000360c:	8b 45 fc             	mov    -0x4(%ebp),%eax
4000360f:	89 d1                	mov    %edx,%ecx
40003611:	29 c1                	sub    %eax,%ecx
40003613:	89 c8                	mov    %ecx,%eax
}
40003615:	c9                   	leave  
40003616:	c3                   	ret    

40003617 <strcmp>:

int
strcmp(const char *p, const char *q)
{
40003617:	55                   	push   %ebp
40003618:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
4000361a:	eb 08                	jmp    40003624 <strcmp+0xd>
		p++, q++;
4000361c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003620:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
40003624:	8b 45 08             	mov    0x8(%ebp),%eax
40003627:	0f b6 00             	movzbl (%eax),%eax
4000362a:	84 c0                	test   %al,%al
4000362c:	74 10                	je     4000363e <strcmp+0x27>
4000362e:	8b 45 08             	mov    0x8(%ebp),%eax
40003631:	0f b6 10             	movzbl (%eax),%edx
40003634:	8b 45 0c             	mov    0xc(%ebp),%eax
40003637:	0f b6 00             	movzbl (%eax),%eax
4000363a:	38 c2                	cmp    %al,%dl
4000363c:	74 de                	je     4000361c <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
4000363e:	8b 45 08             	mov    0x8(%ebp),%eax
40003641:	0f b6 00             	movzbl (%eax),%eax
40003644:	0f b6 d0             	movzbl %al,%edx
40003647:	8b 45 0c             	mov    0xc(%ebp),%eax
4000364a:	0f b6 00             	movzbl (%eax),%eax
4000364d:	0f b6 c0             	movzbl %al,%eax
40003650:	89 d1                	mov    %edx,%ecx
40003652:	29 c1                	sub    %eax,%ecx
40003654:	89 c8                	mov    %ecx,%eax
}
40003656:	5d                   	pop    %ebp
40003657:	c3                   	ret    

40003658 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
40003658:	55                   	push   %ebp
40003659:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
4000365b:	eb 0c                	jmp    40003669 <strncmp+0x11>
		n--, p++, q++;
4000365d:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
40003661:	83 45 08 01          	addl   $0x1,0x8(%ebp)
40003665:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
40003669:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000366d:	74 1a                	je     40003689 <strncmp+0x31>
4000366f:	8b 45 08             	mov    0x8(%ebp),%eax
40003672:	0f b6 00             	movzbl (%eax),%eax
40003675:	84 c0                	test   %al,%al
40003677:	74 10                	je     40003689 <strncmp+0x31>
40003679:	8b 45 08             	mov    0x8(%ebp),%eax
4000367c:	0f b6 10             	movzbl (%eax),%edx
4000367f:	8b 45 0c             	mov    0xc(%ebp),%eax
40003682:	0f b6 00             	movzbl (%eax),%eax
40003685:	38 c2                	cmp    %al,%dl
40003687:	74 d4                	je     4000365d <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
40003689:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
4000368d:	75 07                	jne    40003696 <strncmp+0x3e>
		return 0;
4000368f:	b8 00 00 00 00       	mov    $0x0,%eax
40003694:	eb 18                	jmp    400036ae <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
40003696:	8b 45 08             	mov    0x8(%ebp),%eax
40003699:	0f b6 00             	movzbl (%eax),%eax
4000369c:	0f b6 d0             	movzbl %al,%edx
4000369f:	8b 45 0c             	mov    0xc(%ebp),%eax
400036a2:	0f b6 00             	movzbl (%eax),%eax
400036a5:	0f b6 c0             	movzbl %al,%eax
400036a8:	89 d1                	mov    %edx,%ecx
400036aa:	29 c1                	sub    %eax,%ecx
400036ac:	89 c8                	mov    %ecx,%eax
}
400036ae:	5d                   	pop    %ebp
400036af:	c3                   	ret    

400036b0 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
400036b0:	55                   	push   %ebp
400036b1:	89 e5                	mov    %esp,%ebp
400036b3:	83 ec 04             	sub    $0x4,%esp
400036b6:	8b 45 0c             	mov    0xc(%ebp),%eax
400036b9:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
400036bc:	eb 1a                	jmp    400036d8 <strchr+0x28>
		if (*s++ == 0)
400036be:	8b 45 08             	mov    0x8(%ebp),%eax
400036c1:	0f b6 00             	movzbl (%eax),%eax
400036c4:	84 c0                	test   %al,%al
400036c6:	0f 94 c0             	sete   %al
400036c9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400036cd:	84 c0                	test   %al,%al
400036cf:	74 07                	je     400036d8 <strchr+0x28>
			return NULL;
400036d1:	b8 00 00 00 00       	mov    $0x0,%eax
400036d6:	eb 0e                	jmp    400036e6 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
400036d8:	8b 45 08             	mov    0x8(%ebp),%eax
400036db:	0f b6 00             	movzbl (%eax),%eax
400036de:	3a 45 fc             	cmp    -0x4(%ebp),%al
400036e1:	75 db                	jne    400036be <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
400036e3:	8b 45 08             	mov    0x8(%ebp),%eax
}
400036e6:	c9                   	leave  
400036e7:	c3                   	ret    

400036e8 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
400036e8:	55                   	push   %ebp
400036e9:	89 e5                	mov    %esp,%ebp
400036eb:	57                   	push   %edi
400036ec:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
400036ef:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400036f3:	75 05                	jne    400036fa <memset+0x12>
		return v;
400036f5:	8b 45 08             	mov    0x8(%ebp),%eax
400036f8:	eb 5c                	jmp    40003756 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
400036fa:	8b 45 08             	mov    0x8(%ebp),%eax
400036fd:	83 e0 03             	and    $0x3,%eax
40003700:	85 c0                	test   %eax,%eax
40003702:	75 41                	jne    40003745 <memset+0x5d>
40003704:	8b 45 10             	mov    0x10(%ebp),%eax
40003707:	83 e0 03             	and    $0x3,%eax
4000370a:	85 c0                	test   %eax,%eax
4000370c:	75 37                	jne    40003745 <memset+0x5d>
		c &= 0xFF;
4000370e:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
40003715:	8b 45 0c             	mov    0xc(%ebp),%eax
40003718:	89 c2                	mov    %eax,%edx
4000371a:	c1 e2 18             	shl    $0x18,%edx
4000371d:	8b 45 0c             	mov    0xc(%ebp),%eax
40003720:	c1 e0 10             	shl    $0x10,%eax
40003723:	09 c2                	or     %eax,%edx
40003725:	8b 45 0c             	mov    0xc(%ebp),%eax
40003728:	c1 e0 08             	shl    $0x8,%eax
4000372b:	09 d0                	or     %edx,%eax
4000372d:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
40003730:	8b 45 10             	mov    0x10(%ebp),%eax
40003733:	89 c1                	mov    %eax,%ecx
40003735:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
40003738:	8b 55 08             	mov    0x8(%ebp),%edx
4000373b:	8b 45 0c             	mov    0xc(%ebp),%eax
4000373e:	89 d7                	mov    %edx,%edi
40003740:	fc                   	cld    
40003741:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
40003743:	eb 0e                	jmp    40003753 <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
40003745:	8b 55 08             	mov    0x8(%ebp),%edx
40003748:	8b 45 0c             	mov    0xc(%ebp),%eax
4000374b:	8b 4d 10             	mov    0x10(%ebp),%ecx
4000374e:	89 d7                	mov    %edx,%edi
40003750:	fc                   	cld    
40003751:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
40003753:	8b 45 08             	mov    0x8(%ebp),%eax
}
40003756:	83 c4 10             	add    $0x10,%esp
40003759:	5f                   	pop    %edi
4000375a:	5d                   	pop    %ebp
4000375b:	c3                   	ret    

4000375c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
4000375c:	55                   	push   %ebp
4000375d:	89 e5                	mov    %esp,%ebp
4000375f:	57                   	push   %edi
40003760:	56                   	push   %esi
40003761:	53                   	push   %ebx
40003762:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
40003765:	8b 45 0c             	mov    0xc(%ebp),%eax
40003768:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
4000376b:	8b 45 08             	mov    0x8(%ebp),%eax
4000376e:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
40003771:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003774:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40003777:	73 6e                	jae    400037e7 <memmove+0x8b>
40003779:	8b 45 10             	mov    0x10(%ebp),%eax
4000377c:	8b 55 ec             	mov    -0x14(%ebp),%edx
4000377f:	8d 04 02             	lea    (%edx,%eax,1),%eax
40003782:	3b 45 f0             	cmp    -0x10(%ebp),%eax
40003785:	76 60                	jbe    400037e7 <memmove+0x8b>
		s += n;
40003787:	8b 45 10             	mov    0x10(%ebp),%eax
4000378a:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
4000378d:	8b 45 10             	mov    0x10(%ebp),%eax
40003790:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
40003793:	8b 45 ec             	mov    -0x14(%ebp),%eax
40003796:	83 e0 03             	and    $0x3,%eax
40003799:	85 c0                	test   %eax,%eax
4000379b:	75 2f                	jne    400037cc <memmove+0x70>
4000379d:	8b 45 f0             	mov    -0x10(%ebp),%eax
400037a0:	83 e0 03             	and    $0x3,%eax
400037a3:	85 c0                	test   %eax,%eax
400037a5:	75 25                	jne    400037cc <memmove+0x70>
400037a7:	8b 45 10             	mov    0x10(%ebp),%eax
400037aa:	83 e0 03             	and    $0x3,%eax
400037ad:	85 c0                	test   %eax,%eax
400037af:	75 1b                	jne    400037cc <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
400037b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
400037b4:	83 e8 04             	sub    $0x4,%eax
400037b7:	8b 55 ec             	mov    -0x14(%ebp),%edx
400037ba:	83 ea 04             	sub    $0x4,%edx
400037bd:	8b 4d 10             	mov    0x10(%ebp),%ecx
400037c0:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
400037c3:	89 c7                	mov    %eax,%edi
400037c5:	89 d6                	mov    %edx,%esi
400037c7:	fd                   	std    
400037c8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
400037ca:	eb 18                	jmp    400037e4 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
400037cc:	8b 45 f0             	mov    -0x10(%ebp),%eax
400037cf:	8d 50 ff             	lea    -0x1(%eax),%edx
400037d2:	8b 45 ec             	mov    -0x14(%ebp),%eax
400037d5:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
400037d8:	8b 45 10             	mov    0x10(%ebp),%eax
400037db:	89 d7                	mov    %edx,%edi
400037dd:	89 de                	mov    %ebx,%esi
400037df:	89 c1                	mov    %eax,%ecx
400037e1:	fd                   	std    
400037e2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
400037e4:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
400037e5:	eb 45                	jmp    4000382c <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
400037e7:	8b 45 ec             	mov    -0x14(%ebp),%eax
400037ea:	83 e0 03             	and    $0x3,%eax
400037ed:	85 c0                	test   %eax,%eax
400037ef:	75 2b                	jne    4000381c <memmove+0xc0>
400037f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
400037f4:	83 e0 03             	and    $0x3,%eax
400037f7:	85 c0                	test   %eax,%eax
400037f9:	75 21                	jne    4000381c <memmove+0xc0>
400037fb:	8b 45 10             	mov    0x10(%ebp),%eax
400037fe:	83 e0 03             	and    $0x3,%eax
40003801:	85 c0                	test   %eax,%eax
40003803:	75 17                	jne    4000381c <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
40003805:	8b 45 10             	mov    0x10(%ebp),%eax
40003808:	89 c1                	mov    %eax,%ecx
4000380a:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
4000380d:	8b 45 f0             	mov    -0x10(%ebp),%eax
40003810:	8b 55 ec             	mov    -0x14(%ebp),%edx
40003813:	89 c7                	mov    %eax,%edi
40003815:	89 d6                	mov    %edx,%esi
40003817:	fc                   	cld    
40003818:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
4000381a:	eb 10                	jmp    4000382c <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
4000381c:	8b 45 f0             	mov    -0x10(%ebp),%eax
4000381f:	8b 55 ec             	mov    -0x14(%ebp),%edx
40003822:	8b 4d 10             	mov    0x10(%ebp),%ecx
40003825:	89 c7                	mov    %eax,%edi
40003827:	89 d6                	mov    %edx,%esi
40003829:	fc                   	cld    
4000382a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
4000382c:	8b 45 08             	mov    0x8(%ebp),%eax
}
4000382f:	83 c4 10             	add    $0x10,%esp
40003832:	5b                   	pop    %ebx
40003833:	5e                   	pop    %esi
40003834:	5f                   	pop    %edi
40003835:	5d                   	pop    %ebp
40003836:	c3                   	ret    

40003837 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
40003837:	55                   	push   %ebp
40003838:	89 e5                	mov    %esp,%ebp
4000383a:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
4000383d:	8b 45 10             	mov    0x10(%ebp),%eax
40003840:	89 44 24 08          	mov    %eax,0x8(%esp)
40003844:	8b 45 0c             	mov    0xc(%ebp),%eax
40003847:	89 44 24 04          	mov    %eax,0x4(%esp)
4000384b:	8b 45 08             	mov    0x8(%ebp),%eax
4000384e:	89 04 24             	mov    %eax,(%esp)
40003851:	e8 06 ff ff ff       	call   4000375c <memmove>
}
40003856:	c9                   	leave  
40003857:	c3                   	ret    

40003858 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
40003858:	55                   	push   %ebp
40003859:	89 e5                	mov    %esp,%ebp
4000385b:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
4000385e:	8b 45 08             	mov    0x8(%ebp),%eax
40003861:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
40003864:	8b 45 0c             	mov    0xc(%ebp),%eax
40003867:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
4000386a:	eb 32                	jmp    4000389e <memcmp+0x46>
		if (*s1 != *s2)
4000386c:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000386f:	0f b6 10             	movzbl (%eax),%edx
40003872:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003875:	0f b6 00             	movzbl (%eax),%eax
40003878:	38 c2                	cmp    %al,%dl
4000387a:	74 1a                	je     40003896 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
4000387c:	8b 45 f8             	mov    -0x8(%ebp),%eax
4000387f:	0f b6 00             	movzbl (%eax),%eax
40003882:	0f b6 d0             	movzbl %al,%edx
40003885:	8b 45 fc             	mov    -0x4(%ebp),%eax
40003888:	0f b6 00             	movzbl (%eax),%eax
4000388b:	0f b6 c0             	movzbl %al,%eax
4000388e:	89 d1                	mov    %edx,%ecx
40003890:	29 c1                	sub    %eax,%ecx
40003892:	89 c8                	mov    %ecx,%eax
40003894:	eb 1c                	jmp    400038b2 <memcmp+0x5a>
		s1++, s2++;
40003896:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
4000389a:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
4000389e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
400038a2:	0f 95 c0             	setne  %al
400038a5:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
400038a9:	84 c0                	test   %al,%al
400038ab:	75 bf                	jne    4000386c <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
400038ad:	b8 00 00 00 00       	mov    $0x0,%eax
}
400038b2:	c9                   	leave  
400038b3:	c3                   	ret    

400038b4 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
400038b4:	55                   	push   %ebp
400038b5:	89 e5                	mov    %esp,%ebp
400038b7:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
400038ba:	8b 45 10             	mov    0x10(%ebp),%eax
400038bd:	8b 55 08             	mov    0x8(%ebp),%edx
400038c0:	8d 04 02             	lea    (%edx,%eax,1),%eax
400038c3:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
400038c6:	eb 16                	jmp    400038de <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
400038c8:	8b 45 08             	mov    0x8(%ebp),%eax
400038cb:	0f b6 10             	movzbl (%eax),%edx
400038ce:	8b 45 0c             	mov    0xc(%ebp),%eax
400038d1:	38 c2                	cmp    %al,%dl
400038d3:	75 05                	jne    400038da <memchr+0x26>
			return (void *) s;
400038d5:	8b 45 08             	mov    0x8(%ebp),%eax
400038d8:	eb 11                	jmp    400038eb <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
400038da:	83 45 08 01          	addl   $0x1,0x8(%ebp)
400038de:	8b 45 08             	mov    0x8(%ebp),%eax
400038e1:	3b 45 fc             	cmp    -0x4(%ebp),%eax
400038e4:	72 e2                	jb     400038c8 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
400038e6:	b8 00 00 00 00       	mov    $0x0,%eax
}
400038eb:	c9                   	leave  
400038ec:	c3                   	ret    
400038ed:	90                   	nop
400038ee:	90                   	nop
400038ef:	90                   	nop

400038f0 <cputs>:

#include <inc/stdio.h>
#include <inc/syscall.h>

void cputs(const char *str)
{
400038f0:	55                   	push   %ebp
400038f1:	89 e5                	mov    %esp,%ebp
400038f3:	53                   	push   %ebx
400038f4:	83 ec 10             	sub    $0x10,%esp
400038f7:	8b 45 08             	mov    0x8(%ebp),%eax
400038fa:	89 45 f8             	mov    %eax,-0x8(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
400038fd:	b8 00 00 00 00       	mov    $0x0,%eax
40003902:	8b 55 f8             	mov    -0x8(%ebp),%edx
40003905:	89 d3                	mov    %edx,%ebx
40003907:	cd 30                	int    $0x30
	sys_cputs(str);
}
40003909:	83 c4 10             	add    $0x10,%esp
4000390c:	5b                   	pop    %ebx
4000390d:	5d                   	pop    %ebp
4000390e:	c3                   	ret    
4000390f:	90                   	nop

40003910 <__udivdi3>:
40003910:	55                   	push   %ebp
40003911:	89 e5                	mov    %esp,%ebp
40003913:	57                   	push   %edi
40003914:	56                   	push   %esi
40003915:	83 ec 10             	sub    $0x10,%esp
40003918:	8b 45 14             	mov    0x14(%ebp),%eax
4000391b:	8b 55 08             	mov    0x8(%ebp),%edx
4000391e:	8b 75 10             	mov    0x10(%ebp),%esi
40003921:	8b 7d 0c             	mov    0xc(%ebp),%edi
40003924:	85 c0                	test   %eax,%eax
40003926:	89 55 f0             	mov    %edx,-0x10(%ebp)
40003929:	75 35                	jne    40003960 <__udivdi3+0x50>
4000392b:	39 fe                	cmp    %edi,%esi
4000392d:	77 61                	ja     40003990 <__udivdi3+0x80>
4000392f:	85 f6                	test   %esi,%esi
40003931:	75 0b                	jne    4000393e <__udivdi3+0x2e>
40003933:	b8 01 00 00 00       	mov    $0x1,%eax
40003938:	31 d2                	xor    %edx,%edx
4000393a:	f7 f6                	div    %esi
4000393c:	89 c6                	mov    %eax,%esi
4000393e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
40003941:	31 d2                	xor    %edx,%edx
40003943:	89 f8                	mov    %edi,%eax
40003945:	f7 f6                	div    %esi
40003947:	89 c7                	mov    %eax,%edi
40003949:	89 c8                	mov    %ecx,%eax
4000394b:	f7 f6                	div    %esi
4000394d:	89 c1                	mov    %eax,%ecx
4000394f:	89 fa                	mov    %edi,%edx
40003951:	89 c8                	mov    %ecx,%eax
40003953:	83 c4 10             	add    $0x10,%esp
40003956:	5e                   	pop    %esi
40003957:	5f                   	pop    %edi
40003958:	5d                   	pop    %ebp
40003959:	c3                   	ret    
4000395a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
40003960:	39 f8                	cmp    %edi,%eax
40003962:	77 1c                	ja     40003980 <__udivdi3+0x70>
40003964:	0f bd d0             	bsr    %eax,%edx
40003967:	83 f2 1f             	xor    $0x1f,%edx
4000396a:	89 55 f4             	mov    %edx,-0xc(%ebp)
4000396d:	75 39                	jne    400039a8 <__udivdi3+0x98>
4000396f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
40003972:	0f 86 a0 00 00 00    	jbe    40003a18 <__udivdi3+0x108>
40003978:	39 f8                	cmp    %edi,%eax
4000397a:	0f 82 98 00 00 00    	jb     40003a18 <__udivdi3+0x108>
40003980:	31 ff                	xor    %edi,%edi
40003982:	31 c9                	xor    %ecx,%ecx
40003984:	89 c8                	mov    %ecx,%eax
40003986:	89 fa                	mov    %edi,%edx
40003988:	83 c4 10             	add    $0x10,%esp
4000398b:	5e                   	pop    %esi
4000398c:	5f                   	pop    %edi
4000398d:	5d                   	pop    %ebp
4000398e:	c3                   	ret    
4000398f:	90                   	nop
40003990:	89 d1                	mov    %edx,%ecx
40003992:	89 fa                	mov    %edi,%edx
40003994:	89 c8                	mov    %ecx,%eax
40003996:	31 ff                	xor    %edi,%edi
40003998:	f7 f6                	div    %esi
4000399a:	89 c1                	mov    %eax,%ecx
4000399c:	89 fa                	mov    %edi,%edx
4000399e:	89 c8                	mov    %ecx,%eax
400039a0:	83 c4 10             	add    $0x10,%esp
400039a3:	5e                   	pop    %esi
400039a4:	5f                   	pop    %edi
400039a5:	5d                   	pop    %ebp
400039a6:	c3                   	ret    
400039a7:	90                   	nop
400039a8:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
400039ac:	89 f2                	mov    %esi,%edx
400039ae:	d3 e0                	shl    %cl,%eax
400039b0:	89 45 ec             	mov    %eax,-0x14(%ebp)
400039b3:	b8 20 00 00 00       	mov    $0x20,%eax
400039b8:	2b 45 f4             	sub    -0xc(%ebp),%eax
400039bb:	89 c1                	mov    %eax,%ecx
400039bd:	d3 ea                	shr    %cl,%edx
400039bf:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
400039c3:	0b 55 ec             	or     -0x14(%ebp),%edx
400039c6:	d3 e6                	shl    %cl,%esi
400039c8:	89 c1                	mov    %eax,%ecx
400039ca:	89 75 e8             	mov    %esi,-0x18(%ebp)
400039cd:	89 fe                	mov    %edi,%esi
400039cf:	d3 ee                	shr    %cl,%esi
400039d1:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
400039d5:	89 55 ec             	mov    %edx,-0x14(%ebp)
400039d8:	8b 55 f0             	mov    -0x10(%ebp),%edx
400039db:	d3 e7                	shl    %cl,%edi
400039dd:	89 c1                	mov    %eax,%ecx
400039df:	d3 ea                	shr    %cl,%edx
400039e1:	09 d7                	or     %edx,%edi
400039e3:	89 f2                	mov    %esi,%edx
400039e5:	89 f8                	mov    %edi,%eax
400039e7:	f7 75 ec             	divl   -0x14(%ebp)
400039ea:	89 d6                	mov    %edx,%esi
400039ec:	89 c7                	mov    %eax,%edi
400039ee:	f7 65 e8             	mull   -0x18(%ebp)
400039f1:	39 d6                	cmp    %edx,%esi
400039f3:	89 55 ec             	mov    %edx,-0x14(%ebp)
400039f6:	72 30                	jb     40003a28 <__udivdi3+0x118>
400039f8:	8b 55 f0             	mov    -0x10(%ebp),%edx
400039fb:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
400039ff:	d3 e2                	shl    %cl,%edx
40003a01:	39 c2                	cmp    %eax,%edx
40003a03:	73 05                	jae    40003a0a <__udivdi3+0xfa>
40003a05:	3b 75 ec             	cmp    -0x14(%ebp),%esi
40003a08:	74 1e                	je     40003a28 <__udivdi3+0x118>
40003a0a:	89 f9                	mov    %edi,%ecx
40003a0c:	31 ff                	xor    %edi,%edi
40003a0e:	e9 71 ff ff ff       	jmp    40003984 <__udivdi3+0x74>
40003a13:	90                   	nop
40003a14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003a18:	31 ff                	xor    %edi,%edi
40003a1a:	b9 01 00 00 00       	mov    $0x1,%ecx
40003a1f:	e9 60 ff ff ff       	jmp    40003984 <__udivdi3+0x74>
40003a24:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003a28:	8d 4f ff             	lea    -0x1(%edi),%ecx
40003a2b:	31 ff                	xor    %edi,%edi
40003a2d:	89 c8                	mov    %ecx,%eax
40003a2f:	89 fa                	mov    %edi,%edx
40003a31:	83 c4 10             	add    $0x10,%esp
40003a34:	5e                   	pop    %esi
40003a35:	5f                   	pop    %edi
40003a36:	5d                   	pop    %ebp
40003a37:	c3                   	ret    
40003a38:	90                   	nop
40003a39:	90                   	nop
40003a3a:	90                   	nop
40003a3b:	90                   	nop
40003a3c:	90                   	nop
40003a3d:	90                   	nop
40003a3e:	90                   	nop
40003a3f:	90                   	nop

40003a40 <__umoddi3>:
40003a40:	55                   	push   %ebp
40003a41:	89 e5                	mov    %esp,%ebp
40003a43:	57                   	push   %edi
40003a44:	56                   	push   %esi
40003a45:	83 ec 20             	sub    $0x20,%esp
40003a48:	8b 55 14             	mov    0x14(%ebp),%edx
40003a4b:	8b 4d 08             	mov    0x8(%ebp),%ecx
40003a4e:	8b 7d 10             	mov    0x10(%ebp),%edi
40003a51:	8b 75 0c             	mov    0xc(%ebp),%esi
40003a54:	85 d2                	test   %edx,%edx
40003a56:	89 c8                	mov    %ecx,%eax
40003a58:	89 4d f4             	mov    %ecx,-0xc(%ebp)
40003a5b:	75 13                	jne    40003a70 <__umoddi3+0x30>
40003a5d:	39 f7                	cmp    %esi,%edi
40003a5f:	76 3f                	jbe    40003aa0 <__umoddi3+0x60>
40003a61:	89 f2                	mov    %esi,%edx
40003a63:	f7 f7                	div    %edi
40003a65:	89 d0                	mov    %edx,%eax
40003a67:	31 d2                	xor    %edx,%edx
40003a69:	83 c4 20             	add    $0x20,%esp
40003a6c:	5e                   	pop    %esi
40003a6d:	5f                   	pop    %edi
40003a6e:	5d                   	pop    %ebp
40003a6f:	c3                   	ret    
40003a70:	39 f2                	cmp    %esi,%edx
40003a72:	77 4c                	ja     40003ac0 <__umoddi3+0x80>
40003a74:	0f bd ca             	bsr    %edx,%ecx
40003a77:	83 f1 1f             	xor    $0x1f,%ecx
40003a7a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
40003a7d:	75 51                	jne    40003ad0 <__umoddi3+0x90>
40003a7f:	3b 7d f4             	cmp    -0xc(%ebp),%edi
40003a82:	0f 87 e0 00 00 00    	ja     40003b68 <__umoddi3+0x128>
40003a88:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a8b:	29 f8                	sub    %edi,%eax
40003a8d:	19 d6                	sbb    %edx,%esi
40003a8f:	89 45 f4             	mov    %eax,-0xc(%ebp)
40003a92:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003a95:	89 f2                	mov    %esi,%edx
40003a97:	83 c4 20             	add    $0x20,%esp
40003a9a:	5e                   	pop    %esi
40003a9b:	5f                   	pop    %edi
40003a9c:	5d                   	pop    %ebp
40003a9d:	c3                   	ret    
40003a9e:	66 90                	xchg   %ax,%ax
40003aa0:	85 ff                	test   %edi,%edi
40003aa2:	75 0b                	jne    40003aaf <__umoddi3+0x6f>
40003aa4:	b8 01 00 00 00       	mov    $0x1,%eax
40003aa9:	31 d2                	xor    %edx,%edx
40003aab:	f7 f7                	div    %edi
40003aad:	89 c7                	mov    %eax,%edi
40003aaf:	89 f0                	mov    %esi,%eax
40003ab1:	31 d2                	xor    %edx,%edx
40003ab3:	f7 f7                	div    %edi
40003ab5:	8b 45 f4             	mov    -0xc(%ebp),%eax
40003ab8:	f7 f7                	div    %edi
40003aba:	eb a9                	jmp    40003a65 <__umoddi3+0x25>
40003abc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003ac0:	89 c8                	mov    %ecx,%eax
40003ac2:	89 f2                	mov    %esi,%edx
40003ac4:	83 c4 20             	add    $0x20,%esp
40003ac7:	5e                   	pop    %esi
40003ac8:	5f                   	pop    %edi
40003ac9:	5d                   	pop    %ebp
40003aca:	c3                   	ret    
40003acb:	90                   	nop
40003acc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003ad0:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003ad4:	d3 e2                	shl    %cl,%edx
40003ad6:	89 55 f4             	mov    %edx,-0xc(%ebp)
40003ad9:	ba 20 00 00 00       	mov    $0x20,%edx
40003ade:	2b 55 f0             	sub    -0x10(%ebp),%edx
40003ae1:	89 55 ec             	mov    %edx,-0x14(%ebp)
40003ae4:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
40003ae8:	89 fa                	mov    %edi,%edx
40003aea:	d3 ea                	shr    %cl,%edx
40003aec:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003af0:	0b 55 f4             	or     -0xc(%ebp),%edx
40003af3:	d3 e7                	shl    %cl,%edi
40003af5:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
40003af9:	89 55 f4             	mov    %edx,-0xc(%ebp)
40003afc:	89 f2                	mov    %esi,%edx
40003afe:	89 7d e8             	mov    %edi,-0x18(%ebp)
40003b01:	89 c7                	mov    %eax,%edi
40003b03:	d3 ea                	shr    %cl,%edx
40003b05:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003b09:	89 55 e4             	mov    %edx,-0x1c(%ebp)
40003b0c:	89 c2                	mov    %eax,%edx
40003b0e:	d3 e6                	shl    %cl,%esi
40003b10:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
40003b14:	d3 ea                	shr    %cl,%edx
40003b16:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003b1a:	09 d6                	or     %edx,%esi
40003b1c:	89 f0                	mov    %esi,%eax
40003b1e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
40003b21:	d3 e7                	shl    %cl,%edi
40003b23:	89 f2                	mov    %esi,%edx
40003b25:	f7 75 f4             	divl   -0xc(%ebp)
40003b28:	89 d6                	mov    %edx,%esi
40003b2a:	f7 65 e8             	mull   -0x18(%ebp)
40003b2d:	39 d6                	cmp    %edx,%esi
40003b2f:	72 2b                	jb     40003b5c <__umoddi3+0x11c>
40003b31:	39 c7                	cmp    %eax,%edi
40003b33:	72 23                	jb     40003b58 <__umoddi3+0x118>
40003b35:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003b39:	29 c7                	sub    %eax,%edi
40003b3b:	19 d6                	sbb    %edx,%esi
40003b3d:	89 f0                	mov    %esi,%eax
40003b3f:	89 f2                	mov    %esi,%edx
40003b41:	d3 ef                	shr    %cl,%edi
40003b43:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
40003b47:	d3 e0                	shl    %cl,%eax
40003b49:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
40003b4d:	09 f8                	or     %edi,%eax
40003b4f:	d3 ea                	shr    %cl,%edx
40003b51:	83 c4 20             	add    $0x20,%esp
40003b54:	5e                   	pop    %esi
40003b55:	5f                   	pop    %edi
40003b56:	5d                   	pop    %ebp
40003b57:	c3                   	ret    
40003b58:	39 d6                	cmp    %edx,%esi
40003b5a:	75 d9                	jne    40003b35 <__umoddi3+0xf5>
40003b5c:	2b 45 e8             	sub    -0x18(%ebp),%eax
40003b5f:	1b 55 f4             	sbb    -0xc(%ebp),%edx
40003b62:	eb d1                	jmp    40003b35 <__umoddi3+0xf5>
40003b64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
40003b68:	39 f2                	cmp    %esi,%edx
40003b6a:	0f 82 18 ff ff ff    	jb     40003a88 <__umoddi3+0x48>
40003b70:	e9 1d ff ff ff       	jmp    40003a92 <__umoddi3+0x52>
