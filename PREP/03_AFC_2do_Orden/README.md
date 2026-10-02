# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R`. Referencia: Laboratorio 3 (`G =~ f1 + f2 + f3`).

> El Lab 3 trae la técnica pero con otras bases; **ningún archivo define un segundo orden para el PREP**.
> Se probó donde tiene sentido por los datos: espacio público (`CALEP`) y colonia (`ENT`). Qué modelo
> quiere el PREP queda por confirmar.

## Paso a paso

1. **Modelos.** Igual que el Lab 3: `CALEP =~ EVEP + SEGEP + ACTEP` y
   `ENT =~ IP + SG + CS + INF + SR`, con `std.lv = TRUE`. En la colonia, con la carga marcadora por
   defecto **no converge**.
2. **Solución estandarizada:**

   | | Calificación | Seguridad | Actividades | | | |
   |---|---|---|---|---|---|---|
   | Espacio público, carga en `CALEP` | .86 | .58 | .75 | | | |

   | | IP | SG | CS | INF | SR |
   |---|---|---|---|---|---|
   | Colonia, carga en `ENT` | −.38 | .60 | .46 | .85 | .89 |

   Todas significativas y sin varianzas negativas. `ENT` explica casi todo de Infraestructura (72%) y
   Satisfacción (79%), y poco de Inseguridad (14%) y Cohesión (21%).
3. **Frente al primer orden:**

   | Modelo | gl | CFI | RMSEA | SRMR |
   |---|---|---|---|---|
   | Espacio público 1.er / 2.º orden | 41 / 41 | .979 / .979 | .058 / .058 | .031 / .031 |
   | Colonia 1.er orden | 265 | .938 | .059 | .034 |
   | Colonia 2.º orden | 270 | .936 | .060 | .043 |

   Espacio público: con 3 factores de primer orden el de segundo queda **justo identificado** (ajuste
   idéntico, no se puede contrastar). Colonia: la diferencia de χ² es significativa (con N = 8,239 siempre
   lo es), pero el CFI cae solo .002 (Chen, 2007: ≤ .01).
4. **Bloque G: no.** Sus 3 factores casi no se correlacionan (.05, .20, −.10): no hay factor general.

Salidas: `cargas_2do_orden.csv`, `ajuste_1er_vs_2do_orden.csv` y `diagrama_2do_orden_*.png`.
