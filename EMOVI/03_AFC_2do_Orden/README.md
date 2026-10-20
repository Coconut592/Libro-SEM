# 03 · AFC de segundo orden: Riqueza del hogar de origen

Script: `AFC_2do_Orden.R` (unos 20 segundos). **Sin referencia propia:** la tesis usa un solo factor de riqueza y
no hace segundo orden.

**Pregunta:** los tres factores del AFC (ESP, BAS, TEC) correlacionan de .69 a .81, ¿los gobierna un factor general,
la **riqueza del hogar de origen**?

**Respuesta corta: sí, y con cargas altas** (.84, .97 y .83). Pero con tres factores de primer orden el segundo
orden queda **justo identificado**: ajusta igual que el primer orden y no se puede contrastar contra él.

## Paso a paso

1. **Modelo.** `RIQ =~ ESP + BAS + TEC` sobre el modelo de primer orden de [`02_AFC`](../02_AFC/). WLSMV,
   ítems ordinales y `missing = "pairwise"`.
2. **Ajuste.**

   | Modelo | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | 1.er orden (3 factores) | 740 | 801.2 (374) | .975 | .973 | .039 | .081 |
   | 2.º orden (RIQ) | 740 | 801.2 (374) | .975 | .973 | .039 | .081 |

   Mismos grados de libertad y mismo ajuste: 3 correlaciones entre factores se sustituyen por 3 cargas. El
   segundo orden es una forma más compacta de describir las mismas correlaciones, **no una mejora de ajuste**.
3. **Cargas de segundo orden** (estandarizadas) y varianza que explica RIQ de cada factor:

   | Factor | Carga en RIQ | R² |
   |---|---|---|
   | ESP · espacios de la vivienda | .84 | .70 |
   | **BAS · servicios y bienes básicos** | **.97** | **.94** |
   | TEC · tecnología y confort | .83 | .69 |

   BAS casi no tiene varianza propia: es el factor que más se parece a la riqueza general. Una carga tan cerca de
   1 pide cuidado, pero no pasa de 1 (no es un caso Heywood). Las cargas de primer orden no cambian.
4. **¿Hace falta el segundo orden?** Contra **un solo factor** con los 29 ítems (CFI .952, RMSEA .054): ajusta
   peor que los tres factores con un general encima (CFI .975, RMSEA .039). La estructura de tres dimensiones es
   real y el factor general las resume.

**Salidas** (`output/`): `ajuste_2do_orden.csv` y `cargas_segundo_orden.csv`.
