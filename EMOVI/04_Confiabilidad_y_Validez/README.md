# 04 · Confiabilidad y validez

Script: `Confiabilidad_y_Validez.R` (unos 20 segundos). **Referencia:** la tesis reporta KR-20 (.88 para el índice
de riqueza) y α y Ω para sus otras latentes, con el criterio "cercano o mayor a .7". **No** trae validez
discriminante ni de criterio: se agregan aquí.

**Pregunta:** ¿son confiables los tres factores de riqueza?, ¿se distinguen entre sí?, ¿se relaciona el puntaje con
lo que debería?

**Respuesta corta:** confiabilidad **alta**; validez discriminante **mixta** (HTMT sí, Fornell-Larcker no del todo);
validez de criterio **sí**, con todas las correlaciones en positivo.

## Paso a paso

1. **Confiabilidad.** KR-20 (el alfa de Cronbach con ítems 0/1), confiabilidad compuesta (CR) y AVE, con las cargas
   del AFC:

   | Factor | Ítems | KR-20 | CR | AVE | r² máximo con otro factor | AVE > r² |
   |---|---|---|---|---|---|---|
   | ESP | 10 | .752 | .897 | .483 | .660 | No |
   | BAS | 14 | .837 | .945 | .559 | .660 | No |
   | TEC | 5 | .851 | .955 | .811 | .653 | Sí |

   KR-20 de .75 a .85 y CR de .90 a .96, por encima de .70 (la tesis: .88). La AVE de **ESP (.48) no llega a .50**.
2. **Validez discriminante.**
   - **Fornell-Larcker:** la AVE de cada factor debe superar su r² más alto con otro factor (.66, el de ESP–BAS).
     ESP (.48) y BAS (.56) **no** lo cumplen; TEC (.81) sí.
   - **HTMT** (con correlaciones tetracóricas; se pide < .85):

     | Par | r entre factores | HTMT |
     |---|---|---|
     | ESP – BAS | .81 | .80 |
     | ESP – TEC | .69 | .69 |
     | BAS – TEC | .81 | .83 |

   Por HTMT los tres pares quedan bajo .85 (BAS–TEC se acerca); por Fornell-Larcker, ESP y BAS no se separan del
   todo. Los factores se distinguen pero comparten mucho, que es lo que hace útil el segundo orden
   ([`03`](../03_AFC_2do_Orden/)).
3. **Validez de criterio.** Correlación de Spearman del puntaje de riqueza (segundo orden) con:

   | Criterio | ρ | n |
   |---|---|---|
   | `p104` lugar del hogar a los 14 años en una escala de 1 a 10 (el criterio más cercano) | **.46** | 740 |
   | `educp` educación del padre (4 categorías) | .38 | 592 |
   | `educm` educación de la madre | **.52** | 633 |
   | `clasep` clase ocupacional del padre | .26 | 594 |
   | `p103` lugar del hogar hoy | .28 | 740 |
   | Logaritmo del ingreso per cápita actual (`ingc_pc`) | .33 | 740 |

   Todas positivas. Las más cercanas al origen (`p104`, educación de los padres) son las más altas. La clase del
   padre es la más baja: las 6 clases no son una escala de prestigio estricta.

**Salidas** (`output/`): `confiabilidad.csv`, `htmt.csv` y `validez_criterio.csv`.
