#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

// Function to recursively sum syscall counts from a process and its children
int sum_syscall_counts(struct proc *p, int mask)
{
  if (p == 0)
    return 0;

  int total = 0;

  // Add the syscall count for the current process
  if (mask < MAX_SYSCALLS)
    total += p->syscall_count[mask];

  // Recursively sum syscall counts for child processes
  struct proc *child;
  for (child = proc; child < &proc[NPROC]; child++)
  {
    if (child->parent == p && child->state != UNUSED)
    {
      total += sum_syscall_counts(child, mask); // Recursive call for child process
    }
  }

  return total;
}

// // System call handler for getSysCount
// uint64
// sys_getSysCount(void)
// {
//   int mask;

//   // Retrieve the mask argument
//   argint(0, &mask); // Removed the incorrect conditional check

//   // Validate that exactly one bit is set in the mask
//   int bit_count = 0;
//   int syscall_num = -1;
//   for(int i = 0; i < MAX_SYSCALLS; i++) {
//     if(mask & (1 << i)) {
//       bit_count++;
//       syscall_num = i;
//       if(bit_count > 1)
//         break;
//     }
//   }

//   if(bit_count != 1 || syscall_num < 0 || syscall_num >= MAX_SYSCALLS)
//     return -1; // Invalid mask

//   syscall_num=15;

//   // Get the current process
//   struct proc *p = myproc();

//   // Sum syscall counts from this process and all its children
//   int total = sum_syscall_counts(p, syscall_num);

//   return total;
// }

uint64 sys_getSysCount(void)
{

  int syscall_num;

  argint(0, &syscall_num);

  // printf("%d", syscall_num);

  // Validate that syscall_num is within the correct range
  if (syscall_num < 0 || syscall_num >= MAX_SYSCALLS)
  {
    return -1; // Invalid syscall number
  }

  // Get the current process
  struct proc *p = myproc();

  // Sum syscall counts from this process and all its children
  int total = p->syscall_count[syscall_num];

  return total;
}

// uint64 sys_sigalarm(void) {
//     int ticks;      // Number of ticks between alarms
//     uint64 handler; // Function pointer to the handler

//     // Retrieve the arguments passed from the user program
//     argint(0, &ticks);

//     argaddr(1, &handler);

//     // Set the alarm handler and interval for the current process
//     struct proc *p = myproc();

//     if (ticks == 0) {
//         // Disable the alarm
//         p->alarmticks = 0;
//         p->alarmhandler = 0; // Optionally set handler to NULL or 0
//     } else {
//         // Set the alarm parameters
//         p->alarmticks = ticks;
//         p->alarmhandler = handler;
//         p->ticks = 0; // Reset the tick counter when setting a new alarm
//     }

//     return 0; // Success
// }

int sys_sigalarm(void) {
  int ticks;
  uint64 handler;
  argint(0, &ticks);
  argaddr(1, &handler);
  
  struct proc *p = myproc();
  p->alarmticks = ticks;
  p->alarmhandler = handler;
  p->ticks = 0;
  // Reset the in_alarm_handler flag when setting a new alarm
  p->in_alarm_handler = 0;
  
  return 0;
}


// sys_sigreturn: Resets the process state after the handler is done
// int sys_sigreturn(void) {
//     struct proc *p = myproc();
//     if (p->in_alarm_handler) {
//         // Restore the trapframe to the saved state before the handler
//         memmove(p->trapframe, &p->alarmtrapframe, sizeof(struct trapframe));

//         // Reset the alarm handler flag
//         p->in_alarm_handler = 0;
//     }
//     return 0;
// }

int sys_sigreturn(void) {
  struct proc *p = myproc();
  if (p->in_alarm_handler) {
    // Save the current a0 value
    uint64 current_a0 = p->trapframe->a0;
    
    // Restore the trapframe to the saved state before the handler
    memmove(p->trapframe, &p->alarmtrapframe, sizeof(struct trapframe));
    
    // Restore the saved a0 value
    p->trapframe->a0 = current_a0;
    
    // Reset the alarm handler flag
    p->in_alarm_handler = 0;
  }
  return 0;
}

#ifdef LBS
// System call handler for settickets
uint64 sys_settickets(void)
{
  int new_tickets;

  // Retrieve the number of tickets from the syscall argument
  argint(0, &new_tickets);

  if (new_tickets < 1)
  {
    return -1; // Invalid number of tickets
  }

  // Get the current process
  struct proc *p = myproc();

  // Update the tickets
  acquire(&p->lock);
  p->tickets = new_tickets;
  release(&p->lock);

  return p->tickets;
}
#endif