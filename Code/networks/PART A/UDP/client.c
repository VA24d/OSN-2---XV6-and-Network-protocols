#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <signal.h>
#include <stdatomic.h>

#define SERVER_PORT 12345
#define BUFFER_SIZE 1024

atomic_int running = 1;

void handle_signal(int signum) {
    atomic_store(&running, 0);
}

void *handle_server_response(void *arg) {
    int sockfd = *((int *)arg);
    char buffer[BUFFER_SIZE];
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);

    while (atomic_load(&running)) {
        memset(buffer, 0, BUFFER_SIZE);
        int n = recvfrom(sockfd, buffer, BUFFER_SIZE - 1, 0, (struct sockaddr *)&server_addr, &addr_len);
        if (n < 0) {
            if (atomic_load(&running)) {
                perror("recvfrom failed");
            }
            break;
        }
        buffer[n] = '\0';
        printf("%s\n", buffer);
        fflush(stdout);
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    int sockfd;
    struct sockaddr_in server_addr;
    pthread_t response_thread;
    char *server_ip;

    // Check for the correct number of arguments
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <Server IP Address>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    server_ip = argv[1];

    // Set up signal handling for graceful termination
    signal(SIGINT, handle_signal);

    // Create a UDP socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Server address setup
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    if (inet_pton(AF_INET, server_ip, &server_addr.sin_addr) <= 0) {
        fprintf(stderr, "Invalid address: %s\n", server_ip);
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Send "join" message to the server
    const char *join_message = "join";
    if (sendto(sockfd, join_message, strlen(join_message), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("Failed to send join message");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Create thread to handle server responses
    if (pthread_create(&response_thread, NULL, handle_server_response, &sockfd) != 0) {
        perror("Failed to create thread");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    // Game loop
    char move[10];
    while (atomic_load(&running)) {
        printf("Enter your move (or type 'exit' to quit): ");
        if (fgets(move, sizeof(move), stdin) == NULL) {
            break;
        }
        move[strcspn(move, "\n")] = 0;  // Remove newline

        if (strcmp(move, "exit") == 0) {
            break;
        }

        if (sendto(sockfd, move, strlen(move), 0, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
            perror("Failed to send move");
            break;
        }
    }

    // Clean up
    atomic_store(&running, 0);
    pthread_cancel(response_thread);
    pthread_join(response_thread, NULL);
    close(sockfd);
    printf("\nClient terminated gracefully.\n");
    return 0;
}