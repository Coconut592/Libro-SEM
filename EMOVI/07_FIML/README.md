# 07 · FIML: Origen social con datos faltantes

Script: `FIML.R` (unos 20 segundos). **Referencia:** la tesis estima con FIML porque el ISEI de la madre solo
existe en 1,149 de 3,117 casos y el de la ocupación actual en 1,911; recortar a los casos completos "podría
sesgar los estimadores" (Vargas y Lorenz, 2015). Aquí se hace el AFC de **Origen social** con sus indicadores en
la CDMX 2023 y se compara listwise contra FIML.

**Pregunta:** ¿cuánto se gana con FIML y cambia el resultado?

**Respuesta corta:** **3.8 veces más casos (195 → 740)** y errores estándar un 37 % menores, con cargas casi iguales.
El ajuste es mediocre (RMSEA ≈ .10 con FIML).

## Paso a paso

1. **Indicadores de Origen social.** Con las decisiones del proyecto (6 clases ocupacionales, sin ISEI):

   | Indicador | Qué es | Faltantes |
   |---|---|---|
   | `riq` | Índice de riqueza del hogar de origen (puntaje de [`05`](../05_Puntajes_Factoriales/)) | 0 % |
   | `educp` | Nivel educativo del padre (1 a 4) | 148 (20.0 %) |
   | `educm` | Nivel educativo de la madre (1 a 4) | 107 (14.5 %) |
   | `clasep` | Clase ocupacional del padre (1 a 6) | 146 (19.7 %) |
   | `clasem` | Clase ocupacional de la madre (1 a 6) | **416 (56.2 %)** |

   Las clases se tratan como **numéricas** (1 agrícolas … 6 no manual alta calificación): `lavaan` no ofrece FIML
   con ítems ordinales (probado: `missing = "fiml" not available in the categorical setting`), solo con
   indicadores continuos.
2. **Casos.** Solo **195** de 740 tienen los cinco indicadores (26 %); los 740 tienen al menos uno. La falta de
   `clasem` **no es casual**: 340 de los 416 son madres que "nunca trabajaron" (`p51` = 7). Eso pone en duda el supuesto
   de datos faltantes al azar (MAR) que usa FIML: los resultados deben leerse con esa cautela.
3. **Modelo.** Un factor, `OS =~ riq + educp + educm + clasep + clasem`, con MLR y `std.lv = TRUE`.

   | Modelo | N | χ² (5 gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | Listwise | 195 | 10.9 | .976 | .952 | .077 | .034 |
   | **FIML** | **740** | 24.5 | .956 | .912 | .098 | .034 |

   El ajuste con FIML es algo peor: con más casos la prueba ve más detalle. RMSEA .098 y TLI .912 son mediocres.
4. **Cargas estandarizadas y errores estándar:**

   | Indicador | Carga listwise | Carga FIML | EE listwise | EE FIML | EE FIML / listwise |
   |---|---|---|---|---|---|
   | `riq` | .64 | .64 | .048 | .028 | .58 |
   | `educp` | .64 | .63 | .073 | .044 | .60 |
   | `educm` | .81 | .78 | .064 | .041 | .64 |
   | `clasep` | .45 | .41 | .120 | .072 | .60 |
   | `clasem` | .65 | .60 | .096 | .068 | .71 |

   Las cargas cambian de .00 a .05 y los errores estándar bajan a cerca de dos tercios (.63 en promedio): **se gana
   precisión sin mover el resultado**. El indicador más débil es la clase del padre (.41).

**Salidas** (`output/`): `faltantes.csv`, `ajuste_listwise_vs_fiml.csv` y `cargas_listwise_vs_fiml.csv`.

**Cuidado.** Sin ISEI, esta latente es menos fina que la de la tesis: tratar 6 clases como numéricas es una
simplificación. Esto es solo el AFC de Origen social; el SEM completo (Origen → Educación → Primera ocupación →
Logro) no es parte de los 7 ejercicios.
