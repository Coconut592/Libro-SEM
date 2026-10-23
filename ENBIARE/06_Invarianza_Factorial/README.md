# 06 · Invarianza factorial por tamaño de localidad

Script: `Invarianza_Factorial.R` (unos 2 minutos). **Sin referencia propia:** no hay invarianza publicada de la ENBIARE. Se
sigue la secuencia estándar (Meredith, 1993; Vandenberg y Lance, 2000; Chen, 2007): configural → métrica → escalar →
estricta, para los modelos de primer orden de satisfacción y de confianza, y la de **Chen, Sousa y West (2005)** para el
segundo orden.

> **La base no trae sexo ni edad**, los grupos habituales. El grupo es el **tamaño de localidad** (`tloc`): cuatro grupos de
> **14,095, 4,793, 4,925 y 7,353** personas. `tloc` no tiene etiquetas en el diccionario; se supone 1 = localidades de
> 100 mil habitantes o más ... 4 = menos de 2,500. Cuando llegue la tabla sociodemográfica (ver el README del proyecto),
> se agregan sexo y edad con el mismo script.

**Pregunta:** ¿satisfacción y confianza se miden igual en las cuatro localidades, de modo que se puedan comparar?

**Respuesta corta:**
- **Confianza: sí, hasta la estricta** (ΔCFI ≤ −.003), también en segundo orden.
- **Satisfacción: sí hasta la escalar, pero justo en el límite** (ΔCFI = −.010); **la estricta no pasa** (−.015). Con **invarianza
  parcial** (liberar 1 a 3 interceptos, sobre todo los de ciudad y país) se sostiene con holgura.
- Las diferencias entre localidades son **pequeñas en satisfacción** (|d| ≤ .17 en el general) y **moderadas en confianza
  institucional** (hasta d = .30, más alta en las localidades chicas).

## Paso a paso

1. **Datos y grupos.** Los grupos se ordenan para que el 1 (referencia, media latente 0) sea `tloc1`. MLR, sin faltantes.
2. **Requisito: el modelo ajusta en cada grupo por separado.**

   | Escala | Grupo | N | CFI | RMSEA | SRMR |
   |---|---|---|---|---|---|
   | SAT | tloc1 · tloc2 · tloc3 · tloc4 | 14,095 · 4,793 · 4,925 · 7,353 | .958 · .950 · .953 · **.943** | .046 · .050 · .046 · .050 | .033 · .035 · .032 · .034 |
   | CONF | tloc1 · tloc2 · tloc3 · tloc4 | (igual) | .975 · .968 · .959 · .959 | .080 · .090 · .098 · .099 | .024 · .028 · .033 · .033 |

   Los ocho ajustan parecido y son admisibles; el más flojo es satisfacción en `tloc4` (CFI .943). El RMSEA de confianza es alto
   como en 02, y sube un poco en las localidades chicas.
3. **Secuencia de primer orden** (Chen, 2007: se acepta el paso si el CFI no baja más de .010 y el RMSEA no sube más de .015
   respecto al anterior; los cambios se calculan con los índices sin redondear):

   | Escala | Modelo | χ² (gl) | CFI | TLI | RMSEA | SRMR | ΔCFI | ΔRMSEA |
   |---|---|---|---|---|---|---|---|---|
   | SAT | Configural | 4,832 (436) | .953 | .941 | .048 | .032 | | |
   | | Métrica | 4,928 (472) | .952 | .945 | .046 | .033 | −.001 | −.002 |
   | | Escalar | 6,029 (508) | .942 | .938 | .049 | .035 | **−.010** | +.003 |
   | | Estricta | 7,105 (559) | .927 | .929 | .052 | .040 | **−.015** | +.003 |
   | CONF | Configural | 5,710 (136) | .967 | .947 | .089 | .026 | | |
   | | Métrica | 5,926 (154) | .967 | .953 | .084 | .026 | .000 | −.005 |
   | | Escalar | 6,261 (172) | .967 | .957 | .080 | .026 | −.001 | −.004 |
   | | Estricta | 6,108 (205) | .964 | .961 | .076 | .028 | −.003 | −.004 |

   - **Confianza:** las cuatro pasan sin esfuerzo.
   - **Satisfacción:** la **métrica** pasa (−.001) y la **escalar** pasa **justo en el límite** (−.010); la **estricta no**
     (−.015). La χ² rechaza todos los pasos (31 mil casos; en confianza, la métrica con p = .016).
4. **Satisfacción: invarianza escalar parcial.** Prueba score sobre las restricciones de la escalar: los interceptos que más
   se alejan entre grupos son los de **ciudad y país**, que son los que menos se sostienen:

   | Intercepto | `pa3_16` servicios públicos | `pa3_11` seguridad | `pa3_13` vivienda · `pa3_14` vecindario | `pa3_10` libertad | `pa3_04` relaciones |
   |---|---|---|---|---|---|
   | X² | **497** | **301** | 178 · 178 | 108 | 64 |

   Liberándolos de uno en uno, contra la métrica:

   | Interceptos libres | CFI | RMSEA | SRMR | ΔCFI | ΔRMSEA |
   |---|---|---|---|---|---|
   | `pa3_16` | .947 | .047 | .034 | −.005 | +.001 |
   | `pa3_16`, `pa3_11` | .948 | .046 | .034 | −.004 | .000 |
   | `pa3_16`, `pa3_11`, `pa3_14` | .950 | .046 | .034 | **−.002** | .000 |

   Con 1 a 3 de los 17 interceptos libres, la escalar parcial se sostiene con holgura.
