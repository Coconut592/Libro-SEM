# 06 · Datos faltantes: FIML

Script: `FIML.R`. Referencias: `missing = "fiml"` de `AFE_CFA.R`, el `.inp` (Mplus usa FIML por defecto)
y láminas 9–12 del PDF.

**Objetivo:** usar los 306 usuarios en lugar de los 170 completos. FIML (*Full Information Maximum
Likelihood*) no imputa: cada caso aporta a la verosimilitud con los ítems que sí respondió.

> En `AFE_CFA.R`, `missing = "fiml"` se aplica a `tren_reducido`, que ya solo tiene casos completos,
> así que no cambia nada. Aquí se aplica a la base completa, como hace Mplus.

## Paso a paso

1. **¿Cuánto falta?** `p63` (107) y `p64` (128). Solo 170 casos (56%) están completos: con listwise se
   pierde el **44% de la muestra**. El patrón más común (94 casos) es "falta la tarjeta y nada más".
2. **¿Faltan al azar (MCAR)?** Se comparan los demás ítems entre quienes responden y no responden la
   tarjeta. Quienes no responden califican mejor el confort (p71, p73, p75; p < .02). **No es MCAR**, y
   el listwise puede sesgar. Como la diferencia está en variables observadas del modelo, FIML la
   incorpora (supuesto **MAR**).
3. **Cobertura.** Proporción de casos con información en cada par de ítems. La mínima es .57 (p61–p64),
   muy por encima del .10 que pide Mplus.
4. **Listwise vs FIML** (mismo modelo y marcadores que el `.inp`, estimador MLR):

   | | N | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|---|
   | Listwise | 170 | 135.8 (32) | .895 | .852 | .138 | .097 |
   | **FIML** | **306** | 134.8 (32) | **.920** | **.887** | **.102** | **.069** |

   Los valores de FIML son **exactamente los de Mplus en el PDF**, igual que las cargas y sus errores
   estándar (p4 .612 [.048], p5 .808, p61 .836, p62 .649, p63 .848, p64 .946, p71 .678, p73 .718,
   p74 .769, p75 .877). Las correlaciones Acceso–Confort (.45), Acceso–Tarjeta (.41) y Tarjeta–Confort
   (.34) también coinciden.
5. **Interpretación.** Con FIML se usa toda la muestra, los errores estándar son menores y el ajuste
   mejora. Aun así, RMSEA = .102 y TLI = .887 no alcanzan los criterios convencionales.

> **Supuesto a discutir:** si los faltantes de la tarjeta significan "no usa tarjeta" (la pregunta no
> aplica) y no una no-respuesta, FIML estima una satisfacción con la tarjeta para personas que no la
> usan. El `.dta` no permite distinguir entre los dos casos.

Salidas: `output/ajuste_listwise_vs_FIML.csv` y `output/cargas_listwise_vs_FIML.csv`.
