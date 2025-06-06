#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>

#define DELAY 10000

int main() {
    char *fn = "/tmp/XYZ";
    char buffer[60];
    FILE *fp;
    long int i;

    // Leer entrada
    scanf("%50s", buffer);

    uid_t ruid = getuid();   // UID real (usuario)
    uid_t euid = geteuid();  // UID efectivo (root)

    // Bajar privilegios temporalmente
    seteuid(ruid);

    if (!access(fn, W_OK)) {
        // Elevar privilegios otra vez (a root)
        seteuid(euid);

        // Simular retraso
        for (i = 0; i < DELAY; i++) {
            int a = i * i;
        }

        // Escribir en el archivo como root
        fp = fopen(fn, "a+");
        if (fp != NULL) {
            fwrite("\n", sizeof(char), 1, fp);
            fwrite(buffer, sizeof(char), strlen(buffer), fp);
            fclose(fp);
        } else {
            perror("fopen");
        }

        // Volver a desactivar privilegios
        seteuid(ruid);
    } else {
        printf("No permission\n");
    }

    return 0;
}
