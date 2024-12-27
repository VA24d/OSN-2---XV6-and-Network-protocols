// user/test_sched.c
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    if(argc != 2){
        fprintf(2, "Usage: test_sched <number_of_children>\n");
        exit(1);
    }

    int num_children = atoi(argv[1]);

    for(int i = 0; i < num_children; i++){
        int pid = fork();
        if(pid < 0){
            fprintf(2, "Fork failed\n");
            exit(1);
        }
        if(pid == 0){
            // Child process
            int tickets = (i % 3) + 1; // Assign tickets: 1, 2, 3, 1, 2, 3, ...
            if(settickets(tickets) == -1){
                fprintf(2, "Child %d: Could not set tickets to %d\n", getpid(), tickets);
                exit(1);
            }
            printf("Child %d: Tickets set to %d\n", getpid(), tickets);

            // Perform CPU-bound task
            for(int j = 0; j < 100000000; j++); // Busy loop

            exit(0);
        }
    }

    // Parent process waits for children to finish
    for(int i = 0; i < num_children; i++){
        wait(0);
    }

    exit(0);
}