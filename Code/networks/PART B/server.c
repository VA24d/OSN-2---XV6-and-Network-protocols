#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <fcntl.h>
#include <errno.h>
#include <ifaddrs.h>
#include <netdb.h>

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

void print_ip_addresses()
{
    struct ifaddrs *ifap, *ifa;
    struct sockaddr_in *sa;
    char *addr;

    getifaddrs(&ifap);
    for (ifa = ifap; ifa; ifa = ifa->ifa_next)
    {
        if (ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET)
        {
            sa = (struct sockaddr_in *)ifa->ifa_addr;
            addr = inet_ntoa(sa->sin_addr);
            printf("Interface: %s\tAddress: %s\n", ifa->ifa_name, addr);
        }
    }
    freeifaddrs(ifap);
}

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
            printf("Sent chunk %d\n", packet.seq_num);

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

int main()
{
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);
    char buffer[MAX_BUFFER];
    Packet packet;
    Ack ack;

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    memset(&client_addr, 0, sizeof(client_addr));

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(8080);

    if (bind(sockfd, (const struct sockaddr *)&server_addr, sizeof(server_addr)) < 0)
    {
        perror("Bind failed");
        exit(EXIT_FAILURE);
    }

    printf("Server is running. Available IP addresses:\n");
    print_ip_addresses();
    printf("Listening on port 8080...\n");

    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

    fd_set readfds;
    char received_messages[MAX_CHUNKS][MAX_BUFFER * MAX_CHUNKS] = {0};
    int received_chunks[MAX_CHUNKS] = {0};
    int total_chunks[MAX_CHUNKS] = {0};
    int message_id = 0;
    int ack_counter = 0; // Counter for ACK skipping


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
            send_message(sockfd, &client_addr, addr_len, message);
            printf(">> "); // Print prompt after sending a message
            fflush(stdout);
        }

        if (FD_ISSET(sockfd, &readfds))
        {
            Packet packet;
            int n = recvfrom(sockfd, &packet, sizeof(Packet), MSG_DONTWAIT, (struct sockaddr *)&client_addr, &addr_len);
            if (n > 0)
            {
                printf("Received chunk %d of %d\n", packet.seq_num, packet.total_chunks);

                if (packet.seq_num == 1)
                {
                    message_id = (message_id + 1) % MAX_CHUNKS;
                    memset(received_messages[message_id], 0, sizeof(received_messages[message_id]));
                    received_chunks[message_id] = 0;
                    total_chunks[message_id] = packet.total_chunks;
                }

                if (packet.seq_num <= total_chunks[message_id])
                {
                    strncpy(received_messages[message_id] + (packet.seq_num - 1) * CHUNK_SIZE,
                            packet.data,
                            CHUNK_SIZE);
                    received_chunks[message_id]++;
                }

                // Random ACK skipping logic
                ack_counter++;
                int should_send_ack = 1;

                // Uncomment the following line for final submission
                // should_send_ack = 1;

                // Comment out the following block for final submission
                if (ack_counter % 3 == 0)
                {
                    should_send_ack = 0;
                    printf("Randomly skipping ACK for chunk %d\n", packet.seq_num);
                }

                if (should_send_ack)
                {
                    Ack ack;
                    ack.seq_num = packet.seq_num;
                    sendto(sockfd, &ack, sizeof(Ack), 0, (struct sockaddr *)&client_addr, addr_len);
                    printf("Sent ACK for chunk %d\n", ack.seq_num);
                }
                else
                {
                    printf("DID NOT send ACK for chunk %d\n", packet.seq_num);
                }

                if (received_chunks[message_id] == total_chunks[message_id])
                {
                    printf("\nReceived message: %s\n", received_messages[message_id]);
                    printf(">> ");
                    fflush(stdout);
                }
            }
        }
    }

    close(sockfd);
    return 0;
}