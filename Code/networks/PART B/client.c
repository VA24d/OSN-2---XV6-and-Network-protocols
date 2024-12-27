#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <fcntl.h>
#include <errno.h>

#define MAX_BUFFER 1024
#define CHUNK_SIZE 100
#define MAX_CHUNKS 10
#define TIMEOUT 100000 // 0.1 seconds in microseconds

typedef struct
{
    int seq_num;
    int total_chunks;
    char data[CHUNK_SIZE];
} Packet;

typedef struct
{
    int seq_num;
} Ack;

void send_message(int sockfd, struct sockaddr_in *addr, socklen_t addr_len, const char *message)
{
    Packet packet;
    Ack ack;
    int msg_len = strlen(message);
    int total_chunks = (msg_len + CHUNK_SIZE - 1) / CHUNK_SIZE;

    for (int i = 0; i < total_chunks; i++)
    {
        packet.seq_num = i + 1;
        packet.total_chunks = total_chunks;
        int chunk_size = (i == total_chunks - 1) ? (msg_len % CHUNK_SIZE) : CHUNK_SIZE;
        memcpy(packet.data, message + (i * CHUNK_SIZE), chunk_size);

        int retries = 0;
        int ack_received = 0;

        while (!ack_received && retries < 5)
        {
            sendto(sockfd, &packet, sizeof(Packet), 0, (struct sockaddr *)addr, addr_len);
            printf("Sent chunk %d of %d\n", packet.seq_num, total_chunks);

            struct timeval start, now;
            gettimeofday(&start, NULL);

            while (1)
            {
                gettimeofday(&now, NULL);
                if ((now.tv_sec - start.tv_sec) * 1000000 + (now.tv_usec - start.tv_usec) > TIMEOUT)
                {
                    break;
                }

                int n = recvfrom(sockfd, &ack, sizeof(Ack), MSG_DONTWAIT, NULL, NULL);
                if (n > 0 && ack.seq_num == packet.seq_num)
                {
                    printf("Received ACK for chunk %d\n", ack.seq_num);
                    ack_received = 1;
                    break;
                }

                usleep(1000);
            }

            if (!ack_received)
            {
                printf("Timeout for chunk %d, retrying...\n", packet.seq_num);
                retries++;
            }
        }

        if (!ack_received)
        {
            printf("Failed to send chunk %d after 5 retries\n", packet.seq_num);
        }
    }
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "Usage: %s <server_ip>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int sockfd;
    struct sockaddr_in server_addr;
    char buffer[MAX_BUFFER];
    Packet packet;
    Ack ack;

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);
    if (inet_pton(AF_INET, argv[1], &server_addr.sin_addr) <= 0)
    {
        perror("Invalid address/ Address not supported");
        exit(EXIT_FAILURE);
    }

    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

    printf("Connected to server at %s. Start chatting!\n", argv[1]);
    printf(">> "); // Print prompt after sending a message
    fflush(stdout);

    fd_set readfds;
    char received_message[MAX_BUFFER * MAX_CHUNKS] = {0};
    int current_chunk = 0;
    int total_chunks = 0;

    while (1)
    {
        FD_ZERO(&readfds);
        FD_SET(STDIN_FILENO, &readfds);
        FD_SET(sockfd, &readfds);

        int max_fd = (STDIN_FILENO > sockfd) ? STDIN_FILENO : sockfd;

        if (select(max_fd + 1, &readfds, NULL, NULL, NULL) < 0)
        {
            perror("select error");
            exit(EXIT_FAILURE);
        }

        if (FD_ISSET(STDIN_FILENO, &readfds))
        {
            char message[MAX_BUFFER];
            fgets(message, MAX_BUFFER, stdin);
            message[strcspn(message, "\n")] = 0;
            if (strcasecmp(message, "exit") == 0)
            {
                break;
            }
            send_message(sockfd, &server_addr, sizeof(server_addr), message);
            printf(">> "); // Print prompt after sending a message
            fflush(stdout);
        }

        if (FD_ISSET(sockfd, &readfds))
        {
            int n = recvfrom(sockfd, &packet, sizeof(Packet), MSG_DONTWAIT, NULL, NULL);
            if (n > 0)
            {
                printf("Received chunk %d of %d\n", packet.seq_num, packet.total_chunks);

                if (packet.seq_num == 1)
                {
                    memset(received_message, 0, sizeof(received_message));
                    current_chunk = 0;
                    total_chunks = packet.total_chunks;
                }

                if (packet.seq_num == current_chunk + 1)
                {
                    strcat(received_message, packet.data);
                    current_chunk++;
                }

                ack.seq_num = packet.seq_num;
                sendto(sockfd, &ack, sizeof(Ack), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
                printf("Sent ACK for chunk %d\n", ack.seq_num);

                if (current_chunk == total_chunks)
                {
                    printf("Received message: %s\n", received_message);
                    current_chunk = 0;
                    total_chunks = 0;
                    printf(">> "); // Print prompt after sending a message
                    fflush(stdout);
                }
            }
        }
    }

    close(sockfd);
    return 0;
}