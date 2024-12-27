// syscount 32768 grep hello README

#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/fcntl.h"
#include "user/user.h"
#include "kernel/syscall.h"

#define MAX_SYSCALLS 32

char *syscall_names[MAX_SYSCALLS] = {
    [SYS_fork] "fork",
    [SYS_exit] "exit",
    [SYS_wait] "wait",
    [SYS_pipe] "pipe",
    [SYS_read] "read",
    [SYS_kill] "kill",
    [SYS_exec] "exec",
    [SYS_fstat] "fstat",
    [SYS_chdir] "chdir",
    [SYS_dup] "dup",
    [SYS_getpid] "getpid",
    [SYS_sbrk] "sbrk",
    [SYS_sleep] "sleep",
    [SYS_uptime] "uptime",
    [SYS_open] "open",
    [SYS_write] "write",
    [SYS_mknod] "mknod",
    [SYS_unlink] "unlink",
    [SYS_link] "link",
    [SYS_mkdir] "mkdir",
    [SYS_close] "close",
    // Additional syscalls as needed
};

int find_index(int x) {
    if (x <= 0 || (x & (x - 1)) != 0) {
        // x is not a positive power of 2
        return -1; // or any other error indicator
    }

    int index = 0;
    while (x > 1) {
        x >>= 1; // Shift x right by 1
        index++; // Increment index
    }

    return index; // Return the index i
}


int main(int argc, char *argv[])
{
  if (argc < 3)
  {
    printf("Usage: syscount <mask> command [args]\n");
    exit(1);
  }

  // for(int i=0; i< argc; i++)
  // {
  //   printf("%s\n", argv[i]);
  // }

  // Parse the mask
  int mask = atoi(argv[1]);

  // Verify that only one bit is set in the mask
  int bit_count = 0;
  int syscall_num = -1;

  for (int i = 0; i < MAX_SYSCALLS; i++)
  {
    if (mask & (1 << i))
    {
      bit_count++;
      syscall_num = i;
      if (bit_count > 1)
        break;
    }
  }


  if (bit_count != 1)
  {
    printf("syscount: mask must have exactly one bit set.\n");
    exit(1);
  }

  // Get the syscall name
  char *syscall_name = "unknown";
  if (syscall_num >= 0 && syscall_num < MAX_SYSCALLS && syscall_names[syscall_num] != 0)
    syscall_name = syscall_names[syscall_num];

  // Fork and execute the command
  int pid = fork();
  // if (pid < 0)
  // {
  //   printf("syscount: fork failed.\n");
  //   exit(1);
  // }

  if (pid == 0)
  {
    // In child: execute the specified command with arguments
    exec(argv[2], &argv[2]);

    // If exec fails
    printf("syscount: exec failed.\n");
    exit(1);
  }
  else
  {
    // In parent: wait for the child to finish
    wait(0);

    // Retrieve the syscall count
    int count = getSysCount(syscall_num);
    int caller_pid = getpid(); // PID of the syscount process

    // Print the result
    printf("PID %d called %s %d times.\n", caller_pid, syscall_name, count);
    exit(0);
  }
}