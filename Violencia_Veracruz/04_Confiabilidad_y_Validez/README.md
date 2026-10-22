# 04 · Confiabilidad y validez: los seis ámbitos de violencia

Script: `Confiabilidad_y_Validez.R` (unos 45 segundos). **Sin referencia propia:** `Scripts.do` no calcula confiabilidad ni validez. Se sigue
el esquema de EMOVI (ítems 0/1): **KR-20**, **confiabilidad compuesta (CR)**, **AVE**, **Fornell-Larcker** y **HTMT**, más el **omega** del
factor general. Como criterio externo solo hay dos cosas: la clase latente `c_r` (que sale de estos mismos ítems) y las variables
sociodemográficas.

**Pregunta:** ¿qué tan confiables son los seis ámbitos y se distinguen unos de otros?

**Respuesta corta: confiabilidad compuesta alta (CR .78 a .94) y validez discriminante clara (HTMT máximo .61), con dos matices.**
Los ámbitos con **eventos raros o heterogéneos** (trabajo y comunidad) tienen un KR-20 bajo (.52 y .49) y la AVE de comunidad (.487) no llega a
.50. **No hay validez de criterio independiente.**

## Confiabilidad

1. **KR-20, CR y AVE** (CR = (Σλ)² / [(Σλ)² + Σ(1 − λ²)], con las cargas ordinales de [`02_AFC`](../02_AFC/); AVE = promedio de λ²):

   | Ámbito | Ítems | Mujeres (completas) | KR-20 | CR | AVE | r² máx. con otro factor | AVE > r² |
   |---|---|---|---|---|---|---|---|
   | Infancia (`INF`) | 4 | 1,073 | .80 | **.94** | .81 | .33 | Sí |
   | Familia (`FAM`) | 3 | 1,078 | .65 | **.93** | .82 | .36 | Sí |
   | Pareja (`PAR`) | 5 | 765 | .77 | **.94** | .75 | .26 | Sí |
   | Trabajo (`TRA`) | 4 | 834 | **.52** | .86 | .60 | .36 | Sí |
   | Comunidad (`COM`) | 4 | 1,071 | **.49** | .78 | **.487** | .24 | Sí |
   | Escuela (`ESC`) | 4 | 1,021 | .72 | .91 | .72 | .20 | Sí |

   - **CR de .78 a .94:** confiabilidad compuesta alta en los seis.
   - **El KR-20 es mucho más bajo** en trabajo (.52) y comunidad (.49), y bajo en familia (.65). El KR-20 supone que todos los ítems pesan igual,
     y aquí no (`p193` y `p194` cargan .47 mientras `p191` y `p192` cargan .86–.88); además, con eventos raros las correlaciones entre ítems 0/1 están
     muy limitadas por sus frecuencias distintas.
   - **AVE:** todos superan .50 salvo **comunidad (.487)**, por `p193` y `p194`. Con CR de .78 (> .60), la validez convergente de comunidad
     sigue siendo aceptable por el criterio de Fornell y Larcker (1981).
2. **KR-20 por ítem.** Tres ítems **mejoran** el KR-20 de su ámbito si se quitan: `p144` (.80 → .86), `p165` (.65 → .68) y `p203` (.72 → .74).
   Son tres ítems raros (4.6 %, 2.5 % y 4.0 %) con poca correlación ítem-resto (.32 a .37) aunque en el AFC cargan fuerte (.77, .92 y .79): la carga
   ordinal corrige por la baja frecuencia del evento. No se quita ninguno.
3. **Confiabilidad del factor general.** CR de `VIO` = **.83**; omega total = **.97**; omega jerárquico = **.79**: el **82 %** de la confiabilidad
   de la escala de 24 ítems se debe al factor general (en Habilidades Políticas fue el 92 %). Son omegas sobre las respuestas latentes
   (ordinales) y **son optimistas**: la confiabilidad de una suma simple de ítems 0/1 con eventos raros es mucho menor (ver el KR-20).

## Validez

4. **Validez de contenido (cualitativa).** Los 24 ítems cubren seis ámbitos de violencia contra las mujeres y formas distintas (según las etiquetas:
   emocional, física, sexual, económica). Pero la base trae **una selección** de los reactivos (faltan `p163`, `p164`, `p174`, `p181` y `p182`) y las etiquetas
   están cortadas a 80 caracteres: la cobertura real solo se puede juzgar con el cuestionario.
