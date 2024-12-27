#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define PORT 12345
#define BUFFER_SIZE 1024

#define PLAYER_O "\xE2\x97\x8B"
const char *CLEAR_SCREEN = "\033[2J\033[H";

// Player symbols
#define PLAYER_X_SYMBOL 'X'
#define PLAYER_O_SYMBOL 'O'

// Structure to store client information
typedef struct {
    struct sockaddr_in addr;
    socklen_t addr_len;
} ClientInfo;

char board[3][3];
int current_player = 1;
ClientInfo clients[2];
int client_count = 0;
pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;

// Function to initialize the game board
void initialize_board()
{
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            board[i][j] = ' ';
        }
    }
}

// Function to print the current state of the board into a buffer
void print_board(char *buffer)
{
    sprintf(buffer, "%s\n", CLEAR_SCREEN); // Clear screen before displaying the board
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 3; j++)
        {
            char symbol[5];
            if(board[i][j] == 'O') {
                strcpy(symbol, PLAYER_O); // Unicode circle
            }
            else {
                snprintf(symbol, sizeof(symbol), "%c", board[i][j]);
            }
            strcat(buffer, " ");
            strcat(buffer, symbol);
            strcat(buffer, " ");
            if(j < 2) strcat(buffer, "|");
        }
        strcat(buffer, "\n");
        if(i < 2) strcat(buffer, "---|---|---\n");
    }
    strcat(buffer, "\n");
}

// Function to check if there's a winner or a draw
int check_winner()
{
    // Check rows and columns
    for (int i = 0; i < 3; i++)
    {
        // Check rows
        if (board[i][0] == board[i][1] && board[i][1] == board[i][2] && board[i][0] != ' ')
            return (board[i][0] == PLAYER_X_SYMBOL) ? 1 : 2;
        // Check columns
        if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != ' ')
            return (board[0][i] == PLAYER_X_SYMBOL) ? 1 : 2;
    }
    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ')
        return (board[0][0] == PLAYER_X_SYMBOL) ? 1 : 2;
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')
        return (board[0][2] == PLAYER_X_SYMBOL) ? 1 : 2;
    // Check for draw
    int draw = 1;
    for (int i = 0; i < 3 && draw; i++)
    {
        for (int j = 0; j < 3 && draw; j++)
        {
            if (board[i][j] == ' ')
            {
                draw = 0;
            }
        }
    }
    if (draw)
        return 3;
    return 0;
}

// Function to send a message to both clients
void send_to_both(int server_fd, const char *message)
{
    for(int i = 0; i < 2; i++)
    {
        if(sendto(server_fd, message, strlen(message), 0, (struct sockaddr *)&clients[i].addr, clients[i].addr_len) < 0)
        {
            perror("sendto failed");
        }
    }
}

// Function to reset the game state
void reset_game(int server_fd)
{
    current_player = 1;
    initialize_board();
    send_to_both(server_fd, CLEAR_SCREEN);
}

// Function to get player index based on client address
int get_player_index(struct sockaddr_in *addr)
{
    for(int i = 0; i < 2; i++)
    {
        if(addr->sin_addr.s_addr == clients[i].addr.sin_addr.s_addr &&
           addr->sin_port == clients[i].addr.sin_port)
        {
            return i;
        }
    }
    return -1; // Unknown client
}

