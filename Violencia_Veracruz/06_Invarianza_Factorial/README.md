# 06 · Invarianza factorial: edad y escolaridad

Script: `Invarianza_Factorial.R` (unos 70 segundos). **Sin referencia propia:** `Scripts.do` compara la clase de violencia entre grupos con una
regresión ordinal (`ologit`), pero **no prueba antes que los ítems se miden igual** en esos grupos. Este ejercicio llena ese hueco con los dos cortes que
la base permite. **No hay variable de sexo** (todas son mujeres) ni de región.

**Pregunta:** ¿miden igual los ítems de violencia a las mujeres de 18–44 y de 45 o más años, y a las de hasta primaria y de secundaria o más?

**Respuesta corta: sí en los dos cortes, pero solo con el modelo de 5 ámbitos (20 ítems, sin trabajo).** Con los cuatro ítems de trabajo, que son muy raros,
el modelo de seis ámbitos es **inadmisible** en uno de los dos grupos de cada corte. Con 5 ámbitos: ΔCFI = 0 en los dos y la prueba de χ² no rechaza
(p = .51 por edad, p = .37 por escolaridad).

## Paso a paso

1. **Grupos.** Edad (`p2`): **665** de 18 a 44 años y **421** de 45 o más (2 sin dato). Escolaridad (`p4`): **449** hasta primaria y **618** de secundaria o más
   (5 con "otro" y 16 sin dato, fuera). Otros cortes posibles (conocer los derechos de las mujeres, leer y escribir, recibir dinero) dejan
   grupos con 0 a 2 mujeres en alguno de los ítems raros ([`00_Diagnostico`](../00_Diagnostico/)).
2. **Requisito: el modelo debe ser admisible en cada grupo por separado.** Se llama inadmisible a un modelo que no converge o tiene una carga estandarizada
   mayor que 1 (varianza residual negativa, caso Heywood):

   | Corte | Grupo | N | 6 ámbitos: carga máx. | 5 ámbitos (sin trabajo): carga máx. |
   |---|---|---|---|---|
   | Edad | 18–44 | 665 | .952 ✅ | .954 ✅ |
   | Edad | 45+ | 421 | **1.014 ❌** | .967 ✅ |
   | Escolaridad | Hasta primaria | 449 | **1.002 ❌** | .958 ✅ |
   | Escolaridad | Secundaria o más | 618 | .966 ✅ | .966 ✅ |
   | Conoce derechos | No conoce | 281 | **1.106 ❌** | **1.078 ❌** |
   | Conoce derechos | Conoce | 794 | .954 ✅ | .958 ✅ |

   - **Seis ámbitos:** inadmisible en 45+ (la carga de `p186`, de trabajo, sale 1.01), en "hasta primaria" (1.002) y en "no conoce". En el grupo más chico los
     ítems de trabajo tienen entre 3 y 9 mujeres que dicen "Sí": el bloque no se sostiene al partir la muestra.
   - **Cinco ámbitos (20 ítems):** admisible por edad y por escolaridad. **No** por conocer los derechos de las mujeres (281 contra 794), que se deja fuera.
3. **Pasos con ítems binarios.** Los umbrales y las cargas se restringen **juntos** (Millsap y Tein, 2004): *configural* (todo libre) contra *umbrales + cargas iguales*.
   Criterio de Chen (2007): ΔCFI de −.010 o menos y ΔRMSEA de .015 o menos. Modelo de 5 ámbitos, WLSMV, `missing = "pairwise"`.

   | Corte | Modelo | χ² (gl) | CFI | RMSEA | ΔCFI | ΔRMSEA | p (Δχ²) |
   |---|---|---|---|---|---|---|---|
   | Edad | Configural | 411.0 (320) | .987 | .023 | | | |
   | Edad | Umbrales + cargas | 418.3 (330) | .987 | .022 | **.000** | −.001 | **.506** |
   | Escolaridad | Configural | 403.2 (320) | .989 | .022 | | | |
   | Escolaridad | Umbrales + cargas | 411.9 (330) | .989 | .022 | **.000** | .000 | **.366** |

   - **Edad:** hay invarianza de umbrales y cargas: ΔCFI = 0 y la χ² no rechaza (p = .51).
   - **Escolaridad:** también: ΔCFI = 0 y la χ² no rechaza (p = .37).
   - **Robustez:** la parametrización *theta* (la de Millsap y Tein) da el mismo ajuste (diferencia de χ² de .003) y la misma prueba.
4. **Ajuste del modelo en cada grupo** (conviene saberlo antes de comparar):

   | Grupo | N | CFI | RMSEA | SRMR |
   |---|---|---|---|---|
   | 18–44 | 665 | .988 | .022 | .105 |
   | 45+ | 421 | .985 | .024 | .123 |
   | Hasta primaria | 449 | .985 | .027 | .111 |
   | Secundaria o más | 618 | .992 | .018 | .117 |

   CFI y RMSEA muy buenos en los cuatro; el SRMR (.105 a .123) es alto por las parejas casi vacías, como en [`02_AFC`](../02_AFC/). El más flojo es 45+.
5. **Lo que no se hace: comparar medias latentes.** Con umbrales y cargas iguales se podrían estimar la media y la varianza de cada factor en el segundo grupo, pero
   aquí **no están bien identificadas** (errores estándar enormes y valores que cambian de *delta* a *theta*; p. ej. la varianza de pareja en 45+ sale 6.9 o 24.0).
   No se interpretan. Para comparar niveles de violencia entre grupos conviene usar los puntajes de [`05`](../05_Puntajes_Factoriales/) con cautela.

**Salidas** (`output/`): `admisibilidad_por_grupo.csv`, `invarianza.csv` y `ajuste_por_grupo.csv`.

**Cuidado.**
- Es la invarianza de **20 ítems en 5 ámbitos**. **El ámbito de trabajo queda fuera** (es el más raro) y el modelo de segundo orden no se probó.
- La invarianza de umbrales y cargas **no** dice que los grupos tengan la misma violencia, solo que los ítems funcionan igual en ambos.
- Con ítems tan raros (en los 20 ítems del modelo, el más raro tiene de 10 a 16 mujeres con "Sí" por grupo), la prueba tiene poca potencia para detectar diferencias.
- Si se consigue una variable de grupo sustantiva (región, municipio, zona rural-urbana), basta con cambiar una línea del script.
