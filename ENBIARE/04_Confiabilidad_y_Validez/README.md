# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R` (unos 50 segundos). **Sin referencia propia:** no hay documento de validez. Con los
modelos de 02 y 03 se calculan alfa, omega, confiabilidad compuesta (CR), AVE, validez discriminante (Fornell-Larcker y HTMT,
dentro de cada escala y entre las dos) y validez de criterio **con variables de la propia base** (`pa1`, `pa5`, afecto,
depresión y ansiedad).

**Pregunta:** ¿las escalas miden de forma confiable, convergen en un constructo, se distinguen entre sí y se relacionan
con otras medidas como debieran?

**Respuesta corta:**
- **Confianza: sí en todo.** CR .73–.90, AVE .58–.82, Fornell-Larcker y HTMT cumplidos.
- **Satisfacción: confiable (ω .61–.76) y con buena validez de criterio, pero la validez convergente es débil:** AVE
  .41–.45 con MLR, sin que ningún factor llegue a .50 ni pase Fornell-Larcker. Con WLSMV sube a .49–.54.
- **Las dos escalas se distinguen** (r latente .34, HTMT .44) y la satisfacción se comporta como bienestar (r de .51 a .60
  con `pa1`, `pa5` y afecto positivo) y la confianza institucional, no (r ≤ .19).

## Paso a paso

1. **Alfa, omega, CR, AVE, Fornell-Larcker y HTMT** (modelos de 02, MLR; HTMT con valor absoluto):

   | Escala | Factor | k | α | ω | CR | AVE | r² máx. | HTMT máx. | Fornell-Larcker |
   |---|---|---|---|---|---|---|---|---|---|
   | SAT | `NIV` | 4 | .755 | .752 | .757 | .439 | .674 | .82 | ❌ |
   | | `REL` | 4 | .715 | .720 | .738 | .416 | .674 | .82 | ❌ |
   | | `AUT` | 3 | .663 | .660 | .671 | .405 | .653 | .80 | ❌ |
   | | `BAR` | 2 | .609 | .614 | .612 | .441 | .476 | .67 | ❌ |
   | | `CIU` | 4 | .759 | .760 | .768 | .454 | .476 | .67 | ❌ |
   | CONF | `INT` | 2 | .721 | .743 | .733 | .581 | .216 | .48 | ✅ |
   | | `POL` | 2 | .901 | .903 | .903 | .824 | .599 | .77 | ✅ |
   | | `MIL` | 2 | .894 | .899 | .897 | .814 | .555 | .76 | ✅ |
   | | `JUS` | 2 | .893 | .893 | .893 | .807 | .691 | .84 | ✅ |
   | | `PLT` | 3 | .902 | .903 | .903 | .756 | .691 | .84 | ✅ |

   **Confianza:** todo arriba de lo pedido (α, ω y CR ≥ .70; AVE ≥ .50). El caso más justo es **Justicia–Política**
   (r² = .69 contra AVE de .81 y .76; HTMT .84, a un pelo de .85). Los factores de 2 ítems dan alfas poco informativas.

   **Satisfacción:** α, ω y CR entre .61 y .77: confiabilidad **aceptable** (mínimo .70 no se alcanza en `AUT` ni `BAR`, de
   3 y 2 ítems). La **AVE de los cinco factores está entre .405 y .454**: cada uno explica menos de la mitad de la varianza de
   sus ítems (cargas de .55 a .76). **Ninguno pasa Fornell-Larcker**: `NIV`–`REL` (r² .674) y `NIV`–`AUT` (.653) comparten más
   que su AVE. Pero **HTMT queda bajo .85** (máximo .82): los factores se distinguen, aunque se parecen mucho. Es lo que
   anticipaba el segundo orden (03).
2. **Sensibilidad: la AVE de SAT depende del estimador.** Con WLSMV (los 11 puntos como ordinales) las cargas suben
   (media .71 contra .65):

   | Escala | Factor | CR (MLR) | AVE (MLR) | CR (WLSMV) | AVE (WLSMV) |
   |---|---|---|---|---|---|
   | SAT | `NIV` | .757 | .439 | .790 | .486 |
   | | `REL` | .738 | .416 | .821 | **.535** |
   | | `AUT` | .671 | .405 | .744 | .493 |
   | | `BAR` | .612 | .441 | .704 | **.543** |
   | | `CIU` | .768 | .454 | .794 | .492 |
   | CONF | `INT` · `POL` · `MIL` · `JUS` · `PLT` | .73–.90 | .58–.82 | .75–.93 | .60–.87 |

   Con WLSMV, `REL` y `BAR` pasan de .50 y los otros tres quedan en **.49**. El "AVE < .50" de satisfacción es en parte un
   efecto del estimador (el techo de las respuestas achata las correlaciones de Pearson), no solo de ítems débiles. Con las
   dos lecturas, la satisfacción **converge moderadamente**; la confianza, con claridad.
