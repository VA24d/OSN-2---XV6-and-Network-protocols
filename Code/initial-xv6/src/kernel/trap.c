#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct spinlock tickslock;
uint ticks;

#ifdef MLFQ
extern void scheduler(void);
extern struct proc *myproc(void);
#endif

extern char trampoline[], uservec[], userret[];

// in kernelvec.S, calls kerneltrap().
void kernelvec();

extern int devintr();

void trapinit(void)
{
  initlock(&tickslock, "time");
}

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
  w_stvec((uint64)kernelvec);
}

//
// handle an interrupt, exception, or system call from user space.
// called from trampoline.S
// //
// void usertrap(void)
// {
//   int which_dev = 0;

//   if ((r_sstatus() & SSTATUS_SPP) != 0)
//     panic("usertrap: not from user mode");

//   // send interrupts and exceptions to kerneltrap(),
//   // since we're now in the kernel.
//   w_stvec((uint64)kernelvec);

//   struct proc *p = myproc();

//   // save user program counter.
//   p->trapframe->epc = r_sepc();

//   if (r_scause() == 8)
//   {
//     // system call

//     if (killed(p))
//       exit(-1);

//     // sepc points to the ecall instruction,
//     // but we want to return to the next instruction.
//     p->trapframe->epc += 4;

//     // an interrupt will change sepc, scause, and sstatus,
//     // so enable only now that we're done with those registers.
//     intr_on();

//     syscall();
//   }
//   else if ((which_dev = devintr()) != 0)
//   {
//     // ok
//   }
//   else
//   {
//     printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
//     printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
//     setkilled(p);
//   }

//   if (killed(p))
//     exit(-1);

//   // give up the CPU if this is a timer interrupt.
//   if (which_dev == 2)
//   {
// #ifdef MLFQ
//     if (p)
//     {
//       // Increment runtime
//       p->rtime++;

//       // Decrement remaining_ticks
//       p->remaining_ticks--;

//       // Check if time slice exhausted
//       if (p->remaining_ticks <= 0)
//       {
//         // Reset remaining_ticks based on current priority
//         if (p->priority < MLFQ_LEVELS - 1)
//         {
//           p->priority++;
//           p->remaining_ticks = time_slices[p->priority];
//           printf("Process %d demoted to priority %d at tick %d\n", p->pid, p->priority, ticks);
//         }
//         else
//         {
//           // For the lowest priority, reset the remaining_ticks for round-robin
//           p->remaining_ticks = time_slices[p->priority];
//         }

//         // Set process state to RUNNABLE and yield the CPU
//         p->state = RUNNABLE;
//         yield();
//       }
//     }
// #else
//     yield();
// #endif
//   }

//   usertrapret();
// }