// Function to handle the "Play Again" prompt and responses
int handle_play_again(int server_fd)
{
    char response[BUFFER_SIZE];
    int play_again[2] = {0, 0}; // 0: no, 1: yes

    // Prompt both players
    send_to_both(server_fd, "Do you want to play again? (yes/no)\n");

    // Collect responses
    for(int i = 0; i < 2; i++)
    {
        memset(response, 0, BUFFER_SIZE);
        struct sockaddr_in recv_addr;
        socklen_t recv_len = sizeof(recv_addr);
        int n = recvfrom(server_fd, response, BUFFER_SIZE - 1, 0, (struct sockaddr *)&recv_addr, &recv_len);
        if(n < 0)
        {
            perror("recvfrom failed during play again prompt");
            printf("Player %d disconnected during play again prompt.\n", i + 1);
            return 0; // Treat as no
        }
        response[n] = '\0';

        // Verify the responder is the expected player
        int sender = get_player_index(&recv_addr);
        if(sender != i)
        {
            // Ignore messages from other players
            i--; // Retry this player's response
            continue;
        }

        // Remove any trailing newline or carriage return
        response[strcspn(response, "\r\n")] = 0;

        if(strcmp(response, "yes") == 0 || strcmp(response, "YES") == 0)
        {
            play_again[i] = 1;
        }
        else
        {
            play_again[i] = 0;
        }
    }

    // Determine the outcome based on responses
    if(play_again[0] && play_again[1])
    {
        send_to_both(server_fd, "Both players agreed to play again. Starting new game...\n");
        reset_game(server_fd);
        return 1; // Continue game loop
    }
    else if(!play_again[0] && !play_again[1])
    {
        send_to_both(server_fd, "Both players chose not to play again. Closing connections...\n");
        return -1; // Close connections
    }
    else
    {
        // One player wants to continue, the other does not
        char message1[BUFFER_SIZE], message2[BUFFER_SIZE];
        if(play_again[0])
        {
            // Player 1 wants to continue
            sprintf(message1, "Player 2 chose not to play again. Closing connections...\n");
            sendto(server_fd, message1, strlen(message1), 0, (struct sockaddr *)&clients[0].addr, clients[0].addr_len);
        }
        else
        {
            // Player 2 wants to continue
            sprintf(message2, "Player 1 chose not to play again. Closing connections...\n");
            sendto(server_fd, message2, strlen(message2), 0, (struct sockaddr *)&clients[1].addr, clients[1].addr_len);
        }
        return -1; // Close connections
    }
}

// Function to print all IPv4 addresses of the server
void print_server_ips()
{
    struct ifaddrs *ifaddr, *ifa;
    char ip[INET_ADDRSTRLEN];

    if (getifaddrs(&ifaddr) == -1)
    {
        perror("getifaddrs");
        return;
    }

    printf("Server is running on the following IP addresses:\n");

    for (ifa = ifaddr; ifa != NULL; ifa = ifa->ifa_next)
    {
        if (ifa->ifa_addr == NULL)
            continue;

        // Check for IPv4 addresses
        if (ifa->ifa_addr->sa_family == AF_INET)
        {
            struct sockaddr_in *sa = (struct sockaddr_in *)ifa->ifa_addr;

            // Exclude loopback addresses
            if (strcmp(ifa->ifa_name, "lo") == 0)
                continue;

            // Convert IP to human-readable form
            if (inet_ntop(AF_INET, &(sa->sin_addr), ip, INET_ADDRSTRLEN) != NULL)
            {
                printf(" - %s: %s\n", ifa->ifa_name, ip);
            }
        }
    }

    freeifaddrs(ifaddr);
}

