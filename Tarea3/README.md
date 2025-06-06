# Documentación del Ataque de Condición de Carrera

**Curso:** Maestría en Ciberseguridad
**Materia:** Principios de Seguridad en Sistemas Operativos
**Profesor:** Kevin Moraga ([kmoraga@tec.ac.cr](mailto:kmoraga@tec.ac.cr))
**Estudiante:** Luis Bonilla ([luisbonillah@gmail.com](mailto:luisbonillah@gmail.com))
**Carné:** 2023123456

---

## 1. Introducción

En esta práctica se explota una vulnerabilidad de tipo condición de carrera presente en un programa Set-UID. Esta vulnerabilidad se produce cuando existen accesos concurrentes a un mismo recurso entre procesos, y el orden de ejecución afecta el resultado. El objetivo del ataque es insertar una entrada maliciosa en archivos críticos del sistema como `/etc/passwd` o `/etc/shadow`, con el fin de obtener privilegios de superusuario.

Además, se aborda el problema fundamental de que el programa vulnerable viola el Principio de Privilegio Mínimo. Aunque el programador intenta limitar el poder del usuario con `access()`, esto no es suficiente. La solución adecuada es aplicar `seteuid()` para reducir temporalmente los privilegios del proceso, asegurando que solo se eleven cuando sea estrictamente necesario.

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

La contraseña es vacía, por lo tanto no solicita contraseña.

## 3. Aplicación del Principio de Privilegio Mínimo

El programa vulnerable `vulp` se corrige utilizando `seteuid()` para deshabilitar temporalmente el privilegio de root antes de realizar la operación `access()`, y reactivarlo antes del `fopen()`. Esta práctica reduce la ventana de explotación del TOCTOU (Time Of Check To Time Of Use).

Al repetir el ataque con esta mitigación, el exploit **no tuvo éxito**, validando que aplicar el principio de privilegio mínimo reduce significativamente la posibilidad de explotación.

## 4. Documentación del Ataque

El ataque se automatiza con scripts que lanzan tanto el ataque como la ejecución masiva de `vulp`, alimentado con entradas maliciosas. Se detecta éxito si la entrada aparece al final de `/etc/passwd` o si el `mtime` de `/etc/shadow` cambia.

## 5. Autoevaluación

* El ataque funciona efectivamente contra `/etc/passwd` cuando las protecciones de symlinks y AppArmor están desactivadas.
* En `/etc/shadow`, se logra detectar modificación pero requiere más intentos.
* Al aplicar `seteuid()` correctamente, el ataque falla como se espera.

**Calificación estimada:**

* Tarea 1: 25%
* Tarea 2: 25%
* Tarea 3: 25%
* Documentación: 25%
* **Total estimado: 100%**

## 6. Lecciones Aprendidas

* Las condiciones de carrera son altamente dependientes del tiempo y del comportamiento del sistema operativo.
* Automatizar el ataque mejora la probabilidad de éxito.
* Entender `seteuid` y el principio de privilegio mínimo es crucial para escribir software seguro.
* La protección con symlinks y AppArmor reduce significativamente la viabilidad del ataque.

## 7. Video

[Enlace al video de demostración del ataque](https://youtu.be/dgb4Ev1INJQ)

## 8. Bibliografía

* Wenliang Du - SEED Labs
* Manual de Linux: `man 2 access`, `man 2 symlink`, `man 2 seteuid`
* Curso Principios de Seguridad en Sistemas Operativos - Prof. Kevin Moraga

## 9. Comentarios sobre el Código

* `script_0_settingup.sh`: Prepara el entorno de ataque, compila binarios y configura permisos.
* `attack.c`: Realiza la explotación mediante symlinks y condiciones de carrera.
* `vulp_privilegio_minimo.c`: Contiene la vulnerabilidad TOCTOU, luego mitigada con `seteuid()`.
* `script_1_attack_params.sh`: Automatiza ataques parametrizados (-p y -s).
* `run_attack_passwd.sh` y `run_attack_shadow.sh`: Scripts específicos para ejecutar el ataque.

---

**Advertencia:** Este experimento debe ejecutarse en entornos controlados como máquinas virtuales, nunca en sistemas de producción.
