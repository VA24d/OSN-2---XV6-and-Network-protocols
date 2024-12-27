#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

// #define MLFQ 1
// #define LBS 1

// Add at the top of kernel/proc.c or in an appropriate header
#define boost_interval 48 // Priority boosting interval in ticks

// kernel/proc.c

// Forward declarations for scheduler-specific functions
#ifdef LBS
// extern unsigned long rand_num(void);
unsigned long random_seed = 1;
unsigned long rand_num(void)
{
  random_seed = (random_seed * 1103515245 + 12345) & 0x7fffffff;
  return random_seed;
}
#endif

#ifdef MLFQ

#define MLFQ_LEVELS 4
#define BOOST_INTERVAL 48

struct proc; // Forward declaration

struct proc_queue
{
  struct proc *head;
  struct proc *tail;
};

struct
{
  struct spinlock lock;
  struct proc_queue queues[MLFQ_LEVELS];
  int time_slices[MLFQ_LEVELS];
} mlfq;

static int next_boost;

void mlfq_init(void)
{
  initlock(&mlfq.lock, "mlfq");
  for (int i = 0; i < MLFQ_LEVELS; i++)
  {
    mlfq.queues[i].head = mlfq.queues[i].tail = 0;
  }
  mlfq.time_slices[0] = 1;
  mlfq.time_slices[1] = 4;
  mlfq.time_slices[2] = 8;
  mlfq.time_slices[3] = 16;
  next_boost = BOOST_INTERVAL;
}

void enqueue(struct proc *p, int level)
{
  if (mlfq.queues[level].tail)
  {
    mlfq.queues[level].tail->next = p;
  }
  else
  {
    mlfq.queues[level].head = p;
  }
  mlfq.queues[level].tail = p;
  p->next = 0;
}

struct proc *dequeue(int level)
{
  struct proc *p = mlfq.queues[level].head;
  if (p)
  {
    mlfq.queues[level].head = p->next;
    if (!mlfq.queues[level].head)
    {
      mlfq.queues[level].tail = 0;
    }
  }
  return p;
}

void priority_boosting()
{
  struct proc *p;

  // Acquire the global lock for queue operations
  acquire(&mlfq.lock);

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock); // Lock individual process
    if (p->state == RUNNABLE || p->state == RUNNING)
    {
      p->priority = 0;                          // Boost to highest priority
      p->remaining_ticks = mlfq.time_slices[0]; // Reset time slice
      enqueue(p, 0);                            // Move to highest priority queue
    }
    release(&p->lock); // Unlock process
  }

  release(&mlfq.lock); // Release global lock
}

void mlfq_remove(struct proc *p, int level)
{
  acquire(&mlfq.lock); // Acquire the MLFQ lock

  struct proc_queue *queue = &mlfq.queues[level];
  struct proc *current = queue->head;
  struct proc *prev = 0;

  // Iterate through the queue to find the process to remove
  while (current != 0)
  {
    if (current == p)
    { // Found the process
      if (prev == 0)
      {
        // We're removing the head of the queue
        queue->head = current->next;
      }
      else
      {
        // Bypass the current process
        prev->next = current->next;
      }

      // If we're removing the tail
      if (current == queue->tail)
      {
        queue->tail = prev;
      }

      // Clean up process fields if necessary
      current->next = 0; // Clear the next pointer for safety
      break;             // Exit the loop since we've removed the process
    }
    prev = current;
    current = current->next; // Move to the next process
  }

  release(&mlfq.lock); // Release the MLFQ lock
}

#endif

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;
  p->rtime = 0;
  p->etime = 0;
  p->ctime = ticks;

  for (int i = 0; i < MAX_SYSCALLS; i++)
  {
    p->syscall_count[i] = 0;
  }

#ifdef LBS
  p->tickets = 1;          // Default tickets
  p->arrival_time = ticks; // Set arrival time to current tick
#endif

#ifdef MLFQ
  p->priority = 0;                          // Start at highest priority
  p->remaining_ticks = mlfq.time_slices[0]; // Set initial time slice
  p->next = 0;                              // Initialize next pointer for queue

  // Add the process to the highest priority queue
  acquire(&mlfq.lock);
  enqueue(p, 0);
  release(&mlfq.lock);
#endif
  // change
  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if (p->trapframe)
    kfree((void *)p->trapframe);
  p->trapframe = 0;
  if (p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  // p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

#ifdef MLFQ
  np->priority = 0;
  np->remaining_ticks = mlfq.time_slices[0];
  acquire(&mlfq.lock);
  enqueue(np, 0);
  release(&mlfq.lock);
#endif

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->etime = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }

          for (int i = 0; i < NELEM(pp->syscall_count); i++)
          {
            p->syscall_count[i] += pp->syscall_count[i];
            // printf("%d: %d\n", i, pp->syscall_count[i]);
          }

          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || killed(p))
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
// void scheduler(void)
// {
//   struct proc *p;
//   struct cpu *c = mycpu();

//   c->proc = 0;
//   for (;;)
//   {
//     // Avoid deadlock by ensuring that devices can interrupt.
//     intr_on();

//     for (p = proc; p < &proc[NPROC]; p++)
//     {
//       acquire(&p->lock);
//       if (p->state == RUNNABLE)
//       {
//         // Switch to chosen process.  It is the process's job
//         // to release its lock and then reacquire it
//         // before jumping back to us.
//         p->state = RUNNING;
//         c->proc = p;
//         swtch(&c->context, &p->context);

