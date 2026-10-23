# 01 · Análisis Factorial Exploratorio (AFE)

Script: `AFE.R` (un minuto). **Sin referencia propia:** no hay tesis, capítulo ni script con un modelo
factorial de la ENBIARE 2021. Se explora la estructura de las dos escalas de los ejercicios, ambas de 0 a 10 y sin
faltantes, con las 31,166 personas.

**Preguntas:**
- Los 17 aspectos de la vida con los que se pregunta la satisfacción (`pa3_01`–`pa3_17`), ¿miden una sola satisfacción
  o varias?
- Los 12 niveles de confianza (`pb1_01`–`pb1_12`), ¿son una sola confianza o varias?

**Respuesta corta: cinco dimensiones en cada escala.** Satisfacción: nivel de vida y logros, relaciones, autonomía y
actividad, hogar y vecindario, y ciudad y país. Confianza: interpersonal, policías, fuerzas armadas, justicia y
política. En confianza, `pb1_03` (medios de comunicación) no pertenece a ningún factor y se deja fuera.

## Paso a paso

1. **Datos.** Las escalas 0-10 (11 categorías) no tienen faltantes ni "no sabe": no hay nada que recodificar. Se
   tratan como continuas, como PREP con sus escalas 1-10; el AFC (02) lo comprueba con WLSMV.
2. **¿Tiene sentido factorizar?**

   | Escala | KMO | Por ítem | Bartlett χ² (gl) | Eigenvalores | Kaiser | Paralelo (ML) |
   |---|---|---|---|---|---|---|
   | Satisfacción (17) | .92 | .88–.95 | 160,954 (136) | 5.83 · 1.74 · 0.97 · 0.93 · 0.91 | 2 | 5 (o 6) |
   | Confianza (12) | .90 | .80–.97 | 275,053 (66) | 6.67 · 1.36 · 0.88 · 0.69 · 0.53 | 2 | 5 |

   Kaiser pide 2 factores en las dos y se descarta: el segundo eigenvalor pasa de 1 por poco (1.74 y 1.36) y con 12 o
   17 ítems de la misma familia el criterio se queda corto. **El análisis paralelo con ML dice 5.** En
   satisfacción es un caso límite: con 8 semillas distintas sale 5 cuatro veces y 6 otras cuatro (el 6.º
   eigenvalor, .018, casi iguala al simulado, .015); en confianza sale 5 las ocho veces. Se fija `RNGkind("L'Ecuyer-CMRG")`
   para que la semilla dé siempre el mismo resultado.
3. **Ajuste del AFE de 1 a 6 factores** (ML, oblimin):

   | Factores | SAT RMSEA | SAT TLI | SAT SRMR | CONF RMSEA | CONF TLI | CONF SRMR |
   |---|---|---|---|---|---|---|
   | 1 | .097 | .755 | .076 | .192 | .725 | .089 |
   | 2 | .063 | .896 | .037 | .177 | .765 | .078 |
   | 3 | .057 | .914 | .031 | .149 | .834 | .061 |
   | 4 | .048 | .939 | .023 | .127 | .880 | .024 |
   | **5** | **.035** | **.968** | **.013** | **.021** | **.997** | **.003** |
   | 6 | .031 | .975 | .011 | .012 | .999 | .002 |

   **Se escogen 5 en las dos:** es el primero con RMSEA ≤ .06 y TLI ≥ .95 (en confianza el salto de 4 a 5 es enorme:
   RMSEA de .127 a .021) y los cinco factores se pueden nombrar. Con 6 factores en satisfacción, `pa3_04` forma un
   factor de **un solo ítem** (carga .99, comunalidad 1.00, varianza residual de .005: caso Heywood en el límite).