3. **Confiabilidad del segundo orden** (omega jerárquico ω_h = varianza del puntaje total que se debe al factor general;
   ω_t = la debida a todos los factores; semTools y fórmula a mano coinciden a .005):

   | Segundo orden | ω_h | ω_t | ω_h / ω_t |
   |---|---|---|---|
   | SAT · Satisfacción con la vida (17 ítems) | .79 | .89 | **.88** |
   | CONF · Confianza institucional (9 ítems; sin `INT`) | .89 | .96 | **.92** |

   El factor general explica el **88 %** de la varianza confiable del puntaje de satisfacción y el **92 %** del de confianza
   institucional: aunque los primeros orden se distinguen, un puntaje total de cada escala sirve.
4. **Validez discriminante entre las dos escalas.** HTMT entre `pa3` y `pb1` (todos sus ítems): **.44**, muy por debajo de .85.
   En un modelo conjunto (SAT y CONF de segundo orden; CFI .933, RMSEA .053, SRMR .069) la correlación latente es **.34**
   (r² = .12), muy por debajo de la AVE de cada escala: son constructos distintos.
5. **Validez de criterio con variables de la propia base.** Correlaciones de Spearman de los puntajes factoriales
   (modelos de 2.º orden) con: `pa1` (satisfacción con su vida hoy), `pa5` (escalón en que ubica su vida), afecto positivo
   (media de `pa4_01`–`pa4_05`), afecto negativo (`pa4_06`–`pa4_10`), depresión (CESD-7, `pd2_*` con `pd2_6` invertida) y
   ansiedad (GAD-2, `pd3_*`):

   | Puntaje | `pa1` | `pa5` | Afecto + | Afecto − | Depresión | Ansiedad |
   |---|---|---|---|---|---|---|
   | **SAT** (general) | **.60** | **.57** | .51 | −.31 | −.36 | −.30 |
   | `NIV` nivel de vida y logros | .61 | .57 | .49 | −.30 | −.35 | −.29 |
   | `REL` relaciones | .59 | .53 | .49 | −.31 | −.36 | −.29 |
   | `AUT` autonomía y actividad | .58 | .55 | .51 | −.32 | −.35 | −.29 |
   | `BAR` hogar y vecindario | .52 | .51 | .45 | −.27 | −.29 | −.24 |
   | `CIU` ciudad y país | .37 | .37 | .35 | −.18 | −.20 | −.18 |
   | `INT` confianza interpersonal | .20 | .26 | .24 | −.13 | −.15 | −.15 |
   | **CONF** (general institucional) | .13 | .19 | .17 | −.03 | −.06 | −.07 |
   | `POL` · `MIL` · `JUS` · `PLT` | .11–.13 | .16–.18 | .15–.17 | −.02 a −.05 | −.04 a −.06 | −.05 a −.08 |

   - **La satisfacción se comporta como bienestar:** va con la satisfacción global (.60), el escalón (.57) y el afecto
     positivo (.51), y en contra de la depresión, la ansiedad y el afecto negativo. Más con lo personal (`NIV`, `REL`, `AUT`)
     que con el entorno (`CIU`, .37).
   - **La confianza institucional casi no es bienestar** (hasta .19, con `pa5`), como se esperaba: validez discriminante.
     La **interpersonal** se acerca más (.20–.26).
   - Referencia: entre los propios criterios, `pa1` y `pa5` correlacionan .50, depresión y ansiedad .61, y afecto negativo
     con depresión .48. La satisfacción con `pa1` (.60) correlaciona más de lo que `pa1` lo hace con `pa5` (.50).

**Salidas** (`output/`): `confiabilidad_validez.csv`, `sensibilidad_AVE_WLSMV.csv`, `omega_2do_orden.csv`,
`discriminante_entre_escalas.csv` y `validez_criterio.csv`.

**Lo que conviene tener presente.**
- La **validez convergente de la satisfacción es el punto débil** (AVE < .50 con MLR); la de criterio, el fuerte. Se reporta
  con las dos lecturas y no se retira ningún ítem.
- KR-20 no aplica (ítems de 0 a 10) y no hay documento de validez de contenido en los archivos.
