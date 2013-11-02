
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

00100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		start,_start
start: _start:
	movw	$0x1234,0x472			# warm boot BIOS flag
  100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
  100006:	00 00                	add    %al,(%eax)
  100008:	fb                   	sti    
  100009:	4f                   	dec    %edi
  10000a:	52                   	push   %edx
  10000b:	e4 66                	in     $0x66,%al

0010000c <_start>:
  10000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
  100013:	34 12 

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
  100015:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Leave a few words on the stack for the user trap frame
	movl	$(cpu_boot+4096-SIZEOF_STRUCT_TRAPFRAME),%esp
  10001a:	bc b4 bf 10 00       	mov    $0x10bfb4,%esp

	# now to C code
	call	init
  10001f:	e8 6f 00 00 00       	call   100093 <init>

00100024 <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
  100024:	eb fe                	jmp    100024 <spin>
  100026:	90                   	nop
  100027:	90                   	nop

00100028 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100028:	55                   	push   %ebp
  100029:	89 e5                	mov    %esp,%ebp
  10002b:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10002e:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100031:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100034:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100037:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10003a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10003f:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  100042:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100045:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  10004b:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  100050:	74 24                	je     100076 <cpu_cur+0x4e>
  100052:	c7 44 24 0c e0 82 10 	movl   $0x1082e0,0xc(%esp)
  100059:	00 
  10005a:	c7 44 24 08 f6 82 10 	movl   $0x1082f6,0x8(%esp)
  100061:	00 
  100062:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100069:	00 
  10006a:	c7 04 24 0b 83 10 00 	movl   $0x10830b,(%esp)
  100071:	e8 42 04 00 00       	call   1004b8 <debug_panic>
	return c;
  100076:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100079:	c9                   	leave  
  10007a:	c3                   	ret    

0010007b <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  10007b:	55                   	push   %ebp
  10007c:	89 e5                	mov    %esp,%ebp
  10007e:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  100081:	e8 a2 ff ff ff       	call   100028 <cpu_cur>
  100086:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  10008b:	0f 94 c0             	sete   %al
  10008e:	0f b6 c0             	movzbl %al,%eax
}
  100091:	c9                   	leave  
  100092:	c3                   	ret    

00100093 <init>:
// Called first from entry.S on the bootstrap processor,
// and later from boot/bootother.S on all other processors.
// As a rule, "init" functions in PIOS are called once on EACH processor.
void
init(void)
{
  100093:	55                   	push   %ebp
  100094:	89 e5                	mov    %esp,%ebp
  100096:	53                   	push   %ebx
  100097:	83 ec 14             	sub    $0x14,%esp
	extern char start[], edata[], end[];

	// Before anything else, complete the ELF loading process.
	// Clear all uninitialized global data (BSS) in our program,
	// ensuring that all static/global variables start out zero.
	if (cpu_onboot())
  10009a:	e8 dc ff ff ff       	call   10007b <cpu_onboot>
  10009f:	85 c0                	test   %eax,%eax
  1000a1:	74 28                	je     1000cb <init+0x38>
		memset(edata, 0, end - edata);
  1000a3:	ba 08 20 12 00       	mov    $0x122008,%edx
  1000a8:	b8 16 84 11 00       	mov    $0x118416,%eax
  1000ad:	89 d1                	mov    %edx,%ecx
  1000af:	29 c1                	sub    %eax,%ecx
  1000b1:	89 c8                	mov    %ecx,%eax
  1000b3:	89 44 24 08          	mov    %eax,0x8(%esp)
  1000b7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1000be:	00 
  1000bf:	c7 04 24 16 84 11 00 	movl   $0x118416,(%esp)
  1000c6:	e8 99 7d 00 00       	call   107e64 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
  1000cb:	e8 f9 02 00 00       	call   1003c9 <cons_init>

	// Initialize and load the bootstrap CPU's GDT, TSS, and IDT.
	cpu_init();
  1000d0:	e8 94 11 00 00       	call   101269 <cpu_init>
	trap_init();
  1000d5:	e8 22 20 00 00       	call   1020fc <trap_init>

	// Physical memory detection/initialization.
	// Can't call mem_alloc until after we do this!
	mem_init();
  1000da:	e8 80 08 00 00       	call   10095f <mem_init>

	// Lab 2: check spinlock implementation
	if (cpu_onboot())
  1000df:	e8 97 ff ff ff       	call   10007b <cpu_onboot>
  1000e4:	85 c0                	test   %eax,%eax
  1000e6:	74 05                	je     1000ed <init+0x5a>
		spinlock_check();
  1000e8:	e8 e2 2d 00 00       	call   102ecf <spinlock_check>

	// Initialize the paged virtual memory system.
	pmap_init();
  1000ed:	e8 1a 45 00 00       	call   10460c <pmap_init>

	// Find and start other processors in a multiprocessor system
	mp_init();		// Find info about processors in system
  1000f2:	e8 4f 2a 00 00       	call   102b46 <mp_init>
	pic_init();		// setup the legacy PIC (mainly to disable it)
  1000f7:	e8 6c 6c 00 00       	call   106d68 <pic_init>
	ioapic_init();		// prepare to handle external device interrupts
  1000fc:	e8 9c 72 00 00       	call   10739d <ioapic_init>
	lapic_init();		// setup this CPU's local APIC
  100101:	e8 47 6f 00 00       	call   10704d <lapic_init>

	cpu_bootothers();	// Get other processors started
  100106:	e8 47 13 00 00       	call   101452 <cpu_bootothers>
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
		cpu_onboot() ? "BP" : "AP");
  10010b:	e8 6b ff ff ff       	call   10007b <cpu_onboot>
	pic_init();		// setup the legacy PIC (mainly to disable it)
	ioapic_init();		// prepare to handle external device interrupts
	lapic_init();		// setup this CPU's local APIC

	cpu_bootothers();	// Get other processors started
	cprintf("CPU %d (%s) has booted\n", cpu_cur()->id,
  100110:	85 c0                	test   %eax,%eax
  100112:	74 07                	je     10011b <init+0x88>
  100114:	bb 18 83 10 00       	mov    $0x108318,%ebx
  100119:	eb 05                	jmp    100120 <init+0x8d>
  10011b:	bb 1b 83 10 00       	mov    $0x10831b,%ebx
  100120:	e8 03 ff ff ff       	call   100028 <cpu_cur>
  100125:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  10012c:	0f b6 c0             	movzbl %al,%eax
  10012f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  100133:	89 44 24 04          	mov    %eax,0x4(%esp)
  100137:	c7 04 24 1e 83 10 00 	movl   $0x10831e,(%esp)
  10013e:	e8 3a 7b 00 00       	call   107c7d <cprintf>
		cpu_onboot() ? "BP" : "AP");

	proc_init();
  100143:	e8 45 33 00 00       	call   10348d <proc_init>

	if(cpu_cur()->id == 0) {
  100148:	e8 db fe ff ff       	call   100028 <cpu_cur>
  10014d:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  100154:	84 c0                	test   %al,%al
  100156:	0f 85 93 00 00 00    	jne    1001ef <init+0x15c>
		// Initialize the process management code.
		proc_root = proc_alloc(NULL, 0);
  10015c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  100163:	00 
  100164:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10016b:	e8 61 33 00 00       	call   1034d1 <proc_alloc>
  100170:	a3 f0 f3 11 00       	mov    %eax,0x11f3f0
		user_stack[sizeof(user_stack)-1] = 0;
  100175:	c6 05 ff 9f 11 00 00 	movb   $0x0,0x119fff
		user_stack[sizeof(user_stack)-2] = 0;
  10017c:	c6 05 fe 9f 11 00 00 	movb   $0x0,0x119ffe
		user_stack[sizeof(user_stack)-3] = 0;
  100183:	c6 05 fd 9f 11 00 00 	movb   $0x0,0x119ffd
		user_stack[sizeof(user_stack)-4] = 0;
  10018a:	c6 05 fc 9f 11 00 00 	movb   $0x0,0x119ffc
		proc_root->sv.tf.esp = ((uintptr_t)user_stack)+sizeof(user_stack)-4;
  100191:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  100196:	ba 00 90 11 00       	mov    $0x119000,%edx
  10019b:	81 c2 fc 0f 00 00    	add    $0xffc,%edx
  1001a1:	89 90 94 04 00 00    	mov    %edx,0x494(%eax)
		proc_root->sv.tf.ss = CPU_GDT_UDATA | 0x3;
  1001a7:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  1001ac:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  1001b3:	23 00 
		proc_root->sv.tf.eflags = (FL_IOPL_MASK & FL_IOPL_3);
  1001b5:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  1001ba:	c7 80 90 04 00 00 00 	movl   $0x3000,0x490(%eax)
  1001c1:	30 00 00 
		proc_root->sv.tf.eip = (uintptr_t)(&user);
  1001c4:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  1001c9:	ba f9 01 10 00       	mov    $0x1001f9,%edx
  1001ce:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
		proc_root->sv.tf.cs = CPU_GDT_UCODE | 0x3;
  1001d4:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  1001d9:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  1001e0:	1b 00 
		proc_ready(proc_root);
  1001e2:	a1 f0 f3 11 00       	mov    0x11f3f0,%eax
  1001e7:	89 04 24             	mov    %eax,(%esp)
  1001ea:	e8 b6 34 00 00       	call   1036a5 <proc_ready>
	}

	lapic_eoi();
  1001ef:	e8 f1 6f 00 00       	call   1071e5 <lapic_eoi>
	proc_sched();
  1001f4:	e8 3c 36 00 00       	call   103835 <proc_sched>

001001f9 <user>:
// This is the first function that gets run in user mode (ring 3).
// It acts as PIOS's "root process",
// of which all other processes are descendants.
void
user()
{
  1001f9:	55                   	push   %ebp
  1001fa:	89 e5                	mov    %esp,%ebp
  1001fc:	83 ec 28             	sub    $0x28,%esp
	assert(0 == 0);
	cprintf("in user()\n");
  1001ff:	c7 04 24 36 83 10 00 	movl   $0x108336,(%esp)
  100206:	e8 72 7a 00 00       	call   107c7d <cprintf>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10020b:	89 65 f0             	mov    %esp,-0x10(%ebp)
        return esp;
  10020e:	8b 45 f0             	mov    -0x10(%ebp),%eax
	assert(read_esp() > (uint32_t) &user_stack[0]);
  100211:	89 c2                	mov    %eax,%edx
  100213:	b8 00 90 11 00       	mov    $0x119000,%eax
  100218:	39 c2                	cmp    %eax,%edx
  10021a:	77 24                	ja     100240 <user+0x47>
  10021c:	c7 44 24 0c 44 83 10 	movl   $0x108344,0xc(%esp)
  100223:	00 
  100224:	c7 44 24 08 f6 82 10 	movl   $0x1082f6,0x8(%esp)
  10022b:	00 
  10022c:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
  100233:	00 
  100234:	c7 04 24 6b 83 10 00 	movl   $0x10836b,(%esp)
  10023b:	e8 78 02 00 00       	call   1004b8 <debug_panic>

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100240:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100243:	8b 45 f4             	mov    -0xc(%ebp),%eax
	assert(read_esp() < (uint32_t) &user_stack[sizeof(user_stack)]);
  100246:	89 c2                	mov    %eax,%edx
  100248:	b8 00 a0 11 00       	mov    $0x11a000,%eax
  10024d:	39 c2                	cmp    %eax,%edx
  10024f:	72 24                	jb     100275 <user+0x7c>
  100251:	c7 44 24 0c 78 83 10 	movl   $0x108378,0xc(%esp)
  100258:	00 
  100259:	c7 44 24 08 f6 82 10 	movl   $0x1082f6,0x8(%esp)
  100260:	00 
  100261:	c7 44 24 04 7d 00 00 	movl   $0x7d,0x4(%esp)
  100268:	00 
  100269:	c7 04 24 6b 83 10 00 	movl   $0x10836b,(%esp)
  100270:	e8 43 02 00 00       	call   1004b8 <debug_panic>


	done();
  100275:	e8 00 00 00 00       	call   10027a <done>

0010027a <done>:
// it just puts the processor into an infinite loop.
// We make this a function so that we can set a breakpoints on it.
// Our grade scripts use this breakpoint to know when to stop QEMU.
void gcc_noreturn
done()
{
  10027a:	55                   	push   %ebp
  10027b:	89 e5                	mov    %esp,%ebp
	while (1)
		;	// just spin
  10027d:	eb fe                	jmp    10027d <done+0x3>
  10027f:	90                   	nop

00100280 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  100280:	55                   	push   %ebp
  100281:	89 e5                	mov    %esp,%ebp
  100283:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  100286:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  100289:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10028c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10028f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100292:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100297:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10029a:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10029d:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1002a3:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1002a8:	74 24                	je     1002ce <cpu_cur+0x4e>
  1002aa:	c7 44 24 0c b0 83 10 	movl   $0x1083b0,0xc(%esp)
  1002b1:	00 
  1002b2:	c7 44 24 08 c6 83 10 	movl   $0x1083c6,0x8(%esp)
  1002b9:	00 
  1002ba:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1002c1:	00 
  1002c2:	c7 04 24 db 83 10 00 	movl   $0x1083db,(%esp)
  1002c9:	e8 ea 01 00 00       	call   1004b8 <debug_panic>
	return c;
  1002ce:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1002d1:	c9                   	leave  
  1002d2:	c3                   	ret    

001002d3 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1002d3:	55                   	push   %ebp
  1002d4:	89 e5                	mov    %esp,%ebp
  1002d6:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1002d9:	e8 a2 ff ff ff       	call   100280 <cpu_cur>
  1002de:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  1002e3:	0f 94 c0             	sete   %al
  1002e6:	0f b6 c0             	movzbl %al,%eax
}
  1002e9:	c9                   	leave  
  1002ea:	c3                   	ret    

001002eb <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
  1002eb:	55                   	push   %ebp
  1002ec:	89 e5                	mov    %esp,%ebp
  1002ee:	83 ec 28             	sub    $0x28,%esp
	int c;

	spinlock_acquire(&cons_lock);
  1002f1:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  1002f8:	e8 82 2a 00 00       	call   102d7f <spinlock_acquire>
	while ((c = (*proc)()) != -1) {
  1002fd:	eb 35                	jmp    100334 <cons_intr+0x49>
		if (c == 0)
  1002ff:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  100303:	74 2e                	je     100333 <cons_intr+0x48>
			continue;
		cons.buf[cons.wpos++] = c;
  100305:	a1 04 a2 11 00       	mov    0x11a204,%eax
  10030a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10030d:	88 90 00 a0 11 00    	mov    %dl,0x11a000(%eax)
  100313:	83 c0 01             	add    $0x1,%eax
  100316:	a3 04 a2 11 00       	mov    %eax,0x11a204
		if (cons.wpos == CONSBUFSIZE)
  10031b:	a1 04 a2 11 00       	mov    0x11a204,%eax
  100320:	3d 00 02 00 00       	cmp    $0x200,%eax
  100325:	75 0d                	jne    100334 <cons_intr+0x49>
			cons.wpos = 0;
  100327:	c7 05 04 a2 11 00 00 	movl   $0x0,0x11a204
  10032e:	00 00 00 
  100331:	eb 01                	jmp    100334 <cons_intr+0x49>
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
		if (c == 0)
			continue;
  100333:	90                   	nop
cons_intr(int (*proc)(void))
{
	int c;

	spinlock_acquire(&cons_lock);
	while ((c = (*proc)()) != -1) {
  100334:	8b 45 08             	mov    0x8(%ebp),%eax
  100337:	ff d0                	call   *%eax
  100339:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10033c:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
  100340:	75 bd                	jne    1002ff <cons_intr+0x14>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
	spinlock_release(&cons_lock);
  100342:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  100349:	e8 a6 2a 00 00       	call   102df4 <spinlock_release>

}
  10034e:	c9                   	leave  
  10034f:	c3                   	ret    

00100350 <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
  100350:	55                   	push   %ebp
  100351:	89 e5                	mov    %esp,%ebp
  100353:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
  100356:	e8 bd 68 00 00       	call   106c18 <serial_intr>
	kbd_intr();
  10035b:	e8 12 68 00 00       	call   106b72 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
  100360:	8b 15 00 a2 11 00    	mov    0x11a200,%edx
  100366:	a1 04 a2 11 00       	mov    0x11a204,%eax
  10036b:	39 c2                	cmp    %eax,%edx
  10036d:	74 35                	je     1003a4 <cons_getc+0x54>
		c = cons.buf[cons.rpos++];
  10036f:	a1 00 a2 11 00       	mov    0x11a200,%eax
  100374:	0f b6 90 00 a0 11 00 	movzbl 0x11a000(%eax),%edx
  10037b:	0f b6 d2             	movzbl %dl,%edx
  10037e:	89 55 f4             	mov    %edx,-0xc(%ebp)
  100381:	83 c0 01             	add    $0x1,%eax
  100384:	a3 00 a2 11 00       	mov    %eax,0x11a200
		if (cons.rpos == CONSBUFSIZE)
  100389:	a1 00 a2 11 00       	mov    0x11a200,%eax
  10038e:	3d 00 02 00 00       	cmp    $0x200,%eax
  100393:	75 0a                	jne    10039f <cons_getc+0x4f>
			cons.rpos = 0;
  100395:	c7 05 00 a2 11 00 00 	movl   $0x0,0x11a200
  10039c:	00 00 00 
		return c;
  10039f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1003a2:	eb 05                	jmp    1003a9 <cons_getc+0x59>
	}
	return 0;
  1003a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1003a9:	c9                   	leave  
  1003aa:	c3                   	ret    

001003ab <cons_putc>:

// output a character to the console
static void
cons_putc(int c)
{
  1003ab:	55                   	push   %ebp
  1003ac:	89 e5                	mov    %esp,%ebp
  1003ae:	83 ec 18             	sub    $0x18,%esp
	serial_putc(c);
  1003b1:	8b 45 08             	mov    0x8(%ebp),%eax
  1003b4:	89 04 24             	mov    %eax,(%esp)
  1003b7:	e8 79 68 00 00       	call   106c35 <serial_putc>
	video_putc(c);
  1003bc:	8b 45 08             	mov    0x8(%ebp),%eax
  1003bf:	89 04 24             	mov    %eax,(%esp)
  1003c2:	e8 09 64 00 00       	call   1067d0 <video_putc>
}
  1003c7:	c9                   	leave  
  1003c8:	c3                   	ret    

001003c9 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
  1003c9:	55                   	push   %ebp
  1003ca:	89 e5                	mov    %esp,%ebp
  1003cc:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  1003cf:	e8 ff fe ff ff       	call   1002d3 <cpu_onboot>
  1003d4:	85 c0                	test   %eax,%eax
  1003d6:	74 52                	je     10042a <cons_init+0x61>
		return;

	spinlock_init(&cons_lock);
  1003d8:	c7 44 24 08 6a 00 00 	movl   $0x6a,0x8(%esp)
  1003df:	00 
  1003e0:	c7 44 24 04 e8 83 10 	movl   $0x1083e8,0x4(%esp)
  1003e7:	00 
  1003e8:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  1003ef:	e8 54 29 00 00       	call   102d48 <spinlock_init_>
	video_init();
  1003f4:	e8 0b 63 00 00       	call   106704 <video_init>
	kbd_init();
  1003f9:	e8 88 67 00 00       	call   106b86 <kbd_init>
	serial_init();
  1003fe:	e8 97 68 00 00       	call   106c9a <serial_init>

	if (!serial_exists)
  100403:	a1 00 20 12 00       	mov    0x122000,%eax
  100408:	85 c0                	test   %eax,%eax
  10040a:	75 1f                	jne    10042b <cons_init+0x62>
		warn("Serial port does not exist!\n");
  10040c:	c7 44 24 08 f4 83 10 	movl   $0x1083f4,0x8(%esp)
  100413:	00 
  100414:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  10041b:	00 
  10041c:	c7 04 24 e8 83 10 00 	movl   $0x1083e8,(%esp)
  100423:	e8 4f 01 00 00       	call   100577 <debug_warn>
  100428:	eb 01                	jmp    10042b <cons_init+0x62>
// initialize the console devices
void
cons_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  10042a:	90                   	nop
	kbd_init();
	serial_init();

	if (!serial_exists)
		warn("Serial port does not exist!\n");
}
  10042b:	c9                   	leave  
  10042c:	c3                   	ret    

0010042d <cputs>:


// `High'-level console I/O.  Used by readline and cprintf.
void
cputs(const char *str)
{
  10042d:	55                   	push   %ebp
  10042e:	89 e5                	mov    %esp,%ebp
  100430:	53                   	push   %ebx
  100431:	83 ec 24             	sub    $0x24,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  100434:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  100437:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	if (read_cs() & 3)
  10043b:	0f b7 c0             	movzwl %ax,%eax
  10043e:	83 e0 03             	and    $0x3,%eax
  100441:	85 c0                	test   %eax,%eax
  100443:	74 14                	je     100459 <cputs+0x2c>
  100445:	8b 45 08             	mov    0x8(%ebp),%eax
  100448:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// 
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %0" :
  10044b:	b8 00 00 00 00       	mov    $0x0,%eax
  100450:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100453:	89 d3                	mov    %edx,%ebx
  100455:	cd 30                	int    $0x30
		return sys_cputs(str);	// use syscall from user mode
  100457:	eb 57                	jmp    1004b0 <cputs+0x83>

	// Hold the console spinlock while printing the entire string,
	// so that the output of different cputs calls won't get mixed.
	// Implement ad hoc recursive locking for debugging convenience.
	bool already = spinlock_holding(&cons_lock);
  100459:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  100460:	e8 fd 29 00 00       	call   102e62 <spinlock_holding>
  100465:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!already)
  100468:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  10046c:	75 25                	jne    100493 <cputs+0x66>
		spinlock_acquire(&cons_lock);
  10046e:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  100475:	e8 05 29 00 00       	call   102d7f <spinlock_acquire>

	char ch;
	while (*str)
  10047a:	eb 18                	jmp    100494 <cputs+0x67>
		cons_putc(*str++);
  10047c:	8b 45 08             	mov    0x8(%ebp),%eax
  10047f:	0f b6 00             	movzbl (%eax),%eax
  100482:	0f be c0             	movsbl %al,%eax
  100485:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  100489:	89 04 24             	mov    %eax,(%esp)
  10048c:	e8 1a ff ff ff       	call   1003ab <cons_putc>
  100491:	eb 01                	jmp    100494 <cputs+0x67>
	bool already = spinlock_holding(&cons_lock);
	if (!already)
		spinlock_acquire(&cons_lock);

	char ch;
	while (*str)
  100493:	90                   	nop
  100494:	8b 45 08             	mov    0x8(%ebp),%eax
  100497:	0f b6 00             	movzbl (%eax),%eax
  10049a:	84 c0                	test   %al,%al
  10049c:	75 de                	jne    10047c <cputs+0x4f>
		cons_putc(*str++);

	if (!already)
  10049e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1004a2:	75 0c                	jne    1004b0 <cputs+0x83>
		spinlock_release(&cons_lock);
  1004a4:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  1004ab:	e8 44 29 00 00       	call   102df4 <spinlock_release>
}
  1004b0:	83 c4 24             	add    $0x24,%esp
  1004b3:	5b                   	pop    %ebx
  1004b4:	5d                   	pop    %ebp
  1004b5:	c3                   	ret    
  1004b6:	90                   	nop
  1004b7:	90                   	nop

001004b8 <debug_panic>:

// Panic is called on unresolvable fatal errors.
// It prints "panic: mesg", and then enters the kernel monitor.
void
debug_panic(const char *file, int line, const char *fmt,...)
{
  1004b8:	55                   	push   %ebp
  1004b9:	89 e5                	mov    %esp,%ebp
  1004bb:	83 ec 58             	sub    $0x58,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  1004be:	8c 4d f2             	mov    %cs,-0xe(%ebp)
        return cs;
  1004c1:	0f b7 45 f2          	movzwl -0xe(%ebp),%eax
	va_list ap;
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
  1004c5:	0f b7 c0             	movzwl %ax,%eax
  1004c8:	83 e0 03             	and    $0x3,%eax
  1004cb:	85 c0                	test   %eax,%eax
  1004cd:	75 15                	jne    1004e4 <debug_panic+0x2c>
		if (panicstr)
  1004cf:	a1 08 a2 11 00       	mov    0x11a208,%eax
  1004d4:	85 c0                	test   %eax,%eax
  1004d6:	0f 85 95 00 00 00    	jne    100571 <debug_panic+0xb9>
			goto dead;
		panicstr = fmt;
  1004dc:	8b 45 10             	mov    0x10(%ebp),%eax
  1004df:	a3 08 a2 11 00       	mov    %eax,0x11a208
	}

	// First print the requested message
	va_start(ap, fmt);
  1004e4:	8d 45 10             	lea    0x10(%ebp),%eax
  1004e7:	83 c0 04             	add    $0x4,%eax
  1004ea:	89 45 e8             	mov    %eax,-0x18(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
  1004ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  1004f0:	89 44 24 08          	mov    %eax,0x8(%esp)
  1004f4:	8b 45 08             	mov    0x8(%ebp),%eax
  1004f7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1004fb:	c7 04 24 11 84 10 00 	movl   $0x108411,(%esp)
  100502:	e8 76 77 00 00       	call   107c7d <cprintf>
	vcprintf(fmt, ap);
  100507:	8b 45 10             	mov    0x10(%ebp),%eax
  10050a:	8b 55 e8             	mov    -0x18(%ebp),%edx
  10050d:	89 54 24 04          	mov    %edx,0x4(%esp)
  100511:	89 04 24             	mov    %eax,(%esp)
  100514:	e8 fb 76 00 00       	call   107c14 <vcprintf>
	cprintf("\n");
  100519:	c7 04 24 29 84 10 00 	movl   $0x108429,(%esp)
  100520:	e8 58 77 00 00       	call   107c7d <cprintf>

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100525:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  100528:	8b 45 f4             	mov    -0xc(%ebp),%eax
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
  10052b:	8d 55 c0             	lea    -0x40(%ebp),%edx
  10052e:	89 54 24 04          	mov    %edx,0x4(%esp)
  100532:	89 04 24             	mov    %eax,(%esp)
  100535:	e8 86 00 00 00       	call   1005c0 <debug_trace>
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10053a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  100541:	eb 1b                	jmp    10055e <debug_panic+0xa6>
		cprintf("  from %08x\n", eips[i]);
  100543:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100546:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10054a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10054e:	c7 04 24 2b 84 10 00 	movl   $0x10842b,(%esp)
  100555:	e8 23 77 00 00       	call   107c7d <cprintf>
	va_end(ap);

	// Then print a backtrace of the kernel call chain
	uint32_t eips[DEBUG_TRACEFRAMES];
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
  10055a:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  10055e:	83 7d ec 09          	cmpl   $0x9,-0x14(%ebp)
  100562:	7f 0e                	jg     100572 <debug_panic+0xba>
  100564:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100567:	8b 44 85 c0          	mov    -0x40(%ebp,%eax,4),%eax
  10056b:	85 c0                	test   %eax,%eax
  10056d:	75 d4                	jne    100543 <debug_panic+0x8b>
  10056f:	eb 01                	jmp    100572 <debug_panic+0xba>
	int i;

	// Avoid infinite recursion if we're panicking from kernel mode.
	if ((read_cs() & 3) == 0) {
		if (panicstr)
			goto dead;
  100571:	90                   	nop
	debug_trace(read_ebp(), eips);
	for (i = 0; i < DEBUG_TRACEFRAMES && eips[i] != 0; i++)
		cprintf("  from %08x\n", eips[i]);

dead:
	done();		// enter infinite loop (see kern/init.c)
  100572:	e8 03 fd ff ff       	call   10027a <done>

00100577 <debug_warn>:
}

/* like panic, but don't */
void
debug_warn(const char *file, int line, const char *fmt,...)
{
  100577:	55                   	push   %ebp
  100578:	89 e5                	mov    %esp,%ebp
  10057a:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
  10057d:	8d 45 10             	lea    0x10(%ebp),%eax
  100580:	83 c0 04             	add    $0x4,%eax
  100583:	89 45 f4             	mov    %eax,-0xc(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
  100586:	8b 45 0c             	mov    0xc(%ebp),%eax
  100589:	89 44 24 08          	mov    %eax,0x8(%esp)
  10058d:	8b 45 08             	mov    0x8(%ebp),%eax
  100590:	89 44 24 04          	mov    %eax,0x4(%esp)
  100594:	c7 04 24 38 84 10 00 	movl   $0x108438,(%esp)
  10059b:	e8 dd 76 00 00       	call   107c7d <cprintf>
	vcprintf(fmt, ap);
  1005a0:	8b 45 10             	mov    0x10(%ebp),%eax
  1005a3:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1005a6:	89 54 24 04          	mov    %edx,0x4(%esp)
  1005aa:	89 04 24             	mov    %eax,(%esp)
  1005ad:	e8 62 76 00 00       	call   107c14 <vcprintf>
	cprintf("\n");
  1005b2:	c7 04 24 29 84 10 00 	movl   $0x108429,(%esp)
  1005b9:	e8 bf 76 00 00       	call   107c7d <cprintf>
	va_end(ap);
}
  1005be:	c9                   	leave  
  1005bf:	c3                   	ret    

001005c0 <debug_trace>:

// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
  1005c0:	55                   	push   %ebp
  1005c1:	89 e5                	mov    %esp,%ebp
  1005c3:	83 ec 10             	sub    $0x10,%esp
	int i = 0;
  1005c6:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
	for(; i < DEBUG_TRACEFRAMES && ebp; i++) {
  1005cd:	eb 25                	jmp    1005f4 <debug_trace+0x34>
		uint32_t eip = (*(uint32_t *)(ebp + 4));
  1005cf:	8b 45 08             	mov    0x8(%ebp),%eax
  1005d2:	83 c0 04             	add    $0x4,%eax
  1005d5:	8b 00                	mov    (%eax),%eax
  1005d7:	89 45 fc             	mov    %eax,-0x4(%ebp)
		eips[i] = eip;
  1005da:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1005dd:	c1 e0 02             	shl    $0x2,%eax
  1005e0:	03 45 0c             	add    0xc(%ebp),%eax
  1005e3:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1005e6:	89 10                	mov    %edx,(%eax)
				(*(uint32_t *)(ebp + 8)),
				(*(uint32_t *)(ebp + 12)),
				(*(uint32_t *)(ebp + 16)),
				(*(uint32_t *)(ebp + 20)),
				(*(uint32_t *)(ebp + 24))); */
		ebp = (*(uint32_t *)(ebp));
  1005e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1005eb:	8b 00                	mov    (%eax),%eax
  1005ed:	89 45 08             	mov    %eax,0x8(%ebp)
// Record the current call stack in eips[] by following the %ebp chain.
void gcc_noinline
debug_trace(uint32_t ebp, uint32_t eips[DEBUG_TRACEFRAMES])
{
	int i = 0;
	for(; i < DEBUG_TRACEFRAMES && ebp; i++) {
  1005f0:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  1005f4:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
  1005f8:	7f 1b                	jg     100615 <debug_trace+0x55>
  1005fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  1005fe:	75 cf                	jne    1005cf <debug_trace+0xf>
				(*(uint32_t *)(ebp + 16)),
				(*(uint32_t *)(ebp + 20)),
				(*(uint32_t *)(ebp + 24))); */
		ebp = (*(uint32_t *)(ebp));
	}
	for(; i < DEBUG_TRACEFRAMES; i++) { eips[i] = 0; }
  100600:	eb 13                	jmp    100615 <debug_trace+0x55>
  100602:	8b 45 f8             	mov    -0x8(%ebp),%eax
  100605:	c1 e0 02             	shl    $0x2,%eax
  100608:	03 45 0c             	add    0xc(%ebp),%eax
  10060b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  100611:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  100615:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
  100619:	7e e7                	jle    100602 <debug_trace+0x42>
}
  10061b:	c9                   	leave  
  10061c:	c3                   	ret    

0010061d <f3>:


static void gcc_noinline f3(int r, uint32_t *e) { debug_trace(read_ebp(), e); }
  10061d:	55                   	push   %ebp
  10061e:	89 e5                	mov    %esp,%ebp
  100620:	83 ec 18             	sub    $0x18,%esp

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  100623:	89 6d fc             	mov    %ebp,-0x4(%ebp)
        return ebp;
  100626:	8b 45 fc             	mov    -0x4(%ebp),%eax
  100629:	8b 55 0c             	mov    0xc(%ebp),%edx
  10062c:	89 54 24 04          	mov    %edx,0x4(%esp)
  100630:	89 04 24             	mov    %eax,(%esp)
  100633:	e8 88 ff ff ff       	call   1005c0 <debug_trace>
  100638:	c9                   	leave  
  100639:	c3                   	ret    

0010063a <f2>:
static void gcc_noinline f2(int r, uint32_t *e) { r & 2 ? f3(r,e) : f3(r,e); }
  10063a:	55                   	push   %ebp
  10063b:	89 e5                	mov    %esp,%ebp
  10063d:	83 ec 08             	sub    $0x8,%esp
  100640:	8b 45 08             	mov    0x8(%ebp),%eax
  100643:	83 e0 02             	and    $0x2,%eax
  100646:	85 c0                	test   %eax,%eax
  100648:	74 14                	je     10065e <f2+0x24>
  10064a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10064d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100651:	8b 45 08             	mov    0x8(%ebp),%eax
  100654:	89 04 24             	mov    %eax,(%esp)
  100657:	e8 c1 ff ff ff       	call   10061d <f3>
  10065c:	eb 12                	jmp    100670 <f2+0x36>
  10065e:	8b 45 0c             	mov    0xc(%ebp),%eax
  100661:	89 44 24 04          	mov    %eax,0x4(%esp)
  100665:	8b 45 08             	mov    0x8(%ebp),%eax
  100668:	89 04 24             	mov    %eax,(%esp)
  10066b:	e8 ad ff ff ff       	call   10061d <f3>
  100670:	c9                   	leave  
  100671:	c3                   	ret    

00100672 <f1>:
static void gcc_noinline f1(int r, uint32_t *e) { r & 1 ? f2(r,e) : f2(r,e); }
  100672:	55                   	push   %ebp
  100673:	89 e5                	mov    %esp,%ebp
  100675:	83 ec 08             	sub    $0x8,%esp
  100678:	8b 45 08             	mov    0x8(%ebp),%eax
  10067b:	83 e0 01             	and    $0x1,%eax
  10067e:	84 c0                	test   %al,%al
  100680:	74 14                	je     100696 <f1+0x24>
  100682:	8b 45 0c             	mov    0xc(%ebp),%eax
  100685:	89 44 24 04          	mov    %eax,0x4(%esp)
  100689:	8b 45 08             	mov    0x8(%ebp),%eax
  10068c:	89 04 24             	mov    %eax,(%esp)
  10068f:	e8 a6 ff ff ff       	call   10063a <f2>
  100694:	eb 12                	jmp    1006a8 <f1+0x36>
  100696:	8b 45 0c             	mov    0xc(%ebp),%eax
  100699:	89 44 24 04          	mov    %eax,0x4(%esp)
  10069d:	8b 45 08             	mov    0x8(%ebp),%eax
  1006a0:	89 04 24             	mov    %eax,(%esp)
  1006a3:	e8 92 ff ff ff       	call   10063a <f2>
  1006a8:	c9                   	leave  
  1006a9:	c3                   	ret    

001006aa <debug_check>:

// Test the backtrace implementation for correct operation
void
debug_check(void)
{
  1006aa:	55                   	push   %ebp
  1006ab:	89 e5                	mov    %esp,%ebp
  1006ad:	81 ec c8 00 00 00    	sub    $0xc8,%esp
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1006b3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1006ba:	eb 29                	jmp    1006e5 <debug_check+0x3b>
		f1(i, eips[i]);
  1006bc:	8d 8d 50 ff ff ff    	lea    -0xb0(%ebp),%ecx
  1006c2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1006c5:	89 d0                	mov    %edx,%eax
  1006c7:	c1 e0 02             	shl    $0x2,%eax
  1006ca:	01 d0                	add    %edx,%eax
  1006cc:	c1 e0 03             	shl    $0x3,%eax
  1006cf:	8d 04 01             	lea    (%ecx,%eax,1),%eax
  1006d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1006d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1006d9:	89 04 24             	mov    %eax,(%esp)
  1006dc:	e8 91 ff ff ff       	call   100672 <f1>
{
	uint32_t eips[4][DEBUG_TRACEFRAMES];
	int r, i;

	// produce several related backtraces...
	for (i = 0; i < 4; i++)
  1006e1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1006e5:	83 7d f4 03          	cmpl   $0x3,-0xc(%ebp)
  1006e9:	7e d1                	jle    1006bc <debug_check+0x12>
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1006eb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  1006f2:	e9 bc 00 00 00       	jmp    1007b3 <debug_check+0x109>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1006f7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  1006fe:	e9 a2 00 00 00       	jmp    1007a5 <debug_check+0xfb>
			assert((eips[r][i] != 0) == (i < 5));
  100703:	8b 55 f0             	mov    -0x10(%ebp),%edx
  100706:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  100709:	89 d0                	mov    %edx,%eax
  10070b:	c1 e0 02             	shl    $0x2,%eax
  10070e:	01 d0                	add    %edx,%eax
  100710:	01 c0                	add    %eax,%eax
  100712:	01 c8                	add    %ecx,%eax
  100714:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  10071b:	85 c0                	test   %eax,%eax
  10071d:	0f 95 c2             	setne  %dl
  100720:	83 7d f4 04          	cmpl   $0x4,-0xc(%ebp)
  100724:	0f 9e c0             	setle  %al
  100727:	31 d0                	xor    %edx,%eax
  100729:	84 c0                	test   %al,%al
  10072b:	74 24                	je     100751 <debug_check+0xa7>
  10072d:	c7 44 24 0c 52 84 10 	movl   $0x108452,0xc(%esp)
  100734:	00 
  100735:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10073c:	00 
  10073d:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
  100744:	00 
  100745:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  10074c:	e8 67 fd ff ff       	call   1004b8 <debug_panic>
			if (i >= 2)
  100751:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
  100755:	7e 4a                	jle    1007a1 <debug_check+0xf7>
				assert(eips[r][i] == eips[0][i]);
  100757:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10075a:	8b 4d f4             	mov    -0xc(%ebp),%ecx
  10075d:	89 d0                	mov    %edx,%eax
  10075f:	c1 e0 02             	shl    $0x2,%eax
  100762:	01 d0                	add    %edx,%eax
  100764:	01 c0                	add    %eax,%eax
  100766:	01 c8                	add    %ecx,%eax
  100768:	8b 94 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%edx
  10076f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100772:	8b 84 85 50 ff ff ff 	mov    -0xb0(%ebp,%eax,4),%eax
  100779:	39 c2                	cmp    %eax,%edx
  10077b:	74 24                	je     1007a1 <debug_check+0xf7>
  10077d:	c7 44 24 0c 91 84 10 	movl   $0x108491,0xc(%esp)
  100784:	00 
  100785:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10078c:	00 
  10078d:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  100794:	00 
  100795:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  10079c:	e8 17 fd ff ff       	call   1004b8 <debug_panic>
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
  1007a1:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  1007a5:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  1007a9:	0f 8e 54 ff ff ff    	jle    100703 <debug_check+0x59>
	// produce several related backtraces...
	for (i = 0; i < 4; i++)
		f1(i, eips[i]);

	// ...and make sure they come out correctly.
	for (r = 0; r < 4; r++)
  1007af:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  1007b3:	83 7d f0 03          	cmpl   $0x3,-0x10(%ebp)
  1007b7:	0f 8e 3a ff ff ff    	jle    1006f7 <debug_check+0x4d>
		for (i = 0; i < DEBUG_TRACEFRAMES; i++) {
			assert((eips[r][i] != 0) == (i < 5));
			if (i >= 2)
				assert(eips[r][i] == eips[0][i]);
		}
	assert(eips[0][0] == eips[1][0]);
  1007bd:	8b 95 50 ff ff ff    	mov    -0xb0(%ebp),%edx
  1007c3:	8b 85 78 ff ff ff    	mov    -0x88(%ebp),%eax
  1007c9:	39 c2                	cmp    %eax,%edx
  1007cb:	74 24                	je     1007f1 <debug_check+0x147>
  1007cd:	c7 44 24 0c aa 84 10 	movl   $0x1084aa,0xc(%esp)
  1007d4:	00 
  1007d5:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  1007dc:	00 
  1007dd:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1007e4:	00 
  1007e5:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  1007ec:	e8 c7 fc ff ff       	call   1004b8 <debug_panic>
	assert(eips[2][0] == eips[3][0]);
  1007f1:	8b 55 a0             	mov    -0x60(%ebp),%edx
  1007f4:	8b 45 c8             	mov    -0x38(%ebp),%eax
  1007f7:	39 c2                	cmp    %eax,%edx
  1007f9:	74 24                	je     10081f <debug_check+0x175>
  1007fb:	c7 44 24 0c c3 84 10 	movl   $0x1084c3,0xc(%esp)
  100802:	00 
  100803:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10080a:	00 
  10080b:	c7 44 24 04 74 00 00 	movl   $0x74,0x4(%esp)
  100812:	00 
  100813:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  10081a:	e8 99 fc ff ff       	call   1004b8 <debug_panic>
	assert(eips[1][0] != eips[2][0]);
  10081f:	8b 95 78 ff ff ff    	mov    -0x88(%ebp),%edx
  100825:	8b 45 a0             	mov    -0x60(%ebp),%eax
  100828:	39 c2                	cmp    %eax,%edx
  10082a:	75 24                	jne    100850 <debug_check+0x1a6>
  10082c:	c7 44 24 0c dc 84 10 	movl   $0x1084dc,0xc(%esp)
  100833:	00 
  100834:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10083b:	00 
  10083c:	c7 44 24 04 75 00 00 	movl   $0x75,0x4(%esp)
  100843:	00 
  100844:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  10084b:	e8 68 fc ff ff       	call   1004b8 <debug_panic>
	assert(eips[0][1] == eips[2][1]);
  100850:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  100856:	8b 45 a4             	mov    -0x5c(%ebp),%eax
  100859:	39 c2                	cmp    %eax,%edx
  10085b:	74 24                	je     100881 <debug_check+0x1d7>
  10085d:	c7 44 24 0c f5 84 10 	movl   $0x1084f5,0xc(%esp)
  100864:	00 
  100865:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10086c:	00 
  10086d:	c7 44 24 04 76 00 00 	movl   $0x76,0x4(%esp)
  100874:	00 
  100875:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  10087c:	e8 37 fc ff ff       	call   1004b8 <debug_panic>
	assert(eips[1][1] == eips[3][1]);
  100881:	8b 95 7c ff ff ff    	mov    -0x84(%ebp),%edx
  100887:	8b 45 cc             	mov    -0x34(%ebp),%eax
  10088a:	39 c2                	cmp    %eax,%edx
  10088c:	74 24                	je     1008b2 <debug_check+0x208>
  10088e:	c7 44 24 0c 0e 85 10 	movl   $0x10850e,0xc(%esp)
  100895:	00 
  100896:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  10089d:	00 
  10089e:	c7 44 24 04 77 00 00 	movl   $0x77,0x4(%esp)
  1008a5:	00 
  1008a6:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  1008ad:	e8 06 fc ff ff       	call   1004b8 <debug_panic>
	assert(eips[0][1] != eips[1][1]);
  1008b2:	8b 95 54 ff ff ff    	mov    -0xac(%ebp),%edx
  1008b8:	8b 85 7c ff ff ff    	mov    -0x84(%ebp),%eax
  1008be:	39 c2                	cmp    %eax,%edx
  1008c0:	75 24                	jne    1008e6 <debug_check+0x23c>
  1008c2:	c7 44 24 0c 27 85 10 	movl   $0x108527,0xc(%esp)
  1008c9:	00 
  1008ca:	c7 44 24 08 6f 84 10 	movl   $0x10846f,0x8(%esp)
  1008d1:	00 
  1008d2:	c7 44 24 04 78 00 00 	movl   $0x78,0x4(%esp)
  1008d9:	00 
  1008da:	c7 04 24 84 84 10 00 	movl   $0x108484,(%esp)
  1008e1:	e8 d2 fb ff ff       	call   1004b8 <debug_panic>

	cprintf("debug_check() succeeded!\n");
  1008e6:	c7 04 24 40 85 10 00 	movl   $0x108540,(%esp)
  1008ed:	e8 8b 73 00 00       	call   107c7d <cprintf>
}
  1008f2:	c9                   	leave  
  1008f3:	c3                   	ret    

001008f4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1008f4:	55                   	push   %ebp
  1008f5:	89 e5                	mov    %esp,%ebp
  1008f7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1008fa:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1008fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  100900:	89 45 f0             	mov    %eax,-0x10(%ebp)
  100903:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100906:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10090b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10090e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100911:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  100917:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10091c:	74 24                	je     100942 <cpu_cur+0x4e>
  10091e:	c7 44 24 0c 5c 85 10 	movl   $0x10855c,0xc(%esp)
  100925:	00 
  100926:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  10092d:	00 
  10092e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  100935:	00 
  100936:	c7 04 24 87 85 10 00 	movl   $0x108587,(%esp)
  10093d:	e8 76 fb ff ff       	call   1004b8 <debug_panic>
	return c;
  100942:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  100945:	c9                   	leave  
  100946:	c3                   	ret    

00100947 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  100947:	55                   	push   %ebp
  100948:	89 e5                	mov    %esp,%ebp
  10094a:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10094d:	e8 a2 ff ff ff       	call   1008f4 <cpu_cur>
  100952:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  100957:	0f 94 c0             	sete   %al
  10095a:	0f b6 c0             	movzbl %al,%eax
}
  10095d:	c9                   	leave  
  10095e:	c3                   	ret    

0010095f <mem_init>:

void mem_check(void);

void
mem_init(void)
{
  10095f:	55                   	push   %ebp
  100960:	89 e5                	mov    %esp,%ebp
  100962:	83 ec 68             	sub    $0x68,%esp
	if (!cpu_onboot())	// only do once, on the boot CPU
  100965:	e8 dd ff ff ff       	call   100947 <cpu_onboot>
  10096a:	85 c0                	test   %eax,%eax
  10096c:	0f 84 e4 02 00 00    	je     100c56 <mem_init+0x2f7>
		return;

	spinlock_init(&mem_lock);
  100972:	c7 44 24 08 2a 00 00 	movl   $0x2a,0x8(%esp)
  100979:	00 
  10097a:	c7 44 24 04 94 85 10 	movl   $0x108594,0x4(%esp)
  100981:	00 
  100982:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100989:	e8 ba 23 00 00       	call   102d48 <spinlock_init_>
	// is available in the system (in bytes),
	// by reading the PC's BIOS-managed nonvolatile RAM (NVRAM).
	// The NVRAM tells us how many kilobytes there are.
	// Since the count is 16 bits, this gives us up to 64MB of RAM;
	// additional RAM beyond that would have to be detected another way.
	size_t basemem = ROUNDDOWN(nvram_read16(NVRAM_BASELO)*1024, PAGESIZE);
  10098e:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
  100995:	e8 d9 65 00 00       	call   106f73 <nvram_read16>
  10099a:	c1 e0 0a             	shl    $0xa,%eax
  10099d:	89 45 b8             	mov    %eax,-0x48(%ebp)
  1009a0:	8b 45 b8             	mov    -0x48(%ebp),%eax
  1009a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009a8:	89 45 a8             	mov    %eax,-0x58(%ebp)
	size_t extmem = ROUNDDOWN(nvram_read16(NVRAM_EXTLO)*1024, PAGESIZE);
  1009ab:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
  1009b2:	e8 bc 65 00 00       	call   106f73 <nvram_read16>
  1009b7:	c1 e0 0a             	shl    $0xa,%eax
  1009ba:	89 45 bc             	mov    %eax,-0x44(%ebp)
  1009bd:	8b 45 bc             	mov    -0x44(%ebp),%eax
  1009c0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1009c5:	89 45 ac             	mov    %eax,-0x54(%ebp)

	warn("Assuming we have 1GB of memory!");
  1009c8:	c7 44 24 08 a0 85 10 	movl   $0x1085a0,0x8(%esp)
  1009cf:	00 
  1009d0:	c7 44 24 04 35 00 00 	movl   $0x35,0x4(%esp)
  1009d7:	00 
  1009d8:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  1009df:	e8 93 fb ff ff       	call   100577 <debug_warn>
	extmem = 1024*1024*1024 - MEM_EXT;	// assume 1GB total memory
  1009e4:	c7 45 ac 00 00 f0 3f 	movl   $0x3ff00000,-0x54(%ebp)

	// The maximum physical address is the top of extended memory.
	mem_max = MEM_EXT + extmem;
  1009eb:	8b 45 ac             	mov    -0x54(%ebp),%eax
  1009ee:	05 00 00 10 00       	add    $0x100000,%eax
  1009f3:	a3 20 ed 11 00       	mov    %eax,0x11ed20

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;
  1009f8:	a1 20 ed 11 00       	mov    0x11ed20,%eax
  1009fd:	c1 e8 0c             	shr    $0xc,%eax
  100a00:	a3 1c ed 11 00       	mov    %eax,0x11ed1c

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
  100a05:	a1 20 ed 11 00       	mov    0x11ed20,%eax
  100a0a:	c1 e8 0a             	shr    $0xa,%eax
  100a0d:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a11:	c7 04 24 c0 85 10 00 	movl   $0x1085c0,(%esp)
  100a18:	e8 60 72 00 00       	call   107c7d <cprintf>
	cprintf("base = %dK, extended = %dK\n",
		(int)(basemem/1024), (int)(extmem/1024));
  100a1d:	8b 45 ac             	mov    -0x54(%ebp),%eax
  100a20:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100a23:	89 c2                	mov    %eax,%edx
		(int)(basemem/1024), (int)(extmem/1024));
  100a25:	8b 45 a8             	mov    -0x58(%ebp),%eax
  100a28:	c1 e8 0a             	shr    $0xa,%eax

	// Compute the total number of physical pages (including I/O holes)
	mem_npage = mem_max / PAGESIZE;

	cprintf("Physical memory: %dK available, ", (int)(mem_max/1024));
	cprintf("base = %dK, extended = %dK\n",
  100a2b:	89 54 24 08          	mov    %edx,0x8(%esp)
  100a2f:	89 44 24 04          	mov    %eax,0x4(%esp)
  100a33:	c7 04 24 e1 85 10 00 	movl   $0x1085e1,(%esp)
  100a3a:	e8 3e 72 00 00       	call   107c7d <cprintf>
		(int)(basemem/1024), (int)(extmem/1024));

	// Insert code here to:
	// (1)	allocate physical memory for the mem_pageinfo array,
	//	making it big enough to hold mem_npage entries.
	mem_pageinfo = mem_ptr(ROUNDUP(mem_phys(end), PAGESIZE));
  100a3f:	c7 45 c0 00 10 00 00 	movl   $0x1000,-0x40(%ebp)
  100a46:	b8 08 20 12 00       	mov    $0x122008,%eax
  100a4b:	83 e8 01             	sub    $0x1,%eax
  100a4e:	03 45 c0             	add    -0x40(%ebp),%eax
  100a51:	89 45 c4             	mov    %eax,-0x3c(%ebp)
  100a54:	8b 45 c4             	mov    -0x3c(%ebp),%eax
  100a57:	ba 00 00 00 00       	mov    $0x0,%edx
  100a5c:	f7 75 c0             	divl   -0x40(%ebp)
  100a5f:	89 d0                	mov    %edx,%eax
  100a61:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  100a64:	89 d1                	mov    %edx,%ecx
  100a66:	29 c1                	sub    %eax,%ecx
  100a68:	89 c8                	mov    %ecx,%eax
  100a6a:	a3 24 ed 11 00       	mov    %eax,0x11ed24
	cprintf("kernel end %p, pageinfo %p\n", end, mem_pageinfo);
  100a6f:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100a74:	89 44 24 08          	mov    %eax,0x8(%esp)
  100a78:	c7 44 24 04 08 20 12 	movl   $0x122008,0x4(%esp)
  100a7f:	00 
  100a80:	c7 04 24 fd 85 10 00 	movl   $0x1085fd,(%esp)
  100a87:	e8 f1 71 00 00       	call   107c7d <cprintf>
	cprintf("num pages %d, pagetable takes %d pages\n", mem_npage,
		ROUNDUP(mem_npage*sizeof(pageinfo), PAGESIZE) / PAGESIZE);
  100a8c:	c7 45 c8 00 10 00 00 	movl   $0x1000,-0x38(%ebp)
  100a93:	a1 1c ed 11 00       	mov    0x11ed1c,%eax
  100a98:	c1 e0 03             	shl    $0x3,%eax
  100a9b:	03 45 c8             	add    -0x38(%ebp),%eax
  100a9e:	83 e8 01             	sub    $0x1,%eax
  100aa1:	89 45 cc             	mov    %eax,-0x34(%ebp)
  100aa4:	8b 45 cc             	mov    -0x34(%ebp),%eax
  100aa7:	ba 00 00 00 00       	mov    $0x0,%edx
  100aac:	f7 75 c8             	divl   -0x38(%ebp)
  100aaf:	89 d0                	mov    %edx,%eax
  100ab1:	8b 55 cc             	mov    -0x34(%ebp),%edx
  100ab4:	89 d1                	mov    %edx,%ecx
  100ab6:	29 c1                	sub    %eax,%ecx
  100ab8:	89 c8                	mov    %ecx,%eax
	// Insert code here to:
	// (1)	allocate physical memory for the mem_pageinfo array,
	//	making it big enough to hold mem_npage entries.
	mem_pageinfo = mem_ptr(ROUNDUP(mem_phys(end), PAGESIZE));
	cprintf("kernel end %p, pageinfo %p\n", end, mem_pageinfo);
	cprintf("num pages %d, pagetable takes %d pages\n", mem_npage,
  100aba:	89 c2                	mov    %eax,%edx
  100abc:	c1 ea 0c             	shr    $0xc,%edx
  100abf:	a1 1c ed 11 00       	mov    0x11ed1c,%eax
  100ac4:	89 54 24 08          	mov    %edx,0x8(%esp)
  100ac8:	89 44 24 04          	mov    %eax,0x4(%esp)
  100acc:	c7 04 24 1c 86 10 00 	movl   $0x10861c,(%esp)
  100ad3:	e8 a5 71 00 00       	call   107c7d <cprintf>
	//     Some of it is in use, some is free.
	//     Which pages hold the kernel and the pageinfo array?
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
  100ad8:	c7 45 b0 18 ed 11 00 	movl   $0x11ed18,-0x50(%ebp)
	int i;
	for (i = 0; i < mem_npage; i++) {
  100adf:	c7 45 b4 00 00 00 00 	movl   $0x0,-0x4c(%ebp)
  100ae6:	e9 4b 01 00 00       	jmp    100c36 <mem_init+0x2d7>
		if(i == 0 || i == 1) {
  100aeb:	83 7d b4 00          	cmpl   $0x0,-0x4c(%ebp)
  100aef:	0f 84 30 01 00 00    	je     100c25 <mem_init+0x2c6>
  100af5:	83 7d b4 01          	cmpl   $0x1,-0x4c(%ebp)
  100af9:	0f 84 29 01 00 00    	je     100c28 <mem_init+0x2c9>
			// cprintf("page %d: IDT/BIOS/IO\n", i);
			continue;
		}
		if(i >= MEM_IO/PAGESIZE && i < MEM_EXT/PAGESIZE) {
  100aff:	81 7d b4 9f 00 00 00 	cmpl   $0x9f,-0x4c(%ebp)
  100b06:	7e 0d                	jle    100b15 <mem_init+0x1b6>
  100b08:	81 7d b4 ff 00 00 00 	cmpl   $0xff,-0x4c(%ebp)
  100b0f:	0f 8e 16 01 00 00    	jle    100c2b <mem_init+0x2cc>
			// cprintf("page %d: BIOS IO\n", i);
			continue;
		}
		uint32_t kstartpg = ROUNDDOWN(mem_phys(start),PAGESIZE);
  100b15:	c7 45 e0 0c 00 10 00 	movl   $0x10000c,-0x20(%ebp)
  100b1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  100b1f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100b24:	89 45 d0             	mov    %eax,-0x30(%ebp)
		kstartpg /= PAGESIZE;
  100b27:	8b 45 d0             	mov    -0x30(%ebp),%eax
  100b2a:	c1 e8 0c             	shr    $0xc,%eax
  100b2d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		uint32_t kendpg = ROUNDUP(mem_phys(end), PAGESIZE);
  100b30:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  100b37:	b8 08 20 12 00       	mov    $0x122008,%eax
  100b3c:	83 e8 01             	sub    $0x1,%eax
  100b3f:	03 45 e4             	add    -0x1c(%ebp),%eax
  100b42:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100b45:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100b48:	ba 00 00 00 00       	mov    $0x0,%edx
  100b4d:	f7 75 e4             	divl   -0x1c(%ebp)
  100b50:	89 d0                	mov    %edx,%eax
  100b52:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100b55:	89 d1                	mov    %edx,%ecx
  100b57:	29 c1                	sub    %eax,%ecx
  100b59:	89 c8                	mov    %ecx,%eax
  100b5b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		kendpg /= PAGESIZE;
  100b5e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  100b61:	c1 e8 0c             	shr    $0xc,%eax
  100b64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		if(i >= kstartpg && i < kendpg) {
  100b67:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  100b6a:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  100b6d:	72 0c                	jb     100b7b <mem_init+0x21c>
  100b6f:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  100b72:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  100b75:	0f 82 b3 00 00 00    	jb     100c2e <mem_init+0x2cf>
			// cprintf("page %d: KERNEL\n", i);
			continue;
		}
		uint32_t mstartpg = ROUNDDOWN(mem_phys(mem_pageinfo),PAGESIZE);
  100b7b:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100b80:	89 45 ec             	mov    %eax,-0x14(%ebp)
  100b83:	8b 45 ec             	mov    -0x14(%ebp),%eax
  100b86:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  100b8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
		mstartpg /= PAGESIZE;
  100b8e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  100b91:	c1 e8 0c             	shr    $0xc,%eax
  100b94:	89 45 d8             	mov    %eax,-0x28(%ebp)
		uint32_t mendpg = mem_phys(&mem_pageinfo[mem_npage]);
  100b97:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100b9c:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  100ba2:	c1 e2 03             	shl    $0x3,%edx
  100ba5:	01 d0                	add    %edx,%eax
  100ba7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		mendpg = ROUNDUP(mendpg, PAGESIZE) / PAGESIZE;
  100baa:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
  100bb1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  100bb4:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100bb7:	8d 04 02             	lea    (%edx,%eax,1),%eax
  100bba:	83 e8 01             	sub    $0x1,%eax
  100bbd:	89 45 f4             	mov    %eax,-0xc(%ebp)
  100bc0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100bc3:	ba 00 00 00 00       	mov    $0x0,%edx
  100bc8:	f7 75 f0             	divl   -0x10(%ebp)
  100bcb:	89 d0                	mov    %edx,%eax
  100bcd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100bd0:	89 d1                	mov    %edx,%ecx
  100bd2:	29 c1                	sub    %eax,%ecx
  100bd4:	89 c8                	mov    %ecx,%eax
  100bd6:	c1 e8 0c             	shr    $0xc,%eax
  100bd9:	89 45 dc             	mov    %eax,-0x24(%ebp)
		if(i >= mstartpg && i < mendpg) {
  100bdc:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  100bdf:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  100be2:	72 08                	jb     100bec <mem_init+0x28d>
  100be4:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  100be7:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  100bea:	72 45                	jb     100c31 <mem_init+0x2d2>
			continue;
		}
		// if(i < 1000) cprintf("page %d: free\n", i);

		// A free page has no references to it.
		mem_pageinfo[i].refcount = 0;
  100bec:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100bf1:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  100bf4:	c1 e2 03             	shl    $0x3,%edx
  100bf7:	01 d0                	add    %edx,%eax
  100bf9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
  100c00:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100c05:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  100c08:	c1 e2 03             	shl    $0x3,%edx
  100c0b:	8d 14 10             	lea    (%eax,%edx,1),%edx
  100c0e:	8b 45 b0             	mov    -0x50(%ebp),%eax
  100c11:	89 10                	mov    %edx,(%eax)
		freetail = &mem_pageinfo[i].free_next;
  100c13:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100c18:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  100c1b:	c1 e2 03             	shl    $0x3,%edx
  100c1e:	01 d0                	add    %edx,%eax
  100c20:	89 45 b0             	mov    %eax,-0x50(%ebp)
  100c23:	eb 0d                	jmp    100c32 <mem_init+0x2d3>
	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
		if(i == 0 || i == 1) {
			// cprintf("page %d: IDT/BIOS/IO\n", i);
			continue;
  100c25:	90                   	nop
  100c26:	eb 0a                	jmp    100c32 <mem_init+0x2d3>
  100c28:	90                   	nop
  100c29:	eb 07                	jmp    100c32 <mem_init+0x2d3>
		}
		if(i >= MEM_IO/PAGESIZE && i < MEM_EXT/PAGESIZE) {
			// cprintf("page %d: BIOS IO\n", i);
			continue;
  100c2b:	90                   	nop
  100c2c:	eb 04                	jmp    100c32 <mem_init+0x2d3>
		kstartpg /= PAGESIZE;
		uint32_t kendpg = ROUNDUP(mem_phys(end), PAGESIZE);
		kendpg /= PAGESIZE;
		if(i >= kstartpg && i < kendpg) {
			// cprintf("page %d: KERNEL\n", i);
			continue;
  100c2e:	90                   	nop
  100c2f:	eb 01                	jmp    100c32 <mem_init+0x2d3>
		mstartpg /= PAGESIZE;
		uint32_t mendpg = mem_phys(&mem_pageinfo[mem_npage]);
		mendpg = ROUNDUP(mendpg, PAGESIZE) / PAGESIZE;
		if(i >= mstartpg && i < mendpg) {
			// cprintf("page %d: MEMPAGES\n", i);
			continue;
  100c31:	90                   	nop
	//     Hint: the linker places the kernel (see start and end above),
	//     but YOU decide where to place the pageinfo array.
	// Change the code to reflect this.
	pageinfo **freetail = &mem_freelist;
	int i;
	for (i = 0; i < mem_npage; i++) {
  100c32:	83 45 b4 01          	addl   $0x1,-0x4c(%ebp)
  100c36:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  100c39:	a1 1c ed 11 00       	mov    0x11ed1c,%eax
  100c3e:	39 c2                	cmp    %eax,%edx
  100c40:	0f 82 a5 fe ff ff    	jb     100aeb <mem_init+0x18c>

		// Add the page to the end of the free list.
		*freetail = &mem_pageinfo[i];
		freetail = &mem_pageinfo[i].free_next;
	}
	*freetail = NULL;	// null-terminate the freelist
  100c46:	8b 45 b0             	mov    -0x50(%ebp),%eax
  100c49:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// ...and remove this when you're ready.
	// panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
  100c4f:	e8 b7 00 00 00       	call   100d0b <mem_check>
  100c54:	eb 01                	jmp    100c57 <mem_init+0x2f8>

void
mem_init(void)
{
	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  100c56:	90                   	nop
	// ...and remove this when you're ready.
	// panic("mem_init() not implemented");

	// Check to make sure the page allocator seems to work correctly.
	mem_check();
}
  100c57:	c9                   	leave  
  100c58:	c3                   	ret    

00100c59 <mem_alloc>:
//
// Hint: pi->refs should not be incremented 
// Hint: be sure to use proper mutual exclusion for multiprocessor operation.
pageinfo *
mem_alloc(void)
{
  100c59:	55                   	push   %ebp
  100c5a:	89 e5                	mov    %esp,%ebp
  100c5c:	83 ec 28             	sub    $0x28,%esp
	spinlock_acquire(&mem_lock);
  100c5f:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100c66:	e8 14 21 00 00       	call   102d7f <spinlock_acquire>
	if(!mem_freelist) {
  100c6b:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  100c70:	85 c0                	test   %eax,%eax
  100c72:	75 13                	jne    100c87 <mem_alloc+0x2e>
		spinlock_release(&mem_lock);		
  100c74:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100c7b:	e8 74 21 00 00       	call   102df4 <spinlock_release>
		return NULL;
  100c80:	b8 00 00 00 00       	mov    $0x0,%eax
  100c85:	eb 21                	jmp    100ca8 <mem_alloc+0x4f>
	}
	pageinfo *r = mem_freelist;
  100c87:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  100c8c:	89 45 f4             	mov    %eax,-0xc(%ebp)
	mem_freelist = r->free_next;
  100c8f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100c92:	8b 00                	mov    (%eax),%eax
  100c94:	a3 18 ed 11 00       	mov    %eax,0x11ed18
	spinlock_release(&mem_lock);
  100c99:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100ca0:	e8 4f 21 00 00       	call   102df4 <spinlock_release>
	return r;
  100ca5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  100ca8:	c9                   	leave  
  100ca9:	c3                   	ret    

00100caa <mem_free>:
// Return a page to the free list, given its pageinfo pointer.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
mem_free(pageinfo *pi)
{
  100caa:	55                   	push   %ebp
  100cab:	89 e5                	mov    %esp,%ebp
  100cad:	83 ec 18             	sub    $0x18,%esp
	spinlock_acquire(&mem_lock);
  100cb0:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100cb7:	e8 c3 20 00 00       	call   102d7f <spinlock_acquire>
	assert(pi->refcount == 0);
  100cbc:	8b 45 08             	mov    0x8(%ebp),%eax
  100cbf:	8b 40 04             	mov    0x4(%eax),%eax
  100cc2:	85 c0                	test   %eax,%eax
  100cc4:	74 24                	je     100cea <mem_free+0x40>
  100cc6:	c7 44 24 0c 44 86 10 	movl   $0x108644,0xc(%esp)
  100ccd:	00 
  100cce:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100cd5:	00 
  100cd6:	c7 44 24 04 aa 00 00 	movl   $0xaa,0x4(%esp)
  100cdd:	00 
  100cde:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100ce5:	e8 ce f7 ff ff       	call   1004b8 <debug_panic>
	pi->free_next = mem_freelist;
  100cea:	8b 15 18 ed 11 00    	mov    0x11ed18,%edx
  100cf0:	8b 45 08             	mov    0x8(%ebp),%eax
  100cf3:	89 10                	mov    %edx,(%eax)
	mem_freelist = pi;
  100cf5:	8b 45 08             	mov    0x8(%ebp),%eax
  100cf8:	a3 18 ed 11 00       	mov    %eax,0x11ed18
	spinlock_release(&mem_lock);
  100cfd:	c7 04 24 e0 ec 11 00 	movl   $0x11ece0,(%esp)
  100d04:	e8 eb 20 00 00       	call   102df4 <spinlock_release>
}
  100d09:	c9                   	leave  
  100d0a:	c3                   	ret    

00100d0b <mem_check>:
// Check the physical page allocator (mem_alloc(), mem_free())
// for correct operation after initialization via mem_init().
//
void
mem_check()
{
  100d0b:	55                   	push   %ebp
  100d0c:	89 e5                	mov    %esp,%ebp
  100d0e:	83 ec 38             	sub    $0x38,%esp
	int i;

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
  100d11:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100d18:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  100d1d:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100d20:	eb 38                	jmp    100d5a <mem_check+0x4f>
		memset(mem_pi2ptr(pp), 0x97, 128);
  100d22:	8b 55 dc             	mov    -0x24(%ebp),%edx
  100d25:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100d2a:	89 d1                	mov    %edx,%ecx
  100d2c:	29 c1                	sub    %eax,%ecx
  100d2e:	89 c8                	mov    %ecx,%eax
  100d30:	c1 f8 03             	sar    $0x3,%eax
  100d33:	c1 e0 0c             	shl    $0xc,%eax
  100d36:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
  100d3d:	00 
  100d3e:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
  100d45:	00 
  100d46:	89 04 24             	mov    %eax,(%esp)
  100d49:	e8 16 71 00 00       	call   107e64 <memset>
		freepages++;
  100d4e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)

        // if there's a page that shouldn't be on
        // the free list, try to make sure it
        // eventually causes trouble.
	int freepages = 0;
	for (pp = mem_freelist; pp != 0; pp = pp->free_next) {
  100d52:	8b 45 dc             	mov    -0x24(%ebp),%eax
  100d55:	8b 00                	mov    (%eax),%eax
  100d57:	89 45 dc             	mov    %eax,-0x24(%ebp)
  100d5a:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  100d5e:	75 c2                	jne    100d22 <mem_check+0x17>
		memset(mem_pi2ptr(pp), 0x97, 128);
		freepages++;
	}
	cprintf("mem_check: %d free pages\n", freepages);
  100d60:	8b 45 f4             	mov    -0xc(%ebp),%eax
  100d63:	89 44 24 04          	mov    %eax,0x4(%esp)
  100d67:	c7 04 24 56 86 10 00 	movl   $0x108656,(%esp)
  100d6e:	e8 0a 6f 00 00       	call   107c7d <cprintf>
	assert(freepages < mem_npage);	// can't have more free than total!
  100d73:	8b 55 f4             	mov    -0xc(%ebp),%edx
  100d76:	a1 1c ed 11 00       	mov    0x11ed1c,%eax
  100d7b:	39 c2                	cmp    %eax,%edx
  100d7d:	72 24                	jb     100da3 <mem_check+0x98>
  100d7f:	c7 44 24 0c 70 86 10 	movl   $0x108670,0xc(%esp)
  100d86:	00 
  100d87:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100d8e:	00 
  100d8f:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
  100d96:	00 
  100d97:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100d9e:	e8 15 f7 ff ff       	call   1004b8 <debug_panic>
	assert(freepages > 16000);	// make sure it's in the right ballpark
  100da3:	81 7d f4 80 3e 00 00 	cmpl   $0x3e80,-0xc(%ebp)
  100daa:	7f 24                	jg     100dd0 <mem_check+0xc5>
  100dac:	c7 44 24 0c 86 86 10 	movl   $0x108686,0xc(%esp)
  100db3:	00 
  100db4:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100dbb:	00 
  100dbc:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
  100dc3:	00 
  100dc4:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100dcb:	e8 e8 f6 ff ff       	call   1004b8 <debug_panic>

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
  100dd0:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  100dd7:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100dda:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100ddd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100de0:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  100de3:	e8 71 fe ff ff       	call   100c59 <mem_alloc>
  100de8:	89 45 e0             	mov    %eax,-0x20(%ebp)
  100deb:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100def:	75 24                	jne    100e15 <mem_check+0x10a>
  100df1:	c7 44 24 0c 98 86 10 	movl   $0x108698,0xc(%esp)
  100df8:	00 
  100df9:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100e00:	00 
  100e01:	c7 44 24 04 c9 00 00 	movl   $0xc9,0x4(%esp)
  100e08:	00 
  100e09:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100e10:	e8 a3 f6 ff ff       	call   1004b8 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  100e15:	e8 3f fe ff ff       	call   100c59 <mem_alloc>
  100e1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  100e1d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100e21:	75 24                	jne    100e47 <mem_check+0x13c>
  100e23:	c7 44 24 0c a1 86 10 	movl   $0x1086a1,0xc(%esp)
  100e2a:	00 
  100e2b:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100e32:	00 
  100e33:	c7 44 24 04 ca 00 00 	movl   $0xca,0x4(%esp)
  100e3a:	00 
  100e3b:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100e42:	e8 71 f6 ff ff       	call   1004b8 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  100e47:	e8 0d fe ff ff       	call   100c59 <mem_alloc>
  100e4c:	89 45 e8             	mov    %eax,-0x18(%ebp)
  100e4f:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100e53:	75 24                	jne    100e79 <mem_check+0x16e>
  100e55:	c7 44 24 0c aa 86 10 	movl   $0x1086aa,0xc(%esp)
  100e5c:	00 
  100e5d:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100e64:	00 
  100e65:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
  100e6c:	00 
  100e6d:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100e74:	e8 3f f6 ff ff       	call   1004b8 <debug_panic>

	assert(pp0);
  100e79:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  100e7d:	75 24                	jne    100ea3 <mem_check+0x198>
  100e7f:	c7 44 24 0c b3 86 10 	movl   $0x1086b3,0xc(%esp)
  100e86:	00 
  100e87:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100e8e:	00 
  100e8f:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
  100e96:	00 
  100e97:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100e9e:	e8 15 f6 ff ff       	call   1004b8 <debug_panic>
	assert(pp1 && pp1 != pp0);
  100ea3:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  100ea7:	74 08                	je     100eb1 <mem_check+0x1a6>
  100ea9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  100eac:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100eaf:	75 24                	jne    100ed5 <mem_check+0x1ca>
  100eb1:	c7 44 24 0c b7 86 10 	movl   $0x1086b7,0xc(%esp)
  100eb8:	00 
  100eb9:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100ec0:	00 
  100ec1:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
  100ec8:	00 
  100ec9:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100ed0:	e8 e3 f5 ff ff       	call   1004b8 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  100ed5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  100ed9:	74 10                	je     100eeb <mem_check+0x1e0>
  100edb:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ede:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  100ee1:	74 08                	je     100eeb <mem_check+0x1e0>
  100ee3:	8b 45 e8             	mov    -0x18(%ebp),%eax
  100ee6:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  100ee9:	75 24                	jne    100f0f <mem_check+0x204>
  100eeb:	c7 44 24 0c cc 86 10 	movl   $0x1086cc,0xc(%esp)
  100ef2:	00 
  100ef3:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100efa:	00 
  100efb:	c7 44 24 04 cf 00 00 	movl   $0xcf,0x4(%esp)
  100f02:	00 
  100f03:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100f0a:	e8 a9 f5 ff ff       	call   1004b8 <debug_panic>
        assert(mem_pi2phys(pp0) < mem_npage*PAGESIZE);
  100f0f:	8b 55 e0             	mov    -0x20(%ebp),%edx
  100f12:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100f17:	89 d1                	mov    %edx,%ecx
  100f19:	29 c1                	sub    %eax,%ecx
  100f1b:	89 c8                	mov    %ecx,%eax
  100f1d:	c1 f8 03             	sar    $0x3,%eax
  100f20:	c1 e0 0c             	shl    $0xc,%eax
  100f23:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  100f29:	c1 e2 0c             	shl    $0xc,%edx
  100f2c:	39 d0                	cmp    %edx,%eax
  100f2e:	72 24                	jb     100f54 <mem_check+0x249>
  100f30:	c7 44 24 0c ec 86 10 	movl   $0x1086ec,0xc(%esp)
  100f37:	00 
  100f38:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100f3f:	00 
  100f40:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
  100f47:	00 
  100f48:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100f4f:	e8 64 f5 ff ff       	call   1004b8 <debug_panic>
        assert(mem_pi2phys(pp1) < mem_npage*PAGESIZE);
  100f54:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  100f57:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100f5c:	89 d1                	mov    %edx,%ecx
  100f5e:	29 c1                	sub    %eax,%ecx
  100f60:	89 c8                	mov    %ecx,%eax
  100f62:	c1 f8 03             	sar    $0x3,%eax
  100f65:	c1 e0 0c             	shl    $0xc,%eax
  100f68:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  100f6e:	c1 e2 0c             	shl    $0xc,%edx
  100f71:	39 d0                	cmp    %edx,%eax
  100f73:	72 24                	jb     100f99 <mem_check+0x28e>
  100f75:	c7 44 24 0c 14 87 10 	movl   $0x108714,0xc(%esp)
  100f7c:	00 
  100f7d:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100f84:	00 
  100f85:	c7 44 24 04 d1 00 00 	movl   $0xd1,0x4(%esp)
  100f8c:	00 
  100f8d:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100f94:	e8 1f f5 ff ff       	call   1004b8 <debug_panic>
        assert(mem_pi2phys(pp2) < mem_npage*PAGESIZE);
  100f99:	8b 55 e8             	mov    -0x18(%ebp),%edx
  100f9c:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  100fa1:	89 d1                	mov    %edx,%ecx
  100fa3:	29 c1                	sub    %eax,%ecx
  100fa5:	89 c8                	mov    %ecx,%eax
  100fa7:	c1 f8 03             	sar    $0x3,%eax
  100faa:	c1 e0 0c             	shl    $0xc,%eax
  100fad:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  100fb3:	c1 e2 0c             	shl    $0xc,%edx
  100fb6:	39 d0                	cmp    %edx,%eax
  100fb8:	72 24                	jb     100fde <mem_check+0x2d3>
  100fba:	c7 44 24 0c 3c 87 10 	movl   $0x10873c,0xc(%esp)
  100fc1:	00 
  100fc2:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  100fc9:	00 
  100fca:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
  100fd1:	00 
  100fd2:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  100fd9:	e8 da f4 ff ff       	call   1004b8 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  100fde:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  100fe3:	89 45 ec             	mov    %eax,-0x14(%ebp)
	mem_freelist = 0;
  100fe6:	c7 05 18 ed 11 00 00 	movl   $0x0,0x11ed18
  100fed:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == 0);
  100ff0:	e8 64 fc ff ff       	call   100c59 <mem_alloc>
  100ff5:	85 c0                	test   %eax,%eax
  100ff7:	74 24                	je     10101d <mem_check+0x312>
  100ff9:	c7 44 24 0c 62 87 10 	movl   $0x108762,0xc(%esp)
  101000:	00 
  101001:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  101008:	00 
  101009:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
  101010:	00 
  101011:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  101018:	e8 9b f4 ff ff       	call   1004b8 <debug_panic>

        // free and re-allocate?
        mem_free(pp0);
  10101d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  101020:	89 04 24             	mov    %eax,(%esp)
  101023:	e8 82 fc ff ff       	call   100caa <mem_free>
        mem_free(pp1);
  101028:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10102b:	89 04 24             	mov    %eax,(%esp)
  10102e:	e8 77 fc ff ff       	call   100caa <mem_free>
        mem_free(pp2);
  101033:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101036:	89 04 24             	mov    %eax,(%esp)
  101039:	e8 6c fc ff ff       	call   100caa <mem_free>
	pp0 = pp1 = pp2 = 0;
  10103e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  101045:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10104b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10104e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pp0 = mem_alloc(); assert(pp0 != 0);
  101051:	e8 03 fc ff ff       	call   100c59 <mem_alloc>
  101056:	89 45 e0             	mov    %eax,-0x20(%ebp)
  101059:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  10105d:	75 24                	jne    101083 <mem_check+0x378>
  10105f:	c7 44 24 0c 98 86 10 	movl   $0x108698,0xc(%esp)
  101066:	00 
  101067:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  10106e:	00 
  10106f:	c7 44 24 04 e0 00 00 	movl   $0xe0,0x4(%esp)
  101076:	00 
  101077:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  10107e:	e8 35 f4 ff ff       	call   1004b8 <debug_panic>
	pp1 = mem_alloc(); assert(pp1 != 0);
  101083:	e8 d1 fb ff ff       	call   100c59 <mem_alloc>
  101088:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  10108b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  10108f:	75 24                	jne    1010b5 <mem_check+0x3aa>
  101091:	c7 44 24 0c a1 86 10 	movl   $0x1086a1,0xc(%esp)
  101098:	00 
  101099:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  1010a0:	00 
  1010a1:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
  1010a8:	00 
  1010a9:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  1010b0:	e8 03 f4 ff ff       	call   1004b8 <debug_panic>
	pp2 = mem_alloc(); assert(pp2 != 0);
  1010b5:	e8 9f fb ff ff       	call   100c59 <mem_alloc>
  1010ba:	89 45 e8             	mov    %eax,-0x18(%ebp)
  1010bd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  1010c1:	75 24                	jne    1010e7 <mem_check+0x3dc>
  1010c3:	c7 44 24 0c aa 86 10 	movl   $0x1086aa,0xc(%esp)
  1010ca:	00 
  1010cb:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  1010d2:	00 
  1010d3:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
  1010da:	00 
  1010db:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  1010e2:	e8 d1 f3 ff ff       	call   1004b8 <debug_panic>
	assert(pp0);
  1010e7:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  1010eb:	75 24                	jne    101111 <mem_check+0x406>
  1010ed:	c7 44 24 0c b3 86 10 	movl   $0x1086b3,0xc(%esp)
  1010f4:	00 
  1010f5:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  1010fc:	00 
  1010fd:	c7 44 24 04 e3 00 00 	movl   $0xe3,0x4(%esp)
  101104:	00 
  101105:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  10110c:	e8 a7 f3 ff ff       	call   1004b8 <debug_panic>
	assert(pp1 && pp1 != pp0);
  101111:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  101115:	74 08                	je     10111f <mem_check+0x414>
  101117:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10111a:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  10111d:	75 24                	jne    101143 <mem_check+0x438>
  10111f:	c7 44 24 0c b7 86 10 	movl   $0x1086b7,0xc(%esp)
  101126:	00 
  101127:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  10112e:	00 
  10112f:	c7 44 24 04 e4 00 00 	movl   $0xe4,0x4(%esp)
  101136:	00 
  101137:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  10113e:	e8 75 f3 ff ff       	call   1004b8 <debug_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
  101143:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  101147:	74 10                	je     101159 <mem_check+0x44e>
  101149:	8b 45 e8             	mov    -0x18(%ebp),%eax
  10114c:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  10114f:	74 08                	je     101159 <mem_check+0x44e>
  101151:	8b 45 e8             	mov    -0x18(%ebp),%eax
  101154:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  101157:	75 24                	jne    10117d <mem_check+0x472>
  101159:	c7 44 24 0c cc 86 10 	movl   $0x1086cc,0xc(%esp)
  101160:	00 
  101161:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  101168:	00 
  101169:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
  101170:	00 
  101171:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  101178:	e8 3b f3 ff ff       	call   1004b8 <debug_panic>
	assert(mem_alloc() == 0);
  10117d:	e8 d7 fa ff ff       	call   100c59 <mem_alloc>
  101182:	85 c0                	test   %eax,%eax
  101184:	74 24                	je     1011aa <mem_check+0x49f>
  101186:	c7 44 24 0c 62 87 10 	movl   $0x108762,0xc(%esp)
  10118d:	00 
  10118e:	c7 44 24 08 72 85 10 	movl   $0x108572,0x8(%esp)
  101195:	00 
  101196:	c7 44 24 04 e6 00 00 	movl   $0xe6,0x4(%esp)
  10119d:	00 
  10119e:	c7 04 24 94 85 10 00 	movl   $0x108594,(%esp)
  1011a5:	e8 0e f3 ff ff       	call   1004b8 <debug_panic>

	// give free list back
	mem_freelist = fl;
  1011aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1011ad:	a3 18 ed 11 00       	mov    %eax,0x11ed18

	// free the pages we took
	mem_free(pp0);
  1011b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1011b5:	89 04 24             	mov    %eax,(%esp)
  1011b8:	e8 ed fa ff ff       	call   100caa <mem_free>
	mem_free(pp1);
  1011bd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1011c0:	89 04 24             	mov    %eax,(%esp)
  1011c3:	e8 e2 fa ff ff       	call   100caa <mem_free>
	mem_free(pp2);
  1011c8:	8b 45 e8             	mov    -0x18(%ebp),%eax
  1011cb:	89 04 24             	mov    %eax,(%esp)
  1011ce:	e8 d7 fa ff ff       	call   100caa <mem_free>

	cprintf("mem_check() succeeded!\n");
  1011d3:	c7 04 24 73 87 10 00 	movl   $0x108773,(%esp)
  1011da:	e8 9e 6a 00 00       	call   107c7d <cprintf>
}
  1011df:	c9                   	leave  
  1011e0:	c3                   	ret    
  1011e1:	90                   	nop
  1011e2:	90                   	nop
  1011e3:	90                   	nop

001011e4 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1011e4:	55                   	push   %ebp
  1011e5:	89 e5                	mov    %esp,%ebp
  1011e7:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1011ea:	8b 55 08             	mov    0x8(%ebp),%edx
  1011ed:	8b 45 0c             	mov    0xc(%ebp),%eax
  1011f0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1011f3:	f0 87 02             	lock xchg %eax,(%edx)
  1011f6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  1011f9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  1011fc:	c9                   	leave  
  1011fd:	c3                   	ret    

001011fe <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1011fe:	55                   	push   %ebp
  1011ff:	89 e5                	mov    %esp,%ebp
  101201:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  101204:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  101207:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10120a:	89 45 f0             	mov    %eax,-0x10(%ebp)
  10120d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101210:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  101215:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  101218:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10121b:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101221:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  101226:	74 24                	je     10124c <cpu_cur+0x4e>
  101228:	c7 44 24 0c 8b 87 10 	movl   $0x10878b,0xc(%esp)
  10122f:	00 
  101230:	c7 44 24 08 a1 87 10 	movl   $0x1087a1,0x8(%esp)
  101237:	00 
  101238:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  10123f:	00 
  101240:	c7 04 24 b6 87 10 00 	movl   $0x1087b6,(%esp)
  101247:	e8 6c f2 ff ff       	call   1004b8 <debug_panic>
	return c;
  10124c:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  10124f:	c9                   	leave  
  101250:	c3                   	ret    

00101251 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101251:	55                   	push   %ebp
  101252:	89 e5                	mov    %esp,%ebp
  101254:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  101257:	e8 a2 ff ff ff       	call   1011fe <cpu_cur>
  10125c:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  101261:	0f 94 c0             	sete   %al
  101264:	0f b6 c0             	movzbl %al,%eax
}
  101267:	c9                   	leave  
  101268:	c3                   	ret    

00101269 <cpu_init>:
	magic: CPU_MAGIC
};


void cpu_init()
{
  101269:	55                   	push   %ebp
  10126a:	89 e5                	mov    %esp,%ebp
  10126c:	53                   	push   %ebx
  10126d:	83 ec 24             	sub    $0x24,%esp
	cpu *c = cpu_cur();
  101270:	e8 89 ff ff ff       	call   1011fe <cpu_cur>
  101275:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Load the GDT
	struct pseudodesc gdt_pd = {
		sizeof(c->gdt) - 1, (uint32_t) c->gdt };
  101278:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10127b:	66 c7 45 ea 37 00    	movw   $0x37,-0x16(%ebp)
  101281:	89 45 ec             	mov    %eax,-0x14(%ebp)
	asm volatile("lgdt %0" : : "m" (gdt_pd));
  101284:	0f 01 55 ea          	lgdtl  -0x16(%ebp)

	// Reload all segment registers.
	asm volatile("movw %%ax,%%gs" :: "a" (CPU_GDT_UDATA|3));
  101288:	b8 23 00 00 00       	mov    $0x23,%eax
  10128d:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (CPU_GDT_UDATA|3));
  10128f:	b8 23 00 00 00       	mov    $0x23,%eax
  101294:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (CPU_GDT_KDATA));
  101296:	b8 10 00 00 00       	mov    $0x10,%eax
  10129b:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (CPU_GDT_KDATA));
  10129d:	b8 10 00 00 00       	mov    $0x10,%eax
  1012a2:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (CPU_GDT_KDATA));
  1012a4:	b8 10 00 00 00       	mov    $0x10,%eax
  1012a9:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (CPU_GDT_KCODE));
  1012ab:	ea b2 12 10 00 08 00 	ljmp   $0x8,$0x1012b2
	// reload CS

	c->gdt[CPU_GDT_TSS >> 3] = SEGDESC16(0, STS_T32A, 
  1012b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012b5:	83 c0 38             	add    $0x38,%eax
  1012b8:	89 c3                	mov    %eax,%ebx
  1012ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012bd:	83 c0 38             	add    $0x38,%eax
  1012c0:	c1 e8 10             	shr    $0x10,%eax
  1012c3:	89 c1                	mov    %eax,%ecx
  1012c5:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012c8:	83 c0 38             	add    $0x38,%eax
  1012cb:	c1 e8 18             	shr    $0x18,%eax
  1012ce:	89 c2                	mov    %eax,%edx
  1012d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012d3:	66 c7 40 30 67 00    	movw   $0x67,0x30(%eax)
  1012d9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012dc:	66 89 58 32          	mov    %bx,0x32(%eax)
  1012e0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012e3:	88 48 34             	mov    %cl,0x34(%eax)
  1012e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012e9:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1012ed:	83 e1 f0             	and    $0xfffffff0,%ecx
  1012f0:	83 c9 09             	or     $0x9,%ecx
  1012f3:	88 48 35             	mov    %cl,0x35(%eax)
  1012f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1012f9:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  1012fd:	83 e1 ef             	and    $0xffffffef,%ecx
  101300:	88 48 35             	mov    %cl,0x35(%eax)
  101303:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101306:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  10130a:	83 e1 9f             	and    $0xffffff9f,%ecx
  10130d:	88 48 35             	mov    %cl,0x35(%eax)
  101310:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101313:	0f b6 48 35          	movzbl 0x35(%eax),%ecx
  101317:	83 c9 80             	or     $0xffffff80,%ecx
  10131a:	88 48 35             	mov    %cl,0x35(%eax)
  10131d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101320:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101324:	83 e1 f0             	and    $0xfffffff0,%ecx
  101327:	88 48 36             	mov    %cl,0x36(%eax)
  10132a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10132d:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101331:	83 e1 ef             	and    $0xffffffef,%ecx
  101334:	88 48 36             	mov    %cl,0x36(%eax)
  101337:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10133a:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10133e:	83 e1 df             	and    $0xffffffdf,%ecx
  101341:	88 48 36             	mov    %cl,0x36(%eax)
  101344:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101347:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  10134b:	83 c9 40             	or     $0x40,%ecx
  10134e:	88 48 36             	mov    %cl,0x36(%eax)
  101351:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101354:	0f b6 48 36          	movzbl 0x36(%eax),%ecx
  101358:	83 e1 7f             	and    $0x7f,%ecx
  10135b:	88 48 36             	mov    %cl,0x36(%eax)
  10135e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101361:	88 50 37             	mov    %dl,0x37(%eax)
			(uintptr_t)(&(c->tss)), sizeof(taskstate)-1, 0);
	c->tss.ts_esp0 = (uintptr_t)(c->kstackhi);
  101364:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101367:	05 00 10 00 00       	add    $0x1000,%eax
  10136c:	89 c2                	mov    %eax,%edx
  10136e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101371:	89 50 3c             	mov    %edx,0x3c(%eax)
	c->tss.ts_ss0 = CPU_GDT_KDATA;
  101374:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101377:	66 c7 40 40 10 00    	movw   $0x10,0x40(%eax)
  10137d:	66 c7 45 f6 30 00    	movw   $0x30,-0xa(%ebp)
}

static gcc_inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
  101383:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
  101387:	0f 00 d8             	ltr    %ax
	ltr(CPU_GDT_TSS);

	// We don't need an LDT.
	asm volatile("lldt %%ax" :: "a" (0));
  10138a:	b8 00 00 00 00       	mov    $0x0,%eax
  10138f:	0f 00 d0             	lldt   %ax
	cprintf("cpu_init complete\n");
  101392:	c7 04 24 c3 87 10 00 	movl   $0x1087c3,(%esp)
  101399:	e8 df 68 00 00       	call   107c7d <cprintf>
}
  10139e:	83 c4 24             	add    $0x24,%esp
  1013a1:	5b                   	pop    %ebx
  1013a2:	5d                   	pop    %ebp
  1013a3:	c3                   	ret    

001013a4 <cpu_alloc>:

// Allocate an additional cpu struct representing a non-bootstrap processor.
cpu *
cpu_alloc(void)
{
  1013a4:	55                   	push   %ebp
  1013a5:	89 e5                	mov    %esp,%ebp
  1013a7:	83 ec 28             	sub    $0x28,%esp
	// Pointer to the cpu.next pointer of the last CPU on the list,
	// for chaining on new CPUs in cpu_alloc().  Note: static.
	static cpu **cpu_tail = &cpu_boot.next;

	pageinfo *pi = mem_alloc();
  1013aa:	e8 aa f8 ff ff       	call   100c59 <mem_alloc>
  1013af:	89 45 f0             	mov    %eax,-0x10(%ebp)
	assert(pi != 0);	// shouldn't be out of memory just yet!
  1013b2:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1013b6:	75 24                	jne    1013dc <cpu_alloc+0x38>
  1013b8:	c7 44 24 0c d6 87 10 	movl   $0x1087d6,0xc(%esp)
  1013bf:	00 
  1013c0:	c7 44 24 08 a1 87 10 	movl   $0x1087a1,0x8(%esp)
  1013c7:	00 
  1013c8:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1013cf:	00 
  1013d0:	c7 04 24 de 87 10 00 	movl   $0x1087de,(%esp)
  1013d7:	e8 dc f0 ff ff       	call   1004b8 <debug_panic>

	cpu *c = (cpu*) mem_pi2ptr(pi);
  1013dc:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1013df:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1013e4:	89 d1                	mov    %edx,%ecx
  1013e6:	29 c1                	sub    %eax,%ecx
  1013e8:	89 c8                	mov    %ecx,%eax
  1013ea:	c1 f8 03             	sar    $0x3,%eax
  1013ed:	c1 e0 0c             	shl    $0xc,%eax
  1013f0:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// Clear the whole page for good measure: cpu struct and kernel stack
	memset(c, 0, PAGESIZE);
  1013f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1013fa:	00 
  1013fb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  101402:	00 
  101403:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101406:	89 04 24             	mov    %eax,(%esp)
  101409:	e8 56 6a 00 00       	call   107e64 <memset>
	// when it starts up and calls cpu_init().

	// Initialize the new cpu's GDT by copying from the cpu_boot.
	// The TSS descriptor will be filled in later by cpu_init().
	assert(sizeof(c->gdt) == sizeof(segdesc) * CPU_GDT_NDESC);
	memmove(c->gdt, cpu_boot.gdt, sizeof(c->gdt));
  10140e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101411:	c7 44 24 08 38 00 00 	movl   $0x38,0x8(%esp)
  101418:	00 
  101419:	c7 44 24 04 00 b0 10 	movl   $0x10b000,0x4(%esp)
  101420:	00 
  101421:	89 04 24             	mov    %eax,(%esp)
  101424:	e8 af 6a 00 00       	call   107ed8 <memmove>

	// Magic verification tag for stack overflow/cpu corruption checking
	c->magic = CPU_MAGIC;
  101429:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10142c:	c7 80 b8 00 00 00 32 	movl   $0x98765432,0xb8(%eax)
  101433:	54 76 98 

	// Chain the new CPU onto the tail of the list.
	*cpu_tail = c;
  101436:	a1 00 c0 10 00       	mov    0x10c000,%eax
  10143b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10143e:	89 10                	mov    %edx,(%eax)
	cpu_tail = &c->next;
  101440:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101443:	05 a8 00 00 00       	add    $0xa8,%eax
  101448:	a3 00 c0 10 00       	mov    %eax,0x10c000

	return c;
  10144d:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  101450:	c9                   	leave  
  101451:	c3                   	ret    

00101452 <cpu_bootothers>:

void
cpu_bootothers(void)
{
  101452:	55                   	push   %ebp
  101453:	89 e5                	mov    %esp,%ebp
  101455:	83 ec 28             	sub    $0x28,%esp
	extern uint8_t _binary_obj_boot_bootother_start[],
			_binary_obj_boot_bootother_size[];

	if (!cpu_onboot()) {
  101458:	e8 f4 fd ff ff       	call   101251 <cpu_onboot>
  10145d:	85 c0                	test   %eax,%eax
  10145f:	75 1f                	jne    101480 <cpu_bootothers+0x2e>
		// Just inform the boot cpu we've booted.
		xchg(&cpu_cur()->booted, 1);
  101461:	e8 98 fd ff ff       	call   1011fe <cpu_cur>
  101466:	05 b0 00 00 00       	add    $0xb0,%eax
  10146b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  101472:	00 
  101473:	89 04 24             	mov    %eax,(%esp)
  101476:	e8 69 fd ff ff       	call   1011e4 <xchg>
		return;
  10147b:	e9 91 00 00 00       	jmp    101511 <cpu_bootothers+0xbf>
	}

	// Write bootstrap code to unused memory at 0x1000.
	uint8_t *code = (uint8_t*)0x1000;
  101480:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
	memmove(code, _binary_obj_boot_bootother_start,
  101487:	b8 6a 00 00 00       	mov    $0x6a,%eax
  10148c:	89 44 24 08          	mov    %eax,0x8(%esp)
  101490:	c7 44 24 04 ac 83 11 	movl   $0x1183ac,0x4(%esp)
  101497:	00 
  101498:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10149b:	89 04 24             	mov    %eax,(%esp)
  10149e:	e8 35 6a 00 00       	call   107ed8 <memmove>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1014a3:	c7 45 f4 00 b0 10 00 	movl   $0x10b000,-0xc(%ebp)
  1014aa:	eb 5f                	jmp    10150b <cpu_bootothers+0xb9>
		if(c == cpu_cur())  // We''ve started already.
  1014ac:	e8 4d fd ff ff       	call   1011fe <cpu_cur>
  1014b1:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1014b4:	74 48                	je     1014fe <cpu_bootothers+0xac>
			continue;

		// Fill in %esp, %eip and start code on cpu.
		*(void**)(code-4) = c->kstackhi;
  1014b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014b9:	83 e8 04             	sub    $0x4,%eax
  1014bc:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1014bf:	81 c2 00 10 00 00    	add    $0x1000,%edx
  1014c5:	89 10                	mov    %edx,(%eax)
		*(void**)(code-8) = init;
  1014c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1014ca:	83 e8 08             	sub    $0x8,%eax
  1014cd:	c7 00 93 00 10 00    	movl   $0x100093,(%eax)
		lapic_startcpu(c->id, (uint32_t)code);
  1014d3:	8b 55 f0             	mov    -0x10(%ebp),%edx
  1014d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014d9:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1014e0:	0f b6 c0             	movzbl %al,%eax
  1014e3:	89 54 24 04          	mov    %edx,0x4(%esp)
  1014e7:	89 04 24             	mov    %eax,(%esp)
  1014ea:	e8 85 5d 00 00       	call   107274 <lapic_startcpu>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
  1014ef:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1014f2:	8b 80 b0 00 00 00    	mov    0xb0(%eax),%eax
  1014f8:	85 c0                	test   %eax,%eax
  1014fa:	74 f3                	je     1014ef <cpu_bootothers+0x9d>
  1014fc:	eb 01                	jmp    1014ff <cpu_bootothers+0xad>
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
		if(c == cpu_cur())  // We''ve started already.
			continue;
  1014fe:	90                   	nop
	uint8_t *code = (uint8_t*)0x1000;
	memmove(code, _binary_obj_boot_bootother_start,
		(uint32_t)_binary_obj_boot_bootother_size);

	cpu *c;
	for(c = &cpu_boot; c; c = c->next){
  1014ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
  101502:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
  101508:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10150b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  10150f:	75 9b                	jne    1014ac <cpu_bootothers+0x5a>

		// Wait for cpu to get through bootstrap.
		while(c->booted == 0)
			;
	}
}
  101511:	c9                   	leave  
  101512:	c3                   	ret    
  101513:	90                   	nop

00101514 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  101514:	55                   	push   %ebp
  101515:	89 e5                	mov    %esp,%ebp
  101517:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  10151a:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10151d:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  101520:	89 45 f0             	mov    %eax,-0x10(%ebp)
  101523:	8b 45 f0             	mov    -0x10(%ebp),%eax
  101526:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  10152b:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10152e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  101531:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  101537:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10153c:	74 24                	je     101562 <cpu_cur+0x4e>
  10153e:	c7 44 24 0c 00 88 10 	movl   $0x108800,0xc(%esp)
  101545:	00 
  101546:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  10154d:	00 
  10154e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  101555:	00 
  101556:	c7 04 24 2b 88 10 00 	movl   $0x10882b,(%esp)
  10155d:	e8 56 ef ff ff       	call   1004b8 <debug_panic>
	return c;
  101562:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  101565:	c9                   	leave  
  101566:	c3                   	ret    

00101567 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  101567:	55                   	push   %ebp
  101568:	89 e5                	mov    %esp,%ebp
  10156a:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10156d:	e8 a2 ff ff ff       	call   101514 <cpu_cur>
  101572:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  101577:	0f 94 c0             	sete   %al
  10157a:	0f b6 c0             	movzbl %al,%eax
}
  10157d:	c9                   	leave  
  10157e:	c3                   	ret    

0010157f <trap_init_idt>:
};


static void
trap_init_idt(void)
{
  10157f:	55                   	push   %ebp
  101580:	89 e5                	mov    %esp,%ebp
  101582:	83 ec 18             	sub    $0x18,%esp
	extern void (*tv49)(void);
	extern void (*tv50)(void);
	extern void (*tv500)(void);
	extern void (*tv501)(void);

	cprintf("initializing idt\n");
  101585:	c7 04 24 38 88 10 00 	movl   $0x108838,(%esp)
  10158c:	e8 ec 66 00 00       	call   107c7d <cprintf>
	SETGATE(idt[0], 0, CPU_GDT_KCODE, &tv0, 0);
  101591:	b8 c0 27 10 00       	mov    $0x1027c0,%eax
  101596:	66 a3 20 a2 11 00    	mov    %ax,0x11a220
  10159c:	66 c7 05 22 a2 11 00 	movw   $0x8,0x11a222
  1015a3:	08 00 
  1015a5:	0f b6 05 24 a2 11 00 	movzbl 0x11a224,%eax
  1015ac:	83 e0 e0             	and    $0xffffffe0,%eax
  1015af:	a2 24 a2 11 00       	mov    %al,0x11a224
  1015b4:	0f b6 05 24 a2 11 00 	movzbl 0x11a224,%eax
  1015bb:	83 e0 1f             	and    $0x1f,%eax
  1015be:	a2 24 a2 11 00       	mov    %al,0x11a224
  1015c3:	0f b6 05 25 a2 11 00 	movzbl 0x11a225,%eax
  1015ca:	83 e0 f0             	and    $0xfffffff0,%eax
  1015cd:	83 c8 0e             	or     $0xe,%eax
  1015d0:	a2 25 a2 11 00       	mov    %al,0x11a225
  1015d5:	0f b6 05 25 a2 11 00 	movzbl 0x11a225,%eax
  1015dc:	83 e0 ef             	and    $0xffffffef,%eax
  1015df:	a2 25 a2 11 00       	mov    %al,0x11a225
  1015e4:	0f b6 05 25 a2 11 00 	movzbl 0x11a225,%eax
  1015eb:	83 e0 9f             	and    $0xffffff9f,%eax
  1015ee:	a2 25 a2 11 00       	mov    %al,0x11a225
  1015f3:	0f b6 05 25 a2 11 00 	movzbl 0x11a225,%eax
  1015fa:	83 c8 80             	or     $0xffffff80,%eax
  1015fd:	a2 25 a2 11 00       	mov    %al,0x11a225
  101602:	b8 c0 27 10 00       	mov    $0x1027c0,%eax
  101607:	c1 e8 10             	shr    $0x10,%eax
  10160a:	66 a3 26 a2 11 00    	mov    %ax,0x11a226
	SETGATE(idt[2], 0, CPU_GDT_KCODE, &tv2, 0);
  101610:	b8 ca 27 10 00       	mov    $0x1027ca,%eax
  101615:	66 a3 30 a2 11 00    	mov    %ax,0x11a230
  10161b:	66 c7 05 32 a2 11 00 	movw   $0x8,0x11a232
  101622:	08 00 
  101624:	0f b6 05 34 a2 11 00 	movzbl 0x11a234,%eax
  10162b:	83 e0 e0             	and    $0xffffffe0,%eax
  10162e:	a2 34 a2 11 00       	mov    %al,0x11a234
  101633:	0f b6 05 34 a2 11 00 	movzbl 0x11a234,%eax
  10163a:	83 e0 1f             	and    $0x1f,%eax
  10163d:	a2 34 a2 11 00       	mov    %al,0x11a234
  101642:	0f b6 05 35 a2 11 00 	movzbl 0x11a235,%eax
  101649:	83 e0 f0             	and    $0xfffffff0,%eax
  10164c:	83 c8 0e             	or     $0xe,%eax
  10164f:	a2 35 a2 11 00       	mov    %al,0x11a235
  101654:	0f b6 05 35 a2 11 00 	movzbl 0x11a235,%eax
  10165b:	83 e0 ef             	and    $0xffffffef,%eax
  10165e:	a2 35 a2 11 00       	mov    %al,0x11a235
  101663:	0f b6 05 35 a2 11 00 	movzbl 0x11a235,%eax
  10166a:	83 e0 9f             	and    $0xffffff9f,%eax
  10166d:	a2 35 a2 11 00       	mov    %al,0x11a235
  101672:	0f b6 05 35 a2 11 00 	movzbl 0x11a235,%eax
  101679:	83 c8 80             	or     $0xffffff80,%eax
  10167c:	a2 35 a2 11 00       	mov    %al,0x11a235
  101681:	b8 ca 27 10 00       	mov    $0x1027ca,%eax
  101686:	c1 e8 10             	shr    $0x10,%eax
  101689:	66 a3 36 a2 11 00    	mov    %ax,0x11a236
	SETGATE(idt[3], 0, CPU_GDT_KCODE, &tv3, 3);
  10168f:	b8 d4 27 10 00       	mov    $0x1027d4,%eax
  101694:	66 a3 38 a2 11 00    	mov    %ax,0x11a238
  10169a:	66 c7 05 3a a2 11 00 	movw   $0x8,0x11a23a
  1016a1:	08 00 
  1016a3:	0f b6 05 3c a2 11 00 	movzbl 0x11a23c,%eax
  1016aa:	83 e0 e0             	and    $0xffffffe0,%eax
  1016ad:	a2 3c a2 11 00       	mov    %al,0x11a23c
  1016b2:	0f b6 05 3c a2 11 00 	movzbl 0x11a23c,%eax
  1016b9:	83 e0 1f             	and    $0x1f,%eax
  1016bc:	a2 3c a2 11 00       	mov    %al,0x11a23c
  1016c1:	0f b6 05 3d a2 11 00 	movzbl 0x11a23d,%eax
  1016c8:	83 e0 f0             	and    $0xfffffff0,%eax
  1016cb:	83 c8 0e             	or     $0xe,%eax
  1016ce:	a2 3d a2 11 00       	mov    %al,0x11a23d
  1016d3:	0f b6 05 3d a2 11 00 	movzbl 0x11a23d,%eax
  1016da:	83 e0 ef             	and    $0xffffffef,%eax
  1016dd:	a2 3d a2 11 00       	mov    %al,0x11a23d
  1016e2:	0f b6 05 3d a2 11 00 	movzbl 0x11a23d,%eax
  1016e9:	83 c8 60             	or     $0x60,%eax
  1016ec:	a2 3d a2 11 00       	mov    %al,0x11a23d
  1016f1:	0f b6 05 3d a2 11 00 	movzbl 0x11a23d,%eax
  1016f8:	83 c8 80             	or     $0xffffff80,%eax
  1016fb:	a2 3d a2 11 00       	mov    %al,0x11a23d
  101700:	b8 d4 27 10 00       	mov    $0x1027d4,%eax
  101705:	c1 e8 10             	shr    $0x10,%eax
  101708:	66 a3 3e a2 11 00    	mov    %ax,0x11a23e
	SETGATE(idt[4], 0, CPU_GDT_KCODE, &tv4, 3);
  10170e:	b8 de 27 10 00       	mov    $0x1027de,%eax
  101713:	66 a3 40 a2 11 00    	mov    %ax,0x11a240
  101719:	66 c7 05 42 a2 11 00 	movw   $0x8,0x11a242
  101720:	08 00 
  101722:	0f b6 05 44 a2 11 00 	movzbl 0x11a244,%eax
  101729:	83 e0 e0             	and    $0xffffffe0,%eax
  10172c:	a2 44 a2 11 00       	mov    %al,0x11a244
  101731:	0f b6 05 44 a2 11 00 	movzbl 0x11a244,%eax
  101738:	83 e0 1f             	and    $0x1f,%eax
  10173b:	a2 44 a2 11 00       	mov    %al,0x11a244
  101740:	0f b6 05 45 a2 11 00 	movzbl 0x11a245,%eax
  101747:	83 e0 f0             	and    $0xfffffff0,%eax
  10174a:	83 c8 0e             	or     $0xe,%eax
  10174d:	a2 45 a2 11 00       	mov    %al,0x11a245
  101752:	0f b6 05 45 a2 11 00 	movzbl 0x11a245,%eax
  101759:	83 e0 ef             	and    $0xffffffef,%eax
  10175c:	a2 45 a2 11 00       	mov    %al,0x11a245
  101761:	0f b6 05 45 a2 11 00 	movzbl 0x11a245,%eax
  101768:	83 c8 60             	or     $0x60,%eax
  10176b:	a2 45 a2 11 00       	mov    %al,0x11a245
  101770:	0f b6 05 45 a2 11 00 	movzbl 0x11a245,%eax
  101777:	83 c8 80             	or     $0xffffff80,%eax
  10177a:	a2 45 a2 11 00       	mov    %al,0x11a245
  10177f:	b8 de 27 10 00       	mov    $0x1027de,%eax
  101784:	c1 e8 10             	shr    $0x10,%eax
  101787:	66 a3 46 a2 11 00    	mov    %ax,0x11a246
	SETGATE(idt[5], 0, CPU_GDT_KCODE, &tv5, 0);
  10178d:	b8 e8 27 10 00       	mov    $0x1027e8,%eax
  101792:	66 a3 48 a2 11 00    	mov    %ax,0x11a248
  101798:	66 c7 05 4a a2 11 00 	movw   $0x8,0x11a24a
  10179f:	08 00 
  1017a1:	0f b6 05 4c a2 11 00 	movzbl 0x11a24c,%eax
  1017a8:	83 e0 e0             	and    $0xffffffe0,%eax
  1017ab:	a2 4c a2 11 00       	mov    %al,0x11a24c
  1017b0:	0f b6 05 4c a2 11 00 	movzbl 0x11a24c,%eax
  1017b7:	83 e0 1f             	and    $0x1f,%eax
  1017ba:	a2 4c a2 11 00       	mov    %al,0x11a24c
  1017bf:	0f b6 05 4d a2 11 00 	movzbl 0x11a24d,%eax
  1017c6:	83 e0 f0             	and    $0xfffffff0,%eax
  1017c9:	83 c8 0e             	or     $0xe,%eax
  1017cc:	a2 4d a2 11 00       	mov    %al,0x11a24d
  1017d1:	0f b6 05 4d a2 11 00 	movzbl 0x11a24d,%eax
  1017d8:	83 e0 ef             	and    $0xffffffef,%eax
  1017db:	a2 4d a2 11 00       	mov    %al,0x11a24d
  1017e0:	0f b6 05 4d a2 11 00 	movzbl 0x11a24d,%eax
  1017e7:	83 e0 9f             	and    $0xffffff9f,%eax
  1017ea:	a2 4d a2 11 00       	mov    %al,0x11a24d
  1017ef:	0f b6 05 4d a2 11 00 	movzbl 0x11a24d,%eax
  1017f6:	83 c8 80             	or     $0xffffff80,%eax
  1017f9:	a2 4d a2 11 00       	mov    %al,0x11a24d
  1017fe:	b8 e8 27 10 00       	mov    $0x1027e8,%eax
  101803:	c1 e8 10             	shr    $0x10,%eax
  101806:	66 a3 4e a2 11 00    	mov    %ax,0x11a24e
	SETGATE(idt[6], 0, CPU_GDT_KCODE, &tv6, 0);
  10180c:	b8 f2 27 10 00       	mov    $0x1027f2,%eax
  101811:	66 a3 50 a2 11 00    	mov    %ax,0x11a250
  101817:	66 c7 05 52 a2 11 00 	movw   $0x8,0x11a252
  10181e:	08 00 
  101820:	0f b6 05 54 a2 11 00 	movzbl 0x11a254,%eax
  101827:	83 e0 e0             	and    $0xffffffe0,%eax
  10182a:	a2 54 a2 11 00       	mov    %al,0x11a254
  10182f:	0f b6 05 54 a2 11 00 	movzbl 0x11a254,%eax
  101836:	83 e0 1f             	and    $0x1f,%eax
  101839:	a2 54 a2 11 00       	mov    %al,0x11a254
  10183e:	0f b6 05 55 a2 11 00 	movzbl 0x11a255,%eax
  101845:	83 e0 f0             	and    $0xfffffff0,%eax
  101848:	83 c8 0e             	or     $0xe,%eax
  10184b:	a2 55 a2 11 00       	mov    %al,0x11a255
  101850:	0f b6 05 55 a2 11 00 	movzbl 0x11a255,%eax
  101857:	83 e0 ef             	and    $0xffffffef,%eax
  10185a:	a2 55 a2 11 00       	mov    %al,0x11a255
  10185f:	0f b6 05 55 a2 11 00 	movzbl 0x11a255,%eax
  101866:	83 e0 9f             	and    $0xffffff9f,%eax
  101869:	a2 55 a2 11 00       	mov    %al,0x11a255
  10186e:	0f b6 05 55 a2 11 00 	movzbl 0x11a255,%eax
  101875:	83 c8 80             	or     $0xffffff80,%eax
  101878:	a2 55 a2 11 00       	mov    %al,0x11a255
  10187d:	b8 f2 27 10 00       	mov    $0x1027f2,%eax
  101882:	c1 e8 10             	shr    $0x10,%eax
  101885:	66 a3 56 a2 11 00    	mov    %ax,0x11a256
	SETGATE(idt[7], 0, CPU_GDT_KCODE, &tv7, 0);
  10188b:	b8 fc 27 10 00       	mov    $0x1027fc,%eax
  101890:	66 a3 58 a2 11 00    	mov    %ax,0x11a258
  101896:	66 c7 05 5a a2 11 00 	movw   $0x8,0x11a25a
  10189d:	08 00 
  10189f:	0f b6 05 5c a2 11 00 	movzbl 0x11a25c,%eax
  1018a6:	83 e0 e0             	and    $0xffffffe0,%eax
  1018a9:	a2 5c a2 11 00       	mov    %al,0x11a25c
  1018ae:	0f b6 05 5c a2 11 00 	movzbl 0x11a25c,%eax
  1018b5:	83 e0 1f             	and    $0x1f,%eax
  1018b8:	a2 5c a2 11 00       	mov    %al,0x11a25c
  1018bd:	0f b6 05 5d a2 11 00 	movzbl 0x11a25d,%eax
  1018c4:	83 e0 f0             	and    $0xfffffff0,%eax
  1018c7:	83 c8 0e             	or     $0xe,%eax
  1018ca:	a2 5d a2 11 00       	mov    %al,0x11a25d
  1018cf:	0f b6 05 5d a2 11 00 	movzbl 0x11a25d,%eax
  1018d6:	83 e0 ef             	and    $0xffffffef,%eax
  1018d9:	a2 5d a2 11 00       	mov    %al,0x11a25d
  1018de:	0f b6 05 5d a2 11 00 	movzbl 0x11a25d,%eax
  1018e5:	83 e0 9f             	and    $0xffffff9f,%eax
  1018e8:	a2 5d a2 11 00       	mov    %al,0x11a25d
  1018ed:	0f b6 05 5d a2 11 00 	movzbl 0x11a25d,%eax
  1018f4:	83 c8 80             	or     $0xffffff80,%eax
  1018f7:	a2 5d a2 11 00       	mov    %al,0x11a25d
  1018fc:	b8 fc 27 10 00       	mov    $0x1027fc,%eax
  101901:	c1 e8 10             	shr    $0x10,%eax
  101904:	66 a3 5e a2 11 00    	mov    %ax,0x11a25e
	SETGATE(idt[8], 0, CPU_GDT_KCODE, &tv8, 0);
  10190a:	b8 06 28 10 00       	mov    $0x102806,%eax
  10190f:	66 a3 60 a2 11 00    	mov    %ax,0x11a260
  101915:	66 c7 05 62 a2 11 00 	movw   $0x8,0x11a262
  10191c:	08 00 
  10191e:	0f b6 05 64 a2 11 00 	movzbl 0x11a264,%eax
  101925:	83 e0 e0             	and    $0xffffffe0,%eax
  101928:	a2 64 a2 11 00       	mov    %al,0x11a264
  10192d:	0f b6 05 64 a2 11 00 	movzbl 0x11a264,%eax
  101934:	83 e0 1f             	and    $0x1f,%eax
  101937:	a2 64 a2 11 00       	mov    %al,0x11a264
  10193c:	0f b6 05 65 a2 11 00 	movzbl 0x11a265,%eax
  101943:	83 e0 f0             	and    $0xfffffff0,%eax
  101946:	83 c8 0e             	or     $0xe,%eax
  101949:	a2 65 a2 11 00       	mov    %al,0x11a265
  10194e:	0f b6 05 65 a2 11 00 	movzbl 0x11a265,%eax
  101955:	83 e0 ef             	and    $0xffffffef,%eax
  101958:	a2 65 a2 11 00       	mov    %al,0x11a265
  10195d:	0f b6 05 65 a2 11 00 	movzbl 0x11a265,%eax
  101964:	83 e0 9f             	and    $0xffffff9f,%eax
  101967:	a2 65 a2 11 00       	mov    %al,0x11a265
  10196c:	0f b6 05 65 a2 11 00 	movzbl 0x11a265,%eax
  101973:	83 c8 80             	or     $0xffffff80,%eax
  101976:	a2 65 a2 11 00       	mov    %al,0x11a265
  10197b:	b8 06 28 10 00       	mov    $0x102806,%eax
  101980:	c1 e8 10             	shr    $0x10,%eax
  101983:	66 a3 66 a2 11 00    	mov    %ax,0x11a266
	SETGATE(idt[10], 0, CPU_GDT_KCODE, &tv10, 0);
  101989:	b8 0e 28 10 00       	mov    $0x10280e,%eax
  10198e:	66 a3 70 a2 11 00    	mov    %ax,0x11a270
  101994:	66 c7 05 72 a2 11 00 	movw   $0x8,0x11a272
  10199b:	08 00 
  10199d:	0f b6 05 74 a2 11 00 	movzbl 0x11a274,%eax
  1019a4:	83 e0 e0             	and    $0xffffffe0,%eax
  1019a7:	a2 74 a2 11 00       	mov    %al,0x11a274
  1019ac:	0f b6 05 74 a2 11 00 	movzbl 0x11a274,%eax
  1019b3:	83 e0 1f             	and    $0x1f,%eax
  1019b6:	a2 74 a2 11 00       	mov    %al,0x11a274
  1019bb:	0f b6 05 75 a2 11 00 	movzbl 0x11a275,%eax
  1019c2:	83 e0 f0             	and    $0xfffffff0,%eax
  1019c5:	83 c8 0e             	or     $0xe,%eax
  1019c8:	a2 75 a2 11 00       	mov    %al,0x11a275
  1019cd:	0f b6 05 75 a2 11 00 	movzbl 0x11a275,%eax
  1019d4:	83 e0 ef             	and    $0xffffffef,%eax
  1019d7:	a2 75 a2 11 00       	mov    %al,0x11a275
  1019dc:	0f b6 05 75 a2 11 00 	movzbl 0x11a275,%eax
  1019e3:	83 e0 9f             	and    $0xffffff9f,%eax
  1019e6:	a2 75 a2 11 00       	mov    %al,0x11a275
  1019eb:	0f b6 05 75 a2 11 00 	movzbl 0x11a275,%eax
  1019f2:	83 c8 80             	or     $0xffffff80,%eax
  1019f5:	a2 75 a2 11 00       	mov    %al,0x11a275
  1019fa:	b8 0e 28 10 00       	mov    $0x10280e,%eax
  1019ff:	c1 e8 10             	shr    $0x10,%eax
  101a02:	66 a3 76 a2 11 00    	mov    %ax,0x11a276
	SETGATE(idt[11], 0, CPU_GDT_KCODE, &tv11, 0);
  101a08:	b8 16 28 10 00       	mov    $0x102816,%eax
  101a0d:	66 a3 78 a2 11 00    	mov    %ax,0x11a278
  101a13:	66 c7 05 7a a2 11 00 	movw   $0x8,0x11a27a
  101a1a:	08 00 
  101a1c:	0f b6 05 7c a2 11 00 	movzbl 0x11a27c,%eax
  101a23:	83 e0 e0             	and    $0xffffffe0,%eax
  101a26:	a2 7c a2 11 00       	mov    %al,0x11a27c
  101a2b:	0f b6 05 7c a2 11 00 	movzbl 0x11a27c,%eax
  101a32:	83 e0 1f             	and    $0x1f,%eax
  101a35:	a2 7c a2 11 00       	mov    %al,0x11a27c
  101a3a:	0f b6 05 7d a2 11 00 	movzbl 0x11a27d,%eax
  101a41:	83 e0 f0             	and    $0xfffffff0,%eax
  101a44:	83 c8 0e             	or     $0xe,%eax
  101a47:	a2 7d a2 11 00       	mov    %al,0x11a27d
  101a4c:	0f b6 05 7d a2 11 00 	movzbl 0x11a27d,%eax
  101a53:	83 e0 ef             	and    $0xffffffef,%eax
  101a56:	a2 7d a2 11 00       	mov    %al,0x11a27d
  101a5b:	0f b6 05 7d a2 11 00 	movzbl 0x11a27d,%eax
  101a62:	83 e0 9f             	and    $0xffffff9f,%eax
  101a65:	a2 7d a2 11 00       	mov    %al,0x11a27d
  101a6a:	0f b6 05 7d a2 11 00 	movzbl 0x11a27d,%eax
  101a71:	83 c8 80             	or     $0xffffff80,%eax
  101a74:	a2 7d a2 11 00       	mov    %al,0x11a27d
  101a79:	b8 16 28 10 00       	mov    $0x102816,%eax
  101a7e:	c1 e8 10             	shr    $0x10,%eax
  101a81:	66 a3 7e a2 11 00    	mov    %ax,0x11a27e
	SETGATE(idt[12], 0, CPU_GDT_KCODE, &tv12, 0);
  101a87:	b8 1e 28 10 00       	mov    $0x10281e,%eax
  101a8c:	66 a3 80 a2 11 00    	mov    %ax,0x11a280
  101a92:	66 c7 05 82 a2 11 00 	movw   $0x8,0x11a282
  101a99:	08 00 
  101a9b:	0f b6 05 84 a2 11 00 	movzbl 0x11a284,%eax
  101aa2:	83 e0 e0             	and    $0xffffffe0,%eax
  101aa5:	a2 84 a2 11 00       	mov    %al,0x11a284
  101aaa:	0f b6 05 84 a2 11 00 	movzbl 0x11a284,%eax
  101ab1:	83 e0 1f             	and    $0x1f,%eax
  101ab4:	a2 84 a2 11 00       	mov    %al,0x11a284
  101ab9:	0f b6 05 85 a2 11 00 	movzbl 0x11a285,%eax
  101ac0:	83 e0 f0             	and    $0xfffffff0,%eax
  101ac3:	83 c8 0e             	or     $0xe,%eax
  101ac6:	a2 85 a2 11 00       	mov    %al,0x11a285
  101acb:	0f b6 05 85 a2 11 00 	movzbl 0x11a285,%eax
  101ad2:	83 e0 ef             	and    $0xffffffef,%eax
  101ad5:	a2 85 a2 11 00       	mov    %al,0x11a285
  101ada:	0f b6 05 85 a2 11 00 	movzbl 0x11a285,%eax
  101ae1:	83 e0 9f             	and    $0xffffff9f,%eax
  101ae4:	a2 85 a2 11 00       	mov    %al,0x11a285
  101ae9:	0f b6 05 85 a2 11 00 	movzbl 0x11a285,%eax
  101af0:	83 c8 80             	or     $0xffffff80,%eax
  101af3:	a2 85 a2 11 00       	mov    %al,0x11a285
  101af8:	b8 1e 28 10 00       	mov    $0x10281e,%eax
  101afd:	c1 e8 10             	shr    $0x10,%eax
  101b00:	66 a3 86 a2 11 00    	mov    %ax,0x11a286
	SETGATE(idt[13], 0, CPU_GDT_KCODE, &tv13, 0);
  101b06:	b8 26 28 10 00       	mov    $0x102826,%eax
  101b0b:	66 a3 88 a2 11 00    	mov    %ax,0x11a288
  101b11:	66 c7 05 8a a2 11 00 	movw   $0x8,0x11a28a
  101b18:	08 00 
  101b1a:	0f b6 05 8c a2 11 00 	movzbl 0x11a28c,%eax
  101b21:	83 e0 e0             	and    $0xffffffe0,%eax
  101b24:	a2 8c a2 11 00       	mov    %al,0x11a28c
  101b29:	0f b6 05 8c a2 11 00 	movzbl 0x11a28c,%eax
  101b30:	83 e0 1f             	and    $0x1f,%eax
  101b33:	a2 8c a2 11 00       	mov    %al,0x11a28c
  101b38:	0f b6 05 8d a2 11 00 	movzbl 0x11a28d,%eax
  101b3f:	83 e0 f0             	and    $0xfffffff0,%eax
  101b42:	83 c8 0e             	or     $0xe,%eax
  101b45:	a2 8d a2 11 00       	mov    %al,0x11a28d
  101b4a:	0f b6 05 8d a2 11 00 	movzbl 0x11a28d,%eax
  101b51:	83 e0 ef             	and    $0xffffffef,%eax
  101b54:	a2 8d a2 11 00       	mov    %al,0x11a28d
  101b59:	0f b6 05 8d a2 11 00 	movzbl 0x11a28d,%eax
  101b60:	83 e0 9f             	and    $0xffffff9f,%eax
  101b63:	a2 8d a2 11 00       	mov    %al,0x11a28d
  101b68:	0f b6 05 8d a2 11 00 	movzbl 0x11a28d,%eax
  101b6f:	83 c8 80             	or     $0xffffff80,%eax
  101b72:	a2 8d a2 11 00       	mov    %al,0x11a28d
  101b77:	b8 26 28 10 00       	mov    $0x102826,%eax
  101b7c:	c1 e8 10             	shr    $0x10,%eax
  101b7f:	66 a3 8e a2 11 00    	mov    %ax,0x11a28e
	SETGATE(idt[14], 0, CPU_GDT_KCODE, &tv14, 0);
  101b85:	b8 2e 28 10 00       	mov    $0x10282e,%eax
  101b8a:	66 a3 90 a2 11 00    	mov    %ax,0x11a290
  101b90:	66 c7 05 92 a2 11 00 	movw   $0x8,0x11a292
  101b97:	08 00 
  101b99:	0f b6 05 94 a2 11 00 	movzbl 0x11a294,%eax
  101ba0:	83 e0 e0             	and    $0xffffffe0,%eax
  101ba3:	a2 94 a2 11 00       	mov    %al,0x11a294
  101ba8:	0f b6 05 94 a2 11 00 	movzbl 0x11a294,%eax
  101baf:	83 e0 1f             	and    $0x1f,%eax
  101bb2:	a2 94 a2 11 00       	mov    %al,0x11a294
  101bb7:	0f b6 05 95 a2 11 00 	movzbl 0x11a295,%eax
  101bbe:	83 e0 f0             	and    $0xfffffff0,%eax
  101bc1:	83 c8 0e             	or     $0xe,%eax
  101bc4:	a2 95 a2 11 00       	mov    %al,0x11a295
  101bc9:	0f b6 05 95 a2 11 00 	movzbl 0x11a295,%eax
  101bd0:	83 e0 ef             	and    $0xffffffef,%eax
  101bd3:	a2 95 a2 11 00       	mov    %al,0x11a295
  101bd8:	0f b6 05 95 a2 11 00 	movzbl 0x11a295,%eax
  101bdf:	83 e0 9f             	and    $0xffffff9f,%eax
  101be2:	a2 95 a2 11 00       	mov    %al,0x11a295
  101be7:	0f b6 05 95 a2 11 00 	movzbl 0x11a295,%eax
  101bee:	83 c8 80             	or     $0xffffff80,%eax
  101bf1:	a2 95 a2 11 00       	mov    %al,0x11a295
  101bf6:	b8 2e 28 10 00       	mov    $0x10282e,%eax
  101bfb:	c1 e8 10             	shr    $0x10,%eax
  101bfe:	66 a3 96 a2 11 00    	mov    %ax,0x11a296
	SETGATE(idt[16], 0, CPU_GDT_KCODE, &tv16, 0);
  101c04:	b8 36 28 10 00       	mov    $0x102836,%eax
  101c09:	66 a3 a0 a2 11 00    	mov    %ax,0x11a2a0
  101c0f:	66 c7 05 a2 a2 11 00 	movw   $0x8,0x11a2a2
  101c16:	08 00 
  101c18:	0f b6 05 a4 a2 11 00 	movzbl 0x11a2a4,%eax
  101c1f:	83 e0 e0             	and    $0xffffffe0,%eax
  101c22:	a2 a4 a2 11 00       	mov    %al,0x11a2a4
  101c27:	0f b6 05 a4 a2 11 00 	movzbl 0x11a2a4,%eax
  101c2e:	83 e0 1f             	and    $0x1f,%eax
  101c31:	a2 a4 a2 11 00       	mov    %al,0x11a2a4
  101c36:	0f b6 05 a5 a2 11 00 	movzbl 0x11a2a5,%eax
  101c3d:	83 e0 f0             	and    $0xfffffff0,%eax
  101c40:	83 c8 0e             	or     $0xe,%eax
  101c43:	a2 a5 a2 11 00       	mov    %al,0x11a2a5
  101c48:	0f b6 05 a5 a2 11 00 	movzbl 0x11a2a5,%eax
  101c4f:	83 e0 ef             	and    $0xffffffef,%eax
  101c52:	a2 a5 a2 11 00       	mov    %al,0x11a2a5
  101c57:	0f b6 05 a5 a2 11 00 	movzbl 0x11a2a5,%eax
  101c5e:	83 e0 9f             	and    $0xffffff9f,%eax
  101c61:	a2 a5 a2 11 00       	mov    %al,0x11a2a5
  101c66:	0f b6 05 a5 a2 11 00 	movzbl 0x11a2a5,%eax
  101c6d:	83 c8 80             	or     $0xffffff80,%eax
  101c70:	a2 a5 a2 11 00       	mov    %al,0x11a2a5
  101c75:	b8 36 28 10 00       	mov    $0x102836,%eax
  101c7a:	c1 e8 10             	shr    $0x10,%eax
  101c7d:	66 a3 a6 a2 11 00    	mov    %ax,0x11a2a6
	SETGATE(idt[17], 0, CPU_GDT_KCODE, &tv17, 0);
  101c83:	b8 40 28 10 00       	mov    $0x102840,%eax
  101c88:	66 a3 a8 a2 11 00    	mov    %ax,0x11a2a8
  101c8e:	66 c7 05 aa a2 11 00 	movw   $0x8,0x11a2aa
  101c95:	08 00 
  101c97:	0f b6 05 ac a2 11 00 	movzbl 0x11a2ac,%eax
  101c9e:	83 e0 e0             	and    $0xffffffe0,%eax
  101ca1:	a2 ac a2 11 00       	mov    %al,0x11a2ac
  101ca6:	0f b6 05 ac a2 11 00 	movzbl 0x11a2ac,%eax
  101cad:	83 e0 1f             	and    $0x1f,%eax
  101cb0:	a2 ac a2 11 00       	mov    %al,0x11a2ac
  101cb5:	0f b6 05 ad a2 11 00 	movzbl 0x11a2ad,%eax
  101cbc:	83 e0 f0             	and    $0xfffffff0,%eax
  101cbf:	83 c8 0e             	or     $0xe,%eax
  101cc2:	a2 ad a2 11 00       	mov    %al,0x11a2ad
  101cc7:	0f b6 05 ad a2 11 00 	movzbl 0x11a2ad,%eax
  101cce:	83 e0 ef             	and    $0xffffffef,%eax
  101cd1:	a2 ad a2 11 00       	mov    %al,0x11a2ad
  101cd6:	0f b6 05 ad a2 11 00 	movzbl 0x11a2ad,%eax
  101cdd:	83 e0 9f             	and    $0xffffff9f,%eax
  101ce0:	a2 ad a2 11 00       	mov    %al,0x11a2ad
  101ce5:	0f b6 05 ad a2 11 00 	movzbl 0x11a2ad,%eax
  101cec:	83 c8 80             	or     $0xffffff80,%eax
  101cef:	a2 ad a2 11 00       	mov    %al,0x11a2ad
  101cf4:	b8 40 28 10 00       	mov    $0x102840,%eax
  101cf9:	c1 e8 10             	shr    $0x10,%eax
  101cfc:	66 a3 ae a2 11 00    	mov    %ax,0x11a2ae
	SETGATE(idt[18], 0, CPU_GDT_KCODE, &tv18, 0);
  101d02:	b8 48 28 10 00       	mov    $0x102848,%eax
  101d07:	66 a3 b0 a2 11 00    	mov    %ax,0x11a2b0
  101d0d:	66 c7 05 b2 a2 11 00 	movw   $0x8,0x11a2b2
  101d14:	08 00 
  101d16:	0f b6 05 b4 a2 11 00 	movzbl 0x11a2b4,%eax
  101d1d:	83 e0 e0             	and    $0xffffffe0,%eax
  101d20:	a2 b4 a2 11 00       	mov    %al,0x11a2b4
  101d25:	0f b6 05 b4 a2 11 00 	movzbl 0x11a2b4,%eax
  101d2c:	83 e0 1f             	and    $0x1f,%eax
  101d2f:	a2 b4 a2 11 00       	mov    %al,0x11a2b4
  101d34:	0f b6 05 b5 a2 11 00 	movzbl 0x11a2b5,%eax
  101d3b:	83 e0 f0             	and    $0xfffffff0,%eax
  101d3e:	83 c8 0e             	or     $0xe,%eax
  101d41:	a2 b5 a2 11 00       	mov    %al,0x11a2b5
  101d46:	0f b6 05 b5 a2 11 00 	movzbl 0x11a2b5,%eax
  101d4d:	83 e0 ef             	and    $0xffffffef,%eax
  101d50:	a2 b5 a2 11 00       	mov    %al,0x11a2b5
  101d55:	0f b6 05 b5 a2 11 00 	movzbl 0x11a2b5,%eax
  101d5c:	83 e0 9f             	and    $0xffffff9f,%eax
  101d5f:	a2 b5 a2 11 00       	mov    %al,0x11a2b5
  101d64:	0f b6 05 b5 a2 11 00 	movzbl 0x11a2b5,%eax
  101d6b:	83 c8 80             	or     $0xffffff80,%eax
  101d6e:	a2 b5 a2 11 00       	mov    %al,0x11a2b5
  101d73:	b8 48 28 10 00       	mov    $0x102848,%eax
  101d78:	c1 e8 10             	shr    $0x10,%eax
  101d7b:	66 a3 b6 a2 11 00    	mov    %ax,0x11a2b6
	SETGATE(idt[19], 0, CPU_GDT_KCODE, &tv19, 0);
  101d81:	b8 52 28 10 00       	mov    $0x102852,%eax
  101d86:	66 a3 b8 a2 11 00    	mov    %ax,0x11a2b8
  101d8c:	66 c7 05 ba a2 11 00 	movw   $0x8,0x11a2ba
  101d93:	08 00 
  101d95:	0f b6 05 bc a2 11 00 	movzbl 0x11a2bc,%eax
  101d9c:	83 e0 e0             	and    $0xffffffe0,%eax
  101d9f:	a2 bc a2 11 00       	mov    %al,0x11a2bc
  101da4:	0f b6 05 bc a2 11 00 	movzbl 0x11a2bc,%eax
  101dab:	83 e0 1f             	and    $0x1f,%eax
  101dae:	a2 bc a2 11 00       	mov    %al,0x11a2bc
  101db3:	0f b6 05 bd a2 11 00 	movzbl 0x11a2bd,%eax
  101dba:	83 e0 f0             	and    $0xfffffff0,%eax
  101dbd:	83 c8 0e             	or     $0xe,%eax
  101dc0:	a2 bd a2 11 00       	mov    %al,0x11a2bd
  101dc5:	0f b6 05 bd a2 11 00 	movzbl 0x11a2bd,%eax
  101dcc:	83 e0 ef             	and    $0xffffffef,%eax
  101dcf:	a2 bd a2 11 00       	mov    %al,0x11a2bd
  101dd4:	0f b6 05 bd a2 11 00 	movzbl 0x11a2bd,%eax
  101ddb:	83 e0 9f             	and    $0xffffff9f,%eax
  101dde:	a2 bd a2 11 00       	mov    %al,0x11a2bd
  101de3:	0f b6 05 bd a2 11 00 	movzbl 0x11a2bd,%eax
  101dea:	83 c8 80             	or     $0xffffff80,%eax
  101ded:	a2 bd a2 11 00       	mov    %al,0x11a2bd
  101df2:	b8 52 28 10 00       	mov    $0x102852,%eax
  101df7:	c1 e8 10             	shr    $0x10,%eax
  101dfa:	66 a3 be a2 11 00    	mov    %ax,0x11a2be
	SETGATE(idt[30], 0, CPU_GDT_KCODE, &tv30, 0);
  101e00:	b8 5c 28 10 00       	mov    $0x10285c,%eax
  101e05:	66 a3 10 a3 11 00    	mov    %ax,0x11a310
  101e0b:	66 c7 05 12 a3 11 00 	movw   $0x8,0x11a312
  101e12:	08 00 
  101e14:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  101e1b:	83 e0 e0             	and    $0xffffffe0,%eax
  101e1e:	a2 14 a3 11 00       	mov    %al,0x11a314
  101e23:	0f b6 05 14 a3 11 00 	movzbl 0x11a314,%eax
  101e2a:	83 e0 1f             	and    $0x1f,%eax
  101e2d:	a2 14 a3 11 00       	mov    %al,0x11a314
  101e32:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  101e39:	83 e0 f0             	and    $0xfffffff0,%eax
  101e3c:	83 c8 0e             	or     $0xe,%eax
  101e3f:	a2 15 a3 11 00       	mov    %al,0x11a315
  101e44:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  101e4b:	83 e0 ef             	and    $0xffffffef,%eax
  101e4e:	a2 15 a3 11 00       	mov    %al,0x11a315
  101e53:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  101e5a:	83 e0 9f             	and    $0xffffff9f,%eax
  101e5d:	a2 15 a3 11 00       	mov    %al,0x11a315
  101e62:	0f b6 05 15 a3 11 00 	movzbl 0x11a315,%eax
  101e69:	83 c8 80             	or     $0xffffff80,%eax
  101e6c:	a2 15 a3 11 00       	mov    %al,0x11a315
  101e71:	b8 5c 28 10 00       	mov    $0x10285c,%eax
  101e76:	c1 e8 10             	shr    $0x10,%eax
  101e79:	66 a3 16 a3 11 00    	mov    %ax,0x11a316
	SETGATE(idt[T_IRQ0 + IRQ_TIMER], 0, CPU_GDT_KCODE, &tv32, 0);
  101e7f:	b8 66 28 10 00       	mov    $0x102866,%eax
  101e84:	66 a3 20 a3 11 00    	mov    %ax,0x11a320
  101e8a:	66 c7 05 22 a3 11 00 	movw   $0x8,0x11a322
  101e91:	08 00 
  101e93:	0f b6 05 24 a3 11 00 	movzbl 0x11a324,%eax
  101e9a:	83 e0 e0             	and    $0xffffffe0,%eax
  101e9d:	a2 24 a3 11 00       	mov    %al,0x11a324
  101ea2:	0f b6 05 24 a3 11 00 	movzbl 0x11a324,%eax
  101ea9:	83 e0 1f             	and    $0x1f,%eax
  101eac:	a2 24 a3 11 00       	mov    %al,0x11a324
  101eb1:	0f b6 05 25 a3 11 00 	movzbl 0x11a325,%eax
  101eb8:	83 e0 f0             	and    $0xfffffff0,%eax
  101ebb:	83 c8 0e             	or     $0xe,%eax
  101ebe:	a2 25 a3 11 00       	mov    %al,0x11a325
  101ec3:	0f b6 05 25 a3 11 00 	movzbl 0x11a325,%eax
  101eca:	83 e0 ef             	and    $0xffffffef,%eax
  101ecd:	a2 25 a3 11 00       	mov    %al,0x11a325
  101ed2:	0f b6 05 25 a3 11 00 	movzbl 0x11a325,%eax
  101ed9:	83 e0 9f             	and    $0xffffff9f,%eax
  101edc:	a2 25 a3 11 00       	mov    %al,0x11a325
  101ee1:	0f b6 05 25 a3 11 00 	movzbl 0x11a325,%eax
  101ee8:	83 c8 80             	or     $0xffffff80,%eax
  101eeb:	a2 25 a3 11 00       	mov    %al,0x11a325
  101ef0:	b8 66 28 10 00       	mov    $0x102866,%eax
  101ef5:	c1 e8 10             	shr    $0x10,%eax
  101ef8:	66 a3 26 a3 11 00    	mov    %ax,0x11a326
	SETGATE(idt[T_IRQ0 + IRQ_SPURIOUS], 0, CPU_GDT_KCODE, &tv39, 0);
  101efe:	b8 70 28 10 00       	mov    $0x102870,%eax
  101f03:	66 a3 58 a3 11 00    	mov    %ax,0x11a358
  101f09:	66 c7 05 5a a3 11 00 	movw   $0x8,0x11a35a
  101f10:	08 00 
  101f12:	0f b6 05 5c a3 11 00 	movzbl 0x11a35c,%eax
  101f19:	83 e0 e0             	and    $0xffffffe0,%eax
  101f1c:	a2 5c a3 11 00       	mov    %al,0x11a35c
  101f21:	0f b6 05 5c a3 11 00 	movzbl 0x11a35c,%eax
  101f28:	83 e0 1f             	and    $0x1f,%eax
  101f2b:	a2 5c a3 11 00       	mov    %al,0x11a35c
  101f30:	0f b6 05 5d a3 11 00 	movzbl 0x11a35d,%eax
  101f37:	83 e0 f0             	and    $0xfffffff0,%eax
  101f3a:	83 c8 0e             	or     $0xe,%eax
  101f3d:	a2 5d a3 11 00       	mov    %al,0x11a35d
  101f42:	0f b6 05 5d a3 11 00 	movzbl 0x11a35d,%eax
  101f49:	83 e0 ef             	and    $0xffffffef,%eax
  101f4c:	a2 5d a3 11 00       	mov    %al,0x11a35d
  101f51:	0f b6 05 5d a3 11 00 	movzbl 0x11a35d,%eax
  101f58:	83 e0 9f             	and    $0xffffff9f,%eax
  101f5b:	a2 5d a3 11 00       	mov    %al,0x11a35d
  101f60:	0f b6 05 5d a3 11 00 	movzbl 0x11a35d,%eax
  101f67:	83 c8 80             	or     $0xffffff80,%eax
  101f6a:	a2 5d a3 11 00       	mov    %al,0x11a35d
  101f6f:	b8 70 28 10 00       	mov    $0x102870,%eax
  101f74:	c1 e8 10             	shr    $0x10,%eax
  101f77:	66 a3 5e a3 11 00    	mov    %ax,0x11a35e
	SETGATE(idt[48], 0, CPU_GDT_KCODE, &tv48, 3);
  101f7d:	b8 7a 28 10 00       	mov    $0x10287a,%eax
  101f82:	66 a3 a0 a3 11 00    	mov    %ax,0x11a3a0
  101f88:	66 c7 05 a2 a3 11 00 	movw   $0x8,0x11a3a2
  101f8f:	08 00 
  101f91:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  101f98:	83 e0 e0             	and    $0xffffffe0,%eax
  101f9b:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101fa0:	0f b6 05 a4 a3 11 00 	movzbl 0x11a3a4,%eax
  101fa7:	83 e0 1f             	and    $0x1f,%eax
  101faa:	a2 a4 a3 11 00       	mov    %al,0x11a3a4
  101faf:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101fb6:	83 e0 f0             	and    $0xfffffff0,%eax
  101fb9:	83 c8 0e             	or     $0xe,%eax
  101fbc:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101fc1:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101fc8:	83 e0 ef             	and    $0xffffffef,%eax
  101fcb:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101fd0:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101fd7:	83 c8 60             	or     $0x60,%eax
  101fda:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101fdf:	0f b6 05 a5 a3 11 00 	movzbl 0x11a3a5,%eax
  101fe6:	83 c8 80             	or     $0xffffff80,%eax
  101fe9:	a2 a5 a3 11 00       	mov    %al,0x11a3a5
  101fee:	b8 7a 28 10 00       	mov    $0x10287a,%eax
  101ff3:	c1 e8 10             	shr    $0x10,%eax
  101ff6:	66 a3 a6 a3 11 00    	mov    %ax,0x11a3a6
	SETGATE(idt[49], 0, CPU_GDT_KCODE, &tv49, 0);
  101ffc:	b8 84 28 10 00       	mov    $0x102884,%eax
  102001:	66 a3 a8 a3 11 00    	mov    %ax,0x11a3a8
  102007:	66 c7 05 aa a3 11 00 	movw   $0x8,0x11a3aa
  10200e:	08 00 
  102010:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  102017:	83 e0 e0             	and    $0xffffffe0,%eax
  10201a:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  10201f:	0f b6 05 ac a3 11 00 	movzbl 0x11a3ac,%eax
  102026:	83 e0 1f             	and    $0x1f,%eax
  102029:	a2 ac a3 11 00       	mov    %al,0x11a3ac
  10202e:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  102035:	83 e0 f0             	and    $0xfffffff0,%eax
  102038:	83 c8 0e             	or     $0xe,%eax
  10203b:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  102040:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  102047:	83 e0 ef             	and    $0xffffffef,%eax
  10204a:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10204f:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  102056:	83 e0 9f             	and    $0xffffff9f,%eax
  102059:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10205e:	0f b6 05 ad a3 11 00 	movzbl 0x11a3ad,%eax
  102065:	83 c8 80             	or     $0xffffff80,%eax
  102068:	a2 ad a3 11 00       	mov    %al,0x11a3ad
  10206d:	b8 84 28 10 00       	mov    $0x102884,%eax
  102072:	c1 e8 10             	shr    $0x10,%eax
  102075:	66 a3 ae a3 11 00    	mov    %ax,0x11a3ae
	SETGATE(idt[50], 0, CPU_GDT_KCODE, &tv50, 0);
  10207b:	b8 8e 28 10 00       	mov    $0x10288e,%eax
  102080:	66 a3 b0 a3 11 00    	mov    %ax,0x11a3b0
  102086:	66 c7 05 b2 a3 11 00 	movw   $0x8,0x11a3b2
  10208d:	08 00 
  10208f:	0f b6 05 b4 a3 11 00 	movzbl 0x11a3b4,%eax
  102096:	83 e0 e0             	and    $0xffffffe0,%eax
  102099:	a2 b4 a3 11 00       	mov    %al,0x11a3b4
  10209e:	0f b6 05 b4 a3 11 00 	movzbl 0x11a3b4,%eax
  1020a5:	83 e0 1f             	and    $0x1f,%eax
  1020a8:	a2 b4 a3 11 00       	mov    %al,0x11a3b4
  1020ad:	0f b6 05 b5 a3 11 00 	movzbl 0x11a3b5,%eax
  1020b4:	83 e0 f0             	and    $0xfffffff0,%eax
  1020b7:	83 c8 0e             	or     $0xe,%eax
  1020ba:	a2 b5 a3 11 00       	mov    %al,0x11a3b5
  1020bf:	0f b6 05 b5 a3 11 00 	movzbl 0x11a3b5,%eax
  1020c6:	83 e0 ef             	and    $0xffffffef,%eax
  1020c9:	a2 b5 a3 11 00       	mov    %al,0x11a3b5
  1020ce:	0f b6 05 b5 a3 11 00 	movzbl 0x11a3b5,%eax
  1020d5:	83 e0 9f             	and    $0xffffff9f,%eax
  1020d8:	a2 b5 a3 11 00       	mov    %al,0x11a3b5
  1020dd:	0f b6 05 b5 a3 11 00 	movzbl 0x11a3b5,%eax
  1020e4:	83 c8 80             	or     $0xffffff80,%eax
  1020e7:	a2 b5 a3 11 00       	mov    %al,0x11a3b5
  1020ec:	b8 8e 28 10 00       	mov    $0x10288e,%eax
  1020f1:	c1 e8 10             	shr    $0x10,%eax
  1020f4:	66 a3 b6 a3 11 00    	mov    %ax,0x11a3b6
}
  1020fa:	c9                   	leave  
  1020fb:	c3                   	ret    

001020fc <trap_init>:

void
trap_init(void)
{
  1020fc:	55                   	push   %ebp
  1020fd:	89 e5                	mov    %esp,%ebp
  1020ff:	83 ec 08             	sub    $0x8,%esp
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
  102102:	e8 60 f4 ff ff       	call   101567 <cpu_onboot>
  102107:	85 c0                	test   %eax,%eax
  102109:	74 05                	je     102110 <trap_init+0x14>
		trap_init_idt();
  10210b:	e8 6f f4 ff ff       	call   10157f <trap_init_idt>

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));
  102110:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
  102117:	e8 4b f4 ff ff       	call   101567 <cpu_onboot>
  10211c:	85 c0                	test   %eax,%eax
  10211e:	74 05                	je     102125 <trap_init+0x29>
		trap_check_kernel();
  102120:	e8 6c 03 00 00       	call   102491 <trap_check_kernel>
}
  102125:	c9                   	leave  
  102126:	c3                   	ret    

00102127 <trap_name>:

const char *trap_name(int trapno)
{
  102127:	55                   	push   %ebp
  102128:	89 e5                	mov    %esp,%ebp
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
  10212a:	8b 45 08             	mov    0x8(%ebp),%eax
  10212d:	83 f8 13             	cmp    $0x13,%eax
  102130:	77 0c                	ja     10213e <trap_name+0x17>
		return excnames[trapno];
  102132:	8b 45 08             	mov    0x8(%ebp),%eax
  102135:	8b 04 85 20 8c 10 00 	mov    0x108c20(,%eax,4),%eax
  10213c:	eb 25                	jmp    102163 <trap_name+0x3c>
	if (trapno == T_SYSCALL)
  10213e:	83 7d 08 30          	cmpl   $0x30,0x8(%ebp)
  102142:	75 07                	jne    10214b <trap_name+0x24>
		return "System call";
  102144:	b8 4a 88 10 00       	mov    $0x10884a,%eax
  102149:	eb 18                	jmp    102163 <trap_name+0x3c>
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
  10214b:	83 7d 08 1f          	cmpl   $0x1f,0x8(%ebp)
  10214f:	7e 0d                	jle    10215e <trap_name+0x37>
  102151:	83 7d 08 2f          	cmpl   $0x2f,0x8(%ebp)
  102155:	7f 07                	jg     10215e <trap_name+0x37>
		return "Hardware Interrupt";
  102157:	b8 56 88 10 00       	mov    $0x108856,%eax
  10215c:	eb 05                	jmp    102163 <trap_name+0x3c>
	return "(unknown trap)";
  10215e:	b8 69 88 10 00       	mov    $0x108869,%eax
}
  102163:	5d                   	pop    %ebp
  102164:	c3                   	ret    

00102165 <trap_print_regs>:

void
trap_print_regs(pushregs *regs)
{
  102165:	55                   	push   %ebp
  102166:	89 e5                	mov    %esp,%ebp
  102168:	83 ec 18             	sub    $0x18,%esp
	cprintf("  edi  0x%08x\n", regs->edi);
  10216b:	8b 45 08             	mov    0x8(%ebp),%eax
  10216e:	8b 00                	mov    (%eax),%eax
  102170:	89 44 24 04          	mov    %eax,0x4(%esp)
  102174:	c7 04 24 78 88 10 00 	movl   $0x108878,(%esp)
  10217b:	e8 fd 5a 00 00       	call   107c7d <cprintf>
	cprintf("  esi  0x%08x\n", regs->esi);
  102180:	8b 45 08             	mov    0x8(%ebp),%eax
  102183:	8b 40 04             	mov    0x4(%eax),%eax
  102186:	89 44 24 04          	mov    %eax,0x4(%esp)
  10218a:	c7 04 24 87 88 10 00 	movl   $0x108887,(%esp)
  102191:	e8 e7 5a 00 00       	call   107c7d <cprintf>
	cprintf("  ebp  0x%08x\n", regs->ebp);
  102196:	8b 45 08             	mov    0x8(%ebp),%eax
  102199:	8b 40 08             	mov    0x8(%eax),%eax
  10219c:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021a0:	c7 04 24 96 88 10 00 	movl   $0x108896,(%esp)
  1021a7:	e8 d1 5a 00 00       	call   107c7d <cprintf>
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
  1021ac:	8b 45 08             	mov    0x8(%ebp),%eax
  1021af:	8b 40 10             	mov    0x10(%eax),%eax
  1021b2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021b6:	c7 04 24 a5 88 10 00 	movl   $0x1088a5,(%esp)
  1021bd:	e8 bb 5a 00 00       	call   107c7d <cprintf>
	cprintf("  edx  0x%08x\n", regs->edx);
  1021c2:	8b 45 08             	mov    0x8(%ebp),%eax
  1021c5:	8b 40 14             	mov    0x14(%eax),%eax
  1021c8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021cc:	c7 04 24 b4 88 10 00 	movl   $0x1088b4,(%esp)
  1021d3:	e8 a5 5a 00 00       	call   107c7d <cprintf>
	cprintf("  ecx  0x%08x\n", regs->ecx);
  1021d8:	8b 45 08             	mov    0x8(%ebp),%eax
  1021db:	8b 40 18             	mov    0x18(%eax),%eax
  1021de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021e2:	c7 04 24 c3 88 10 00 	movl   $0x1088c3,(%esp)
  1021e9:	e8 8f 5a 00 00       	call   107c7d <cprintf>
	cprintf("  eax  0x%08x\n", regs->eax);
  1021ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1021f1:	8b 40 1c             	mov    0x1c(%eax),%eax
  1021f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1021f8:	c7 04 24 d2 88 10 00 	movl   $0x1088d2,(%esp)
  1021ff:	e8 79 5a 00 00       	call   107c7d <cprintf>
}
  102204:	c9                   	leave  
  102205:	c3                   	ret    

00102206 <trap_print>:

void
trap_print(trapframe *tf)
{
  102206:	55                   	push   %ebp
  102207:	89 e5                	mov    %esp,%ebp
  102209:	83 ec 18             	sub    $0x18,%esp
	cprintf("TRAP frame at %p\n", tf);
  10220c:	8b 45 08             	mov    0x8(%ebp),%eax
  10220f:	89 44 24 04          	mov    %eax,0x4(%esp)
  102213:	c7 04 24 e1 88 10 00 	movl   $0x1088e1,(%esp)
  10221a:	e8 5e 5a 00 00       	call   107c7d <cprintf>
	trap_print_regs(&tf->regs);
  10221f:	8b 45 08             	mov    0x8(%ebp),%eax
  102222:	89 04 24             	mov    %eax,(%esp)
  102225:	e8 3b ff ff ff       	call   102165 <trap_print_regs>
	cprintf("  es   0x----%04x\n", tf->es);
  10222a:	8b 45 08             	mov    0x8(%ebp),%eax
  10222d:	0f b7 40 28          	movzwl 0x28(%eax),%eax
  102231:	0f b7 c0             	movzwl %ax,%eax
  102234:	89 44 24 04          	mov    %eax,0x4(%esp)
  102238:	c7 04 24 f3 88 10 00 	movl   $0x1088f3,(%esp)
  10223f:	e8 39 5a 00 00       	call   107c7d <cprintf>
	cprintf("  ds   0x----%04x\n", tf->ds);
  102244:	8b 45 08             	mov    0x8(%ebp),%eax
  102247:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
  10224b:	0f b7 c0             	movzwl %ax,%eax
  10224e:	89 44 24 04          	mov    %eax,0x4(%esp)
  102252:	c7 04 24 06 89 10 00 	movl   $0x108906,(%esp)
  102259:	e8 1f 5a 00 00       	call   107c7d <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
  10225e:	8b 45 08             	mov    0x8(%ebp),%eax
  102261:	8b 40 30             	mov    0x30(%eax),%eax
  102264:	89 04 24             	mov    %eax,(%esp)
  102267:	e8 bb fe ff ff       	call   102127 <trap_name>
  10226c:	8b 55 08             	mov    0x8(%ebp),%edx
  10226f:	8b 52 30             	mov    0x30(%edx),%edx
  102272:	89 44 24 08          	mov    %eax,0x8(%esp)
  102276:	89 54 24 04          	mov    %edx,0x4(%esp)
  10227a:	c7 04 24 19 89 10 00 	movl   $0x108919,(%esp)
  102281:	e8 f7 59 00 00       	call   107c7d <cprintf>
	cprintf("  err  0x%08x\n", tf->err);
  102286:	8b 45 08             	mov    0x8(%ebp),%eax
  102289:	8b 40 34             	mov    0x34(%eax),%eax
  10228c:	89 44 24 04          	mov    %eax,0x4(%esp)
  102290:	c7 04 24 2b 89 10 00 	movl   $0x10892b,(%esp)
  102297:	e8 e1 59 00 00       	call   107c7d <cprintf>
	cprintf("  eip  0x%08x\n", tf->eip);
  10229c:	8b 45 08             	mov    0x8(%ebp),%eax
  10229f:	8b 40 38             	mov    0x38(%eax),%eax
  1022a2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022a6:	c7 04 24 3a 89 10 00 	movl   $0x10893a,(%esp)
  1022ad:	e8 cb 59 00 00       	call   107c7d <cprintf>
	cprintf("  cs   0x----%04x\n", tf->cs);
  1022b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022b5:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  1022b9:	0f b7 c0             	movzwl %ax,%eax
  1022bc:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022c0:	c7 04 24 49 89 10 00 	movl   $0x108949,(%esp)
  1022c7:	e8 b1 59 00 00       	call   107c7d <cprintf>
	cprintf("  flag 0x%08x\n", tf->eflags);
  1022cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1022cf:	8b 40 40             	mov    0x40(%eax),%eax
  1022d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022d6:	c7 04 24 5c 89 10 00 	movl   $0x10895c,(%esp)
  1022dd:	e8 9b 59 00 00       	call   107c7d <cprintf>
	cprintf("  esp  0x%08x\n", tf->esp);
  1022e2:	8b 45 08             	mov    0x8(%ebp),%eax
  1022e5:	8b 40 44             	mov    0x44(%eax),%eax
  1022e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1022ec:	c7 04 24 6b 89 10 00 	movl   $0x10896b,(%esp)
  1022f3:	e8 85 59 00 00       	call   107c7d <cprintf>
	cprintf("  ss   0x----%04x\n", tf->ss);
  1022f8:	8b 45 08             	mov    0x8(%ebp),%eax
  1022fb:	0f b7 40 48          	movzwl 0x48(%eax),%eax
  1022ff:	0f b7 c0             	movzwl %ax,%eax
  102302:	89 44 24 04          	mov    %eax,0x4(%esp)
  102306:	c7 04 24 7a 89 10 00 	movl   $0x10897a,(%esp)
  10230d:	e8 6b 59 00 00       	call   107c7d <cprintf>
}
  102312:	c9                   	leave  
  102313:	c3                   	ret    

00102314 <trap>:

void gcc_noreturn
trap(trapframe *tf)
{
  102314:	55                   	push   %ebp
  102315:	89 e5                	mov    %esp,%ebp
  102317:	83 ec 28             	sub    $0x28,%esp
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");
  10231a:	fc                   	cld    

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
  10231b:	e8 f4 f1 ff ff       	call   101514 <cpu_cur>
  102320:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// trap_print(tf);
	if (c->recover)
  102323:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102326:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
  10232c:	85 c0                	test   %eax,%eax
  10232e:	74 1e                	je     10234e <trap+0x3a>
		c->recover(tf, c->recoverdata);
  102330:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102333:	8b 90 a0 00 00 00    	mov    0xa0(%eax),%edx
  102339:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10233c:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
  102342:	89 44 24 04          	mov    %eax,0x4(%esp)
  102346:	8b 45 08             	mov    0x8(%ebp),%eax
  102349:	89 04 24             	mov    %eax,(%esp)
  10234c:	ff d2                	call   *%edx

	// cprintf("cpu %d handling trap\n", c->id);

	// Lab 2: your trap handling code here!
	if(tf->trapno < T_IRQ0 && (tf->cs & 0x3)) {
  10234e:	8b 45 08             	mov    0x8(%ebp),%eax
  102351:	8b 40 30             	mov    0x30(%eax),%eax
  102354:	83 f8 1f             	cmp    $0x1f,%eax
  102357:	77 24                	ja     10237d <trap+0x69>
  102359:	8b 45 08             	mov    0x8(%ebp),%eax
  10235c:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
  102360:	0f b7 c0             	movzwl %ax,%eax
  102363:	83 e0 03             	and    $0x3,%eax
  102366:	85 c0                	test   %eax,%eax
  102368:	74 13                	je     10237d <trap+0x69>
		proc_ret(tf, -1);
  10236a:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  102371:	ff 
  102372:	8b 45 08             	mov    0x8(%ebp),%eax
  102375:	89 04 24             	mov    %eax,(%esp)
  102378:	e8 14 16 00 00       	call   103991 <proc_ret>
	}

	if(tf->trapno == T_SYSCALL) syscall(tf);
  10237d:	8b 45 08             	mov    0x8(%ebp),%eax
  102380:	8b 40 30             	mov    0x30(%eax),%eax
  102383:	83 f8 30             	cmp    $0x30,%eax
  102386:	75 0b                	jne    102393 <trap+0x7f>
  102388:	8b 45 08             	mov    0x8(%ebp),%eax
  10238b:	89 04 24             	mov    %eax,(%esp)
  10238e:	e8 65 21 00 00       	call   1044f8 <syscall>

	if(tf->trapno == (T_LTIMER)) {
  102393:	8b 45 08             	mov    0x8(%ebp),%eax
  102396:	8b 40 30             	mov    0x30(%eax),%eax
  102399:	83 f8 31             	cmp    $0x31,%eax
  10239c:	75 10                	jne    1023ae <trap+0x9a>
		// cprintf("cpu %d timer\n", c->id);
		lapic_eoi();
  10239e:	e8 42 4e 00 00       	call   1071e5 <lapic_eoi>
		proc_yield(tf);
  1023a3:	8b 45 08             	mov    0x8(%ebp),%eax
  1023a6:	89 04 24             	mov    %eax,(%esp)
  1023a9:	e8 8f 15 00 00       	call   10393d <proc_yield>
	}
	if(tf->trapno == (T_IRQ0 + IRQ_SPURIOUS)) {
  1023ae:	8b 45 08             	mov    0x8(%ebp),%eax
  1023b1:	8b 40 30             	mov    0x30(%eax),%eax
  1023b4:	83 f8 27             	cmp    $0x27,%eax
  1023b7:	75 28                	jne    1023e1 <trap+0xcd>
		cprintf("cpu %d spurious timer\n", c->id);
  1023b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1023bc:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  1023c3:	0f b6 c0             	movzbl %al,%eax
  1023c6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1023ca:	c7 04 24 8d 89 10 00 	movl   $0x10898d,(%esp)
  1023d1:	e8 a7 58 00 00       	call   107c7d <cprintf>
		trap_return(tf);
  1023d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1023d9:	89 04 24             	mov    %eax,(%esp)
  1023dc:	e8 ef 04 00 00       	call   1028d0 <trap_return>
	}
	if(tf->trapno == T_LERROR) {
  1023e1:	8b 45 08             	mov    0x8(%ebp),%eax
  1023e4:	8b 40 30             	mov    0x30(%eax),%eax
  1023e7:	83 f8 32             	cmp    $0x32,%eax
  1023ea:	75 10                	jne    1023fc <trap+0xe8>
		lapic_errintr();
  1023ec:	e8 19 4e 00 00       	call   10720a <lapic_errintr>
		trap_return(tf);
  1023f1:	8b 45 08             	mov    0x8(%ebp),%eax
  1023f4:	89 04 24             	mov    %eax,(%esp)
  1023f7:	e8 d4 04 00 00       	call   1028d0 <trap_return>
	}

	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
  1023fc:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  102403:	e8 5a 0a 00 00       	call   102e62 <spinlock_holding>
  102408:	85 c0                	test   %eax,%eax
  10240a:	74 0c                	je     102418 <trap+0x104>
		spinlock_release(&cons_lock);
  10240c:	c7 04 24 a0 ec 11 00 	movl   $0x11eca0,(%esp)
  102413:	e8 dc 09 00 00       	call   102df4 <spinlock_release>
	trap_print(tf);
  102418:	8b 45 08             	mov    0x8(%ebp),%eax
  10241b:	89 04 24             	mov    %eax,(%esp)
  10241e:	e8 e3 fd ff ff       	call   102206 <trap_print>
	panic("unhandled trap");
  102423:	c7 44 24 08 a4 89 10 	movl   $0x1089a4,0x8(%esp)
  10242a:	00 
  10242b:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
  102432:	00 
  102433:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  10243a:	e8 79 e0 ff ff       	call   1004b8 <debug_panic>

0010243f <trap_check_recover>:

// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
  10243f:	55                   	push   %ebp
  102440:	89 e5                	mov    %esp,%ebp
  102442:	83 ec 28             	sub    $0x28,%esp
	trap_check_args *args = recoverdata;
  102445:	8b 45 0c             	mov    0xc(%ebp),%eax
  102448:	89 45 f4             	mov    %eax,-0xc(%ebp)
	trap_print(tf);
  10244b:	8b 45 08             	mov    0x8(%ebp),%eax
  10244e:	89 04 24             	mov    %eax,(%esp)
  102451:	e8 b0 fd ff ff       	call   102206 <trap_print>
	cprintf("reip = %d\n", args->reip);
  102456:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102459:	8b 00                	mov    (%eax),%eax
  10245b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10245f:	c7 04 24 bf 89 10 00 	movl   $0x1089bf,(%esp)
  102466:	e8 12 58 00 00       	call   107c7d <cprintf>
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
  10246b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10246e:	8b 00                	mov    (%eax),%eax
  102470:	89 c2                	mov    %eax,%edx
  102472:	8b 45 08             	mov    0x8(%ebp),%eax
  102475:	89 50 38             	mov    %edx,0x38(%eax)
	args->trapno = tf->trapno;		// Return trap number
  102478:	8b 45 08             	mov    0x8(%ebp),%eax
  10247b:	8b 40 30             	mov    0x30(%eax),%eax
  10247e:	89 c2                	mov    %eax,%edx
  102480:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102483:	89 50 04             	mov    %edx,0x4(%eax)
	trap_return(tf);
  102486:	8b 45 08             	mov    0x8(%ebp),%eax
  102489:	89 04 24             	mov    %eax,(%esp)
  10248c:	e8 3f 04 00 00       	call   1028d0 <trap_return>

00102491 <trap_check_kernel>:

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
  102491:	55                   	push   %ebp
  102492:	89 e5                	mov    %esp,%ebp
  102494:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102497:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  10249a:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 0);	// better be in kernel mode!
  10249e:	0f b7 c0             	movzwl %ax,%eax
  1024a1:	83 e0 03             	and    $0x3,%eax
  1024a4:	85 c0                	test   %eax,%eax
  1024a6:	74 24                	je     1024cc <trap_check_kernel+0x3b>
  1024a8:	c7 44 24 0c ca 89 10 	movl   $0x1089ca,0xc(%esp)
  1024af:	00 
  1024b0:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  1024b7:	00 
  1024b8:	c7 44 24 04 ec 00 00 	movl   $0xec,0x4(%esp)
  1024bf:	00 
  1024c0:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  1024c7:	e8 ec df ff ff       	call   1004b8 <debug_panic>

	cpu *c = cpu_cur();
  1024cc:	e8 43 f0 ff ff       	call   101514 <cpu_cur>
  1024d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	c->recover = trap_check_recover;
  1024d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024d7:	c7 80 a0 00 00 00 3f 	movl   $0x10243f,0xa0(%eax)
  1024de:	24 10 00 
	trap_check(&c->recoverdata);
  1024e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024e4:	05 a4 00 00 00       	add    $0xa4,%eax
  1024e9:	89 04 24             	mov    %eax,(%esp)
  1024ec:	e8 96 00 00 00       	call   102587 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  1024f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1024f4:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  1024fb:	00 00 00 

	cprintf("trap_check_kernel() succeeded!\n");
  1024fe:	c7 04 24 e0 89 10 00 	movl   $0x1089e0,(%esp)
  102505:	e8 73 57 00 00       	call   107c7d <cprintf>
}
  10250a:	c9                   	leave  
  10250b:	c3                   	ret    

0010250c <trap_check_user>:
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
  10250c:	55                   	push   %ebp
  10250d:	89 e5                	mov    %esp,%ebp
  10250f:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  102512:	8c 4d f6             	mov    %cs,-0xa(%ebp)
        return cs;
  102515:	0f b7 45 f6          	movzwl -0xa(%ebp),%eax
	assert((read_cs() & 3) == 3);	// better be in user mode!
  102519:	0f b7 c0             	movzwl %ax,%eax
  10251c:	83 e0 03             	and    $0x3,%eax
  10251f:	83 f8 03             	cmp    $0x3,%eax
  102522:	74 24                	je     102548 <trap_check_user+0x3c>
  102524:	c7 44 24 0c 00 8a 10 	movl   $0x108a00,0xc(%esp)
  10252b:	00 
  10252c:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102533:	00 
  102534:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  10253b:	00 
  10253c:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102543:	e8 70 df ff ff       	call   1004b8 <debug_panic>

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
  102548:	c7 45 f0 00 b0 10 00 	movl   $0x10b000,-0x10(%ebp)
	c->recover = trap_check_recover;
  10254f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102552:	c7 80 a0 00 00 00 3f 	movl   $0x10243f,0xa0(%eax)
  102559:	24 10 00 
	trap_check(&c->recoverdata);
  10255c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10255f:	05 a4 00 00 00       	add    $0xa4,%eax
  102564:	89 04 24             	mov    %eax,(%esp)
  102567:	e8 1b 00 00 00       	call   102587 <trap_check>
	c->recover = NULL;	// No more mr. nice-guy; traps are real again
  10256c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10256f:	c7 80 a0 00 00 00 00 	movl   $0x0,0xa0(%eax)
  102576:	00 00 00 

	cprintf("trap_check_user() succeeded!\n");
  102579:	c7 04 24 15 8a 10 00 	movl   $0x108a15,(%esp)
  102580:	e8 f8 56 00 00       	call   107c7d <cprintf>
}
  102585:	c9                   	leave  
  102586:	c3                   	ret    

00102587 <trap_check>:
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
  102587:	55                   	push   %ebp
  102588:	89 e5                	mov    %esp,%ebp
  10258a:	57                   	push   %edi
  10258b:	56                   	push   %esi
  10258c:	53                   	push   %ebx
  10258d:	83 ec 3c             	sub    $0x3c,%esp
	volatile int cookie = 0xfeedface;
  102590:	c7 45 e0 ce fa ed fe 	movl   $0xfeedface,-0x20(%ebp)
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery
  102597:	8b 45 08             	mov    0x8(%ebp),%eax
  10259a:	8d 55 d8             	lea    -0x28(%ebp),%edx
  10259d:	89 10                	mov    %edx,(%eax)

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
  10259f:	c7 45 d8 ad 25 10 00 	movl   $0x1025ad,-0x28(%ebp)
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
  1025a6:	b8 00 00 00 00       	mov    $0x0,%eax
  1025ab:	f7 f0                	div    %eax

001025ad <after_div0>:
	assert(args.trapno == T_DIVIDE);
  1025ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1025b0:	85 c0                	test   %eax,%eax
  1025b2:	74 24                	je     1025d8 <after_div0+0x2b>
  1025b4:	c7 44 24 0c 33 8a 10 	movl   $0x108a33,0xc(%esp)
  1025bb:	00 
  1025bc:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  1025c3:	00 
  1025c4:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
  1025cb:	00 
  1025cc:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  1025d3:	e8 e0 de ff ff       	call   1004b8 <debug_panic>

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);
  1025d8:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1025db:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  1025e0:	74 24                	je     102606 <after_div0+0x59>
  1025e2:	c7 44 24 0c 4b 8a 10 	movl   $0x108a4b,0xc(%esp)
  1025e9:	00 
  1025ea:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  1025f1:	00 
  1025f2:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
  1025f9:	00 
  1025fa:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102601:	e8 b2 de ff ff       	call   1004b8 <debug_panic>

	// Breakpoint trap
	args.reip = after_breakpoint;
  102606:	c7 45 d8 0e 26 10 00 	movl   $0x10260e,-0x28(%ebp)
	asm volatile("int3; after_breakpoint:");
  10260d:	cc                   	int3   

0010260e <after_breakpoint>:
	assert(args.trapno == T_BRKPT);
  10260e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102611:	83 f8 03             	cmp    $0x3,%eax
  102614:	74 24                	je     10263a <after_breakpoint+0x2c>
  102616:	c7 44 24 0c 60 8a 10 	movl   $0x108a60,0xc(%esp)
  10261d:	00 
  10261e:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102625:	00 
  102626:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  10262d:	00 
  10262e:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102635:	e8 7e de ff ff       	call   1004b8 <debug_panic>

	// Overflow trap
	args.reip = after_overflow;
  10263a:	c7 45 d8 49 26 10 00 	movl   $0x102649,-0x28(%ebp)
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
  102641:	b8 00 00 00 70       	mov    $0x70000000,%eax
  102646:	01 c0                	add    %eax,%eax
  102648:	ce                   	into   

00102649 <after_overflow>:
	assert(args.trapno == T_OFLOW);
  102649:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10264c:	83 f8 04             	cmp    $0x4,%eax
  10264f:	74 24                	je     102675 <after_overflow+0x2c>
  102651:	c7 44 24 0c 77 8a 10 	movl   $0x108a77,0xc(%esp)
  102658:	00 
  102659:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102660:	00 
  102661:	c7 44 24 04 2c 01 00 	movl   $0x12c,0x4(%esp)
  102668:	00 
  102669:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102670:	e8 43 de ff ff       	call   1004b8 <debug_panic>

	// Bounds trap
	args.reip = after_bound;
  102675:	c7 45 d8 92 26 10 00 	movl   $0x102692,-0x28(%ebp)
	int bounds[2] = { 1, 3 };
  10267c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
  102683:	c7 45 d4 03 00 00 00 	movl   $0x3,-0x2c(%ebp)
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
  10268a:	b8 00 00 00 00       	mov    $0x0,%eax
  10268f:	62 45 d0             	bound  %eax,-0x30(%ebp)

00102692 <after_bound>:
	assert(args.trapno == T_BOUND);
  102692:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102695:	83 f8 05             	cmp    $0x5,%eax
  102698:	74 24                	je     1026be <after_bound+0x2c>
  10269a:	c7 44 24 0c 8e 8a 10 	movl   $0x108a8e,0xc(%esp)
  1026a1:	00 
  1026a2:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  1026a9:	00 
  1026aa:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  1026b1:	00 
  1026b2:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  1026b9:	e8 fa dd ff ff       	call   1004b8 <debug_panic>

	// Illegal instruction trap
	args.reip = after_illegal;
  1026be:	c7 45 d8 c7 26 10 00 	movl   $0x1026c7,-0x28(%ebp)
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
  1026c5:	0f 0b                	ud2    

001026c7 <after_illegal>:
	assert(args.trapno == T_ILLOP);
  1026c7:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1026ca:	83 f8 06             	cmp    $0x6,%eax
  1026cd:	74 24                	je     1026f3 <after_illegal+0x2c>
  1026cf:	c7 44 24 0c a5 8a 10 	movl   $0x108aa5,0xc(%esp)
  1026d6:	00 
  1026d7:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  1026de:	00 
  1026df:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
  1026e6:	00 
  1026e7:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  1026ee:	e8 c5 dd ff ff       	call   1004b8 <debug_panic>

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
  1026f3:	c7 45 d8 01 27 10 00 	movl   $0x102701,-0x28(%ebp)
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
  1026fa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  1026ff:	8e e0                	mov    %eax,%fs

00102701 <after_gpfault>:
	assert(args.trapno == T_GPFLT);
  102701:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102704:	83 f8 0d             	cmp    $0xd,%eax
  102707:	74 24                	je     10272d <after_gpfault+0x2c>
  102709:	c7 44 24 0c bc 8a 10 	movl   $0x108abc,0xc(%esp)
  102710:	00 
  102711:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102718:	00 
  102719:	c7 44 24 04 3c 01 00 	movl   $0x13c,0x4(%esp)
  102720:	00 
  102721:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102728:	e8 8b dd ff ff       	call   1004b8 <debug_panic>

static gcc_inline uint16_t
read_cs(void)
{
        uint16_t cs;
        __asm __volatile("movw %%cs,%0" : "=rm" (cs));
  10272d:	8c 4d e6             	mov    %cs,-0x1a(%ebp)
        return cs;
  102730:	0f b7 45 e6          	movzwl -0x1a(%ebp),%eax

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
  102734:	0f b7 c0             	movzwl %ax,%eax
  102737:	83 e0 03             	and    $0x3,%eax
  10273a:	85 c0                	test   %eax,%eax
  10273c:	74 3a                	je     102778 <after_priv+0x2c>
		args.reip = after_priv;
  10273e:	c7 45 d8 4c 27 10 00 	movl   $0x10274c,-0x28(%ebp)
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
  102745:	0f 01 1d 04 c0 10 00 	lidtl  0x10c004

0010274c <after_priv>:
		assert(args.trapno == T_GPFLT);
  10274c:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10274f:	83 f8 0d             	cmp    $0xd,%eax
  102752:	74 24                	je     102778 <after_priv+0x2c>
  102754:	c7 44 24 0c bc 8a 10 	movl   $0x108abc,0xc(%esp)
  10275b:	00 
  10275c:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102763:	00 
  102764:	c7 44 24 04 42 01 00 	movl   $0x142,0x4(%esp)
  10276b:	00 
  10276c:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  102773:	e8 40 dd ff ff       	call   1004b8 <debug_panic>
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);
  102778:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10277b:	3d ce fa ed fe       	cmp    $0xfeedface,%eax
  102780:	74 24                	je     1027a6 <after_priv+0x5a>
  102782:	c7 44 24 0c 4b 8a 10 	movl   $0x108a4b,0xc(%esp)
  102789:	00 
  10278a:	c7 44 24 08 16 88 10 	movl   $0x108816,0x8(%esp)
  102791:	00 
  102792:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
  102799:	00 
  10279a:	c7 04 24 b3 89 10 00 	movl   $0x1089b3,(%esp)
  1027a1:	e8 12 dd ff ff       	call   1004b8 <debug_panic>

	*argsp = NULL;	// recovery mechanism not needed anymore
  1027a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1027a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
  1027af:	83 c4 3c             	add    $0x3c,%esp
  1027b2:	5b                   	pop    %ebx
  1027b3:	5e                   	pop    %esi
  1027b4:	5f                   	pop    %edi
  1027b5:	5d                   	pop    %ebp
  1027b6:	c3                   	ret    
  1027b7:	90                   	nop
  1027b8:	90                   	nop
  1027b9:	90                   	nop
  1027ba:	90                   	nop
  1027bb:	90                   	nop
  1027bc:	90                   	nop
  1027bd:	90                   	nop
  1027be:	90                   	nop
  1027bf:	90                   	nop

001027c0 <tv0>:
.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(tv0, 0);
  1027c0:	6a 00                	push   $0x0
  1027c2:	6a 00                	push   $0x0
  1027c4:	e9 e7 00 00 00       	jmp    1028b0 <_alltraps>
  1027c9:	90                   	nop

001027ca <tv2>:
/* TRAPHANDLER_NOEC(trap_debug, 1); */
TRAPHANDLER_NOEC(tv2, 2);
  1027ca:	6a 00                	push   $0x0
  1027cc:	6a 02                	push   $0x2
  1027ce:	e9 dd 00 00 00       	jmp    1028b0 <_alltraps>
  1027d3:	90                   	nop

001027d4 <tv3>:
TRAPHANDLER_NOEC(tv3, 3);
  1027d4:	6a 00                	push   $0x0
  1027d6:	6a 03                	push   $0x3
  1027d8:	e9 d3 00 00 00       	jmp    1028b0 <_alltraps>
  1027dd:	90                   	nop

001027de <tv4>:
TRAPHANDLER_NOEC(tv4, 4);
  1027de:	6a 00                	push   $0x0
  1027e0:	6a 04                	push   $0x4
  1027e2:	e9 c9 00 00 00       	jmp    1028b0 <_alltraps>
  1027e7:	90                   	nop

001027e8 <tv5>:
TRAPHANDLER_NOEC(tv5, 5);
  1027e8:	6a 00                	push   $0x0
  1027ea:	6a 05                	push   $0x5
  1027ec:	e9 bf 00 00 00       	jmp    1028b0 <_alltraps>
  1027f1:	90                   	nop

001027f2 <tv6>:
TRAPHANDLER_NOEC(tv6, 6);
  1027f2:	6a 00                	push   $0x0
  1027f4:	6a 06                	push   $0x6
  1027f6:	e9 b5 00 00 00       	jmp    1028b0 <_alltraps>
  1027fb:	90                   	nop

001027fc <tv7>:
TRAPHANDLER_NOEC(tv7, 7);
  1027fc:	6a 00                	push   $0x0
  1027fe:	6a 07                	push   $0x7
  102800:	e9 ab 00 00 00       	jmp    1028b0 <_alltraps>
  102805:	90                   	nop

00102806 <tv8>:
TRAPHANDLER(tv8, 8);
  102806:	6a 08                	push   $0x8
  102808:	e9 a3 00 00 00       	jmp    1028b0 <_alltraps>
  10280d:	90                   	nop

0010280e <tv10>:
/* TRAPHANDLER_NOEC(trap_coproc_seg_overrun, 9); */
TRAPHANDLER(tv10, 10);
  10280e:	6a 0a                	push   $0xa
  102810:	e9 9b 00 00 00       	jmp    1028b0 <_alltraps>
  102815:	90                   	nop

00102816 <tv11>:
TRAPHANDLER(tv11, 11);
  102816:	6a 0b                	push   $0xb
  102818:	e9 93 00 00 00       	jmp    1028b0 <_alltraps>
  10281d:	90                   	nop

0010281e <tv12>:
TRAPHANDLER(tv12, 12);
  10281e:	6a 0c                	push   $0xc
  102820:	e9 8b 00 00 00       	jmp    1028b0 <_alltraps>
  102825:	90                   	nop

00102826 <tv13>:
TRAPHANDLER(tv13, 13);
  102826:	6a 0d                	push   $0xd
  102828:	e9 83 00 00 00       	jmp    1028b0 <_alltraps>
  10282d:	90                   	nop

0010282e <tv14>:
TRAPHANDLER(tv14, 14);
  10282e:	6a 0e                	push   $0xe
  102830:	e9 7b 00 00 00       	jmp    1028b0 <_alltraps>
  102835:	90                   	nop

00102836 <tv16>:
/* TRAPHANDLER_NOEC(reserved, 15); */
TRAPHANDLER_NOEC(tv16, 16);
  102836:	6a 00                	push   $0x0
  102838:	6a 10                	push   $0x10
  10283a:	e9 71 00 00 00       	jmp    1028b0 <_alltraps>
  10283f:	90                   	nop

00102840 <tv17>:
TRAPHANDLER(tv17, 17);
  102840:	6a 11                	push   $0x11
  102842:	e9 69 00 00 00       	jmp    1028b0 <_alltraps>
  102847:	90                   	nop

00102848 <tv18>:
TRAPHANDLER_NOEC(tv18, 18);
  102848:	6a 00                	push   $0x0
  10284a:	6a 12                	push   $0x12
  10284c:	e9 5f 00 00 00       	jmp    1028b0 <_alltraps>
  102851:	90                   	nop

00102852 <tv19>:
TRAPHANDLER_NOEC(tv19, 19);
  102852:	6a 00                	push   $0x0
  102854:	6a 13                	push   $0x13
  102856:	e9 55 00 00 00       	jmp    1028b0 <_alltraps>
  10285b:	90                   	nop

0010285c <tv30>:
TRAPHANDLER_NOEC(tv30, 30);
  10285c:	6a 00                	push   $0x0
  10285e:	6a 1e                	push   $0x1e
  102860:	e9 4b 00 00 00       	jmp    1028b0 <_alltraps>
  102865:	90                   	nop

00102866 <tv32>:
TRAPHANDLER_NOEC(tv32, 32);
  102866:	6a 00                	push   $0x0
  102868:	6a 20                	push   $0x20
  10286a:	e9 41 00 00 00       	jmp    1028b0 <_alltraps>
  10286f:	90                   	nop

00102870 <tv39>:
TRAPHANDLER_NOEC(tv39, 39);
  102870:	6a 00                	push   $0x0
  102872:	6a 27                	push   $0x27
  102874:	e9 37 00 00 00       	jmp    1028b0 <_alltraps>
  102879:	90                   	nop

0010287a <tv48>:
TRAPHANDLER_NOEC(tv48, 48);
  10287a:	6a 00                	push   $0x0
  10287c:	6a 30                	push   $0x30
  10287e:	e9 2d 00 00 00       	jmp    1028b0 <_alltraps>
  102883:	90                   	nop

00102884 <tv49>:
TRAPHANDLER_NOEC(tv49, 49);
  102884:	6a 00                	push   $0x0
  102886:	6a 31                	push   $0x31
  102888:	e9 23 00 00 00       	jmp    1028b0 <_alltraps>
  10288d:	90                   	nop

0010288e <tv50>:
TRAPHANDLER_NOEC(tv50, 50);
  10288e:	6a 00                	push   $0x0
  102890:	6a 32                	push   $0x32
  102892:	e9 19 00 00 00       	jmp    1028b0 <_alltraps>
  102897:	90                   	nop

00102898 <tv500>:
TRAPHANDLER_NOEC(tv500, 500);
  102898:	6a 00                	push   $0x0
  10289a:	68 f4 01 00 00       	push   $0x1f4
  10289f:	e9 0c 00 00 00       	jmp    1028b0 <_alltraps>

001028a4 <tv501>:
TRAPHANDLER_NOEC(tv501, 501);
  1028a4:	6a 00                	push   $0x0
  1028a6:	68 f5 01 00 00       	push   $0x1f5
  1028ab:	e9 00 00 00 00       	jmp    1028b0 <_alltraps>

001028b0 <_alltraps>:
/*
 * Lab 1: Your code here for _alltraps
 */
.globl _alltraps
_alltraps:
	pushl %ds
  1028b0:	1e                   	push   %ds
	pushl %es
  1028b1:	06                   	push   %es
	pushl %fs
  1028b2:	0f a0                	push   %fs
	pushl %gs
  1028b4:	0f a8                	push   %gs
	pushal
  1028b6:	60                   	pusha  

	movw $CPU_GDT_KDATA, %ax
  1028b7:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
  1028bb:	8e d8                	mov    %eax,%ds
	movw %ax, %es
  1028bd:	8e c0                	mov    %eax,%es

	pushl %esp // passing trapframe addr as parameter
  1028bf:	54                   	push   %esp
	call trap
  1028c0:	e8 4f fa ff ff       	call   102314 <trap>
  1028c5:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1028c9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi

001028d0 <trap_return>:
// replaces the caller's stack pointer and other registers.
.globl	trap_return
.type	trap_return,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
	movl 0x4(%esp), %eax
  1028d0:	8b 44 24 04          	mov    0x4(%esp),%eax
	movl %eax, %esp // setting stack to trap frame
  1028d4:	89 c4                	mov    %eax,%esp
	popal
  1028d6:	61                   	popa   
	popl %gs
  1028d7:	0f a9                	pop    %gs
	popl %fs
  1028d9:	0f a1                	pop    %fs
	popl %es
  1028db:	07                   	pop    %es
	popl %ds
  1028dc:	1f                   	pop    %ds
	addl $0x8, %esp // trapno and errcode
  1028dd:	83 c4 08             	add    $0x8,%esp
	iret
  1028e0:	cf                   	iret   
  1028e1:	90                   	nop
  1028e2:	90                   	nop
  1028e3:	90                   	nop

001028e4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1028e4:	55                   	push   %ebp
  1028e5:	89 e5                	mov    %esp,%ebp
  1028e7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1028ea:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1028ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1028f0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1028f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1028f6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1028fb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1028fe:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102901:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102907:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10290c:	74 24                	je     102932 <cpu_cur+0x4e>
  10290e:	c7 44 24 0c 70 8c 10 	movl   $0x108c70,0xc(%esp)
  102915:	00 
  102916:	c7 44 24 08 86 8c 10 	movl   $0x108c86,0x8(%esp)
  10291d:	00 
  10291e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102925:	00 
  102926:	c7 04 24 9b 8c 10 00 	movl   $0x108c9b,(%esp)
  10292d:	e8 86 db ff ff       	call   1004b8 <debug_panic>
	return c;
  102932:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  102935:	c9                   	leave  
  102936:	c3                   	ret    

00102937 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  102937:	55                   	push   %ebp
  102938:	89 e5                	mov    %esp,%ebp
  10293a:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10293d:	e8 a2 ff ff ff       	call   1028e4 <cpu_cur>
  102942:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  102947:	0f 94 c0             	sete   %al
  10294a:	0f b6 c0             	movzbl %al,%eax
}
  10294d:	c9                   	leave  
  10294e:	c3                   	ret    

0010294f <sum>:
volatile struct ioapic *ioapic;


static uint8_t
sum(uint8_t * addr, int len)
{
  10294f:	55                   	push   %ebp
  102950:	89 e5                	mov    %esp,%ebp
  102952:	83 ec 10             	sub    $0x10,%esp
	int i, sum;

	sum = 0;
  102955:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	for (i = 0; i < len; i++)
  10295c:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  102963:	eb 13                	jmp    102978 <sum+0x29>
		sum += addr[i];
  102965:	8b 45 f8             	mov    -0x8(%ebp),%eax
  102968:	03 45 08             	add    0x8(%ebp),%eax
  10296b:	0f b6 00             	movzbl (%eax),%eax
  10296e:	0f b6 c0             	movzbl %al,%eax
  102971:	01 45 fc             	add    %eax,-0x4(%ebp)
sum(uint8_t * addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
  102974:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  102978:	8b 45 f8             	mov    -0x8(%ebp),%eax
  10297b:	3b 45 0c             	cmp    0xc(%ebp),%eax
  10297e:	7c e5                	jl     102965 <sum+0x16>
		sum += addr[i];
	return sum;
  102980:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102983:	c9                   	leave  
  102984:	c3                   	ret    

00102985 <mpsearch1>:

//Look for an MP structure in the len bytes at addr.
static struct mp *
mpsearch1(uint8_t * addr, int len)
{
  102985:	55                   	push   %ebp
  102986:	89 e5                	mov    %esp,%ebp
  102988:	83 ec 28             	sub    $0x28,%esp
	uint8_t *e, *p;

	e = addr + len;
  10298b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10298e:	03 45 08             	add    0x8(%ebp),%eax
  102991:	89 45 f0             	mov    %eax,-0x10(%ebp)
	for (p = addr; p < e; p += sizeof(struct mp))
  102994:	8b 45 08             	mov    0x8(%ebp),%eax
  102997:	89 45 f4             	mov    %eax,-0xc(%ebp)
  10299a:	eb 3f                	jmp    1029db <mpsearch1+0x56>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
  10299c:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  1029a3:	00 
  1029a4:	c7 44 24 04 a8 8c 10 	movl   $0x108ca8,0x4(%esp)
  1029ab:	00 
  1029ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029af:	89 04 24             	mov    %eax,(%esp)
  1029b2:	e8 1d 56 00 00       	call   107fd4 <memcmp>
  1029b7:	85 c0                	test   %eax,%eax
  1029b9:	75 1c                	jne    1029d7 <mpsearch1+0x52>
  1029bb:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
  1029c2:	00 
  1029c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029c6:	89 04 24             	mov    %eax,(%esp)
  1029c9:	e8 81 ff ff ff       	call   10294f <sum>
  1029ce:	84 c0                	test   %al,%al
  1029d0:	75 05                	jne    1029d7 <mpsearch1+0x52>
			return (struct mp *) p;
  1029d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029d5:	eb 11                	jmp    1029e8 <mpsearch1+0x63>
mpsearch1(uint8_t * addr, int len)
{
	uint8_t *e, *p;

	e = addr + len;
	for (p = addr; p < e; p += sizeof(struct mp))
  1029d7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
  1029db:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1029de:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1029e1:	72 b9                	jb     10299c <mpsearch1+0x17>
		if (memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
			return (struct mp *) p;
	return 0;
  1029e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
  1029e8:	c9                   	leave  
  1029e9:	c3                   	ret    

001029ea <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp *
mpsearch(void)
{
  1029ea:	55                   	push   %ebp
  1029eb:	89 e5                	mov    %esp,%ebp
  1029ed:	83 ec 28             	sub    $0x28,%esp
	uint8_t          *bda;
	uint32_t            p;
	struct mp      *mp;

	bda = (uint8_t *) 0x400;
  1029f0:	c7 45 ec 00 04 00 00 	movl   $0x400,-0x14(%ebp)
	if ((p = ((bda[0x0F] << 8) | bda[0x0E]) << 4)) {
  1029f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1029fa:	83 c0 0f             	add    $0xf,%eax
  1029fd:	0f b6 00             	movzbl (%eax),%eax
  102a00:	0f b6 c0             	movzbl %al,%eax
  102a03:	89 c2                	mov    %eax,%edx
  102a05:	c1 e2 08             	shl    $0x8,%edx
  102a08:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a0b:	83 c0 0e             	add    $0xe,%eax
  102a0e:	0f b6 00             	movzbl (%eax),%eax
  102a11:	0f b6 c0             	movzbl %al,%eax
  102a14:	09 d0                	or     %edx,%eax
  102a16:	c1 e0 04             	shl    $0x4,%eax
  102a19:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102a1c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  102a20:	74 21                	je     102a43 <mpsearch+0x59>
		if ((mp = mpsearch1((uint8_t *) p, 1024)))
  102a22:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a25:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102a2c:	00 
  102a2d:	89 04 24             	mov    %eax,(%esp)
  102a30:	e8 50 ff ff ff       	call   102985 <mpsearch1>
  102a35:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102a38:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102a3c:	74 50                	je     102a8e <mpsearch+0xa4>
			return mp;
  102a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a41:	eb 5f                	jmp    102aa2 <mpsearch+0xb8>
	} else {
		p = ((bda[0x14] << 8) | bda[0x13]) * 1024;
  102a43:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a46:	83 c0 14             	add    $0x14,%eax
  102a49:	0f b6 00             	movzbl (%eax),%eax
  102a4c:	0f b6 c0             	movzbl %al,%eax
  102a4f:	89 c2                	mov    %eax,%edx
  102a51:	c1 e2 08             	shl    $0x8,%edx
  102a54:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102a57:	83 c0 13             	add    $0x13,%eax
  102a5a:	0f b6 00             	movzbl (%eax),%eax
  102a5d:	0f b6 c0             	movzbl %al,%eax
  102a60:	09 d0                	or     %edx,%eax
  102a62:	c1 e0 0a             	shl    $0xa,%eax
  102a65:	89 45 f0             	mov    %eax,-0x10(%ebp)
		if ((mp = mpsearch1((uint8_t *) p - 1024, 1024)))
  102a68:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102a6b:	2d 00 04 00 00       	sub    $0x400,%eax
  102a70:	c7 44 24 04 00 04 00 	movl   $0x400,0x4(%esp)
  102a77:	00 
  102a78:	89 04 24             	mov    %eax,(%esp)
  102a7b:	e8 05 ff ff ff       	call   102985 <mpsearch1>
  102a80:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102a83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102a87:	74 05                	je     102a8e <mpsearch+0xa4>
			return mp;
  102a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102a8c:	eb 14                	jmp    102aa2 <mpsearch+0xb8>
	}
	return mpsearch1((uint8_t *) 0xF0000, 0x10000);
  102a8e:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  102a95:	00 
  102a96:	c7 04 24 00 00 0f 00 	movl   $0xf0000,(%esp)
  102a9d:	e8 e3 fe ff ff       	call   102985 <mpsearch1>
}
  102aa2:	c9                   	leave  
  102aa3:	c3                   	ret    

00102aa4 <mpconfig>:
// don 't accept the default configurations (physaddr == 0).
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf *
mpconfig(struct mp **pmp) {
  102aa4:	55                   	push   %ebp
  102aa5:	89 e5                	mov    %esp,%ebp
  102aa7:	83 ec 28             	sub    $0x28,%esp
	struct mpconf  *conf;
	struct mp      *mp;

	if ((mp = mpsearch()) == 0 || mp->physaddr == 0)
  102aaa:	e8 3b ff ff ff       	call   1029ea <mpsearch>
  102aaf:	89 45 f4             	mov    %eax,-0xc(%ebp)
  102ab2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  102ab6:	74 0a                	je     102ac2 <mpconfig+0x1e>
  102ab8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102abb:	8b 40 04             	mov    0x4(%eax),%eax
  102abe:	85 c0                	test   %eax,%eax
  102ac0:	75 07                	jne    102ac9 <mpconfig+0x25>
		return 0;
  102ac2:	b8 00 00 00 00       	mov    $0x0,%eax
  102ac7:	eb 7b                	jmp    102b44 <mpconfig+0xa0>
	conf = (struct mpconf *) mp->physaddr;
  102ac9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102acc:	8b 40 04             	mov    0x4(%eax),%eax
  102acf:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (memcmp(conf, "PCMP", 4) != 0)
  102ad2:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
  102ad9:	00 
  102ada:	c7 44 24 04 ad 8c 10 	movl   $0x108cad,0x4(%esp)
  102ae1:	00 
  102ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102ae5:	89 04 24             	mov    %eax,(%esp)
  102ae8:	e8 e7 54 00 00       	call   107fd4 <memcmp>
  102aed:	85 c0                	test   %eax,%eax
  102aef:	74 07                	je     102af8 <mpconfig+0x54>
		return 0;
  102af1:	b8 00 00 00 00       	mov    $0x0,%eax
  102af6:	eb 4c                	jmp    102b44 <mpconfig+0xa0>
	if (conf->version != 1 && conf->version != 4)
  102af8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102afb:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102aff:	3c 01                	cmp    $0x1,%al
  102b01:	74 12                	je     102b15 <mpconfig+0x71>
  102b03:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b06:	0f b6 40 06          	movzbl 0x6(%eax),%eax
  102b0a:	3c 04                	cmp    $0x4,%al
  102b0c:	74 07                	je     102b15 <mpconfig+0x71>
		return 0;
  102b0e:	b8 00 00 00 00       	mov    $0x0,%eax
  102b13:	eb 2f                	jmp    102b44 <mpconfig+0xa0>
	if (sum((uint8_t *) conf, conf->length) != 0)
  102b15:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b18:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102b1c:	0f b7 d0             	movzwl %ax,%edx
  102b1f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102b22:	89 54 24 04          	mov    %edx,0x4(%esp)
  102b26:	89 04 24             	mov    %eax,(%esp)
  102b29:	e8 21 fe ff ff       	call   10294f <sum>
  102b2e:	84 c0                	test   %al,%al
  102b30:	74 07                	je     102b39 <mpconfig+0x95>
		return 0;
  102b32:	b8 00 00 00 00       	mov    $0x0,%eax
  102b37:	eb 0b                	jmp    102b44 <mpconfig+0xa0>
       *pmp = mp;
  102b39:	8b 45 08             	mov    0x8(%ebp),%eax
  102b3c:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102b3f:	89 10                	mov    %edx,(%eax)
	return conf;
  102b41:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  102b44:	c9                   	leave  
  102b45:	c3                   	ret    

00102b46 <mp_init>:

void
mp_init(void)
{
  102b46:	55                   	push   %ebp
  102b47:	89 e5                	mov    %esp,%ebp
  102b49:	83 ec 48             	sub    $0x48,%esp
	struct mp      *mp;
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
  102b4c:	e8 e6 fd ff ff       	call   102937 <cpu_onboot>
  102b51:	85 c0                	test   %eax,%eax
  102b53:	0f 84 72 01 00 00    	je     102ccb <mp_init+0x185>
		return;

	if ((conf = mpconfig(&mp)) == 0)
  102b59:	8d 45 c8             	lea    -0x38(%ebp),%eax
  102b5c:	89 04 24             	mov    %eax,(%esp)
  102b5f:	e8 40 ff ff ff       	call   102aa4 <mpconfig>
  102b64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  102b67:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  102b6b:	0f 84 5d 01 00 00    	je     102cce <mp_init+0x188>
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
  102b71:	c7 05 30 ed 11 00 01 	movl   $0x1,0x11ed30
  102b78:	00 00 00 
	lapic = (uint32_t *) conf->lapicaddr;
  102b7b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102b7e:	8b 40 24             	mov    0x24(%eax),%eax
  102b81:	a3 04 20 12 00       	mov    %eax,0x122004
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102b86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102b89:	83 c0 2c             	add    $0x2c,%eax
  102b8c:	89 45 cc             	mov    %eax,-0x34(%ebp)
  102b8f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  102b92:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  102b95:	0f b7 40 04          	movzwl 0x4(%eax),%eax
  102b99:	0f b7 c0             	movzwl %ax,%eax
  102b9c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  102b9f:	89 45 d0             	mov    %eax,-0x30(%ebp)
  102ba2:	e9 cc 00 00 00       	jmp    102c73 <mp_init+0x12d>
			p < e;) {
		switch (*p) {
  102ba7:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102baa:	0f b6 00             	movzbl (%eax),%eax
  102bad:	0f b6 c0             	movzbl %al,%eax
  102bb0:	83 f8 04             	cmp    $0x4,%eax
  102bb3:	0f 87 90 00 00 00    	ja     102c49 <mp_init+0x103>
  102bb9:	8b 04 85 e0 8c 10 00 	mov    0x108ce0(,%eax,4),%eax
  102bc0:	ff e0                	jmp    *%eax
		case MPPROC:
			proc = (struct mpproc *) p;
  102bc2:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102bc5:	89 45 d8             	mov    %eax,-0x28(%ebp)
			p += sizeof(struct mpproc);
  102bc8:	83 45 cc 14          	addl   $0x14,-0x34(%ebp)
			if (!(proc->flags & MPENAB))
  102bcc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102bcf:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102bd3:	0f b6 c0             	movzbl %al,%eax
  102bd6:	83 e0 01             	and    $0x1,%eax
  102bd9:	85 c0                	test   %eax,%eax
  102bdb:	0f 84 91 00 00 00    	je     102c72 <mp_init+0x12c>
				continue;	// processor disabled

			// Get a cpu struct and kernel stack for this CPU.
			cpu *c = (proc->flags & MPBOOT)
  102be1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102be4:	0f b6 40 03          	movzbl 0x3(%eax),%eax
  102be8:	0f b6 c0             	movzbl %al,%eax
  102beb:	83 e0 02             	and    $0x2,%eax
					? &cpu_boot : cpu_alloc();
  102bee:	85 c0                	test   %eax,%eax
  102bf0:	75 07                	jne    102bf9 <mp_init+0xb3>
  102bf2:	e8 ad e7 ff ff       	call   1013a4 <cpu_alloc>
  102bf7:	eb 05                	jmp    102bfe <mp_init+0xb8>
  102bf9:	b8 00 b0 10 00       	mov    $0x10b000,%eax
  102bfe:	89 45 e0             	mov    %eax,-0x20(%ebp)
			c->id = proc->apicid;
  102c01:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102c04:	0f b6 50 01          	movzbl 0x1(%eax),%edx
  102c08:	8b 45 e0             	mov    -0x20(%ebp),%eax
  102c0b:	88 90 ac 00 00 00    	mov    %dl,0xac(%eax)
			ncpu++;
  102c11:	a1 34 ed 11 00       	mov    0x11ed34,%eax
  102c16:	83 c0 01             	add    $0x1,%eax
  102c19:	a3 34 ed 11 00       	mov    %eax,0x11ed34
			continue;
  102c1e:	eb 53                	jmp    102c73 <mp_init+0x12d>
		case MPIOAPIC:
			mpio = (struct mpioapic *) p;
  102c20:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102c23:	89 45 dc             	mov    %eax,-0x24(%ebp)
			p += sizeof(struct mpioapic);
  102c26:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			ioapicid = mpio->apicno;
  102c2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102c2d:	0f b6 40 01          	movzbl 0x1(%eax),%eax
  102c31:	a2 28 ed 11 00       	mov    %al,0x11ed28
			ioapic = (struct ioapic *) mpio->addr;
  102c36:	8b 45 dc             	mov    -0x24(%ebp),%eax
  102c39:	8b 40 04             	mov    0x4(%eax),%eax
  102c3c:	a3 2c ed 11 00       	mov    %eax,0x11ed2c
			continue;
  102c41:	eb 30                	jmp    102c73 <mp_init+0x12d>
		case MPBUS:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
  102c43:	83 45 cc 08          	addl   $0x8,-0x34(%ebp)
			continue;
  102c47:	eb 2a                	jmp    102c73 <mp_init+0x12d>
		default:
			panic("mpinit: unknown config type %x\n", *p);
  102c49:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102c4c:	0f b6 00             	movzbl (%eax),%eax
  102c4f:	0f b6 c0             	movzbl %al,%eax
  102c52:	89 44 24 0c          	mov    %eax,0xc(%esp)
  102c56:	c7 44 24 08 b4 8c 10 	movl   $0x108cb4,0x8(%esp)
  102c5d:	00 
  102c5e:	c7 44 24 04 92 00 00 	movl   $0x92,0x4(%esp)
  102c65:	00 
  102c66:	c7 04 24 d4 8c 10 00 	movl   $0x108cd4,(%esp)
  102c6d:	e8 46 d8 ff ff       	call   1004b8 <debug_panic>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *) p;
			p += sizeof(struct mpproc);
			if (!(proc->flags & MPENAB))
				continue;	// processor disabled
  102c72:	90                   	nop
	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.

	ismp = 1;
	lapic = (uint32_t *) conf->lapicaddr;
	for (p = (uint8_t *) (conf + 1), e = (uint8_t *) conf + conf->length;
  102c73:	8b 45 cc             	mov    -0x34(%ebp),%eax
  102c76:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102c79:	0f 82 28 ff ff ff    	jb     102ba7 <mp_init+0x61>
			continue;
		default:
			panic("mpinit: unknown config type %x\n", *p);
		}
	}
	if (mp->imcrp) {
  102c7f:	8b 45 c8             	mov    -0x38(%ebp),%eax
  102c82:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
  102c86:	84 c0                	test   %al,%al
  102c88:	74 45                	je     102ccf <mp_init+0x189>
  102c8a:	c7 45 e8 22 00 00 00 	movl   $0x22,-0x18(%ebp)
  102c91:	c6 45 e7 70          	movb   $0x70,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102c95:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  102c99:	8b 55 e8             	mov    -0x18(%ebp),%edx
  102c9c:	ee                   	out    %al,(%dx)
  102c9d:	c7 45 ec 23 00 00 00 	movl   $0x23,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  102ca4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102ca7:	89 c2                	mov    %eax,%edx
  102ca9:	ec                   	in     (%dx),%al
  102caa:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  102cad:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
  102cb1:	83 c8 01             	or     $0x1,%eax
  102cb4:	0f b6 c0             	movzbl %al,%eax
  102cb7:	c7 45 f4 23 00 00 00 	movl   $0x23,-0xc(%ebp)
  102cbe:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  102cc1:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  102cc5:	8b 55 f4             	mov    -0xc(%ebp),%edx
  102cc8:	ee                   	out    %al,(%dx)
  102cc9:	eb 04                	jmp    102ccf <mp_init+0x189>
	struct mpconf  *conf;
	struct mpproc  *proc;
	struct mpioapic *mpio;

	if (!cpu_onboot())	// only do once, on the boot CPU
		return;
  102ccb:	90                   	nop
  102ccc:	eb 01                	jmp    102ccf <mp_init+0x189>

	if ((conf = mpconfig(&mp)) == 0)
		return; // Not a multiprocessor machine - just use boot CPU.
  102cce:	90                   	nop
		// Bochs doesn 't support IMCR, so this doesn' t run on Bochs.
		// But it would on real hardware.
		outb(0x22, 0x70);		// Select IMCR
		outb(0x23, inb(0x23) | 1);	// Mask external interrupts.
	}
}
  102ccf:	c9                   	leave  
  102cd0:	c3                   	ret    
  102cd1:	90                   	nop
  102cd2:	90                   	nop
  102cd3:	90                   	nop

00102cd4 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  102cd4:	55                   	push   %ebp
  102cd5:	89 e5                	mov    %esp,%ebp
  102cd7:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  102cda:	8b 55 08             	mov    0x8(%ebp),%edx
  102cdd:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ce0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  102ce3:	f0 87 02             	lock xchg %eax,(%edx)
  102ce6:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  102ce9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  102cec:	c9                   	leave  
  102ced:	c3                   	ret    

00102cee <pause>:
	return result;
}

static inline void
pause(void)
{
  102cee:	55                   	push   %ebp
  102cef:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  102cf1:	f3 90                	pause  
}
  102cf3:	5d                   	pop    %ebp
  102cf4:	c3                   	ret    

00102cf5 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  102cf5:	55                   	push   %ebp
  102cf6:	89 e5                	mov    %esp,%ebp
  102cf8:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  102cfb:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  102cfe:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  102d01:	89 45 f0             	mov    %eax,-0x10(%ebp)
  102d04:	8b 45 f0             	mov    -0x10(%ebp),%eax
  102d07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  102d0c:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  102d0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  102d12:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  102d18:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  102d1d:	74 24                	je     102d43 <cpu_cur+0x4e>
  102d1f:	c7 44 24 0c f4 8c 10 	movl   $0x108cf4,0xc(%esp)
  102d26:	00 
  102d27:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  102d2e:	00 
  102d2f:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  102d36:	00 
  102d37:	c7 04 24 1f 8d 10 00 	movl   $0x108d1f,(%esp)
  102d3e:	e8 75 d7 ff ff       	call   1004b8 <debug_panic>
	return c;
  102d43:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  102d46:	c9                   	leave  
  102d47:	c3                   	ret    

00102d48 <spinlock_init_>:



void
spinlock_init_(struct spinlock *lk, const char *file, int line)
{
  102d48:	55                   	push   %ebp
  102d49:	89 e5                	mov    %esp,%ebp
  102d4b:	83 ec 08             	sub    $0x8,%esp
	lk->cpu = NULL;
  102d4e:	8b 45 08             	mov    0x8(%ebp),%eax
  102d51:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	lk->file = file; /* static string somewhere in memory? */
  102d58:	8b 45 08             	mov    0x8(%ebp),%eax
  102d5b:	8b 55 0c             	mov    0xc(%ebp),%edx
  102d5e:	89 50 04             	mov    %edx,0x4(%eax)
	lk->line = line;
  102d61:	8b 45 08             	mov    0x8(%ebp),%eax
  102d64:	8b 55 10             	mov    0x10(%ebp),%edx
  102d67:	89 50 08             	mov    %edx,0x8(%eax)
	xchg(&(lk->locked), 0);
  102d6a:	8b 45 08             	mov    0x8(%ebp),%eax
  102d6d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102d74:	00 
  102d75:	89 04 24             	mov    %eax,(%esp)
  102d78:	e8 57 ff ff ff       	call   102cd4 <xchg>
}
  102d7d:	c9                   	leave  
  102d7e:	c3                   	ret    

00102d7f <spinlock_acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spinlock_acquire(struct spinlock *lk)
{
  102d7f:	55                   	push   %ebp
  102d80:	89 e5                	mov    %esp,%ebp
  102d82:	83 ec 28             	sub    $0x28,%esp
	if(spinlock_holding(lk)) panic("cpu already holds lock.\n");
  102d85:	8b 45 08             	mov    0x8(%ebp),%eax
  102d88:	89 04 24             	mov    %eax,(%esp)
  102d8b:	e8 d2 00 00 00       	call   102e62 <spinlock_holding>
  102d90:	85 c0                	test   %eax,%eax
  102d92:	74 23                	je     102db7 <spinlock_acquire+0x38>
  102d94:	c7 44 24 08 2c 8d 10 	movl   $0x108d2c,0x8(%esp)
  102d9b:	00 
  102d9c:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  102da3:	00 
  102da4:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  102dab:	e8 08 d7 ff ff       	call   1004b8 <debug_panic>
	while(xchg(&(lk->locked), 1)) pause();
  102db0:	e8 39 ff ff ff       	call   102cee <pause>
  102db5:	eb 01                	jmp    102db8 <spinlock_acquire+0x39>
  102db7:	90                   	nop
  102db8:	8b 45 08             	mov    0x8(%ebp),%eax
  102dbb:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  102dc2:	00 
  102dc3:	89 04 24             	mov    %eax,(%esp)
  102dc6:	e8 09 ff ff ff       	call   102cd4 <xchg>
  102dcb:	85 c0                	test   %eax,%eax
  102dcd:	75 e1                	jne    102db0 <spinlock_acquire+0x31>
	lk->cpu = cpu_cur();
  102dcf:	e8 21 ff ff ff       	call   102cf5 <cpu_cur>
  102dd4:	8b 55 08             	mov    0x8(%ebp),%edx
  102dd7:	89 42 0c             	mov    %eax,0xc(%edx)
	debug_trace(read_ebp(), lk->eips);
  102dda:	8b 45 08             	mov    0x8(%ebp),%eax
  102ddd:	8d 50 10             	lea    0x10(%eax),%edx

static gcc_inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=rm" (ebp));
  102de0:	89 6d f4             	mov    %ebp,-0xc(%ebp)
        return ebp;
  102de3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  102de6:	89 54 24 04          	mov    %edx,0x4(%esp)
  102dea:	89 04 24             	mov    %eax,(%esp)
  102ded:	e8 ce d7 ff ff       	call   1005c0 <debug_trace>
}
  102df2:	c9                   	leave  
  102df3:	c3                   	ret    

00102df4 <spinlock_release>:

// Release the lock.
void
spinlock_release(struct spinlock *lk)
{
  102df4:	55                   	push   %ebp
  102df5:	89 e5                	mov    %esp,%ebp
  102df7:	83 ec 18             	sub    $0x18,%esp
	if(!spinlock_holding(lk)) panic("cpu not holding lock.\n");
  102dfa:	8b 45 08             	mov    0x8(%ebp),%eax
  102dfd:	89 04 24             	mov    %eax,(%esp)
  102e00:	e8 5d 00 00 00       	call   102e62 <spinlock_holding>
  102e05:	85 c0                	test   %eax,%eax
  102e07:	75 1c                	jne    102e25 <spinlock_release+0x31>
  102e09:	c7 44 24 08 55 8d 10 	movl   $0x108d55,0x8(%esp)
  102e10:	00 
  102e11:	c7 44 24 04 2f 00 00 	movl   $0x2f,0x4(%esp)
  102e18:	00 
  102e19:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  102e20:	e8 93 d6 ff ff       	call   1004b8 <debug_panic>
	lk->cpu = NULL;
  102e25:	8b 45 08             	mov    0x8(%ebp),%eax
  102e28:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
	memset(lk->eips, 0, sizeof(lk->eips));
  102e2f:	8b 45 08             	mov    0x8(%ebp),%eax
  102e32:	83 c0 10             	add    $0x10,%eax
  102e35:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
  102e3c:	00 
  102e3d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102e44:	00 
  102e45:	89 04 24             	mov    %eax,(%esp)
  102e48:	e8 17 50 00 00       	call   107e64 <memset>
	xchg(&(lk->locked), 0);
  102e4d:	8b 45 08             	mov    0x8(%ebp),%eax
  102e50:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  102e57:	00 
  102e58:	89 04 24             	mov    %eax,(%esp)
  102e5b:	e8 74 fe ff ff       	call   102cd4 <xchg>
}
  102e60:	c9                   	leave  
  102e61:	c3                   	ret    

00102e62 <spinlock_holding>:

// Check whether this cpu is holding the lock.
int
spinlock_holding(spinlock *lock)
{
  102e62:	55                   	push   %ebp
  102e63:	89 e5                	mov    %esp,%ebp
  102e65:	53                   	push   %ebx
  102e66:	83 ec 04             	sub    $0x4,%esp
	return lock->locked && (lock->cpu == cpu_cur());
  102e69:	8b 45 08             	mov    0x8(%ebp),%eax
  102e6c:	8b 00                	mov    (%eax),%eax
  102e6e:	85 c0                	test   %eax,%eax
  102e70:	74 16                	je     102e88 <spinlock_holding+0x26>
  102e72:	8b 45 08             	mov    0x8(%ebp),%eax
  102e75:	8b 58 0c             	mov    0xc(%eax),%ebx
  102e78:	e8 78 fe ff ff       	call   102cf5 <cpu_cur>
  102e7d:	39 c3                	cmp    %eax,%ebx
  102e7f:	75 07                	jne    102e88 <spinlock_holding+0x26>
  102e81:	b8 01 00 00 00       	mov    $0x1,%eax
  102e86:	eb 05                	jmp    102e8d <spinlock_holding+0x2b>
  102e88:	b8 00 00 00 00       	mov    $0x0,%eax
}
  102e8d:	83 c4 04             	add    $0x4,%esp
  102e90:	5b                   	pop    %ebx
  102e91:	5d                   	pop    %ebp
  102e92:	c3                   	ret    

00102e93 <spinlock_godeep>:
// Function that simply recurses to a specified depth.
// The useless return value and volatile parameter are
// so GCC doesn't collapse it via tail-call elimination.
int gcc_noinline
spinlock_godeep(volatile int depth, spinlock* lk)
{
  102e93:	55                   	push   %ebp
  102e94:	89 e5                	mov    %esp,%ebp
  102e96:	83 ec 18             	sub    $0x18,%esp
	if (depth==0) { spinlock_acquire(lk); return 1; }
  102e99:	8b 45 08             	mov    0x8(%ebp),%eax
  102e9c:	85 c0                	test   %eax,%eax
  102e9e:	75 12                	jne    102eb2 <spinlock_godeep+0x1f>
  102ea0:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ea3:	89 04 24             	mov    %eax,(%esp)
  102ea6:	e8 d4 fe ff ff       	call   102d7f <spinlock_acquire>
  102eab:	b8 01 00 00 00       	mov    $0x1,%eax
  102eb0:	eb 1b                	jmp    102ecd <spinlock_godeep+0x3a>
	else return spinlock_godeep(depth-1, lk) * depth;
  102eb2:	8b 45 08             	mov    0x8(%ebp),%eax
  102eb5:	8d 50 ff             	lea    -0x1(%eax),%edx
  102eb8:	8b 45 0c             	mov    0xc(%ebp),%eax
  102ebb:	89 44 24 04          	mov    %eax,0x4(%esp)
  102ebf:	89 14 24             	mov    %edx,(%esp)
  102ec2:	e8 cc ff ff ff       	call   102e93 <spinlock_godeep>
  102ec7:	8b 55 08             	mov    0x8(%ebp),%edx
  102eca:	0f af c2             	imul   %edx,%eax
}
  102ecd:	c9                   	leave  
  102ece:	c3                   	ret    

00102ecf <spinlock_check>:

void spinlock_check()
{
  102ecf:	55                   	push   %ebp
  102ed0:	89 e5                	mov    %esp,%ebp
  102ed2:	57                   	push   %edi
  102ed3:	56                   	push   %esi
  102ed4:	53                   	push   %ebx
  102ed5:	83 ec 5c             	sub    $0x5c,%esp
  102ed8:	89 e0                	mov    %esp,%eax
  102eda:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	const int NUMLOCKS=10;
  102edd:	c7 45 d0 0a 00 00 00 	movl   $0xa,-0x30(%ebp)
	const int NUMRUNS=5;
  102ee4:	c7 45 d4 05 00 00 00 	movl   $0x5,-0x2c(%ebp)
	int i,j,run;
	const char* file = "spinlock_check";
  102eeb:	c7 45 e4 6c 8d 10 00 	movl   $0x108d6c,-0x1c(%ebp)
	spinlock locks[NUMLOCKS];
  102ef2:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102ef5:	83 e8 01             	sub    $0x1,%eax
  102ef8:	89 45 c8             	mov    %eax,-0x38(%ebp)
  102efb:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102efe:	ba 00 00 00 00       	mov    $0x0,%edx
  102f03:	89 c1                	mov    %eax,%ecx
  102f05:	80 e5 ff             	and    $0xff,%ch
  102f08:	89 d3                	mov    %edx,%ebx
  102f0a:	83 e3 0f             	and    $0xf,%ebx
  102f0d:	89 c8                	mov    %ecx,%eax
  102f0f:	89 da                	mov    %ebx,%edx
  102f11:	69 da c0 01 00 00    	imul   $0x1c0,%edx,%ebx
  102f17:	6b c8 00             	imul   $0x0,%eax,%ecx
  102f1a:	01 cb                	add    %ecx,%ebx
  102f1c:	b9 c0 01 00 00       	mov    $0x1c0,%ecx
  102f21:	f7 e1                	mul    %ecx
  102f23:	01 d3                	add    %edx,%ebx
  102f25:	89 da                	mov    %ebx,%edx
  102f27:	89 c6                	mov    %eax,%esi
  102f29:	83 e6 ff             	and    $0xffffffff,%esi
  102f2c:	89 d7                	mov    %edx,%edi
  102f2e:	83 e7 0f             	and    $0xf,%edi
  102f31:	89 f0                	mov    %esi,%eax
  102f33:	89 fa                	mov    %edi,%edx
  102f35:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102f38:	c1 e0 03             	shl    $0x3,%eax
  102f3b:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102f3e:	ba 00 00 00 00       	mov    $0x0,%edx
  102f43:	89 c1                	mov    %eax,%ecx
  102f45:	80 e5 ff             	and    $0xff,%ch
  102f48:	89 4d b8             	mov    %ecx,-0x48(%ebp)
  102f4b:	89 d3                	mov    %edx,%ebx
  102f4d:	83 e3 0f             	and    $0xf,%ebx
  102f50:	89 5d bc             	mov    %ebx,-0x44(%ebp)
  102f53:	8b 45 b8             	mov    -0x48(%ebp),%eax
  102f56:	8b 55 bc             	mov    -0x44(%ebp),%edx
  102f59:	69 ca c0 01 00 00    	imul   $0x1c0,%edx,%ecx
  102f5f:	6b d8 00             	imul   $0x0,%eax,%ebx
  102f62:	01 d9                	add    %ebx,%ecx
  102f64:	bb c0 01 00 00       	mov    $0x1c0,%ebx
  102f69:	f7 e3                	mul    %ebx
  102f6b:	01 d1                	add    %edx,%ecx
  102f6d:	89 ca                	mov    %ecx,%edx
  102f6f:	89 c1                	mov    %eax,%ecx
  102f71:	80 e5 ff             	and    $0xff,%ch
  102f74:	89 4d b0             	mov    %ecx,-0x50(%ebp)
  102f77:	89 d3                	mov    %edx,%ebx
  102f79:	83 e3 0f             	and    $0xf,%ebx
  102f7c:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
  102f7f:	8b 45 b0             	mov    -0x50(%ebp),%eax
  102f82:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  102f85:	8b 45 d0             	mov    -0x30(%ebp),%eax
  102f88:	c1 e0 03             	shl    $0x3,%eax
  102f8b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  102f92:	89 d1                	mov    %edx,%ecx
  102f94:	29 c1                	sub    %eax,%ecx
  102f96:	89 c8                	mov    %ecx,%eax
  102f98:	83 c0 0f             	add    $0xf,%eax
  102f9b:	83 c0 0f             	add    $0xf,%eax
  102f9e:	c1 e8 04             	shr    $0x4,%eax
  102fa1:	c1 e0 04             	shl    $0x4,%eax
  102fa4:	29 c4                	sub    %eax,%esp
  102fa6:	8d 44 24 10          	lea    0x10(%esp),%eax
  102faa:	83 c0 0f             	add    $0xf,%eax
  102fad:	c1 e8 04             	shr    $0x4,%eax
  102fb0:	c1 e0 04             	shl    $0x4,%eax
  102fb3:	89 45 cc             	mov    %eax,-0x34(%ebp)

	// Initialize the locks
	for(i=0;i<NUMLOCKS;i++) spinlock_init_(&locks[i], file, 0);
  102fb6:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  102fbd:	eb 33                	jmp    102ff2 <spinlock_check+0x123>
  102fbf:	8b 55 cc             	mov    -0x34(%ebp),%edx
  102fc2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102fc5:	c1 e0 03             	shl    $0x3,%eax
  102fc8:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  102fcf:	89 cb                	mov    %ecx,%ebx
  102fd1:	29 c3                	sub    %eax,%ebx
  102fd3:	89 d8                	mov    %ebx,%eax
  102fd5:	01 c2                	add    %eax,%edx
  102fd7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  102fde:	00 
  102fdf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  102fe2:	89 44 24 04          	mov    %eax,0x4(%esp)
  102fe6:	89 14 24             	mov    %edx,(%esp)
  102fe9:	e8 5a fd ff ff       	call   102d48 <spinlock_init_>
  102fee:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  102ff2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  102ff5:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  102ff8:	7c c5                	jl     102fbf <spinlock_check+0xf0>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
  102ffa:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103001:	eb 46                	jmp    103049 <spinlock_check+0x17a>
  103003:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103006:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  103009:	c1 e0 03             	shl    $0x3,%eax
  10300c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103013:	29 c2                	sub    %eax,%edx
  103015:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  103018:	83 c0 0c             	add    $0xc,%eax
  10301b:	8b 00                	mov    (%eax),%eax
  10301d:	85 c0                	test   %eax,%eax
  10301f:	74 24                	je     103045 <spinlock_check+0x176>
  103021:	c7 44 24 0c 7b 8d 10 	movl   $0x108d7b,0xc(%esp)
  103028:	00 
  103029:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  103030:	00 
  103031:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  103038:	00 
  103039:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  103040:	e8 73 d4 ff ff       	call   1004b8 <debug_panic>
  103045:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  103049:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10304c:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10304f:	7c b2                	jl     103003 <spinlock_check+0x134>
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);
  103051:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103058:	eb 47                	jmp    1030a1 <spinlock_check+0x1d2>
  10305a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10305d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  103060:	c1 e0 03             	shl    $0x3,%eax
  103063:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10306a:	29 c2                	sub    %eax,%edx
  10306c:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  10306f:	83 c0 04             	add    $0x4,%eax
  103072:	8b 00                	mov    (%eax),%eax
  103074:	3b 45 e4             	cmp    -0x1c(%ebp),%eax
  103077:	74 24                	je     10309d <spinlock_check+0x1ce>
  103079:	c7 44 24 0c 8e 8d 10 	movl   $0x108d8e,0xc(%esp)
  103080:	00 
  103081:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  103088:	00 
  103089:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  103090:	00 
  103091:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  103098:	e8 1b d4 ff ff       	call   1004b8 <debug_panic>
  10309d:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1030a1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1030a4:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1030a7:	7c b1                	jl     10305a <spinlock_check+0x18b>

	for (run=0;run<NUMRUNS;run++) 
  1030a9:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  1030b0:	e9 12 03 00 00       	jmp    1033c7 <spinlock_check+0x4f8>
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1030b5:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1030bc:	eb 2c                	jmp    1030ea <spinlock_check+0x21b>
			spinlock_godeep(i, &locks[i]);
  1030be:	8b 55 cc             	mov    -0x34(%ebp),%edx
  1030c1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1030c4:	c1 e0 03             	shl    $0x3,%eax
  1030c7:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  1030ce:	89 cb                	mov    %ecx,%ebx
  1030d0:	29 c3                	sub    %eax,%ebx
  1030d2:	89 d8                	mov    %ebx,%eax
  1030d4:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1030d7:	89 44 24 04          	mov    %eax,0x4(%esp)
  1030db:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1030de:	89 04 24             	mov    %eax,(%esp)
  1030e1:	e8 ad fd ff ff       	call   102e93 <spinlock_godeep>
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
	{
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
  1030e6:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1030ea:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1030ed:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1030f0:	7c cc                	jl     1030be <spinlock_check+0x1ef>
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  1030f2:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1030f9:	eb 4b                	jmp    103146 <spinlock_check+0x277>
			assert(locks[i].cpu == cpu_cur());
  1030fb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1030fe:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  103101:	c1 e0 03             	shl    $0x3,%eax
  103104:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  10310b:	29 c2                	sub    %eax,%edx
  10310d:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  103110:	83 c0 0c             	add    $0xc,%eax
  103113:	8b 18                	mov    (%eax),%ebx
  103115:	e8 db fb ff ff       	call   102cf5 <cpu_cur>
  10311a:	39 c3                	cmp    %eax,%ebx
  10311c:	74 24                	je     103142 <spinlock_check+0x273>
  10311e:	c7 44 24 0c a2 8d 10 	movl   $0x108da2,0xc(%esp)
  103125:	00 
  103126:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  10312d:	00 
  10312e:	c7 44 24 04 5d 00 00 	movl   $0x5d,0x4(%esp)
  103135:	00 
  103136:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  10313d:	e8 76 d3 ff ff       	call   1004b8 <debug_panic>
		// Lock all locks
		for(i=0;i<NUMLOCKS;i++)
			spinlock_godeep(i, &locks[i]);

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
  103142:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  103146:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103149:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10314c:	7c ad                	jl     1030fb <spinlock_check+0x22c>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  10314e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103155:	eb 4d                	jmp    1031a4 <spinlock_check+0x2d5>
			assert(spinlock_holding(&locks[i]) != 0);
  103157:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10315a:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10315d:	c1 e0 03             	shl    $0x3,%eax
  103160:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  103167:	89 cb                	mov    %ecx,%ebx
  103169:	29 c3                	sub    %eax,%ebx
  10316b:	89 d8                	mov    %ebx,%eax
  10316d:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103170:	89 04 24             	mov    %eax,(%esp)
  103173:	e8 ea fc ff ff       	call   102e62 <spinlock_holding>
  103178:	85 c0                	test   %eax,%eax
  10317a:	75 24                	jne    1031a0 <spinlock_check+0x2d1>
  10317c:	c7 44 24 0c bc 8d 10 	movl   $0x108dbc,0xc(%esp)
  103183:	00 
  103184:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  10318b:	00 
  10318c:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  103193:	00 
  103194:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  10319b:	e8 18 d3 ff ff       	call   1004b8 <debug_panic>

		// Make sure that all locks have the right CPU
		for(i=0;i<NUMLOCKS;i++)
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
  1031a0:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1031a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1031a7:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1031aa:	7c ab                	jl     103157 <spinlock_check+0x288>
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  1031ac:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1031b3:	e9 bd 00 00 00       	jmp    103275 <spinlock_check+0x3a6>
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  1031b8:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  1031bf:	e9 9b 00 00 00       	jmp    10325f <spinlock_check+0x390>
			{
				assert(locks[i].eips[j] >=
  1031c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1031c7:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  1031ca:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1031cd:	01 c0                	add    %eax,%eax
  1031cf:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1031d6:	29 c2                	sub    %eax,%edx
  1031d8:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  1031db:	83 c0 04             	add    $0x4,%eax
  1031de:	8b 14 81             	mov    (%ecx,%eax,4),%edx
  1031e1:	b8 93 2e 10 00       	mov    $0x102e93,%eax
  1031e6:	39 c2                	cmp    %eax,%edx
  1031e8:	73 24                	jae    10320e <spinlock_check+0x33f>
  1031ea:	c7 44 24 0c e0 8d 10 	movl   $0x108de0,0xc(%esp)
  1031f1:	00 
  1031f2:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  1031f9:	00 
  1031fa:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
  103201:	00 
  103202:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  103209:	e8 aa d2 ff ff       	call   1004b8 <debug_panic>
					(uint32_t)spinlock_godeep);
				assert(locks[i].eips[j] <
  10320e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103211:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  103214:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  103217:	01 c0                	add    %eax,%eax
  103219:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103220:	29 c2                	sub    %eax,%edx
  103222:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
  103225:	83 c0 04             	add    $0x4,%eax
  103228:	8b 04 81             	mov    (%ecx,%eax,4),%eax
  10322b:	ba 93 2e 10 00       	mov    $0x102e93,%edx
  103230:	83 c2 64             	add    $0x64,%edx
  103233:	39 d0                	cmp    %edx,%eax
  103235:	72 24                	jb     10325b <spinlock_check+0x38c>
  103237:	c7 44 24 0c 10 8e 10 	movl   $0x108e10,0xc(%esp)
  10323e:	00 
  10323f:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  103246:	00 
  103247:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
  10324e:	00 
  10324f:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  103256:	e8 5d d2 ff ff       	call   1004b8 <debug_panic>
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
		{
			for(j=0; j<=i && j < DEBUG_TRACEFRAMES ; j++) 
  10325b:	83 45 dc 01          	addl   $0x1,-0x24(%ebp)
  10325f:	8b 45 dc             	mov    -0x24(%ebp),%eax
  103262:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  103265:	7f 0a                	jg     103271 <spinlock_check+0x3a2>
  103267:	83 7d dc 09          	cmpl   $0x9,-0x24(%ebp)
  10326b:	0f 8e 53 ff ff ff    	jle    1031c4 <spinlock_check+0x2f5>
			assert(locks[i].cpu == cpu_cur());
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++)
			assert(spinlock_holding(&locks[i]) != 0);
		// Make sure that top i frames are somewhere in godeep.
		for(i=0;i<NUMLOCKS;i++) 
  103271:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  103275:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103278:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10327b:	0f 8c 37 ff ff ff    	jl     1031b8 <spinlock_check+0x2e9>
					(uint32_t)spinlock_godeep+100);
			}
		}

		// Release all locks
		for(i=0;i<NUMLOCKS;i++) spinlock_release(&locks[i]);
  103281:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103288:	eb 25                	jmp    1032af <spinlock_check+0x3e0>
  10328a:	8b 55 cc             	mov    -0x34(%ebp),%edx
  10328d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103290:	c1 e0 03             	shl    $0x3,%eax
  103293:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10329a:	89 cb                	mov    %ecx,%ebx
  10329c:	29 c3                	sub    %eax,%ebx
  10329e:	89 d8                	mov    %ebx,%eax
  1032a0:	8d 04 02             	lea    (%edx,%eax,1),%eax
  1032a3:	89 04 24             	mov    %eax,(%esp)
  1032a6:	e8 49 fb ff ff       	call   102df4 <spinlock_release>
  1032ab:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1032af:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1032b2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1032b5:	7c d3                	jl     10328a <spinlock_check+0x3bb>
		// Make sure that the CPU has been cleared
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
  1032b7:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  1032be:	eb 46                	jmp    103306 <spinlock_check+0x437>
  1032c0:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1032c3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  1032c6:	c1 e0 03             	shl    $0x3,%eax
  1032c9:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  1032d0:	29 c2                	sub    %eax,%edx
  1032d2:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  1032d5:	83 c0 0c             	add    $0xc,%eax
  1032d8:	8b 00                	mov    (%eax),%eax
  1032da:	85 c0                	test   %eax,%eax
  1032dc:	74 24                	je     103302 <spinlock_check+0x433>
  1032de:	c7 44 24 0c 41 8e 10 	movl   $0x108e41,0xc(%esp)
  1032e5:	00 
  1032e6:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  1032ed:	00 
  1032ee:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
  1032f5:	00 
  1032f6:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  1032fd:	e8 b6 d1 ff ff       	call   1004b8 <debug_panic>
  103302:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  103306:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103309:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  10330c:	7c b2                	jl     1032c0 <spinlock_check+0x3f1>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
  10330e:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103315:	eb 46                	jmp    10335d <spinlock_check+0x48e>
  103317:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10331a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
  10331d:	c1 e0 03             	shl    $0x3,%eax
  103320:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
  103327:	29 c2                	sub    %eax,%edx
  103329:	8d 04 11             	lea    (%ecx,%edx,1),%eax
  10332c:	83 c0 10             	add    $0x10,%eax
  10332f:	8b 00                	mov    (%eax),%eax
  103331:	85 c0                	test   %eax,%eax
  103333:	74 24                	je     103359 <spinlock_check+0x48a>
  103335:	c7 44 24 0c 56 8e 10 	movl   $0x108e56,0xc(%esp)
  10333c:	00 
  10333d:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  103344:	00 
  103345:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
  10334c:	00 
  10334d:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  103354:	e8 5f d1 ff ff       	call   1004b8 <debug_panic>
  103359:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  10335d:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103360:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  103363:	7c b2                	jl     103317 <spinlock_check+0x448>
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
  103365:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  10336c:	eb 4d                	jmp    1033bb <spinlock_check+0x4ec>
  10336e:	8b 55 cc             	mov    -0x34(%ebp),%edx
  103371:	8b 45 d8             	mov    -0x28(%ebp),%eax
  103374:	c1 e0 03             	shl    $0x3,%eax
  103377:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
  10337e:	89 cb                	mov    %ecx,%ebx
  103380:	29 c3                	sub    %eax,%ebx
  103382:	89 d8                	mov    %ebx,%eax
  103384:	8d 04 02             	lea    (%edx,%eax,1),%eax
  103387:	89 04 24             	mov    %eax,(%esp)
  10338a:	e8 d3 fa ff ff       	call   102e62 <spinlock_holding>
  10338f:	85 c0                	test   %eax,%eax
  103391:	74 24                	je     1033b7 <spinlock_check+0x4e8>
  103393:	c7 44 24 0c 6c 8e 10 	movl   $0x108e6c,0xc(%esp)
  10339a:	00 
  10339b:	c7 44 24 08 0a 8d 10 	movl   $0x108d0a,0x8(%esp)
  1033a2:	00 
  1033a3:	c7 44 24 04 73 00 00 	movl   $0x73,0x4(%esp)
  1033aa:	00 
  1033ab:	c7 04 24 45 8d 10 00 	movl   $0x108d45,(%esp)
  1033b2:	e8 01 d1 ff ff       	call   1004b8 <debug_panic>
  1033b7:	83 45 d8 01          	addl   $0x1,-0x28(%ebp)
  1033bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1033be:	3b 45 d0             	cmp    -0x30(%ebp),%eax
  1033c1:	7c ab                	jl     10336e <spinlock_check+0x49f>
	// Make sure that all locks have CPU set to NULL initially
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu==NULL);
	// Make sure that all locks have the correct debug info.
	for(i=0;i<NUMLOCKS;i++) assert(locks[i].file==file);

	for (run=0;run<NUMRUNS;run++) 
  1033c3:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
  1033c7:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1033ca:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  1033cd:	0f 8c e2 fc ff ff    	jl     1030b5 <spinlock_check+0x1e6>
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].cpu == NULL);
		for(i=0;i<NUMLOCKS;i++) assert(locks[i].eips[0]==0);
		// Make sure that all locks have holding correctly implemented.
		for(i=0;i<NUMLOCKS;i++) assert(spinlock_holding(&locks[i]) == 0);
	}
	cprintf("spinlock_check() succeeded!\n");
  1033d3:	c7 04 24 8d 8e 10 00 	movl   $0x108e8d,(%esp)
  1033da:	e8 9e 48 00 00       	call   107c7d <cprintf>
  1033df:	8b 65 c4             	mov    -0x3c(%ebp),%esp
}
  1033e2:	8d 65 f4             	lea    -0xc(%ebp),%esp
  1033e5:	83 c4 00             	add    $0x0,%esp
  1033e8:	5b                   	pop    %ebx
  1033e9:	5e                   	pop    %esi
  1033ea:	5f                   	pop    %edi
  1033eb:	5d                   	pop    %ebp
  1033ec:	c3                   	ret    
  1033ed:	90                   	nop
  1033ee:	90                   	nop
  1033ef:	90                   	nop

001033f0 <xchg>:
}

// Atomically set *addr to newval and return the old value of *addr.
static inline uint32_t
xchg(volatile uint32_t *addr, uint32_t newval)
{
  1033f0:	55                   	push   %ebp
  1033f1:	89 e5                	mov    %esp,%ebp
  1033f3:	83 ec 10             	sub    $0x10,%esp
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
  1033f6:	8b 55 08             	mov    0x8(%ebp),%edx
  1033f9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1033fc:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1033ff:	f0 87 02             	lock xchg %eax,(%edx)
  103402:	89 45 fc             	mov    %eax,-0x4(%ebp)
	       "+m" (*addr), "=a" (result) :
	       "1" (newval) :
	       "cc");
	return result;
  103405:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  103408:	c9                   	leave  
  103409:	c3                   	ret    

0010340a <lockadd>:

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  10340a:	55                   	push   %ebp
  10340b:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  10340d:	8b 45 08             	mov    0x8(%ebp),%eax
  103410:	8b 55 0c             	mov    0xc(%ebp),%edx
  103413:	8b 4d 08             	mov    0x8(%ebp),%ecx
  103416:	f0 01 10             	lock add %edx,(%eax)
}
  103419:	5d                   	pop    %ebp
  10341a:	c3                   	ret    

0010341b <pause>:
	return result;
}

static inline void
pause(void)
{
  10341b:	55                   	push   %ebp
  10341c:	89 e5                	mov    %esp,%ebp
	asm volatile("pause" : : : "memory");
  10341e:	f3 90                	pause  
}
  103420:	5d                   	pop    %ebp
  103421:	c3                   	ret    

00103422 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  103422:	55                   	push   %ebp
  103423:	89 e5                	mov    %esp,%ebp
  103425:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  103428:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  10342b:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  10342e:	89 45 f0             	mov    %eax,-0x10(%ebp)
  103431:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103434:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  103439:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  10343c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10343f:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  103445:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  10344a:	74 24                	je     103470 <cpu_cur+0x4e>
  10344c:	c7 44 24 0c ac 8e 10 	movl   $0x108eac,0xc(%esp)
  103453:	00 
  103454:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  10345b:	00 
  10345c:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  103463:	00 
  103464:	c7 04 24 d7 8e 10 00 	movl   $0x108ed7,(%esp)
  10346b:	e8 48 d0 ff ff       	call   1004b8 <debug_panic>
	return c;
  103470:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  103473:	c9                   	leave  
  103474:	c3                   	ret    

00103475 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  103475:	55                   	push   %ebp
  103476:	89 e5                	mov    %esp,%ebp
  103478:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  10347b:	e8 a2 ff ff ff       	call   103422 <cpu_cur>
  103480:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  103485:	0f 94 c0             	sete   %al
  103488:	0f b6 c0             	movzbl %al,%eax
}
  10348b:	c9                   	leave  
  10348c:	c3                   	ret    

0010348d <proc_init>:
proc* proc_last;


void
proc_init(void)
{
  10348d:	55                   	push   %ebp
  10348e:	89 e5                	mov    %esp,%ebp
  103490:	83 ec 18             	sub    $0x18,%esp
	if (!cpu_onboot())
  103493:	e8 dd ff ff ff       	call   103475 <cpu_onboot>
  103498:	85 c0                	test   %eax,%eax
  10349a:	74 32                	je     1034ce <proc_init+0x41>
		return;

	spinlock_init(&proc_lock);
  10349c:	c7 44 24 08 25 00 00 	movl   $0x25,0x8(%esp)
  1034a3:	00 
  1034a4:	c7 44 24 04 e4 8e 10 	movl   $0x108ee4,0x4(%esp)
  1034ab:	00 
  1034ac:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  1034b3:	e8 90 f8 ff ff       	call   102d48 <spinlock_init_>
	proc_first = NULL;
  1034b8:	c7 05 f4 f3 11 00 00 	movl   $0x0,0x11f3f4
  1034bf:	00 00 00 
	proc_last = NULL;
  1034c2:	c7 05 f8 f3 11 00 00 	movl   $0x0,0x11f3f8
  1034c9:	00 00 00 
  1034cc:	eb 01                	jmp    1034cf <proc_init+0x42>

void
proc_init(void)
{
	if (!cpu_onboot())
		return;
  1034ce:	90                   	nop

	spinlock_init(&proc_lock);
	proc_first = NULL;
	proc_last = NULL;
}
  1034cf:	c9                   	leave  
  1034d0:	c3                   	ret    

001034d1 <proc_alloc>:

// Allocate and initialize a new proc as child 'cn' of parent 'p'.
// Returns NULL if no physical memory available.
proc *
proc_alloc(proc *p, uint32_t cn)
{
  1034d1:	55                   	push   %ebp
  1034d2:	89 e5                	mov    %esp,%ebp
  1034d4:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  1034d7:	e8 7d d7 ff ff       	call   100c59 <mem_alloc>
  1034dc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (!pi)
  1034df:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1034e3:	75 0a                	jne    1034ef <proc_alloc+0x1e>
		return NULL;
  1034e5:	b8 00 00 00 00       	mov    $0x0,%eax
  1034ea:	e9 b4 01 00 00       	jmp    1036a3 <proc_alloc+0x1d2>
  1034ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1034f2:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1034f5:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1034fa:	83 c0 08             	add    $0x8,%eax
  1034fd:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103500:	76 15                	jbe    103517 <proc_alloc+0x46>
  103502:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  103507:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  10350d:	c1 e2 03             	shl    $0x3,%edx
  103510:	01 d0                	add    %edx,%eax
  103512:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103515:	72 24                	jb     10353b <proc_alloc+0x6a>
  103517:	c7 44 24 0c f0 8e 10 	movl   $0x108ef0,0xc(%esp)
  10351e:	00 
  10351f:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  103526:	00 
  103527:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  10352e:	00 
  10352f:	c7 04 24 27 8f 10 00 	movl   $0x108f27,(%esp)
  103536:	e8 7d cf ff ff       	call   1004b8 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  10353b:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  103540:	ba 00 10 12 00       	mov    $0x121000,%edx
  103545:	c1 ea 0c             	shr    $0xc,%edx
  103548:	c1 e2 03             	shl    $0x3,%edx
  10354b:	01 d0                	add    %edx,%eax
  10354d:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  103550:	75 24                	jne    103576 <proc_alloc+0xa5>
  103552:	c7 44 24 0c 34 8f 10 	movl   $0x108f34,0xc(%esp)
  103559:	00 
  10355a:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  103561:	00 
  103562:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  103569:	00 
  10356a:	c7 04 24 27 8f 10 00 	movl   $0x108f27,(%esp)
  103571:	e8 42 cf ff ff       	call   1004b8 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  103576:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  10357b:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  103580:	c1 ea 0c             	shr    $0xc,%edx
  103583:	c1 e2 03             	shl    $0x3,%edx
  103586:	01 d0                	add    %edx,%eax
  103588:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10358b:	72 3b                	jb     1035c8 <proc_alloc+0xf7>
  10358d:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  103592:	ba 07 20 12 00       	mov    $0x122007,%edx
  103597:	c1 ea 0c             	shr    $0xc,%edx
  10359a:	c1 e2 03             	shl    $0x3,%edx
  10359d:	01 d0                	add    %edx,%eax
  10359f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1035a2:	77 24                	ja     1035c8 <proc_alloc+0xf7>
  1035a4:	c7 44 24 0c 50 8f 10 	movl   $0x108f50,0xc(%esp)
  1035ab:	00 
  1035ac:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  1035b3:	00 
  1035b4:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  1035bb:	00 
  1035bc:	c7 04 24 27 8f 10 00 	movl   $0x108f27,(%esp)
  1035c3:	e8 f0 ce ff ff       	call   1004b8 <debug_panic>

	lockadd(&pi->refcount, 1);
  1035c8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1035cb:	83 c0 04             	add    $0x4,%eax
  1035ce:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1035d5:	00 
  1035d6:	89 04 24             	mov    %eax,(%esp)
  1035d9:	e8 2c fe ff ff       	call   10340a <lockadd>
	mem_incref(pi);

	proc *cp = (proc*)mem_pi2ptr(pi);
  1035de:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1035e1:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1035e6:	89 d1                	mov    %edx,%ecx
  1035e8:	29 c1                	sub    %eax,%ecx
  1035ea:	89 c8                	mov    %ecx,%eax
  1035ec:	c1 f8 03             	sar    $0x3,%eax
  1035ef:	c1 e0 0c             	shl    $0xc,%eax
  1035f2:	89 45 f0             	mov    %eax,-0x10(%ebp)
	memset(cp, 0, sizeof(proc));
  1035f5:	c7 44 24 08 b0 06 00 	movl   $0x6b0,0x8(%esp)
  1035fc:	00 
  1035fd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  103604:	00 
  103605:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103608:	89 04 24             	mov    %eax,(%esp)
  10360b:	e8 54 48 00 00       	call   107e64 <memset>
	spinlock_init(&cp->lock);
  103610:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103613:	c7 44 24 08 36 00 00 	movl   $0x36,0x8(%esp)
  10361a:	00 
  10361b:	c7 44 24 04 e4 8e 10 	movl   $0x108ee4,0x4(%esp)
  103622:	00 
  103623:	89 04 24             	mov    %eax,(%esp)
  103626:	e8 1d f7 ff ff       	call   102d48 <spinlock_init_>
	cp->parent = p;
  10362b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10362e:	8b 55 08             	mov    0x8(%ebp),%edx
  103631:	89 50 38             	mov    %edx,0x38(%eax)
	cp->state = PROC_STOP;
  103634:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103637:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  10363e:	00 00 00 

	// Integer register state
	cp->sv.tf.eflags = (FL_IOPL_MASK & FL_IOPL_3) | FL_IF;
  103641:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103644:	c7 80 90 04 00 00 00 	movl   $0x3200,0x490(%eax)
  10364b:	32 00 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  10364e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103651:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  103658:	1b 00 
	cp->sv.tf.ds = CPU_GDT_UDATA | 3;
  10365a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10365d:	66 c7 80 7c 04 00 00 	movw   $0x23,0x47c(%eax)
  103664:	23 00 
	cp->sv.tf.es = CPU_GDT_UDATA | 3;
  103666:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103669:	66 c7 80 78 04 00 00 	movw   $0x23,0x478(%eax)
  103670:	23 00 
	cp->sv.tf.cs = CPU_GDT_UCODE | 3;
  103672:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103675:	66 c7 80 8c 04 00 00 	movw   $0x1b,0x48c(%eax)
  10367c:	1b 00 
	cp->sv.tf.ss = CPU_GDT_UDATA | 3;
  10367e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103681:	66 c7 80 98 04 00 00 	movw   $0x23,0x498(%eax)
  103688:	23 00 


	if (p)
  10368a:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  10368e:	74 10                	je     1036a0 <proc_alloc+0x1cf>
		p->child[cn] = cp;
  103690:	8b 55 0c             	mov    0xc(%ebp),%edx
  103693:	8b 45 08             	mov    0x8(%ebp),%eax
  103696:	8d 4a 0c             	lea    0xc(%edx),%ecx
  103699:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10369c:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
	return cp;
  1036a0:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1036a3:	c9                   	leave  
  1036a4:	c3                   	ret    

001036a5 <proc_ready>:

// Put process p in the ready state and add it to the ready queue.
void
proc_ready(proc *p)
{
  1036a5:	55                   	push   %ebp
  1036a6:	89 e5                	mov    %esp,%ebp
  1036a8:	83 ec 18             	sub    $0x18,%esp
	// cprintf("proc_ready %p\n", p);
	spinlock_acquire(&proc_lock);
  1036ab:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  1036b2:	e8 c8 f6 ff ff       	call   102d7f <spinlock_acquire>
	if(proc_last) {
  1036b7:	a1 f8 f3 11 00       	mov    0x11f3f8,%eax
  1036bc:	85 c0                	test   %eax,%eax
  1036be:	74 32                	je     1036f2 <proc_ready+0x4d>
		spinlock_acquire(&(proc_last->lock));
  1036c0:	a1 f8 f3 11 00       	mov    0x11f3f8,%eax
  1036c5:	89 04 24             	mov    %eax,(%esp)
  1036c8:	e8 b2 f6 ff ff       	call   102d7f <spinlock_acquire>
		proc_last->readynext = p;
  1036cd:	a1 f8 f3 11 00       	mov    0x11f3f8,%eax
  1036d2:	8b 55 08             	mov    0x8(%ebp),%edx
  1036d5:	89 90 40 04 00 00    	mov    %edx,0x440(%eax)
		spinlock_release(&(proc_last->lock));
  1036db:	a1 f8 f3 11 00       	mov    0x11f3f8,%eax
  1036e0:	89 04 24             	mov    %eax,(%esp)
  1036e3:	e8 0c f7 ff ff       	call   102df4 <spinlock_release>
		proc_last = p;
  1036e8:	8b 45 08             	mov    0x8(%ebp),%eax
  1036eb:	a3 f8 f3 11 00       	mov    %eax,0x11f3f8
  1036f0:	eb 3d                	jmp    10372f <proc_ready+0x8a>
	} else {
		assert(!proc_first);
  1036f2:	a1 f4 f3 11 00       	mov    0x11f3f4,%eax
  1036f7:	85 c0                	test   %eax,%eax
  1036f9:	74 24                	je     10371f <proc_ready+0x7a>
  1036fb:	c7 44 24 0c 81 8f 10 	movl   $0x108f81,0xc(%esp)
  103702:	00 
  103703:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  10370a:	00 
  10370b:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
  103712:	00 
  103713:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  10371a:	e8 99 cd ff ff       	call   1004b8 <debug_panic>
		proc_first = p;
  10371f:	8b 45 08             	mov    0x8(%ebp),%eax
  103722:	a3 f4 f3 11 00       	mov    %eax,0x11f3f4
		proc_last = p;
  103727:	8b 45 08             	mov    0x8(%ebp),%eax
  10372a:	a3 f8 f3 11 00       	mov    %eax,0x11f3f8
	}
	spinlock_acquire(&(p->lock));
  10372f:	8b 45 08             	mov    0x8(%ebp),%eax
  103732:	89 04 24             	mov    %eax,(%esp)
  103735:	e8 45 f6 ff ff       	call   102d7f <spinlock_acquire>
	p->state = PROC_READY;
  10373a:	8b 45 08             	mov    0x8(%ebp),%eax
  10373d:	c7 80 3c 04 00 00 01 	movl   $0x1,0x43c(%eax)
  103744:	00 00 00 
	spinlock_release(&(p->lock));
  103747:	8b 45 08             	mov    0x8(%ebp),%eax
  10374a:	89 04 24             	mov    %eax,(%esp)
  10374d:	e8 a2 f6 ff ff       	call   102df4 <spinlock_release>
	spinlock_release(&proc_lock);
  103752:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  103759:	e8 96 f6 ff ff       	call   102df4 <spinlock_release>
}
  10375e:	c9                   	leave  
  10375f:	c3                   	ret    

00103760 <proc_save>:
//	-1	if we entered the kernel via a trap before executing an insn
//	0	if we entered via a syscall and must abort/rollback the syscall
//	1	if we entered via a syscall and are completing the syscall
void
proc_save(proc *p, trapframe *tf, int entry)
{
  103760:	55                   	push   %ebp
  103761:	89 e5                	mov    %esp,%ebp
  103763:	57                   	push   %edi
  103764:	56                   	push   %esi
  103765:	53                   	push   %ebx
  103766:	83 ec 1c             	sub    $0x1c,%esp
	if(!spinlock_holding(&(p->lock))) panic("not holding p->lock");
  103769:	8b 45 08             	mov    0x8(%ebp),%eax
  10376c:	89 04 24             	mov    %eax,(%esp)
  10376f:	e8 ee f6 ff ff       	call   102e62 <spinlock_holding>
  103774:	85 c0                	test   %eax,%eax
  103776:	75 1c                	jne    103794 <proc_save+0x34>
  103778:	c7 44 24 08 8d 8f 10 	movl   $0x108f8d,0x8(%esp)
  10377f:	00 
  103780:	c7 44 24 04 68 00 00 	movl   $0x68,0x4(%esp)
  103787:	00 
  103788:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  10378f:	e8 24 cd ff ff       	call   1004b8 <debug_panic>
	// memcpy(&(p->sv.tf), tf, sizeof(p->sv.tf));
	p->sv.tf = *tf;
  103794:	8b 55 08             	mov    0x8(%ebp),%edx
  103797:	8b 45 0c             	mov    0xc(%ebp),%eax
  10379a:	8d 9a 50 04 00 00    	lea    0x450(%edx),%ebx
  1037a0:	89 c2                	mov    %eax,%edx
  1037a2:	b8 13 00 00 00       	mov    $0x13,%eax
  1037a7:	89 df                	mov    %ebx,%edi
  1037a9:	89 d6                	mov    %edx,%esi
  1037ab:	89 c1                	mov    %eax,%ecx
  1037ad:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	if(entry == 0) p->sv.tf.eip -= 2;
  1037af:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  1037b3:	75 15                	jne    1037ca <proc_save+0x6a>
  1037b5:	8b 45 08             	mov    0x8(%ebp),%eax
  1037b8:	8b 80 88 04 00 00    	mov    0x488(%eax),%eax
  1037be:	8d 50 fe             	lea    -0x2(%eax),%edx
  1037c1:	8b 45 08             	mov    0x8(%ebp),%eax
  1037c4:	89 90 88 04 00 00    	mov    %edx,0x488(%eax)
}
  1037ca:	83 c4 1c             	add    $0x1c,%esp
  1037cd:	5b                   	pop    %ebx
  1037ce:	5e                   	pop    %esi
  1037cf:	5f                   	pop    %edi
  1037d0:	5d                   	pop    %ebp
  1037d1:	c3                   	ret    

001037d2 <proc_wait>:
// Go to sleep waiting for a given child process to finish running.
// Parent process 'p' must be running and locked on entry.
// The supplied trapframe represents p's register state on syscall entry.
void gcc_noreturn
proc_wait(proc *p, proc *cp, trapframe *tf)
{
  1037d2:	55                   	push   %ebp
  1037d3:	89 e5                	mov    %esp,%ebp
  1037d5:	83 ec 18             	sub    $0x18,%esp
	cprintf("proc_wait parent=%p child=%p\n", p, cp);
  1037d8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1037db:	89 44 24 08          	mov    %eax,0x8(%esp)
  1037df:	8b 45 08             	mov    0x8(%ebp),%eax
  1037e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  1037e6:	c7 04 24 a1 8f 10 00 	movl   $0x108fa1,(%esp)
  1037ed:	e8 8b 44 00 00       	call   107c7d <cprintf>
	p->state = PROC_WAIT;
  1037f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1037f5:	c7 80 3c 04 00 00 03 	movl   $0x3,0x43c(%eax)
  1037fc:	00 00 00 
	p->waitchild = cp;
  1037ff:	8b 45 08             	mov    0x8(%ebp),%eax
  103802:	8b 55 0c             	mov    0xc(%ebp),%edx
  103805:	89 90 48 04 00 00    	mov    %edx,0x448(%eax)
	proc_save(p, tf, 0);
  10380b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  103812:	00 
  103813:	8b 45 10             	mov    0x10(%ebp),%eax
  103816:	89 44 24 04          	mov    %eax,0x4(%esp)
  10381a:	8b 45 08             	mov    0x8(%ebp),%eax
  10381d:	89 04 24             	mov    %eax,(%esp)
  103820:	e8 3b ff ff ff       	call   103760 <proc_save>
	spinlock_release(&(p->lock));
  103825:	8b 45 08             	mov    0x8(%ebp),%eax
  103828:	89 04 24             	mov    %eax,(%esp)
  10382b:	e8 c4 f5 ff ff       	call   102df4 <spinlock_release>
	proc_sched();
  103830:	e8 00 00 00 00       	call   103835 <proc_sched>

00103835 <proc_sched>:
}

void gcc_noreturn
proc_sched(void)
{
  103835:	55                   	push   %ebp
  103836:	89 e5                	mov    %esp,%ebp
  103838:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	do {
		spinlock_acquire(&proc_lock);
  10383b:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  103842:	e8 38 f5 ff ff       	call   102d7f <spinlock_acquire>
		if(proc_first) break;
  103847:	a1 f4 f3 11 00       	mov    0x11f3f4,%eax
  10384c:	85 c0                	test   %eax,%eax
  10384e:	74 2c                	je     10387c <proc_sched+0x47>
		spinlock_release(&proc_lock);
		while(!proc_first) pause();
	} while(1);
	p = proc_first;
  103850:	a1 f4 f3 11 00       	mov    0x11f3f4,%eax
  103855:	89 45 f4             	mov    %eax,-0xc(%ebp)
	spinlock_acquire(&(p->lock));
  103858:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10385b:	89 04 24             	mov    %eax,(%esp)
  10385e:	e8 1c f5 ff ff       	call   102d7f <spinlock_acquire>
	proc_first = p->readynext;
  103863:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103866:	8b 80 40 04 00 00    	mov    0x440(%eax),%eax
  10386c:	a3 f4 f3 11 00       	mov    %eax,0x11f3f4
	if(proc_first == NULL) proc_last = NULL;
  103871:	a1 f4 f3 11 00       	mov    0x11f3f4,%eax
  103876:	85 c0                	test   %eax,%eax
  103878:	74 20                	je     10389a <proc_sched+0x65>
  10387a:	eb 28                	jmp    1038a4 <proc_sched+0x6f>
{
	proc *p;
	do {
		spinlock_acquire(&proc_lock);
		if(proc_first) break;
		spinlock_release(&proc_lock);
  10387c:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  103883:	e8 6c f5 ff ff       	call   102df4 <spinlock_release>
		while(!proc_first) pause();
  103888:	eb 05                	jmp    10388f <proc_sched+0x5a>
  10388a:	e8 8c fb ff ff       	call   10341b <pause>
  10388f:	a1 f4 f3 11 00       	mov    0x11f3f4,%eax
  103894:	85 c0                	test   %eax,%eax
  103896:	74 f2                	je     10388a <proc_sched+0x55>
	} while(1);
  103898:	eb a1                	jmp    10383b <proc_sched+0x6>
	p = proc_first;
	spinlock_acquire(&(p->lock));
	proc_first = p->readynext;
	if(proc_first == NULL) proc_last = NULL;
  10389a:	c7 05 f8 f3 11 00 00 	movl   $0x0,0x11f3f8
  1038a1:	00 00 00 
	spinlock_release(&proc_lock);
  1038a4:	c7 04 24 00 f4 11 00 	movl   $0x11f400,(%esp)
  1038ab:	e8 44 f5 ff ff       	call   102df4 <spinlock_release>
	p->readynext = NULL;
  1038b0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038b3:	c7 80 40 04 00 00 00 	movl   $0x0,0x440(%eax)
  1038ba:	00 00 00 
	proc_run(p);
  1038bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1038c0:	89 04 24             	mov    %eax,(%esp)
  1038c3:	e8 00 00 00 00       	call   1038c8 <proc_run>

001038c8 <proc_run>:
}

// Switch to and run a specified process, which must already be locked.
void gcc_noreturn
proc_run(proc *p)
{
  1038c8:	55                   	push   %ebp
  1038c9:	89 e5                	mov    %esp,%ebp
  1038cb:	83 ec 18             	sub    $0x18,%esp
	// cprintf("proc_run %p\n", p);
	if(!spinlock_holding(&(p->lock))) panic("should have p->lock.\n");
  1038ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1038d1:	89 04 24             	mov    %eax,(%esp)
  1038d4:	e8 89 f5 ff ff       	call   102e62 <spinlock_holding>
  1038d9:	85 c0                	test   %eax,%eax
  1038db:	75 1c                	jne    1038f9 <proc_run+0x31>
  1038dd:	c7 44 24 08 bf 8f 10 	movl   $0x108fbf,0x8(%esp)
  1038e4:	00 
  1038e5:	c7 44 24 04 94 00 00 	movl   $0x94,0x4(%esp)
  1038ec:	00 
  1038ed:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  1038f4:	e8 bf cb ff ff       	call   1004b8 <debug_panic>
	p->runcpu = cpu_cur();
  1038f9:	e8 24 fb ff ff       	call   103422 <cpu_cur>
  1038fe:	8b 55 08             	mov    0x8(%ebp),%edx
  103901:	89 82 44 04 00 00    	mov    %eax,0x444(%edx)
	p->state = PROC_RUN;
  103907:	8b 45 08             	mov    0x8(%ebp),%eax
  10390a:	c7 80 3c 04 00 00 02 	movl   $0x2,0x43c(%eax)
  103911:	00 00 00 
	cpu_cur()->proc = p;
  103914:	e8 09 fb ff ff       	call   103422 <cpu_cur>
  103919:	8b 55 08             	mov    0x8(%ebp),%edx
  10391c:	89 90 b4 00 00 00    	mov    %edx,0xb4(%eax)
	spinlock_release(&(p->lock));
  103922:	8b 45 08             	mov    0x8(%ebp),%eax
  103925:	89 04 24             	mov    %eax,(%esp)
  103928:	e8 c7 f4 ff ff       	call   102df4 <spinlock_release>

	trap_return(&(p->sv.tf));
  10392d:	8b 45 08             	mov    0x8(%ebp),%eax
  103930:	05 50 04 00 00       	add    $0x450,%eax
  103935:	89 04 24             	mov    %eax,(%esp)
  103938:	e8 93 ef ff ff       	call   1028d0 <trap_return>

0010393d <proc_yield>:

// Yield the current CPU to another ready process.
// Called while handling a timer interrupt.
void gcc_noreturn
proc_yield(trapframe *tf)
{
  10393d:	55                   	push   %ebp
  10393e:	89 e5                	mov    %esp,%ebp
  103940:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	p = cpu_cur()->proc;
  103943:	e8 da fa ff ff       	call   103422 <cpu_cur>
  103948:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  10394e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	spinlock_acquire(&(p->lock));
  103951:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103954:	89 04 24             	mov    %eax,(%esp)
  103957:	e8 23 f4 ff ff       	call   102d7f <spinlock_acquire>
	proc_save(p, tf, -1);
  10395c:	c7 44 24 08 ff ff ff 	movl   $0xffffffff,0x8(%esp)
  103963:	ff 
  103964:	8b 45 08             	mov    0x8(%ebp),%eax
  103967:	89 44 24 04          	mov    %eax,0x4(%esp)
  10396b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10396e:	89 04 24             	mov    %eax,(%esp)
  103971:	e8 ea fd ff ff       	call   103760 <proc_save>
	spinlock_release(&(p->lock));
  103976:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103979:	89 04 24             	mov    %eax,(%esp)
  10397c:	e8 73 f4 ff ff       	call   102df4 <spinlock_release>
	proc_ready(p);
  103981:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103984:	89 04 24             	mov    %eax,(%esp)
  103987:	e8 19 fd ff ff       	call   1036a5 <proc_ready>
	proc_sched();
  10398c:	e8 a4 fe ff ff       	call   103835 <proc_sched>

00103991 <proc_ret>:
// Used both when a process calls the SYS_RET system call explicitly,
// and when a process causes an unhandled trap in user mode.
// The 'entry' parameter is as in proc_save().
void gcc_noreturn
proc_ret(trapframe *tf, int entry)
{
  103991:	55                   	push   %ebp
  103992:	89 e5                	mov    %esp,%ebp
  103994:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	proc *cp;
	cp = cpu_cur()->proc;
  103997:	e8 86 fa ff ff       	call   103422 <cpu_cur>
  10399c:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1039a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
	p = cp->parent;
  1039a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039a8:	8b 40 38             	mov    0x38(%eax),%eax
  1039ab:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("proc_ret child=%p parent=%p\n", cp, p);
  1039ae:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039b1:	89 44 24 08          	mov    %eax,0x8(%esp)
  1039b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039bc:	c7 04 24 d5 8f 10 00 	movl   $0x108fd5,(%esp)
  1039c3:	e8 b5 42 00 00       	call   107c7d <cprintf>
	spinlock_acquire(&(p->lock));
  1039c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1039cb:	89 04 24             	mov    %eax,(%esp)
  1039ce:	e8 ac f3 ff ff       	call   102d7f <spinlock_acquire>
	spinlock_acquire(&(cp->lock));
  1039d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039d6:	89 04 24             	mov    %eax,(%esp)
  1039d9:	e8 a1 f3 ff ff       	call   102d7f <spinlock_acquire>
	cp->state = PROC_STOP;
  1039de:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039e1:	c7 80 3c 04 00 00 00 	movl   $0x0,0x43c(%eax)
  1039e8:	00 00 00 
	proc_save(cp, tf, entry);
  1039eb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1039ee:	89 44 24 08          	mov    %eax,0x8(%esp)
  1039f2:	8b 45 08             	mov    0x8(%ebp),%eax
  1039f5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1039f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1039fc:	89 04 24             	mov    %eax,(%esp)
  1039ff:	e8 5c fd ff ff       	call   103760 <proc_save>
	spinlock_release(&(cp->lock));
  103a04:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103a07:	89 04 24             	mov    %eax,(%esp)
  103a0a:	e8 e5 f3 ff ff       	call   102df4 <spinlock_release>
	if(p->state == PROC_WAIT && p->waitchild == cp) {
  103a0f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a12:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  103a18:	83 f8 03             	cmp    $0x3,%eax
  103a1b:	75 19                	jne    103a36 <proc_ret+0xa5>
  103a1d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a20:	8b 80 48 04 00 00    	mov    0x448(%eax),%eax
  103a26:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  103a29:	75 0b                	jne    103a36 <proc_ret+0xa5>
		proc_run(p);
  103a2b:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a2e:	89 04 24             	mov    %eax,(%esp)
  103a31:	e8 92 fe ff ff       	call   1038c8 <proc_run>
	}
	spinlock_release(&(p->lock));
  103a36:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103a39:	89 04 24             	mov    %eax,(%esp)
  103a3c:	e8 b3 f3 ff ff       	call   102df4 <spinlock_release>
	proc_sched();
  103a41:	e8 ef fd ff ff       	call   103835 <proc_sched>

00103a46 <proc_check>:
static volatile uint32_t pingpong = 0;
static void *recovargs;

void
proc_check(void)
{
  103a46:	55                   	push   %ebp
  103a47:	89 e5                	mov    %esp,%ebp
  103a49:	57                   	push   %edi
  103a4a:	56                   	push   %esi
  103a4b:	53                   	push   %ebx
  103a4c:	81 ec dc 00 00 00    	sub    $0xdc,%esp
	// Spawn 2 child processes, executing on statically allocated stacks.

	cprintf("in proc_check()\n");
  103a52:	c7 04 24 f2 8f 10 00 	movl   $0x108ff2,(%esp)
  103a59:	e8 1f 42 00 00       	call   107c7d <cprintf>
	int i;
	for (i = 0; i < 4; i++) {
  103a5e:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103a65:	00 00 00 
  103a68:	e9 f0 00 00 00       	jmp    103b5d <proc_check+0x117>
		// Setup register state for child
		uint32_t *esp = (uint32_t*) &child_stack[i][PAGESIZE];
  103a6d:	b8 70 ac 11 00       	mov    $0x11ac70,%eax
  103a72:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103a78:	83 c2 01             	add    $0x1,%edx
  103a7b:	c1 e2 0c             	shl    $0xc,%edx
  103a7e:	01 d0                	add    %edx,%eax
  103a80:	89 85 38 ff ff ff    	mov    %eax,-0xc8(%ebp)
		*--esp = i;	// push argument to child() function
  103a86:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103a8d:	8b 95 34 ff ff ff    	mov    -0xcc(%ebp),%edx
  103a93:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  103a99:	89 10                	mov    %edx,(%eax)
		*--esp = 0;	// fake return address
  103a9b:	83 ad 38 ff ff ff 04 	subl   $0x4,-0xc8(%ebp)
  103aa2:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  103aa8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		child_state.tf.eip = (uint32_t) child;
  103aae:	b8 3e 3f 10 00       	mov    $0x103f3e,%eax
  103ab3:	a3 58 aa 11 00       	mov    %eax,0x11aa58
		child_state.tf.esp = (uint32_t) esp;
  103ab8:	8b 85 38 ff ff ff    	mov    -0xc8(%ebp),%eax
  103abe:	a3 64 aa 11 00       	mov    %eax,0x11aa64

		// Use PUT syscall to create each child,
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
  103ac3:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103ac9:	89 44 24 04          	mov    %eax,0x4(%esp)
  103acd:	c7 04 24 03 90 10 00 	movl   $0x109003,(%esp)
  103ad4:	e8 a4 41 00 00       	call   107c7d <cprintf>
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
  103ad9:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103adf:	0f b7 d0             	movzwl %ax,%edx
  103ae2:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103ae9:	7f 07                	jg     103af2 <proc_check+0xac>
  103aeb:	b8 10 10 00 00       	mov    $0x1010,%eax
  103af0:	eb 05                	jmp    103af7 <proc_check+0xb1>
  103af2:	b8 00 10 00 00       	mov    $0x1000,%eax
  103af7:	89 85 54 ff ff ff    	mov    %eax,-0xac(%ebp)
  103afd:	66 89 95 52 ff ff ff 	mov    %dx,-0xae(%ebp)
  103b04:	c7 85 4c ff ff ff 20 	movl   $0x11aa20,-0xb4(%ebp)
  103b0b:	aa 11 00 
  103b0e:	c7 85 48 ff ff ff 00 	movl   $0x0,-0xb8(%ebp)
  103b15:	00 00 00 
  103b18:	c7 85 44 ff ff ff 00 	movl   $0x0,-0xbc(%ebp)
  103b1f:	00 00 00 
  103b22:	c7 85 40 ff ff ff 00 	movl   $0x0,-0xc0(%ebp)
  103b29:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103b2c:	8b 85 54 ff ff ff    	mov    -0xac(%ebp),%eax
  103b32:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103b35:	8b 9d 4c ff ff ff    	mov    -0xb4(%ebp),%ebx
  103b3b:	0f b7 95 52 ff ff ff 	movzwl -0xae(%ebp),%edx
  103b42:	8b b5 48 ff ff ff    	mov    -0xb8(%ebp),%esi
  103b48:	8b bd 44 ff ff ff    	mov    -0xbc(%ebp),%edi
  103b4e:	8b 8d 40 ff ff ff    	mov    -0xc0(%ebp),%ecx
  103b54:	cd 30                	int    $0x30
{
	// Spawn 2 child processes, executing on statically allocated stacks.

	cprintf("in proc_check()\n");
	int i;
	for (i = 0; i < 4; i++) {
  103b56:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103b5d:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103b64:	0f 8e 03 ff ff ff    	jle    103a6d <proc_check+0x27>
		// but only start the first 2 children for now.
		cprintf("spawning child %d\n", i);
		sys_put(SYS_REGS | (i < 2 ? SYS_START : 0), i, &child_state,
			NULL, NULL, 0);
	}
	cprintf("proc_check() created childs\n");
  103b6a:	c7 04 24 16 90 10 00 	movl   $0x109016,(%esp)
  103b71:	e8 07 41 00 00       	call   107c7d <cprintf>


	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103b76:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103b7d:	00 00 00 
  103b80:	e9 89 00 00 00       	jmp    103c0e <proc_check+0x1c8>
		cprintf("waiting for child %d\n", i);
  103b85:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103b8b:	89 44 24 04          	mov    %eax,0x4(%esp)
  103b8f:	c7 04 24 33 90 10 00 	movl   $0x109033,(%esp)
  103b96:	e8 e2 40 00 00       	call   107c7d <cprintf>
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103b9b:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103ba1:	0f b7 c0             	movzwl %ax,%eax
  103ba4:	c7 85 6c ff ff ff 00 	movl   $0x1000,-0x94(%ebp)
  103bab:	10 00 00 
  103bae:	66 89 85 6a ff ff ff 	mov    %ax,-0x96(%ebp)
  103bb5:	c7 85 64 ff ff ff 20 	movl   $0x11aa20,-0x9c(%ebp)
  103bbc:	aa 11 00 
  103bbf:	c7 85 60 ff ff ff 00 	movl   $0x0,-0xa0(%ebp)
  103bc6:	00 00 00 
  103bc9:	c7 85 5c ff ff ff 00 	movl   $0x0,-0xa4(%ebp)
  103bd0:	00 00 00 
  103bd3:	c7 85 58 ff ff ff 00 	movl   $0x0,-0xa8(%ebp)
  103bda:	00 00 00 
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103bdd:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
  103be3:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103be6:	8b 9d 64 ff ff ff    	mov    -0x9c(%ebp),%ebx
  103bec:	0f b7 95 6a ff ff ff 	movzwl -0x96(%ebp),%edx
  103bf3:	8b b5 60 ff ff ff    	mov    -0xa0(%ebp),%esi
  103bf9:	8b bd 5c ff ff ff    	mov    -0xa4(%ebp),%edi
  103bff:	8b 8d 58 ff ff ff    	mov    -0xa8(%ebp),%ecx
  103c05:	cd 30                	int    $0x30


	// Wait for both children to complete.
	// This should complete without preemptive scheduling
	// when we're running on a 2-processor machine.
	for (i = 0; i < 2; i++) {
  103c07:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103c0e:	83 bd 34 ff ff ff 01 	cmpl   $0x1,-0xcc(%ebp)
  103c15:	0f 8e 6a ff ff ff    	jle    103b85 <proc_check+0x13f>
		cprintf("waiting for child %d\n", i);
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
	}
	cprintf("proc_check() 2-child test succeeded\n");
  103c1b:	c7 04 24 4c 90 10 00 	movl   $0x10904c,(%esp)
  103c22:	e8 56 40 00 00       	call   107c7d <cprintf>

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
  103c27:	c7 04 24 74 90 10 00 	movl   $0x109074,(%esp)
  103c2e:	e8 4a 40 00 00       	call   107c7d <cprintf>
	for (i = 0; i < 4; i++) {
  103c33:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103c3a:	00 00 00 
  103c3d:	eb 7d                	jmp    103cbc <proc_check+0x276>
		cprintf("spawning child %d\n", i);
  103c3f:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103c45:	89 44 24 04          	mov    %eax,0x4(%esp)
  103c49:	c7 04 24 03 90 10 00 	movl   $0x109003,(%esp)
  103c50:	e8 28 40 00 00       	call   107c7d <cprintf>
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
  103c55:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103c5b:	0f b7 c0             	movzwl %ax,%eax
  103c5e:	c7 45 84 10 00 00 00 	movl   $0x10,-0x7c(%ebp)
  103c65:	66 89 45 82          	mov    %ax,-0x7e(%ebp)
  103c69:	c7 85 7c ff ff ff 00 	movl   $0x0,-0x84(%ebp)
  103c70:	00 00 00 
  103c73:	c7 85 78 ff ff ff 00 	movl   $0x0,-0x88(%ebp)
  103c7a:	00 00 00 
  103c7d:	c7 85 74 ff ff ff 00 	movl   $0x0,-0x8c(%ebp)
  103c84:	00 00 00 
  103c87:	c7 85 70 ff ff ff 00 	movl   $0x0,-0x90(%ebp)
  103c8e:	00 00 00 
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103c91:	8b 45 84             	mov    -0x7c(%ebp),%eax
  103c94:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103c97:	8b 9d 7c ff ff ff    	mov    -0x84(%ebp),%ebx
  103c9d:	0f b7 55 82          	movzwl -0x7e(%ebp),%edx
  103ca1:	8b b5 78 ff ff ff    	mov    -0x88(%ebp),%esi
  103ca7:	8b bd 74 ff ff ff    	mov    -0x8c(%ebp),%edi
  103cad:	8b 8d 70 ff ff ff    	mov    -0x90(%ebp),%ecx
  103cb3:	cd 30                	int    $0x30

	// (Re)start all four children, and wait for them.
	// This will require preemptive scheduling to complete
	// if we have less than 4 CPUs.
	cprintf("proc_check: spawning 4 children\n");
	for (i = 0; i < 4; i++) {
  103cb5:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103cbc:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103cc3:	0f 8e 76 ff ff ff    	jle    103c3f <proc_check+0x1f9>
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103cc9:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103cd0:	00 00 00 
  103cd3:	eb 4f                	jmp    103d24 <proc_check+0x2de>
		sys_get(0, i, NULL, NULL, NULL, 0);
  103cd5:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103cdb:	0f b7 c0             	movzwl %ax,%eax
  103cde:	c7 45 9c 00 00 00 00 	movl   $0x0,-0x64(%ebp)
  103ce5:	66 89 45 9a          	mov    %ax,-0x66(%ebp)
  103ce9:	c7 45 94 00 00 00 00 	movl   $0x0,-0x6c(%ebp)
  103cf0:	c7 45 90 00 00 00 00 	movl   $0x0,-0x70(%ebp)
  103cf7:	c7 45 8c 00 00 00 00 	movl   $0x0,-0x74(%ebp)
  103cfe:	c7 45 88 00 00 00 00 	movl   $0x0,-0x78(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103d05:	8b 45 9c             	mov    -0x64(%ebp),%eax
  103d08:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103d0b:	8b 5d 94             	mov    -0x6c(%ebp),%ebx
  103d0e:	0f b7 55 9a          	movzwl -0x66(%ebp),%edx
  103d12:	8b 75 90             	mov    -0x70(%ebp),%esi
  103d15:	8b 7d 8c             	mov    -0x74(%ebp),%edi
  103d18:	8b 4d 88             	mov    -0x78(%ebp),%ecx
  103d1b:	cd 30                	int    $0x30
		cprintf("spawning child %d\n", i);
		sys_put(SYS_START, i, NULL, NULL, NULL, 0);
	}

	// Wait for all 4 children to complete.
	for (i = 0; i < 4; i++)
  103d1d:	83 85 34 ff ff ff 01 	addl   $0x1,-0xcc(%ebp)
  103d24:	83 bd 34 ff ff ff 03 	cmpl   $0x3,-0xcc(%ebp)
  103d2b:	7e a8                	jle    103cd5 <proc_check+0x28f>
		sys_get(0, i, NULL, NULL, NULL, 0);
	cprintf("proc_check() 4-child test succeeded\n");
  103d2d:	c7 04 24 98 90 10 00 	movl   $0x109098,(%esp)
  103d34:	e8 44 3f 00 00       	call   107c7d <cprintf>

	// Now do a trap handling test using all 4 children -
	// but they'll _think_ they're all child 0!
	// (We'll lose the register state of the other children.)
	i = 0;
  103d39:	c7 85 34 ff ff ff 00 	movl   $0x0,-0xcc(%ebp)
  103d40:	00 00 00 
	sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103d43:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103d49:	0f b7 c0             	movzwl %ax,%eax
  103d4c:	c7 45 b4 00 10 00 00 	movl   $0x1000,-0x4c(%ebp)
  103d53:	66 89 45 b2          	mov    %ax,-0x4e(%ebp)
  103d57:	c7 45 ac 20 aa 11 00 	movl   $0x11aa20,-0x54(%ebp)
  103d5e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
  103d65:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
  103d6c:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103d73:	8b 45 b4             	mov    -0x4c(%ebp),%eax
  103d76:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103d79:	8b 5d ac             	mov    -0x54(%ebp),%ebx
  103d7c:	0f b7 55 b2          	movzwl -0x4e(%ebp),%edx
  103d80:	8b 75 a8             	mov    -0x58(%ebp),%esi
  103d83:	8b 7d a4             	mov    -0x5c(%ebp),%edi
  103d86:	8b 4d a0             	mov    -0x60(%ebp),%ecx
  103d89:	cd 30                	int    $0x30
		// get child 0's state
	assert(recovargs == NULL);
  103d8b:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  103d90:	85 c0                	test   %eax,%eax
  103d92:	74 24                	je     103db8 <proc_check+0x372>
  103d94:	c7 44 24 0c bd 90 10 	movl   $0x1090bd,0xc(%esp)
  103d9b:	00 
  103d9c:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  103da3:	00 
  103da4:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
  103dab:	00 
  103dac:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  103db3:	e8 00 c7 ff ff       	call   1004b8 <debug_panic>
	do {
		sys_put(SYS_REGS | SYS_START, i, &child_state, NULL, NULL, 0);
  103db8:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103dbe:	0f b7 c0             	movzwl %ax,%eax
  103dc1:	c7 45 cc 10 10 00 00 	movl   $0x1010,-0x34(%ebp)
  103dc8:	66 89 45 ca          	mov    %ax,-0x36(%ebp)
  103dcc:	c7 45 c4 20 aa 11 00 	movl   $0x11aa20,-0x3c(%ebp)
  103dd3:	c7 45 c0 00 00 00 00 	movl   $0x0,-0x40(%ebp)
  103dda:	c7 45 bc 00 00 00 00 	movl   $0x0,-0x44(%ebp)
  103de1:	c7 45 b8 00 00 00 00 	movl   $0x0,-0x48(%ebp)
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_PUT | flags),
  103de8:	8b 45 cc             	mov    -0x34(%ebp),%eax
  103deb:	83 c8 01             	or     $0x1,%eax

static void gcc_inline
sys_put(uint32_t flags, uint16_t child, procstate *save,
		void *localsrc, void *childdest, size_t size)
{
	asm volatile("int %0" :
  103dee:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
  103df1:	0f b7 55 ca          	movzwl -0x36(%ebp),%edx
  103df5:	8b 75 c0             	mov    -0x40(%ebp),%esi
  103df8:	8b 7d bc             	mov    -0x44(%ebp),%edi
  103dfb:	8b 4d b8             	mov    -0x48(%ebp),%ecx
  103dfe:	cd 30                	int    $0x30
		sys_get(SYS_REGS, i, &child_state, NULL, NULL, 0);
  103e00:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103e06:	0f b7 c0             	movzwl %ax,%eax
  103e09:	c7 45 e4 00 10 00 00 	movl   $0x1000,-0x1c(%ebp)
  103e10:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
  103e14:	c7 45 dc 20 aa 11 00 	movl   $0x11aa20,-0x24(%ebp)
  103e1b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
  103e22:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  103e29:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
		: "i" (T_SYSCALL),
		  "a" (SYS_GET | flags),
  103e30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  103e33:	83 c8 02             	or     $0x2,%eax

static void gcc_inline
sys_get(uint32_t flags, uint16_t child, procstate *save,
		void *childsrc, void *localdest, size_t size)
{
	asm volatile("int %0" :
  103e36:	8b 5d dc             	mov    -0x24(%ebp),%ebx
  103e39:	0f b7 55 e2          	movzwl -0x1e(%ebp),%edx
  103e3d:	8b 75 d8             	mov    -0x28(%ebp),%esi
  103e40:	8b 7d d4             	mov    -0x2c(%ebp),%edi
  103e43:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  103e46:	cd 30                	int    $0x30
		if (recovargs) {	// trap recovery needed
  103e48:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  103e4d:	85 c0                	test   %eax,%eax
  103e4f:	74 3f                	je     103e90 <proc_check+0x44a>
			trap_check_args *args = recovargs;
  103e51:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  103e56:	89 85 3c ff ff ff    	mov    %eax,-0xc4(%ebp)
			cprintf("recover from trap %d\n",
  103e5c:	a1 50 aa 11 00       	mov    0x11aa50,%eax
  103e61:	89 44 24 04          	mov    %eax,0x4(%esp)
  103e65:	c7 04 24 cf 90 10 00 	movl   $0x1090cf,(%esp)
  103e6c:	e8 0c 3e 00 00       	call   107c7d <cprintf>
				child_state.tf.trapno);
			child_state.tf.eip = (uint32_t) args->reip;
  103e71:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103e77:	8b 00                	mov    (%eax),%eax
  103e79:	a3 58 aa 11 00       	mov    %eax,0x11aa58
			args->trapno = child_state.tf.trapno;
  103e7e:	a1 50 aa 11 00       	mov    0x11aa50,%eax
  103e83:	89 c2                	mov    %eax,%edx
  103e85:	8b 85 3c ff ff ff    	mov    -0xc4(%ebp),%eax
  103e8b:	89 50 04             	mov    %edx,0x4(%eax)
  103e8e:	eb 2e                	jmp    103ebe <proc_check+0x478>
		} else
			assert(child_state.tf.trapno == T_SYSCALL);
  103e90:	a1 50 aa 11 00       	mov    0x11aa50,%eax
  103e95:	83 f8 30             	cmp    $0x30,%eax
  103e98:	74 24                	je     103ebe <proc_check+0x478>
  103e9a:	c7 44 24 0c e8 90 10 	movl   $0x1090e8,0xc(%esp)
  103ea1:	00 
  103ea2:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  103ea9:	00 
  103eaa:	c7 44 24 04 0d 01 00 	movl   $0x10d,0x4(%esp)
  103eb1:	00 
  103eb2:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  103eb9:	e8 fa c5 ff ff       	call   1004b8 <debug_panic>
		i = (i+1) % 4;	// rotate to next child proc
  103ebe:	8b 85 34 ff ff ff    	mov    -0xcc(%ebp),%eax
  103ec4:	8d 50 01             	lea    0x1(%eax),%edx
  103ec7:	89 d0                	mov    %edx,%eax
  103ec9:	c1 f8 1f             	sar    $0x1f,%eax
  103ecc:	c1 e8 1e             	shr    $0x1e,%eax
  103ecf:	01 c2                	add    %eax,%edx
  103ed1:	83 e2 03             	and    $0x3,%edx
  103ed4:	89 d1                	mov    %edx,%ecx
  103ed6:	29 c1                	sub    %eax,%ecx
  103ed8:	89 c8                	mov    %ecx,%eax
  103eda:	89 85 34 ff ff ff    	mov    %eax,-0xcc(%ebp)
	} while (child_state.tf.trapno != T_SYSCALL);
  103ee0:	a1 50 aa 11 00       	mov    0x11aa50,%eax
  103ee5:	83 f8 30             	cmp    $0x30,%eax
  103ee8:	0f 85 ca fe ff ff    	jne    103db8 <proc_check+0x372>
	assert(recovargs == NULL);
  103eee:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  103ef3:	85 c0                	test   %eax,%eax
  103ef5:	74 24                	je     103f1b <proc_check+0x4d5>
  103ef7:	c7 44 24 0c bd 90 10 	movl   $0x1090bd,0xc(%esp)
  103efe:	00 
  103eff:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  103f06:	00 
  103f07:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
  103f0e:	00 
  103f0f:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  103f16:	e8 9d c5 ff ff       	call   1004b8 <debug_panic>

	cprintf("proc_check() trap reflection test succeeded\n");
  103f1b:	c7 04 24 0c 91 10 00 	movl   $0x10910c,(%esp)
  103f22:	e8 56 3d 00 00       	call   107c7d <cprintf>

	cprintf("proc_check() succeeded!\n");
  103f27:	c7 04 24 39 91 10 00 	movl   $0x109139,(%esp)
  103f2e:	e8 4a 3d 00 00       	call   107c7d <cprintf>
}
  103f33:	81 c4 dc 00 00 00    	add    $0xdc,%esp
  103f39:	5b                   	pop    %ebx
  103f3a:	5e                   	pop    %esi
  103f3b:	5f                   	pop    %edi
  103f3c:	5d                   	pop    %ebp
  103f3d:	c3                   	ret    

00103f3e <child>:

static void child(int n)
{
  103f3e:	55                   	push   %ebp
  103f3f:	89 e5                	mov    %esp,%ebp
  103f41:	83 ec 28             	sub    $0x28,%esp
	// Only first 2 children participate in first pingpong test
	cprintf("in child %d\n", n);
  103f44:	8b 45 08             	mov    0x8(%ebp),%eax
  103f47:	89 44 24 04          	mov    %eax,0x4(%esp)
  103f4b:	c7 04 24 52 91 10 00 	movl   $0x109152,(%esp)
  103f52:	e8 26 3d 00 00       	call   107c7d <cprintf>
	if (n < 2) {
  103f57:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
  103f5b:	7f 64                	jg     103fc1 <child+0x83>
		int i;
		for (i = 0; i < 10; i++) {
  103f5d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  103f64:	eb 4e                	jmp    103fb4 <child+0x76>
			cprintf("in child %d count %d\n", n, i);
  103f66:	8b 45 f4             	mov    -0xc(%ebp),%eax
  103f69:	89 44 24 08          	mov    %eax,0x8(%esp)
  103f6d:	8b 45 08             	mov    0x8(%ebp),%eax
  103f70:	89 44 24 04          	mov    %eax,0x4(%esp)
  103f74:	c7 04 24 5f 91 10 00 	movl   $0x10915f,(%esp)
  103f7b:	e8 fd 3c 00 00       	call   107c7d <cprintf>
			while (pingpong != n)
  103f80:	eb 05                	jmp    103f87 <child+0x49>
				pause();
  103f82:	e8 94 f4 ff ff       	call   10341b <pause>
	cprintf("in child %d\n", n);
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
			cprintf("in child %d count %d\n", n, i);
			while (pingpong != n)
  103f87:	8b 55 08             	mov    0x8(%ebp),%edx
  103f8a:	a1 70 ec 11 00       	mov    0x11ec70,%eax
  103f8f:	39 c2                	cmp    %eax,%edx
  103f91:	75 ef                	jne    103f82 <child+0x44>
				pause();
			xchg(&pingpong, !pingpong);
  103f93:	a1 70 ec 11 00       	mov    0x11ec70,%eax
  103f98:	85 c0                	test   %eax,%eax
  103f9a:	0f 94 c0             	sete   %al
  103f9d:	0f b6 c0             	movzbl %al,%eax
  103fa0:	89 44 24 04          	mov    %eax,0x4(%esp)
  103fa4:	c7 04 24 70 ec 11 00 	movl   $0x11ec70,(%esp)
  103fab:	e8 40 f4 ff ff       	call   1033f0 <xchg>
{
	// Only first 2 children participate in first pingpong test
	cprintf("in child %d\n", n);
	if (n < 2) {
		int i;
		for (i = 0; i < 10; i++) {
  103fb0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
  103fb4:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
  103fb8:	7e ac                	jle    103f66 <child+0x28>
}

static void gcc_inline
sys_ret(void)
{
	asm volatile("int %0" : :
  103fba:	b8 03 00 00 00       	mov    $0x3,%eax
  103fbf:	cd 30                	int    $0x30
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  103fc1:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  103fc8:	eb 4c                	jmp    104016 <child+0xd8>
		cprintf("in child %d count %d\n", n, i);
  103fca:	8b 45 f0             	mov    -0x10(%ebp),%eax
  103fcd:	89 44 24 08          	mov    %eax,0x8(%esp)
  103fd1:	8b 45 08             	mov    0x8(%ebp),%eax
  103fd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  103fd8:	c7 04 24 5f 91 10 00 	movl   $0x10915f,(%esp)
  103fdf:	e8 99 3c 00 00       	call   107c7d <cprintf>
		while (pingpong != n)
  103fe4:	eb 05                	jmp    103feb <child+0xad>
			pause();
  103fe6:	e8 30 f4 ff ff       	call   10341b <pause>

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
		cprintf("in child %d count %d\n", n, i);
		while (pingpong != n)
  103feb:	8b 55 08             	mov    0x8(%ebp),%edx
  103fee:	a1 70 ec 11 00       	mov    0x11ec70,%eax
  103ff3:	39 c2                	cmp    %eax,%edx
  103ff5:	75 ef                	jne    103fe6 <child+0xa8>
			pause();
		xchg(&pingpong, (pingpong + 1) % 4);
  103ff7:	a1 70 ec 11 00       	mov    0x11ec70,%eax
  103ffc:	83 c0 01             	add    $0x1,%eax
  103fff:	83 e0 03             	and    $0x3,%eax
  104002:	89 44 24 04          	mov    %eax,0x4(%esp)
  104006:	c7 04 24 70 ec 11 00 	movl   $0x11ec70,(%esp)
  10400d:	e8 de f3 ff ff       	call   1033f0 <xchg>
		sys_ret();
	}

	// Second test, round-robin pingpong between all 4 children
	int i;
	for (i = 0; i < 10; i++) {
  104012:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  104016:	83 7d f0 09          	cmpl   $0x9,-0x10(%ebp)
  10401a:	7e ae                	jle    103fca <child+0x8c>
  10401c:	b8 03 00 00 00       	mov    $0x3,%eax
  104021:	cd 30                	int    $0x30
		xchg(&pingpong, (pingpong + 1) % 4);
	}
	sys_ret();

	// Only "child 0" (or the proc that thinks it's child 0), trap check...
	if (n == 0) {
  104023:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
  104027:	75 6d                	jne    104096 <child+0x158>
		assert(recovargs == NULL);
  104029:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  10402e:	85 c0                	test   %eax,%eax
  104030:	74 24                	je     104056 <child+0x118>
  104032:	c7 44 24 0c bd 90 10 	movl   $0x1090bd,0xc(%esp)
  104039:	00 
  10403a:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  104041:	00 
  104042:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  104049:	00 
  10404a:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  104051:	e8 62 c4 ff ff       	call   1004b8 <debug_panic>
		trap_check(&recovargs);
  104056:	c7 04 24 74 ec 11 00 	movl   $0x11ec74,(%esp)
  10405d:	e8 25 e5 ff ff       	call   102587 <trap_check>
		assert(recovargs == NULL);
  104062:	a1 74 ec 11 00       	mov    0x11ec74,%eax
  104067:	85 c0                	test   %eax,%eax
  104069:	74 24                	je     10408f <child+0x151>
  10406b:	c7 44 24 0c bd 90 10 	movl   $0x1090bd,0xc(%esp)
  104072:	00 
  104073:	c7 44 24 08 c2 8e 10 	movl   $0x108ec2,0x8(%esp)
  10407a:	00 
  10407b:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
  104082:	00 
  104083:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  10408a:	e8 29 c4 ff ff       	call   1004b8 <debug_panic>
  10408f:	b8 03 00 00 00       	mov    $0x3,%eax
  104094:	cd 30                	int    $0x30
		sys_ret();
	}

	panic("child(): shouldn't have gotten here");
  104096:	c7 44 24 08 78 91 10 	movl   $0x109178,0x8(%esp)
  10409d:	00 
  10409e:	c7 44 24 04 38 01 00 	movl   $0x138,0x4(%esp)
  1040a5:	00 
  1040a6:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  1040ad:	e8 06 c4 ff ff       	call   1004b8 <debug_panic>

001040b2 <grandchild>:
}

static void grandchild(int n)
{
  1040b2:	55                   	push   %ebp
  1040b3:	89 e5                	mov    %esp,%ebp
  1040b5:	83 ec 18             	sub    $0x18,%esp
	panic("grandchild(): shouldn't have gotten here");
  1040b8:	c7 44 24 08 9c 91 10 	movl   $0x10919c,0x8(%esp)
  1040bf:	00 
  1040c0:	c7 44 24 04 3d 01 00 	movl   $0x13d,0x4(%esp)
  1040c7:	00 
  1040c8:	c7 04 24 e4 8e 10 00 	movl   $0x108ee4,(%esp)
  1040cf:	e8 e4 c3 ff ff       	call   1004b8 <debug_panic>

001040d4 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1040d4:	55                   	push   %ebp
  1040d5:	89 e5                	mov    %esp,%ebp
  1040d7:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1040da:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1040dd:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1040e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1040e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1040e6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1040eb:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1040ee:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1040f1:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1040f7:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1040fc:	74 24                	je     104122 <cpu_cur+0x4e>
  1040fe:	c7 44 24 0c c8 91 10 	movl   $0x1091c8,0xc(%esp)
  104105:	00 
  104106:	c7 44 24 08 de 91 10 	movl   $0x1091de,0x8(%esp)
  10410d:	00 
  10410e:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  104115:	00 
  104116:	c7 04 24 f3 91 10 00 	movl   $0x1091f3,(%esp)
  10411d:	e8 96 c3 ff ff       	call   1004b8 <debug_panic>
	return c;
  104122:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  104125:	c9                   	leave  
  104126:	c3                   	ret    

00104127 <systrap>:
// During a system call, generate a specific processor trap -
// as if the user code's INT 0x30 instruction had caused it -
// and reflect the trap to the parent process as with other traps.
static void gcc_noreturn
systrap(trapframe *utf, int trapno, int err)
{
  104127:	55                   	push   %ebp
  104128:	89 e5                	mov    %esp,%ebp
  10412a:	83 ec 18             	sub    $0x18,%esp
	panic("systrap() not implemented.");
  10412d:	c7 44 24 08 00 92 10 	movl   $0x109200,0x8(%esp)
  104134:	00 
  104135:	c7 44 24 04 24 00 00 	movl   $0x24,0x4(%esp)
  10413c:	00 
  10413d:	c7 04 24 1b 92 10 00 	movl   $0x10921b,(%esp)
  104144:	e8 6f c3 ff ff       	call   1004b8 <debug_panic>

00104149 <sysrecover>:
// - Be sure the parent gets the correct trapno, err, and eip values.
// - Be sure to release any spinlocks you were holding during the copyin/out.
//
static void gcc_noreturn
sysrecover(trapframe *ktf, void *recoverdata)
{
  104149:	55                   	push   %ebp
  10414a:	89 e5                	mov    %esp,%ebp
  10414c:	83 ec 18             	sub    $0x18,%esp
	panic("sysrecover() not implemented.");
  10414f:	c7 44 24 08 2a 92 10 	movl   $0x10922a,0x8(%esp)
  104156:	00 
  104157:	c7 44 24 04 34 00 00 	movl   $0x34,0x4(%esp)
  10415e:	00 
  10415f:	c7 04 24 1b 92 10 00 	movl   $0x10921b,(%esp)
  104166:	e8 4d c3 ff ff       	call   1004b8 <debug_panic>

0010416b <checkva>:
//
// Note: Be careful that your arithmetic works correctly
// even if size is very large, e.g., if uva+size wraps around!
//
static void checkva(trapframe *utf, uint32_t uva, size_t size)
{
  10416b:	55                   	push   %ebp
  10416c:	89 e5                	mov    %esp,%ebp
  10416e:	83 ec 18             	sub    $0x18,%esp
	panic("checkva() not implemented.");
  104171:	c7 44 24 08 48 92 10 	movl   $0x109248,0x8(%esp)
  104178:	00 
  104179:	c7 44 24 04 42 00 00 	movl   $0x42,0x4(%esp)
  104180:	00 
  104181:	c7 04 24 1b 92 10 00 	movl   $0x10921b,(%esp)
  104188:	e8 2b c3 ff ff       	call   1004b8 <debug_panic>

0010418d <usercopy>:
// Copy data to/from user space,
// using checkva() above to validate the address range
// and using sysrecover() to recover from any traps during the copy.
void usercopy(trapframe *utf, bool copyout,
			void *kva, uint32_t uva, size_t size)
{
  10418d:	55                   	push   %ebp
  10418e:	89 e5                	mov    %esp,%ebp
  104190:	83 ec 18             	sub    $0x18,%esp
	checkva(utf, uva, size);
  104193:	8b 45 18             	mov    0x18(%ebp),%eax
  104196:	89 44 24 08          	mov    %eax,0x8(%esp)
  10419a:	8b 45 14             	mov    0x14(%ebp),%eax
  10419d:	89 44 24 04          	mov    %eax,0x4(%esp)
  1041a1:	8b 45 08             	mov    0x8(%ebp),%eax
  1041a4:	89 04 24             	mov    %eax,(%esp)
  1041a7:	e8 bf ff ff ff       	call   10416b <checkva>

	// Now do the copy, but recover from page faults.
	panic("syscall_usercopy() not implemented.");
  1041ac:	c7 44 24 08 64 92 10 	movl   $0x109264,0x8(%esp)
  1041b3:	00 
  1041b4:	c7 44 24 04 4e 00 00 	movl   $0x4e,0x4(%esp)
  1041bb:	00 
  1041bc:	c7 04 24 1b 92 10 00 	movl   $0x10921b,(%esp)
  1041c3:	e8 f0 c2 ff ff       	call   1004b8 <debug_panic>

001041c8 <do_put>:
}

static void do_put(trapframe *tf, uint32_t cmd)
{
  1041c8:	55                   	push   %ebp
  1041c9:	89 e5                	mov    %esp,%ebp
  1041cb:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	proc *cp;
	uint8_t cn = tf->regs.edx;
  1041ce:	8b 45 08             	mov    0x8(%ebp),%eax
  1041d1:	8b 40 14             	mov    0x14(%eax),%eax
  1041d4:	88 45 f7             	mov    %al,-0x9(%ebp)
	p = cpu_cur()->proc;
  1041d7:	e8 f8 fe ff ff       	call   1040d4 <cpu_cur>
  1041dc:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1041e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	spinlock_acquire(&(p->lock));
  1041e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1041e8:	89 04 24             	mov    %eax,(%esp)
  1041eb:	e8 8f eb ff ff       	call   102d7f <spinlock_acquire>
	cp = p->child[cn];
  1041f0:	0f b6 55 f7          	movzbl -0x9(%ebp),%edx
  1041f4:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1041f7:	83 c2 0c             	add    $0xc,%edx
  1041fa:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  1041fe:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if(!cp) cp = proc_alloc(p, cn);
  104201:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  104205:	75 16                	jne    10421d <do_put+0x55>
  104207:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
  10420b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10420f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104212:	89 04 24             	mov    %eax,(%esp)
  104215:	e8 b7 f2 ff ff       	call   1034d1 <proc_alloc>
  10421a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	spinlock_acquire(&(cp->lock));
  10421d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104220:	89 04 24             	mov    %eax,(%esp)
  104223:	e8 57 eb ff ff       	call   102d7f <spinlock_acquire>
	if(cp->state != PROC_STOP) {
  104228:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10422b:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  104231:	85 c0                	test   %eax,%eax
  104233:	74 24                	je     104259 <do_put+0x91>
		spinlock_release(&(cp->lock));
  104235:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104238:	89 04 24             	mov    %eax,(%esp)
  10423b:	e8 b4 eb ff ff       	call   102df4 <spinlock_release>
		proc_wait(p, cp, tf);
  104240:	8b 45 08             	mov    0x8(%ebp),%eax
  104243:	89 44 24 08          	mov    %eax,0x8(%esp)
  104247:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10424a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10424e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104251:	89 04 24             	mov    %eax,(%esp)
  104254:	e8 79 f5 ff ff       	call   1037d2 <proc_wait>
	}
	if(cmd & SYS_REGS) {
  104259:	8b 45 0c             	mov    0xc(%ebp),%eax
  10425c:	25 00 10 00 00       	and    $0x1000,%eax
  104261:	85 c0                	test   %eax,%eax
  104263:	0f 84 01 01 00 00    	je     10436a <do_put+0x1a2>
		memcpy(&(cp->sv), (void *)tf->regs.ebx, sizeof(cp->sv));
  104269:	8b 45 08             	mov    0x8(%ebp),%eax
  10426c:	8b 40 10             	mov    0x10(%eax),%eax
  10426f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  104272:	81 c2 50 04 00 00    	add    $0x450,%edx
  104278:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
  10427f:	00 
  104280:	89 44 24 04          	mov    %eax,0x4(%esp)
  104284:	89 14 24             	mov    %edx,(%esp)
  104287:	e8 27 3d 00 00       	call   107fb3 <memcpy>
		cp->sv.tf.eflags &= FL_USER;
  10428c:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10428f:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  104295:	89 c2                	mov    %eax,%edx
  104297:	81 e2 d5 0c 00 00    	and    $0xcd5,%edx
  10429d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042a0:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
		cp->sv.tf.eflags |= (FL_IOPL_MASK & FL_IOPL_3);
  1042a6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042a9:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1042af:	89 c2                	mov    %eax,%edx
  1042b1:	80 ce 30             	or     $0x30,%dh
  1042b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042b7:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
		cp->sv.tf.eflags |= FL_IF;
  1042bd:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042c0:	8b 80 90 04 00 00    	mov    0x490(%eax),%eax
  1042c6:	89 c2                	mov    %eax,%edx
  1042c8:	80 ce 02             	or     $0x2,%dh
  1042cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042ce:	89 90 90 04 00 00    	mov    %edx,0x490(%eax)
		cp->sv.tf.cs |= CPU_GDT_UCODE | 0x3;
  1042d4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042d7:	0f b7 80 8c 04 00 00 	movzwl 0x48c(%eax),%eax
  1042de:	89 c2                	mov    %eax,%edx
  1042e0:	83 ca 1b             	or     $0x1b,%edx
  1042e3:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042e6:	66 89 90 8c 04 00 00 	mov    %dx,0x48c(%eax)
		cp->sv.tf.ds |= CPU_GDT_UDATA | 0x3;
  1042ed:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042f0:	0f b7 80 7c 04 00 00 	movzwl 0x47c(%eax),%eax
  1042f7:	89 c2                	mov    %eax,%edx
  1042f9:	83 ca 23             	or     $0x23,%edx
  1042fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1042ff:	66 89 90 7c 04 00 00 	mov    %dx,0x47c(%eax)
		cp->sv.tf.es |= CPU_GDT_UDATA | 0x3;
  104306:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104309:	0f b7 80 78 04 00 00 	movzwl 0x478(%eax),%eax
  104310:	89 c2                	mov    %eax,%edx
  104312:	83 ca 23             	or     $0x23,%edx
  104315:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104318:	66 89 90 78 04 00 00 	mov    %dx,0x478(%eax)
		cp->sv.tf.fs |= CPU_GDT_UDATA | 0x3;
  10431f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104322:	0f b7 80 74 04 00 00 	movzwl 0x474(%eax),%eax
  104329:	89 c2                	mov    %eax,%edx
  10432b:	83 ca 23             	or     $0x23,%edx
  10432e:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104331:	66 89 90 74 04 00 00 	mov    %dx,0x474(%eax)
		cp->sv.tf.gs |= CPU_GDT_UDATA | 0x3;
  104338:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10433b:	0f b7 80 70 04 00 00 	movzwl 0x470(%eax),%eax
  104342:	89 c2                	mov    %eax,%edx
  104344:	83 ca 23             	or     $0x23,%edx
  104347:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10434a:	66 89 90 70 04 00 00 	mov    %dx,0x470(%eax)
		cp->sv.tf.ss |= CPU_GDT_UDATA | 0x3;
  104351:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104354:	0f b7 80 98 04 00 00 	movzwl 0x498(%eax),%eax
  10435b:	89 c2                	mov    %eax,%edx
  10435d:	83 ca 23             	or     $0x23,%edx
  104360:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104363:	66 89 90 98 04 00 00 	mov    %dx,0x498(%eax)
	}
	spinlock_release(&(cp->lock));
  10436a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10436d:	89 04 24             	mov    %eax,(%esp)
  104370:	e8 7f ea ff ff       	call   102df4 <spinlock_release>
	spinlock_release(&(p->lock));
  104375:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104378:	89 04 24             	mov    %eax,(%esp)
  10437b:	e8 74 ea ff ff       	call   102df4 <spinlock_release>
	if(cmd & SYS_START) {
  104380:	8b 45 0c             	mov    0xc(%ebp),%eax
  104383:	83 e0 10             	and    $0x10,%eax
  104386:	85 c0                	test   %eax,%eax
  104388:	74 0b                	je     104395 <do_put+0x1cd>
		proc_ready(cp);
  10438a:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10438d:	89 04 24             	mov    %eax,(%esp)
  104390:	e8 10 f3 ff ff       	call   1036a5 <proc_ready>
	}
	trap_return(tf);
  104395:	8b 45 08             	mov    0x8(%ebp),%eax
  104398:	89 04 24             	mov    %eax,(%esp)
  10439b:	e8 30 e5 ff ff       	call   1028d0 <trap_return>

001043a0 <do_get>:
}

static void do_get(trapframe *tf, uint32_t cmd)
{
  1043a0:	55                   	push   %ebp
  1043a1:	89 e5                	mov    %esp,%ebp
  1043a3:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	proc *cp;
	uint8_t cn = tf->regs.edx;
  1043a6:	8b 45 08             	mov    0x8(%ebp),%eax
  1043a9:	8b 40 14             	mov    0x14(%eax),%eax
  1043ac:	88 45 f7             	mov    %al,-0x9(%ebp)
	p = cpu_cur()->proc;
  1043af:	e8 20 fd ff ff       	call   1040d4 <cpu_cur>
  1043b4:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  1043ba:	89 45 ec             	mov    %eax,-0x14(%ebp)
	spinlock_acquire(&(p->lock));
  1043bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1043c0:	89 04 24             	mov    %eax,(%esp)
  1043c3:	e8 b7 e9 ff ff       	call   102d7f <spinlock_acquire>
	cp = p->child[cn];
  1043c8:	0f b6 55 f7          	movzbl -0x9(%ebp),%edx
  1043cc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1043cf:	83 c2 0c             	add    $0xc,%edx
  1043d2:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
  1043d6:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if(!cp) panic("no such child.\n");
  1043d9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1043dd:	75 1c                	jne    1043fb <do_get+0x5b>
  1043df:	c7 44 24 08 88 92 10 	movl   $0x109288,0x8(%esp)
  1043e6:	00 
  1043e7:	c7 44 24 04 7b 00 00 	movl   $0x7b,0x4(%esp)
  1043ee:	00 
  1043ef:	c7 04 24 1b 92 10 00 	movl   $0x10921b,(%esp)
  1043f6:	e8 bd c0 ff ff       	call   1004b8 <debug_panic>
	spinlock_acquire(&(cp->lock));
  1043fb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1043fe:	89 04 24             	mov    %eax,(%esp)
  104401:	e8 79 e9 ff ff       	call   102d7f <spinlock_acquire>
	if(cp->state != PROC_STOP) {
  104406:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104409:	8b 80 3c 04 00 00    	mov    0x43c(%eax),%eax
  10440f:	85 c0                	test   %eax,%eax
  104411:	74 24                	je     104437 <do_get+0x97>
		spinlock_release(&(cp->lock));
  104413:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104416:	89 04 24             	mov    %eax,(%esp)
  104419:	e8 d6 e9 ff ff       	call   102df4 <spinlock_release>
		proc_wait(p, cp, tf);
  10441e:	8b 45 08             	mov    0x8(%ebp),%eax
  104421:	89 44 24 08          	mov    %eax,0x8(%esp)
  104425:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104428:	89 44 24 04          	mov    %eax,0x4(%esp)
  10442c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  10442f:	89 04 24             	mov    %eax,(%esp)
  104432:	e8 9b f3 ff ff       	call   1037d2 <proc_wait>
	}
	if(cmd & SYS_REGS) {
  104437:	8b 45 0c             	mov    0xc(%ebp),%eax
  10443a:	25 00 10 00 00       	and    $0x1000,%eax
  10443f:	85 c0                	test   %eax,%eax
  104441:	74 23                	je     104466 <do_get+0xc6>
		memcpy((void*)tf->regs.ebx, &(cp->sv), sizeof(cp->sv));
  104443:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104446:	8d 90 50 04 00 00    	lea    0x450(%eax),%edx
  10444c:	8b 45 08             	mov    0x8(%ebp),%eax
  10444f:	8b 40 10             	mov    0x10(%eax),%eax
  104452:	c7 44 24 08 50 02 00 	movl   $0x250,0x8(%esp)
  104459:	00 
  10445a:	89 54 24 04          	mov    %edx,0x4(%esp)
  10445e:	89 04 24             	mov    %eax,(%esp)
  104461:	e8 4d 3b 00 00       	call   107fb3 <memcpy>
	}
	spinlock_release(&(cp->lock));
  104466:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104469:	89 04 24             	mov    %eax,(%esp)
  10446c:	e8 83 e9 ff ff       	call   102df4 <spinlock_release>
	spinlock_release(&(p->lock));
  104471:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104474:	89 04 24             	mov    %eax,(%esp)
  104477:	e8 78 e9 ff ff       	call   102df4 <spinlock_release>
	trap_return(tf);
  10447c:	8b 45 08             	mov    0x8(%ebp),%eax
  10447f:	89 04 24             	mov    %eax,(%esp)
  104482:	e8 49 e4 ff ff       	call   1028d0 <trap_return>

00104487 <do_ret>:
}

static void do_ret(trapframe *tf, uint32_t cmd)
{
  104487:	55                   	push   %ebp
  104488:	89 e5                	mov    %esp,%ebp
  10448a:	83 ec 28             	sub    $0x28,%esp
	proc *p;
	proc *cp;
	cp = cpu_cur()->proc;
  10448d:	e8 42 fc ff ff       	call   1040d4 <cpu_cur>
  104492:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104498:	89 45 f4             	mov    %eax,-0xc(%ebp)
	p = cp->parent;
  10449b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10449e:	8b 40 38             	mov    0x38(%eax),%eax
  1044a1:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cprintf("do_ret child=%p parent=%p\n", cp, p);
  1044a4:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1044a7:	89 44 24 08          	mov    %eax,0x8(%esp)
  1044ab:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1044ae:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044b2:	c7 04 24 98 92 10 00 	movl   $0x109298,(%esp)
  1044b9:	e8 bf 37 00 00       	call   107c7d <cprintf>
	proc_ret(tf, 1);
  1044be:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  1044c5:	00 
  1044c6:	8b 45 08             	mov    0x8(%ebp),%eax
  1044c9:	89 04 24             	mov    %eax,(%esp)
  1044cc:	e8 c0 f4 ff ff       	call   103991 <proc_ret>

001044d1 <do_cputs>:
}

static void
do_cputs(trapframe *tf, uint32_t cmd)
{
  1044d1:	55                   	push   %ebp
  1044d2:	89 e5                	mov    %esp,%ebp
  1044d4:	83 ec 18             	sub    $0x18,%esp
	// Print the string supplied by the user: pointer in EBX
	cprintf("%s", (char*)tf->regs.ebx);
  1044d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1044da:	8b 40 10             	mov    0x10(%eax),%eax
  1044dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1044e1:	c7 04 24 b3 92 10 00 	movl   $0x1092b3,(%esp)
  1044e8:	e8 90 37 00 00       	call   107c7d <cprintf>

	trap_return(tf);	// syscall completed
  1044ed:	8b 45 08             	mov    0x8(%ebp),%eax
  1044f0:	89 04 24             	mov    %eax,(%esp)
  1044f3:	e8 d8 e3 ff ff       	call   1028d0 <trap_return>

001044f8 <syscall>:
// Common function to handle all system calls -
// decode the system call type and call an appropriate handler function.
// Be sure to handle undefined system calls appropriately.
void
syscall(trapframe *tf)
{
  1044f8:	55                   	push   %ebp
  1044f9:	89 e5                	mov    %esp,%ebp
  1044fb:	83 ec 28             	sub    $0x28,%esp
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
  1044fe:	8b 45 08             	mov    0x8(%ebp),%eax
  104501:	8b 40 1c             	mov    0x1c(%eax),%eax
  104504:	89 45 f4             	mov    %eax,-0xc(%ebp)
	switch (cmd & SYS_TYPE) {
  104507:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10450a:	83 e0 0f             	and    $0xf,%eax
  10450d:	83 f8 01             	cmp    $0x1,%eax
  104510:	74 25                	je     104537 <syscall+0x3f>
  104512:	83 f8 01             	cmp    $0x1,%eax
  104515:	72 0c                	jb     104523 <syscall+0x2b>
  104517:	83 f8 02             	cmp    $0x2,%eax
  10451a:	74 2f                	je     10454b <syscall+0x53>
  10451c:	83 f8 03             	cmp    $0x3,%eax
  10451f:	74 3e                	je     10455f <syscall+0x67>
	case SYS_CPUTS:	return do_cputs(tf, cmd);
	case SYS_PUT:	return do_put(tf, cmd);
	case SYS_GET:	return do_get(tf, cmd);
	case SYS_RET:	return do_ret(tf, cmd);
	default:	return;
  104521:	eb 4f                	jmp    104572 <syscall+0x7a>
syscall(trapframe *tf)
{
	// EAX register holds system call command/flags
	uint32_t cmd = tf->regs.eax;
	switch (cmd & SYS_TYPE) {
	case SYS_CPUTS:	return do_cputs(tf, cmd);
  104523:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104526:	89 44 24 04          	mov    %eax,0x4(%esp)
  10452a:	8b 45 08             	mov    0x8(%ebp),%eax
  10452d:	89 04 24             	mov    %eax,(%esp)
  104530:	e8 9c ff ff ff       	call   1044d1 <do_cputs>
  104535:	eb 3b                	jmp    104572 <syscall+0x7a>
	case SYS_PUT:	return do_put(tf, cmd);
  104537:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10453a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10453e:	8b 45 08             	mov    0x8(%ebp),%eax
  104541:	89 04 24             	mov    %eax,(%esp)
  104544:	e8 7f fc ff ff       	call   1041c8 <do_put>
  104549:	eb 27                	jmp    104572 <syscall+0x7a>
	case SYS_GET:	return do_get(tf, cmd);
  10454b:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10454e:	89 44 24 04          	mov    %eax,0x4(%esp)
  104552:	8b 45 08             	mov    0x8(%ebp),%eax
  104555:	89 04 24             	mov    %eax,(%esp)
  104558:	e8 43 fe ff ff       	call   1043a0 <do_get>
  10455d:	eb 13                	jmp    104572 <syscall+0x7a>
	case SYS_RET:	return do_ret(tf, cmd);
  10455f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104562:	89 44 24 04          	mov    %eax,0x4(%esp)
  104566:	8b 45 08             	mov    0x8(%ebp),%eax
  104569:	89 04 24             	mov    %eax,(%esp)
  10456c:	e8 16 ff ff ff       	call   104487 <do_ret>
  104571:	90                   	nop
	default:	return;
	}
}
  104572:	c9                   	leave  
  104573:	c3                   	ret    

00104574 <lockadd>:
}

// Atomically add incr to *addr.
static inline void
lockadd(volatile int32_t *addr, int32_t incr)
{
  104574:	55                   	push   %ebp
  104575:	89 e5                	mov    %esp,%ebp
	asm volatile("lock; addl %1,%0" : "+m" (*addr) : "r" (incr) : "cc");
  104577:	8b 45 08             	mov    0x8(%ebp),%eax
  10457a:	8b 55 0c             	mov    0xc(%ebp),%edx
  10457d:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104580:	f0 01 10             	lock add %edx,(%eax)
}
  104583:	5d                   	pop    %ebp
  104584:	c3                   	ret    

00104585 <lockaddz>:

// Atomically add incr to *addr and return true if the result is zero.
static inline uint8_t
lockaddz(volatile int32_t *addr, int32_t incr)
{
  104585:	55                   	push   %ebp
  104586:	89 e5                	mov    %esp,%ebp
  104588:	83 ec 10             	sub    $0x10,%esp
	uint8_t zero;
	asm volatile("lock; addl %2,%0; setzb %1"
  10458b:	8b 45 08             	mov    0x8(%ebp),%eax
  10458e:	8b 55 0c             	mov    0xc(%ebp),%edx
  104591:	8b 4d 08             	mov    0x8(%ebp),%ecx
  104594:	f0 01 10             	lock add %edx,(%eax)
  104597:	0f 94 45 ff          	sete   -0x1(%ebp)
		: "+m" (*addr), "=rm" (zero)
		: "r" (incr)
		: "cc");
	return zero;
  10459b:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
  10459f:	c9                   	leave  
  1045a0:	c3                   	ret    

001045a1 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  1045a1:	55                   	push   %ebp
  1045a2:	89 e5                	mov    %esp,%ebp
  1045a4:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  1045a7:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  1045aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  1045ad:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1045b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1045b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  1045b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  1045bb:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1045be:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  1045c4:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  1045c9:	74 24                	je     1045ef <cpu_cur+0x4e>
  1045cb:	c7 44 24 0c b8 92 10 	movl   $0x1092b8,0xc(%esp)
  1045d2:	00 
  1045d3:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1045da:	00 
  1045db:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  1045e2:	00 
  1045e3:	c7 04 24 e3 92 10 00 	movl   $0x1092e3,(%esp)
  1045ea:	e8 c9 be ff ff       	call   1004b8 <debug_panic>
	return c;
  1045ef:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  1045f2:	c9                   	leave  
  1045f3:	c3                   	ret    

001045f4 <cpu_onboot>:

// Returns true if we're running on the bootstrap CPU.
static inline int
cpu_onboot() {
  1045f4:	55                   	push   %ebp
  1045f5:	89 e5                	mov    %esp,%ebp
  1045f7:	83 ec 08             	sub    $0x8,%esp
	return cpu_cur() == &cpu_boot;
  1045fa:	e8 a2 ff ff ff       	call   1045a1 <cpu_cur>
  1045ff:	3d 00 b0 10 00       	cmp    $0x10b000,%eax
  104604:	0f 94 c0             	sete   %al
  104607:	0f b6 c0             	movzbl %al,%eax
}
  10460a:	c9                   	leave  
  10460b:	c3                   	ret    

0010460c <pmap_init>:
// (addresses outside of the range between VM_USERLO and VM_USERHI).
// The user part of the address space remains all PTE_ZERO until later.
//
void
pmap_init(void)
{
  10460c:	55                   	push   %ebp
  10460d:	89 e5                	mov    %esp,%ebp
  10460f:	83 ec 38             	sub    $0x38,%esp
	if (cpu_onboot()) {
  104612:	e8 dd ff ff ff       	call   1045f4 <cpu_onboot>
  104617:	85 c0                	test   %eax,%eax
  104619:	74 1c                	je     104637 <pmap_init+0x2b>
		// but only accessible in kernel mode (not in user mode).
		// The easiest way to do this is to use 4MB page mappings.
		// Since these page mappings never change on context switches,
		// we can also mark them global (PTE_G) so the processor
		// doesn't flush these mappings when we reload the PDBR.
		panic("pmap_init() not implemented");
  10461b:	c7 44 24 08 f0 92 10 	movl   $0x1092f0,0x8(%esp)
  104622:	00 
  104623:	c7 44 24 04 3f 00 00 	movl   $0x3f,0x4(%esp)
  10462a:	00 
  10462b:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104632:	e8 81 be ff ff       	call   1004b8 <debug_panic>

static gcc_inline uint32_t
rcr4(void)
{
	uint32_t cr4;
	__asm __volatile("movl %%cr4,%0" : "=r" (cr4));
  104637:	0f 20 e0             	mov    %cr4,%eax
  10463a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	return cr4;
  10463d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
	// where LA == PA according to the page mapping structures.
	// In PIOS this is always the case for the kernel's address space,
	// so we don't have to play any special tricks as in other kernels.

	// Enable 4MB pages and global pages.
	uint32_t cr4 = rcr4();
  104640:	89 45 dc             	mov    %eax,-0x24(%ebp)
	cr4 |= CR4_PSE | CR4_PGE;
  104643:	81 4d dc 90 00 00 00 	orl    $0x90,-0x24(%ebp)
  10464a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10464d:	89 45 e8             	mov    %eax,-0x18(%ebp)
}

static gcc_inline void
lcr4(uint32_t val)
{
	__asm __volatile("movl %0,%%cr4" : : "r" (val));
  104650:	8b 45 e8             	mov    -0x18(%ebp),%eax
  104653:	0f 22 e0             	mov    %eax,%cr4
	lcr4(cr4);

	// Install the bootstrap page directory into the PDBR.
	lcr3(mem_phys(pmap_bootpdir));
  104656:	b8 00 00 12 00       	mov    $0x120000,%eax
  10465b:	89 45 ec             	mov    %eax,-0x14(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  10465e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104661:	0f 22 d8             	mov    %eax,%cr3

static gcc_inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
  104664:	0f 20 c0             	mov    %cr0,%eax
  104667:	89 45 f0             	mov    %eax,-0x10(%ebp)
	return val;
  10466a:	8b 45 f0             	mov    -0x10(%ebp),%eax

	// Turn on paging.
	uint32_t cr0 = rcr0();
  10466d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_MP|CR0_TS;
  104670:	81 4d e0 2b 00 05 80 	orl    $0x8005002b,-0x20(%ebp)
	cr0 &= ~(CR0_EM);
  104677:	83 65 e0 fb          	andl   $0xfffffffb,-0x20(%ebp)
  10467b:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10467e:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
  104681:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104684:	0f 22 c0             	mov    %eax,%cr0
	lcr0(cr0);

	// If we survived the lcr0, we're running with paging enabled.
	// Now check the page table management functions below.
	if (cpu_onboot())
  104687:	e8 68 ff ff ff       	call   1045f4 <cpu_onboot>
  10468c:	85 c0                	test   %eax,%eax
  10468e:	74 05                	je     104695 <pmap_init+0x89>
		pmap_check();
  104690:	e8 1d 09 00 00       	call   104fb2 <pmap_check>
}
  104695:	c9                   	leave  
  104696:	c3                   	ret    

00104697 <pmap_newpdir>:
// Allocate a new page directory, initialized from the bootstrap pdir.
// Returns the new pdir with a reference count of 1.
//
pte_t *
pmap_newpdir(void)
{
  104697:	55                   	push   %ebp
  104698:	89 e5                	mov    %esp,%ebp
  10469a:	83 ec 28             	sub    $0x28,%esp
	pageinfo *pi = mem_alloc();
  10469d:	e8 b7 c5 ff ff       	call   100c59 <mem_alloc>
  1046a2:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (pi == NULL)
  1046a5:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  1046a9:	75 0a                	jne    1046b5 <pmap_newpdir+0x1e>
		return NULL;
  1046ab:	b8 00 00 00 00       	mov    $0x0,%eax
  1046b0:	e9 24 01 00 00       	jmp    1047d9 <pmap_newpdir+0x142>
  1046b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1046b8:	89 45 f4             	mov    %eax,-0xc(%ebp)

// Atomically increment the reference count on a page.
static gcc_inline void
mem_incref(pageinfo *pi)
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  1046bb:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1046c0:	83 c0 08             	add    $0x8,%eax
  1046c3:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1046c6:	76 15                	jbe    1046dd <pmap_newpdir+0x46>
  1046c8:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1046cd:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  1046d3:	c1 e2 03             	shl    $0x3,%edx
  1046d6:	01 d0                	add    %edx,%eax
  1046d8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1046db:	72 24                	jb     104701 <pmap_newpdir+0x6a>
  1046dd:	c7 44 24 0c 18 93 10 	movl   $0x109318,0xc(%esp)
  1046e4:	00 
  1046e5:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1046ec:	00 
  1046ed:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  1046f4:	00 
  1046f5:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  1046fc:	e8 b7 bd ff ff       	call   1004b8 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  104701:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104706:	ba 00 10 12 00       	mov    $0x121000,%edx
  10470b:	c1 ea 0c             	shr    $0xc,%edx
  10470e:	c1 e2 03             	shl    $0x3,%edx
  104711:	01 d0                	add    %edx,%eax
  104713:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104716:	75 24                	jne    10473c <pmap_newpdir+0xa5>
  104718:	c7 44 24 0c 5c 93 10 	movl   $0x10935c,0xc(%esp)
  10471f:	00 
  104720:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104727:	00 
  104728:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
  10472f:	00 
  104730:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  104737:	e8 7c bd ff ff       	call   1004b8 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  10473c:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104741:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104746:	c1 ea 0c             	shr    $0xc,%edx
  104749:	c1 e2 03             	shl    $0x3,%edx
  10474c:	01 d0                	add    %edx,%eax
  10474e:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104751:	72 3b                	jb     10478e <pmap_newpdir+0xf7>
  104753:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104758:	ba 07 20 12 00       	mov    $0x122007,%edx
  10475d:	c1 ea 0c             	shr    $0xc,%edx
  104760:	c1 e2 03             	shl    $0x3,%edx
  104763:	01 d0                	add    %edx,%eax
  104765:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104768:	77 24                	ja     10478e <pmap_newpdir+0xf7>
  10476a:	c7 44 24 0c 78 93 10 	movl   $0x109378,0xc(%esp)
  104771:	00 
  104772:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104779:	00 
  10477a:	c7 44 24 04 5a 00 00 	movl   $0x5a,0x4(%esp)
  104781:	00 
  104782:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  104789:	e8 2a bd ff ff       	call   1004b8 <debug_panic>

	lockadd(&pi->refcount, 1);
  10478e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104791:	83 c0 04             	add    $0x4,%eax
  104794:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  10479b:	00 
  10479c:	89 04 24             	mov    %eax,(%esp)
  10479f:	e8 d0 fd ff ff       	call   104574 <lockadd>
	mem_incref(pi);
	pte_t *pdir = mem_pi2ptr(pi);
  1047a4:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1047a7:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1047ac:	89 d1                	mov    %edx,%ecx
  1047ae:	29 c1                	sub    %eax,%ecx
  1047b0:	89 c8                	mov    %ecx,%eax
  1047b2:	c1 f8 03             	sar    $0x3,%eax
  1047b5:	c1 e0 0c             	shl    $0xc,%eax
  1047b8:	89 45 f0             	mov    %eax,-0x10(%ebp)

	// Initialize it from the bootstrap page directory
	assert(sizeof(pmap_bootpdir) == PAGESIZE);
	memmove(pdir, pmap_bootpdir, PAGESIZE);
  1047bb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1047c2:	00 
  1047c3:	c7 44 24 04 00 00 12 	movl   $0x120000,0x4(%esp)
  1047ca:	00 
  1047cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
  1047ce:	89 04 24             	mov    %eax,(%esp)
  1047d1:	e8 02 37 00 00       	call   107ed8 <memmove>

	return pdir;
  1047d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
  1047d9:	c9                   	leave  
  1047da:	c3                   	ret    

001047db <pmap_freepdir>:

// Free a page directory, and all page tables and mappings it may contain.
void
pmap_freepdir(pageinfo *pdirpi)
{
  1047db:	55                   	push   %ebp
  1047dc:	89 e5                	mov    %esp,%ebp
  1047de:	83 ec 18             	sub    $0x18,%esp
	pmap_remove(mem_pi2ptr(pdirpi), VM_USERLO, VM_USERHI-VM_USERLO);
  1047e1:	8b 55 08             	mov    0x8(%ebp),%edx
  1047e4:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1047e9:	89 d1                	mov    %edx,%ecx
  1047eb:	29 c1                	sub    %eax,%ecx
  1047ed:	89 c8                	mov    %ecx,%eax
  1047ef:	c1 f8 03             	sar    $0x3,%eax
  1047f2:	c1 e0 0c             	shl    $0xc,%eax
  1047f5:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  1047fc:	b0 
  1047fd:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  104804:	40 
  104805:	89 04 24             	mov    %eax,(%esp)
  104808:	e8 ff 01 00 00       	call   104a0c <pmap_remove>
	mem_free(pdirpi);
  10480d:	8b 45 08             	mov    0x8(%ebp),%eax
  104810:	89 04 24             	mov    %eax,(%esp)
  104813:	e8 92 c4 ff ff       	call   100caa <mem_free>
}
  104818:	c9                   	leave  
  104819:	c3                   	ret    

0010481a <pmap_freeptab>:

// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
  10481a:	55                   	push   %ebp
  10481b:	89 e5                	mov    %esp,%ebp
  10481d:	83 ec 38             	sub    $0x38,%esp
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
  104820:	8b 55 08             	mov    0x8(%ebp),%edx
  104823:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104828:	89 d1                	mov    %edx,%ecx
  10482a:	29 c1                	sub    %eax,%ecx
  10482c:	89 c8                	mov    %ecx,%eax
  10482e:	c1 f8 03             	sar    $0x3,%eax
  104831:	c1 e0 0c             	shl    $0xc,%eax
  104834:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  104837:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10483a:	05 00 10 00 00       	add    $0x1000,%eax
  10483f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for (; pte < ptelim; pte++) {
  104842:	e9 5f 01 00 00       	jmp    1049a6 <pmap_freeptab+0x18c>
		uint32_t pgaddr = PGADDR(*pte);
  104847:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  10484a:	8b 00                	mov    (%eax),%eax
  10484c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104851:	89 45 ec             	mov    %eax,-0x14(%ebp)
		if (pgaddr != PTE_ZERO)
  104854:	b8 00 10 12 00       	mov    $0x121000,%eax
  104859:	39 45 ec             	cmp    %eax,-0x14(%ebp)
  10485c:	0f 84 40 01 00 00    	je     1049a2 <pmap_freeptab+0x188>
			mem_decref(mem_phys2pi(pgaddr), mem_free);
  104862:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104867:	8b 55 ec             	mov    -0x14(%ebp),%edx
  10486a:	c1 ea 0c             	shr    $0xc,%edx
  10486d:	c1 e2 03             	shl    $0x3,%edx
  104870:	01 d0                	add    %edx,%eax
  104872:	89 45 f4             	mov    %eax,-0xc(%ebp)
  104875:	c7 45 f0 aa 0c 10 00 	movl   $0x100caa,-0x10(%ebp)
// Atomically decrement the reference count on a page,
// freeing the page with the provided function if there are no more refs.
static gcc_inline void
mem_decref(pageinfo* pi, void (*freefun)(pageinfo *pi))
{
	assert(pi > &mem_pageinfo[1] && pi < &mem_pageinfo[mem_npage]);
  10487c:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104881:	83 c0 08             	add    $0x8,%eax
  104884:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104887:	76 15                	jbe    10489e <pmap_freeptab+0x84>
  104889:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  10488e:	8b 15 1c ed 11 00    	mov    0x11ed1c,%edx
  104894:	c1 e2 03             	shl    $0x3,%edx
  104897:	01 d0                	add    %edx,%eax
  104899:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  10489c:	72 24                	jb     1048c2 <pmap_freeptab+0xa8>
  10489e:	c7 44 24 0c 18 93 10 	movl   $0x109318,0xc(%esp)
  1048a5:	00 
  1048a6:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1048ad:	00 
  1048ae:	c7 44 24 04 64 00 00 	movl   $0x64,0x4(%esp)
  1048b5:	00 
  1048b6:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  1048bd:	e8 f6 bb ff ff       	call   1004b8 <debug_panic>
	assert(pi != mem_ptr2pi(pmap_zero));	// Don't alloc/free zero page!
  1048c2:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1048c7:	ba 00 10 12 00       	mov    $0x121000,%edx
  1048cc:	c1 ea 0c             	shr    $0xc,%edx
  1048cf:	c1 e2 03             	shl    $0x3,%edx
  1048d2:	01 d0                	add    %edx,%eax
  1048d4:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  1048d7:	75 24                	jne    1048fd <pmap_freeptab+0xe3>
  1048d9:	c7 44 24 0c 5c 93 10 	movl   $0x10935c,0xc(%esp)
  1048e0:	00 
  1048e1:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1048e8:	00 
  1048e9:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
  1048f0:	00 
  1048f1:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  1048f8:	e8 bb bb ff ff       	call   1004b8 <debug_panic>
	assert(pi < mem_ptr2pi(start) || pi > mem_ptr2pi(end-1));
  1048fd:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104902:	ba 0c 00 10 00       	mov    $0x10000c,%edx
  104907:	c1 ea 0c             	shr    $0xc,%edx
  10490a:	c1 e2 03             	shl    $0x3,%edx
  10490d:	01 d0                	add    %edx,%eax
  10490f:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104912:	72 3b                	jb     10494f <pmap_freeptab+0x135>
  104914:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  104919:	ba 07 20 12 00       	mov    $0x122007,%edx
  10491e:	c1 ea 0c             	shr    $0xc,%edx
  104921:	c1 e2 03             	shl    $0x3,%edx
  104924:	01 d0                	add    %edx,%eax
  104926:	39 45 f4             	cmp    %eax,-0xc(%ebp)
  104929:	77 24                	ja     10494f <pmap_freeptab+0x135>
  10492b:	c7 44 24 0c 78 93 10 	movl   $0x109378,0xc(%esp)
  104932:	00 
  104933:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10493a:	00 
  10493b:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
  104942:	00 
  104943:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  10494a:	e8 69 bb ff ff       	call   1004b8 <debug_panic>

	if (lockaddz(&pi->refcount, -1))
  10494f:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104952:	83 c0 04             	add    $0x4,%eax
  104955:	c7 44 24 04 ff ff ff 	movl   $0xffffffff,0x4(%esp)
  10495c:	ff 
  10495d:	89 04 24             	mov    %eax,(%esp)
  104960:	e8 20 fc ff ff       	call   104585 <lockaddz>
  104965:	84 c0                	test   %al,%al
  104967:	74 0b                	je     104974 <pmap_freeptab+0x15a>
			freefun(pi);
  104969:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10496c:	89 04 24             	mov    %eax,(%esp)
  10496f:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104972:	ff d0                	call   *%eax
	assert(pi->refcount >= 0);
  104974:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104977:	8b 40 04             	mov    0x4(%eax),%eax
  10497a:	85 c0                	test   %eax,%eax
  10497c:	79 24                	jns    1049a2 <pmap_freeptab+0x188>
  10497e:	c7 44 24 0c a9 93 10 	movl   $0x1093a9,0xc(%esp)
  104985:	00 
  104986:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10498d:	00 
  10498e:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
  104995:	00 
  104996:	c7 04 24 4f 93 10 00 	movl   $0x10934f,(%esp)
  10499d:	e8 16 bb ff ff       	call   1004b8 <debug_panic>
// Free a page table and all page mappings it may contain.
void
pmap_freeptab(pageinfo *ptabpi)
{
	pte_t *pte = mem_pi2ptr(ptabpi), *ptelim = pte + NPTENTRIES;
	for (; pte < ptelim; pte++) {
  1049a2:	83 45 e4 04          	addl   $0x4,-0x1c(%ebp)
  1049a6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1049a9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1049ac:	0f 82 95 fe ff ff    	jb     104847 <pmap_freeptab+0x2d>
		uint32_t pgaddr = PGADDR(*pte);
		if (pgaddr != PTE_ZERO)
			mem_decref(mem_phys2pi(pgaddr), mem_free);
	}
	mem_free(ptabpi);
  1049b2:	8b 45 08             	mov    0x8(%ebp),%eax
  1049b5:	89 04 24             	mov    %eax,(%esp)
  1049b8:	e8 ed c2 ff ff       	call   100caa <mem_free>
}
  1049bd:	c9                   	leave  
  1049be:	c3                   	ret    

001049bf <pmap_walk>:
// Hint 2: the x86 MMU checks permission bits in both the page directory
// and the page table, so it's safe to leave some page permissions
// more permissive than strictly necessary.
pte_t *
pmap_walk(pde_t *pdir, uint32_t va, bool writing)
{
  1049bf:	55                   	push   %ebp
  1049c0:	89 e5                	mov    %esp,%ebp
  1049c2:	83 ec 18             	sub    $0x18,%esp
	assert(va >= VM_USERLO && va < VM_USERHI);
  1049c5:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  1049cc:	76 09                	jbe    1049d7 <pmap_walk+0x18>
  1049ce:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  1049d5:	76 24                	jbe    1049fb <pmap_walk+0x3c>
  1049d7:	c7 44 24 0c bc 93 10 	movl   $0x1093bc,0xc(%esp)
  1049de:	00 
  1049df:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1049e6:	00 
  1049e7:	c7 44 24 04 a1 00 00 	movl   $0xa1,0x4(%esp)
  1049ee:	00 
  1049ef:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1049f6:	e8 bd ba ff ff       	call   1004b8 <debug_panic>

	// Fill in this function
	return NULL;
  1049fb:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104a00:	c9                   	leave  
  104a01:	c3                   	ret    

00104a02 <pmap_insert>:
//
// Hint: The reference solution uses pmap_walk, pmap_remove, and mem_pi2phys.
//
pte_t *
pmap_insert(pde_t *pdir, pageinfo *pi, uint32_t va, int perm)
{
  104a02:	55                   	push   %ebp
  104a03:	89 e5                	mov    %esp,%ebp
	// Fill in this function
	return NULL;
  104a05:	b8 00 00 00 00       	mov    $0x0,%eax
}
  104a0a:	5d                   	pop    %ebp
  104a0b:	c3                   	ret    

00104a0c <pmap_remove>:
// Hint: The TA solution is implemented using pmap_lookup,
// 	pmap_inval, and mem_decref.
//
void
pmap_remove(pde_t *pdir, uint32_t va, size_t size)
{
  104a0c:	55                   	push   %ebp
  104a0d:	89 e5                	mov    %esp,%ebp
  104a0f:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(size) == 0);	// must be page-aligned
  104a12:	8b 45 10             	mov    0x10(%ebp),%eax
  104a15:	25 ff 0f 00 00       	and    $0xfff,%eax
  104a1a:	85 c0                	test   %eax,%eax
  104a1c:	74 24                	je     104a42 <pmap_remove+0x36>
  104a1e:	c7 44 24 0c de 93 10 	movl   $0x1093de,0xc(%esp)
  104a25:	00 
  104a26:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104a2d:	00 
  104a2e:	c7 44 24 04 da 00 00 	movl   $0xda,0x4(%esp)
  104a35:	00 
  104a36:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104a3d:	e8 76 ba ff ff       	call   1004b8 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  104a42:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104a49:	76 09                	jbe    104a54 <pmap_remove+0x48>
  104a4b:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104a52:	76 24                	jbe    104a78 <pmap_remove+0x6c>
  104a54:	c7 44 24 0c bc 93 10 	movl   $0x1093bc,0xc(%esp)
  104a5b:	00 
  104a5c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104a63:	00 
  104a64:	c7 44 24 04 db 00 00 	movl   $0xdb,0x4(%esp)
  104a6b:	00 
  104a6c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104a73:	e8 40 ba ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - va);
  104a78:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104a7d:	2b 45 0c             	sub    0xc(%ebp),%eax
  104a80:	3b 45 10             	cmp    0x10(%ebp),%eax
  104a83:	73 24                	jae    104aa9 <pmap_remove+0x9d>
  104a85:	c7 44 24 0c ef 93 10 	movl   $0x1093ef,0xc(%esp)
  104a8c:	00 
  104a8d:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104a94:	00 
  104a95:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
  104a9c:	00 
  104a9d:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104aa4:	e8 0f ba ff ff       	call   1004b8 <debug_panic>

	// Fill in this function
}
  104aa9:	c9                   	leave  
  104aaa:	c3                   	ret    

00104aab <pmap_inval>:
// but only if the page tables being edited are the ones
// currently in use by the processor.
//
void
pmap_inval(pde_t *pdir, uint32_t va, size_t size)
{
  104aab:	55                   	push   %ebp
  104aac:	89 e5                	mov    %esp,%ebp
  104aae:	83 ec 18             	sub    $0x18,%esp
	// Flush the entry only if we're modifying the current address space.
	proc *p = proc_cur();
  104ab1:	e8 eb fa ff ff       	call   1045a1 <cpu_cur>
  104ab6:	8b 80 b4 00 00 00    	mov    0xb4(%eax),%eax
  104abc:	89 45 ec             	mov    %eax,-0x14(%ebp)
	if (p == NULL || p->pdir == pdir) {
  104abf:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  104ac3:	74 0e                	je     104ad3 <pmap_inval+0x28>
  104ac5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  104ac8:	8b 80 a0 06 00 00    	mov    0x6a0(%eax),%eax
  104ace:	3b 45 08             	cmp    0x8(%ebp),%eax
  104ad1:	75 23                	jne    104af6 <pmap_inval+0x4b>
		if (size == PAGESIZE)
  104ad3:	81 7d 10 00 10 00 00 	cmpl   $0x1000,0x10(%ebp)
  104ada:	75 0e                	jne    104aea <pmap_inval+0x3f>
			invlpg(mem_ptr(va));	// invalidate one page
  104adc:	8b 45 0c             	mov    0xc(%ebp),%eax
  104adf:	89 45 f0             	mov    %eax,-0x10(%ebp)
}

static gcc_inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
  104ae2:	8b 45 f0             	mov    -0x10(%ebp),%eax
  104ae5:	0f 01 38             	invlpg (%eax)
  104ae8:	eb 0c                	jmp    104af6 <pmap_inval+0x4b>
		else
			lcr3(mem_phys(pdir));	// invalidate everything
  104aea:	8b 45 08             	mov    0x8(%ebp),%eax
  104aed:	89 45 f4             	mov    %eax,-0xc(%ebp)
}

static gcc_inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
  104af0:	8b 45 f4             	mov    -0xc(%ebp),%eax
  104af3:	0f 22 d8             	mov    %eax,%cr3
	}
}
  104af6:	c9                   	leave  
  104af7:	c3                   	ret    

00104af8 <pmap_copy>:
// Returns true if successfull, false if not enough memory for copy.
//
int
pmap_copy(pde_t *spdir, uint32_t sva, pde_t *dpdir, uint32_t dva,
		size_t size)
{
  104af8:	55                   	push   %ebp
  104af9:	89 e5                	mov    %esp,%ebp
  104afb:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  104afe:	8b 45 0c             	mov    0xc(%ebp),%eax
  104b01:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104b06:	85 c0                	test   %eax,%eax
  104b08:	74 24                	je     104b2e <pmap_copy+0x36>
  104b0a:	c7 44 24 0c 06 94 10 	movl   $0x109406,0xc(%esp)
  104b11:	00 
  104b12:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104b19:	00 
  104b1a:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
  104b21:	00 
  104b22:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104b29:	e8 8a b9 ff ff       	call   1004b8 <debug_panic>
	assert(PTOFF(dva) == 0);
  104b2e:	8b 45 14             	mov    0x14(%ebp),%eax
  104b31:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104b36:	85 c0                	test   %eax,%eax
  104b38:	74 24                	je     104b5e <pmap_copy+0x66>
  104b3a:	c7 44 24 0c 16 94 10 	movl   $0x109416,0xc(%esp)
  104b41:	00 
  104b42:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104b49:	00 
  104b4a:	c7 44 24 04 fe 00 00 	movl   $0xfe,0x4(%esp)
  104b51:	00 
  104b52:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104b59:	e8 5a b9 ff ff       	call   1004b8 <debug_panic>
	assert(PTOFF(size) == 0);
  104b5e:	8b 45 18             	mov    0x18(%ebp),%eax
  104b61:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104b66:	85 c0                	test   %eax,%eax
  104b68:	74 24                	je     104b8e <pmap_copy+0x96>
  104b6a:	c7 44 24 0c 26 94 10 	movl   $0x109426,0xc(%esp)
  104b71:	00 
  104b72:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104b79:	00 
  104b7a:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  104b81:	00 
  104b82:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104b89:	e8 2a b9 ff ff       	call   1004b8 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104b8e:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104b95:	76 09                	jbe    104ba0 <pmap_copy+0xa8>
  104b97:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104b9e:	76 24                	jbe    104bc4 <pmap_copy+0xcc>
  104ba0:	c7 44 24 0c 38 94 10 	movl   $0x109438,0xc(%esp)
  104ba7:	00 
  104ba8:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104baf:	00 
  104bb0:	c7 44 24 04 00 01 00 	movl   $0x100,0x4(%esp)
  104bb7:	00 
  104bb8:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104bbf:	e8 f4 b8 ff ff       	call   1004b8 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104bc4:	81 7d 14 ff ff ff 3f 	cmpl   $0x3fffffff,0x14(%ebp)
  104bcb:	76 09                	jbe    104bd6 <pmap_copy+0xde>
  104bcd:	81 7d 14 ff ff ff ef 	cmpl   $0xefffffff,0x14(%ebp)
  104bd4:	76 24                	jbe    104bfa <pmap_copy+0x102>
  104bd6:	c7 44 24 0c 5c 94 10 	movl   $0x10945c,0xc(%esp)
  104bdd:	00 
  104bde:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104be5:	00 
  104be6:	c7 44 24 04 01 01 00 	movl   $0x101,0x4(%esp)
  104bed:	00 
  104bee:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104bf5:	e8 be b8 ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - sva);
  104bfa:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104bff:	2b 45 0c             	sub    0xc(%ebp),%eax
  104c02:	3b 45 18             	cmp    0x18(%ebp),%eax
  104c05:	73 24                	jae    104c2b <pmap_copy+0x133>
  104c07:	c7 44 24 0c 80 94 10 	movl   $0x109480,0xc(%esp)
  104c0e:	00 
  104c0f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104c16:	00 
  104c17:	c7 44 24 04 02 01 00 	movl   $0x102,0x4(%esp)
  104c1e:	00 
  104c1f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104c26:	e8 8d b8 ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - dva);
  104c2b:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104c30:	2b 45 14             	sub    0x14(%ebp),%eax
  104c33:	3b 45 18             	cmp    0x18(%ebp),%eax
  104c36:	73 24                	jae    104c5c <pmap_copy+0x164>
  104c38:	c7 44 24 0c 98 94 10 	movl   $0x109498,0xc(%esp)
  104c3f:	00 
  104c40:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104c47:	00 
  104c48:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
  104c4f:	00 
  104c50:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104c57:	e8 5c b8 ff ff       	call   1004b8 <debug_panic>

	panic("pmap_copy() not implemented");
  104c5c:	c7 44 24 08 b0 94 10 	movl   $0x1094b0,0x8(%esp)
  104c63:	00 
  104c64:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
  104c6b:	00 
  104c6c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104c73:	e8 40 b8 ff ff       	call   1004b8 <debug_panic>

00104c78 <pmap_pagefault>:
// If the fault wasn't due to the kernel's copy on write optimization,
// however, this function just returns so the trap gets blamed on the user.
//
void
pmap_pagefault(trapframe *tf)
{
  104c78:	55                   	push   %ebp
  104c79:	89 e5                	mov    %esp,%ebp
  104c7b:	83 ec 10             	sub    $0x10,%esp

static gcc_inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
  104c7e:	0f 20 d0             	mov    %cr2,%eax
  104c81:	89 45 fc             	mov    %eax,-0x4(%ebp)
	return val;
  104c84:	8b 45 fc             	mov    -0x4(%ebp),%eax
	// Read processor's CR2 register to find the faulting linear address.
	uint32_t fva = rcr2();
  104c87:	89 45 f8             	mov    %eax,-0x8(%ebp)
	//cprintf("pmap_pagefault fva %x eip %x\n", fva, tf->eip);

	// Fill in the rest of this code.
}
  104c8a:	c9                   	leave  
  104c8b:	c3                   	ret    

00104c8c <pmap_mergepage>:
// print a warning to the console and remove the page from the destination.
// If the destination page is read-shared, be sure to copy it before modifying!
//
void
pmap_mergepage(pte_t *rpte, pte_t *spte, pte_t *dpte, uint32_t dva)
{
  104c8c:	55                   	push   %ebp
  104c8d:	89 e5                	mov    %esp,%ebp
  104c8f:	83 ec 18             	sub    $0x18,%esp
	panic("pmap_mergepage() not implemented");
  104c92:	c7 44 24 08 cc 94 10 	movl   $0x1094cc,0x8(%esp)
  104c99:	00 
  104c9a:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
  104ca1:	00 
  104ca2:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104ca9:	e8 0a b8 ff ff       	call   1004b8 <debug_panic>

00104cae <pmap_merge>:
// and a source address space spdir into a destination address space dpdir.
//
int
pmap_merge(pde_t *rpdir, pde_t *spdir, uint32_t sva,
		pde_t *dpdir, uint32_t dva, size_t size)
{
  104cae:	55                   	push   %ebp
  104caf:	89 e5                	mov    %esp,%ebp
  104cb1:	83 ec 18             	sub    $0x18,%esp
	assert(PTOFF(sva) == 0);	// must be 4MB-aligned
  104cb4:	8b 45 10             	mov    0x10(%ebp),%eax
  104cb7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104cbc:	85 c0                	test   %eax,%eax
  104cbe:	74 24                	je     104ce4 <pmap_merge+0x36>
  104cc0:	c7 44 24 0c 06 94 10 	movl   $0x109406,0xc(%esp)
  104cc7:	00 
  104cc8:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104ccf:	00 
  104cd0:	c7 44 24 04 2e 01 00 	movl   $0x12e,0x4(%esp)
  104cd7:	00 
  104cd8:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104cdf:	e8 d4 b7 ff ff       	call   1004b8 <debug_panic>
	assert(PTOFF(dva) == 0);
  104ce4:	8b 45 18             	mov    0x18(%ebp),%eax
  104ce7:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104cec:	85 c0                	test   %eax,%eax
  104cee:	74 24                	je     104d14 <pmap_merge+0x66>
  104cf0:	c7 44 24 0c 16 94 10 	movl   $0x109416,0xc(%esp)
  104cf7:	00 
  104cf8:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104cff:	00 
  104d00:	c7 44 24 04 2f 01 00 	movl   $0x12f,0x4(%esp)
  104d07:	00 
  104d08:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104d0f:	e8 a4 b7 ff ff       	call   1004b8 <debug_panic>
	assert(PTOFF(size) == 0);
  104d14:	8b 45 1c             	mov    0x1c(%ebp),%eax
  104d17:	25 ff ff 3f 00       	and    $0x3fffff,%eax
  104d1c:	85 c0                	test   %eax,%eax
  104d1e:	74 24                	je     104d44 <pmap_merge+0x96>
  104d20:	c7 44 24 0c 26 94 10 	movl   $0x109426,0xc(%esp)
  104d27:	00 
  104d28:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104d2f:	00 
  104d30:	c7 44 24 04 30 01 00 	movl   $0x130,0x4(%esp)
  104d37:	00 
  104d38:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104d3f:	e8 74 b7 ff ff       	call   1004b8 <debug_panic>
	assert(sva >= VM_USERLO && sva < VM_USERHI);
  104d44:	81 7d 10 ff ff ff 3f 	cmpl   $0x3fffffff,0x10(%ebp)
  104d4b:	76 09                	jbe    104d56 <pmap_merge+0xa8>
  104d4d:	81 7d 10 ff ff ff ef 	cmpl   $0xefffffff,0x10(%ebp)
  104d54:	76 24                	jbe    104d7a <pmap_merge+0xcc>
  104d56:	c7 44 24 0c 38 94 10 	movl   $0x109438,0xc(%esp)
  104d5d:	00 
  104d5e:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104d65:	00 
  104d66:	c7 44 24 04 31 01 00 	movl   $0x131,0x4(%esp)
  104d6d:	00 
  104d6e:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104d75:	e8 3e b7 ff ff       	call   1004b8 <debug_panic>
	assert(dva >= VM_USERLO && dva < VM_USERHI);
  104d7a:	81 7d 18 ff ff ff 3f 	cmpl   $0x3fffffff,0x18(%ebp)
  104d81:	76 09                	jbe    104d8c <pmap_merge+0xde>
  104d83:	81 7d 18 ff ff ff ef 	cmpl   $0xefffffff,0x18(%ebp)
  104d8a:	76 24                	jbe    104db0 <pmap_merge+0x102>
  104d8c:	c7 44 24 0c 5c 94 10 	movl   $0x10945c,0xc(%esp)
  104d93:	00 
  104d94:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104d9b:	00 
  104d9c:	c7 44 24 04 32 01 00 	movl   $0x132,0x4(%esp)
  104da3:	00 
  104da4:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104dab:	e8 08 b7 ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - sva);
  104db0:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104db5:	2b 45 10             	sub    0x10(%ebp),%eax
  104db8:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  104dbb:	73 24                	jae    104de1 <pmap_merge+0x133>
  104dbd:	c7 44 24 0c 80 94 10 	movl   $0x109480,0xc(%esp)
  104dc4:	00 
  104dc5:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104dcc:	00 
  104dcd:	c7 44 24 04 33 01 00 	movl   $0x133,0x4(%esp)
  104dd4:	00 
  104dd5:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104ddc:	e8 d7 b6 ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - dva);
  104de1:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104de6:	2b 45 18             	sub    0x18(%ebp),%eax
  104de9:	3b 45 1c             	cmp    0x1c(%ebp),%eax
  104dec:	73 24                	jae    104e12 <pmap_merge+0x164>
  104dee:	c7 44 24 0c 98 94 10 	movl   $0x109498,0xc(%esp)
  104df5:	00 
  104df6:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104dfd:	00 
  104dfe:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
  104e05:	00 
  104e06:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104e0d:	e8 a6 b6 ff ff       	call   1004b8 <debug_panic>

	panic("pmap_merge() not implemented");
  104e12:	c7 44 24 08 ed 94 10 	movl   $0x1094ed,0x8(%esp)
  104e19:	00 
  104e1a:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
  104e21:	00 
  104e22:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104e29:	e8 8a b6 ff ff       	call   1004b8 <debug_panic>

00104e2e <pmap_setperm>:
// If the user gives SYS_WRITE permission to a PTE_ZERO mapping,
// the page fault handler copies the zero page when the first write occurs.
//
int
pmap_setperm(pde_t *pdir, uint32_t va, uint32_t size, int perm)
{
  104e2e:	55                   	push   %ebp
  104e2f:	89 e5                	mov    %esp,%ebp
  104e31:	83 ec 18             	sub    $0x18,%esp
	assert(PGOFF(va) == 0);
  104e34:	8b 45 0c             	mov    0xc(%ebp),%eax
  104e37:	25 ff 0f 00 00       	and    $0xfff,%eax
  104e3c:	85 c0                	test   %eax,%eax
  104e3e:	74 24                	je     104e64 <pmap_setperm+0x36>
  104e40:	c7 44 24 0c 0a 95 10 	movl   $0x10950a,0xc(%esp)
  104e47:	00 
  104e48:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104e4f:	00 
  104e50:	c7 44 24 04 44 01 00 	movl   $0x144,0x4(%esp)
  104e57:	00 
  104e58:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104e5f:	e8 54 b6 ff ff       	call   1004b8 <debug_panic>
	assert(PGOFF(size) == 0);
  104e64:	8b 45 10             	mov    0x10(%ebp),%eax
  104e67:	25 ff 0f 00 00       	and    $0xfff,%eax
  104e6c:	85 c0                	test   %eax,%eax
  104e6e:	74 24                	je     104e94 <pmap_setperm+0x66>
  104e70:	c7 44 24 0c de 93 10 	movl   $0x1093de,0xc(%esp)
  104e77:	00 
  104e78:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104e7f:	00 
  104e80:	c7 44 24 04 45 01 00 	movl   $0x145,0x4(%esp)
  104e87:	00 
  104e88:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104e8f:	e8 24 b6 ff ff       	call   1004b8 <debug_panic>
	assert(va >= VM_USERLO && va < VM_USERHI);
  104e94:	81 7d 0c ff ff ff 3f 	cmpl   $0x3fffffff,0xc(%ebp)
  104e9b:	76 09                	jbe    104ea6 <pmap_setperm+0x78>
  104e9d:	81 7d 0c ff ff ff ef 	cmpl   $0xefffffff,0xc(%ebp)
  104ea4:	76 24                	jbe    104eca <pmap_setperm+0x9c>
  104ea6:	c7 44 24 0c bc 93 10 	movl   $0x1093bc,0xc(%esp)
  104ead:	00 
  104eae:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104eb5:	00 
  104eb6:	c7 44 24 04 46 01 00 	movl   $0x146,0x4(%esp)
  104ebd:	00 
  104ebe:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104ec5:	e8 ee b5 ff ff       	call   1004b8 <debug_panic>
	assert(size <= VM_USERHI - va);
  104eca:	b8 00 00 00 f0       	mov    $0xf0000000,%eax
  104ecf:	2b 45 0c             	sub    0xc(%ebp),%eax
  104ed2:	3b 45 10             	cmp    0x10(%ebp),%eax
  104ed5:	73 24                	jae    104efb <pmap_setperm+0xcd>
  104ed7:	c7 44 24 0c ef 93 10 	movl   $0x1093ef,0xc(%esp)
  104ede:	00 
  104edf:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104ee6:	00 
  104ee7:	c7 44 24 04 47 01 00 	movl   $0x147,0x4(%esp)
  104eee:	00 
  104eef:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104ef6:	e8 bd b5 ff ff       	call   1004b8 <debug_panic>
	assert((perm & ~(SYS_RW)) == 0);
  104efb:	8b 45 14             	mov    0x14(%ebp),%eax
  104efe:	80 e4 f9             	and    $0xf9,%ah
  104f01:	85 c0                	test   %eax,%eax
  104f03:	74 24                	je     104f29 <pmap_setperm+0xfb>
  104f05:	c7 44 24 0c 19 95 10 	movl   $0x109519,0xc(%esp)
  104f0c:	00 
  104f0d:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  104f14:	00 
  104f15:	c7 44 24 04 48 01 00 	movl   $0x148,0x4(%esp)
  104f1c:	00 
  104f1d:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104f24:	e8 8f b5 ff ff       	call   1004b8 <debug_panic>

	panic("pmap_merge() not implemented");
  104f29:	c7 44 24 08 ed 94 10 	movl   $0x1094ed,0x8(%esp)
  104f30:	00 
  104f31:	c7 44 24 04 4a 01 00 	movl   $0x14a,0x4(%esp)
  104f38:	00 
  104f39:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  104f40:	e8 73 b5 ff ff       	call   1004b8 <debug_panic>

00104f45 <va2pa>:
// this functionality for us!  We define our own version to help check
// the pmap_check() function; it shouldn't be used elsewhere.
//
static uint32_t
va2pa(pde_t *pdir, uintptr_t va)
{
  104f45:	55                   	push   %ebp
  104f46:	89 e5                	mov    %esp,%ebp
  104f48:	83 ec 10             	sub    $0x10,%esp
	pdir = &pdir[PDX(va)];
  104f4b:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f4e:	c1 e8 16             	shr    $0x16,%eax
  104f51:	c1 e0 02             	shl    $0x2,%eax
  104f54:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pdir & PTE_P))
  104f57:	8b 45 08             	mov    0x8(%ebp),%eax
  104f5a:	8b 00                	mov    (%eax),%eax
  104f5c:	83 e0 01             	and    $0x1,%eax
  104f5f:	85 c0                	test   %eax,%eax
  104f61:	75 07                	jne    104f6a <va2pa+0x25>
		return ~0;
  104f63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104f68:	eb 46                	jmp    104fb0 <va2pa+0x6b>
	pte_t *ptab = mem_ptr(PGADDR(*pdir));
  104f6a:	8b 45 08             	mov    0x8(%ebp),%eax
  104f6d:	8b 00                	mov    (%eax),%eax
  104f6f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  104f74:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(ptab[PTX(va)] & PTE_P))
  104f77:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f7a:	c1 e8 0c             	shr    $0xc,%eax
  104f7d:	25 ff 03 00 00       	and    $0x3ff,%eax
  104f82:	c1 e0 02             	shl    $0x2,%eax
  104f85:	03 45 fc             	add    -0x4(%ebp),%eax
  104f88:	8b 00                	mov    (%eax),%eax
  104f8a:	83 e0 01             	and    $0x1,%eax
  104f8d:	85 c0                	test   %eax,%eax
  104f8f:	75 07                	jne    104f98 <va2pa+0x53>
		return ~0;
  104f91:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  104f96:	eb 18                	jmp    104fb0 <va2pa+0x6b>
	return PGADDR(ptab[PTX(va)]);
  104f98:	8b 45 0c             	mov    0xc(%ebp),%eax
  104f9b:	c1 e8 0c             	shr    $0xc,%eax
  104f9e:	25 ff 03 00 00       	and    $0x3ff,%eax
  104fa3:	c1 e0 02             	shl    $0x2,%eax
  104fa6:	03 45 fc             	add    -0x4(%ebp),%eax
  104fa9:	8b 00                	mov    (%eax),%eax
  104fab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
}
  104fb0:	c9                   	leave  
  104fb1:	c3                   	ret    

00104fb2 <pmap_check>:

// check pmap_insert, pmap_remove, &c
void
pmap_check(void)
{
  104fb2:	55                   	push   %ebp
  104fb3:	89 e5                	mov    %esp,%ebp
  104fb5:	53                   	push   %ebx
  104fb6:	83 ec 44             	sub    $0x44,%esp
	pageinfo *fl;
	pte_t *ptep, *ptep1;
	int i;

	// should be able to allocate three pages
	pi0 = pi1 = pi2 = 0;
  104fb9:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
  104fc0:	8b 45 dc             	mov    -0x24(%ebp),%eax
  104fc3:	89 45 d8             	mov    %eax,-0x28(%ebp)
  104fc6:	8b 45 d8             	mov    -0x28(%ebp),%eax
  104fc9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi0 = mem_alloc();
  104fcc:	e8 88 bc ff ff       	call   100c59 <mem_alloc>
  104fd1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	pi1 = mem_alloc();
  104fd4:	e8 80 bc ff ff       	call   100c59 <mem_alloc>
  104fd9:	89 45 d8             	mov    %eax,-0x28(%ebp)
	pi2 = mem_alloc();
  104fdc:	e8 78 bc ff ff       	call   100c59 <mem_alloc>
  104fe1:	89 45 dc             	mov    %eax,-0x24(%ebp)
	pi3 = mem_alloc();
  104fe4:	e8 70 bc ff ff       	call   100c59 <mem_alloc>
  104fe9:	89 45 e0             	mov    %eax,-0x20(%ebp)

	assert(pi0);
  104fec:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  104ff0:	75 24                	jne    105016 <pmap_check+0x64>
  104ff2:	c7 44 24 0c 31 95 10 	movl   $0x109531,0xc(%esp)
  104ff9:	00 
  104ffa:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105001:	00 
  105002:	c7 44 24 04 71 01 00 	movl   $0x171,0x4(%esp)
  105009:	00 
  10500a:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105011:	e8 a2 b4 ff ff       	call   1004b8 <debug_panic>
	assert(pi1 && pi1 != pi0);
  105016:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
  10501a:	74 08                	je     105024 <pmap_check+0x72>
  10501c:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10501f:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  105022:	75 24                	jne    105048 <pmap_check+0x96>
  105024:	c7 44 24 0c 35 95 10 	movl   $0x109535,0xc(%esp)
  10502b:	00 
  10502c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105033:	00 
  105034:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
  10503b:	00 
  10503c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105043:	e8 70 b4 ff ff       	call   1004b8 <debug_panic>
	assert(pi2 && pi2 != pi1 && pi2 != pi0);
  105048:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  10504c:	74 10                	je     10505e <pmap_check+0xac>
  10504e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105051:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105054:	74 08                	je     10505e <pmap_check+0xac>
  105056:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105059:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  10505c:	75 24                	jne    105082 <pmap_check+0xd0>
  10505e:	c7 44 24 0c 48 95 10 	movl   $0x109548,0xc(%esp)
  105065:	00 
  105066:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10506d:	00 
  10506e:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
  105075:	00 
  105076:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10507d:	e8 36 b4 ff ff       	call   1004b8 <debug_panic>

	// temporarily steal the rest of the free pages
	fl = mem_freelist;
  105082:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  105087:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	mem_freelist = NULL;
  10508a:	c7 05 18 ed 11 00 00 	movl   $0x0,0x11ed18
  105091:	00 00 00 

	// should be no free memory
	assert(mem_alloc() == NULL);
  105094:	e8 c0 bb ff ff       	call   100c59 <mem_alloc>
  105099:	85 c0                	test   %eax,%eax
  10509b:	74 24                	je     1050c1 <pmap_check+0x10f>
  10509d:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  1050a4:	00 
  1050a5:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1050ac:	00 
  1050ad:	c7 44 24 04 7a 01 00 	movl   $0x17a,0x4(%esp)
  1050b4:	00 
  1050b5:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1050bc:	e8 f7 b3 ff ff       	call   1004b8 <debug_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) == NULL);
  1050c1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1050c8:	00 
  1050c9:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  1050d0:	40 
  1050d1:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1050d4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1050d8:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1050df:	e8 1e f9 ff ff       	call   104a02 <pmap_insert>
  1050e4:	85 c0                	test   %eax,%eax
  1050e6:	74 24                	je     10510c <pmap_check+0x15a>
  1050e8:	c7 44 24 0c 7c 95 10 	movl   $0x10957c,0xc(%esp)
  1050ef:	00 
  1050f0:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1050f7:	00 
  1050f8:	c7 44 24 04 7d 01 00 	movl   $0x17d,0x4(%esp)
  1050ff:	00 
  105100:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105107:	e8 ac b3 ff ff       	call   1004b8 <debug_panic>

	// free pi0 and try again: pi0 should be used for page table
	mem_free(pi0);
  10510c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10510f:	89 04 24             	mov    %eax,(%esp)
  105112:	e8 93 bb ff ff       	call   100caa <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0) != NULL);
  105117:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  10511e:	00 
  10511f:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105126:	40 
  105127:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10512a:	89 44 24 04          	mov    %eax,0x4(%esp)
  10512e:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105135:	e8 c8 f8 ff ff       	call   104a02 <pmap_insert>
  10513a:	85 c0                	test   %eax,%eax
  10513c:	75 24                	jne    105162 <pmap_check+0x1b0>
  10513e:	c7 44 24 0c b4 95 10 	movl   $0x1095b4,0xc(%esp)
  105145:	00 
  105146:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10514d:	00 
  10514e:	c7 44 24 04 81 01 00 	movl   $0x181,0x4(%esp)
  105155:	00 
  105156:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10515d:	e8 56 b3 ff ff       	call   1004b8 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi0));
  105162:	a1 00 04 12 00       	mov    0x120400,%eax
  105167:	89 c1                	mov    %eax,%ecx
  105169:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  10516f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  105172:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  105177:	89 d3                	mov    %edx,%ebx
  105179:	29 c3                	sub    %eax,%ebx
  10517b:	89 d8                	mov    %ebx,%eax
  10517d:	c1 f8 03             	sar    $0x3,%eax
  105180:	c1 e0 0c             	shl    $0xc,%eax
  105183:	39 c1                	cmp    %eax,%ecx
  105185:	74 24                	je     1051ab <pmap_check+0x1f9>
  105187:	c7 44 24 0c ec 95 10 	movl   $0x1095ec,0xc(%esp)
  10518e:	00 
  10518f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105196:	00 
  105197:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
  10519e:	00 
  10519f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1051a6:	e8 0d b3 ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO) == mem_pi2phys(pi1));
  1051ab:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1051b2:	40 
  1051b3:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1051ba:	e8 86 fd ff ff       	call   104f45 <va2pa>
  1051bf:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1051c2:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  1051c8:	89 cb                	mov    %ecx,%ebx
  1051ca:	29 d3                	sub    %edx,%ebx
  1051cc:	89 da                	mov    %ebx,%edx
  1051ce:	c1 fa 03             	sar    $0x3,%edx
  1051d1:	c1 e2 0c             	shl    $0xc,%edx
  1051d4:	39 d0                	cmp    %edx,%eax
  1051d6:	74 24                	je     1051fc <pmap_check+0x24a>
  1051d8:	c7 44 24 0c 28 96 10 	movl   $0x109628,0xc(%esp)
  1051df:	00 
  1051e0:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1051e7:	00 
  1051e8:	c7 44 24 04 83 01 00 	movl   $0x183,0x4(%esp)
  1051ef:	00 
  1051f0:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1051f7:	e8 bc b2 ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 1);
  1051fc:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1051ff:	8b 40 04             	mov    0x4(%eax),%eax
  105202:	83 f8 01             	cmp    $0x1,%eax
  105205:	74 24                	je     10522b <pmap_check+0x279>
  105207:	c7 44 24 0c 5c 96 10 	movl   $0x10965c,0xc(%esp)
  10520e:	00 
  10520f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105216:	00 
  105217:	c7 44 24 04 84 01 00 	movl   $0x184,0x4(%esp)
  10521e:	00 
  10521f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105226:	e8 8d b2 ff ff       	call   1004b8 <debug_panic>
	assert(pi0->refcount == 1);
  10522b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10522e:	8b 40 04             	mov    0x4(%eax),%eax
  105231:	83 f8 01             	cmp    $0x1,%eax
  105234:	74 24                	je     10525a <pmap_check+0x2a8>
  105236:	c7 44 24 0c 6f 96 10 	movl   $0x10966f,0xc(%esp)
  10523d:	00 
  10523e:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105245:	00 
  105246:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
  10524d:	00 
  10524e:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105255:	e8 5e b2 ff ff       	call   1004b8 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because pi0 is already allocated for page table
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  10525a:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105261:	00 
  105262:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  105269:	40 
  10526a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10526d:	89 44 24 04          	mov    %eax,0x4(%esp)
  105271:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105278:	e8 85 f7 ff ff       	call   104a02 <pmap_insert>
  10527d:	85 c0                	test   %eax,%eax
  10527f:	75 24                	jne    1052a5 <pmap_check+0x2f3>
  105281:	c7 44 24 0c 84 96 10 	movl   $0x109684,0xc(%esp)
  105288:	00 
  105289:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105290:	00 
  105291:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
  105298:	00 
  105299:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1052a0:	e8 13 b2 ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1052a5:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1052ac:	40 
  1052ad:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1052b4:	e8 8c fc ff ff       	call   104f45 <va2pa>
  1052b9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1052bc:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  1052c2:	89 cb                	mov    %ecx,%ebx
  1052c4:	29 d3                	sub    %edx,%ebx
  1052c6:	89 da                	mov    %ebx,%edx
  1052c8:	c1 fa 03             	sar    $0x3,%edx
  1052cb:	c1 e2 0c             	shl    $0xc,%edx
  1052ce:	39 d0                	cmp    %edx,%eax
  1052d0:	74 24                	je     1052f6 <pmap_check+0x344>
  1052d2:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  1052d9:	00 
  1052da:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1052e1:	00 
  1052e2:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
  1052e9:	00 
  1052ea:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1052f1:	e8 c2 b1 ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 1);
  1052f6:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1052f9:	8b 40 04             	mov    0x4(%eax),%eax
  1052fc:	83 f8 01             	cmp    $0x1,%eax
  1052ff:	74 24                	je     105325 <pmap_check+0x373>
  105301:	c7 44 24 0c f9 96 10 	movl   $0x1096f9,0xc(%esp)
  105308:	00 
  105309:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105310:	00 
  105311:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
  105318:	00 
  105319:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105320:	e8 93 b1 ff ff       	call   1004b8 <debug_panic>

	// should be no free memory
	assert(mem_alloc() == NULL);
  105325:	e8 2f b9 ff ff       	call   100c59 <mem_alloc>
  10532a:	85 c0                	test   %eax,%eax
  10532c:	74 24                	je     105352 <pmap_check+0x3a0>
  10532e:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  105335:	00 
  105336:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10533d:	00 
  10533e:	c7 44 24 04 8e 01 00 	movl   $0x18e,0x4(%esp)
  105345:	00 
  105346:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10534d:	e8 66 b1 ff ff       	call   1004b8 <debug_panic>

	// should be able to map pi2 at VM_USERLO+PAGESIZE
	// because it's already there
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, 0));
  105352:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105359:	00 
  10535a:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  105361:	40 
  105362:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105365:	89 44 24 04          	mov    %eax,0x4(%esp)
  105369:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105370:	e8 8d f6 ff ff       	call   104a02 <pmap_insert>
  105375:	85 c0                	test   %eax,%eax
  105377:	75 24                	jne    10539d <pmap_check+0x3eb>
  105379:	c7 44 24 0c 84 96 10 	movl   $0x109684,0xc(%esp)
  105380:	00 
  105381:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105388:	00 
  105389:	c7 44 24 04 92 01 00 	movl   $0x192,0x4(%esp)
  105390:	00 
  105391:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105398:	e8 1b b1 ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  10539d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1053a4:	40 
  1053a5:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1053ac:	e8 94 fb ff ff       	call   104f45 <va2pa>
  1053b1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  1053b4:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  1053ba:	89 cb                	mov    %ecx,%ebx
  1053bc:	29 d3                	sub    %edx,%ebx
  1053be:	89 da                	mov    %ebx,%edx
  1053c0:	c1 fa 03             	sar    $0x3,%edx
  1053c3:	c1 e2 0c             	shl    $0xc,%edx
  1053c6:	39 d0                	cmp    %edx,%eax
  1053c8:	74 24                	je     1053ee <pmap_check+0x43c>
  1053ca:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  1053d1:	00 
  1053d2:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1053d9:	00 
  1053da:	c7 44 24 04 93 01 00 	movl   $0x193,0x4(%esp)
  1053e1:	00 
  1053e2:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1053e9:	e8 ca b0 ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 1);
  1053ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1053f1:	8b 40 04             	mov    0x4(%eax),%eax
  1053f4:	83 f8 01             	cmp    $0x1,%eax
  1053f7:	74 24                	je     10541d <pmap_check+0x46b>
  1053f9:	c7 44 24 0c f9 96 10 	movl   $0x1096f9,0xc(%esp)
  105400:	00 
  105401:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105408:	00 
  105409:	c7 44 24 04 94 01 00 	movl   $0x194,0x4(%esp)
  105410:	00 
  105411:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105418:	e8 9b b0 ff ff       	call   1004b8 <debug_panic>

	// pi2 should NOT be on the free list
	// could hapien in ref counts are handled slopiily in pmap_insert
	assert(mem_alloc() == NULL);
  10541d:	e8 37 b8 ff ff       	call   100c59 <mem_alloc>
  105422:	85 c0                	test   %eax,%eax
  105424:	74 24                	je     10544a <pmap_check+0x498>
  105426:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  10542d:	00 
  10542e:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105435:	00 
  105436:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
  10543d:	00 
  10543e:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105445:	e8 6e b0 ff ff       	call   1004b8 <debug_panic>

	// check that pmap_walk returns a pointer to the pte
	ptep = mem_ptr(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PAGESIZE)]));
  10544a:	a1 00 04 12 00       	mov    0x120400,%eax
  10544f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  105454:	89 45 e8             	mov    %eax,-0x18(%ebp)
	assert(pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0)
  105457:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  10545e:	00 
  10545f:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105466:	40 
  105467:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10546e:	e8 4c f5 ff ff       	call   1049bf <pmap_walk>
  105473:	8b 55 e8             	mov    -0x18(%ebp),%edx
  105476:	83 c2 04             	add    $0x4,%edx
  105479:	39 d0                	cmp    %edx,%eax
  10547b:	74 24                	je     1054a1 <pmap_check+0x4ef>
  10547d:	c7 44 24 0c 0c 97 10 	movl   $0x10970c,0xc(%esp)
  105484:	00 
  105485:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10548c:	00 
  10548d:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
  105494:	00 
  105495:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10549c:	e8 17 b0 ff ff       	call   1004b8 <debug_panic>
		== ptep+PTX(VM_USERLO+PAGESIZE));

	// should be able to change permissions too.
	assert(pmap_insert(pmap_bootpdir, pi2, VM_USERLO+PAGESIZE, PTE_U));
  1054a1:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  1054a8:	00 
  1054a9:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  1054b0:	40 
  1054b1:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1054b4:	89 44 24 04          	mov    %eax,0x4(%esp)
  1054b8:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1054bf:	e8 3e f5 ff ff       	call   104a02 <pmap_insert>
  1054c4:	85 c0                	test   %eax,%eax
  1054c6:	75 24                	jne    1054ec <pmap_check+0x53a>
  1054c8:	c7 44 24 0c 5c 97 10 	movl   $0x10975c,0xc(%esp)
  1054cf:	00 
  1054d0:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1054d7:	00 
  1054d8:	c7 44 24 04 a0 01 00 	movl   $0x1a0,0x4(%esp)
  1054df:	00 
  1054e0:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1054e7:	e8 cc af ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi2));
  1054ec:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  1054f3:	40 
  1054f4:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1054fb:	e8 45 fa ff ff       	call   104f45 <va2pa>
  105500:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  105503:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  105509:	89 cb                	mov    %ecx,%ebx
  10550b:	29 d3                	sub    %edx,%ebx
  10550d:	89 da                	mov    %ebx,%edx
  10550f:	c1 fa 03             	sar    $0x3,%edx
  105512:	c1 e2 0c             	shl    $0xc,%edx
  105515:	39 d0                	cmp    %edx,%eax
  105517:	74 24                	je     10553d <pmap_check+0x58b>
  105519:	c7 44 24 0c bc 96 10 	movl   $0x1096bc,0xc(%esp)
  105520:	00 
  105521:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105528:	00 
  105529:	c7 44 24 04 a1 01 00 	movl   $0x1a1,0x4(%esp)
  105530:	00 
  105531:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105538:	e8 7b af ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 1);
  10553d:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105540:	8b 40 04             	mov    0x4(%eax),%eax
  105543:	83 f8 01             	cmp    $0x1,%eax
  105546:	74 24                	je     10556c <pmap_check+0x5ba>
  105548:	c7 44 24 0c f9 96 10 	movl   $0x1096f9,0xc(%esp)
  10554f:	00 
  105550:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105557:	00 
  105558:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
  10555f:	00 
  105560:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105567:	e8 4c af ff ff       	call   1004b8 <debug_panic>
	assert(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U);
  10556c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105573:	00 
  105574:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10557b:	40 
  10557c:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105583:	e8 37 f4 ff ff       	call   1049bf <pmap_walk>
  105588:	8b 00                	mov    (%eax),%eax
  10558a:	83 e0 04             	and    $0x4,%eax
  10558d:	85 c0                	test   %eax,%eax
  10558f:	75 24                	jne    1055b5 <pmap_check+0x603>
  105591:	c7 44 24 0c 98 97 10 	movl   $0x109798,0xc(%esp)
  105598:	00 
  105599:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1055a0:	00 
  1055a1:	c7 44 24 04 a3 01 00 	movl   $0x1a3,0x4(%esp)
  1055a8:	00 
  1055a9:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1055b0:	e8 03 af ff ff       	call   1004b8 <debug_panic>
	assert(pmap_bootpdir[PDX(VM_USERLO)] & PTE_U);
  1055b5:	a1 00 04 12 00       	mov    0x120400,%eax
  1055ba:	83 e0 04             	and    $0x4,%eax
  1055bd:	85 c0                	test   %eax,%eax
  1055bf:	75 24                	jne    1055e5 <pmap_check+0x633>
  1055c1:	c7 44 24 0c d4 97 10 	movl   $0x1097d4,0xc(%esp)
  1055c8:	00 
  1055c9:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1055d0:	00 
  1055d1:	c7 44 24 04 a4 01 00 	movl   $0x1a4,0x4(%esp)
  1055d8:	00 
  1055d9:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1055e0:	e8 d3 ae ff ff       	call   1004b8 <debug_panic>
	
	// should not be able to map at VM_USERLO+PTSIZE
	// because we need a free page for a page table
	assert(pmap_insert(pmap_bootpdir, pi0, VM_USERLO+PTSIZE, 0) == NULL);
  1055e5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1055ec:	00 
  1055ed:	c7 44 24 08 00 00 40 	movl   $0x40400000,0x8(%esp)
  1055f4:	40 
  1055f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1055f8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1055fc:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105603:	e8 fa f3 ff ff       	call   104a02 <pmap_insert>
  105608:	85 c0                	test   %eax,%eax
  10560a:	74 24                	je     105630 <pmap_check+0x67e>
  10560c:	c7 44 24 0c fc 97 10 	movl   $0x1097fc,0xc(%esp)
  105613:	00 
  105614:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10561b:	00 
  10561c:	c7 44 24 04 a8 01 00 	movl   $0x1a8,0x4(%esp)
  105623:	00 
  105624:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10562b:	e8 88 ae ff ff       	call   1004b8 <debug_panic>

	// insert pi1 at VM_USERLO+PAGESIZE (replacing pi2)
	assert(pmap_insert(pmap_bootpdir, pi1, VM_USERLO+PAGESIZE, 0));
  105630:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105637:	00 
  105638:	c7 44 24 08 00 10 00 	movl   $0x40001000,0x8(%esp)
  10563f:	40 
  105640:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105643:	89 44 24 04          	mov    %eax,0x4(%esp)
  105647:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10564e:	e8 af f3 ff ff       	call   104a02 <pmap_insert>
  105653:	85 c0                	test   %eax,%eax
  105655:	75 24                	jne    10567b <pmap_check+0x6c9>
  105657:	c7 44 24 0c 3c 98 10 	movl   $0x10983c,0xc(%esp)
  10565e:	00 
  10565f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105666:	00 
  105667:	c7 44 24 04 ab 01 00 	movl   $0x1ab,0x4(%esp)
  10566e:	00 
  10566f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105676:	e8 3d ae ff ff       	call   1004b8 <debug_panic>
	assert(!(*pmap_walk(pmap_bootpdir, VM_USERLO+PAGESIZE, 0) & PTE_U));
  10567b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  105682:	00 
  105683:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10568a:	40 
  10568b:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105692:	e8 28 f3 ff ff       	call   1049bf <pmap_walk>
  105697:	8b 00                	mov    (%eax),%eax
  105699:	83 e0 04             	and    $0x4,%eax
  10569c:	85 c0                	test   %eax,%eax
  10569e:	74 24                	je     1056c4 <pmap_check+0x712>
  1056a0:	c7 44 24 0c 74 98 10 	movl   $0x109874,0xc(%esp)
  1056a7:	00 
  1056a8:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1056af:	00 
  1056b0:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
  1056b7:	00 
  1056b8:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1056bf:	e8 f4 ad ff ff       	call   1004b8 <debug_panic>

	// should have pi1 at both +0 and +PAGESIZE, pi2 nowhere, ...
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == mem_pi2phys(pi1));
  1056c4:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  1056cb:	40 
  1056cc:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1056d3:	e8 6d f8 ff ff       	call   104f45 <va2pa>
  1056d8:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  1056db:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  1056e1:	89 cb                	mov    %ecx,%ebx
  1056e3:	29 d3                	sub    %edx,%ebx
  1056e5:	89 da                	mov    %ebx,%edx
  1056e7:	c1 fa 03             	sar    $0x3,%edx
  1056ea:	c1 e2 0c             	shl    $0xc,%edx
  1056ed:	39 d0                	cmp    %edx,%eax
  1056ef:	74 24                	je     105715 <pmap_check+0x763>
  1056f1:	c7 44 24 0c b0 98 10 	movl   $0x1098b0,0xc(%esp)
  1056f8:	00 
  1056f9:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105700:	00 
  105701:	c7 44 24 04 af 01 00 	movl   $0x1af,0x4(%esp)
  105708:	00 
  105709:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105710:	e8 a3 ad ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  105715:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  10571c:	40 
  10571d:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105724:	e8 1c f8 ff ff       	call   104f45 <va2pa>
  105729:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  10572c:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  105732:	89 cb                	mov    %ecx,%ebx
  105734:	29 d3                	sub    %edx,%ebx
  105736:	89 da                	mov    %ebx,%edx
  105738:	c1 fa 03             	sar    $0x3,%edx
  10573b:	c1 e2 0c             	shl    $0xc,%edx
  10573e:	39 d0                	cmp    %edx,%eax
  105740:	74 24                	je     105766 <pmap_check+0x7b4>
  105742:	c7 44 24 0c e8 98 10 	movl   $0x1098e8,0xc(%esp)
  105749:	00 
  10574a:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105751:	00 
  105752:	c7 44 24 04 b0 01 00 	movl   $0x1b0,0x4(%esp)
  105759:	00 
  10575a:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105761:	e8 52 ad ff ff       	call   1004b8 <debug_panic>
	// ... and ref counts should reflect this
	assert(pi1->refcount == 2);
  105766:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105769:	8b 40 04             	mov    0x4(%eax),%eax
  10576c:	83 f8 02             	cmp    $0x2,%eax
  10576f:	74 24                	je     105795 <pmap_check+0x7e3>
  105771:	c7 44 24 0c 25 99 10 	movl   $0x109925,0xc(%esp)
  105778:	00 
  105779:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105780:	00 
  105781:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
  105788:	00 
  105789:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105790:	e8 23 ad ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 0);
  105795:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105798:	8b 40 04             	mov    0x4(%eax),%eax
  10579b:	85 c0                	test   %eax,%eax
  10579d:	74 24                	je     1057c3 <pmap_check+0x811>
  10579f:	c7 44 24 0c 38 99 10 	movl   $0x109938,0xc(%esp)
  1057a6:	00 
  1057a7:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1057ae:	00 
  1057af:	c7 44 24 04 b3 01 00 	movl   $0x1b3,0x4(%esp)
  1057b6:	00 
  1057b7:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1057be:	e8 f5 ac ff ff       	call   1004b8 <debug_panic>

	// pi2 should be returned by mem_alloc
	assert(mem_alloc() == pi2);
  1057c3:	e8 91 b4 ff ff       	call   100c59 <mem_alloc>
  1057c8:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  1057cb:	74 24                	je     1057f1 <pmap_check+0x83f>
  1057cd:	c7 44 24 0c 4b 99 10 	movl   $0x10994b,0xc(%esp)
  1057d4:	00 
  1057d5:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1057dc:	00 
  1057dd:	c7 44 24 04 b6 01 00 	movl   $0x1b6,0x4(%esp)
  1057e4:	00 
  1057e5:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1057ec:	e8 c7 ac ff ff       	call   1004b8 <debug_panic>

	// unmapping pi1 at VM_USERLO+0 should keep pi1 at +PAGESIZE
	pmap_remove(pmap_bootpdir, VM_USERLO+0, PAGESIZE);
  1057f1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  1057f8:	00 
  1057f9:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105800:	40 
  105801:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105808:	e8 ff f1 ff ff       	call   104a0c <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  10580d:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105814:	40 
  105815:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10581c:	e8 24 f7 ff ff       	call   104f45 <va2pa>
  105821:	83 f8 ff             	cmp    $0xffffffff,%eax
  105824:	74 24                	je     10584a <pmap_check+0x898>
  105826:	c7 44 24 0c 60 99 10 	movl   $0x109960,0xc(%esp)
  10582d:	00 
  10582e:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105835:	00 
  105836:	c7 44 24 04 ba 01 00 	movl   $0x1ba,0x4(%esp)
  10583d:	00 
  10583e:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105845:	e8 6e ac ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == mem_pi2phys(pi1));
  10584a:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105851:	40 
  105852:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105859:	e8 e7 f6 ff ff       	call   104f45 <va2pa>
  10585e:	8b 4d d8             	mov    -0x28(%ebp),%ecx
  105861:	8b 15 24 ed 11 00    	mov    0x11ed24,%edx
  105867:	89 cb                	mov    %ecx,%ebx
  105869:	29 d3                	sub    %edx,%ebx
  10586b:	89 da                	mov    %ebx,%edx
  10586d:	c1 fa 03             	sar    $0x3,%edx
  105870:	c1 e2 0c             	shl    $0xc,%edx
  105873:	39 d0                	cmp    %edx,%eax
  105875:	74 24                	je     10589b <pmap_check+0x8e9>
  105877:	c7 44 24 0c e8 98 10 	movl   $0x1098e8,0xc(%esp)
  10587e:	00 
  10587f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105886:	00 
  105887:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
  10588e:	00 
  10588f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105896:	e8 1d ac ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 1);
  10589b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10589e:	8b 40 04             	mov    0x4(%eax),%eax
  1058a1:	83 f8 01             	cmp    $0x1,%eax
  1058a4:	74 24                	je     1058ca <pmap_check+0x918>
  1058a6:	c7 44 24 0c 5c 96 10 	movl   $0x10965c,0xc(%esp)
  1058ad:	00 
  1058ae:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1058b5:	00 
  1058b6:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
  1058bd:	00 
  1058be:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1058c5:	e8 ee ab ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 0);
  1058ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1058cd:	8b 40 04             	mov    0x4(%eax),%eax
  1058d0:	85 c0                	test   %eax,%eax
  1058d2:	74 24                	je     1058f8 <pmap_check+0x946>
  1058d4:	c7 44 24 0c 38 99 10 	movl   $0x109938,0xc(%esp)
  1058db:	00 
  1058dc:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1058e3:	00 
  1058e4:	c7 44 24 04 bd 01 00 	movl   $0x1bd,0x4(%esp)
  1058eb:	00 
  1058ec:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1058f3:	e8 c0 ab ff ff       	call   1004b8 <debug_panic>
	assert(mem_alloc() == NULL);	// still should have no pages free
  1058f8:	e8 5c b3 ff ff       	call   100c59 <mem_alloc>
  1058fd:	85 c0                	test   %eax,%eax
  1058ff:	74 24                	je     105925 <pmap_check+0x973>
  105901:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  105908:	00 
  105909:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105910:	00 
  105911:	c7 44 24 04 be 01 00 	movl   $0x1be,0x4(%esp)
  105918:	00 
  105919:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105920:	e8 93 ab ff ff       	call   1004b8 <debug_panic>

	// unmapping pi1 at VM_USERLO+PAGESIZE should free it
	pmap_remove(pmap_bootpdir, VM_USERLO+PAGESIZE, PAGESIZE);
  105925:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10592c:	00 
  10592d:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105934:	40 
  105935:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10593c:	e8 cb f0 ff ff       	call   104a0c <pmap_remove>
	assert(va2pa(pmap_bootpdir, VM_USERLO+0) == ~0);
  105941:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105948:	40 
  105949:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105950:	e8 f0 f5 ff ff       	call   104f45 <va2pa>
  105955:	83 f8 ff             	cmp    $0xffffffff,%eax
  105958:	74 24                	je     10597e <pmap_check+0x9cc>
  10595a:	c7 44 24 0c 60 99 10 	movl   $0x109960,0xc(%esp)
  105961:	00 
  105962:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105969:	00 
  10596a:	c7 44 24 04 c2 01 00 	movl   $0x1c2,0x4(%esp)
  105971:	00 
  105972:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105979:	e8 3a ab ff ff       	call   1004b8 <debug_panic>
	assert(va2pa(pmap_bootpdir, VM_USERLO+PAGESIZE) == ~0);
  10597e:	c7 44 24 04 00 10 00 	movl   $0x40001000,0x4(%esp)
  105985:	40 
  105986:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10598d:	e8 b3 f5 ff ff       	call   104f45 <va2pa>
  105992:	83 f8 ff             	cmp    $0xffffffff,%eax
  105995:	74 24                	je     1059bb <pmap_check+0xa09>
  105997:	c7 44 24 0c 88 99 10 	movl   $0x109988,0xc(%esp)
  10599e:	00 
  10599f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1059a6:	00 
  1059a7:	c7 44 24 04 c3 01 00 	movl   $0x1c3,0x4(%esp)
  1059ae:	00 
  1059af:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1059b6:	e8 fd aa ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 0);
  1059bb:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1059be:	8b 40 04             	mov    0x4(%eax),%eax
  1059c1:	85 c0                	test   %eax,%eax
  1059c3:	74 24                	je     1059e9 <pmap_check+0xa37>
  1059c5:	c7 44 24 0c b7 99 10 	movl   $0x1099b7,0xc(%esp)
  1059cc:	00 
  1059cd:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1059d4:	00 
  1059d5:	c7 44 24 04 c4 01 00 	movl   $0x1c4,0x4(%esp)
  1059dc:	00 
  1059dd:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1059e4:	e8 cf aa ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 0);
  1059e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1059ec:	8b 40 04             	mov    0x4(%eax),%eax
  1059ef:	85 c0                	test   %eax,%eax
  1059f1:	74 24                	je     105a17 <pmap_check+0xa65>
  1059f3:	c7 44 24 0c 38 99 10 	movl   $0x109938,0xc(%esp)
  1059fa:	00 
  1059fb:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105a02:	00 
  105a03:	c7 44 24 04 c5 01 00 	movl   $0x1c5,0x4(%esp)
  105a0a:	00 
  105a0b:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105a12:	e8 a1 aa ff ff       	call   1004b8 <debug_panic>

	// so it should be returned by page_alloc
	assert(mem_alloc() == pi1);
  105a17:	e8 3d b2 ff ff       	call   100c59 <mem_alloc>
  105a1c:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105a1f:	74 24                	je     105a45 <pmap_check+0xa93>
  105a21:	c7 44 24 0c ca 99 10 	movl   $0x1099ca,0xc(%esp)
  105a28:	00 
  105a29:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105a30:	00 
  105a31:	c7 44 24 04 c8 01 00 	movl   $0x1c8,0x4(%esp)
  105a38:	00 
  105a39:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105a40:	e8 73 aa ff ff       	call   1004b8 <debug_panic>

	// should once again have no free memory
	assert(mem_alloc() == NULL);
  105a45:	e8 0f b2 ff ff       	call   100c59 <mem_alloc>
  105a4a:	85 c0                	test   %eax,%eax
  105a4c:	74 24                	je     105a72 <pmap_check+0xac0>
  105a4e:	c7 44 24 0c 68 95 10 	movl   $0x109568,0xc(%esp)
  105a55:	00 
  105a56:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105a5d:	00 
  105a5e:	c7 44 24 04 cb 01 00 	movl   $0x1cb,0x4(%esp)
  105a65:	00 
  105a66:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105a6d:	e8 46 aa ff ff       	call   1004b8 <debug_panic>

	// should be able to pmap_insert to change a page
	// and see the new data immediately.
	memset(mem_pi2ptr(pi1), 1, PAGESIZE);
  105a72:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105a75:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  105a7a:	89 d1                	mov    %edx,%ecx
  105a7c:	29 c1                	sub    %eax,%ecx
  105a7e:	89 c8                	mov    %ecx,%eax
  105a80:	c1 f8 03             	sar    $0x3,%eax
  105a83:	c1 e0 0c             	shl    $0xc,%eax
  105a86:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105a8d:	00 
  105a8e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
  105a95:	00 
  105a96:	89 04 24             	mov    %eax,(%esp)
  105a99:	e8 c6 23 00 00       	call   107e64 <memset>
	memset(mem_pi2ptr(pi2), 2, PAGESIZE);
  105a9e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105aa1:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  105aa6:	89 d3                	mov    %edx,%ebx
  105aa8:	29 c3                	sub    %eax,%ebx
  105aaa:	89 d8                	mov    %ebx,%eax
  105aac:	c1 f8 03             	sar    $0x3,%eax
  105aaf:	c1 e0 0c             	shl    $0xc,%eax
  105ab2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105ab9:	00 
  105aba:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  105ac1:	00 
  105ac2:	89 04 24             	mov    %eax,(%esp)
  105ac5:	e8 9a 23 00 00       	call   107e64 <memset>
	pmap_insert(pmap_bootpdir, pi1, VM_USERLO, 0);
  105aca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105ad1:	00 
  105ad2:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105ad9:	40 
  105ada:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105add:	89 44 24 04          	mov    %eax,0x4(%esp)
  105ae1:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105ae8:	e8 15 ef ff ff       	call   104a02 <pmap_insert>
	assert(pi1->refcount == 1);
  105aed:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105af0:	8b 40 04             	mov    0x4(%eax),%eax
  105af3:	83 f8 01             	cmp    $0x1,%eax
  105af6:	74 24                	je     105b1c <pmap_check+0xb6a>
  105af8:	c7 44 24 0c 5c 96 10 	movl   $0x10965c,0xc(%esp)
  105aff:	00 
  105b00:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105b07:	00 
  105b08:	c7 44 24 04 d2 01 00 	movl   $0x1d2,0x4(%esp)
  105b0f:	00 
  105b10:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105b17:	e8 9c a9 ff ff       	call   1004b8 <debug_panic>
	assert(*(int*)VM_USERLO == 0x01010101);
  105b1c:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105b21:	8b 00                	mov    (%eax),%eax
  105b23:	3d 01 01 01 01       	cmp    $0x1010101,%eax
  105b28:	74 24                	je     105b4e <pmap_check+0xb9c>
  105b2a:	c7 44 24 0c e0 99 10 	movl   $0x1099e0,0xc(%esp)
  105b31:	00 
  105b32:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105b39:	00 
  105b3a:	c7 44 24 04 d3 01 00 	movl   $0x1d3,0x4(%esp)
  105b41:	00 
  105b42:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105b49:	e8 6a a9 ff ff       	call   1004b8 <debug_panic>
	pmap_insert(pmap_bootpdir, pi2, VM_USERLO, 0);
  105b4e:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105b55:	00 
  105b56:	c7 44 24 08 00 00 00 	movl   $0x40000000,0x8(%esp)
  105b5d:	40 
  105b5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105b61:	89 44 24 04          	mov    %eax,0x4(%esp)
  105b65:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105b6c:	e8 91 ee ff ff       	call   104a02 <pmap_insert>
	assert(*(int*)VM_USERLO == 0x02020202);
  105b71:	b8 00 00 00 40       	mov    $0x40000000,%eax
  105b76:	8b 00                	mov    (%eax),%eax
  105b78:	3d 02 02 02 02       	cmp    $0x2020202,%eax
  105b7d:	74 24                	je     105ba3 <pmap_check+0xbf1>
  105b7f:	c7 44 24 0c 00 9a 10 	movl   $0x109a00,0xc(%esp)
  105b86:	00 
  105b87:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105b8e:	00 
  105b8f:	c7 44 24 04 d5 01 00 	movl   $0x1d5,0x4(%esp)
  105b96:	00 
  105b97:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105b9e:	e8 15 a9 ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 1);
  105ba3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105ba6:	8b 40 04             	mov    0x4(%eax),%eax
  105ba9:	83 f8 01             	cmp    $0x1,%eax
  105bac:	74 24                	je     105bd2 <pmap_check+0xc20>
  105bae:	c7 44 24 0c f9 96 10 	movl   $0x1096f9,0xc(%esp)
  105bb5:	00 
  105bb6:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105bbd:	00 
  105bbe:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
  105bc5:	00 
  105bc6:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105bcd:	e8 e6 a8 ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 0);
  105bd2:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105bd5:	8b 40 04             	mov    0x4(%eax),%eax
  105bd8:	85 c0                	test   %eax,%eax
  105bda:	74 24                	je     105c00 <pmap_check+0xc4e>
  105bdc:	c7 44 24 0c b7 99 10 	movl   $0x1099b7,0xc(%esp)
  105be3:	00 
  105be4:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105beb:	00 
  105bec:	c7 44 24 04 d7 01 00 	movl   $0x1d7,0x4(%esp)
  105bf3:	00 
  105bf4:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105bfb:	e8 b8 a8 ff ff       	call   1004b8 <debug_panic>
	assert(mem_alloc() == pi1);
  105c00:	e8 54 b0 ff ff       	call   100c59 <mem_alloc>
  105c05:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  105c08:	74 24                	je     105c2e <pmap_check+0xc7c>
  105c0a:	c7 44 24 0c ca 99 10 	movl   $0x1099ca,0xc(%esp)
  105c11:	00 
  105c12:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105c19:	00 
  105c1a:	c7 44 24 04 d8 01 00 	movl   $0x1d8,0x4(%esp)
  105c21:	00 
  105c22:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105c29:	e8 8a a8 ff ff       	call   1004b8 <debug_panic>
	pmap_remove(pmap_bootpdir, VM_USERLO, PAGESIZE);
  105c2e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  105c35:	00 
  105c36:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105c3d:	40 
  105c3e:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105c45:	e8 c2 ed ff ff       	call   104a0c <pmap_remove>
	assert(pi2->refcount == 0);
  105c4a:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105c4d:	8b 40 04             	mov    0x4(%eax),%eax
  105c50:	85 c0                	test   %eax,%eax
  105c52:	74 24                	je     105c78 <pmap_check+0xcc6>
  105c54:	c7 44 24 0c 38 99 10 	movl   $0x109938,0xc(%esp)
  105c5b:	00 
  105c5c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105c63:	00 
  105c64:	c7 44 24 04 da 01 00 	movl   $0x1da,0x4(%esp)
  105c6b:	00 
  105c6c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105c73:	e8 40 a8 ff ff       	call   1004b8 <debug_panic>
	assert(mem_alloc() == pi2);
  105c78:	e8 dc af ff ff       	call   100c59 <mem_alloc>
  105c7d:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  105c80:	74 24                	je     105ca6 <pmap_check+0xcf4>
  105c82:	c7 44 24 0c 4b 99 10 	movl   $0x10994b,0xc(%esp)
  105c89:	00 
  105c8a:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105c91:	00 
  105c92:	c7 44 24 04 db 01 00 	movl   $0x1db,0x4(%esp)
  105c99:	00 
  105c9a:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105ca1:	e8 12 a8 ff ff       	call   1004b8 <debug_panic>

	// now use a pmap_remove on a large region to take pi0 back
	pmap_remove(pmap_bootpdir, VM_USERLO, VM_USERHI-VM_USERLO);
  105ca6:	c7 44 24 08 00 00 00 	movl   $0xb0000000,0x8(%esp)
  105cad:	b0 
  105cae:	c7 44 24 04 00 00 00 	movl   $0x40000000,0x4(%esp)
  105cb5:	40 
  105cb6:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105cbd:	e8 4a ed ff ff       	call   104a0c <pmap_remove>
	assert(pmap_bootpdir[PDX(VM_USERLO)] == PTE_ZERO);
  105cc2:	8b 15 00 04 12 00    	mov    0x120400,%edx
  105cc8:	b8 00 10 12 00       	mov    $0x121000,%eax
  105ccd:	39 c2                	cmp    %eax,%edx
  105ccf:	74 24                	je     105cf5 <pmap_check+0xd43>
  105cd1:	c7 44 24 0c 20 9a 10 	movl   $0x109a20,0xc(%esp)
  105cd8:	00 
  105cd9:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105ce0:	00 
  105ce1:	c7 44 24 04 df 01 00 	movl   $0x1df,0x4(%esp)
  105ce8:	00 
  105ce9:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105cf0:	e8 c3 a7 ff ff       	call   1004b8 <debug_panic>
	assert(pi0->refcount == 0);
  105cf5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105cf8:	8b 40 04             	mov    0x4(%eax),%eax
  105cfb:	85 c0                	test   %eax,%eax
  105cfd:	74 24                	je     105d23 <pmap_check+0xd71>
  105cff:	c7 44 24 0c 4a 9a 10 	movl   $0x109a4a,0xc(%esp)
  105d06:	00 
  105d07:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105d0e:	00 
  105d0f:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
  105d16:	00 
  105d17:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105d1e:	e8 95 a7 ff ff       	call   1004b8 <debug_panic>
	assert(mem_alloc() == pi0);
  105d23:	e8 31 af ff ff       	call   100c59 <mem_alloc>
  105d28:	3b 45 d4             	cmp    -0x2c(%ebp),%eax
  105d2b:	74 24                	je     105d51 <pmap_check+0xd9f>
  105d2d:	c7 44 24 0c 5d 9a 10 	movl   $0x109a5d,0xc(%esp)
  105d34:	00 
  105d35:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105d3c:	00 
  105d3d:	c7 44 24 04 e1 01 00 	movl   $0x1e1,0x4(%esp)
  105d44:	00 
  105d45:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105d4c:	e8 67 a7 ff ff       	call   1004b8 <debug_panic>
	assert(mem_freelist == NULL);
  105d51:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  105d56:	85 c0                	test   %eax,%eax
  105d58:	74 24                	je     105d7e <pmap_check+0xdcc>
  105d5a:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  105d61:	00 
  105d62:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105d69:	00 
  105d6a:	c7 44 24 04 e2 01 00 	movl   $0x1e2,0x4(%esp)
  105d71:	00 
  105d72:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105d79:	e8 3a a7 ff ff       	call   1004b8 <debug_panic>

	// test pmap_remove with large, non-ptable-aligned regions
	mem_free(pi1);
  105d7e:	8b 45 d8             	mov    -0x28(%ebp),%eax
  105d81:	89 04 24             	mov    %eax,(%esp)
  105d84:	e8 21 af ff ff       	call   100caa <mem_free>
	uintptr_t va = VM_USERLO;
  105d89:	c7 45 f4 00 00 00 40 	movl   $0x40000000,-0xc(%ebp)
	assert(pmap_insert(pmap_bootpdir, pi0, va, 0));
  105d90:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105d97:	00 
  105d98:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105d9b:	89 44 24 08          	mov    %eax,0x8(%esp)
  105d9f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105da2:	89 44 24 04          	mov    %eax,0x4(%esp)
  105da6:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105dad:	e8 50 ec ff ff       	call   104a02 <pmap_insert>
  105db2:	85 c0                	test   %eax,%eax
  105db4:	75 24                	jne    105dda <pmap_check+0xe28>
  105db6:	c7 44 24 0c 88 9a 10 	movl   $0x109a88,0xc(%esp)
  105dbd:	00 
  105dbe:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105dc5:	00 
  105dc6:	c7 44 24 04 e7 01 00 	movl   $0x1e7,0x4(%esp)
  105dcd:	00 
  105dce:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105dd5:	e8 de a6 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PAGESIZE, 0));
  105dda:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105ddd:	05 00 10 00 00       	add    $0x1000,%eax
  105de2:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105de9:	00 
  105dea:	89 44 24 08          	mov    %eax,0x8(%esp)
  105dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105df1:	89 44 24 04          	mov    %eax,0x4(%esp)
  105df5:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105dfc:	e8 01 ec ff ff       	call   104a02 <pmap_insert>
  105e01:	85 c0                	test   %eax,%eax
  105e03:	75 24                	jne    105e29 <pmap_check+0xe77>
  105e05:	c7 44 24 0c b0 9a 10 	movl   $0x109ab0,0xc(%esp)
  105e0c:	00 
  105e0d:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105e14:	00 
  105e15:	c7 44 24 04 e8 01 00 	movl   $0x1e8,0x4(%esp)
  105e1c:	00 
  105e1d:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105e24:	e8 8f a6 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE-PAGESIZE, 0));
  105e29:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105e2c:	05 00 f0 3f 00       	add    $0x3ff000,%eax
  105e31:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105e38:	00 
  105e39:	89 44 24 08          	mov    %eax,0x8(%esp)
  105e3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105e40:	89 44 24 04          	mov    %eax,0x4(%esp)
  105e44:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105e4b:	e8 b2 eb ff ff       	call   104a02 <pmap_insert>
  105e50:	85 c0                	test   %eax,%eax
  105e52:	75 24                	jne    105e78 <pmap_check+0xec6>
  105e54:	c7 44 24 0c e0 9a 10 	movl   $0x109ae0,0xc(%esp)
  105e5b:	00 
  105e5c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105e63:	00 
  105e64:	c7 44 24 04 e9 01 00 	movl   $0x1e9,0x4(%esp)
  105e6b:	00 
  105e6c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105e73:	e8 40 a6 ff ff       	call   1004b8 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO)]) == mem_pi2phys(pi1));
  105e78:	a1 00 04 12 00       	mov    0x120400,%eax
  105e7d:	89 c1                	mov    %eax,%ecx
  105e7f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105e85:	8b 55 d8             	mov    -0x28(%ebp),%edx
  105e88:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  105e8d:	89 d3                	mov    %edx,%ebx
  105e8f:	29 c3                	sub    %eax,%ebx
  105e91:	89 d8                	mov    %ebx,%eax
  105e93:	c1 f8 03             	sar    $0x3,%eax
  105e96:	c1 e0 0c             	shl    $0xc,%eax
  105e99:	39 c1                	cmp    %eax,%ecx
  105e9b:	74 24                	je     105ec1 <pmap_check+0xf0f>
  105e9d:	c7 44 24 0c 18 9b 10 	movl   $0x109b18,0xc(%esp)
  105ea4:	00 
  105ea5:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105eac:	00 
  105ead:	c7 44 24 04 ea 01 00 	movl   $0x1ea,0x4(%esp)
  105eb4:	00 
  105eb5:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105ebc:	e8 f7 a5 ff ff       	call   1004b8 <debug_panic>
	assert(mem_freelist == NULL);
  105ec1:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  105ec6:	85 c0                	test   %eax,%eax
  105ec8:	74 24                	je     105eee <pmap_check+0xf3c>
  105eca:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  105ed1:	00 
  105ed2:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105ed9:	00 
  105eda:	c7 44 24 04 eb 01 00 	movl   $0x1eb,0x4(%esp)
  105ee1:	00 
  105ee2:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105ee9:	e8 ca a5 ff ff       	call   1004b8 <debug_panic>
	mem_free(pi2);
  105eee:	8b 45 dc             	mov    -0x24(%ebp),%eax
  105ef1:	89 04 24             	mov    %eax,(%esp)
  105ef4:	e8 b1 ad ff ff       	call   100caa <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE, 0));
  105ef9:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105efc:	05 00 00 40 00       	add    $0x400000,%eax
  105f01:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105f08:	00 
  105f09:	89 44 24 08          	mov    %eax,0x8(%esp)
  105f0d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105f10:	89 44 24 04          	mov    %eax,0x4(%esp)
  105f14:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105f1b:	e8 e2 ea ff ff       	call   104a02 <pmap_insert>
  105f20:	85 c0                	test   %eax,%eax
  105f22:	75 24                	jne    105f48 <pmap_check+0xf96>
  105f24:	c7 44 24 0c 54 9b 10 	movl   $0x109b54,0xc(%esp)
  105f2b:	00 
  105f2c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105f33:	00 
  105f34:	c7 44 24 04 ed 01 00 	movl   $0x1ed,0x4(%esp)
  105f3b:	00 
  105f3c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105f43:	e8 70 a5 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE+PAGESIZE, 0));
  105f48:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105f4b:	05 00 10 40 00       	add    $0x401000,%eax
  105f50:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105f57:	00 
  105f58:	89 44 24 08          	mov    %eax,0x8(%esp)
  105f5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105f5f:	89 44 24 04          	mov    %eax,0x4(%esp)
  105f63:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105f6a:	e8 93 ea ff ff       	call   104a02 <pmap_insert>
  105f6f:	85 c0                	test   %eax,%eax
  105f71:	75 24                	jne    105f97 <pmap_check+0xfe5>
  105f73:	c7 44 24 0c 84 9b 10 	movl   $0x109b84,0xc(%esp)
  105f7a:	00 
  105f7b:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105f82:	00 
  105f83:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
  105f8a:	00 
  105f8b:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105f92:	e8 21 a5 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2-PAGESIZE, 0));
  105f97:	8b 45 f4             	mov    -0xc(%ebp),%eax
  105f9a:	05 00 f0 7f 00       	add    $0x7ff000,%eax
  105f9f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  105fa6:	00 
  105fa7:	89 44 24 08          	mov    %eax,0x8(%esp)
  105fab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  105fae:	89 44 24 04          	mov    %eax,0x4(%esp)
  105fb2:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  105fb9:	e8 44 ea ff ff       	call   104a02 <pmap_insert>
  105fbe:	85 c0                	test   %eax,%eax
  105fc0:	75 24                	jne    105fe6 <pmap_check+0x1034>
  105fc2:	c7 44 24 0c bc 9b 10 	movl   $0x109bbc,0xc(%esp)
  105fc9:	00 
  105fca:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  105fd1:	00 
  105fd2:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
  105fd9:	00 
  105fda:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  105fe1:	e8 d2 a4 ff ff       	call   1004b8 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE)])
  105fe6:	a1 04 04 12 00       	mov    0x120404,%eax
  105feb:	89 c1                	mov    %eax,%ecx
  105fed:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  105ff3:	8b 55 dc             	mov    -0x24(%ebp),%edx
  105ff6:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  105ffb:	89 d3                	mov    %edx,%ebx
  105ffd:	29 c3                	sub    %eax,%ebx
  105fff:	89 d8                	mov    %ebx,%eax
  106001:	c1 f8 03             	sar    $0x3,%eax
  106004:	c1 e0 0c             	shl    $0xc,%eax
  106007:	39 c1                	cmp    %eax,%ecx
  106009:	74 24                	je     10602f <pmap_check+0x107d>
  10600b:	c7 44 24 0c f8 9b 10 	movl   $0x109bf8,0xc(%esp)
  106012:	00 
  106013:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10601a:	00 
  10601b:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
  106022:	00 
  106023:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10602a:	e8 89 a4 ff ff       	call   1004b8 <debug_panic>
		== mem_pi2phys(pi2));
	assert(mem_freelist == NULL);
  10602f:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  106034:	85 c0                	test   %eax,%eax
  106036:	74 24                	je     10605c <pmap_check+0x10aa>
  106038:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  10603f:	00 
  106040:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106047:	00 
  106048:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
  10604f:	00 
  106050:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106057:	e8 5c a4 ff ff       	call   1004b8 <debug_panic>
	mem_free(pi3);
  10605c:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10605f:	89 04 24             	mov    %eax,(%esp)
  106062:	e8 43 ac ff ff       	call   100caa <mem_free>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2, 0));
  106067:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10606a:	05 00 00 80 00       	add    $0x800000,%eax
  10606f:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106076:	00 
  106077:	89 44 24 08          	mov    %eax,0x8(%esp)
  10607b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10607e:	89 44 24 04          	mov    %eax,0x4(%esp)
  106082:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  106089:	e8 74 e9 ff ff       	call   104a02 <pmap_insert>
  10608e:	85 c0                	test   %eax,%eax
  106090:	75 24                	jne    1060b6 <pmap_check+0x1104>
  106092:	c7 44 24 0c 3c 9c 10 	movl   $0x109c3c,0xc(%esp)
  106099:	00 
  10609a:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1060a1:	00 
  1060a2:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
  1060a9:	00 
  1060aa:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1060b1:	e8 02 a4 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*2+PAGESIZE, 0));
  1060b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1060b9:	05 00 10 80 00       	add    $0x801000,%eax
  1060be:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  1060c5:	00 
  1060c6:	89 44 24 08          	mov    %eax,0x8(%esp)
  1060ca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1060cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  1060d1:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1060d8:	e8 25 e9 ff ff       	call   104a02 <pmap_insert>
  1060dd:	85 c0                	test   %eax,%eax
  1060df:	75 24                	jne    106105 <pmap_check+0x1153>
  1060e1:	c7 44 24 0c 6c 9c 10 	movl   $0x109c6c,0xc(%esp)
  1060e8:	00 
  1060e9:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1060f0:	00 
  1060f1:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
  1060f8:	00 
  1060f9:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106100:	e8 b3 a3 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE*2, 0));
  106105:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106108:	05 00 e0 bf 00       	add    $0xbfe000,%eax
  10610d:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106114:	00 
  106115:	89 44 24 08          	mov    %eax,0x8(%esp)
  106119:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10611c:	89 44 24 04          	mov    %eax,0x4(%esp)
  106120:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  106127:	e8 d6 e8 ff ff       	call   104a02 <pmap_insert>
  10612c:	85 c0                	test   %eax,%eax
  10612e:	75 24                	jne    106154 <pmap_check+0x11a2>
  106130:	c7 44 24 0c a8 9c 10 	movl   $0x109ca8,0xc(%esp)
  106137:	00 
  106138:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10613f:	00 
  106140:	c7 44 24 04 f6 01 00 	movl   $0x1f6,0x4(%esp)
  106147:	00 
  106148:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10614f:	e8 64 a3 ff ff       	call   1004b8 <debug_panic>
	assert(pmap_insert(pmap_bootpdir, pi0, va+PTSIZE*3-PAGESIZE, 0));
  106154:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106157:	05 00 f0 bf 00       	add    $0xbff000,%eax
  10615c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
  106163:	00 
  106164:	89 44 24 08          	mov    %eax,0x8(%esp)
  106168:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10616b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10616f:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  106176:	e8 87 e8 ff ff       	call   104a02 <pmap_insert>
  10617b:	85 c0                	test   %eax,%eax
  10617d:	75 24                	jne    1061a3 <pmap_check+0x11f1>
  10617f:	c7 44 24 0c e4 9c 10 	movl   $0x109ce4,0xc(%esp)
  106186:	00 
  106187:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10618e:	00 
  10618f:	c7 44 24 04 f7 01 00 	movl   $0x1f7,0x4(%esp)
  106196:	00 
  106197:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10619e:	e8 15 a3 ff ff       	call   1004b8 <debug_panic>
	assert(PGADDR(pmap_bootpdir[PDX(VM_USERLO+PTSIZE*2)])
  1061a3:	a1 08 04 12 00       	mov    0x120408,%eax
  1061a8:	89 c1                	mov    %eax,%ecx
  1061aa:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
  1061b0:	8b 55 e0             	mov    -0x20(%ebp),%edx
  1061b3:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1061b8:	89 d3                	mov    %edx,%ebx
  1061ba:	29 c3                	sub    %eax,%ebx
  1061bc:	89 d8                	mov    %ebx,%eax
  1061be:	c1 f8 03             	sar    $0x3,%eax
  1061c1:	c1 e0 0c             	shl    $0xc,%eax
  1061c4:	39 c1                	cmp    %eax,%ecx
  1061c6:	74 24                	je     1061ec <pmap_check+0x123a>
  1061c8:	c7 44 24 0c 20 9d 10 	movl   $0x109d20,0xc(%esp)
  1061cf:	00 
  1061d0:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1061d7:	00 
  1061d8:	c7 44 24 04 f9 01 00 	movl   $0x1f9,0x4(%esp)
  1061df:	00 
  1061e0:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1061e7:	e8 cc a2 ff ff       	call   1004b8 <debug_panic>
		== mem_pi2phys(pi3));
	assert(mem_freelist == NULL);
  1061ec:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  1061f1:	85 c0                	test   %eax,%eax
  1061f3:	74 24                	je     106219 <pmap_check+0x1267>
  1061f5:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  1061fc:	00 
  1061fd:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106204:	00 
  106205:	c7 44 24 04 fa 01 00 	movl   $0x1fa,0x4(%esp)
  10620c:	00 
  10620d:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106214:	e8 9f a2 ff ff       	call   1004b8 <debug_panic>
	assert(pi0->refcount == 10);
  106219:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10621c:	8b 40 04             	mov    0x4(%eax),%eax
  10621f:	83 f8 0a             	cmp    $0xa,%eax
  106222:	74 24                	je     106248 <pmap_check+0x1296>
  106224:	c7 44 24 0c 63 9d 10 	movl   $0x109d63,0xc(%esp)
  10622b:	00 
  10622c:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106233:	00 
  106234:	c7 44 24 04 fb 01 00 	movl   $0x1fb,0x4(%esp)
  10623b:	00 
  10623c:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106243:	e8 70 a2 ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 1);
  106248:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10624b:	8b 40 04             	mov    0x4(%eax),%eax
  10624e:	83 f8 01             	cmp    $0x1,%eax
  106251:	74 24                	je     106277 <pmap_check+0x12c5>
  106253:	c7 44 24 0c 5c 96 10 	movl   $0x10965c,0xc(%esp)
  10625a:	00 
  10625b:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106262:	00 
  106263:	c7 44 24 04 fc 01 00 	movl   $0x1fc,0x4(%esp)
  10626a:	00 
  10626b:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106272:	e8 41 a2 ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 1);
  106277:	8b 45 dc             	mov    -0x24(%ebp),%eax
  10627a:	8b 40 04             	mov    0x4(%eax),%eax
  10627d:	83 f8 01             	cmp    $0x1,%eax
  106280:	74 24                	je     1062a6 <pmap_check+0x12f4>
  106282:	c7 44 24 0c f9 96 10 	movl   $0x1096f9,0xc(%esp)
  106289:	00 
  10628a:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106291:	00 
  106292:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
  106299:	00 
  10629a:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1062a1:	e8 12 a2 ff ff       	call   1004b8 <debug_panic>
	assert(pi3->refcount == 1);
  1062a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1062a9:	8b 40 04             	mov    0x4(%eax),%eax
  1062ac:	83 f8 01             	cmp    $0x1,%eax
  1062af:	74 24                	je     1062d5 <pmap_check+0x1323>
  1062b1:	c7 44 24 0c 77 9d 10 	movl   $0x109d77,0xc(%esp)
  1062b8:	00 
  1062b9:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1062c0:	00 
  1062c1:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
  1062c8:	00 
  1062c9:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1062d0:	e8 e3 a1 ff ff       	call   1004b8 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3-PAGESIZE*2);
  1062d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1062d8:	05 00 10 00 00       	add    $0x1000,%eax
  1062dd:	c7 44 24 08 00 e0 bf 	movl   $0xbfe000,0x8(%esp)
  1062e4:	00 
  1062e5:	89 44 24 04          	mov    %eax,0x4(%esp)
  1062e9:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1062f0:	e8 17 e7 ff ff       	call   104a0c <pmap_remove>
	assert(pi0->refcount == 2);
  1062f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1062f8:	8b 40 04             	mov    0x4(%eax),%eax
  1062fb:	83 f8 02             	cmp    $0x2,%eax
  1062fe:	74 24                	je     106324 <pmap_check+0x1372>
  106300:	c7 44 24 0c 8a 9d 10 	movl   $0x109d8a,0xc(%esp)
  106307:	00 
  106308:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10630f:	00 
  106310:	c7 44 24 04 00 02 00 	movl   $0x200,0x4(%esp)
  106317:	00 
  106318:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10631f:	e8 94 a1 ff ff       	call   1004b8 <debug_panic>
	assert(pi2->refcount == 0); assert(mem_alloc() == pi2);
  106324:	8b 45 dc             	mov    -0x24(%ebp),%eax
  106327:	8b 40 04             	mov    0x4(%eax),%eax
  10632a:	85 c0                	test   %eax,%eax
  10632c:	74 24                	je     106352 <pmap_check+0x13a0>
  10632e:	c7 44 24 0c 38 99 10 	movl   $0x109938,0xc(%esp)
  106335:	00 
  106336:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10633d:	00 
  10633e:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
  106345:	00 
  106346:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10634d:	e8 66 a1 ff ff       	call   1004b8 <debug_panic>
  106352:	e8 02 a9 ff ff       	call   100c59 <mem_alloc>
  106357:	3b 45 dc             	cmp    -0x24(%ebp),%eax
  10635a:	74 24                	je     106380 <pmap_check+0x13ce>
  10635c:	c7 44 24 0c 4b 99 10 	movl   $0x10994b,0xc(%esp)
  106363:	00 
  106364:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10636b:	00 
  10636c:	c7 44 24 04 01 02 00 	movl   $0x201,0x4(%esp)
  106373:	00 
  106374:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10637b:	e8 38 a1 ff ff       	call   1004b8 <debug_panic>
	assert(mem_freelist == NULL);
  106380:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  106385:	85 c0                	test   %eax,%eax
  106387:	74 24                	je     1063ad <pmap_check+0x13fb>
  106389:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  106390:	00 
  106391:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106398:	00 
  106399:	c7 44 24 04 02 02 00 	movl   $0x202,0x4(%esp)
  1063a0:	00 
  1063a1:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1063a8:	e8 0b a1 ff ff       	call   1004b8 <debug_panic>
	pmap_remove(pmap_bootpdir, va, PTSIZE*3-PAGESIZE);
  1063ad:	c7 44 24 08 00 f0 bf 	movl   $0xbff000,0x8(%esp)
  1063b4:	00 
  1063b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1063b8:	89 44 24 04          	mov    %eax,0x4(%esp)
  1063bc:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1063c3:	e8 44 e6 ff ff       	call   104a0c <pmap_remove>
	assert(pi0->refcount == 1);
  1063c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1063cb:	8b 40 04             	mov    0x4(%eax),%eax
  1063ce:	83 f8 01             	cmp    $0x1,%eax
  1063d1:	74 24                	je     1063f7 <pmap_check+0x1445>
  1063d3:	c7 44 24 0c 6f 96 10 	movl   $0x10966f,0xc(%esp)
  1063da:	00 
  1063db:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1063e2:	00 
  1063e3:	c7 44 24 04 04 02 00 	movl   $0x204,0x4(%esp)
  1063ea:	00 
  1063eb:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1063f2:	e8 c1 a0 ff ff       	call   1004b8 <debug_panic>
	assert(pi1->refcount == 0); assert(mem_alloc() == pi1);
  1063f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1063fa:	8b 40 04             	mov    0x4(%eax),%eax
  1063fd:	85 c0                	test   %eax,%eax
  1063ff:	74 24                	je     106425 <pmap_check+0x1473>
  106401:	c7 44 24 0c b7 99 10 	movl   $0x1099b7,0xc(%esp)
  106408:	00 
  106409:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106410:	00 
  106411:	c7 44 24 04 05 02 00 	movl   $0x205,0x4(%esp)
  106418:	00 
  106419:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106420:	e8 93 a0 ff ff       	call   1004b8 <debug_panic>
  106425:	e8 2f a8 ff ff       	call   100c59 <mem_alloc>
  10642a:	3b 45 d8             	cmp    -0x28(%ebp),%eax
  10642d:	74 24                	je     106453 <pmap_check+0x14a1>
  10642f:	c7 44 24 0c ca 99 10 	movl   $0x1099ca,0xc(%esp)
  106436:	00 
  106437:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10643e:	00 
  10643f:	c7 44 24 04 05 02 00 	movl   $0x205,0x4(%esp)
  106446:	00 
  106447:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10644e:	e8 65 a0 ff ff       	call   1004b8 <debug_panic>
	assert(mem_freelist == NULL);
  106453:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  106458:	85 c0                	test   %eax,%eax
  10645a:	74 24                	je     106480 <pmap_check+0x14ce>
  10645c:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  106463:	00 
  106464:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10646b:	00 
  10646c:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
  106473:	00 
  106474:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10647b:	e8 38 a0 ff ff       	call   1004b8 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PTSIZE*3-PAGESIZE, PAGESIZE);
  106480:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106483:	05 00 f0 bf 00       	add    $0xbff000,%eax
  106488:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10648f:	00 
  106490:	89 44 24 04          	mov    %eax,0x4(%esp)
  106494:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10649b:	e8 6c e5 ff ff       	call   104a0c <pmap_remove>
	assert(pi0->refcount == 0);	// pi3 might or might not also be freed
  1064a0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1064a3:	8b 40 04             	mov    0x4(%eax),%eax
  1064a6:	85 c0                	test   %eax,%eax
  1064a8:	74 24                	je     1064ce <pmap_check+0x151c>
  1064aa:	c7 44 24 0c 4a 9a 10 	movl   $0x109a4a,0xc(%esp)
  1064b1:	00 
  1064b2:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1064b9:	00 
  1064ba:	c7 44 24 04 08 02 00 	movl   $0x208,0x4(%esp)
  1064c1:	00 
  1064c2:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1064c9:	e8 ea 9f ff ff       	call   1004b8 <debug_panic>
	pmap_remove(pmap_bootpdir, va+PAGESIZE, PTSIZE*3);
  1064ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1064d1:	05 00 10 00 00       	add    $0x1000,%eax
  1064d6:	c7 44 24 08 00 00 c0 	movl   $0xc00000,0x8(%esp)
  1064dd:	00 
  1064de:	89 44 24 04          	mov    %eax,0x4(%esp)
  1064e2:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  1064e9:	e8 1e e5 ff ff       	call   104a0c <pmap_remove>
	assert(pi3->refcount == 0);
  1064ee:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1064f1:	8b 40 04             	mov    0x4(%eax),%eax
  1064f4:	85 c0                	test   %eax,%eax
  1064f6:	74 24                	je     10651c <pmap_check+0x156a>
  1064f8:	c7 44 24 0c 9d 9d 10 	movl   $0x109d9d,0xc(%esp)
  1064ff:	00 
  106500:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106507:	00 
  106508:	c7 44 24 04 0a 02 00 	movl   $0x20a,0x4(%esp)
  10650f:	00 
  106510:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106517:	e8 9c 9f ff ff       	call   1004b8 <debug_panic>
	mem_alloc(); mem_alloc();	// collect pi0 and pi3
  10651c:	e8 38 a7 ff ff       	call   100c59 <mem_alloc>
  106521:	e8 33 a7 ff ff       	call   100c59 <mem_alloc>
	assert(mem_freelist == NULL);
  106526:	a1 18 ed 11 00       	mov    0x11ed18,%eax
  10652b:	85 c0                	test   %eax,%eax
  10652d:	74 24                	je     106553 <pmap_check+0x15a1>
  10652f:	c7 44 24 0c 70 9a 10 	movl   $0x109a70,0xc(%esp)
  106536:	00 
  106537:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  10653e:	00 
  10653f:	c7 44 24 04 0c 02 00 	movl   $0x20c,0x4(%esp)
  106546:	00 
  106547:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  10654e:	e8 65 9f ff ff       	call   1004b8 <debug_panic>

	// check pointer arithmetic in pmap_walk
	mem_free(pi0);
  106553:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  106556:	89 04 24             	mov    %eax,(%esp)
  106559:	e8 4c a7 ff ff       	call   100caa <mem_free>
	va = VM_USERLO + PAGESIZE*NPTENTRIES + PAGESIZE;
  10655e:	c7 45 f4 00 10 40 40 	movl   $0x40401000,-0xc(%ebp)
	ptep = pmap_walk(pmap_bootpdir, va, 1);
  106565:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10656c:	00 
  10656d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106570:	89 44 24 04          	mov    %eax,0x4(%esp)
  106574:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10657b:	e8 3f e4 ff ff       	call   1049bf <pmap_walk>
  106580:	89 45 e8             	mov    %eax,-0x18(%ebp)
	ptep1 = mem_ptr(PGADDR(pmap_bootpdir[PDX(va)]));
  106583:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106586:	c1 e8 16             	shr    $0x16,%eax
  106589:	8b 04 85 00 00 12 00 	mov    0x120000(,%eax,4),%eax
  106590:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106595:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(ptep == ptep1 + PTX(va));
  106598:	8b 45 f4             	mov    -0xc(%ebp),%eax
  10659b:	c1 e8 0c             	shr    $0xc,%eax
  10659e:	25 ff 03 00 00       	and    $0x3ff,%eax
  1065a3:	c1 e0 02             	shl    $0x2,%eax
  1065a6:	03 45 ec             	add    -0x14(%ebp),%eax
  1065a9:	3b 45 e8             	cmp    -0x18(%ebp),%eax
  1065ac:	74 24                	je     1065d2 <pmap_check+0x1620>
  1065ae:	c7 44 24 0c b0 9d 10 	movl   $0x109db0,0xc(%esp)
  1065b5:	00 
  1065b6:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  1065bd:	00 
  1065be:	c7 44 24 04 13 02 00 	movl   $0x213,0x4(%esp)
  1065c5:	00 
  1065c6:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  1065cd:	e8 e6 9e ff ff       	call   1004b8 <debug_panic>
	pmap_bootpdir[PDX(va)] = PTE_ZERO;
  1065d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1065d5:	89 c2                	mov    %eax,%edx
  1065d7:	c1 ea 16             	shr    $0x16,%edx
  1065da:	b8 00 10 12 00       	mov    $0x121000,%eax
  1065df:	89 04 95 00 00 12 00 	mov    %eax,0x120000(,%edx,4)
	pi0->refcount = 0;
  1065e6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1065e9:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
  1065f0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  1065f3:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  1065f8:	89 d1                	mov    %edx,%ecx
  1065fa:	29 c1                	sub    %eax,%ecx
  1065fc:	89 c8                	mov    %ecx,%eax
  1065fe:	c1 f8 03             	sar    $0x3,%eax
  106601:	c1 e0 0c             	shl    $0xc,%eax
  106604:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  10660b:	00 
  10660c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  106613:	00 
  106614:	89 04 24             	mov    %eax,(%esp)
  106617:	e8 48 18 00 00       	call   107e64 <memset>
	mem_free(pi0);
  10661c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  10661f:	89 04 24             	mov    %eax,(%esp)
  106622:	e8 83 a6 ff ff       	call   100caa <mem_free>
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
  106627:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
  10662e:	00 
  10662f:	c7 44 24 04 00 f0 ff 	movl   $0xeffff000,0x4(%esp)
  106636:	ef 
  106637:	c7 04 24 00 00 12 00 	movl   $0x120000,(%esp)
  10663e:	e8 7c e3 ff ff       	call   1049bf <pmap_walk>
	ptep = mem_pi2ptr(pi0);
  106643:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106646:	a1 24 ed 11 00       	mov    0x11ed24,%eax
  10664b:	89 d3                	mov    %edx,%ebx
  10664d:	29 c3                	sub    %eax,%ebx
  10664f:	89 d8                	mov    %ebx,%eax
  106651:	c1 f8 03             	sar    $0x3,%eax
  106654:	c1 e0 0c             	shl    $0xc,%eax
  106657:	89 45 e8             	mov    %eax,-0x18(%ebp)
	for(i=0; i<NPTENTRIES; i++)
  10665a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106661:	eb 3c                	jmp    10669f <pmap_check+0x16ed>
		assert(ptep[i] == PTE_ZERO);
  106663:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106666:	c1 e0 02             	shl    $0x2,%eax
  106669:	03 45 e8             	add    -0x18(%ebp),%eax
  10666c:	8b 10                	mov    (%eax),%edx
  10666e:	b8 00 10 12 00       	mov    $0x121000,%eax
  106673:	39 c2                	cmp    %eax,%edx
  106675:	74 24                	je     10669b <pmap_check+0x16e9>
  106677:	c7 44 24 0c c8 9d 10 	movl   $0x109dc8,0xc(%esp)
  10667e:	00 
  10667f:	c7 44 24 08 ce 92 10 	movl   $0x1092ce,0x8(%esp)
  106686:	00 
  106687:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
  10668e:	00 
  10668f:	c7 04 24 0c 93 10 00 	movl   $0x10930c,(%esp)
  106696:	e8 1d 9e ff ff       	call   1004b8 <debug_panic>
	// check that new page tables get cleared
	memset(mem_pi2ptr(pi0), 0xFF, PAGESIZE);
	mem_free(pi0);
	pmap_walk(pmap_bootpdir, VM_USERHI-PAGESIZE, 1);
	ptep = mem_pi2ptr(pi0);
	for(i=0; i<NPTENTRIES; i++)
  10669b:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  10669f:	81 7d f0 ff 03 00 00 	cmpl   $0x3ff,-0x10(%ebp)
  1066a6:	7e bb                	jle    106663 <pmap_check+0x16b1>
		assert(ptep[i] == PTE_ZERO);
	pmap_bootpdir[PDX(VM_USERHI-PAGESIZE)] = PTE_ZERO;
  1066a8:	b8 00 10 12 00       	mov    $0x121000,%eax
  1066ad:	a3 fc 0e 12 00       	mov    %eax,0x120efc
	pi0->refcount = 0;
  1066b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1066b5:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)

	// give free list back
	mem_freelist = fl;
  1066bc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1066bf:	a3 18 ed 11 00       	mov    %eax,0x11ed18

	// free the pages we filched
	mem_free(pi0);
  1066c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  1066c7:	89 04 24             	mov    %eax,(%esp)
  1066ca:	e8 db a5 ff ff       	call   100caa <mem_free>
	mem_free(pi1);
  1066cf:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1066d2:	89 04 24             	mov    %eax,(%esp)
  1066d5:	e8 d0 a5 ff ff       	call   100caa <mem_free>
	mem_free(pi2);
  1066da:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1066dd:	89 04 24             	mov    %eax,(%esp)
  1066e0:	e8 c5 a5 ff ff       	call   100caa <mem_free>
	mem_free(pi3);
  1066e5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1066e8:	89 04 24             	mov    %eax,(%esp)
  1066eb:	e8 ba a5 ff ff       	call   100caa <mem_free>

	cprintf("pmap_check() succeeded!\n");
  1066f0:	c7 04 24 dc 9d 10 00 	movl   $0x109ddc,(%esp)
  1066f7:	e8 81 15 00 00       	call   107c7d <cprintf>
}
  1066fc:	83 c4 44             	add    $0x44,%esp
  1066ff:	5b                   	pop    %ebx
  106700:	5d                   	pop    %ebp
  106701:	c3                   	ret    
  106702:	90                   	nop
  106703:	90                   	nop

00106704 <video_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
video_init(void)
{
  106704:	55                   	push   %ebp
  106705:	89 e5                	mov    %esp,%ebp
  106707:	83 ec 30             	sub    $0x30,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	/* Get a pointer to the memory-mapped text display buffer. */
	cp = (uint16_t*) mem_ptr(CGA_BUF);
  10670a:	c7 45 d8 00 80 0b 00 	movl   $0xb8000,-0x28(%ebp)
	was = *cp;
  106711:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106714:	0f b7 00             	movzwl (%eax),%eax
  106717:	66 89 45 de          	mov    %ax,-0x22(%ebp)
	*cp = (uint16_t) 0xA55A;
  10671b:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10671e:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
  106723:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106726:	0f b7 00             	movzwl (%eax),%eax
  106729:	66 3d 5a a5          	cmp    $0xa55a,%ax
  10672d:	74 13                	je     106742 <video_init+0x3e>
		cp = (uint16_t*) mem_ptr(MONO_BUF);
  10672f:	c7 45 d8 00 00 0b 00 	movl   $0xb0000,-0x28(%ebp)
		addr_6845 = MONO_BASE;
  106736:	c7 05 78 ec 11 00 b4 	movl   $0x3b4,0x11ec78
  10673d:	03 00 00 
  106740:	eb 14                	jmp    106756 <video_init+0x52>
	} else {
		*cp = was;
  106742:	8b 45 d8             	mov    -0x28(%ebp),%eax
  106745:	0f b7 55 de          	movzwl -0x22(%ebp),%edx
  106749:	66 89 10             	mov    %dx,(%eax)
		addr_6845 = CGA_BASE;
  10674c:	c7 05 78 ec 11 00 d4 	movl   $0x3d4,0x11ec78
  106753:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
  106756:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  10675b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  10675e:	c6 45 e7 0e          	movb   $0xe,-0x19(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106762:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
  106766:	8b 55 e8             	mov    -0x18(%ebp),%edx
  106769:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
  10676a:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  10676f:	83 c0 01             	add    $0x1,%eax
  106772:	89 45 ec             	mov    %eax,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106775:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106778:	89 c2                	mov    %eax,%edx
  10677a:	ec                   	in     (%dx),%al
  10677b:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  10677e:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax
  106782:	0f b6 c0             	movzbl %al,%eax
  106785:	c1 e0 08             	shl    $0x8,%eax
  106788:	89 45 e0             	mov    %eax,-0x20(%ebp)
	outb(addr_6845, 15);
  10678b:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  106790:	89 45 f4             	mov    %eax,-0xc(%ebp)
  106793:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106797:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10679b:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10679e:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
  10679f:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  1067a4:	83 c0 01             	add    $0x1,%eax
  1067a7:	89 45 f8             	mov    %eax,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1067aa:	8b 45 f8             	mov    -0x8(%ebp),%eax
  1067ad:	89 c2                	mov    %eax,%edx
  1067af:	ec                   	in     (%dx),%al
  1067b0:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  1067b3:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
  1067b7:	0f b6 c0             	movzbl %al,%eax
  1067ba:	09 45 e0             	or     %eax,-0x20(%ebp)

	crt_buf = (uint16_t*) cp;
  1067bd:	8b 45 d8             	mov    -0x28(%ebp),%eax
  1067c0:	a3 7c ec 11 00       	mov    %eax,0x11ec7c
	crt_pos = pos;
  1067c5:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1067c8:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
}
  1067ce:	c9                   	leave  
  1067cf:	c3                   	ret    

001067d0 <video_putc>:



void
video_putc(int c)
{
  1067d0:	55                   	push   %ebp
  1067d1:	89 e5                	mov    %esp,%ebp
  1067d3:	53                   	push   %ebx
  1067d4:	83 ec 44             	sub    $0x44,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
  1067d7:	8b 45 08             	mov    0x8(%ebp),%eax
  1067da:	b0 00                	mov    $0x0,%al
  1067dc:	85 c0                	test   %eax,%eax
  1067de:	75 07                	jne    1067e7 <video_putc+0x17>
		c |= 0x0700;
  1067e0:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
  1067e7:	8b 45 08             	mov    0x8(%ebp),%eax
  1067ea:	25 ff 00 00 00       	and    $0xff,%eax
  1067ef:	83 f8 09             	cmp    $0x9,%eax
  1067f2:	0f 84 ae 00 00 00    	je     1068a6 <video_putc+0xd6>
  1067f8:	83 f8 09             	cmp    $0x9,%eax
  1067fb:	7f 0a                	jg     106807 <video_putc+0x37>
  1067fd:	83 f8 08             	cmp    $0x8,%eax
  106800:	74 14                	je     106816 <video_putc+0x46>
  106802:	e9 dd 00 00 00       	jmp    1068e4 <video_putc+0x114>
  106807:	83 f8 0a             	cmp    $0xa,%eax
  10680a:	74 4e                	je     10685a <video_putc+0x8a>
  10680c:	83 f8 0d             	cmp    $0xd,%eax
  10680f:	74 59                	je     10686a <video_putc+0x9a>
  106811:	e9 ce 00 00 00       	jmp    1068e4 <video_putc+0x114>
	case '\b':
		if (crt_pos > 0) {
  106816:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  10681d:	66 85 c0             	test   %ax,%ax
  106820:	0f 84 e4 00 00 00    	je     10690a <video_putc+0x13a>
			crt_pos--;
  106826:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  10682d:	83 e8 01             	sub    $0x1,%eax
  106830:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
  106836:	a1 7c ec 11 00       	mov    0x11ec7c,%eax
  10683b:	0f b7 15 80 ec 11 00 	movzwl 0x11ec80,%edx
  106842:	0f b7 d2             	movzwl %dx,%edx
  106845:	01 d2                	add    %edx,%edx
  106847:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10684a:	8b 45 08             	mov    0x8(%ebp),%eax
  10684d:	b0 00                	mov    $0x0,%al
  10684f:	83 c8 20             	or     $0x20,%eax
  106852:	66 89 02             	mov    %ax,(%edx)
		}
		break;
  106855:	e9 b1 00 00 00       	jmp    10690b <video_putc+0x13b>
	case '\n':
		crt_pos += CRT_COLS;
  10685a:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  106861:	83 c0 50             	add    $0x50,%eax
  106864:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
  10686a:	0f b7 1d 80 ec 11 00 	movzwl 0x11ec80,%ebx
  106871:	0f b7 0d 80 ec 11 00 	movzwl 0x11ec80,%ecx
  106878:	0f b7 c1             	movzwl %cx,%eax
  10687b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
  106881:	c1 e8 10             	shr    $0x10,%eax
  106884:	89 c2                	mov    %eax,%edx
  106886:	66 c1 ea 06          	shr    $0x6,%dx
  10688a:	89 d0                	mov    %edx,%eax
  10688c:	c1 e0 02             	shl    $0x2,%eax
  10688f:	01 d0                	add    %edx,%eax
  106891:	c1 e0 04             	shl    $0x4,%eax
  106894:	89 ca                	mov    %ecx,%edx
  106896:	66 29 c2             	sub    %ax,%dx
  106899:	89 d8                	mov    %ebx,%eax
  10689b:	66 29 d0             	sub    %dx,%ax
  10689e:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
		break;
  1068a4:	eb 65                	jmp    10690b <video_putc+0x13b>
	case '\t':
		video_putc(' ');
  1068a6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1068ad:	e8 1e ff ff ff       	call   1067d0 <video_putc>
		video_putc(' ');
  1068b2:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1068b9:	e8 12 ff ff ff       	call   1067d0 <video_putc>
		video_putc(' ');
  1068be:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1068c5:	e8 06 ff ff ff       	call   1067d0 <video_putc>
		video_putc(' ');
  1068ca:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1068d1:	e8 fa fe ff ff       	call   1067d0 <video_putc>
		video_putc(' ');
  1068d6:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1068dd:	e8 ee fe ff ff       	call   1067d0 <video_putc>
		break;
  1068e2:	eb 27                	jmp    10690b <video_putc+0x13b>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
  1068e4:	8b 15 7c ec 11 00    	mov    0x11ec7c,%edx
  1068ea:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  1068f1:	0f b7 c8             	movzwl %ax,%ecx
  1068f4:	01 c9                	add    %ecx,%ecx
  1068f6:	8d 0c 0a             	lea    (%edx,%ecx,1),%ecx
  1068f9:	8b 55 08             	mov    0x8(%ebp),%edx
  1068fc:	66 89 11             	mov    %dx,(%ecx)
  1068ff:	83 c0 01             	add    $0x1,%eax
  106902:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
  106908:	eb 01                	jmp    10690b <video_putc+0x13b>
	case '\b':
		if (crt_pos > 0) {
			crt_pos--;
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
		}
		break;
  10690a:	90                   	nop
		crt_buf[crt_pos++] = c;		/* write the character */
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
  10690b:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  106912:	66 3d cf 07          	cmp    $0x7cf,%ax
  106916:	76 5b                	jbe    106973 <video_putc+0x1a3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
  106918:	a1 7c ec 11 00       	mov    0x11ec7c,%eax
  10691d:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
  106923:	a1 7c ec 11 00       	mov    0x11ec7c,%eax
  106928:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
  10692f:	00 
  106930:	89 54 24 04          	mov    %edx,0x4(%esp)
  106934:	89 04 24             	mov    %eax,(%esp)
  106937:	e8 9c 15 00 00       	call   107ed8 <memmove>
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  10693c:	c7 45 d4 80 07 00 00 	movl   $0x780,-0x2c(%ebp)
  106943:	eb 15                	jmp    10695a <video_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
  106945:	a1 7c ec 11 00       	mov    0x11ec7c,%eax
  10694a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  10694d:	01 d2                	add    %edx,%edx
  10694f:	01 d0                	add    %edx,%eax
  106951:	66 c7 00 20 07       	movw   $0x720,(%eax)
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS,
			(CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
  106956:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
  10695a:	81 7d d4 cf 07 00 00 	cmpl   $0x7cf,-0x2c(%ebp)
  106961:	7e e2                	jle    106945 <video_putc+0x175>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
  106963:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  10696a:	83 e8 50             	sub    $0x50,%eax
  10696d:	66 a3 80 ec 11 00    	mov    %ax,0x11ec80
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
  106973:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  106978:	89 45 dc             	mov    %eax,-0x24(%ebp)
  10697b:	c6 45 db 0e          	movb   $0xe,-0x25(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10697f:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106983:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106986:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
  106987:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  10698e:	66 c1 e8 08          	shr    $0x8,%ax
  106992:	0f b6 c0             	movzbl %al,%eax
  106995:	8b 15 78 ec 11 00    	mov    0x11ec78,%edx
  10699b:	83 c2 01             	add    $0x1,%edx
  10699e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  1069a1:	88 45 e3             	mov    %al,-0x1d(%ebp)
  1069a4:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  1069a8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  1069ab:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
  1069ac:	a1 78 ec 11 00       	mov    0x11ec78,%eax
  1069b1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  1069b4:	c6 45 eb 0f          	movb   $0xf,-0x15(%ebp)
  1069b8:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  1069bc:	8b 55 ec             	mov    -0x14(%ebp),%edx
  1069bf:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
  1069c0:	0f b7 05 80 ec 11 00 	movzwl 0x11ec80,%eax
  1069c7:	0f b6 c0             	movzbl %al,%eax
  1069ca:	8b 15 78 ec 11 00    	mov    0x11ec78,%edx
  1069d0:	83 c2 01             	add    $0x1,%edx
  1069d3:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1069d6:	88 45 f3             	mov    %al,-0xd(%ebp)
  1069d9:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  1069dd:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1069e0:	ee                   	out    %al,(%dx)
}
  1069e1:	83 c4 44             	add    $0x44,%esp
  1069e4:	5b                   	pop    %ebx
  1069e5:	5d                   	pop    %ebp
  1069e6:	c3                   	ret    
  1069e7:	90                   	nop

001069e8 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
  1069e8:	55                   	push   %ebp
  1069e9:	89 e5                	mov    %esp,%ebp
  1069eb:	83 ec 38             	sub    $0x38,%esp
  1069ee:	c7 45 e4 64 00 00 00 	movl   $0x64,-0x1c(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  1069f5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  1069f8:	89 c2                	mov    %eax,%edx
  1069fa:	ec                   	in     (%dx),%al
  1069fb:	88 45 eb             	mov    %al,-0x15(%ebp)
	return data;
  1069fe:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
  106a02:	0f b6 c0             	movzbl %al,%eax
  106a05:	83 e0 01             	and    $0x1,%eax
  106a08:	85 c0                	test   %eax,%eax
  106a0a:	75 0a                	jne    106a16 <kbd_proc_data+0x2e>
		return -1;
  106a0c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106a11:	e9 5a 01 00 00       	jmp    106b70 <kbd_proc_data+0x188>
  106a16:	c7 45 ec 60 00 00 00 	movl   $0x60,-0x14(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106a1d:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106a20:	89 c2                	mov    %eax,%edx
  106a22:	ec                   	in     (%dx),%al
  106a23:	88 45 f2             	mov    %al,-0xe(%ebp)
	return data;
  106a26:	0f b6 45 f2          	movzbl -0xe(%ebp),%eax

	data = inb(KBDATAP);
  106a2a:	88 45 e3             	mov    %al,-0x1d(%ebp)

	if (data == 0xE0) {
  106a2d:	80 7d e3 e0          	cmpb   $0xe0,-0x1d(%ebp)
  106a31:	75 17                	jne    106a4a <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
  106a33:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106a38:	83 c8 40             	or     $0x40,%eax
  106a3b:	a3 84 ec 11 00       	mov    %eax,0x11ec84
		return 0;
  106a40:	b8 00 00 00 00       	mov    $0x0,%eax
  106a45:	e9 26 01 00 00       	jmp    106b70 <kbd_proc_data+0x188>
	} else if (data & 0x80) {
  106a4a:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106a4e:	84 c0                	test   %al,%al
  106a50:	79 47                	jns    106a99 <kbd_proc_data+0xb1>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
  106a52:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106a57:	83 e0 40             	and    $0x40,%eax
  106a5a:	85 c0                	test   %eax,%eax
  106a5c:	75 09                	jne    106a67 <kbd_proc_data+0x7f>
  106a5e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106a62:	83 e0 7f             	and    $0x7f,%eax
  106a65:	eb 04                	jmp    106a6b <kbd_proc_data+0x83>
  106a67:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106a6b:	88 45 e3             	mov    %al,-0x1d(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
  106a6e:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106a72:	0f b6 80 20 c0 10 00 	movzbl 0x10c020(%eax),%eax
  106a79:	83 c8 40             	or     $0x40,%eax
  106a7c:	0f b6 c0             	movzbl %al,%eax
  106a7f:	f7 d0                	not    %eax
  106a81:	89 c2                	mov    %eax,%edx
  106a83:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106a88:	21 d0                	and    %edx,%eax
  106a8a:	a3 84 ec 11 00       	mov    %eax,0x11ec84
		return 0;
  106a8f:	b8 00 00 00 00       	mov    $0x0,%eax
  106a94:	e9 d7 00 00 00       	jmp    106b70 <kbd_proc_data+0x188>
	} else if (shift & E0ESC) {
  106a99:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106a9e:	83 e0 40             	and    $0x40,%eax
  106aa1:	85 c0                	test   %eax,%eax
  106aa3:	74 11                	je     106ab6 <kbd_proc_data+0xce>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
  106aa5:	80 4d e3 80          	orb    $0x80,-0x1d(%ebp)
		shift &= ~E0ESC;
  106aa9:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106aae:	83 e0 bf             	and    $0xffffffbf,%eax
  106ab1:	a3 84 ec 11 00       	mov    %eax,0x11ec84
	}

	shift |= shiftcode[data];
  106ab6:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106aba:	0f b6 80 20 c0 10 00 	movzbl 0x10c020(%eax),%eax
  106ac1:	0f b6 d0             	movzbl %al,%edx
  106ac4:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106ac9:	09 d0                	or     %edx,%eax
  106acb:	a3 84 ec 11 00       	mov    %eax,0x11ec84
	shift ^= togglecode[data];
  106ad0:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106ad4:	0f b6 80 20 c1 10 00 	movzbl 0x10c120(%eax),%eax
  106adb:	0f b6 d0             	movzbl %al,%edx
  106ade:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106ae3:	31 d0                	xor    %edx,%eax
  106ae5:	a3 84 ec 11 00       	mov    %eax,0x11ec84

	c = charcode[shift & (CTL | SHIFT)][data];
  106aea:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106aef:	83 e0 03             	and    $0x3,%eax
  106af2:	8b 14 85 20 c5 10 00 	mov    0x10c520(,%eax,4),%edx
  106af9:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106afd:	8d 04 02             	lea    (%edx,%eax,1),%eax
  106b00:	0f b6 00             	movzbl (%eax),%eax
  106b03:	0f b6 c0             	movzbl %al,%eax
  106b06:	89 45 dc             	mov    %eax,-0x24(%ebp)
	if (shift & CAPSLOCK) {
  106b09:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106b0e:	83 e0 08             	and    $0x8,%eax
  106b11:	85 c0                	test   %eax,%eax
  106b13:	74 22                	je     106b37 <kbd_proc_data+0x14f>
		if ('a' <= c && c <= 'z')
  106b15:	83 7d dc 60          	cmpl   $0x60,-0x24(%ebp)
  106b19:	7e 0c                	jle    106b27 <kbd_proc_data+0x13f>
  106b1b:	83 7d dc 7a          	cmpl   $0x7a,-0x24(%ebp)
  106b1f:	7f 06                	jg     106b27 <kbd_proc_data+0x13f>
			c += 'A' - 'a';
  106b21:	83 6d dc 20          	subl   $0x20,-0x24(%ebp)
	shift |= shiftcode[data];
	shift ^= togglecode[data];

	c = charcode[shift & (CTL | SHIFT)][data];
	if (shift & CAPSLOCK) {
		if ('a' <= c && c <= 'z')
  106b25:	eb 10                	jmp    106b37 <kbd_proc_data+0x14f>
			c += 'A' - 'a';
		else if ('A' <= c && c <= 'Z')
  106b27:	83 7d dc 40          	cmpl   $0x40,-0x24(%ebp)
  106b2b:	7e 0a                	jle    106b37 <kbd_proc_data+0x14f>
  106b2d:	83 7d dc 5a          	cmpl   $0x5a,-0x24(%ebp)
  106b31:	7f 04                	jg     106b37 <kbd_proc_data+0x14f>
			c += 'a' - 'A';
  106b33:	83 45 dc 20          	addl   $0x20,-0x24(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
  106b37:	a1 84 ec 11 00       	mov    0x11ec84,%eax
  106b3c:	f7 d0                	not    %eax
  106b3e:	83 e0 06             	and    $0x6,%eax
  106b41:	85 c0                	test   %eax,%eax
  106b43:	75 28                	jne    106b6d <kbd_proc_data+0x185>
  106b45:	81 7d dc e9 00 00 00 	cmpl   $0xe9,-0x24(%ebp)
  106b4c:	75 1f                	jne    106b6d <kbd_proc_data+0x185>
		cprintf("Rebooting!\n");
  106b4e:	c7 04 24 f5 9d 10 00 	movl   $0x109df5,(%esp)
  106b55:	e8 23 11 00 00       	call   107c7d <cprintf>
  106b5a:	c7 45 f4 92 00 00 00 	movl   $0x92,-0xc(%ebp)
  106b61:	c6 45 f3 03          	movb   $0x3,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106b65:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106b69:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106b6c:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
  106b6d:	8b 45 dc             	mov    -0x24(%ebp),%eax
}
  106b70:	c9                   	leave  
  106b71:	c3                   	ret    

00106b72 <kbd_intr>:

void
kbd_intr(void)
{
  106b72:	55                   	push   %ebp
  106b73:	89 e5                	mov    %esp,%ebp
  106b75:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
  106b78:	c7 04 24 e8 69 10 00 	movl   $0x1069e8,(%esp)
  106b7f:	e8 67 97 ff ff       	call   1002eb <cons_intr>
}
  106b84:	c9                   	leave  
  106b85:	c3                   	ret    

00106b86 <kbd_init>:

void
kbd_init(void)
{
  106b86:	55                   	push   %ebp
  106b87:	89 e5                	mov    %esp,%ebp
}
  106b89:	5d                   	pop    %ebp
  106b8a:	c3                   	ret    
  106b8b:	90                   	nop

00106b8c <delay>:


// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
  106b8c:	55                   	push   %ebp
  106b8d:	89 e5                	mov    %esp,%ebp
  106b8f:	83 ec 20             	sub    $0x20,%esp
  106b92:	c7 45 e0 84 00 00 00 	movl   $0x84,-0x20(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106b99:	8b 45 e0             	mov    -0x20(%ebp),%eax
  106b9c:	89 c2                	mov    %eax,%edx
  106b9e:	ec                   	in     (%dx),%al
  106b9f:	88 45 e7             	mov    %al,-0x19(%ebp)
	return data;
  106ba2:	c7 45 e8 84 00 00 00 	movl   $0x84,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106ba9:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106bac:	89 c2                	mov    %eax,%edx
  106bae:	ec                   	in     (%dx),%al
  106baf:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  106bb2:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106bb9:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106bbc:	89 c2                	mov    %eax,%edx
  106bbe:	ec                   	in     (%dx),%al
  106bbf:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106bc2:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106bc9:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106bcc:	89 c2                	mov    %eax,%edx
  106bce:	ec                   	in     (%dx),%al
  106bcf:	88 45 ff             	mov    %al,-0x1(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
  106bd2:	c9                   	leave  
  106bd3:	c3                   	ret    

00106bd4 <serial_proc_data>:

static int
serial_proc_data(void)
{
  106bd4:	55                   	push   %ebp
  106bd5:	89 e5                	mov    %esp,%ebp
  106bd7:	83 ec 10             	sub    $0x10,%esp
  106bda:	c7 45 f0 fd 03 00 00 	movl   $0x3fd,-0x10(%ebp)
  106be1:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106be4:	89 c2                	mov    %eax,%edx
  106be6:	ec                   	in     (%dx),%al
  106be7:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106bea:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
  106bee:	0f b6 c0             	movzbl %al,%eax
  106bf1:	83 e0 01             	and    $0x1,%eax
  106bf4:	85 c0                	test   %eax,%eax
  106bf6:	75 07                	jne    106bff <serial_proc_data+0x2b>
		return -1;
  106bf8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
  106bfd:	eb 17                	jmp    106c16 <serial_proc_data+0x42>
  106bff:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106c06:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106c09:	89 c2                	mov    %eax,%edx
  106c0b:	ec                   	in     (%dx),%al
  106c0c:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106c0f:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(COM1+COM_RX);
  106c13:	0f b6 c0             	movzbl %al,%eax
}
  106c16:	c9                   	leave  
  106c17:	c3                   	ret    

00106c18 <serial_intr>:

void
serial_intr(void)
{
  106c18:	55                   	push   %ebp
  106c19:	89 e5                	mov    %esp,%ebp
  106c1b:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
  106c1e:	a1 00 20 12 00       	mov    0x122000,%eax
  106c23:	85 c0                	test   %eax,%eax
  106c25:	74 0c                	je     106c33 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
  106c27:	c7 04 24 d4 6b 10 00 	movl   $0x106bd4,(%esp)
  106c2e:	e8 b8 96 ff ff       	call   1002eb <cons_intr>
}
  106c33:	c9                   	leave  
  106c34:	c3                   	ret    

00106c35 <serial_putc>:

void
serial_putc(int c)
{
  106c35:	55                   	push   %ebp
  106c36:	89 e5                	mov    %esp,%ebp
  106c38:	83 ec 10             	sub    $0x10,%esp
	if (!serial_exists)
  106c3b:	a1 00 20 12 00       	mov    0x122000,%eax
  106c40:	85 c0                	test   %eax,%eax
  106c42:	74 53                	je     106c97 <serial_putc+0x62>
		return;

	int i;
	for (i = 0;
  106c44:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  106c4b:	eb 09                	jmp    106c56 <serial_putc+0x21>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
  106c4d:	e8 3a ff ff ff       	call   106b8c <delay>
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
  106c52:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
  106c56:	c7 45 f4 fd 03 00 00 	movl   $0x3fd,-0xc(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106c5d:	8b 45 f4             	mov    -0xc(%ebp),%eax
  106c60:	89 c2                	mov    %eax,%edx
  106c62:	ec                   	in     (%dx),%al
  106c63:	88 45 fa             	mov    %al,-0x6(%ebp)
	return data;
  106c66:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
  106c6a:	0f b6 c0             	movzbl %al,%eax
  106c6d:	83 e0 20             	and    $0x20,%eax
{
	if (!serial_exists)
		return;

	int i;
	for (i = 0;
  106c70:	85 c0                	test   %eax,%eax
  106c72:	75 09                	jne    106c7d <serial_putc+0x48>
  106c74:	81 7d f0 ff 31 00 00 	cmpl   $0x31ff,-0x10(%ebp)
  106c7b:	7e d0                	jle    106c4d <serial_putc+0x18>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
  106c7d:	8b 45 08             	mov    0x8(%ebp),%eax
  106c80:	0f b6 c0             	movzbl %al,%eax
  106c83:	c7 45 fc f8 03 00 00 	movl   $0x3f8,-0x4(%ebp)
  106c8a:	88 45 fb             	mov    %al,-0x5(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106c8d:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106c91:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106c94:	ee                   	out    %al,(%dx)
  106c95:	eb 01                	jmp    106c98 <serial_putc+0x63>

void
serial_putc(int c)
{
	if (!serial_exists)
		return;
  106c97:	90                   	nop
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
}
  106c98:	c9                   	leave  
  106c99:	c3                   	ret    

00106c9a <serial_init>:

void
serial_init(void)
{
  106c9a:	55                   	push   %ebp
  106c9b:	89 e5                	mov    %esp,%ebp
  106c9d:	83 ec 50             	sub    $0x50,%esp
  106ca0:	c7 45 b4 fa 03 00 00 	movl   $0x3fa,-0x4c(%ebp)
  106ca7:	c6 45 b3 00          	movb   $0x0,-0x4d(%ebp)
  106cab:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  106caf:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106cb2:	ee                   	out    %al,(%dx)
  106cb3:	c7 45 bc fb 03 00 00 	movl   $0x3fb,-0x44(%ebp)
  106cba:	c6 45 bb 80          	movb   $0x80,-0x45(%ebp)
  106cbe:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106cc2:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106cc5:	ee                   	out    %al,(%dx)
  106cc6:	c7 45 c4 f8 03 00 00 	movl   $0x3f8,-0x3c(%ebp)
  106ccd:	c6 45 c3 0c          	movb   $0xc,-0x3d(%ebp)
  106cd1:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106cd5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106cd8:	ee                   	out    %al,(%dx)
  106cd9:	c7 45 cc f9 03 00 00 	movl   $0x3f9,-0x34(%ebp)
  106ce0:	c6 45 cb 00          	movb   $0x0,-0x35(%ebp)
  106ce4:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106ce8:	8b 55 cc             	mov    -0x34(%ebp),%edx
  106ceb:	ee                   	out    %al,(%dx)
  106cec:	c7 45 d4 fb 03 00 00 	movl   $0x3fb,-0x2c(%ebp)
  106cf3:	c6 45 d3 03          	movb   $0x3,-0x2d(%ebp)
  106cf7:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106cfb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106cfe:	ee                   	out    %al,(%dx)
  106cff:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
  106d06:	c6 45 db 00          	movb   $0x0,-0x25(%ebp)
  106d0a:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106d0e:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106d11:	ee                   	out    %al,(%dx)
  106d12:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
  106d19:	c6 45 e3 01          	movb   $0x1,-0x1d(%ebp)
  106d1d:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106d21:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106d24:	ee                   	out    %al,(%dx)
  106d25:	c7 45 e8 fd 03 00 00 	movl   $0x3fd,-0x18(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106d2c:	8b 45 e8             	mov    -0x18(%ebp),%eax
  106d2f:	89 c2                	mov    %eax,%edx
  106d31:	ec                   	in     (%dx),%al
  106d32:	88 45 ef             	mov    %al,-0x11(%ebp)
	return data;
  106d35:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
  106d39:	3c ff                	cmp    $0xff,%al
  106d3b:	0f 95 c0             	setne  %al
  106d3e:	0f b6 c0             	movzbl %al,%eax
  106d41:	a3 00 20 12 00       	mov    %eax,0x122000
  106d46:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106d4d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106d50:	89 c2                	mov    %eax,%edx
  106d52:	ec                   	in     (%dx),%al
  106d53:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
  106d56:	c7 45 f8 f8 03 00 00 	movl   $0x3f8,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106d5d:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106d60:	89 c2                	mov    %eax,%edx
  106d62:	ec                   	in     (%dx),%al
  106d63:	88 45 ff             	mov    %al,-0x1(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);
}
  106d66:	c9                   	leave  
  106d67:	c3                   	ret    

00106d68 <pic_init>:
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
  106d68:	55                   	push   %ebp
  106d69:	89 e5                	mov    %esp,%ebp
  106d6b:	81 ec 88 00 00 00    	sub    $0x88,%esp
	if (didinit)		// only do once on bootstrap CPU
  106d71:	a1 88 ec 11 00       	mov    0x11ec88,%eax
  106d76:	85 c0                	test   %eax,%eax
  106d78:	0f 85 35 01 00 00    	jne    106eb3 <pic_init+0x14b>
		return;
	didinit = 1;
  106d7e:	c7 05 88 ec 11 00 01 	movl   $0x1,0x11ec88
  106d85:	00 00 00 
  106d88:	c7 45 8c 21 00 00 00 	movl   $0x21,-0x74(%ebp)
  106d8f:	c6 45 8b ff          	movb   $0xff,-0x75(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106d93:	0f b6 45 8b          	movzbl -0x75(%ebp),%eax
  106d97:	8b 55 8c             	mov    -0x74(%ebp),%edx
  106d9a:	ee                   	out    %al,(%dx)
  106d9b:	c7 45 94 a1 00 00 00 	movl   $0xa1,-0x6c(%ebp)
  106da2:	c6 45 93 ff          	movb   $0xff,-0x6d(%ebp)
  106da6:	0f b6 45 93          	movzbl -0x6d(%ebp),%eax
  106daa:	8b 55 94             	mov    -0x6c(%ebp),%edx
  106dad:	ee                   	out    %al,(%dx)
  106dae:	c7 45 9c 20 00 00 00 	movl   $0x20,-0x64(%ebp)
  106db5:	c6 45 9b 11          	movb   $0x11,-0x65(%ebp)
  106db9:	0f b6 45 9b          	movzbl -0x65(%ebp),%eax
  106dbd:	8b 55 9c             	mov    -0x64(%ebp),%edx
  106dc0:	ee                   	out    %al,(%dx)
  106dc1:	c7 45 a4 21 00 00 00 	movl   $0x21,-0x5c(%ebp)
  106dc8:	c6 45 a3 20          	movb   $0x20,-0x5d(%ebp)
  106dcc:	0f b6 45 a3          	movzbl -0x5d(%ebp),%eax
  106dd0:	8b 55 a4             	mov    -0x5c(%ebp),%edx
  106dd3:	ee                   	out    %al,(%dx)
  106dd4:	c7 45 ac 21 00 00 00 	movl   $0x21,-0x54(%ebp)
  106ddb:	c6 45 ab 04          	movb   $0x4,-0x55(%ebp)
  106ddf:	0f b6 45 ab          	movzbl -0x55(%ebp),%eax
  106de3:	8b 55 ac             	mov    -0x54(%ebp),%edx
  106de6:	ee                   	out    %al,(%dx)
  106de7:	c7 45 b4 21 00 00 00 	movl   $0x21,-0x4c(%ebp)
  106dee:	c6 45 b3 03          	movb   $0x3,-0x4d(%ebp)
  106df2:	0f b6 45 b3          	movzbl -0x4d(%ebp),%eax
  106df6:	8b 55 b4             	mov    -0x4c(%ebp),%edx
  106df9:	ee                   	out    %al,(%dx)
  106dfa:	c7 45 bc a0 00 00 00 	movl   $0xa0,-0x44(%ebp)
  106e01:	c6 45 bb 11          	movb   $0x11,-0x45(%ebp)
  106e05:	0f b6 45 bb          	movzbl -0x45(%ebp),%eax
  106e09:	8b 55 bc             	mov    -0x44(%ebp),%edx
  106e0c:	ee                   	out    %al,(%dx)
  106e0d:	c7 45 c4 a1 00 00 00 	movl   $0xa1,-0x3c(%ebp)
  106e14:	c6 45 c3 28          	movb   $0x28,-0x3d(%ebp)
  106e18:	0f b6 45 c3          	movzbl -0x3d(%ebp),%eax
  106e1c:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  106e1f:	ee                   	out    %al,(%dx)
  106e20:	c7 45 cc a1 00 00 00 	movl   $0xa1,-0x34(%ebp)
  106e27:	c6 45 cb 02          	movb   $0x2,-0x35(%ebp)
  106e2b:	0f b6 45 cb          	movzbl -0x35(%ebp),%eax
  106e2f:	8b 55 cc             	mov    -0x34(%ebp),%edx
  106e32:	ee                   	out    %al,(%dx)
  106e33:	c7 45 d4 a1 00 00 00 	movl   $0xa1,-0x2c(%ebp)
  106e3a:	c6 45 d3 01          	movb   $0x1,-0x2d(%ebp)
  106e3e:	0f b6 45 d3          	movzbl -0x2d(%ebp),%eax
  106e42:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  106e45:	ee                   	out    %al,(%dx)
  106e46:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
  106e4d:	c6 45 db 68          	movb   $0x68,-0x25(%ebp)
  106e51:	0f b6 45 db          	movzbl -0x25(%ebp),%eax
  106e55:	8b 55 dc             	mov    -0x24(%ebp),%edx
  106e58:	ee                   	out    %al,(%dx)
  106e59:	c7 45 e4 20 00 00 00 	movl   $0x20,-0x1c(%ebp)
  106e60:	c6 45 e3 0a          	movb   $0xa,-0x1d(%ebp)
  106e64:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
  106e68:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  106e6b:	ee                   	out    %al,(%dx)
  106e6c:	c7 45 ec a0 00 00 00 	movl   $0xa0,-0x14(%ebp)
  106e73:	c6 45 eb 68          	movb   $0x68,-0x15(%ebp)
  106e77:	0f b6 45 eb          	movzbl -0x15(%ebp),%eax
  106e7b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  106e7e:	ee                   	out    %al,(%dx)
  106e7f:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
  106e86:	c6 45 f3 0a          	movb   $0xa,-0xd(%ebp)
  106e8a:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106e8e:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106e91:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
  106e92:	0f b7 05 30 c5 10 00 	movzwl 0x10c530,%eax
  106e99:	66 83 f8 ff          	cmp    $0xffff,%ax
  106e9d:	74 15                	je     106eb4 <pic_init+0x14c>
		pic_setmask(irqmask);
  106e9f:	0f b7 05 30 c5 10 00 	movzwl 0x10c530,%eax
  106ea6:	0f b7 c0             	movzwl %ax,%eax
  106ea9:	89 04 24             	mov    %eax,(%esp)
  106eac:	e8 05 00 00 00       	call   106eb6 <pic_setmask>
  106eb1:	eb 01                	jmp    106eb4 <pic_init+0x14c>
/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	if (didinit)		// only do once on bootstrap CPU
		return;
  106eb3:	90                   	nop
	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irqmask != 0xFFFF)
		pic_setmask(irqmask);
}
  106eb4:	c9                   	leave  
  106eb5:	c3                   	ret    

00106eb6 <pic_setmask>:

void
pic_setmask(uint16_t mask)
{
  106eb6:	55                   	push   %ebp
  106eb7:	89 e5                	mov    %esp,%ebp
  106eb9:	83 ec 14             	sub    $0x14,%esp
  106ebc:	8b 45 08             	mov    0x8(%ebp),%eax
  106ebf:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
	irqmask = mask;
  106ec3:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106ec7:	66 a3 30 c5 10 00    	mov    %ax,0x10c530
	outb(IO_PIC1+1, (char)mask);
  106ecd:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106ed1:	0f b6 c0             	movzbl %al,%eax
  106ed4:	c7 45 f4 21 00 00 00 	movl   $0x21,-0xc(%ebp)
  106edb:	88 45 f3             	mov    %al,-0xd(%ebp)
  106ede:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106ee2:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106ee5:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
  106ee6:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
  106eea:	66 c1 e8 08          	shr    $0x8,%ax
  106eee:	0f b6 c0             	movzbl %al,%eax
  106ef1:	c7 45 fc a1 00 00 00 	movl   $0xa1,-0x4(%ebp)
  106ef8:	88 45 fb             	mov    %al,-0x5(%ebp)
  106efb:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106eff:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106f02:	ee                   	out    %al,(%dx)
}
  106f03:	c9                   	leave  
  106f04:	c3                   	ret    

00106f05 <pic_enable>:

void
pic_enable(int irq)
{
  106f05:	55                   	push   %ebp
  106f06:	89 e5                	mov    %esp,%ebp
  106f08:	53                   	push   %ebx
  106f09:	83 ec 04             	sub    $0x4,%esp
	pic_setmask(irqmask & ~(1 << irq));
  106f0c:	8b 45 08             	mov    0x8(%ebp),%eax
  106f0f:	ba 01 00 00 00       	mov    $0x1,%edx
  106f14:	89 d3                	mov    %edx,%ebx
  106f16:	89 c1                	mov    %eax,%ecx
  106f18:	d3 e3                	shl    %cl,%ebx
  106f1a:	89 d8                	mov    %ebx,%eax
  106f1c:	89 c2                	mov    %eax,%edx
  106f1e:	f7 d2                	not    %edx
  106f20:	0f b7 05 30 c5 10 00 	movzwl 0x10c530,%eax
  106f27:	21 d0                	and    %edx,%eax
  106f29:	0f b7 c0             	movzwl %ax,%eax
  106f2c:	89 04 24             	mov    %eax,(%esp)
  106f2f:	e8 82 ff ff ff       	call   106eb6 <pic_setmask>
}
  106f34:	83 c4 04             	add    $0x4,%esp
  106f37:	5b                   	pop    %ebx
  106f38:	5d                   	pop    %ebp
  106f39:	c3                   	ret    
  106f3a:	90                   	nop
  106f3b:	90                   	nop

00106f3c <nvram_read>:
#include <dev/nvram.h>


unsigned
nvram_read(unsigned reg)
{
  106f3c:	55                   	push   %ebp
  106f3d:	89 e5                	mov    %esp,%ebp
  106f3f:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  106f42:	8b 45 08             	mov    0x8(%ebp),%eax
  106f45:	0f b6 c0             	movzbl %al,%eax
  106f48:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106f4f:	88 45 f3             	mov    %al,-0xd(%ebp)
  106f52:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106f56:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106f59:	ee                   	out    %al,(%dx)
  106f5a:	c7 45 f8 71 00 00 00 	movl   $0x71,-0x8(%ebp)

static gcc_inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
  106f61:	8b 45 f8             	mov    -0x8(%ebp),%eax
  106f64:	89 c2                	mov    %eax,%edx
  106f66:	ec                   	in     (%dx),%al
  106f67:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
  106f6a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	return inb(IO_RTC+1);
  106f6e:	0f b6 c0             	movzbl %al,%eax
}
  106f71:	c9                   	leave  
  106f72:	c3                   	ret    

00106f73 <nvram_read16>:

unsigned
nvram_read16(unsigned r)
{
  106f73:	55                   	push   %ebp
  106f74:	89 e5                	mov    %esp,%ebp
  106f76:	53                   	push   %ebx
  106f77:	83 ec 04             	sub    $0x4,%esp
	return nvram_read(r) | (nvram_read(r + 1) << 8);
  106f7a:	8b 45 08             	mov    0x8(%ebp),%eax
  106f7d:	89 04 24             	mov    %eax,(%esp)
  106f80:	e8 b7 ff ff ff       	call   106f3c <nvram_read>
  106f85:	89 c3                	mov    %eax,%ebx
  106f87:	8b 45 08             	mov    0x8(%ebp),%eax
  106f8a:	83 c0 01             	add    $0x1,%eax
  106f8d:	89 04 24             	mov    %eax,(%esp)
  106f90:	e8 a7 ff ff ff       	call   106f3c <nvram_read>
  106f95:	c1 e0 08             	shl    $0x8,%eax
  106f98:	09 d8                	or     %ebx,%eax
}
  106f9a:	83 c4 04             	add    $0x4,%esp
  106f9d:	5b                   	pop    %ebx
  106f9e:	5d                   	pop    %ebp
  106f9f:	c3                   	ret    

00106fa0 <nvram_write>:

void
nvram_write(unsigned reg, unsigned datum)
{
  106fa0:	55                   	push   %ebp
  106fa1:	89 e5                	mov    %esp,%ebp
  106fa3:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
  106fa6:	8b 45 08             	mov    0x8(%ebp),%eax
  106fa9:	0f b6 c0             	movzbl %al,%eax
  106fac:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  106fb3:	88 45 f3             	mov    %al,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  106fb6:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  106fba:	8b 55 f4             	mov    -0xc(%ebp),%edx
  106fbd:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
  106fbe:	8b 45 0c             	mov    0xc(%ebp),%eax
  106fc1:	0f b6 c0             	movzbl %al,%eax
  106fc4:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  106fcb:	88 45 fb             	mov    %al,-0x5(%ebp)
  106fce:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  106fd2:	8b 55 fc             	mov    -0x4(%ebp),%edx
  106fd5:	ee                   	out    %al,(%dx)
}
  106fd6:	c9                   	leave  
  106fd7:	c3                   	ret    

00106fd8 <cpu_cur>:
#define cpu_disabled(c)		0

// Find the CPU struct representing the current CPU.
// It always resides at the bottom of the page containing the CPU's stack.
static inline cpu *
cpu_cur() {
  106fd8:	55                   	push   %ebp
  106fd9:	89 e5                	mov    %esp,%ebp
  106fdb:	83 ec 28             	sub    $0x28,%esp

static gcc_inline uint32_t
read_esp(void)
{
        uint32_t esp;
        __asm __volatile("movl %%esp,%0" : "=rm" (esp));
  106fde:	89 65 f4             	mov    %esp,-0xc(%ebp)
        return esp;
  106fe1:	8b 45 f4             	mov    -0xc(%ebp),%eax
	cpu *c = (cpu*)ROUNDDOWN(read_esp(), PAGESIZE);
  106fe4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  106fe7:	8b 45 f0             	mov    -0x10(%ebp),%eax
  106fea:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  106fef:	89 45 ec             	mov    %eax,-0x14(%ebp)
	assert(c->magic == CPU_MAGIC);
  106ff2:	8b 45 ec             	mov    -0x14(%ebp),%eax
  106ff5:	8b 80 b8 00 00 00    	mov    0xb8(%eax),%eax
  106ffb:	3d 32 54 76 98       	cmp    $0x98765432,%eax
  107000:	74 24                	je     107026 <cpu_cur+0x4e>
  107002:	c7 44 24 0c 01 9e 10 	movl   $0x109e01,0xc(%esp)
  107009:	00 
  10700a:	c7 44 24 08 17 9e 10 	movl   $0x109e17,0x8(%esp)
  107011:	00 
  107012:	c7 44 24 04 5c 00 00 	movl   $0x5c,0x4(%esp)
  107019:	00 
  10701a:	c7 04 24 2c 9e 10 00 	movl   $0x109e2c,(%esp)
  107021:	e8 92 94 ff ff       	call   1004b8 <debug_panic>
	return c;
  107026:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
  107029:	c9                   	leave  
  10702a:	c3                   	ret    

0010702b <lapicw>:
volatile uint32_t *lapic;  // Initialized in mp.c


static void
lapicw(int index, int value)
{
  10702b:	55                   	push   %ebp
  10702c:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
  10702e:	a1 04 20 12 00       	mov    0x122004,%eax
  107033:	8b 55 08             	mov    0x8(%ebp),%edx
  107036:	c1 e2 02             	shl    $0x2,%edx
  107039:	8d 14 10             	lea    (%eax,%edx,1),%edx
  10703c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10703f:	89 02                	mov    %eax,(%edx)
	lapic[ID];  // wait for write to finish, by reading
  107041:	a1 04 20 12 00       	mov    0x122004,%eax
  107046:	83 c0 20             	add    $0x20,%eax
  107049:	8b 00                	mov    (%eax),%eax
}
  10704b:	5d                   	pop    %ebp
  10704c:	c3                   	ret    

0010704d <lapic_init>:

void
lapic_init()
{
  10704d:	55                   	push   %ebp
  10704e:	89 e5                	mov    %esp,%ebp
  107050:	83 ec 08             	sub    $0x8,%esp
	if (!lapic) 
  107053:	a1 04 20 12 00       	mov    0x122004,%eax
  107058:	85 c0                	test   %eax,%eax
  10705a:	0f 84 82 01 00 00    	je     1071e2 <lapic_init+0x195>
		return;

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
  107060:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
  107067:	00 
  107068:	c7 04 24 3c 00 00 00 	movl   $0x3c,(%esp)
  10706f:	e8 b7 ff ff ff       	call   10702b <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	lapicw(TDCR, X1);
  107074:	c7 44 24 04 0b 00 00 	movl   $0xb,0x4(%esp)
  10707b:	00 
  10707c:	c7 04 24 f8 00 00 00 	movl   $0xf8,(%esp)
  107083:	e8 a3 ff ff ff       	call   10702b <lapicw>
	lapicw(TIMER, PERIODIC | T_LTIMER);
  107088:	c7 44 24 04 31 00 02 	movl   $0x20031,0x4(%esp)
  10708f:	00 
  107090:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  107097:	e8 8f ff ff ff       	call   10702b <lapicw>

	// If we cared more about precise timekeeping,
	// we would calibrate TICR with another time source such as the PIT.
	lapicw(TICR, 10000000);
  10709c:	c7 44 24 04 80 96 98 	movl   $0x989680,0x4(%esp)
  1070a3:	00 
  1070a4:	c7 04 24 e0 00 00 00 	movl   $0xe0,(%esp)
  1070ab:	e8 7b ff ff ff       	call   10702b <lapicw>

	// Disable logical interrupt lines.
	lapicw(LINT0, MASKED);
  1070b0:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1070b7:	00 
  1070b8:	c7 04 24 d4 00 00 00 	movl   $0xd4,(%esp)
  1070bf:	e8 67 ff ff ff       	call   10702b <lapicw>
	lapicw(LINT1, MASKED);
  1070c4:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1070cb:	00 
  1070cc:	c7 04 24 d8 00 00 00 	movl   $0xd8,(%esp)
  1070d3:	e8 53 ff ff ff       	call   10702b <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
  1070d8:	a1 04 20 12 00       	mov    0x122004,%eax
  1070dd:	83 c0 30             	add    $0x30,%eax
  1070e0:	8b 00                	mov    (%eax),%eax
  1070e2:	c1 e8 10             	shr    $0x10,%eax
  1070e5:	25 ff 00 00 00       	and    $0xff,%eax
  1070ea:	83 f8 03             	cmp    $0x3,%eax
  1070ed:	76 14                	jbe    107103 <lapic_init+0xb6>
		lapicw(PCINT, MASKED);
  1070ef:	c7 44 24 04 00 00 01 	movl   $0x10000,0x4(%esp)
  1070f6:	00 
  1070f7:	c7 04 24 d0 00 00 00 	movl   $0xd0,(%esp)
  1070fe:	e8 28 ff ff ff       	call   10702b <lapicw>

	// Map other interrupts to appropriate vectors.
	lapicw(ERROR, T_LERROR);
  107103:	c7 44 24 04 32 00 00 	movl   $0x32,0x4(%esp)
  10710a:	00 
  10710b:	c7 04 24 dc 00 00 00 	movl   $0xdc,(%esp)
  107112:	e8 14 ff ff ff       	call   10702b <lapicw>

	// Set up to lowest-priority, "anycast" interrupts
	lapicw(LDR, 0xff << 24);	// Accept all interrupts
  107117:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  10711e:	ff 
  10711f:	c7 04 24 34 00 00 00 	movl   $0x34,(%esp)
  107126:	e8 00 ff ff ff       	call   10702b <lapicw>
	lapicw(DFR, 0xf << 28);		// Flat model
  10712b:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
  107132:	f0 
  107133:	c7 04 24 38 00 00 00 	movl   $0x38,(%esp)
  10713a:	e8 ec fe ff ff       	call   10702b <lapicw>
	lapicw(TPR, 0x00);		// Task priority 0, no intrs masked
  10713f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107146:	00 
  107147:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  10714e:	e8 d8 fe ff ff       	call   10702b <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
  107153:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10715a:	00 
  10715b:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107162:	e8 c4 fe ff ff       	call   10702b <lapicw>
	lapicw(ESR, 0);
  107167:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10716e:	00 
  10716f:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107176:	e8 b0 fe ff ff       	call   10702b <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
  10717b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107182:	00 
  107183:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  10718a:	e8 9c fe ff ff       	call   10702b <lapicw>

	// Send an Init Level De-Assert to synchronise arbitration ID's.
	lapicw(ICRHI, 0);
  10718f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107196:	00 
  107197:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  10719e:	e8 88 fe ff ff       	call   10702b <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
  1071a3:	c7 44 24 04 00 85 08 	movl   $0x88500,0x4(%esp)
  1071aa:	00 
  1071ab:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1071b2:	e8 74 fe ff ff       	call   10702b <lapicw>
	while(lapic[ICRLO] & DELIVS)
  1071b7:	a1 04 20 12 00       	mov    0x122004,%eax
  1071bc:	05 00 03 00 00       	add    $0x300,%eax
  1071c1:	8b 00                	mov    (%eax),%eax
  1071c3:	25 00 10 00 00       	and    $0x1000,%eax
  1071c8:	85 c0                	test   %eax,%eax
  1071ca:	75 eb                	jne    1071b7 <lapic_init+0x16a>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
  1071cc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1071d3:	00 
  1071d4:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  1071db:	e8 4b fe ff ff       	call   10702b <lapicw>
  1071e0:	eb 01                	jmp    1071e3 <lapic_init+0x196>

void
lapic_init()
{
	if (!lapic) 
		return;
  1071e2:	90                   	nop
	while(lapic[ICRLO] & DELIVS)
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
}
  1071e3:	c9                   	leave  
  1071e4:	c3                   	ret    

001071e5 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
  1071e5:	55                   	push   %ebp
  1071e6:	89 e5                	mov    %esp,%ebp
  1071e8:	83 ec 08             	sub    $0x8,%esp
	if (lapic)
  1071eb:	a1 04 20 12 00       	mov    0x122004,%eax
  1071f0:	85 c0                	test   %eax,%eax
  1071f2:	74 14                	je     107208 <lapic_eoi+0x23>
		lapicw(EOI, 0);
  1071f4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  1071fb:	00 
  1071fc:	c7 04 24 2c 00 00 00 	movl   $0x2c,(%esp)
  107203:	e8 23 fe ff ff       	call   10702b <lapicw>
}
  107208:	c9                   	leave  
  107209:	c3                   	ret    

0010720a <lapic_errintr>:

void lapic_errintr(void)
{
  10720a:	55                   	push   %ebp
  10720b:	89 e5                	mov    %esp,%ebp
  10720d:	53                   	push   %ebx
  10720e:	83 ec 24             	sub    $0x24,%esp
	lapic_eoi();	// Acknowledge interrupt
  107211:	e8 cf ff ff ff       	call   1071e5 <lapic_eoi>
	lapicw(ESR, 0);	// Trigger update of ESR by writing anything
  107216:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  10721d:	00 
  10721e:	c7 04 24 a0 00 00 00 	movl   $0xa0,(%esp)
  107225:	e8 01 fe ff ff       	call   10702b <lapicw>
	warn("CPU%d LAPIC error: ESR %x", cpu_cur()->id, lapic[ESR]);
  10722a:	a1 04 20 12 00       	mov    0x122004,%eax
  10722f:	05 80 02 00 00       	add    $0x280,%eax
  107234:	8b 18                	mov    (%eax),%ebx
  107236:	e8 9d fd ff ff       	call   106fd8 <cpu_cur>
  10723b:	0f b6 80 ac 00 00 00 	movzbl 0xac(%eax),%eax
  107242:	0f b6 c0             	movzbl %al,%eax
  107245:	89 5c 24 10          	mov    %ebx,0x10(%esp)
  107249:	89 44 24 0c          	mov    %eax,0xc(%esp)
  10724d:	c7 44 24 08 39 9e 10 	movl   $0x109e39,0x8(%esp)
  107254:	00 
  107255:	c7 44 24 04 60 00 00 	movl   $0x60,0x4(%esp)
  10725c:	00 
  10725d:	c7 04 24 53 9e 10 00 	movl   $0x109e53,(%esp)
  107264:	e8 0e 93 ff ff       	call   100577 <debug_warn>
}
  107269:	83 c4 24             	add    $0x24,%esp
  10726c:	5b                   	pop    %ebx
  10726d:	5d                   	pop    %ebp
  10726e:	c3                   	ret    

0010726f <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
  10726f:	55                   	push   %ebp
  107270:	89 e5                	mov    %esp,%ebp
}
  107272:	5d                   	pop    %ebp
  107273:	c3                   	ret    

00107274 <lapic_startcpu>:

// Start additional processor running bootstrap code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startcpu(uint8_t apicid, uint32_t addr)
{
  107274:	55                   	push   %ebp
  107275:	89 e5                	mov    %esp,%ebp
  107277:	83 ec 2c             	sub    $0x2c,%esp
  10727a:	8b 45 08             	mov    0x8(%ebp),%eax
  10727d:	88 45 dc             	mov    %al,-0x24(%ebp)
  107280:	c7 45 f4 70 00 00 00 	movl   $0x70,-0xc(%ebp)
  107287:	c6 45 f3 0f          	movb   $0xf,-0xd(%ebp)
}

static gcc_inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
  10728b:	0f b6 45 f3          	movzbl -0xd(%ebp),%eax
  10728f:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107292:	ee                   	out    %al,(%dx)
  107293:	c7 45 fc 71 00 00 00 	movl   $0x71,-0x4(%ebp)
  10729a:	c6 45 fb 0a          	movb   $0xa,-0x5(%ebp)
  10729e:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
  1072a2:	8b 55 fc             	mov    -0x4(%ebp),%edx
  1072a5:	ee                   	out    %al,(%dx)
	// "The BSP must initialize CMOS shutdown code to 0AH
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t*)(0x40<<4 | 0x67);  // Warm reset vector
  1072a6:	c7 45 ec 67 04 00 00 	movl   $0x467,-0x14(%ebp)
	wrv[0] = 0;
  1072ad:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1072b0:	66 c7 00 00 00       	movw   $0x0,(%eax)
	wrv[1] = addr >> 4;
  1072b5:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1072b8:	8d 50 02             	lea    0x2(%eax),%edx
  1072bb:	8b 45 0c             	mov    0xc(%ebp),%eax
  1072be:	c1 e8 04             	shr    $0x4,%eax
  1072c1:	66 89 02             	mov    %ax,(%edx)

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid<<24);
  1072c4:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  1072c8:	c1 e0 18             	shl    $0x18,%eax
  1072cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  1072cf:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  1072d6:	e8 50 fd ff ff       	call   10702b <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
  1072db:	c7 44 24 04 00 c5 00 	movl   $0xc500,0x4(%esp)
  1072e2:	00 
  1072e3:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  1072ea:	e8 3c fd ff ff       	call   10702b <lapicw>
	microdelay(200);
  1072ef:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  1072f6:	e8 74 ff ff ff       	call   10726f <microdelay>
	lapicw(ICRLO, INIT | LEVEL);
  1072fb:	c7 44 24 04 00 85 00 	movl   $0x8500,0x4(%esp)
  107302:	00 
  107303:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10730a:	e8 1c fd ff ff       	call   10702b <lapicw>
	microdelay(100);    // should be 10ms, but too slow in Bochs!
  10730f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
  107316:	e8 54 ff ff ff       	call   10726f <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  10731b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
  107322:	eb 40                	jmp    107364 <lapic_startcpu+0xf0>
		lapicw(ICRHI, apicid<<24);
  107324:	0f b6 45 dc          	movzbl -0x24(%ebp),%eax
  107328:	c1 e0 18             	shl    $0x18,%eax
  10732b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10732f:	c7 04 24 c4 00 00 00 	movl   $0xc4,(%esp)
  107336:	e8 f0 fc ff ff       	call   10702b <lapicw>
		lapicw(ICRLO, STARTUP | (addr>>12));
  10733b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10733e:	c1 e8 0c             	shr    $0xc,%eax
  107341:	80 cc 06             	or     $0x6,%ah
  107344:	89 44 24 04          	mov    %eax,0x4(%esp)
  107348:	c7 04 24 c0 00 00 00 	movl   $0xc0,(%esp)
  10734f:	e8 d7 fc ff ff       	call   10702b <lapicw>
		microdelay(200);
  107354:	c7 04 24 c8 00 00 00 	movl   $0xc8,(%esp)
  10735b:	e8 0f ff ff ff       	call   10726f <microdelay>
	// Send startup IPI (twice!) to enter bootstrap code.
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for(i = 0; i < 2; i++){
  107360:	83 45 e8 01          	addl   $0x1,-0x18(%ebp)
  107364:	83 7d e8 01          	cmpl   $0x1,-0x18(%ebp)
  107368:	7e ba                	jle    107324 <lapic_startcpu+0xb0>
		lapicw(ICRHI, apicid<<24);
		lapicw(ICRLO, STARTUP | (addr>>12));
		microdelay(200);
	}
}
  10736a:	c9                   	leave  
  10736b:	c3                   	ret    

0010736c <ioapic_read>:
	uint32_t data;
};

static uint32_t
ioapic_read(int reg)
{
  10736c:	55                   	push   %ebp
  10736d:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  10736f:	a1 2c ed 11 00       	mov    0x11ed2c,%eax
  107374:	8b 55 08             	mov    0x8(%ebp),%edx
  107377:	89 10                	mov    %edx,(%eax)
	return ioapic->data;
  107379:	a1 2c ed 11 00       	mov    0x11ed2c,%eax
  10737e:	8b 40 10             	mov    0x10(%eax),%eax
}
  107381:	5d                   	pop    %ebp
  107382:	c3                   	ret    

00107383 <ioapic_write>:

static void
ioapic_write(int reg, uint32_t data)
{
  107383:	55                   	push   %ebp
  107384:	89 e5                	mov    %esp,%ebp
	ioapic->reg = reg;
  107386:	a1 2c ed 11 00       	mov    0x11ed2c,%eax
  10738b:	8b 55 08             	mov    0x8(%ebp),%edx
  10738e:	89 10                	mov    %edx,(%eax)
	ioapic->data = data;
  107390:	a1 2c ed 11 00       	mov    0x11ed2c,%eax
  107395:	8b 55 0c             	mov    0xc(%ebp),%edx
  107398:	89 50 10             	mov    %edx,0x10(%eax)
}
  10739b:	5d                   	pop    %ebp
  10739c:	c3                   	ret    

0010739d <ioapic_init>:

void
ioapic_init(void)
{
  10739d:	55                   	push   %ebp
  10739e:	89 e5                	mov    %esp,%ebp
  1073a0:	83 ec 38             	sub    $0x38,%esp
	int i, id, maxintr;

	if(!ismp)
  1073a3:	a1 30 ed 11 00       	mov    0x11ed30,%eax
  1073a8:	85 c0                	test   %eax,%eax
  1073aa:	0f 84 fd 00 00 00    	je     1074ad <ioapic_init+0x110>
		return;

	if (ioapic == NULL)
  1073b0:	a1 2c ed 11 00       	mov    0x11ed2c,%eax
  1073b5:	85 c0                	test   %eax,%eax
  1073b7:	75 0a                	jne    1073c3 <ioapic_init+0x26>
		ioapic = mem_ptr(IOAPIC);	// assume default address
  1073b9:	c7 05 2c ed 11 00 00 	movl   $0xfec00000,0x11ed2c
  1073c0:	00 c0 fe 

	maxintr = (ioapic_read(REG_VER) >> 16) & 0xFF;
  1073c3:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
  1073ca:	e8 9d ff ff ff       	call   10736c <ioapic_read>
  1073cf:	c1 e8 10             	shr    $0x10,%eax
  1073d2:	25 ff 00 00 00       	and    $0xff,%eax
  1073d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	id = ioapic_read(REG_ID) >> 24;
  1073da:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  1073e1:	e8 86 ff ff ff       	call   10736c <ioapic_read>
  1073e6:	c1 e8 18             	shr    $0x18,%eax
  1073e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (id == 0) {
  1073ec:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  1073f0:	75 2a                	jne    10741c <ioapic_init+0x7f>
		// I/O APIC ID not initialized yet - have to do it ourselves.
		ioapic_write(REG_ID, ioapicid << 24);
  1073f2:	0f b6 05 28 ed 11 00 	movzbl 0x11ed28,%eax
  1073f9:	0f b6 c0             	movzbl %al,%eax
  1073fc:	c1 e0 18             	shl    $0x18,%eax
  1073ff:	89 44 24 04          	mov    %eax,0x4(%esp)
  107403:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  10740a:	e8 74 ff ff ff       	call   107383 <ioapic_write>
		id = ioapicid;
  10740f:	0f b6 05 28 ed 11 00 	movzbl 0x11ed28,%eax
  107416:	0f b6 c0             	movzbl %al,%eax
  107419:	89 45 f0             	mov    %eax,-0x10(%ebp)
	}
	if (id != ioapicid)
  10741c:	0f b6 05 28 ed 11 00 	movzbl 0x11ed28,%eax
  107423:	0f b6 c0             	movzbl %al,%eax
  107426:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107429:	74 31                	je     10745c <ioapic_init+0xbf>
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);
  10742b:	0f b6 05 28 ed 11 00 	movzbl 0x11ed28,%eax
  107432:	0f b6 c0             	movzbl %al,%eax
  107435:	89 44 24 10          	mov    %eax,0x10(%esp)
  107439:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10743c:	89 44 24 0c          	mov    %eax,0xc(%esp)
  107440:	c7 44 24 08 60 9e 10 	movl   $0x109e60,0x8(%esp)
  107447:	00 
  107448:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
  10744f:	00 
  107450:	c7 04 24 81 9e 10 00 	movl   $0x109e81,(%esp)
  107457:	e8 1b 91 ff ff       	call   100577 <debug_warn>

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10745c:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  107463:	eb 3e                	jmp    1074a3 <ioapic_init+0x106>
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
  107465:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107468:	83 c0 20             	add    $0x20,%eax
  10746b:	0d 00 00 01 00       	or     $0x10000,%eax
  107470:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107473:	83 c2 08             	add    $0x8,%edx
  107476:	01 d2                	add    %edx,%edx
  107478:	89 44 24 04          	mov    %eax,0x4(%esp)
  10747c:	89 14 24             	mov    %edx,(%esp)
  10747f:	e8 ff fe ff ff       	call   107383 <ioapic_write>
		ioapic_write(REG_TABLE+2*i+1, 0);
  107484:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107487:	83 c0 08             	add    $0x8,%eax
  10748a:	01 c0                	add    %eax,%eax
  10748c:	83 c0 01             	add    $0x1,%eax
  10748f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107496:	00 
  107497:	89 04 24             	mov    %eax,(%esp)
  10749a:	e8 e4 fe ff ff       	call   107383 <ioapic_write>
	if (id != ioapicid)
		warn("ioapicinit: id %d != ioapicid %d", id, ioapicid);

	// Mark all interrupts edge-triggered, active high, disabled,
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
  10749f:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
  1074a3:	8b 45 ec             	mov    -0x14(%ebp),%eax
  1074a6:	3b 45 f4             	cmp    -0xc(%ebp),%eax
  1074a9:	7e ba                	jle    107465 <ioapic_init+0xc8>
  1074ab:	eb 01                	jmp    1074ae <ioapic_init+0x111>
ioapic_init(void)
{
	int i, id, maxintr;

	if(!ismp)
		return;
  1074ad:	90                   	nop
	// and not routed to any CPUs.
	for (i = 0; i <= maxintr; i++){
		ioapic_write(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
		ioapic_write(REG_TABLE+2*i+1, 0);
	}
}
  1074ae:	c9                   	leave  
  1074af:	c3                   	ret    

001074b0 <ioapic_enable>:

void
ioapic_enable(int irq)
{
  1074b0:	55                   	push   %ebp
  1074b1:	89 e5                	mov    %esp,%ebp
  1074b3:	83 ec 08             	sub    $0x8,%esp
	if (!ismp)
  1074b6:	a1 30 ed 11 00       	mov    0x11ed30,%eax
  1074bb:	85 c0                	test   %eax,%eax
  1074bd:	74 3a                	je     1074f9 <ioapic_enable+0x49>
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
  1074bf:	8b 45 08             	mov    0x8(%ebp),%eax
  1074c2:	83 c0 20             	add    $0x20,%eax
  1074c5:	80 cc 09             	or     $0x9,%ah
	if (!ismp)
		return;

	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
  1074c8:	8b 55 08             	mov    0x8(%ebp),%edx
  1074cb:	83 c2 08             	add    $0x8,%edx
  1074ce:	01 d2                	add    %edx,%edx
  1074d0:	89 44 24 04          	mov    %eax,0x4(%esp)
  1074d4:	89 14 24             	mov    %edx,(%esp)
  1074d7:	e8 a7 fe ff ff       	call   107383 <ioapic_write>
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
  1074dc:	8b 45 08             	mov    0x8(%ebp),%eax
  1074df:	83 c0 08             	add    $0x8,%eax
  1074e2:	01 c0                	add    %eax,%eax
  1074e4:	83 c0 01             	add    $0x1,%eax
  1074e7:	c7 44 24 04 00 00 00 	movl   $0xff000000,0x4(%esp)
  1074ee:	ff 
  1074ef:	89 04 24             	mov    %eax,(%esp)
  1074f2:	e8 8c fe ff ff       	call   107383 <ioapic_write>
  1074f7:	eb 01                	jmp    1074fa <ioapic_enable+0x4a>

void
ioapic_enable(int irq)
{
	if (!ismp)
		return;
  1074f9:	90                   	nop
	// Mark interrupt edge-triggered, active high,
	// enabled, and routed to any CPU.
	ioapic_write(REG_TABLE+2*irq,
			INT_LOGICAL | INT_LOWEST | (T_IRQ0 + irq));
	ioapic_write(REG_TABLE+2*irq+1, 0xff << 24);
}
  1074fa:	c9                   	leave  
  1074fb:	c3                   	ret    

001074fc <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static uintmax_t
getuint(printstate *st, va_list *ap)
{
  1074fc:	55                   	push   %ebp
  1074fd:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  1074ff:	8b 45 08             	mov    0x8(%ebp),%eax
  107502:	8b 40 18             	mov    0x18(%eax),%eax
  107505:	83 e0 02             	and    $0x2,%eax
  107508:	85 c0                	test   %eax,%eax
  10750a:	74 1c                	je     107528 <getuint+0x2c>
		return va_arg(*ap, unsigned long long);
  10750c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10750f:	8b 00                	mov    (%eax),%eax
  107511:	8d 50 08             	lea    0x8(%eax),%edx
  107514:	8b 45 0c             	mov    0xc(%ebp),%eax
  107517:	89 10                	mov    %edx,(%eax)
  107519:	8b 45 0c             	mov    0xc(%ebp),%eax
  10751c:	8b 00                	mov    (%eax),%eax
  10751e:	83 e8 08             	sub    $0x8,%eax
  107521:	8b 50 04             	mov    0x4(%eax),%edx
  107524:	8b 00                	mov    (%eax),%eax
  107526:	eb 47                	jmp    10756f <getuint+0x73>
	else if (st->flags & F_L)
  107528:	8b 45 08             	mov    0x8(%ebp),%eax
  10752b:	8b 40 18             	mov    0x18(%eax),%eax
  10752e:	83 e0 01             	and    $0x1,%eax
  107531:	84 c0                	test   %al,%al
  107533:	74 1e                	je     107553 <getuint+0x57>
		return va_arg(*ap, unsigned long);
  107535:	8b 45 0c             	mov    0xc(%ebp),%eax
  107538:	8b 00                	mov    (%eax),%eax
  10753a:	8d 50 04             	lea    0x4(%eax),%edx
  10753d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107540:	89 10                	mov    %edx,(%eax)
  107542:	8b 45 0c             	mov    0xc(%ebp),%eax
  107545:	8b 00                	mov    (%eax),%eax
  107547:	83 e8 04             	sub    $0x4,%eax
  10754a:	8b 00                	mov    (%eax),%eax
  10754c:	ba 00 00 00 00       	mov    $0x0,%edx
  107551:	eb 1c                	jmp    10756f <getuint+0x73>
	else
		return va_arg(*ap, unsigned int);
  107553:	8b 45 0c             	mov    0xc(%ebp),%eax
  107556:	8b 00                	mov    (%eax),%eax
  107558:	8d 50 04             	lea    0x4(%eax),%edx
  10755b:	8b 45 0c             	mov    0xc(%ebp),%eax
  10755e:	89 10                	mov    %edx,(%eax)
  107560:	8b 45 0c             	mov    0xc(%ebp),%eax
  107563:	8b 00                	mov    (%eax),%eax
  107565:	83 e8 04             	sub    $0x4,%eax
  107568:	8b 00                	mov    (%eax),%eax
  10756a:	ba 00 00 00 00       	mov    $0x0,%edx
}
  10756f:	5d                   	pop    %ebp
  107570:	c3                   	ret    

00107571 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static intmax_t
getint(printstate *st, va_list *ap)
{
  107571:	55                   	push   %ebp
  107572:	89 e5                	mov    %esp,%ebp
	if (st->flags & F_LL)
  107574:	8b 45 08             	mov    0x8(%ebp),%eax
  107577:	8b 40 18             	mov    0x18(%eax),%eax
  10757a:	83 e0 02             	and    $0x2,%eax
  10757d:	85 c0                	test   %eax,%eax
  10757f:	74 1c                	je     10759d <getint+0x2c>
		return va_arg(*ap, long long);
  107581:	8b 45 0c             	mov    0xc(%ebp),%eax
  107584:	8b 00                	mov    (%eax),%eax
  107586:	8d 50 08             	lea    0x8(%eax),%edx
  107589:	8b 45 0c             	mov    0xc(%ebp),%eax
  10758c:	89 10                	mov    %edx,(%eax)
  10758e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107591:	8b 00                	mov    (%eax),%eax
  107593:	83 e8 08             	sub    $0x8,%eax
  107596:	8b 50 04             	mov    0x4(%eax),%edx
  107599:	8b 00                	mov    (%eax),%eax
  10759b:	eb 47                	jmp    1075e4 <getint+0x73>
	else if (st->flags & F_L)
  10759d:	8b 45 08             	mov    0x8(%ebp),%eax
  1075a0:	8b 40 18             	mov    0x18(%eax),%eax
  1075a3:	83 e0 01             	and    $0x1,%eax
  1075a6:	84 c0                	test   %al,%al
  1075a8:	74 1e                	je     1075c8 <getint+0x57>
		return va_arg(*ap, long);
  1075aa:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075ad:	8b 00                	mov    (%eax),%eax
  1075af:	8d 50 04             	lea    0x4(%eax),%edx
  1075b2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075b5:	89 10                	mov    %edx,(%eax)
  1075b7:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075ba:	8b 00                	mov    (%eax),%eax
  1075bc:	83 e8 04             	sub    $0x4,%eax
  1075bf:	8b 00                	mov    (%eax),%eax
  1075c1:	89 c2                	mov    %eax,%edx
  1075c3:	c1 fa 1f             	sar    $0x1f,%edx
  1075c6:	eb 1c                	jmp    1075e4 <getint+0x73>
	else
		return va_arg(*ap, int);
  1075c8:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075cb:	8b 00                	mov    (%eax),%eax
  1075cd:	8d 50 04             	lea    0x4(%eax),%edx
  1075d0:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075d3:	89 10                	mov    %edx,(%eax)
  1075d5:	8b 45 0c             	mov    0xc(%ebp),%eax
  1075d8:	8b 00                	mov    (%eax),%eax
  1075da:	83 e8 04             	sub    $0x4,%eax
  1075dd:	8b 00                	mov    (%eax),%eax
  1075df:	89 c2                	mov    %eax,%edx
  1075e1:	c1 fa 1f             	sar    $0x1f,%edx
}
  1075e4:	5d                   	pop    %ebp
  1075e5:	c3                   	ret    

001075e6 <putpad>:

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
  1075e6:	55                   	push   %ebp
  1075e7:	89 e5                	mov    %esp,%ebp
  1075e9:	83 ec 18             	sub    $0x18,%esp
	while (--st->width >= 0)
  1075ec:	eb 1a                	jmp    107608 <putpad+0x22>
		st->putch(st->padc, st->putdat);
  1075ee:	8b 45 08             	mov    0x8(%ebp),%eax
  1075f1:	8b 08                	mov    (%eax),%ecx
  1075f3:	8b 45 08             	mov    0x8(%ebp),%eax
  1075f6:	8b 50 04             	mov    0x4(%eax),%edx
  1075f9:	8b 45 08             	mov    0x8(%ebp),%eax
  1075fc:	8b 40 08             	mov    0x8(%eax),%eax
  1075ff:	89 54 24 04          	mov    %edx,0x4(%esp)
  107603:	89 04 24             	mov    %eax,(%esp)
  107606:	ff d1                	call   *%ecx

// Print padding characters, and an optional sign before a number.
static void
putpad(printstate *st)
{
	while (--st->width >= 0)
  107608:	8b 45 08             	mov    0x8(%ebp),%eax
  10760b:	8b 40 0c             	mov    0xc(%eax),%eax
  10760e:	8d 50 ff             	lea    -0x1(%eax),%edx
  107611:	8b 45 08             	mov    0x8(%ebp),%eax
  107614:	89 50 0c             	mov    %edx,0xc(%eax)
  107617:	8b 45 08             	mov    0x8(%ebp),%eax
  10761a:	8b 40 0c             	mov    0xc(%eax),%eax
  10761d:	85 c0                	test   %eax,%eax
  10761f:	79 cd                	jns    1075ee <putpad+0x8>
		st->putch(st->padc, st->putdat);
}
  107621:	c9                   	leave  
  107622:	c3                   	ret    

00107623 <putstr>:

// Print a string with a specified maximum length (-1=unlimited),
// with any appropriate left or right field padding.
static void
putstr(printstate *st, const char *str, int maxlen)
{
  107623:	55                   	push   %ebp
  107624:	89 e5                	mov    %esp,%ebp
  107626:	53                   	push   %ebx
  107627:	83 ec 24             	sub    $0x24,%esp
	const char *lim;		// find where the string actually ends
	if (maxlen < 0)
  10762a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10762e:	79 18                	jns    107648 <putstr+0x25>
		lim = strchr(str, 0);	// find the terminating null
  107630:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107637:	00 
  107638:	8b 45 0c             	mov    0xc(%ebp),%eax
  10763b:	89 04 24             	mov    %eax,(%esp)
  10763e:	e8 e9 07 00 00       	call   107e2c <strchr>
  107643:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107646:	eb 2c                	jmp    107674 <putstr+0x51>
	else if ((lim = memchr(str, 0, maxlen)) == NULL)
  107648:	8b 45 10             	mov    0x10(%ebp),%eax
  10764b:	89 44 24 08          	mov    %eax,0x8(%esp)
  10764f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
  107656:	00 
  107657:	8b 45 0c             	mov    0xc(%ebp),%eax
  10765a:	89 04 24             	mov    %eax,(%esp)
  10765d:	e8 ce 09 00 00       	call   108030 <memchr>
  107662:	89 45 f0             	mov    %eax,-0x10(%ebp)
  107665:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
  107669:	75 09                	jne    107674 <putstr+0x51>
		lim = str + maxlen;
  10766b:	8b 45 10             	mov    0x10(%ebp),%eax
  10766e:	03 45 0c             	add    0xc(%ebp),%eax
  107671:	89 45 f0             	mov    %eax,-0x10(%ebp)
	st->width -= (lim-str);		// deduct string length from field width
  107674:	8b 45 08             	mov    0x8(%ebp),%eax
  107677:	8b 40 0c             	mov    0xc(%eax),%eax
  10767a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  10767d:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107680:	89 cb                	mov    %ecx,%ebx
  107682:	29 d3                	sub    %edx,%ebx
  107684:	89 da                	mov    %ebx,%edx
  107686:	8d 14 10             	lea    (%eax,%edx,1),%edx
  107689:	8b 45 08             	mov    0x8(%ebp),%eax
  10768c:	89 50 0c             	mov    %edx,0xc(%eax)

	if (!(st->flags & F_RPAD))	// print left-side padding
  10768f:	8b 45 08             	mov    0x8(%ebp),%eax
  107692:	8b 40 18             	mov    0x18(%eax),%eax
  107695:	83 e0 10             	and    $0x10,%eax
  107698:	85 c0                	test   %eax,%eax
  10769a:	75 32                	jne    1076ce <putstr+0xab>
		putpad(st);		// (also leaves st->width == 0)
  10769c:	8b 45 08             	mov    0x8(%ebp),%eax
  10769f:	89 04 24             	mov    %eax,(%esp)
  1076a2:	e8 3f ff ff ff       	call   1075e6 <putpad>
	while (str < lim) {
  1076a7:	eb 25                	jmp    1076ce <putstr+0xab>
		char ch = *str++;
  1076a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076ac:	0f b6 00             	movzbl (%eax),%eax
  1076af:	88 45 f7             	mov    %al,-0x9(%ebp)
  1076b2:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
			st->putch(ch, st->putdat);
  1076b6:	8b 45 08             	mov    0x8(%ebp),%eax
  1076b9:	8b 08                	mov    (%eax),%ecx
  1076bb:	8b 45 08             	mov    0x8(%ebp),%eax
  1076be:	8b 50 04             	mov    0x4(%eax),%edx
  1076c1:	0f be 45 f7          	movsbl -0x9(%ebp),%eax
  1076c5:	89 54 24 04          	mov    %edx,0x4(%esp)
  1076c9:	89 04 24             	mov    %eax,(%esp)
  1076cc:	ff d1                	call   *%ecx
		lim = str + maxlen;
	st->width -= (lim-str);		// deduct string length from field width

	if (!(st->flags & F_RPAD))	// print left-side padding
		putpad(st);		// (also leaves st->width == 0)
	while (str < lim) {
  1076ce:	8b 45 0c             	mov    0xc(%ebp),%eax
  1076d1:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  1076d4:	72 d3                	jb     1076a9 <putstr+0x86>
		char ch = *str++;
			st->putch(ch, st->putdat);
	}
	putpad(st);			// print right-side padding
  1076d6:	8b 45 08             	mov    0x8(%ebp),%eax
  1076d9:	89 04 24             	mov    %eax,(%esp)
  1076dc:	e8 05 ff ff ff       	call   1075e6 <putpad>
}
  1076e1:	83 c4 24             	add    $0x24,%esp
  1076e4:	5b                   	pop    %ebx
  1076e5:	5d                   	pop    %ebp
  1076e6:	c3                   	ret    

001076e7 <genint>:

// Generate a number (base <= 16) in reverse order into a string buffer.
static char *
genint(printstate *st, char *p, uintmax_t num)
{
  1076e7:	55                   	push   %ebp
  1076e8:	89 e5                	mov    %esp,%ebp
  1076ea:	53                   	push   %ebx
  1076eb:	83 ec 24             	sub    $0x24,%esp
  1076ee:	8b 45 10             	mov    0x10(%ebp),%eax
  1076f1:	89 45 f0             	mov    %eax,-0x10(%ebp)
  1076f4:	8b 45 14             	mov    0x14(%ebp),%eax
  1076f7:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= st->base)
  1076fa:	8b 45 08             	mov    0x8(%ebp),%eax
  1076fd:	8b 40 1c             	mov    0x1c(%eax),%eax
  107700:	89 c2                	mov    %eax,%edx
  107702:	c1 fa 1f             	sar    $0x1f,%edx
  107705:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  107708:	77 4e                	ja     107758 <genint+0x71>
  10770a:	3b 55 f4             	cmp    -0xc(%ebp),%edx
  10770d:	72 05                	jb     107714 <genint+0x2d>
  10770f:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107712:	77 44                	ja     107758 <genint+0x71>
		p = genint(st, p, num / st->base);	// output higher digits
  107714:	8b 45 08             	mov    0x8(%ebp),%eax
  107717:	8b 40 1c             	mov    0x1c(%eax),%eax
  10771a:	89 c2                	mov    %eax,%edx
  10771c:	c1 fa 1f             	sar    $0x1f,%edx
  10771f:	89 44 24 08          	mov    %eax,0x8(%esp)
  107723:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107727:	8b 45 f0             	mov    -0x10(%ebp),%eax
  10772a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  10772d:	89 04 24             	mov    %eax,(%esp)
  107730:	89 54 24 04          	mov    %edx,0x4(%esp)
  107734:	e8 37 09 00 00       	call   108070 <__udivdi3>
  107739:	89 44 24 08          	mov    %eax,0x8(%esp)
  10773d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107741:	8b 45 0c             	mov    0xc(%ebp),%eax
  107744:	89 44 24 04          	mov    %eax,0x4(%esp)
  107748:	8b 45 08             	mov    0x8(%ebp),%eax
  10774b:	89 04 24             	mov    %eax,(%esp)
  10774e:	e8 94 ff ff ff       	call   1076e7 <genint>
  107753:	89 45 0c             	mov    %eax,0xc(%ebp)
  107756:	eb 1b                	jmp    107773 <genint+0x8c>
	else if (st->signc >= 0)
  107758:	8b 45 08             	mov    0x8(%ebp),%eax
  10775b:	8b 40 14             	mov    0x14(%eax),%eax
  10775e:	85 c0                	test   %eax,%eax
  107760:	78 11                	js     107773 <genint+0x8c>
		*p++ = st->signc;			// output leading sign
  107762:	8b 45 08             	mov    0x8(%ebp),%eax
  107765:	8b 40 14             	mov    0x14(%eax),%eax
  107768:	89 c2                	mov    %eax,%edx
  10776a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10776d:	88 10                	mov    %dl,(%eax)
  10776f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	*p++ = "0123456789abcdef"[num % st->base];	// output this digit
  107773:	8b 45 08             	mov    0x8(%ebp),%eax
  107776:	8b 40 1c             	mov    0x1c(%eax),%eax
  107779:	89 c1                	mov    %eax,%ecx
  10777b:	89 c3                	mov    %eax,%ebx
  10777d:	c1 fb 1f             	sar    $0x1f,%ebx
  107780:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107783:	8b 55 f4             	mov    -0xc(%ebp),%edx
  107786:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  10778a:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  10778e:	89 04 24             	mov    %eax,(%esp)
  107791:	89 54 24 04          	mov    %edx,0x4(%esp)
  107795:	e8 06 0a 00 00       	call   1081a0 <__umoddi3>
  10779a:	05 90 9e 10 00       	add    $0x109e90,%eax
  10779f:	0f b6 10             	movzbl (%eax),%edx
  1077a2:	8b 45 0c             	mov    0xc(%ebp),%eax
  1077a5:	88 10                	mov    %dl,(%eax)
  1077a7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
	return p;
  1077ab:	8b 45 0c             	mov    0xc(%ebp),%eax
}
  1077ae:	83 c4 24             	add    $0x24,%esp
  1077b1:	5b                   	pop    %ebx
  1077b2:	5d                   	pop    %ebp
  1077b3:	c3                   	ret    

001077b4 <putint>:

// Print an integer with any appropriate field padding.
static void
putint(printstate *st, uintmax_t num, int base)
{
  1077b4:	55                   	push   %ebp
  1077b5:	89 e5                	mov    %esp,%ebp
  1077b7:	83 ec 58             	sub    $0x58,%esp
  1077ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  1077bd:	89 45 c0             	mov    %eax,-0x40(%ebp)
  1077c0:	8b 45 10             	mov    0x10(%ebp),%eax
  1077c3:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	char buf[30], *p = buf;		// big enough for any 64-bit int in octal
  1077c6:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1077c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
	st->base = base;		// select base for genint
  1077cc:	8b 45 08             	mov    0x8(%ebp),%eax
  1077cf:	8b 55 14             	mov    0x14(%ebp),%edx
  1077d2:	89 50 1c             	mov    %edx,0x1c(%eax)
	p = genint(st, p, num);		// output to the string buffer
  1077d5:	8b 45 c0             	mov    -0x40(%ebp),%eax
  1077d8:	8b 55 c4             	mov    -0x3c(%ebp),%edx
  1077db:	89 44 24 08          	mov    %eax,0x8(%esp)
  1077df:	89 54 24 0c          	mov    %edx,0xc(%esp)
  1077e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1077e6:	89 44 24 04          	mov    %eax,0x4(%esp)
  1077ea:	8b 45 08             	mov    0x8(%ebp),%eax
  1077ed:	89 04 24             	mov    %eax,(%esp)
  1077f0:	e8 f2 fe ff ff       	call   1076e7 <genint>
  1077f5:	89 45 f4             	mov    %eax,-0xc(%ebp)
	putstr(st, buf, p-buf);		// print it with left/right padding
  1077f8:	8b 55 f4             	mov    -0xc(%ebp),%edx
  1077fb:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  1077fe:	89 d1                	mov    %edx,%ecx
  107800:	29 c1                	sub    %eax,%ecx
  107802:	89 c8                	mov    %ecx,%eax
  107804:	89 44 24 08          	mov    %eax,0x8(%esp)
  107808:	8d 45 d6             	lea    -0x2a(%ebp),%eax
  10780b:	89 44 24 04          	mov    %eax,0x4(%esp)
  10780f:	8b 45 08             	mov    0x8(%ebp),%eax
  107812:	89 04 24             	mov    %eax,(%esp)
  107815:	e8 09 fe ff ff       	call   107623 <putstr>
}
  10781a:	c9                   	leave  
  10781b:	c3                   	ret    

0010781c <vprintfmt>:


// Main function to format and print a string.
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  10781c:	55                   	push   %ebp
  10781d:	89 e5                	mov    %esp,%ebp
  10781f:	53                   	push   %ebx
  107820:	83 ec 44             	sub    $0x44,%esp
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
  107823:	8d 55 c8             	lea    -0x38(%ebp),%edx
  107826:	b9 00 00 00 00       	mov    $0x0,%ecx
  10782b:	b8 20 00 00 00       	mov    $0x20,%eax
  107830:	89 c3                	mov    %eax,%ebx
  107832:	83 e3 fc             	and    $0xfffffffc,%ebx
  107835:	b8 00 00 00 00       	mov    $0x0,%eax
  10783a:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
  10783d:	83 c0 04             	add    $0x4,%eax
  107840:	39 d8                	cmp    %ebx,%eax
  107842:	72 f6                	jb     10783a <vprintfmt+0x1e>
  107844:	01 c2                	add    %eax,%edx
  107846:	8b 45 08             	mov    0x8(%ebp),%eax
  107849:	89 45 c8             	mov    %eax,-0x38(%ebp)
  10784c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10784f:	89 45 cc             	mov    %eax,-0x34(%ebp)
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107852:	eb 17                	jmp    10786b <vprintfmt+0x4f>
			if (ch == '\0')
  107854:	85 db                	test   %ebx,%ebx
  107856:	0f 84 52 03 00 00    	je     107bae <vprintfmt+0x392>
				return;
			putch(ch, putdat);
  10785c:	8b 45 0c             	mov    0xc(%ebp),%eax
  10785f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107863:	89 1c 24             	mov    %ebx,(%esp)
  107866:	8b 45 08             	mov    0x8(%ebp),%eax
  107869:	ff d0                	call   *%eax
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  10786b:	8b 45 10             	mov    0x10(%ebp),%eax
  10786e:	0f b6 00             	movzbl (%eax),%eax
  107871:	0f b6 d8             	movzbl %al,%ebx
  107874:	83 fb 25             	cmp    $0x25,%ebx
  107877:	0f 95 c0             	setne  %al
  10787a:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  10787e:	84 c0                	test   %al,%al
  107880:	75 d2                	jne    107854 <vprintfmt+0x38>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		st.padc = ' ';
  107882:	c7 45 d0 20 00 00 00 	movl   $0x20,-0x30(%ebp)
		st.width = -1;
  107889:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		st.prec = -1;
  107890:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
		st.signc = -1;
  107897:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		st.flags = 0;
  10789e:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
		st.base = 10;
  1078a5:	c7 45 e4 0a 00 00 00 	movl   $0xa,-0x1c(%ebp)
  1078ac:	eb 04                	jmp    1078b2 <vprintfmt+0x96>
			goto reswitch;

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
				st.signc = ' ';
			goto reswitch;
  1078ae:	90                   	nop
  1078af:	eb 01                	jmp    1078b2 <vprintfmt+0x96>
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
				st.width = st.prec;	// then it's a field width
				st.prec = -1;
			}
			goto reswitch;
  1078b1:	90                   	nop
		st.signc = -1;
		st.flags = 0;
		st.base = 10;
		uintmax_t num;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  1078b2:	8b 45 10             	mov    0x10(%ebp),%eax
  1078b5:	0f b6 00             	movzbl (%eax),%eax
  1078b8:	0f b6 d8             	movzbl %al,%ebx
  1078bb:	89 d8                	mov    %ebx,%eax
  1078bd:	83 45 10 01          	addl   $0x1,0x10(%ebp)
  1078c1:	83 e8 20             	sub    $0x20,%eax
  1078c4:	83 f8 58             	cmp    $0x58,%eax
  1078c7:	0f 87 b1 02 00 00    	ja     107b7e <vprintfmt+0x362>
  1078cd:	8b 04 85 a8 9e 10 00 	mov    0x109ea8(,%eax,4),%eax
  1078d4:	ff e0                	jmp    *%eax

		// modifier flags
		case '-': // pad on the right instead of the left
			st.flags |= F_RPAD;
  1078d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1078d9:	83 c8 10             	or     $0x10,%eax
  1078dc:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1078df:	eb d1                	jmp    1078b2 <vprintfmt+0x96>

		case '+': // prefix positive numeric values with a '+' sign
			st.signc = '+';
  1078e1:	c7 45 dc 2b 00 00 00 	movl   $0x2b,-0x24(%ebp)
			goto reswitch;
  1078e8:	eb c8                	jmp    1078b2 <vprintfmt+0x96>

		case ' ': // prefix signless numeric values with a space
			if (st.signc < 0)	// (but only if no '+' is specified)
  1078ea:	8b 45 dc             	mov    -0x24(%ebp),%eax
  1078ed:	85 c0                	test   %eax,%eax
  1078ef:	79 bd                	jns    1078ae <vprintfmt+0x92>
				st.signc = ' ';
  1078f1:	c7 45 dc 20 00 00 00 	movl   $0x20,-0x24(%ebp)
			goto reswitch;
  1078f8:	eb b8                	jmp    1078b2 <vprintfmt+0x96>

		// width or precision field
		case '0':
			if (!(st.flags & F_DOT))
  1078fa:	8b 45 e0             	mov    -0x20(%ebp),%eax
  1078fd:	83 e0 08             	and    $0x8,%eax
  107900:	85 c0                	test   %eax,%eax
  107902:	75 07                	jne    10790b <vprintfmt+0xef>
				st.padc = '0'; // pad with 0's instead of spaces
  107904:	c7 45 d0 30 00 00 00 	movl   $0x30,-0x30(%ebp)
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  10790b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
				st.prec = st.prec * 10 + ch - '0';
  107912:	8b 55 d8             	mov    -0x28(%ebp),%edx
  107915:	89 d0                	mov    %edx,%eax
  107917:	c1 e0 02             	shl    $0x2,%eax
  10791a:	01 d0                	add    %edx,%eax
  10791c:	01 c0                	add    %eax,%eax
  10791e:	01 d8                	add    %ebx,%eax
  107920:	83 e8 30             	sub    $0x30,%eax
  107923:	89 45 d8             	mov    %eax,-0x28(%ebp)
				ch = *fmt;
  107926:	8b 45 10             	mov    0x10(%ebp),%eax
  107929:	0f b6 00             	movzbl (%eax),%eax
  10792c:	0f be d8             	movsbl %al,%ebx
				if (ch < '0' || ch > '9')
  10792f:	83 fb 2f             	cmp    $0x2f,%ebx
  107932:	7e 21                	jle    107955 <vprintfmt+0x139>
  107934:	83 fb 39             	cmp    $0x39,%ebx
  107937:	7f 1f                	jg     107958 <vprintfmt+0x13c>
		case '0':
			if (!(st.flags & F_DOT))
				st.padc = '0'; // pad with 0's instead of spaces
		case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			for (st.prec = 0; ; ++fmt) {
  107939:	83 45 10 01          	addl   $0x1,0x10(%ebp)
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  10793d:	eb d3                	jmp    107912 <vprintfmt+0xf6>
			goto gotprec;

		case '*':
			st.prec = va_arg(ap, int);
  10793f:	8b 45 14             	mov    0x14(%ebp),%eax
  107942:	83 c0 04             	add    $0x4,%eax
  107945:	89 45 14             	mov    %eax,0x14(%ebp)
  107948:	8b 45 14             	mov    0x14(%ebp),%eax
  10794b:	83 e8 04             	sub    $0x4,%eax
  10794e:	8b 00                	mov    (%eax),%eax
  107950:	89 45 d8             	mov    %eax,-0x28(%ebp)
  107953:	eb 04                	jmp    107959 <vprintfmt+0x13d>
				st.prec = st.prec * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
			goto gotprec;
  107955:	90                   	nop
  107956:	eb 01                	jmp    107959 <vprintfmt+0x13d>
  107958:	90                   	nop

		case '*':
			st.prec = va_arg(ap, int);
		gotprec:
			if (!(st.flags & F_DOT)) {	// haven't seen a '.' yet?
  107959:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10795c:	83 e0 08             	and    $0x8,%eax
  10795f:	85 c0                	test   %eax,%eax
  107961:	0f 85 4a ff ff ff    	jne    1078b1 <vprintfmt+0x95>
				st.width = st.prec;	// then it's a field width
  107967:	8b 45 d8             	mov    -0x28(%ebp),%eax
  10796a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				st.prec = -1;
  10796d:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
			}
			goto reswitch;
  107974:	e9 39 ff ff ff       	jmp    1078b2 <vprintfmt+0x96>

		case '.':
			st.flags |= F_DOT;
  107979:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10797c:	83 c8 08             	or     $0x8,%eax
  10797f:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107982:	e9 2b ff ff ff       	jmp    1078b2 <vprintfmt+0x96>

		case '#':
			st.flags |= F_ALT;
  107987:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10798a:	83 c8 04             	or     $0x4,%eax
  10798d:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  107990:	e9 1d ff ff ff       	jmp    1078b2 <vprintfmt+0x96>

		// long flag (doubled for long long)
		case 'l':
			st.flags |= (st.flags & F_L) ? F_LL : F_L;
  107995:	8b 55 e0             	mov    -0x20(%ebp),%edx
  107998:	8b 45 e0             	mov    -0x20(%ebp),%eax
  10799b:	83 e0 01             	and    $0x1,%eax
  10799e:	84 c0                	test   %al,%al
  1079a0:	74 07                	je     1079a9 <vprintfmt+0x18d>
  1079a2:	b8 02 00 00 00       	mov    $0x2,%eax
  1079a7:	eb 05                	jmp    1079ae <vprintfmt+0x192>
  1079a9:	b8 01 00 00 00       	mov    $0x1,%eax
  1079ae:	09 d0                	or     %edx,%eax
  1079b0:	89 45 e0             	mov    %eax,-0x20(%ebp)
			goto reswitch;
  1079b3:	e9 fa fe ff ff       	jmp    1078b2 <vprintfmt+0x96>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  1079b8:	8b 45 14             	mov    0x14(%ebp),%eax
  1079bb:	83 c0 04             	add    $0x4,%eax
  1079be:	89 45 14             	mov    %eax,0x14(%ebp)
  1079c1:	8b 45 14             	mov    0x14(%ebp),%eax
  1079c4:	83 e8 04             	sub    $0x4,%eax
  1079c7:	8b 00                	mov    (%eax),%eax
  1079c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  1079cc:	89 54 24 04          	mov    %edx,0x4(%esp)
  1079d0:	89 04 24             	mov    %eax,(%esp)
  1079d3:	8b 45 08             	mov    0x8(%ebp),%eax
  1079d6:	ff d0                	call   *%eax
			break;
  1079d8:	e9 cb 01 00 00       	jmp    107ba8 <vprintfmt+0x38c>

		// string
		case 's': {
			const char *s;
			if ((s = va_arg(ap, char *)) == NULL)
  1079dd:	8b 45 14             	mov    0x14(%ebp),%eax
  1079e0:	83 c0 04             	add    $0x4,%eax
  1079e3:	89 45 14             	mov    %eax,0x14(%ebp)
  1079e6:	8b 45 14             	mov    0x14(%ebp),%eax
  1079e9:	83 e8 04             	sub    $0x4,%eax
  1079ec:	8b 00                	mov    (%eax),%eax
  1079ee:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1079f1:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
  1079f5:	75 07                	jne    1079fe <vprintfmt+0x1e2>
				s = "(null)";
  1079f7:	c7 45 f4 a1 9e 10 00 	movl   $0x109ea1,-0xc(%ebp)
			putstr(&st, s, st.prec);
  1079fe:	8b 45 d8             	mov    -0x28(%ebp),%eax
  107a01:	89 44 24 08          	mov    %eax,0x8(%esp)
  107a05:	8b 45 f4             	mov    -0xc(%ebp),%eax
  107a08:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a0c:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107a0f:	89 04 24             	mov    %eax,(%esp)
  107a12:	e8 0c fc ff ff       	call   107623 <putstr>
			break;
  107a17:	e9 8c 01 00 00       	jmp    107ba8 <vprintfmt+0x38c>
		    }

		// (signed) decimal
		case 'd':
			num = getint(&st, &ap);
  107a1c:	8d 45 14             	lea    0x14(%ebp),%eax
  107a1f:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a23:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107a26:	89 04 24             	mov    %eax,(%esp)
  107a29:	e8 43 fb ff ff       	call   107571 <getint>
  107a2e:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107a31:	89 55 ec             	mov    %edx,-0x14(%ebp)
			if ((intmax_t) num < 0) {
  107a34:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107a37:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107a3a:	85 d2                	test   %edx,%edx
  107a3c:	79 1a                	jns    107a58 <vprintfmt+0x23c>
				num = -(intmax_t) num;
  107a3e:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107a41:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107a44:	f7 d8                	neg    %eax
  107a46:	83 d2 00             	adc    $0x0,%edx
  107a49:	f7 da                	neg    %edx
  107a4b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  107a4e:	89 55 ec             	mov    %edx,-0x14(%ebp)
				st.signc = '-';
  107a51:	c7 45 dc 2d 00 00 00 	movl   $0x2d,-0x24(%ebp)
			}
			putint(&st, num, 10);
  107a58:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107a5f:	00 
  107a60:	8b 45 e8             	mov    -0x18(%ebp),%eax
  107a63:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107a66:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a6a:	89 54 24 08          	mov    %edx,0x8(%esp)
  107a6e:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107a71:	89 04 24             	mov    %eax,(%esp)
  107a74:	e8 3b fd ff ff       	call   1077b4 <putint>
			break;
  107a79:	e9 2a 01 00 00       	jmp    107ba8 <vprintfmt+0x38c>

		// unsigned decimal
		case 'u':
			putint(&st, getuint(&st, &ap), 10);
  107a7e:	8d 45 14             	lea    0x14(%ebp),%eax
  107a81:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a85:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107a88:	89 04 24             	mov    %eax,(%esp)
  107a8b:	e8 6c fa ff ff       	call   1074fc <getuint>
  107a90:	c7 44 24 0c 0a 00 00 	movl   $0xa,0xc(%esp)
  107a97:	00 
  107a98:	89 44 24 04          	mov    %eax,0x4(%esp)
  107a9c:	89 54 24 08          	mov    %edx,0x8(%esp)
  107aa0:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107aa3:	89 04 24             	mov    %eax,(%esp)
  107aa6:	e8 09 fd ff ff       	call   1077b4 <putint>
			break;
  107aab:	e9 f8 00 00 00       	jmp    107ba8 <vprintfmt+0x38c>

		// (unsigned) octal
		case 'o':
			putint(&st, getuint(&st, &ap), 8);
  107ab0:	8d 45 14             	lea    0x14(%ebp),%eax
  107ab3:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ab7:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107aba:	89 04 24             	mov    %eax,(%esp)
  107abd:	e8 3a fa ff ff       	call   1074fc <getuint>
  107ac2:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  107ac9:	00 
  107aca:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ace:	89 54 24 08          	mov    %edx,0x8(%esp)
  107ad2:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107ad5:	89 04 24             	mov    %eax,(%esp)
  107ad8:	e8 d7 fc ff ff       	call   1077b4 <putint>
			break;
  107add:	e9 c6 00 00 00       	jmp    107ba8 <vprintfmt+0x38c>

		// (unsigned) hexadecimal
		case 'x':
			putint(&st, getuint(&st, &ap), 16);
  107ae2:	8d 45 14             	lea    0x14(%ebp),%eax
  107ae5:	89 44 24 04          	mov    %eax,0x4(%esp)
  107ae9:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107aec:	89 04 24             	mov    %eax,(%esp)
  107aef:	e8 08 fa ff ff       	call   1074fc <getuint>
  107af4:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107afb:	00 
  107afc:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b00:	89 54 24 08          	mov    %edx,0x8(%esp)
  107b04:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107b07:	89 04 24             	mov    %eax,(%esp)
  107b0a:	e8 a5 fc ff ff       	call   1077b4 <putint>
			break;
  107b0f:	e9 94 00 00 00       	jmp    107ba8 <vprintfmt+0x38c>

		// pointer
		case 'p':
			putch('0', putdat);
  107b14:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b17:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b1b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  107b22:	8b 45 08             	mov    0x8(%ebp),%eax
  107b25:	ff d0                	call   *%eax
			putch('x', putdat);
  107b27:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b2a:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b2e:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  107b35:	8b 45 08             	mov    0x8(%ebp),%eax
  107b38:	ff d0                	call   *%eax
			putint(&st, (uintptr_t) va_arg(ap, void *), 16);
  107b3a:	8b 45 14             	mov    0x14(%ebp),%eax
  107b3d:	83 c0 04             	add    $0x4,%eax
  107b40:	89 45 14             	mov    %eax,0x14(%ebp)
  107b43:	8b 45 14             	mov    0x14(%ebp),%eax
  107b46:	83 e8 04             	sub    $0x4,%eax
  107b49:	8b 00                	mov    (%eax),%eax
  107b4b:	ba 00 00 00 00       	mov    $0x0,%edx
  107b50:	c7 44 24 0c 10 00 00 	movl   $0x10,0xc(%esp)
  107b57:	00 
  107b58:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b5c:	89 54 24 08          	mov    %edx,0x8(%esp)
  107b60:	8d 45 c8             	lea    -0x38(%ebp),%eax
  107b63:	89 04 24             	mov    %eax,(%esp)
  107b66:	e8 49 fc ff ff       	call   1077b4 <putint>
			break;
  107b6b:	eb 3b                	jmp    107ba8 <vprintfmt+0x38c>


		// escaped '%' character
		case '%':
			putch(ch, putdat);
  107b6d:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b70:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b74:	89 1c 24             	mov    %ebx,(%esp)
  107b77:	8b 45 08             	mov    0x8(%ebp),%eax
  107b7a:	ff d0                	call   *%eax
			break;
  107b7c:	eb 2a                	jmp    107ba8 <vprintfmt+0x38c>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  107b7e:	8b 45 0c             	mov    0xc(%ebp),%eax
  107b81:	89 44 24 04          	mov    %eax,0x4(%esp)
  107b85:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  107b8c:	8b 45 08             	mov    0x8(%ebp),%eax
  107b8f:	ff d0                	call   *%eax
			for (fmt--; fmt[-1] != '%'; fmt--)
  107b91:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107b95:	eb 04                	jmp    107b9b <vprintfmt+0x37f>
  107b97:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107b9b:	8b 45 10             	mov    0x10(%ebp),%eax
  107b9e:	83 e8 01             	sub    $0x1,%eax
  107ba1:	0f b6 00             	movzbl (%eax),%eax
  107ba4:	3c 25                	cmp    $0x25,%al
  107ba6:	75 ef                	jne    107b97 <vprintfmt+0x37b>
				/* do nothing */;
			break;
		}
	}
  107ba8:	90                   	nop
{
	register int ch, err;

	printstate st = { .putch = putch, .putdat = putdat };
	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  107ba9:	e9 bd fc ff ff       	jmp    10786b <vprintfmt+0x4f>
			for (fmt--; fmt[-1] != '%'; fmt--)
				/* do nothing */;
			break;
		}
	}
}
  107bae:	83 c4 44             	add    $0x44,%esp
  107bb1:	5b                   	pop    %ebx
  107bb2:	5d                   	pop    %ebp
  107bb3:	c3                   	ret    

00107bb4 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  107bb4:	55                   	push   %ebp
  107bb5:	89 e5                	mov    %esp,%ebp
  107bb7:	83 ec 18             	sub    $0x18,%esp
	b->buf[b->idx++] = ch;
  107bba:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bbd:	8b 00                	mov    (%eax),%eax
  107bbf:	8b 55 08             	mov    0x8(%ebp),%edx
  107bc2:	89 d1                	mov    %edx,%ecx
  107bc4:	8b 55 0c             	mov    0xc(%ebp),%edx
  107bc7:	88 4c 02 08          	mov    %cl,0x8(%edx,%eax,1)
  107bcb:	8d 50 01             	lea    0x1(%eax),%edx
  107bce:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bd1:	89 10                	mov    %edx,(%eax)
	if (b->idx == CPUTS_MAX-1) {
  107bd3:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bd6:	8b 00                	mov    (%eax),%eax
  107bd8:	3d ff 00 00 00       	cmp    $0xff,%eax
  107bdd:	75 24                	jne    107c03 <putch+0x4f>
		b->buf[b->idx] = 0;
  107bdf:	8b 45 0c             	mov    0xc(%ebp),%eax
  107be2:	8b 00                	mov    (%eax),%eax
  107be4:	8b 55 0c             	mov    0xc(%ebp),%edx
  107be7:	c6 44 02 08 00       	movb   $0x0,0x8(%edx,%eax,1)
		cputs(b->buf);
  107bec:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bef:	83 c0 08             	add    $0x8,%eax
  107bf2:	89 04 24             	mov    %eax,(%esp)
  107bf5:	e8 33 88 ff ff       	call   10042d <cputs>
		b->idx = 0;
  107bfa:	8b 45 0c             	mov    0xc(%ebp),%eax
  107bfd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	b->cnt++;
  107c03:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c06:	8b 40 04             	mov    0x4(%eax),%eax
  107c09:	8d 50 01             	lea    0x1(%eax),%edx
  107c0c:	8b 45 0c             	mov    0xc(%ebp),%eax
  107c0f:	89 50 04             	mov    %edx,0x4(%eax)
}
  107c12:	c9                   	leave  
  107c13:	c3                   	ret    

00107c14 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  107c14:	55                   	push   %ebp
  107c15:	89 e5                	mov    %esp,%ebp
  107c17:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  107c1d:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  107c24:	00 00 00 
	b.cnt = 0;
  107c27:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  107c2e:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  107c31:	b8 b4 7b 10 00       	mov    $0x107bb4,%eax
  107c36:	8b 55 0c             	mov    0xc(%ebp),%edx
  107c39:	89 54 24 0c          	mov    %edx,0xc(%esp)
  107c3d:	8b 55 08             	mov    0x8(%ebp),%edx
  107c40:	89 54 24 08          	mov    %edx,0x8(%esp)
  107c44:	8d 95 f0 fe ff ff    	lea    -0x110(%ebp),%edx
  107c4a:	89 54 24 04          	mov    %edx,0x4(%esp)
  107c4e:	89 04 24             	mov    %eax,(%esp)
  107c51:	e8 c6 fb ff ff       	call   10781c <vprintfmt>

	b.buf[b.idx] = 0;
  107c56:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  107c5c:	c6 84 05 f8 fe ff ff 	movb   $0x0,-0x108(%ebp,%eax,1)
  107c63:	00 
	cputs(b.buf);
  107c64:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  107c6a:	83 c0 08             	add    $0x8,%eax
  107c6d:	89 04 24             	mov    %eax,(%esp)
  107c70:	e8 b8 87 ff ff       	call   10042d <cputs>

	return b.cnt;
  107c75:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
}
  107c7b:	c9                   	leave  
  107c7c:	c3                   	ret    

00107c7d <cprintf>:

int
cprintf(const char *fmt, ...)
{
  107c7d:	55                   	push   %ebp
  107c7e:	89 e5                	mov    %esp,%ebp
  107c80:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  107c83:	8d 45 08             	lea    0x8(%ebp),%eax
  107c86:	83 c0 04             	add    $0x4,%eax
  107c89:	89 45 f0             	mov    %eax,-0x10(%ebp)
	cnt = vcprintf(fmt, ap);
  107c8c:	8b 45 08             	mov    0x8(%ebp),%eax
  107c8f:	8b 55 f0             	mov    -0x10(%ebp),%edx
  107c92:	89 54 24 04          	mov    %edx,0x4(%esp)
  107c96:	89 04 24             	mov    %eax,(%esp)
  107c99:	e8 76 ff ff ff       	call   107c14 <vcprintf>
  107c9e:	89 45 f4             	mov    %eax,-0xc(%ebp)
	va_end(ap);

	return cnt;
  107ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
  107ca4:	c9                   	leave  
  107ca5:	c3                   	ret    
  107ca6:	90                   	nop
  107ca7:	90                   	nop

00107ca8 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  107ca8:	55                   	push   %ebp
  107ca9:	89 e5                	mov    %esp,%ebp
  107cab:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
  107cae:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  107cb5:	eb 08                	jmp    107cbf <strlen+0x17>
		n++;
  107cb7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  107cbb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107cbf:	8b 45 08             	mov    0x8(%ebp),%eax
  107cc2:	0f b6 00             	movzbl (%eax),%eax
  107cc5:	84 c0                	test   %al,%al
  107cc7:	75 ee                	jne    107cb7 <strlen+0xf>
		n++;
	return n;
  107cc9:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107ccc:	c9                   	leave  
  107ccd:	c3                   	ret    

00107cce <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  107cce:	55                   	push   %ebp
  107ccf:	89 e5                	mov    %esp,%ebp
  107cd1:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
  107cd4:	8b 45 08             	mov    0x8(%ebp),%eax
  107cd7:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
  107cda:	8b 45 0c             	mov    0xc(%ebp),%eax
  107cdd:	0f b6 10             	movzbl (%eax),%edx
  107ce0:	8b 45 08             	mov    0x8(%ebp),%eax
  107ce3:	88 10                	mov    %dl,(%eax)
  107ce5:	8b 45 08             	mov    0x8(%ebp),%eax
  107ce8:	0f b6 00             	movzbl (%eax),%eax
  107ceb:	84 c0                	test   %al,%al
  107ced:	0f 95 c0             	setne  %al
  107cf0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107cf4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
  107cf8:	84 c0                	test   %al,%al
  107cfa:	75 de                	jne    107cda <strcpy+0xc>
		/* do nothing */;
	return ret;
  107cfc:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107cff:	c9                   	leave  
  107d00:	c3                   	ret    

00107d01 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size)
{
  107d01:	55                   	push   %ebp
  107d02:	89 e5                	mov    %esp,%ebp
  107d04:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
  107d07:	8b 45 08             	mov    0x8(%ebp),%eax
  107d0a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (i = 0; i < size; i++) {
  107d0d:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  107d14:	eb 21                	jmp    107d37 <strncpy+0x36>
		*dst++ = *src;
  107d16:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d19:	0f b6 10             	movzbl (%eax),%edx
  107d1c:	8b 45 08             	mov    0x8(%ebp),%eax
  107d1f:	88 10                	mov    %dl,(%eax)
  107d21:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
  107d25:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d28:	0f b6 00             	movzbl (%eax),%eax
  107d2b:	84 c0                	test   %al,%al
  107d2d:	74 04                	je     107d33 <strncpy+0x32>
			src++;
  107d2f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  107d33:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  107d37:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107d3a:	3b 45 10             	cmp    0x10(%ebp),%eax
  107d3d:	72 d7                	jb     107d16 <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
  107d3f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
  107d42:	c9                   	leave  
  107d43:	c3                   	ret    

00107d44 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  107d44:	55                   	push   %ebp
  107d45:	89 e5                	mov    %esp,%ebp
  107d47:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
  107d4a:	8b 45 08             	mov    0x8(%ebp),%eax
  107d4d:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
  107d50:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107d54:	74 2f                	je     107d85 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
  107d56:	eb 13                	jmp    107d6b <strlcpy+0x27>
			*dst++ = *src++;
  107d58:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d5b:	0f b6 10             	movzbl (%eax),%edx
  107d5e:	8b 45 08             	mov    0x8(%ebp),%eax
  107d61:	88 10                	mov    %dl,(%eax)
  107d63:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107d67:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  107d6b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107d6f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107d73:	74 0a                	je     107d7f <strlcpy+0x3b>
  107d75:	8b 45 0c             	mov    0xc(%ebp),%eax
  107d78:	0f b6 00             	movzbl (%eax),%eax
  107d7b:	84 c0                	test   %al,%al
  107d7d:	75 d9                	jne    107d58 <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
  107d7f:	8b 45 08             	mov    0x8(%ebp),%eax
  107d82:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
  107d85:	8b 55 08             	mov    0x8(%ebp),%edx
  107d88:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107d8b:	89 d1                	mov    %edx,%ecx
  107d8d:	29 c1                	sub    %eax,%ecx
  107d8f:	89 c8                	mov    %ecx,%eax
}
  107d91:	c9                   	leave  
  107d92:	c3                   	ret    

00107d93 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  107d93:	55                   	push   %ebp
  107d94:	89 e5                	mov    %esp,%ebp
	while (*p && *p == *q)
  107d96:	eb 08                	jmp    107da0 <strcmp+0xd>
		p++, q++;
  107d98:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107d9c:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  107da0:	8b 45 08             	mov    0x8(%ebp),%eax
  107da3:	0f b6 00             	movzbl (%eax),%eax
  107da6:	84 c0                	test   %al,%al
  107da8:	74 10                	je     107dba <strcmp+0x27>
  107daa:	8b 45 08             	mov    0x8(%ebp),%eax
  107dad:	0f b6 10             	movzbl (%eax),%edx
  107db0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107db3:	0f b6 00             	movzbl (%eax),%eax
  107db6:	38 c2                	cmp    %al,%dl
  107db8:	74 de                	je     107d98 <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  107dba:	8b 45 08             	mov    0x8(%ebp),%eax
  107dbd:	0f b6 00             	movzbl (%eax),%eax
  107dc0:	0f b6 d0             	movzbl %al,%edx
  107dc3:	8b 45 0c             	mov    0xc(%ebp),%eax
  107dc6:	0f b6 00             	movzbl (%eax),%eax
  107dc9:	0f b6 c0             	movzbl %al,%eax
  107dcc:	89 d1                	mov    %edx,%ecx
  107dce:	29 c1                	sub    %eax,%ecx
  107dd0:	89 c8                	mov    %ecx,%eax
}
  107dd2:	5d                   	pop    %ebp
  107dd3:	c3                   	ret    

00107dd4 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  107dd4:	55                   	push   %ebp
  107dd5:	89 e5                	mov    %esp,%ebp
	while (n > 0 && *p && *p == *q)
  107dd7:	eb 0c                	jmp    107de5 <strncmp+0x11>
		n--, p++, q++;
  107dd9:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  107ddd:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107de1:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  107de5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107de9:	74 1a                	je     107e05 <strncmp+0x31>
  107deb:	8b 45 08             	mov    0x8(%ebp),%eax
  107dee:	0f b6 00             	movzbl (%eax),%eax
  107df1:	84 c0                	test   %al,%al
  107df3:	74 10                	je     107e05 <strncmp+0x31>
  107df5:	8b 45 08             	mov    0x8(%ebp),%eax
  107df8:	0f b6 10             	movzbl (%eax),%edx
  107dfb:	8b 45 0c             	mov    0xc(%ebp),%eax
  107dfe:	0f b6 00             	movzbl (%eax),%eax
  107e01:	38 c2                	cmp    %al,%dl
  107e03:	74 d4                	je     107dd9 <strncmp+0x5>
		n--, p++, q++;
	if (n == 0)
  107e05:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107e09:	75 07                	jne    107e12 <strncmp+0x3e>
		return 0;
  107e0b:	b8 00 00 00 00       	mov    $0x0,%eax
  107e10:	eb 18                	jmp    107e2a <strncmp+0x56>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  107e12:	8b 45 08             	mov    0x8(%ebp),%eax
  107e15:	0f b6 00             	movzbl (%eax),%eax
  107e18:	0f b6 d0             	movzbl %al,%edx
  107e1b:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e1e:	0f b6 00             	movzbl (%eax),%eax
  107e21:	0f b6 c0             	movzbl %al,%eax
  107e24:	89 d1                	mov    %edx,%ecx
  107e26:	29 c1                	sub    %eax,%ecx
  107e28:	89 c8                	mov    %ecx,%eax
}
  107e2a:	5d                   	pop    %ebp
  107e2b:	c3                   	ret    

00107e2c <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  107e2c:	55                   	push   %ebp
  107e2d:	89 e5                	mov    %esp,%ebp
  107e2f:	83 ec 04             	sub    $0x4,%esp
  107e32:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e35:	88 45 fc             	mov    %al,-0x4(%ebp)
	while (*s != c)
  107e38:	eb 1a                	jmp    107e54 <strchr+0x28>
		if (*s++ == 0)
  107e3a:	8b 45 08             	mov    0x8(%ebp),%eax
  107e3d:	0f b6 00             	movzbl (%eax),%eax
  107e40:	84 c0                	test   %al,%al
  107e42:	0f 94 c0             	sete   %al
  107e45:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  107e49:	84 c0                	test   %al,%al
  107e4b:	74 07                	je     107e54 <strchr+0x28>
			return NULL;
  107e4d:	b8 00 00 00 00       	mov    $0x0,%eax
  107e52:	eb 0e                	jmp    107e62 <strchr+0x36>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	while (*s != c)
  107e54:	8b 45 08             	mov    0x8(%ebp),%eax
  107e57:	0f b6 00             	movzbl (%eax),%eax
  107e5a:	3a 45 fc             	cmp    -0x4(%ebp),%al
  107e5d:	75 db                	jne    107e3a <strchr+0xe>
		if (*s++ == 0)
			return NULL;
	return (char *) s;
  107e5f:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107e62:	c9                   	leave  
  107e63:	c3                   	ret    

00107e64 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  107e64:	55                   	push   %ebp
  107e65:	89 e5                	mov    %esp,%ebp
  107e67:	57                   	push   %edi
  107e68:	83 ec 10             	sub    $0x10,%esp
	char *p;

	if (n == 0)
  107e6b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  107e6f:	75 05                	jne    107e76 <memset+0x12>
		return v;
  107e71:	8b 45 08             	mov    0x8(%ebp),%eax
  107e74:	eb 5c                	jmp    107ed2 <memset+0x6e>
	if ((int)v%4 == 0 && n%4 == 0) {
  107e76:	8b 45 08             	mov    0x8(%ebp),%eax
  107e79:	83 e0 03             	and    $0x3,%eax
  107e7c:	85 c0                	test   %eax,%eax
  107e7e:	75 41                	jne    107ec1 <memset+0x5d>
  107e80:	8b 45 10             	mov    0x10(%ebp),%eax
  107e83:	83 e0 03             	and    $0x3,%eax
  107e86:	85 c0                	test   %eax,%eax
  107e88:	75 37                	jne    107ec1 <memset+0x5d>
		c &= 0xFF;
  107e8a:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
		c = (c<<24)|(c<<16)|(c<<8)|c;
  107e91:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e94:	89 c2                	mov    %eax,%edx
  107e96:	c1 e2 18             	shl    $0x18,%edx
  107e99:	8b 45 0c             	mov    0xc(%ebp),%eax
  107e9c:	c1 e0 10             	shl    $0x10,%eax
  107e9f:	09 c2                	or     %eax,%edx
  107ea1:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ea4:	c1 e0 08             	shl    $0x8,%eax
  107ea7:	09 d0                	or     %edx,%eax
  107ea9:	09 45 0c             	or     %eax,0xc(%ebp)
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  107eac:	8b 45 10             	mov    0x10(%ebp),%eax
  107eaf:	89 c1                	mov    %eax,%ecx
  107eb1:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  107eb4:	8b 55 08             	mov    0x8(%ebp),%edx
  107eb7:	8b 45 0c             	mov    0xc(%ebp),%eax
  107eba:	89 d7                	mov    %edx,%edi
  107ebc:	fc                   	cld    
  107ebd:	f3 ab                	rep stos %eax,%es:(%edi)
{
	char *p;

	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  107ebf:	eb 0e                	jmp    107ecf <memset+0x6b>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  107ec1:	8b 55 08             	mov    0x8(%ebp),%edx
  107ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ec7:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107eca:	89 d7                	mov    %edx,%edi
  107ecc:	fc                   	cld    
  107ecd:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
  107ecf:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107ed2:	83 c4 10             	add    $0x10,%esp
  107ed5:	5f                   	pop    %edi
  107ed6:	5d                   	pop    %ebp
  107ed7:	c3                   	ret    

00107ed8 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  107ed8:	55                   	push   %ebp
  107ed9:	89 e5                	mov    %esp,%ebp
  107edb:	57                   	push   %edi
  107edc:	56                   	push   %esi
  107edd:	53                   	push   %ebx
  107ede:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
  107ee1:	8b 45 0c             	mov    0xc(%ebp),%eax
  107ee4:	89 45 ec             	mov    %eax,-0x14(%ebp)
	d = dst;
  107ee7:	8b 45 08             	mov    0x8(%ebp),%eax
  107eea:	89 45 f0             	mov    %eax,-0x10(%ebp)
	if (s < d && s + n > d) {
  107eed:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107ef0:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107ef3:	73 6e                	jae    107f63 <memmove+0x8b>
  107ef5:	8b 45 10             	mov    0x10(%ebp),%eax
  107ef8:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107efb:	8d 04 02             	lea    (%edx,%eax,1),%eax
  107efe:	3b 45 f0             	cmp    -0x10(%ebp),%eax
  107f01:	76 60                	jbe    107f63 <memmove+0x8b>
		s += n;
  107f03:	8b 45 10             	mov    0x10(%ebp),%eax
  107f06:	01 45 ec             	add    %eax,-0x14(%ebp)
		d += n;
  107f09:	8b 45 10             	mov    0x10(%ebp),%eax
  107f0c:	01 45 f0             	add    %eax,-0x10(%ebp)
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107f0f:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107f12:	83 e0 03             	and    $0x3,%eax
  107f15:	85 c0                	test   %eax,%eax
  107f17:	75 2f                	jne    107f48 <memmove+0x70>
  107f19:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f1c:	83 e0 03             	and    $0x3,%eax
  107f1f:	85 c0                	test   %eax,%eax
  107f21:	75 25                	jne    107f48 <memmove+0x70>
  107f23:	8b 45 10             	mov    0x10(%ebp),%eax
  107f26:	83 e0 03             	and    $0x3,%eax
  107f29:	85 c0                	test   %eax,%eax
  107f2b:	75 1b                	jne    107f48 <memmove+0x70>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  107f2d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f30:	83 e8 04             	sub    $0x4,%eax
  107f33:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107f36:	83 ea 04             	sub    $0x4,%edx
  107f39:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107f3c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  107f3f:	89 c7                	mov    %eax,%edi
  107f41:	89 d6                	mov    %edx,%esi
  107f43:	fd                   	std    
  107f44:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107f46:	eb 18                	jmp    107f60 <memmove+0x88>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  107f48:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f4b:	8d 50 ff             	lea    -0x1(%eax),%edx
  107f4e:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107f51:	8d 58 ff             	lea    -0x1(%eax),%ebx
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  107f54:	8b 45 10             	mov    0x10(%ebp),%eax
  107f57:	89 d7                	mov    %edx,%edi
  107f59:	89 de                	mov    %ebx,%esi
  107f5b:	89 c1                	mov    %eax,%ecx
  107f5d:	fd                   	std    
  107f5e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  107f60:	fc                   	cld    
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
  107f61:	eb 45                	jmp    107fa8 <memmove+0xd0>
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107f63:	8b 45 ec             	mov    -0x14(%ebp),%eax
  107f66:	83 e0 03             	and    $0x3,%eax
  107f69:	85 c0                	test   %eax,%eax
  107f6b:	75 2b                	jne    107f98 <memmove+0xc0>
  107f6d:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f70:	83 e0 03             	and    $0x3,%eax
  107f73:	85 c0                	test   %eax,%eax
  107f75:	75 21                	jne    107f98 <memmove+0xc0>
  107f77:	8b 45 10             	mov    0x10(%ebp),%eax
  107f7a:	83 e0 03             	and    $0x3,%eax
  107f7d:	85 c0                	test   %eax,%eax
  107f7f:	75 17                	jne    107f98 <memmove+0xc0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  107f81:	8b 45 10             	mov    0x10(%ebp),%eax
  107f84:	89 c1                	mov    %eax,%ecx
  107f86:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  107f89:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f8c:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107f8f:	89 c7                	mov    %eax,%edi
  107f91:	89 d6                	mov    %edx,%esi
  107f93:	fc                   	cld    
  107f94:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  107f96:	eb 10                	jmp    107fa8 <memmove+0xd0>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  107f98:	8b 45 f0             	mov    -0x10(%ebp),%eax
  107f9b:	8b 55 ec             	mov    -0x14(%ebp),%edx
  107f9e:	8b 4d 10             	mov    0x10(%ebp),%ecx
  107fa1:	89 c7                	mov    %eax,%edi
  107fa3:	89 d6                	mov    %edx,%esi
  107fa5:	fc                   	cld    
  107fa6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
  107fa8:	8b 45 08             	mov    0x8(%ebp),%eax
}
  107fab:	83 c4 10             	add    $0x10,%esp
  107fae:	5b                   	pop    %ebx
  107faf:	5e                   	pop    %esi
  107fb0:	5f                   	pop    %edi
  107fb1:	5d                   	pop    %ebp
  107fb2:	c3                   	ret    

00107fb3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  107fb3:	55                   	push   %ebp
  107fb4:	89 e5                	mov    %esp,%ebp
  107fb6:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  107fb9:	8b 45 10             	mov    0x10(%ebp),%eax
  107fbc:	89 44 24 08          	mov    %eax,0x8(%esp)
  107fc0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107fc3:	89 44 24 04          	mov    %eax,0x4(%esp)
  107fc7:	8b 45 08             	mov    0x8(%ebp),%eax
  107fca:	89 04 24             	mov    %eax,(%esp)
  107fcd:	e8 06 ff ff ff       	call   107ed8 <memmove>
}
  107fd2:	c9                   	leave  
  107fd3:	c3                   	ret    

00107fd4 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  107fd4:	55                   	push   %ebp
  107fd5:	89 e5                	mov    %esp,%ebp
  107fd7:	83 ec 10             	sub    $0x10,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
  107fda:	8b 45 08             	mov    0x8(%ebp),%eax
  107fdd:	89 45 f8             	mov    %eax,-0x8(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
  107fe0:	8b 45 0c             	mov    0xc(%ebp),%eax
  107fe3:	89 45 fc             	mov    %eax,-0x4(%ebp)

	while (n-- > 0) {
  107fe6:	eb 32                	jmp    10801a <memcmp+0x46>
		if (*s1 != *s2)
  107fe8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107feb:	0f b6 10             	movzbl (%eax),%edx
  107fee:	8b 45 fc             	mov    -0x4(%ebp),%eax
  107ff1:	0f b6 00             	movzbl (%eax),%eax
  107ff4:	38 c2                	cmp    %al,%dl
  107ff6:	74 1a                	je     108012 <memcmp+0x3e>
			return (int) *s1 - (int) *s2;
  107ff8:	8b 45 f8             	mov    -0x8(%ebp),%eax
  107ffb:	0f b6 00             	movzbl (%eax),%eax
  107ffe:	0f b6 d0             	movzbl %al,%edx
  108001:	8b 45 fc             	mov    -0x4(%ebp),%eax
  108004:	0f b6 00             	movzbl (%eax),%eax
  108007:	0f b6 c0             	movzbl %al,%eax
  10800a:	89 d1                	mov    %edx,%ecx
  10800c:	29 c1                	sub    %eax,%ecx
  10800e:	89 c8                	mov    %ecx,%eax
  108010:	eb 1c                	jmp    10802e <memcmp+0x5a>
		s1++, s2++;
  108012:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
  108016:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  10801a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
  10801e:	0f 95 c0             	setne  %al
  108021:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
  108025:	84 c0                	test   %al,%al
  108027:	75 bf                	jne    107fe8 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  108029:	b8 00 00 00 00       	mov    $0x0,%eax
}
  10802e:	c9                   	leave  
  10802f:	c3                   	ret    

00108030 <memchr>:

void *
memchr(const void *s, int c, size_t n)
{
  108030:	55                   	push   %ebp
  108031:	89 e5                	mov    %esp,%ebp
  108033:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
  108036:	8b 45 10             	mov    0x10(%ebp),%eax
  108039:	8b 55 08             	mov    0x8(%ebp),%edx
  10803c:	8d 04 02             	lea    (%edx,%eax,1),%eax
  10803f:	89 45 fc             	mov    %eax,-0x4(%ebp)
	for (; s < ends; s++)
  108042:	eb 16                	jmp    10805a <memchr+0x2a>
		if (*(const unsigned char *) s == (unsigned char) c)
  108044:	8b 45 08             	mov    0x8(%ebp),%eax
  108047:	0f b6 10             	movzbl (%eax),%edx
  10804a:	8b 45 0c             	mov    0xc(%ebp),%eax
  10804d:	38 c2                	cmp    %al,%dl
  10804f:	75 05                	jne    108056 <memchr+0x26>
			return (void *) s;
  108051:	8b 45 08             	mov    0x8(%ebp),%eax
  108054:	eb 11                	jmp    108067 <memchr+0x37>

void *
memchr(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  108056:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  10805a:	8b 45 08             	mov    0x8(%ebp),%eax
  10805d:	3b 45 fc             	cmp    -0x4(%ebp),%eax
  108060:	72 e2                	jb     108044 <memchr+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			return (void *) s;
	return NULL;
  108062:	b8 00 00 00 00       	mov    $0x0,%eax
}
  108067:	c9                   	leave  
  108068:	c3                   	ret    
  108069:	90                   	nop
  10806a:	90                   	nop
  10806b:	90                   	nop
  10806c:	90                   	nop
  10806d:	90                   	nop
  10806e:	90                   	nop
  10806f:	90                   	nop

00108070 <__udivdi3>:
  108070:	55                   	push   %ebp
  108071:	89 e5                	mov    %esp,%ebp
  108073:	57                   	push   %edi
  108074:	56                   	push   %esi
  108075:	83 ec 10             	sub    $0x10,%esp
  108078:	8b 45 14             	mov    0x14(%ebp),%eax
  10807b:	8b 55 08             	mov    0x8(%ebp),%edx
  10807e:	8b 75 10             	mov    0x10(%ebp),%esi
  108081:	8b 7d 0c             	mov    0xc(%ebp),%edi
  108084:	85 c0                	test   %eax,%eax
  108086:	89 55 f0             	mov    %edx,-0x10(%ebp)
  108089:	75 35                	jne    1080c0 <__udivdi3+0x50>
  10808b:	39 fe                	cmp    %edi,%esi
  10808d:	77 61                	ja     1080f0 <__udivdi3+0x80>
  10808f:	85 f6                	test   %esi,%esi
  108091:	75 0b                	jne    10809e <__udivdi3+0x2e>
  108093:	b8 01 00 00 00       	mov    $0x1,%eax
  108098:	31 d2                	xor    %edx,%edx
  10809a:	f7 f6                	div    %esi
  10809c:	89 c6                	mov    %eax,%esi
  10809e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  1080a1:	31 d2                	xor    %edx,%edx
  1080a3:	89 f8                	mov    %edi,%eax
  1080a5:	f7 f6                	div    %esi
  1080a7:	89 c7                	mov    %eax,%edi
  1080a9:	89 c8                	mov    %ecx,%eax
  1080ab:	f7 f6                	div    %esi
  1080ad:	89 c1                	mov    %eax,%ecx
  1080af:	89 fa                	mov    %edi,%edx
  1080b1:	89 c8                	mov    %ecx,%eax
  1080b3:	83 c4 10             	add    $0x10,%esp
  1080b6:	5e                   	pop    %esi
  1080b7:	5f                   	pop    %edi
  1080b8:	5d                   	pop    %ebp
  1080b9:	c3                   	ret    
  1080ba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  1080c0:	39 f8                	cmp    %edi,%eax
  1080c2:	77 1c                	ja     1080e0 <__udivdi3+0x70>
  1080c4:	0f bd d0             	bsr    %eax,%edx
  1080c7:	83 f2 1f             	xor    $0x1f,%edx
  1080ca:	89 55 f4             	mov    %edx,-0xc(%ebp)
  1080cd:	75 39                	jne    108108 <__udivdi3+0x98>
  1080cf:	3b 75 f0             	cmp    -0x10(%ebp),%esi
  1080d2:	0f 86 a0 00 00 00    	jbe    108178 <__udivdi3+0x108>
  1080d8:	39 f8                	cmp    %edi,%eax
  1080da:	0f 82 98 00 00 00    	jb     108178 <__udivdi3+0x108>
  1080e0:	31 ff                	xor    %edi,%edi
  1080e2:	31 c9                	xor    %ecx,%ecx
  1080e4:	89 c8                	mov    %ecx,%eax
  1080e6:	89 fa                	mov    %edi,%edx
  1080e8:	83 c4 10             	add    $0x10,%esp
  1080eb:	5e                   	pop    %esi
  1080ec:	5f                   	pop    %edi
  1080ed:	5d                   	pop    %ebp
  1080ee:	c3                   	ret    
  1080ef:	90                   	nop
  1080f0:	89 d1                	mov    %edx,%ecx
  1080f2:	89 fa                	mov    %edi,%edx
  1080f4:	89 c8                	mov    %ecx,%eax
  1080f6:	31 ff                	xor    %edi,%edi
  1080f8:	f7 f6                	div    %esi
  1080fa:	89 c1                	mov    %eax,%ecx
  1080fc:	89 fa                	mov    %edi,%edx
  1080fe:	89 c8                	mov    %ecx,%eax
  108100:	83 c4 10             	add    $0x10,%esp
  108103:	5e                   	pop    %esi
  108104:	5f                   	pop    %edi
  108105:	5d                   	pop    %ebp
  108106:	c3                   	ret    
  108107:	90                   	nop
  108108:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10810c:	89 f2                	mov    %esi,%edx
  10810e:	d3 e0                	shl    %cl,%eax
  108110:	89 45 ec             	mov    %eax,-0x14(%ebp)
  108113:	b8 20 00 00 00       	mov    $0x20,%eax
  108118:	2b 45 f4             	sub    -0xc(%ebp),%eax
  10811b:	89 c1                	mov    %eax,%ecx
  10811d:	d3 ea                	shr    %cl,%edx
  10811f:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108123:	0b 55 ec             	or     -0x14(%ebp),%edx
  108126:	d3 e6                	shl    %cl,%esi
  108128:	89 c1                	mov    %eax,%ecx
  10812a:	89 75 e8             	mov    %esi,-0x18(%ebp)
  10812d:	89 fe                	mov    %edi,%esi
  10812f:	d3 ee                	shr    %cl,%esi
  108131:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  108135:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108138:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10813b:	d3 e7                	shl    %cl,%edi
  10813d:	89 c1                	mov    %eax,%ecx
  10813f:	d3 ea                	shr    %cl,%edx
  108141:	09 d7                	or     %edx,%edi
  108143:	89 f2                	mov    %esi,%edx
  108145:	89 f8                	mov    %edi,%eax
  108147:	f7 75 ec             	divl   -0x14(%ebp)
  10814a:	89 d6                	mov    %edx,%esi
  10814c:	89 c7                	mov    %eax,%edi
  10814e:	f7 65 e8             	mull   -0x18(%ebp)
  108151:	39 d6                	cmp    %edx,%esi
  108153:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108156:	72 30                	jb     108188 <__udivdi3+0x118>
  108158:	8b 55 f0             	mov    -0x10(%ebp),%edx
  10815b:	0f b6 4d f4          	movzbl -0xc(%ebp),%ecx
  10815f:	d3 e2                	shl    %cl,%edx
  108161:	39 c2                	cmp    %eax,%edx
  108163:	73 05                	jae    10816a <__udivdi3+0xfa>
  108165:	3b 75 ec             	cmp    -0x14(%ebp),%esi
  108168:	74 1e                	je     108188 <__udivdi3+0x118>
  10816a:	89 f9                	mov    %edi,%ecx
  10816c:	31 ff                	xor    %edi,%edi
  10816e:	e9 71 ff ff ff       	jmp    1080e4 <__udivdi3+0x74>
  108173:	90                   	nop
  108174:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108178:	31 ff                	xor    %edi,%edi
  10817a:	b9 01 00 00 00       	mov    $0x1,%ecx
  10817f:	e9 60 ff ff ff       	jmp    1080e4 <__udivdi3+0x74>
  108184:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108188:	8d 4f ff             	lea    -0x1(%edi),%ecx
  10818b:	31 ff                	xor    %edi,%edi
  10818d:	89 c8                	mov    %ecx,%eax
  10818f:	89 fa                	mov    %edi,%edx
  108191:	83 c4 10             	add    $0x10,%esp
  108194:	5e                   	pop    %esi
  108195:	5f                   	pop    %edi
  108196:	5d                   	pop    %ebp
  108197:	c3                   	ret    
  108198:	90                   	nop
  108199:	90                   	nop
  10819a:	90                   	nop
  10819b:	90                   	nop
  10819c:	90                   	nop
  10819d:	90                   	nop
  10819e:	90                   	nop
  10819f:	90                   	nop

001081a0 <__umoddi3>:
  1081a0:	55                   	push   %ebp
  1081a1:	89 e5                	mov    %esp,%ebp
  1081a3:	57                   	push   %edi
  1081a4:	56                   	push   %esi
  1081a5:	83 ec 20             	sub    $0x20,%esp
  1081a8:	8b 55 14             	mov    0x14(%ebp),%edx
  1081ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  1081ae:	8b 7d 10             	mov    0x10(%ebp),%edi
  1081b1:	8b 75 0c             	mov    0xc(%ebp),%esi
  1081b4:	85 d2                	test   %edx,%edx
  1081b6:	89 c8                	mov    %ecx,%eax
  1081b8:	89 4d f4             	mov    %ecx,-0xc(%ebp)
  1081bb:	75 13                	jne    1081d0 <__umoddi3+0x30>
  1081bd:	39 f7                	cmp    %esi,%edi
  1081bf:	76 3f                	jbe    108200 <__umoddi3+0x60>
  1081c1:	89 f2                	mov    %esi,%edx
  1081c3:	f7 f7                	div    %edi
  1081c5:	89 d0                	mov    %edx,%eax
  1081c7:	31 d2                	xor    %edx,%edx
  1081c9:	83 c4 20             	add    $0x20,%esp
  1081cc:	5e                   	pop    %esi
  1081cd:	5f                   	pop    %edi
  1081ce:	5d                   	pop    %ebp
  1081cf:	c3                   	ret    
  1081d0:	39 f2                	cmp    %esi,%edx
  1081d2:	77 4c                	ja     108220 <__umoddi3+0x80>
  1081d4:	0f bd ca             	bsr    %edx,%ecx
  1081d7:	83 f1 1f             	xor    $0x1f,%ecx
  1081da:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  1081dd:	75 51                	jne    108230 <__umoddi3+0x90>
  1081df:	3b 7d f4             	cmp    -0xc(%ebp),%edi
  1081e2:	0f 87 e0 00 00 00    	ja     1082c8 <__umoddi3+0x128>
  1081e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1081eb:	29 f8                	sub    %edi,%eax
  1081ed:	19 d6                	sbb    %edx,%esi
  1081ef:	89 45 f4             	mov    %eax,-0xc(%ebp)
  1081f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
  1081f5:	89 f2                	mov    %esi,%edx
  1081f7:	83 c4 20             	add    $0x20,%esp
  1081fa:	5e                   	pop    %esi
  1081fb:	5f                   	pop    %edi
  1081fc:	5d                   	pop    %ebp
  1081fd:	c3                   	ret    
  1081fe:	66 90                	xchg   %ax,%ax
  108200:	85 ff                	test   %edi,%edi
  108202:	75 0b                	jne    10820f <__umoddi3+0x6f>
  108204:	b8 01 00 00 00       	mov    $0x1,%eax
  108209:	31 d2                	xor    %edx,%edx
  10820b:	f7 f7                	div    %edi
  10820d:	89 c7                	mov    %eax,%edi
  10820f:	89 f0                	mov    %esi,%eax
  108211:	31 d2                	xor    %edx,%edx
  108213:	f7 f7                	div    %edi
  108215:	8b 45 f4             	mov    -0xc(%ebp),%eax
  108218:	f7 f7                	div    %edi
  10821a:	eb a9                	jmp    1081c5 <__umoddi3+0x25>
  10821c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108220:	89 c8                	mov    %ecx,%eax
  108222:	89 f2                	mov    %esi,%edx
  108224:	83 c4 20             	add    $0x20,%esp
  108227:	5e                   	pop    %esi
  108228:	5f                   	pop    %edi
  108229:	5d                   	pop    %ebp
  10822a:	c3                   	ret    
  10822b:	90                   	nop
  10822c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  108230:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108234:	d3 e2                	shl    %cl,%edx
  108236:	89 55 f4             	mov    %edx,-0xc(%ebp)
  108239:	ba 20 00 00 00       	mov    $0x20,%edx
  10823e:	2b 55 f0             	sub    -0x10(%ebp),%edx
  108241:	89 55 ec             	mov    %edx,-0x14(%ebp)
  108244:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108248:	89 fa                	mov    %edi,%edx
  10824a:	d3 ea                	shr    %cl,%edx
  10824c:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108250:	0b 55 f4             	or     -0xc(%ebp),%edx
  108253:	d3 e7                	shl    %cl,%edi
  108255:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108259:	89 55 f4             	mov    %edx,-0xc(%ebp)
  10825c:	89 f2                	mov    %esi,%edx
  10825e:	89 7d e8             	mov    %edi,-0x18(%ebp)
  108261:	89 c7                	mov    %eax,%edi
  108263:	d3 ea                	shr    %cl,%edx
  108265:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108269:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  10826c:	89 c2                	mov    %eax,%edx
  10826e:	d3 e6                	shl    %cl,%esi
  108270:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  108274:	d3 ea                	shr    %cl,%edx
  108276:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  10827a:	09 d6                	or     %edx,%esi
  10827c:	89 f0                	mov    %esi,%eax
  10827e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
  108281:	d3 e7                	shl    %cl,%edi
  108283:	89 f2                	mov    %esi,%edx
  108285:	f7 75 f4             	divl   -0xc(%ebp)
  108288:	89 d6                	mov    %edx,%esi
  10828a:	f7 65 e8             	mull   -0x18(%ebp)
  10828d:	39 d6                	cmp    %edx,%esi
  10828f:	72 2b                	jb     1082bc <__umoddi3+0x11c>
  108291:	39 c7                	cmp    %eax,%edi
  108293:	72 23                	jb     1082b8 <__umoddi3+0x118>
  108295:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  108299:	29 c7                	sub    %eax,%edi
  10829b:	19 d6                	sbb    %edx,%esi
  10829d:	89 f0                	mov    %esi,%eax
  10829f:	89 f2                	mov    %esi,%edx
  1082a1:	d3 ef                	shr    %cl,%edi
  1082a3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
  1082a7:	d3 e0                	shl    %cl,%eax
  1082a9:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
  1082ad:	09 f8                	or     %edi,%eax
  1082af:	d3 ea                	shr    %cl,%edx
  1082b1:	83 c4 20             	add    $0x20,%esp
  1082b4:	5e                   	pop    %esi
  1082b5:	5f                   	pop    %edi
  1082b6:	5d                   	pop    %ebp
  1082b7:	c3                   	ret    
  1082b8:	39 d6                	cmp    %edx,%esi
  1082ba:	75 d9                	jne    108295 <__umoddi3+0xf5>
  1082bc:	2b 45 e8             	sub    -0x18(%ebp),%eax
  1082bf:	1b 55 f4             	sbb    -0xc(%ebp),%edx
  1082c2:	eb d1                	jmp    108295 <__umoddi3+0xf5>
  1082c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  1082c8:	39 f2                	cmp    %esi,%edx
  1082ca:	0f 82 18 ff ff ff    	jb     1081e8 <__umoddi3+0x48>
  1082d0:	e9 1d ff ff ff       	jmp    1081f2 <__umoddi3+0x52>
