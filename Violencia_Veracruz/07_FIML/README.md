# 07 · FIML: los seis ámbitos con datos faltantes

Script: `FIML.R` (unos 30 segundos). **Sin referencia propia.** Siguiendo EMOVI (indicadores 0/1) y Violencia Guerrero (faltantes por bloques), se compara el AFC
de seis ámbitos con eliminación por lista (*listwise*) y con **FIML**. Aquí solo **505 de 1,088** mujeres contestan los 24 ítems, y los faltantes no son
esporádicos: son **saltos de pregunta** (pareja, trabajo, escuela).

**Pregunta:** ¿cuánto se gana con FIML y qué tan creíble es el supuesto de datos faltantes al azar?

**Respuesta corta: FIML usa a las 1,088 mujeres en lugar de 505 (2.2 veces más) y el ajuste mejora (CFI .903 → .949), con errores estándar un ~32 % menores.**
Pero los faltantes **no son MCAR** (quien nunca trabajó reporta más violencia) y, sobre todo, **el salto significa que el constructo no aplica**: FIML
no debe leerse como "la violencia de pareja de las mujeres sin pareja".

> **Una restricción de `lavaan`:** no ofrece FIML con ítems ordinales (probado: `missing = "fiml" not available in the categorical setting`). Aquí los ítems 0/1 se
> tratan como **continuos con MLR**, como en EMOVI. Las cargas no son comparables con las del AFC ordinal (las correlaciones de Pearson entre ítems 0/1 están
> acotadas por sus frecuencias); sí lo son entre *listwise* y FIML.

## Paso a paso

1. **¿Cuántos datos faltan y dónde?** El 11.1 % de las celdas está vacío y solo **505 de 1,088** (46 %) contestan los 24 ítems.

   | Ámbito | Mujeres sin ningún ítem | % |
   |---|---|---|
   | Infancia | 0 | 0 % |
   | Familia | 5 | 0.5 % |
   | **Pareja** | **313** | **28.8 %** |
   | **Trabajo** | **249** | **22.9 %** |
   | Comunidad | 7 | 0.6 % |
   | Escuela | 57 | 5.2 % |

   Patrones por bloque: ninguno falta en 536 mujeres; falta solo pareja en 272, solo trabajo en 195, trabajo + escuela en 25, pareja + trabajo en 20 y solo escuela en 14.
   Con *listwise* se pierde el 54 % de la muestra, y con ella **todas** las mujeres sin pareja, sin trabajo o sin estudios.
2. **¿Son faltantes al azar?** FIML es insesgado si los datos son MCAR o MAR; *listwise* exige MCAR. La prueba de Little (1988) supone normalidad multivariada y **no es válida con
   ítems 0/1**, así que no se usa (en Violencia Guerrero sí, con escalas de 1 a 10).
   - **a) ¿Quien se salta un bloque responde distinto en los demás ítems?** (χ² por ítem; por azar ~5 % con p < .05):

     | Quien se salta | Ítems comparados | Con p < .05 | Esperados por azar |
     |---|---|---|---|
     | Pareja (313) | 19 | 1 | 1 |
     | **Trabajo (249)** | 20 | **8** | 1 |
     | Escuela (57) | 20 | 4 | 1 |

     Pareja pasa; **trabajo no**: quien nunca trabajó reporta **más** violencia (infancia `p142`: 35 % contra 24 %; pareja `p172`: 14 % contra 6 %; `p173`: 10 % contra 3 %). No es MCAR, y
     eliminar por lista **subestimaría** la violencia.
   - **b) Qué explica los saltos.** Son de cuestionario, así que dependen de variables observadas:

     | Condición | % que se salta el bloque si la cumple | % si no la cumple |
     |---|---|---|
     | Pareja: sin pareja actual (`p9` = soltera, separada, divorciada o viuda) | **87.2 %** | 0.8 % |
     | Trabajo: ama de casa (`p5` = 2) | 39.7 % | 6.6 % |
     | Escuela: sin estudios (`p4` = 1) | 28.8 % | 1.2 % |

     Es MAR (depende de lo observado), no MNAR: FIML es defendible. Pero `p9`, `p5` y `p4` **no están en el modelo** (podrían entrar como variables auxiliares) y, sobre todo, el salto
     significa que el constructo no aplica (paso 6).
