# 05 · Puntajes factoriales

Script: `Puntajes_Factoriales.R` (unos 10 segundos). **Sin referencia propia:** no hay puntajes publicados. Con los modelos de
segundo orden de 03 se calculan los puntajes de los 10 factores de primer orden y de los dos generales (satisfacción con
la vida y confianza institucional), su determinación, la comparación con medias simples, una versión en escala 0-10 y las
medias por tamaño de localidad y entidad, con y sin ponderador.

**Pregunta:** ¿qué tan bien se pueden estimar los factores de cada persona, y cómo cambian entre localidades y entidades?

**Respuesta corta:** los **31,166 reciben puntaje** de los 12 factores; la determinación va de **.84 a .97** (los generales,
.91 y .95). La satisfacción casi no cambia con el tamaño de localidad (8.0 de 10) pero la **confianza institucional sí**: baja
de 5.2 en las localidades más pequeñas a 4.3 en las más grandes. Entre entidades, la satisfacción va de 7.7 (Puebla) a 8.4
(Coahuila).

## Paso a paso

1. **Puntajes por regresión** (`lavPredict`, el método de Mplus): media 0, sin faltantes (no hay ninguno en las escalas).
   El resultado queda en la **métrica de cada factor**:

   | Factor | Desviación | Mín. | Máx. |
   |---|---|---|---|
   | `NIV` · `REL` · `AUT` · `BAR` · `CIU` | 2.24 · 1.72 · 1.89 · 1.29 · 1.11 | −14.7 a −5.4 | 1.7 a 3.3 |
   | **`SAT`** | **0.91** | −6.38 | 1.37 |
   | `INT` · `POL` · `MIL` · `JUS` · `PLT` | 0.87 · 1.89 · 1.66 · 2.53 · 1.87 | −4.7 a −2.4 | 1.6 a 4.9 |
   | **`CONF`** | **0.95** | −1.90 | 2.00 |

   Los generales tienen varianza 1 (la desviación de .91 y .95 es el encogimiento de la regresión); los de primer orden
   tienen la varianza que les da el modelo, por eso sus desviaciones pasan de 1. Los mínimos muy bajos (`NIV` −14.7, `AUT`
   −13.1) son las pocas personas que contestaron 0 a casi todo.
2. **Determinación** (correlación del puntaje con el factor verdadero; ≥ .90 = confiable):

   | Factor | `NIV` | `REL` | `AUT` | `BAR` | `CIU` | **`SAT`** | `INT` | `POL` | `MIL` | `JUS` | `PLT` | **`CONF`** |
   |---|---|---|---|---|---|---|---|---|---|---|---|---|
   | ρ | .912 | .902 | .887 | .843 | .891 | **.913** | .872 | .968 | .963 | .959 | .958 | **.950** |

   Ocho de los doce llegan a .90; `AUT`, `BAR`, `CIU` e `INT` (de 2 a 4 ítems con cargas moderadas) quedan entre .84 y .89, y
   ninguno baja de .80. Los de **confianza** son más precisos que los de satisfacción.
3. **Contra la media simple de los ítems:** el puntaje correlaciona de **.92** (`AUT`) a **.99** (`PLT`, `CONF`) con el
   promedio de sus ítems; `SAT`, .97. Con cargas parecidas, el promedio y el puntaje ordenan casi igual.
4. **Escala original (0-10).** Media ponderada por las cargas sin estandarizar (Lab 5): para el general, carga del ítem por la
   de su factor. Queda en la escala de las preguntas y correlaciona con el puntaje de regresión .978 (SAT) y .995 (CONF):

   | | Media | Desv. | Mín. | Máx. |
   |---|---|---|---|---|
   | Satisfacción con la vida (`SAT_0_10`) | 8.03 | 1.20 | 0 | 10 |
   | Confianza institucional (`CONF_0_10`) | 4.79 | 2.47 | 0 | 10 |
5. **Medias por grupo, con y sin ponderador.** Aquí sí se pondera: la media de la población no es la de la muestra (pesos de
   122 a 45,955). **Nacional:** satisfacción 8.03 sin ponderar y **8.01** ponderada; confianza 4.79 y **4.65**.

   | Tamaño de localidad* | n | Satisfacción (pond.) | Confianza (pond.) |
   |---|---|---|---|
   | 1 | 14,095 | 8.00 | **4.33** |
   | 2 | 4,793 | 8.07 | 4.68 |
   | 3 | 4,925 | 8.03 | 4.97 |
   | 4 | 7,353 | 7.98 | **5.16** |

   \* Sin etiquetas; se supone de las más grandes (1) a las más chicas (4). **La satisfacción es plana** (7.98 a 8.07) y la
   **confianza institucional sube casi un punto** de la 1 a la 4. Ponderar baja la confianza hasta .2 (la nacional, de 4.79 a
   4.65): las localidades grandes pesan más en la población.

   Por **entidad** (catálogo estándar de INEGI; el diccionario no trae etiquetas), satisfacción ponderada:

   | Más alta | | Más baja | |
   |---|---|---|---|
   | Coahuila | 8.43 | Puebla | 7.68 |
   | Nuevo León | 8.38 | Ciudad de México | 7.72 |
   | Colima | 8.36 | Tabasco y Oaxaca | 7.83 |
   | Nayarit | 8.35 | Tlaxcala | 7.85 |
   | Sinaloa | 8.29 | México | 7.88 |

   De la primera a la última, .75 puntos. La confianza institucional más baja es la de la **Ciudad de México (3.53)**. Hay
   una gráfica en `output/satisfaccion_por_entidad.png`.
6. **Guardado.** `puntajes_ENBIARE.csv`: los 31,166 con la llave (`folio`, `hogar`; `folio` es la vivienda y se repite
   cuando hay varios hogares), los 12 puntajes de regresión y los dos de escala 0-10.

**Salidas** (`output/`): `resumen_puntajes.csv`, `determinacion.csv`, `comparacion_media_simple.csv`,
`medias_por_tloc.csv`, `medias_por_entidad.csv`, `satisfaccion_por_entidad.png` y `puntajes_ENBIARE.csv`.

**Lo que conviene tener presente.**
- **No se calculan errores estándar de diseño** (haría falta `survey` con estrato y UPM): con ~1,000 personas por entidad y
  pocas UPM por grupo, las diferencias pequeñas entre entidades (de décimas) no deben leerse como significativas.
- Los puntajes salen del modelo de segundo orden con **un general único** en satisfacción (el de 03); con la variante de
  dos generales (personal y entorno) los puntajes de primer orden no se recalcularon.
