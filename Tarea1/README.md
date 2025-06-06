# Documentación del Ataque de Condición de Carrera

**Curso:** Maestría en Ciberseguridad
**Materia:** Principios de Seguridad en Sistemas Operativos
**Profesor:** Kevin Moraga ([kmoraga@tec.ac.cr](mailto:kmoraga@tec.ac.cr))
**Estudiante:** Luis Bonilla ([luisbonillah@gmail.com](mailto:luisbonillah@gmail.com))
**Carné:** 2023123456

---

## 1. Introducción

En esta práctica se explota una vulnerabilidad de tipo condición de carrera presente en un programa Set-UID. Esta vulnerabilidad se produce cuando existen accesos concurrentes a un mismo recurso (archivo) entre procesos, y el orden de ejecución afecta el resultado. El objetivo del ataque es insertar una entrada maliciosa en archivos críticos del sistema como `/etc/passwd` o `/etc/shadow`, con el fin de obtener privilegios de superusuario.

## 2. Instrucciones para ejecutar el programa

### Preparación

```bash
chmod +x script_0_settingup.sh
./script_0_settingup.sh -p
```

Este script compila el programa vulnerable (`vulp`), el ataque (`attack`), configura permisos, y genera entradas maliciosas para `/etc/passwd` y `/etc/shadow`.

### Ataque a /etc/passwd

```bash
chmod +x run_attack_passwd.sh
./run_attack_passwd.sh
```

Esto intenta insertar una entrada tipo:

```
evil:x:0:0:Evil_User:/root:/bin/bash
```

### Ataque a /etc/shadow

```bash
chmod +x script_1_attack_params.sh
./script_1_attack_params.sh -s
```

Esto intenta insertar:

```
evil::20250:0:99999:7:::
```

La contraseña es "123".

## 3. Descripción del Ataque

El programa `vulp` realiza una verificación `access()` sobre `/tmp/XYZ` y posteriormente un `fopen()`. La condición de carrera se explota reemplazando `/tmp/XYZ` por un symlink hacia `/etc/passwd` o `/etc/shadow` justo entre esas dos operaciones.

El programa `attack` automatiza este proceso corriendo un bucle de hasta 50000 intentos, borrando el archivo dummy, creando el symlink y chequeando si el archivo objetivo fue modificado.

## 4. Documentación del Ataque

El ataque se automatiza con scripts que lanzan tanto el ataque como la ejecución masiva de `vulp`, alimentado con entradas maliciosas. Se detecta éxito si la entrada aparece al final de `/etc/passwd` o si el tiempo de modificación (`mtime`) de `/etc/shadow` cambia.

## 5. Autoevaluación

* El ataque funciona de manera efectiva en `/etc/passwd` cuando `fs.protected_symlinks` está desactivado y AppArmor detenido.
* En `/etc/shadow`, se logra detectar modificación pero se requiere más intentos.
* Problemas encontrados:

  * La sincronización entre `vulp` y `attack` es sensible al tiempo del sistema.
  * Fue necesario ejecutar múltiples intentos para lograr un ataque exitoso.
  * El tamaño del búfer en `vulp.c` (`char buffer[60]`) limitaba la longitud de las entradas maliciosas, forzando a usar cadenas menores a 60 caracteres.
  * Si el archivo `/tmp/XYZ` no se limpia adecuadamente entre iteraciones, puede quedar como archivo regular con dueño `root`, bloqueando futuros intentos hasta que se elimine manualmente.

### Calificación (Autoevaluada):

* Tarea 1: 25%
* Tarea 2: 20% (difícil ajustar bien la comparación de i-nodes)
* Tarea 3: 20% (seteuid implementado)
* Documentación: 25%
* **Total estimado: 100%**

## 6. Lecciones Aprendidas

* Las condiciones de carrera son altamente dependientes del tiempo y del comportamiento del sistema operativo.
* Automatizar el ataque mejora la probabilidad de éxito.
* Entender `seteuid` y los principios de privilegio mínimo es crucial para escribir software seguro.
* La protección con symlinks y AppArmor reduce significativamente la viabilidad del ataque.

## 7. Video

[Enlace al video de demostración del ataque](https://youtu.be/dgb4Ev1INJQ)

## 8. Bibliografía

* Wenliang Du - SEED Labs
* Manual de Linux: `man 2 access`, `man 2 symlink`, `man 2 seteuid`
* Curso Principios de Seguridad en Sistemas Operativos - Prof. Kevin Moraga

## 9. Comentarios sobre el Código

* `script_0_settingup.sh`: prepara el entorno de ataque. Este script compila los binarios (`vulp` y `attack`), configura los permisos `setuid`, desactiva restricciones como `fs.protected_symlinks` y `apparmor`, y genera las entradas maliciosas necesarias para `/etc/passwd` y `/etc/shadow`.

* `attack.c`: contiene lógica del atacante que reemplaza el archivo dummy por un symlink hacia el archivo objetivo, buscando explotar la ventana de condición de carrera.

* `vulp.c`: simula una aplicación vulnerable SetUID que realiza una verificación con `access()` y luego abre el archivo con `fopen()`, lo cual permite la explotación de TOCTOU.

* `script_1_attack_params.sh`: automatiza la ejecución del ataque contra archivos críticos de forma parametrizada con las opciones `-p` para `/etc/passwd` y `-s` para `/etc/shadow`.

* `run_attack_passwd.sh`: simplifica la ejecución del ataque específico contra `/etc/passwd`, invocando el script parametrizado.

* `run_attack_shadow.sh`: simplifica la ejecución del ataque contra `/etc/shadow`, utilizando el mismo script parametrizado con la opción `-s`.

---

**Advertencia**: Este experimento debe ejecutarse en entornos controlados como máquinas virtuales, nunca en sistemas de producción.
