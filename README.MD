# Documentación Principal de la Práctica

**Curso:** Maestría en Ciberseguridad
**Materia:** Principios de Seguridad en Sistemas Operativos
**Profesor:** Kevin Moraga ([kmoraga@tec.ac.cr](mailto:kmoraga@tec.ac.cr))
**Estudiante:** Luis Bonilla ([luisbonillah@gmail.com](mailto:luisbonillah@gmail.com))
**Carné:** 2023123456

---

## 1. Introducción General

Este documento consolida la documentación de las tres tareas asignadas durante el curso, enfocadas en la explotación y mitigación de vulnerabilidades en programas `Set-UID`. A través de condiciones de carrera y principios de seguridad como el **Principio de Privilegio Mínimo**, se estudia el comportamiento del sistema operativo y cómo protegerlo ante ataques en el contexto del acceso a archivos críticos como `/etc/passwd` y `/etc/shadow`.

Cada tarea se encuentra organizada en carpetas independientes: `Tarea1`, `Tarea2` y `Tarea3`, cada una con su propio `README.md` y scripts de ejecución.

En el ejercicio 2, se corrige la vulnerabilidad del programa `vulp.c` implementando una técnica de defensa basada en repetir las llamadas `access()` y `open()` varias veces, seguidas de una verificación del i-node para asegurar que el archivo abierto es el mismo que fue verificado. Esta estrategia, conocida como Protección A, hace que el ataque de condición de carrera sea altamente improbable y poco efectivo.

---

## 2. Instrucciones de Ejecución por Tarea

### Tarea 1 - Exploit de Condición de Carrera

```bash
cd Tarea1
chmod +x script_0_settingup.sh
./script_0_settingup.sh -p
chmod +x run_attack_passwd.sh
./run_attack_passwd.sh
```

### Tarea 2 - Protección A: Repetición y Validación

```bash
cd Tarea2
chmod +x script_0_settingup.sh
./script_0_settingup.sh -s
chmod +x run_attack_shadow.sh
./run_attack_shadow.sh
```

### Tarea 3 - Protección B: Privilegio Mínimo

```bash
cd Tarea3
chmod +x script_0_settingup.sh
./script_0_settingup.sh -p
chmod +x run_attack_passwd.sh
./run_attack_passwd.sh
```

---

## 3. Documentación del Ataque

Cada tarea documenta el proceso de ataque, desde la creación del symlink hasta la inserción de la entrada maliciosa, automatizando múltiples intentos con el fin de explotar la ventana entre `access()` y `fopen()`.

En la **Tarea 1**, el ataque tiene éxito cuando las condiciones de seguridad del sistema lo permiten (symlinks no protegidos y AppArmor detenido). Se observó que al reducir el valor de `#define DELAY 10000` en el archivo `vulp.c`, el tiempo entre `access()` y `fopen()` disminuye, reduciendo significativamente la ventana de oportunidad del atacante y dificultando el éxito del ataque.

En la **Tarea 2**, se implementa la **Protección A**: repetir múltiples veces las llamadas a `access()` y `open()`, y validar el inode del archivo al final del proceso. Esta defensa reduce la probabilidad de explotación hasta hacerla prácticamente inviable. El ataque no logra insertarse exitosamente en `/etc/shadow`.

En la **Tarea 3**, se aplica la **Protección B**: el **Principio de Privilegio Mínimo** mediante el uso de `seteuid()` para bajar temporalmente los privilegios del proceso. Esta mitigación elimina la ventana de ataque, resultando en un sistema no explotable por esta vía.

Los detalles específicos están documentados en:

* [`Tarea1/README.md`](./Tarea1/README.md)
* [`Tarea2/README.md`](./Tarea2/README.md)
* [`Tarea3/README.md`](./Tarea3/README.md)

---

## 4. Autoevaluación

| Tarea         | Porcentaje | Comentario                                        |
| ------------- | ---------- | ------------------------------------------------- |
| Tarea 1       | 25%        | Ataque básico exitoso con condiciones de carrera. |
| Tarea 2       | 25%        | Mitigación efectiva con repetición y validación.  |
| Tarea 3       | 25%        | Uso correcto de `seteuid()` como defensa.         |
| Documentación | 25%        | Documentación clara, estructurada y detallada.    |
| **Total**     | **100%**   | Cumplimiento total de los objetivos del curso.    |

---

## 5. Lecciones Aprendidas

* El tiempo y la concurrencia son elementos críticos en las condiciones de carrera.
* La validación a través de múltiples repeticiones reduce el éxito de ataques.
* El principio de privilegio mínimo es clave para desarrollar software seguro.
* Automatizar el ataque mejora la probabilidad de éxito y facilita el análisis del comportamiento del sistema.
* Desactivar protecciones como AppArmor puede ser necesario en ambientes controlados para estudiar estas vulnerabilidades.
* Las defensas bien implementadas como la comparación de inodes o el descenso temporal de privilegios hacen que el ataque sea **imposible de ejecutar exitosamente**, validando su efectividad.
* Reducir el valor de `DELAY` en `vulp.c` también actúa como un mecanismo de mitigación involuntario al cerrar la ventana temporal de ataque, dificultando la sincronización del exploit.

---

## 6. Comentarios sobre el Código

Cada carpeta contiene los siguientes archivos clave:

* `script_0_settingup.sh`: Compila y prepara los binarios y configuraciones iniciales.
* `attack.c`: Código principal que ejecuta el ataque de condición de carrera.
* `vulp.c`: Programa vulnerable con `access()` seguido de `fopen()`, posteriormente modificado para aplicar defensas.
* `run_attack_passwd.sh` y `run_attack_shadow.sh`: Scripts de ejecución automatizada.
* `script_1_attack_params.sh`: Ejecuta el ataque de forma parametrizada (-p o -s).

---

## 7. Video

[Video de demostración del ataque y defensas](https://youtu.be/dgb4Ev1INJQ)

---

## 8. Bibliografía

* Wenliang Du - SEED Labs
* Manuales de Linux: `man 2 access`, `man 2 symlink`, `man 2 seteuid`
* Curso Principios de Seguridad en Sistemas Operativos - Prof. Kevin Moraga

---

**Nota:** Este experimento está diseñado para ambientes de laboratorio controlados (como máquinas virtuales). No debe ejecutarse en sistemas de producción.
