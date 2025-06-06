/* vulp_protegido_inode.c - Protección A: Múltiples condiciones de carrera (Repetición de access/open + verificación final) */

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/stat.h>
#include <stdlib.h>

#define DELAY 10000
#define REPS 3

int main() {
    const char *fn = "/tmp/XYZ";
    char buffer[60];
    struct stat stats[REPS];
    int fds[REPS];
    int success = 1;

    /* Entrada del usuario */
    scanf("%50s", buffer);

    for (int i = 0; i < REPS; i++) {
        if (access(fn, W_OK) != 0) {
            printf("[!] Sin acceso durante la repetición %d\n", i + 1);
            success = 0;
            break;
        }

        /* Simular retraso entre access y open */
        for (int j = 0; j < DELAY; j++) {
            int x = j * j;
        }

        fds[i] = open(fn, O_WRONLY);
        if (fds[i] < 0) {
            printf("[!] No se pudo abrir el archivo en la repetición %d\n", i + 1);
            success = 0;
            break;
        }

        if (fstat(fds[i], &stats[i]) != 0) {
            printf("[!] Error al obtener fstat() en repetición %d\n", i + 1);
            close(fds[i]);
            success = 0;
            break;
        }
    }

    if (success) {
        for (int i = 1; i < REPS; i++) {
            if (stats[i].st_ino != stats[0].st_ino || stats[i].st_dev != stats[0].st_dev) {
                printf("[!] Detección de condición de carrera: i-nodes no coinciden en repetición %d\n", i + 1);
                success = 0;
                break;
            }
        }
    }

    if (success) {
        dprintf(fds[0], "\n%s", buffer);
        printf("[+] Escritura completada tras pasar %d verificaciones.\n", REPS);
    } else {
        printf("[!] Operación abortada por detección de incoherencia.\n");
    }

    for (int i = 0; i < REPS; i++) {
        if (fds[i] >= 0) close(fds[i]);
    }

    return 0;
}
