# 03 · AFC de segundo orden

Script: `AFC_2do_Orden.R` (un minuto). **Sin referencia propia:** no hay un modelo de segundo orden publicado de
la ENBIARE. Como en PREP y ENCO, el factor general se define igual que uno de primer orden (`SAT =~ NIV + REL + ...`) y
`std.lv = TRUE` fija su varianza en 1.

**Pregunta:** ¿los cinco factores de satisfacción comparten un factor general de **satisfacción con la vida**, y los
de confianza uno de **confianza institucional**?

**Respuesta corta: sí en confianza, con salvedad en satisfacción.** Confianza institucional pierde casi nada (ΔCFI
−.006; cargas de .82 a .93). La satisfacción con la vida pierde algo más (ΔCFI −.014, más del límite de .010 de
Chen), porque el factor de **ciudad y país** (`CIU`) carga solo .60 y dos factores generales (personal y entorno)
ajustan mejor que uno.

## Los modelos

```
SAT  =~ NIV + REL + AUT + BAR + CIU      (los cinco factores de satisfacción)
CONF =~ POL + MIL + JUS + PLT            (los cuatro de instituciones; INT queda aparte, covaría con CONF)
```

## Paso a paso

1. **Primer y segundo orden.** Convergen y son admisibles (sin varianzas negativas).
2. **Solución estandarizada** (todas las cargas, p < .001; R² = varianza del factor explicada por el general):

   | Segundo orden | Factor | Carga | R² | Disturbio (1 − R²) |
   |---|---|---|---|---|
   | **SAT** · Satisfacción con la vida | `NIV` nivel de vida y logros | **.91** | .83 | .17 |
   | | `AUT` autonomía y actividad | .88 | .78 | .22 |
   | | `REL` relaciones | .85 | .73 | .27 |
   | | `BAR` hogar y vecindario | .76 | .57 | .43 |
   | | `CIU` ciudad y país | **.60** | .36 | .64 |
   | **CONF** · Confianza institucional | `JUS` justicia | **.93** | .86 | .14 |
   | | `POL` policías | .86 | .74 | .26 |
   | | `PLT` política | .86 | .74 | .26 |
   | | `MIL` fuerzas armadas | .82 | .66 | .34 |

   La satisfacción con la vida se parece sobre todo al **nivel de vida y logros**; el entorno (hogar, ciudad, país) se
   le parece menos. `INT` (confianza en las personas) correlaciona **.46** con la confianza institucional: es
   un constructo cercano pero distinto. Meterlo dentro del general da exactamente el mismo modelo (χ² = 6,592.41 contra
   6,592.41; su carga es esa correlación de .46), así que no es una decisión de ajuste.
3. **Comparación con el primer orden** (el segundo orden agrega 5 gl en las dos escalas):

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR | ΔCFI | ΔRMSEA | Δχ² (5 gl) |
   |---|---|---|---|---|---|---|---|---|
   | SAT, 1.er orden | 4,419 (109) | .952 | .941 | .047 | .032 | | | |
   | SAT, 2.º orden | 5,768 (114) | .938 | .925 | .053 | .041 | **−.014** | +.006 | 1,290 |
   | CONF, 1.er orden | 5,468 (34) | .968 | .949 | .088 | .027 | | | |
   | CONF, 2.º orden | 6,592 (39) | .962 | .946 | .090 | .034 | **−.006** | +.002 | 1,121 |

   Con 31 mil casos el Δχ² siempre es significativo (p < 10⁻²³⁰); se juzga por ΔCFI (Chen, 2007: hasta −.010).
   **CONF cumple. SAT se pasa por .004**, aunque su CFI de .938 sigue siendo aceptable (> .90) y su RMSEA (.053), bueno.
4. **¿Un solo factor general en satisfacción?** `CIU` (.60) y `BAR` (.76) cargan menos que los demás. Con **dos**
   factores de segundo orden, personal (`NIV`, `REL`, `AUT`) y entorno (`BAR`, `CIU`):

   | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | SAT, 1.er orden | 4,419 (109) | .952 | .941 | .047 | .032 |
   | SAT, 2.º orden, 1 general | 5,768 (114) | .938 | .925 | .053 | .041 |
   | **SAT, 2.º orden, personal + entorno** | **4,632 (113)** | **.950** | **.940** | **.048** | **.034** |

   Cargas: personal, .93 · .87 · .88; entorno, .94 · .74; **personal y entorno correlacionan .75**. Este modelo ajusta casi
   igual que el de primer orden (ΔCFI −.002, 4 gl más), mejor que el general único. **Decisión:** los ejercicios 04 a 06
   usan el **general único**, que es la propuesta acordada y el ejemplo clásico de segundo orden, con esta salvedad:
   la satisfacción con la vida tiene, en rigor, dos componentes.
5. **Sensibilidad con WLSMV** (los 11 puntos como ordinales):

   | Escala | CFI 1.er orden | CFI 2.º orden | ΔCFI | Cargas del general |
   |---|---|---|---|---|
   | SAT | .966 | .941 | **−.025** | .91 · .86 · .90 · .82 · .65 |
   | CONF | .980 | .981 | +.001 | .85 · .82 · .95 · .88 |

   Con el estimador ordinal confianza institucional sigue sin perder nada y las cargas son parecidas; el segundo orden de
   satisfacción pierde más que con MLR (−.025). La salvedad del paso 4 se refuerza.

**Salidas** (`output/`): `cargas_2do_orden.csv`, `ajuste_1er_vs_2do_orden.csv`, `variantes_SAT.csv`,
`sensibilidad_2do_orden_WLSMV.csv` y los diagramas.

**Lo que conviene tener presente.**
- El segundo orden de SAT con cinco factores **sí se puede contrastar** (5 gl). El de BS (evaluación, afecto positivo y
  negativo, del diagnóstico) quedaría justo identificado y no se puede; no es parte de los ejercicios.
- Las cargas de `CONF` son altas, pero `INT` queda fuera: la confianza interpersonal y la institucional no son la misma
  dimensión. Eso es una conclusión, no un defecto del modelo.