int main()
{
    int server_fd;
    struct sockaddr_in address;
    socklen_t addrlen = sizeof(address);
    char buffer[BUFFER_SIZE];

    // Initialize the game board
    initialize_board();

    // Create UDP socket
    if ((server_fd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    // Define server address
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY; // Listen on all interfaces
    address.sin_port = htons(PORT);

    // Bind the socket to the address
    if (bind(server_fd, (const struct sockaddr *)&address, sizeof(address)) < 0)
    {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }


    // Print server IP addresses
    print_server_ips();
    
    printf("Waiting for 2 players to connect...\n");

    // Accept connections from two players
    while(client_count < 2)
    {
        memset(buffer, 0, BUFFER_SIZE);
        struct sockaddr_in client_addr;
        socklen_t len = sizeof(client_addr);
        int n = recvfrom(server_fd, buffer, BUFFER_SIZE - 1, 0, (struct sockaddr *)&client_addr, &len);
        if(n < 0)
        {
            perror("recvfrom failed");
            continue;
        }
        buffer[n] = '\0';

        if(strcmp(buffer, "join") == 0 && client_count < 2)
        {
            clients[client_count].addr = client_addr;
            clients[client_count].addr_len = len;
            client_count++;

            // Send welcome message
            sprintf(buffer, "Welcome Player %d!\n", client_count);
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&client_addr, len);

            printf("Player %d joined from %s:%d\n", client_count, inet_ntoa(client_addr.sin_addr), ntohs(client_addr.sin_port));
        }
    }

    printf("Both players connected. Starting game...\n");
    send_to_both(server_fd, "Both players connected. Starting game...\n");
    initialize_board();

    // Main game loop
    while(1)
    {
        pthread_mutex_lock(&lock);
        int player = current_player;
        int opponent = (current_player == 1) ? 2 : 1;
        char turn_msg[BUFFER_SIZE];
        sprintf(turn_msg, "%sPlayer %d's turn. Enter row and column (e.g., 1 1):\n", CLEAR_SCREEN, player);
        sendto(server_fd, turn_msg, strlen(turn_msg), 0, (struct sockaddr *)&clients[player-1].addr, clients[player-1].addr_len);
        pthread_mutex_unlock(&lock);

        // Receive move from the current player
        memset(buffer, 0, BUFFER_SIZE);
        struct sockaddr_in recv_addr;
        socklen_t recv_len = sizeof(recv_addr);
        int n = recvfrom(server_fd, buffer, BUFFER_SIZE - 1, 0, (struct sockaddr *)&recv_addr, &recv_len);
        if(n < 0)
        {
            perror("recvfrom failed");
            break;
        }
        buffer[n] = '\0';

        // Identify which player sent the move
        int sender = get_player_index(&recv_addr);
        if(sender != player-1)
        {
            // Not the current player's turn
            sprintf(buffer, "It's not your turn.\n");
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&recv_addr, recv_len);
            continue;
        }

        // Parse move
        int row, col;
        if(sscanf(buffer, "%d %d", &row, &col) != 2)
        {
            sprintf(buffer, "Invalid input format. Use: row column\n");
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&clients[sender].addr, clients[sender].addr_len);
            continue;
        }

        pthread_mutex_lock(&lock);
        // Validate move
        if(row < 1 || row > 3 || col < 1 || col > 3 || board[row-1][col-1] != ' ')
        {
            sprintf(buffer, "Invalid move. Try again.\n");
            sendto(server_fd, buffer, strlen(buffer), 0, (struct sockaddr *)&clients[sender].addr, clients[sender].addr_len);
            pthread_mutex_unlock(&lock);
            continue;
        }

        // Make the move
        board[row-1][col-1] = (player == 1) ? PLAYER_X_SYMBOL : PLAYER_O_SYMBOL;

        // Send updated board
        char board_state[BUFFER_SIZE];
        print_board(board_state);
        send_to_both(server_fd, board_state);

        // Check for winner or draw
        int result = check_winner();
        if(result != 0)
        {
            if(result == 1)
            {
                send_to_both(server_fd, "Player 1 Wins!\n");
                printf("Player 1 Wins!\n"); // Server-side logging
            }
            else if(result == 2)
            {
                send_to_both(server_fd, "Player 2 Wins!\n");
                printf("Player 2 Wins!\n"); // Server-side logging
            }
            else
            {
                send_to_both(server_fd, "It's a Draw!\n");
                printf("It's a Draw!\n"); // Server-side logging
            }

            // Handle play again logic
            pthread_mutex_unlock(&lock); // Unlock before handling play again
            int play_again_result = handle_play_again(server_fd);
            if(play_again_result == 1)
            {
                // Continue to next game
                continue;
            }
            else
            {
                // Close connections and exit
                break;
            }
        }

        // Switch player
        current_player = opponent;
        pthread_mutex_unlock(&lock);
    }

    // Close server socket
    close(server_fd);
    printf("Server shutting down.\n");
    return 0;
}