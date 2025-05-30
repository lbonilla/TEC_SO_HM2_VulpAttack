/* vulp.c */

#include <stdio.h>
#include <unistd.h>
#include <string.h>  // <-- Necesario para strlen

#define DELAY 10000

int main()
{
    char * fn = "/tmp/XYZ";
    char buffer[60];
    FILE *fp;
    long int i;

    /* get user input */
    scanf("%50s", buffer );

    if (!access(fn, W_OK)) {
        /* simulating delay */
        for (i = 0; i < DELAY; i++) {
            int a = i * i;  // <-- Usar multiplicación, no XOR
        }

        fp = fopen(fn, "a+");
        fwrite("\n", sizeof(char), 1, fp);
        fwrite(buffer, sizeof(char), strlen(buffer), fp);
        fclose(fp);
    } else {
        printf("No permission \n");
    }
}
