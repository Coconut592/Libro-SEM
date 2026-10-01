# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R` (todavía es un esqueleto). Estado: **⚠️ Parcial**.

## Qué traen los archivos

- Laboratorio 3: sintaxis de `lavaan` (`G =~ f1 + f2 + f3`) y un modelo con indicadores formativos (`<~`).
  Usa **otras bases** (`exampleCFA1_ssd.dta`, `ExampleVivienda_ssd.dta`, `ExampleFormative_ssd.dta`), que
  no están en el repositorio. Ningún archivo define un segundo orden para el PREP.

## Con la base (`PREP.dta`)

Sí en lo técnico. **Espacio público:** con 3 factores de primer orden el de segundo orden queda justo
identificado (mismo ajuste, CFI = .979). **Colonia:** con 5 factores es contrastable; converge con
`std.lv = TRUE` (con la parametrización por defecto no converge) y da CFI = .936, RMSEA = .060 (primer
orden: .938 y .059). Cargas de segundo orden: IP −.38, SG .60, CS .46, INF .85, SR .89. **Bloque G:** los
3 factores casi no se correlacionan (.05, .20, −.10): no hay segundo orden que justificar.

## Qué falta

**Qué modelo de segundo orden se quiere para el PREP** (qué factores y con qué nombre). No está en los
archivos. Si se quieren replicar los ejemplos del Laboratorio 3, faltan sus tres `.dta`.

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