5. **Validez discriminante: HTMT** (promedio de las correlaciones entre ítems de dos factores / raíz del producto de los promedios dentro de cada uno;
   se pide < .85) y **Fornell-Larcker** (AVE > r² con cualquier otro factor):

   | Par | *r* entre factores | HTMT |
   |---|---|---|
   | FAM – TRA | .60 | **.61** |
   | INF – FAM | .57 | .60 |
   | FAM – COM | .49 | .54 |
   | FAM – PAR | .51 | .53 |
   | INF – PAR | .48 | .51 |
   | TRA – COM | .45 | .48 |
   | PAR – COM | .47 | .46 |
   | PAR – TRA | .50 | .43 |
   | INF – ESC | .43 | .41 |
   | PAR – ESC | .37 | .40 |
   | TRA – ESC | .44 | .37 |
   | FAM – ESC | .33 | .36 |
   | INF – TRA | .32 | .30 |
   | INF – COM | .31 | .29 |
   | COM – ESC | .32 | .24 |

   El HTMT máximo es **.61**, muy por debajo de .85, y Fornell-Larcker se cumple en los seis: **los ámbitos se distinguen con claridad**. Los pares más
   cercanos son familia con trabajo (que el AFE fusionaba) y familia con infancia.
6. **Validez convergente con la clase latente `c_r`.** `c_r` sale del análisis de clases latentes de **estos mismos 24 ítems**, así que **no es un criterio
   independiente**: sirve para ver que los puntajes factoriales y las clases cuentan la misma historia, no para probar que la escala mide violencia.
   Promedio del puntaje (EBM, ver [`05`](../05_Puntajes_Factoriales/)) por clase:

   | `c_r` | `INF` | `FAM` | `PAR` | `TRA` | `COM` | `ESC` | `VIO` |
   |---|---|---|---|---|---|---|---|
   | 1 (poca violencia) | −0.20 | −0.02 | −0.03 | −0.02 | 0.00 | −0.02 | −0.05 |
   | 2 (infancia) | **0.91** | 0.47 | 0.23 | 0.35 | 0.32 | 0.45 | 0.43 |
   | 3 (varios ámbitos) | 0.74 | **0.94** | **1.13** | **0.83** | **0.86** | **0.81** | **0.82** |

   `VIO` sube con la clase (η² = .66). **`INF` es la excepción esperada:** es más alta en la clase 2 (infancia) que en la 3. Pareja, familia, trabajo, comunidad y escuela
   suben de la clase 1 a la 3. η² por puntaje: `INF` .74, `PAR` .62, `TRA` .50, `FAM` .48, `COM` .35, `ESC` .31.
7. **Correlatos sociodemográficos (exploratorio).** Correlación de Spearman del puntaje `VIO` con las variables de `Scripts.do`:

   | Variable | ρ | p | n |
   |---|---|---|---|
   | Edad al primer embarazo (`p13`) | **−.21** | < .001 | 876 |
   | Escolaridad (`p4`, 1 ninguna … 5 universidad) | **−.20** | < .001 | 1,067 |
   | Sabe leer y escribir (`p3`) | −.11 | < .001 | 1,086 |
   | Conoce los derechos de las mujeres (`p62`) | −.07 | .017 | 1,075 |
   | Recibe dinero de alguien (`p7`) | +.07 | .026 | 1,040 |
   | Se considera indígena (`p1`) | +.06 | .060 | 1,088 |
   | Edad, grupo (`p2`) | +.04 | .170 | 1,086 |

   Las direcciones coinciden con las razones de momios de `Scripts.do` ([`00_Diagnostico`](../00_Diagnostico/)): menos violencia con más escolaridad y con un
   primer embarazo más tardío. Pero las correlaciones son **bajas** (|ρ| ≤ .21): son asociaciones débiles, **no una prueba de criterio**.

**Salidas** (`output/`): `confiabilidad.csv`, `kr20_por_item.csv`, `omega_factor_general.csv`, `htmt.csv`, `puntajes_por_clase.csv` y
`correlatos_sociodemograficos.csv`.

**Lo que falta.** Una **validez de criterio** de verdad pide una variable externa que mida lo mismo (otra escala de violencia, denuncias, salud
mental...) y que no salga de estos 24 ítems. Y un documento de validez que diga qué pruebas se esperan (en el Tren se usó SEM06).
