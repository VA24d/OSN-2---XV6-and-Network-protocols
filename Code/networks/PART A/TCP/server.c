
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>
#include <pthread.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>


#define PORT 12345
#define BUFFER_SIZE 1024

#define PLAYER_O "\xE2\x97\x8B"
const char *CLEAR_SCREEN = "\033[2J\033[H";


char board[3][3];
int current_player = 1;
int client_fds[2];
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
    sprintf(buffer, "\n");
    for (int i = 0; i < 3; i++)
    {
        sprintf(buffer + strlen(buffer), " %c | %c | %c \n", board[i][0], board[i][1], board[i][2]);
        if (i < 2)
            strcat(buffer, "---|---|---\n");
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
            return (board[i][0] == 'X') ? 1 : 2;
        // Check columns
        if (board[0][i] == board[1][i] && board[1][i] == board[2][i] && board[0][i] != ' ')
            return (board[0][i] == 'X') ? 1 : 2;
    }
    // Check diagonals
    if (board[0][0] == board[1][1] && board[1][1] == board[2][2] && board[0][0] != ' ')
        return (board[0][0] == 'X') ? 1 : 2;
    if (board[0][2] == board[1][1] && board[1][1] == board[2][0] && board[0][2] != ' ')
        return (board[0][2] == 'X') ? 1 : 2;
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
void send_to_both(const char *message)
{
    for (int i = 0; i < 2; i++)
    {
        if (write(client_fds[i], message, strlen(message)) < 0)
        {
            perror("Write to client failed");
        }
    }
}

// Function to reset the game state
void reset_game()
{
    current_player = 1;
    initialize_board();
    send_to_both(CLEAR_SCREEN);
}

// Function to handle the "Play Again" prompt and responses
int handle_play_again()
{
    char response[BUFFER_SIZE];
    int play_again[2] = {0, 0}; // 0: no, 1: yes

    // Prompt both players
    send_to_both("Do you want to play again? (yes/no)\n");

    // Collect responses
    for (int i = 0; i < 2; i++)
    {
        memset(response, 0, BUFFER_SIZE);
        int valread = read(client_fds[i], response, BUFFER_SIZE - 1);
        if (valread <= 0)
        {
            printf("Player %d disconnected during play again prompt.\n", i + 1);
            return 0; // Treat as no
        }
        // Remove any trailing newline or carriage return
        response[strcspn(response, "\r\n")] = 0;

        if (strcmp(response, "yes") == 0 || strcmp(response, "YES") == 0)
        {
            play_again[i] = 1;
        }
        else
        {
            play_again[i] = 0;
        }
    }

    // Determine the outcome based on responses
    if (play_again[0] && play_again[1])
    {
        send_to_both("Both players agreed to play again. Starting new game...\n");
        reset_game();
        return 1; // Continue game loop
    }
    else if (!play_again[0] && !play_again[1])
    {
        send_to_both("Both players chose not to play again. Closing connections...\n");
        return -1; // Close connections
    }
    else
    {
        // One player wants to continue, the other does not
        char message1[BUFFER_SIZE], message2[BUFFER_SIZE];
        if (play_again[0])
        {
            // Player 1 wants to continue
            sprintf(message1, "Player 2 chose not to play again. Closing connections...\n");
            write(client_fds[0], message1, strlen(message1));
        }
        else
        {
            // Player 2 wants to continue
            sprintf(message2, "Player 1 chose not to play again. Closing connections...\n");
            write(client_fds[1], message2, strlen(message2));
        }
        return -1; // Close connections
    }
}

int get_local_ip(char *ip_buffer, size_t buffer_size)
{
    int sockfd;
    struct sockaddr_in servaddr;

    // Create a socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket creation failed");
        return -1;
    }

    // Specify a public server address (Google DNS) just to get the interface IP
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(80);  // Any arbitrary port will do (HTTP: 80)
    servaddr.sin_addr.s_addr = inet_addr("8.8.8.8");  // Google's public DNS server

    // Connect the socket
    if (connect(sockfd, (const struct sockaddr *)&servaddr, sizeof(servaddr)) < 0) {
        perror("connect");
        close(sockfd);
        return -1;
    }

    // Get the local address assigned to the socket
    struct sockaddr_in localaddr;
    socklen_t len = sizeof(localaddr);
    if (getsockname(sockfd, (struct sockaddr *)&localaddr, &len) == -1) {
        perror("getsockname");
        close(sockfd);
        return -1;
    }

    // Convert the IP address to string
    inet_ntop(AF_INET, &localaddr.sin_addr, ip_buffer, buffer_size);

    close(sockfd);  // Close the socket
    return 0;  // Success
}

