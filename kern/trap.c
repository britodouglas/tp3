/*
 * Processor trap handling.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>

#include <kern/cpu.h>
#include <kern/trap.h>
#include <kern/cons.h>
#include <kern/init.h>
#include <kern/proc.h>
#include <kern/syscall.h>
#include <kern/pmap.h>

#include <dev/lapic.h>


// Interrupt descriptor table.  Must be built at run time because
// shifted function addresses can't be represented in relocation records.
static struct gatedesc idt[256];

// This "pseudo-descriptor" is needed only by the LIDT instruction,
// to specify both the size and address of th IDT at once.
static struct pseudodesc idt_pd = {
	sizeof(idt) - 1, (uint32_t) idt
};


static void
trap_init_idt(void)
{
	extern segdesc gdt[];
	extern void (*tv0)(void);
	extern void (*tv2)(void);
	extern void (*tv3)(void);
	extern void (*tv4)(void);
	extern void (*tv5)(void);
	extern void (*tv6)(void);
	extern void (*tv7)(void);
	extern void (*tv8)(void);
	extern void (*tv9)(void);
	extern void (*tv10)(void);
	extern void (*tv11)(void);
	extern void (*tv12)(void);
	extern void (*tv13)(void);
	extern void (*tv14)(void);
	extern void (*tv16)(void);
	extern void (*tv17)(void);
	extern void (*tv18)(void);
	extern void (*tv19)(void);
	extern void (*tv30)(void);
	extern void (*tv32)(void);
	extern void (*tv39)(void);
	extern void (*tv48)(void);
	extern void (*tv49)(void);
	extern void (*tv50)(void);
	extern void (*tv500)(void);
	extern void (*tv501)(void);

	cprintf("initializing idt\n");
	SETGATE(idt[0], 0, CPU_GDT_KCODE, &tv0, 0);
	SETGATE(idt[2], 0, CPU_GDT_KCODE, &tv2, 0);
	SETGATE(idt[3], 0, CPU_GDT_KCODE, &tv3, 3);
	SETGATE(idt[4], 0, CPU_GDT_KCODE, &tv4, 3);
	SETGATE(idt[5], 0, CPU_GDT_KCODE, &tv5, 0);
	SETGATE(idt[6], 0, CPU_GDT_KCODE, &tv6, 0);
	SETGATE(idt[7], 0, CPU_GDT_KCODE, &tv7, 0);
	SETGATE(idt[8], 0, CPU_GDT_KCODE, &tv8, 0);
	SETGATE(idt[10], 0, CPU_GDT_KCODE, &tv10, 0);
	SETGATE(idt[11], 0, CPU_GDT_KCODE, &tv11, 0);
	SETGATE(idt[12], 0, CPU_GDT_KCODE, &tv12, 0);
	SETGATE(idt[13], 0, CPU_GDT_KCODE, &tv13, 0);
	SETGATE(idt[14], 0, CPU_GDT_KCODE, &tv14, 0);
	SETGATE(idt[16], 0, CPU_GDT_KCODE, &tv16, 0);
	SETGATE(idt[17], 0, CPU_GDT_KCODE, &tv17, 0);
	SETGATE(idt[18], 0, CPU_GDT_KCODE, &tv18, 0);
	SETGATE(idt[19], 0, CPU_GDT_KCODE, &tv19, 0);
	SETGATE(idt[30], 0, CPU_GDT_KCODE, &tv30, 0);
	SETGATE(idt[T_IRQ0 + IRQ_TIMER], 0, CPU_GDT_KCODE, &tv32, 0);
	SETGATE(idt[T_IRQ0 + IRQ_SPURIOUS], 0, CPU_GDT_KCODE, &tv39, 0);
	SETGATE(idt[48], 0, CPU_GDT_KCODE, &tv48, 3);
	SETGATE(idt[49], 0, CPU_GDT_KCODE, &tv49, 0);
	SETGATE(idt[50], 0, CPU_GDT_KCODE, &tv50, 0);
}

void
trap_init(void)
{
	// The first time we get called on the bootstrap processor,
	// initialize the IDT.  Other CPUs will share the same IDT.
	if (cpu_onboot())
		trap_init_idt();

	// Load the IDT into this processor's IDT register.
	asm volatile("lidt %0" : : "m" (idt_pd));

	// Check for the correct IDT and trap handler operation.
	if (cpu_onboot())
		trap_check_kernel();
}

const char *trap_name(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}

void
trap_print_regs(pushregs *regs)
{
	cprintf("  edi  0x%08x\n", regs->edi);
	cprintf("  esi  0x%08x\n", regs->esi);
	cprintf("  ebp  0x%08x\n", regs->ebp);
//	cprintf("  oesp 0x%08x\n", regs->oesp);	don't print - useless
	cprintf("  ebx  0x%08x\n", regs->ebx);
	cprintf("  edx  0x%08x\n", regs->edx);
	cprintf("  ecx  0x%08x\n", regs->ecx);
	cprintf("  eax  0x%08x\n", regs->eax);
}

void
trap_print(trapframe *tf)
{
	cprintf("TRAP frame at %p\n", tf);
	trap_print_regs(&tf->regs);
	cprintf("  es   0x----%04x\n", tf->es);
	cprintf("  ds   0x----%04x\n", tf->ds);
	cprintf("  trap 0x%08x %s\n", tf->trapno, trap_name(tf->trapno));
	cprintf("  err  0x%08x\n", tf->err);
	cprintf("  eip  0x%08x\n", tf->eip);
	cprintf("  cs   0x----%04x\n", tf->cs);
	cprintf("  flag 0x%08x\n", tf->eflags);
	cprintf("  esp  0x%08x\n", tf->esp);
	cprintf("  ss   0x----%04x\n", tf->ss);
}

void gcc_noreturn
trap(trapframe *tf)
{
	// The user-level environment may have set the DF flag,
	// and some versions of GCC rely on DF being clear.
	asm volatile("cld" ::: "cc");

	// If this trap was anticipated, just use the designated handler.
	cpu *c = cpu_cur();
	// trap_print(tf);
	if (c->recover)
		c->recover(tf, c->recoverdata);

	// cprintf("cpu %d handling trap\n", c->id);

	// Lab 2: your trap handling code here!
	if(tf->trapno < T_IRQ0 && (tf->cs & 0x3)) {
		proc_ret(tf, -1);
	}

	if(tf->trapno == T_SYSCALL) syscall(tf);

	if(tf->trapno == (T_LTIMER)) {
		// cprintf("cpu %d timer\n", c->id);
		lapic_eoi();
		proc_yield(tf);
	}
	if(tf->trapno == (T_IRQ0 + IRQ_SPURIOUS)) {
		cprintf("cpu %d spurious timer\n", c->id);
		trap_return(tf);
	}
	if(tf->trapno == T_LERROR) {
		lapic_errintr();
		trap_return(tf);
	}

	// If we panic while holding the console lock,
	// release it so we don't get into a recursive panic that way.
	if (spinlock_holding(&cons_lock))
		spinlock_release(&cons_lock);
	trap_print(tf);
	panic("unhandled trap");
}


// Helper function for trap_check_recover(), below:
// handles "anticipated" traps by simply resuming at a new EIP.
static void gcc_noreturn
trap_check_recover(trapframe *tf, void *recoverdata)
{
	trap_check_args *args = recoverdata;
	trap_print(tf);
	cprintf("reip = %d\n", args->reip);
	tf->eip = (uint32_t) args->reip;	// Use recovery EIP on return
	args->trapno = tf->trapno;		// Return trap number
	trap_return(tf);
}

// Check for correct handling of traps from kernel mode.
// Called on the boot CPU after trap_init() and trap_setup().
void
trap_check_kernel(void)
{
	assert((read_cs() & 3) == 0);	// better be in kernel mode!

	cpu *c = cpu_cur();
	c->recover = trap_check_recover;
	trap_check(&c->recoverdata);
	c->recover = NULL;	// No more mr. nice-guy; traps are real again

	cprintf("trap_check_kernel() succeeded!\n");
}

// Check for correct handling of traps from user mode.
// Called from user() in kern/init.c, only in lab 1.
// We assume the "current cpu" is always the boot cpu;
// this true only because lab 1 doesn't start any other CPUs.
void
trap_check_user(void)
{
	assert((read_cs() & 3) == 3);	// better be in user mode!

	cpu *c = &cpu_boot;	// cpu_cur doesn't work from user mode!
	c->recover = trap_check_recover;
	trap_check(&c->recoverdata);
	c->recover = NULL;	// No more mr. nice-guy; traps are real again

	cprintf("trap_check_user() succeeded!\n");
}

void after_div0();
void after_breakpoint();
void after_overflow();
void after_bound();
void after_illegal();
void after_gpfault();
void after_priv();

// Multi-purpose trap checking function.
void
trap_check(void **argsp)
{
	volatile int cookie = 0xfeedface;
	volatile trap_check_args args;
	*argsp = (void*)&args;	// provide args needed for trap recovery

	// Try a divide by zero trap.
	// Be careful when using && to take the address of a label:
	// some versions of GCC (4.4.2 at least) will incorrectly try to
	// eliminate code it thinks is _only_ reachable via such a pointer.
	args.reip = after_div0;
	asm volatile("div %0,%0; after_div0:" : : "r" (0));
	assert(args.trapno == T_DIVIDE);

	// Make sure we got our correct stack back with us.
	// The asm ensures gcc uses ebp/esp to get the cookie.
	asm volatile("" : : : "eax","ebx","ecx","edx","esi","edi");
	assert(cookie == 0xfeedface);

	// Breakpoint trap
	args.reip = after_breakpoint;
	asm volatile("int3; after_breakpoint:");
	assert(args.trapno == T_BRKPT);

	// Overflow trap
	args.reip = after_overflow;
	asm volatile("addl %0,%0; into; after_overflow:" : : "r" (0x70000000));
	assert(args.trapno == T_OFLOW);

	// Bounds trap
	args.reip = after_bound;
	int bounds[2] = { 1, 3 };
	asm volatile("boundl %0,%1; after_bound:" : : "r" (0), "m" (bounds[0]));
	assert(args.trapno == T_BOUND);

	// Illegal instruction trap
	args.reip = after_illegal;
	asm volatile("ud2; after_illegal:");	// guaranteed to be undefined
	assert(args.trapno == T_ILLOP);

	// General protection fault due to invalid segment load
	args.reip = after_gpfault;
	asm volatile("movl %0,%%fs; after_gpfault:" : : "r" (-1));
	assert(args.trapno == T_GPFLT);

	// General protection fault due to privilege violation
	if (read_cs() & 3) {
		args.reip = after_priv;
		asm volatile("lidt %0; after_priv:" : : "m" (idt_pd));
		assert(args.trapno == T_GPFLT);
	}

	// Make sure our stack cookie is still with us
	assert(cookie == 0xfeedface);

	*argsp = NULL;	// recovery mechanism not needed anymore
}

