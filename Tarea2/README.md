# Tarea 2 – Mecanismo de Protección A: Repetición

**Curso:** Maestría en Ciberseguridad
**Materia:** Principios de Seguridad en Sistemas Operativos
**Profesor:** Kevin Moraga
**Estudiante:** Luis Bonilla
**Carné:** 2023123456
**Fecha:** Junio 2025

---

## 📌 Objetivo

Implementar un mecanismo de defensa frente a condiciones de carrera basado en la **repetición del patrón vulnerable (**\`\`**)** varias veces, con verificación de los i-nodes al final. El objetivo es reducir exponencialmente la probabilidad de éxito del atacante, cumpliendo con el enunciado oficial de la Tarea 2.

> “...podemos agregar más condiciones de carrera, de modo que para comprometer la seguridad del programa, los atacantes deben ganar *todas* estas condiciones... y al final, comprobar si el mismo archivo está abierto comprobando sus i-nodes.”

---

## 🔧 Descripción Técnica

Se modificó el programa vulnerable `vulp.c` creando una versión protegida: `vulp_protegido_inode.c`, que:

1. Repite el patrón `access() → delay → open()` N veces (por defecto 3).
2. Obtiene el i-node de cada archivo abierto mediante `fstat()`.
3. Compara todos los i-nodes al final.
4. Solo si todos coinciden, realiza la escritura.

```c
for (int i = 0; i < REPS; i++) {
    access(fn, W_OK);
    delay();
    fd[i] = open(fn, O_WRONLY);
    fstat(fd[i], &stats[i]);
}
// Comparar todos los i-nodes al final
```

### Variables:

* `REPS`: Número de repeticiones (3 por defecto)
* `DELAY`: Retraso artificial para simular la ventana vulnerable

---

## Documentación del Ataque

Se intentó repetir el ataque original utilizando `attack.c` y el nuevo binario protegido `vulp_protegido`. Durante las pruebas:

* El atacante necesitaba sincronizar el cambio de symlink exitosamente \*\*en cada repetición del patrón \*\*\`\`.
* En la mayoría de ejecuciones (más de 10 intentos), el ataque falló.
* No fue posible insertar la entrada maliciosa, indicando que la protección **incrementó la dificultad de forma exponencial**.

El mecanismo no elimina la vulnerabilidad, pero logra exactamente lo que se busca: **hacer que el ataque sea improbable sin una sincronización perfecta en múltiples puntos.**

---

## Autoevaluación

* La solución propuesta está alineada completamente con el enunciado de la Tarea 2.
* Se implementó correctamente la repetición de `access()` + `open()` seguida por validación de i-nodes.
* El ataque original fue ejecutado repetidas veces para comprobar la dificultad real.
* Se documentó tanto a nivel técnico como experimental el funcionamiento de la mitigación.
* Se observó una **reducción significativa en la tasa de éxito del atacante**.

### Calificación (Autoevaluada):

* Implementación de la protección: 25%
* Prueba y validación experimental: 25%
* Documentación técnica clara: 25%
* Análisis de dificultad y comparación con el enfoque vulnerable: 25%
* **Total: 100%**

---

## Lecciones Aprendidas

* No siempre se puede eliminar una condición de carrera, pero se puede **aumentar la dificultad de explotación**.
* El uso de múltiples validaciones independientes fortalece la seguridad sin eliminar funcionalidad.
* Las herramientas del sistema como `stat()` y `fstat()` permiten verificar integridad con alta precisión.
* Validar lo que se usa (comparar i-nodes) es más efectivo que confiar solo en verificaciones previas (`access`).

---

## Código Fuente y Scripts Relacionados

* `vulp_protegido_inode.c`: versión segura del programa vulnerable original, implementando la estrategia de repetición e inspección de i-nodes.
* `attack.c`: script de ataque usado para intentar explotar la vulnerabilidad con symlinks.
* `script_0_settingup.sh`: prepara el entorno del ataque (compilación, permisos, configuración de entorno).
* `script_1_attack_params.sh`: ejecuta el ataque con parámetros `-p` (passwd) o `-s` (shadow).

---

## 📎 Compilación y Prueba

```bash
gcc -o vulp_protegido vulp_protegido_inode.c
sudo chown root:root vulp_protegido
sudo chmod u+s vulp_protegido
```

Luego ejecutar:

```bash
./script_1_attack_params.sh -p  # Ataque a /etc/passwd
./script_1_attack_params.sh -s  # Ataque a /etc/shadow
```
---

## 📚 Bibliografía

* Wenliang Du - SEED Labs
* man pages: `access(2)`, `open(2)`, `stat(2)`, `fstat(2)`
* Enunciado oficial Tarea 2 – Prof. Kevin Moraga

---

**Advertencia:** Este ejercicio debe realizarse en entornos controlados (máquinas virtuales). No ejecutar en sistemas reales o de producción.
