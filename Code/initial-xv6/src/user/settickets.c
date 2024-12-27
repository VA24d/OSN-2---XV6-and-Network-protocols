// user/settickets.c
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"


int main(int argc, char *argv[]) {
    if(argc != 2){
        fprintf(2, "Usage: settickets <number_of_tickets>\n");
        exit(1);
    }

    int tickets = atoi(argv[1]);

    // Call the syscall directly
    int result = settickets(tickets);

    if(result == -1){
        fprintf(2, "Could not set tickets to %d for process with pid %d\n", tickets, getpid());
        exit(1);
    }

    printf("Process %d: Tickets set to %d\n", getpid(), tickets);
    exit(0);
}