void usertrap(void)
{
  int which_dev = 0;

  if ((r_sstatus() & SSTATUS_SPP) != 0)
    panic("usertrap: not from user mode");

  // send interrupts and exceptions to kerneltrap(),
  // since we're now in the kernel.
  w_stvec((uint64)kernelvec);

  struct proc *p = myproc();

  // save user program counter.
  p->trapframe->epc = r_sepc();

  if (r_scause() == 8) // System call
  {
    if (killed(p))
      exit(-1);

    // sepc points to the ecall instruction,
    // but we want to return to the next instruction.
    p->trapframe->epc += 4;

    // Enable interrupts, as we're done with registers.
    intr_on();

    syscall();
  }
  else if ((which_dev = devintr()) != 0) // Device interrupt
  {
    // ok
  }
  else // Unexpected trap
  {
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    setkilled(p);
  }

  if (killed(p))
    exit(-1);

  // Check if the interrupt was a timer interrupt
  if (which_dev == 2) // Timer interrupt
  {
#ifdef LBS
    // Increment the tick count for the process
    p->ticks++;

    // Check if the process has registered an alarm handler and if the ticks have reached the alarm threshold
    if (p->alarmticks > 0 && p->ticks >= p->alarmticks && !p->in_alarm_handler)
    {
      // Save the current trapframe before entering the handler
      memmove(&p->alarmtrapframe, p->trapframe, sizeof(struct trapframe));

      // Set the flag indicating we're in the alarm handler
      p->in_alarm_handler = 1;

      // Set the epc (program counter) to the alarm handler address
      p->trapframe->epc = p->alarmhandler;

      // Reset the ticks counter for the next alarm
      p->ticks = 0;
    }
#endif
#ifdef MLFQ

    // timer interrupt
    if (p->state == RUNNING)
    {
      p->remaining_ticks--;
      if (p->remaining_ticks <= 0)
      {
        yield();
      }
    }
#endif

    // If the process is in the alarm handler, we don't want to increment the runtime
  }
#ifdef MLFQ
  // if (p)
  // {
  //   // Increment runtime
  //   p->rtime++;

  //   // Decrement remaining_ticks
  //   p->remaining_ticks--;

  //   // Check if time slice exhausted
  //   if (p->remaining_ticks <= 0)
  //   {
  //     // Reset remaining_ticks based on current priority
  //     if (p->priority < MLFQ_LEVELS - 1)
  //     {
  //       p->priority++;
  //       p->remaining_ticks = time_slices[p->priority];
  //       printf("Process %d demoted to priority %d at tick %d\n", p->pid, p->priority, ticks);
  //     }
  //     else
  //     {
  //       // For the lowest priority, reset the remaining_ticks for round-robin
  //       p->remaining_ticks = time_slices[p->priority];
  //     }

  //     // Set process state to RUNNABLE and yield the CPU
  //     p->state = RUNNABLE;
  //     yield();
  //   }
  // }
#else
  yield();
#endif

  usertrapret();
}

//
// return to user space
//
void usertrapret(void)
{
  struct proc *p = myproc();

  // we're about to switch the destination of traps from
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
  p->trapframe->kernel_trap = (uint64)usertrap;
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()

  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
  x |= SSTATUS_SPIE; // enable interrupts in user mode
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
  ((void (*)(uint64))trampoline_userret)(satp);
}

// interrupts and exceptions from kernel code go here via kernelvec,
// on whatever the current kernel stack is.
void kerneltrap()
{
  int which_dev = 0;
  uint64 sepc = r_sepc();
  uint64 sstatus = r_sstatus();
  uint64 scause = r_scause();

  if ((sstatus & SSTATUS_SPP) == 0)
    panic("kerneltrap: not from supervisor mode");
  if (intr_get() != 0)
    panic("kerneltrap: interrupts enabled");

  if ((which_dev = devintr()) == 0)
  {
    printf("scause %p\n", scause);
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    panic("kerneltrap");
  }

  // give up the CPU if this is a timer interrupt.
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();

  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  // for (struct proc *p = proc; p < &proc[NPROC]; p++)
  // {
  //   acquire(&p->lock);
  //   if (p->state == RUNNING)
  //   {
  //     printf("here");
  //     p->rtime++;
  //   }
  //   // if (p->state == SLEEPING)
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
  release(&tickslock);
}

// check if it's an external interrupt or software interrupt,
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
      (scause & 0xff) == 9)
  {
    // this is a supervisor external interrupt, via PLIC.

    // irq indicates which device interrupted.
    int irq = plic_claim();

    if (irq == UART0_IRQ)
    {
      uartintr();
    }
    else if (irq == VIRTIO0_IRQ)
    {
      virtio_disk_intr();
    }
    else if (irq)
    {
      printf("unexpected interrupt irq=%d\n", irq);
    }

    // the PLIC allows each device to raise at most one
    // interrupt at a time; tell the PLIC the device is
    // now allowed to interrupt again.
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
  {
    // software interrupt from a machine-mode timer interrupt,
    // forwarded by timervec in kernelvec.S.

    if (cpuid() == 0)
    {
      clockintr();
    }

    // acknowledge the software interrupt by clearing
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  }
  else
  {
    return 0;
  }
}
