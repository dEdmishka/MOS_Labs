#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define SERVER_IP "127.0.0.1"
#define SERVER_PORT 8125
#define MESSAGE "test:1|g"

int main() {
    int sockfd;
    struct sockaddr_in server_addr;

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(SERVER_PORT);
    if (inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr) <= 0) {
        perror("inet_pton failed");
        exit(EXIT_FAILURE);
    }

    if (sendto(sockfd, MESSAGE, strlen(MESSAGE), 0, (const struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("sendto failed");
        exit(EXIT_FAILURE);
    }

    printf("Message sent to server: %s\n", MESSAGE);

    close(sockfd);
    return 0;
}