4. **Satisfacción, cinco factores** (cargas de patrón, oblimin; comunalidad entre paréntesis):

   | Factor | Ítems con carga principal |
   |---|---|
   | **F1 · Nivel de vida y logros** | `pa3_01` nivel de vida (.67), `pa3_02` salud (.49), `pa3_03` logros (.46); `pa3_08` futuro (.26) con tres cargas de .22 a .26 |
   | **F2 · Relaciones** | `pa3_04` relaciones personales (.71), `pa3_07` vida afectiva (.57), `pa3_05` vida social (.56), `pa3_06` vida familiar (.55) |
   | **F3 · Autonomía y actividad** | `pa3_10` libertad para decidir (.66), `pa3_09` tiempo libre (.57), `pa3_12` actividad principal (.45) |
   | **F4 · Hogar y vecindario** | `pa3_14` vecindario (.58), `pa3_13` vivienda (.54; .24 en nivel de vida) |
   | **F5 · Ciudad y país** | `pa3_17` país (.72), `pa3_15` ciudad (.68), `pa3_16` servicios públicos (.62), `pa3_11` seguridad (.53) |

   Los factores correlacionan de **.33 a .63** (nivel de vida con autonomía, .55; con relaciones, .61; relaciones con
   autonomía, .63). **Ningún ítem carga .30 o más en dos factores.** El menos limpio es `pa3_08`; la comunalidad más
   baja es la de `pa3_07` (.32) y todas las demás pasan de .37.

   Con **4 factores** el vecindario (`pa3_14`, .45) se une a ciudad y país y la vivienda (`pa3_13`) queda sin factor
   claro (.26 y .22), de ahí el RMSEA de .048 contra .035.
5. **Confianza, cinco factores** (12 ítems):

   | Factor | Ítems con carga principal |
   |---|---|
   | **F1 · Interpersonal** | `pb1_02` la gente que conoce (.76), `pb1_01` la mayoría de la gente (.75) |
   | **F2 · Policías** | `pb1_04` municipal (.91), `pb1_05` estatal (.78) |
   | **F3 · Fuerzas armadas** | `pb1_06` Guardia Nacional (.92), `pb1_07` Ejército y Marina (.84) |
   | **F4 · Justicia** | `pb1_09` juzgados y tribunales (.93), `pb1_08` ministerio público (.58) |
   | **F5 · Política** | `pb1_11` partidos políticos (.95), `pb1_12` funcionarios públicos (.78), `pb1_10` cámaras de diputados y senadores (.51; .38 en justicia) |
   | *Sin factor* | `pb1_03` medios de comunicación: cargas de .19, .30 y .25 y la comunalidad más baja (**.41**; las demás, de .55 a .92) |

   Los cuatro factores de instituciones correlacionan de **.58 a .69**; el interpersonal, de .33 a .46 con ellos: la
   confianza en las personas es otra cosa que la confianza en las instituciones.

   **Sin `pb1_03`** (11 ítems) salen los mismos cinco factores y el ajuste mejora: RMSEA **.019**, TLI **.998**, SRMR
   .002. Es la escala que pasa al AFC.
6. **¿Se sostiene en dos mitades al azar?** Se parte la muestra (15,513 y 15,653) y se compara cada mitad con la
   solución completa con el coeficiente de congruencia de Tucker (arriba de .95, el mismo factor). El peor factor de
   cada mitad: satisfacción **1.00 y .99**, confianza **1.00 y 1.00**. La estructura es estable.

**Salidas** (`output/`): `ajuste_AFE_SAT.csv`, `ajuste_AFE_CONF.csv`, `cargas_AFE_SAT_5_factores.csv`,
`cargas_AFE_CONF_5_factores.csv`, `cargas_AFE_CONF_11_items.csv`, `congruencia_mitades.csv` y las gráficas de codo.

**Cuidado.** El AFC (02) usa los mismos 31,166 casos del AFE, así que no es una prueba independiente; para eso está el
paso de validación cruzada en 02 (AFE en una mitad y AFC en la otra). Los eigenvalores de las dos escalas
caen de golpe después del primero (5.8 → 1.7 y 6.7 → 1.4): hay un factor general fuerte, que es lo que justifica el
segundo orden (03).