3. **Listwise contra FIML** (MLR, `std.lv = TRUE`, ítems 0/1 como continuos):

   | Modelo | N | χ² (237 gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | Listwise | 505 | 377.6 | .903 | .887 | .045 | .056 |
   | **FIML** | **1,088** | 395.6 | **.949** | **.940** | **.034** | .045 |

   El ajuste con FIML es **mejor**, no peor (al revés que en EMOVI); no se investigó a qué se debe. Ninguno llega al .987 del AFC ordinal:
   es otra métrica (Pearson sobre ítems 0/1).
4. **Cargas estandarizadas y errores estándar.** Las cargas cambian poco en infancia, pareja y escuela (hasta .06) y más en los ítems raros:

   | Ítem | Listwise | FIML | | Ítem | Listwise | FIML |
   |---|---|---|---|---|---|---|
   | `p165` | .36 | **.48** | | `p193` | .38 | **.24** |
   | `p192` | .47 | **.60** | | `p185` | .64 | **.53** |
   | `p176` | .74 | .68 | | `p201` | .81 | .76 |

   Los errores estándar de FIML son **~.68** de los de *listwise* en promedio (de .34 en `p193` a .90 en `p186`): se gana precisión. Con otra matriz de información (esperada, `h1` sin
   estructura) el cociente es .73: la ganancia no depende de ese detalle. Las correlaciones entre factores cambian hasta .14 (y son de .18 a .46, más bajas que las ordinales).
   **Aviso de `lavaan`:** con FIML y ítems 0/1 dice que la matriz de varianzas de los parámetros es casi singular. Es esperable: la varianza de un ítem 0/1 es función de su media
   (*p*(1 − *p*)), así que hay dependencia exacta entre momentos. Las estimaciones y el ajuste no cambian; los errores estándar son aproximados. El script silencia el aviso y lo explica.
5. **Cobertura.** Proporción de mujeres con información para cada par de ítems: **mínima .505** (`p183` con `p173`: trabajo con pareja) y **media .80**; **41 de 276 parejas están por debajo de .70**.
   Mplus pide al menos .10: se cumple de sobra.
6. **Los faltantes de pareja son estructurales: ¿qué tanto importan?** A las 313 mujeres sin pareja, FIML (MAR) les trata el bloque de pareja como un dato que *podría* haber existido.
   Se compara FIML con las 1,088 y FIML solo con las **775** con pareja:

   | | Todas (1,088) | Solo con pareja (775) |
   |---|---|---|
   | CFI (robusto) | .949 | .930 |
   | Diferencia máxima en cargas | | .122 (`p185`; luego `p194` .085 y `p184` .062) |
   | Diferencia máxima en correlaciones entre factores | | .121 (hasta .037 las de pareja) |

   El modelo de medida se mueve poco, pero no nada, y los ítems que se mueven son raros. Es un resultado sobre el **modelo de medida**, no sobre la prevalencia de violencia de pareja:
   **FIML nunca debe leerse como "la violencia de pareja de las mujeres sin pareja".**

**Salidas** (`output/`): `faltantes.csv`, `faltantes_vs_resto.csv`, `ajuste_listwise_vs_fiml.csv`, `cargas_listwise_vs_fiml.csv` y `sensibilidad_con_pareja.csv`.

**Cuidado.**
- **MAR no se puede probar.** Little solo distingue MCAR de "no MCAR"; y aquí el salto de pregunta significa que, para esas mujeres, el ámbito no existe. Los resultados con FIML valen para el modelo de medida; los
  niveles de violencia por ámbito deben calcularse solo entre quienes lo contestan.
- Tratar ítems 0/1 como continuos es una simplificación; el análisis principal del proyecto es el ordinal (WLSMV, `missing = "pairwise"`).
- La ganancia de FIML es real (2.2 veces más casos, ajuste mejor), pero depende de un supuesto que aquí solo se cumple en parte.
