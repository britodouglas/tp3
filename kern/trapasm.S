/*
 * Trap handler entry and exit code, written in assembly language.
 *
 * Copyright (C) 1997 Massachusetts Institute of Technology
 * See section "MIT License" in the file LICENSES for licensing terms.
 *
 * Derived from the MIT Exokernel and JOS.
 * Adapted for PIOS by Bryan Ford at Yale University.
 */

#include <inc/mmu.h>
#include <inc/trap.h>

#include <kern/cpu.h>



/* The TRAPHANDLER macro defines a globally-visible function for handling
 * a trap.  It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 */ 
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

.text

/*
 * Lab 1: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(tv0, 0);
/* TRAPHANDLER_NOEC(trap_debug, 1); */
TRAPHANDLER_NOEC(tv2, 2);
TRAPHANDLER_NOEC(tv3, 3);
TRAPHANDLER_NOEC(tv4, 4);
TRAPHANDLER_NOEC(tv5, 5);
TRAPHANDLER_NOEC(tv6, 6);
TRAPHANDLER_NOEC(tv7, 7);
TRAPHANDLER(tv8, 8);
/* TRAPHANDLER_NOEC(trap_coproc_seg_overrun, 9); */
TRAPHANDLER(tv10, 10);
TRAPHANDLER(tv11, 11);
TRAPHANDLER(tv12, 12);
TRAPHANDLER(tv13, 13);
TRAPHANDLER(tv14, 14);
/* TRAPHANDLER_NOEC(reserved, 15); */
TRAPHANDLER_NOEC(tv16, 16);
TRAPHANDLER(tv17, 17);
TRAPHANDLER_NOEC(tv18, 18);
TRAPHANDLER_NOEC(tv19, 19);
TRAPHANDLER_NOEC(tv30, 30);
TRAPHANDLER_NOEC(tv32, 32);
TRAPHANDLER_NOEC(tv39, 39);
TRAPHANDLER_NOEC(tv48, 48);
TRAPHANDLER_NOEC(tv49, 49);
TRAPHANDLER_NOEC(tv50, 50);
TRAPHANDLER_NOEC(tv500, 500);
TRAPHANDLER_NOEC(tv501, 501);


/*
 * Lab 1: Your code here for _alltraps
 */
.globl _alltraps
_alltraps:
	pushl %ds
	pushl %es
	pushl %fs
	pushl %gs
	pushal

	movw $CPU_GDT_KDATA, %ax
	movw %ax, %ds
	movw %ax, %es

	pushl %esp // passing trapframe addr as parameter
	call trap

//
// Trap return code.
// C code in the kernel will call this function to return from a trap,
// providing the 
// Restore the CPU state from a given trapframe struct
// and return from the trap using the processor's 'iret' instruction.
// This function does not return to the caller,
// since the new CPU state this function loads
// replaces the caller's stack pointer and other registers.
.globl	trap_return
.type	trap_return,@function
.p2align 4, 0x90		/* 16-byte alignment, nop filled */
trap_return:
	movl 0x4(%esp), %eax
	movl %eax, %esp // setting stack to trap frame
	popal
	popl %gs
	popl %fs
	popl %es
	popl %ds
	addl $0x8, %esp // trapno and errcode
	iret
