# 02 · Análisis Factorial Confirmatorio (AFC)

Script: `AFC.R` (todavía es un esqueleto). Estado: **✅ Cubierto por los archivos**.

## Qué traen los archivos

- `CFA_Espacio_Publico.inp` (Mplus): 3 factores (`EVEP`, `SEGEP`, `ACTEP`), MLR, intercepto de cada ítem en 0,
  `SAVEDATA: SAVE = FS`.
- `CFA_Hogares.inp` (Mplus): 5 factores (`IP`, `SG`, `CS`, `IN`, `SR`), ML, `SAVE = FS`.
- `cfa_espacio_publico.pdf`: salida de Mplus del piloto (abril 2013, **75 casos**): χ²(41) = 77.2,
  CFI = .890, RMSEA = .108, SRMR = .062. Es de una versión anterior (usa `B18`–`B21` sin recodificar).
- Laboratorio 2 (`lavaan` con `Evaluación`, `Inseguridad`, `Actividades`) y Laboratorio 5 (CFA de la colonia).

## Con la base (`PREP.dta`)

Sí. Con MLR y FIML (como Mplus): **espacio público** CFI = .979, RMSEA = .058, SRMR = .031 (7,814 casos);
**colonia** CFI = .938, RMSEA = .059, SRMR = .034 (8,239 casos); **bloque G** CFI = .985, RMSEA = .045,
SRMR = .025. Todas las cargas estandarizadas son ≥ .46 y no hay varianzas negativas.

## Qué falta

Solo las equivalencias piloto → base. Cuidado con `SR` (satisfacción): en la base tiene **2 ítems**
(`f01`, `f02`) y se correlaciona .77 con Infraestructura.

> Diagnóstico completo en [`00_Diagnostico/`](../00_Diagnostico/).