int main()
{
    int server_fd, new_socket;
    struct sockaddr_in address;
    int addrlen = sizeof(address);
    char buffer[BUFFER_SIZE];


    char ip[INET6_ADDRSTRLEN]; // Buffer to hold the IP address

    if (get_local_ip(ip, sizeof(ip)) == 0)
    {
        printf("Local IP: %s\n", ip);
    }
    else
    {
        printf("Failed to get the local IP address.\n");
        exit(0);
    }


    // Initialize the game board
    initialize_board();

    // Create server socket
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0)
    {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }

    // Define server address
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    // Bind the socket to the address
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0)
    {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    // Listen for incoming connections
    if (listen(server_fd, 2) < 0)
    {
        perror("Listen");
        close(server_fd);
        exit(EXIT_FAILURE);
    }

    printf("Waiting for 2 players to connect...\n");

    // Accept connections from two players
    for (int i = 0; i < 2; i++)
    {
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0)
        {
            perror("Accept");
            for (int j = 0; j < i; j++)
                close(client_fds[j]);
            close(server_fd);
            exit(EXIT_FAILURE);
        }
        client_fds[i] = new_socket;
        char welcome[BUFFER_SIZE];
        sprintf(welcome, "Welcome Player %d!\n", i + 1);
        printf("Player %d has joint..\n", i+1);
        if (write(new_socket, welcome, strlen(welcome)) < 0)
        {
            perror("Write to client failed");
        }
    }

    printf("Both players connected. Starting game...\n");
    send_to_both("Both players connected. Starting game...\n");
    initialize_board();

    // Main game loop
    while (1)
    {
        pthread_mutex_lock(&lock);
        int player = current_player;
        int opponent = (current_player == 1) ? 2 : 1;
        char turn_msg[BUFFER_SIZE];
        sprintf(turn_msg, "Player %d's turn. Enter row and column (e.g., 1 1):\n", player);
        if (write(client_fds[player - 1], turn_msg, strlen(turn_msg)) < 0)
        {
            perror("Write to client failed");
            pthread_mutex_unlock(&lock);
            break;
        }
        pthread_mutex_unlock(&lock);

        // Receive move from the current player
        memset(buffer, 0, BUFFER_SIZE);
        int valread = read(client_fds[player - 1], buffer, BUFFER_SIZE - 1);
        if (valread <= 0)
        {
            printf("Player %d disconnected.\n", player);
            break;
        }
        buffer[valread] = '\0'; // Ensure null-terminated string

        int row, col;
        if (sscanf(buffer, "%d %d", &row, &col) != 2)
        {
            write(client_fds[player - 1], "Invalid input format. Use: row column\n", 40);
            continue;
        }

        pthread_mutex_lock(&lock);
        // Validate move
        if (row < 1 || row > 3 || col < 1 || col > 3 || board[row - 1][col - 1] != ' ')
        {
            write(client_fds[player - 1], "Invalid move. Try again.\n", strlen("Invalid move. Try again.\n"));
            pthread_mutex_unlock(&lock);
            continue;
        }
        // Make the move
        board[row - 1][col - 1] = (player == 1) ? 'X' : 'O';

        // Send updated board
        char board_state[BUFFER_SIZE];
        print_board(board_state);
        send_to_both(board_state);

        // Check for winner or draw
        int result = check_winner();
        if (result != 0)
        {
            if (result == 1)
            {
                send_to_both("Player 1 Wins!\n");
                printf("Player 1 Wins!\n"); // Server-side logging
            }
            else if (result == 2)
            {
                send_to_both("Player 2 Wins!\n");
                printf("Player 2 Wins!\n"); // Server-side logging
            }
            else
            {
                send_to_both("It's a Draw!\n");
                printf("It's a Draw!\n"); // Server-side logging
            }

            // Handle play again logic
            pthread_mutex_unlock(&lock); // Unlock before handling play again
            int play_again_result = handle_play_again();
            if (play_again_result == 1)
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

    // Close client connections
    for (int i = 0; i < 2; i++)
    {
        close(client_fds[i]);
    }
    // Close server socket
    close(server_fd);
    printf("Server shutting down.\n");
    return 0;
}