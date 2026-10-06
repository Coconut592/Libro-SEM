# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R`. Referencias: el capítulo (alfa de Cronbach de Ferris = .90; los tres
tipos de validez de Nunnally, 1987; validez de constructo con el AFC) y la lámina 16 de la presentación
(`alpha AS11-AS14, d item` en Stata). **El capítulo no calcula** la confiabilidad compuesta, el AVE, la
validez discriminante ni la confiabilidad del factor general: se agregan con el esquema de los otros
proyectos.

## Confiabilidad

Alfa con los 356 (matriz de covarianzas, como el `alpha` de Stata) y confiabilidad compuesta con el AFC
de [`02_AFC`](../02_AFC/).

| Factor | Ítems | α de Cronbach | α con la covarianza del modelo | Confiabilidad compuesta |
|---|---|---|---|---|
| HR | 5 | .831 | .833 | .834 |
| SA | 3 | .738 | .742 | .743 |
| AS | 4 | .757 | .754 | .755 |
| II | 3 | .819 | .820 | .821 |
| **Total (15 ítems)** | 15 | **.911** | | |

- Todos superan .70 (Nunnally y Bernstein, 1994). Con los 15 ítems el alfa total (.911) es casi igual al
  .90 que reporta Ferris para el PSI de 18 ítems.
- **Por ítem** (`output/alfa_por_item.csv`): ninguno mejora la escala al quitarlo; la correlación
  ítem-resto va de .50 (`SA9`) a .70 (`II18`).
- **KR-20 no aplica:** es para ítems dicotómicos (0/1) y estos van de 1 a 7.
- **Factor general (segundo orden).** Confiabilidad compuesta de HP a partir de sus cuatro cargas:
  **.932**. Omega total de la escala de 15 ítems: **.926**; omega jerárquico (la parte debida solo a HP):
  **.854**. Es decir, **el 92% de la confiabilidad de la suma de los 15 ítems se debe al factor general**:
  sumar los ítems mide sobre todo HP, y lo que las dimensiones agregan por separado es poco.

## Validez

1. **Validez de contenido (cualitativa).** No se calcula. Los 15 ítems son una versión recortada del PSI de
   18 (se quitaron `HR5`, `AS12` e `II15`), y cada dimensión conserva ítems que cubren su definición
   (ver el glosario en [`../README.md`](../README.md)). El capítulo describe una traducción por dos
   traductores independientes y la revisión de una especialista en psicología.
2. **Validez de criterio: no es posible con esta base.** Requiere un criterio externo (desempeño,
   ascensos, otro instrumento de efectividad social). La base solo trae `Genero` y los 15 ítems.
3. **Validez de constructo:**
   - **Teoría:** cuatro dimensiones de la habilidad política (Ferris et al., 2005).
   - **Correlaciones entre ítems:** los de una dimensión deben correlacionar más entre sí que con los de
     otras.

     | Factor | r media dentro | r media fuera | Diferencia |
     |---|---|---|---|
     | HR | .496 | .372 | .124 |
     | SA | .485 | .401 | .084 |
     | AS | .438 | .384 | .054 |
     | II | .602 | .385 | .217 |

     Hay estructura, pero es pequeña salvo en II y HR: los ítems de dimensiones distintas están bastante
     correlacionados. En AS casi no hay diferencia.
   - **AFE y AFC:** el AFE recupera HR e II y mezcla SA con AS ([`01_AFE`](../01_AFE/)); el AFC confirma
     los 4 factores con cargas de .63 a .81 y ajuste aceptable ([`02_AFC`](../02_AFC/)).

### Complemento: validez convergente y discriminante

- **Convergente (AVE ≥ .50):** HR **.50**, SA **.49**, AS **.44**, II **.61**. HR e II cumplen, SA queda al
  límite y AS por debajo. Con confiabilidad compuesta de .74 a .83 (todas > .60), la validez convergente es
  aceptable según Fornell y Larcker (1981).
- **Discriminante, Fornell-Larcker** (raíz del AVE en la diagonal, correlaciones debajo):

  | | HR | SA | AS | II |
  |---|---|---|---|---|
  | HR | **.708** | | | |
  | SA | .774 | **.701** | | |
  | AS | .778 | .885 | **.660** | |
  | II | .662 | .746 | .769 | **.778** |

  Se cumple en **un solo par de seis** (HR–II). Falla en SA–AS (.885 contra raíces de .70 y .66), HR–SA,
  HR–AS, SA–II y AS–II.
- **Discriminante, HTMT** (Henseler et al., 2015; se pide < .85):

  | | HR | SA | AS |
  |---|---|---|---|
  | SA | .789 | | |
  | AS | .777 | **.903** | |
  | II | .674 | .748 | .759 |

  Solo **SA–AS** supera .85 (.903, en el límite de .90).
- **Discriminante, prueba de χ²** (se fija en 1 la correlación de cada par y se compara con el modelo
  libre):

  | Par | Correlación | Δχ² (1 gl) | p |
  |---|---|---|---|
  | HR–SA | .774 | 55.7 | < .001 |
  | HR–AS | .778 | 63.3 | < .001 |
  | HR–II | .662 | 160.6 | < .001 |
  | **SA–AS** | **.885** | **12.3** | **< .001** |
  | SA–II | .746 | 63.7 | < .001 |
  | AS–II | .769 | 62.5 | < .001 |

  Los seis pares son estadísticamente distintos de 1; SA–AS es el más cercano.

## Conclusión

- **Confiabilidad:** buena en todas las dimensiones (.74 a .83) y muy buena en la escala total (.91). El
  segundo orden indica que la suma total mide sobre todo el factor general.
- **Validez de constructo:** la estructura de cuatro dimensiones se confirma (AFC) y las dimensiones son
  **estadísticamente distintas**, pero el criterio de Fornell-Larcker falla en 5 de 6 pares y SA–AS roza el
  límite del HTMT: **la validez discriminante es débil**. Es el resultado que el segundo orden anticipa y
  que justifica leer HP como un factor general. Para usar las dimensiones por separado hay que hacerlo con
  cautela (sobre todo SA y AS).
- **Pendiente:** validez de criterio, que requiere una variable externa.

## Salidas

`output/confiabilidad_validez.csv` (tabla resumen), `alfa_por_item.csv`, `confiabilidad_compuesta.csv`,
`fornell_larcker.csv`, `HTMT.csv` y `prueba_chi2_discriminante.csv`.
