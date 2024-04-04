#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#define MAX_HOST_LENGTH 256
#define MAX_LINE_LENGTH 1024

// Structure to store host and its redirect count
typedef struct {
    char host[MAX_HOST_LENGTH];
    int redirects;
} HostRedirect;

// Function to parse a line and extract host and response code
void parse_line(char *line, char *host, char *response_code) {
    sscanf(line, "%s %*s %*s %*s %s", host, response_code);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <log_file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    char *log_file = argv[1];
    FILE *file = fopen(log_file, "r");
    if (file == NULL) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }

    // Create pipe for communication between parent and child process
    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe");
        exit(EXIT_FAILURE);
    }

    pid_t pid = fork();

    if (pid == -1) {
        perror("fork");
        exit(EXIT_FAILURE);
    }

    if (pid == 0) { // Child process
        close(pipefd[0]); // Close unused read end

        // Redirect stdout to write end of the pipe
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);

        // Execute grep command to filter lines starting with '3'
        execlp("grep", "grep", "^[^ ]* - - .*\" 3[0-9][0-9] ", log_file, NULL);
        perror("execlp");
        exit(EXIT_FAILURE);
    } else { // Parent process
        close(pipefd[1]); // Close unused write end

        // Read from the pipe (output of grep command)
        FILE *pipe_stream = fdopen(pipefd[0], "r");
        if (pipe_stream == NULL) {
            perror("fdopen");
            exit(EXIT_FAILURE);
        }

        // Dynamically allocate memory for hosts array
        HostRedirect *hosts = NULL;
        int num_hosts = 0;
        int total_redirects = 0;
        int top_10_redirects = 0;

        char line[MAX_LINE_LENGTH];
        char host[MAX_HOST_LENGTH];
        char response_code[4];

        // Read each line from the pipe and count redirects for each host
        while (fgets(line, sizeof(line), pipe_stream)) {
            parse_line(line, host, response_code);

            // Check if host already exists in the array
            int i;
            for (i = 0; i < num_hosts; i++) {
                if (strcmp(hosts[i].host, host) == 0) {
                    hosts[i].redirects++;
                    break;
                }
            }

            // If host doesn't exist, add it to the array
            if (i == num_hosts) {
                // Reallocate memory for hosts array
                hosts = realloc(hosts, (num_hosts + 1) * sizeof(HostRedirect));
                if (hosts == NULL) {
                    perror("realloc");
                    exit(EXIT_FAILURE);
                }
                strcpy(hosts[num_hosts].host, host);
                hosts[num_hosts].redirects = 1;
                num_hosts++;
            }
            total_redirects++;
        }

        // Close pipe stream
        fclose(pipe_stream);

        // Wait for the child process to finish
        int status;
        waitpid(pid, &status, 0);

        // Sort hosts by redirect count in descending order
        for (int i = 0; i < num_hosts - 1; i++) {
            for (int j = i + 1; j < num_hosts; j++) {
                if (hosts[i].redirects < hosts[j].redirects) {
                    HostRedirect temp = hosts[i];
                    hosts[i] = hosts[j];
                    hosts[j] = temp;
                }
            }
        }

        // Calculate the total redirects for the top 10 hosts
        for (int i = 0; i < num_hosts && i < 10; i++) {
            top_10_redirects += hosts[i].redirects;
        }

        // Display the hosts with their redirect count and percentage
        for (int i = 0; i < num_hosts && i < 10; i++) {
            float percentage = (float)hosts[i].redirects * 100 / top_10_redirects;
            printf("%s - %d - %.0f%%\n", hosts[i].host, hosts[i].redirects, percentage);
        }

        // Free dynamically allocated memory
        free(hosts);
    }

    fclose(file);
    return 0;
}