5. **Diferencias en las medias latentes** (modelo escalar; `tloc1` = 0; d = diferencia / desviación del factor en `tloc1`):

   | Escala | Factor | tloc2 (d) | tloc3 (d) | tloc4 (d) |
   |---|---|---|---|---|
   | SAT | `NIV` nivel de vida y logros | −.13 (−.09) | −.22 (−.16) | **−.45 (−.33)** |
   | | `REL` relaciones | −.05 (−.04) | −.04 (−.03) | −.14 (−.10) |
   | | `AUT` autonomía y actividad | −.05 (−.04) | −.08 (−.06) | −.16 (−.13) |
   | | `BAR` hogar y vecindario | −.01 (−.01) | −.06 (−.05) | −.09 (−.08) |
   | | `CIU` ciudad y país | +.13 (+.08) | +.19 (+.11) | **+.28 (+.16)** |
   | CONF | `INT` interpersonal | −.15 (−.07) | −.24 (−.11) | −.26 (−.12) |
   | | `POL` policías | +.09 (+.03) | +.20 (+.08) | +.47 (+.19) |
   | | `MIL` fuerzas armadas | +.34 (+.12) | +.61 (+.21) | **+.72 (+.25)** |
   | | `JUS` justicia | +.19 (+.07) | +.44 (+.16) | **+.73 (+.27)** |
   | | `PLT` política | +.30 (+.11) | +.60 (+.23) | **+.89 (+.34)** |

   En las localidades más chicas (`tloc4`) el **nivel de vida y logros es menor** (d = −.33) y **ciudad y país, mayor**
   (+.16): dos movimientos opuestos que se compensan en el puntaje de satisfacción general (por eso en 05 casi no cambia).
   La **confianza en las instituciones sube** al bajar el tamaño de la localidad (d hasta .34), y la **interpersonal baja**
   un poco. **Ojo:** los interceptos de ciudad y país son los que no se sostienen del todo (paso 4); esa diferencia
   (+.16) se lee con cautela.
6. **Segundo orden** (Chen, Sousa y West, 2005; en lavaan, `"loadings"` incluye las cargas de segundo orden, y el paso 2 las
   libera con `group.partial`):

   | Paso | SAT: CFI | ΔCFI | ΔRMSEA | CONF: CFI | ΔCFI | ΔRMSEA |
   |---|---|---|---|---|---|---|
   | 1 Configural | .938 | | | .961 | | |
   | 2 Cargas de 1.er orden | .937 | −.001 | −.002 | .961 | .000 | −.005 |
   | 3 + cargas de 2.º orden | .937 | .000 | −.001 | .960 | .000 | −.002 |
   | 4 + interceptos de los ítems | .927 | **−.010** | +.002 | .960 | −.001 | −.003 |
   | 5 + interceptos de las dimensiones | .923 | −.004 | +.001 | .959 | −.001 | −.001 |
   | 6 + residuos de los ítems | .909 | **−.014** | +.002 | .956 | −.003 | −.003 |
   | 7 + disturbios | .905 | −.004 | .000 | .955 | −.001 | −.002 |

   - **Confianza institucional:** los **siete pasos pasan** (ningún ΔCFI pasa de −.003).
   - **Satisfacción con la vida:** pasan las cargas de los dos órdenes; los **interceptos de los ítems** quedan justo en el
     límite (−.010) y los **residuos** no pasan (−.014): el mismo patrón del primer orden. El CFI configural de partida
     es el del segundo orden (.938, ver 03).
   - La χ² rechaza todos los pasos (p < .01).
7. **Diferencias en el factor general** (paso 5 del segundo orden; `tloc1` = 0):

   | | tloc2 | tloc3 | tloc4 |
   |---|---|---|---|
   | **Satisfacción con la vida** | −.07 (d = −.06) | −.11 (−.08) | −.22 (**−.17**) |
   | **Confianza institucional** | +.20 (d = .09) | +.41 (.19) | +.65 (**.30**) |

   La satisfacción general baja apenas en las localidades chicas (d = −.17); la confianza institucional sube hasta tres
   décimas de desviación.

**Salidas** (`output/`): `ajuste_por_grupo.csv`, `ajuste_invarianza_SAT.csv`, `ajuste_invarianza_CONF.csv`,
`invarianza_parcial_SAT.csv`, `medias_latentes_primer_orden.csv`, `ajuste_invarianza_2do_orden_SAT.csv`,
`ajuste_invarianza_2do_orden_CONF.csv` y `medias_latentes_general.csv`.

**Lo que conviene tener presente.**
- **Es una invarianza real, pero no la habitual.** Por sexo y edad se hará con la tabla sociodemográfica.
- **Satisfacción cumple la escalar solo por un pelo** y la estricta no: las diferencias de medias entre localidades se leen
  con cautela, en particular las de ciudad y país. Confianza no tiene ese problema.
- Las diferencias de d de .2 a .3 son pequeñas a moderadas. Con 31 mil casos todo es "significativo"; la lectura útil es el
  tamaño del efecto. No se corrigió por el diseño muestral (conglomerados, pesos): ver 05.
