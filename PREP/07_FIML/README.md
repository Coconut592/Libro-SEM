# 07 · Datos faltantes: FIML

Script: `FIML.R`. Referencias: `TYPE = H1 missing` de Mplus (PDF), `EFA_Hogares.inp` y `missing = "fiml"`
de los Labs 4 y 5.

**Objetivo:** usar a todos los respondientes en lugar de solo los completos. FIML no imputa: cada caso
aporta a la verosimilitud con los ítems que sí respondió.

## Paso a paso

1. **¿Cuánto falta?** `b22` 33%, `b21` 33%, `b18` 22%, `b17` 16%, `b14` 14%, `c05` 13%; el resto, menos de
   11%. Con listwise solo quedan **4,019** (49%) en espacio público, 5,880 (71%) en colonia y 6,627 (80%)
   en G. Hay 246 patrones de faltantes en el espacio público; el más común es "completo" (4,019), luego
   "faltan solo `b21` y `b22`" (1,498) y "falta todo" (428).
2. **Faltantes estructurales.** Los 428 sin ningún ítem del espacio público están en 31 espacios, y en **10
   de ellos nadie tiene el bloque B**: parece un bloque no aplicado o no capturado. FIML no puede
   arreglarlo; falta el cuestionario.
3. **¿Al azar?** Quienes no contestan `b21` califican más bajo casi todo lo demás: 19 de 34 ítems difieren
   con p < .001 (`b26` −0.93, `b11` −0.59). **No es MCAR**; FIML supone MAR (depende de lo observado). El
   80% de quienes no contestan `b21` sí contesta `b26`, así que parece "no sé" más que un salto.
4. **Cobertura de covarianzas** (como la tabla de Mplus): mínima .59 (`b18`–`b21`), muy arriba del .10 que
   pide Mplus.
5. **Listwise vs FIML** (MLR):

   | Bloque | | N | CFI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | Espacio público | listwise | 4,019 | .979 | .058 | .036 |
   | | **FIML** | **7,814** | .979 | .058 | .031 |
   | Colonia | listwise | 5,880 | .943 | .058 | .034 |
   | | **FIML** | **8,239** | .938 | .059 | .034 |
   | G | listwise | 6,688 | .985 | .044 | .025 |
   | | **FIML** | **7,805** | .985 | .045 | .025 |

   Las cargas estandarizadas cambian como máximo .019, .036 y .014. Con FIML se usa de 17% a 94% más
   muestra con prácticamente la misma solución.

> **Supuesto a discutir:** si en los 10 espacios sin bloque B la pregunta "no aplica", FIML estima
> calificaciones de un espacio que no se evaluó. Con el cuestionario se puede decidir si esos espacios
> se excluyen.

Salidas: `ajuste_listwise_vs_FIML.csv`, `cargas_listwise_vs_FIML.csv` y `faltantes_por_item.csv`.