//         // Process is done running for now.
//         // It should have changed its p->state before coming back.
//         c->proc = 0;
//       }
//       release(&p->lock);
//     }
//   }
// }

void scheduler(void)
{
#ifdef LBS
  // Lottery-Based Scheduling Implementation
  struct proc *p;
  struct cpu *c = mycpu();

  static int printed = 0;
  if (!printed)
  {
    printf("Scheduler: Lottery-Based Scheduling (LBS) is active.\n");
    printed = 1;
  }

  c->proc = 0;
  for (;;)
  {
    intr_on();

    int total_tickets = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        total_tickets += p->tickets;
      }
      release(&p->lock);
    }

    if (total_tickets == 0)
      continue;

    int winning_ticket = (rand_num() % total_tickets) + 1;

    int current_sum = 0;
    struct proc *chosen_proc = 0;

    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        current_sum += p->tickets;
        if (current_sum >= winning_ticket)
        {
          chosen_proc = p;
          release(&p->lock);
          break; // Potential Issue: Lock not released before break
        }
      }
      release(&p->lock);
    }

    if (chosen_proc == 0)
      continue;

    struct proc *earlier_proc = chosen_proc;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      if (p == chosen_proc)
        continue;

      acquire(&p->lock);
      if (p->state == RUNNABLE && p->tickets == chosen_proc->tickets && p->arrival_time < chosen_proc->arrival_time)
      {
        earlier_proc = p;
        release(&p->lock);
        break;
      }
      release(&p->lock);
    }

    chosen_proc = earlier_proc;

    // Switch to chosen process
    acquire(&chosen_proc->lock);
    if (chosen_proc->state == RUNNABLE)
    {
      chosen_proc->state = RUNNING;
      c->proc = chosen_proc;
      swtch(&c->context, &chosen_proc->context);
      c->proc = 0;
    }
    release(&chosen_proc->lock);
  }

#elif defined(MLFQ)
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;

  printf("Scheduler: Multi-Level Feedback Queue (MLFQ) is active.\n");

  for (;;)
  {
    intr_on(); // Enable interrupts

    // Perform priority boosting if necessary
    if (ticks >= next_boost)
    {
      priority_boosting(); // Ensure this function properly handles locks
    }

    acquire(&mlfq.lock); // Acquire MLFQ lock

    for (int q = 0; q < MLFQ_LEVELS; q++)
    {
      while ((p = dequeue(q)) != 0)
      {                    // Dequeue from the current queue
        acquire(&p->lock); // Acquire the process lock

        if (p->state == RUNNABLE)
        {

          printf("pid: %d, q: %d, ticks: %d\n", p->pid, q, ticks);
      
          p->state = RUNNING; // Set state to RUNNING
          c->proc = p;        // Set current process

          release(&mlfq.lock);             // Release MLFQ lock before switching
          swtch(&c->context, &p->context); // Context switch to the process
          c->proc = 0;                     // Clear current process after returning

          // Reacquire MLFQ lock after returning
          acquire(&mlfq.lock);

          // Check the state of the process after returning
          if (p->state == RUNNABLE)
          {
            // Check if ticks need to be decremented and priority adjusted
            p->remaining_ticks--;
            if (p->remaining_ticks <= 0)
            {
              if (p->priority < MLFQ_LEVELS - 1)
              {
                p->priority++;
              }
              p->remaining_ticks = mlfq.time_slices[p->priority]; // Reset remaining ticks
            }
            enqueue(p, p->priority); // Requeue based on new priority
          }
        }

        release(&p->lock); // Release the process lock
      }
    }
    release(&mlfq.lock); // Release MLFQ lock after processing all queues
  }
#else
  // Default Round-Robin (RR) Scheduling Implementation
  struct proc *p;
  struct cpu *c = mycpu();

  static int printed = 0;
  if (!printed)
  {
    printf("Scheduler: Round Robin Scheduling (RR) is active.\n");
    printed = 1;
  }

  c->proc = 0;
  for (;;)
  {
    // Enable interrupts on this processor.
    intr_on();

    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process. It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
#endif
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
#ifdef MLFQ
  struct proc *p = myproc();
  acquire(&mlfq.lock); // Acquire MLFQ lock
  acquire(&p->lock);   // Acquire the process lock

  if (p->state == RUNNING)
  {
    p->state = RUNNABLE;  // Set to RUNNABLE
    p->remaining_ticks--; // Decrement remaining ticks

    // Check if remaining ticks are zero and adjust priority accordingly
    if (p->remaining_ticks <= 0)
    {
      if (p->priority < MLFQ_LEVELS - 1)
      {
        p->priority++;
      }
      p->remaining_ticks = mlfq.time_slices[p->priority]; // Reset remaining ticks
    }
    enqueue(p, p->priority); // Enqueue the process based on its priority
  }

  release(&mlfq.lock); // Release MLFQ lock
  sched(); // Call scheduler
  // Important: Call sched() while holding the process lock
  release(&p->lock);   // Release the process lock before switching


#else
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
#endif
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

#ifdef MLFQ
  // acquire(&mlfq.lock);
  mlfq_remove(p, p->priority);
  // release(&mlfq.lock);
#endif

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
#ifdef MLFQ
        acquire(&mlfq.lock);
        enqueue(p, p->priority);
        release(&mlfq.lock);
#endif
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;

  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
#ifdef MLFQ
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s priority: %d remaining_ticks: %d\n", p->pid, state, p->name, p->priority, p->remaining_ticks);
  }
#else
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
#endif
}

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->rtime;
          *wtime = np->etime - np->ctime - np->rtime;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
    }
    release(&p->lock);
  }
}