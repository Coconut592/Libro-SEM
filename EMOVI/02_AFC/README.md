# 02 · Análisis Factorial Confirmatorio (AFC) de primer orden

Script: `AFC.R` (unos 20 segundos). **Referencia:** la tesis confirma el índice de riqueza del hogar de origen
con un CFA binario (WLSMV): KR-20 .88, RMSEA .05, CFI .99 y TLI .99 con n = 17,665 (Anexo 2, un factor y 12
ítems). Aquí se confirma la estructura de tres factores del AFE con la CDMX de 2023.

**Pregunta:** ¿ajustan los tres factores (espacios, servicios y bienes básicos, tecnología) que salieron del AFE?

**Respuesta corta: sí.** CFI .975, TLI .973 y RMSEA .039, mejor que un solo factor. Los factores correlacionan
mucho (de .69 a .81).

## Paso a paso

1. **Datos.** Los 29 ítems que quedan con el criterio 90-10 (ver [`01_AFE`](../01_AFE/)), 1 = Sí y 0 = No.
2. **Modelo.** Cada ítem en el factor donde más carga en el AFE: **ESP** (10 ítems), **BAS** (14) y **TEC** (5).
3. **Estimación.** WLSMV con los ítems como ordinales y `missing = "pairwise"`, para no perder a los 89
   entrevistados con algún `NS`. `lavaan` no tiene FIML con ítems ordinales (ver [`07_FIML`](../07_FIML/)).

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | **3 factores** (pairwise) | 740 | 801.2 (374) | **.975** | **.973** | **.039** | .081 |
   | 3 factores (listwise) | 651 | 768.3 (374) | .975 | .973 | .040 | .085 |
   | 1 factor | 740 | 1,194.9 (377) | .952 | .948 | .054 | .100 |

   Los tres factores ajustan mejor que uno solo, y listwise da lo mismo. El SRMR (.08) queda en el límite, algo
   habitual con WLSMV y 29 ítems.
4. **Cargas estandarizadas:** de **.42** (`p29c`, patio) a **.96** (`p31l`, internet); ninguna baja de .40.
   Las más bajas: `p29c` (.42), `p31o` bicicleta (.44), `p29b` jardín (.46), `p26e` servicio doméstico (.46),
   `p29g` cuarto para cocinar (.49) y `p32a` otra vivienda (.50).
5. **Correlaciones entre factores:** ESP–BAS **.81**, BAS–TEC **.81**, ESP–TEC **.69**. Son altas: lo que
   justifica el segundo orden ([`03`](../03_AFC_2do_Orden/)) y lo que pone a prueba la validez discriminante
   ([`04`](../04_Confiabilidad_y_Validez/)).
6. **Índices de modificación** (solo para ver): los mayores son residuales entre ítems parecidos (`p29d`–`p29e`
   cuarto de lavado y de TV, 57; `p32e`–`p32f` cuenta y tarjeta, 55). No se agregan: el ajuste ya es bueno.

**Salidas** (`output/`): `ajuste_AFC.csv` y `cargas_AFC.csv`.
