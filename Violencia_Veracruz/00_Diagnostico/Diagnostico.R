# =============================================================================
# Libro SEM · Violencia Veracruz
# 00 - Diagnóstico: ¿se pueden hacer los 7 ejercicios con lo que se tiene?
# =============================================================================
# Referencias: la base BASE_ACLnew.dta (Stata) y el script Scripts.do que la
# acompaña: recodifica la clase latente `c` (c_r), corre una regresión logística
# ordinal de c_r contra las variables sociodemográficas y exporta los 24 ítems a
# Mplus (stata2mplus, "ACLmplus"), donde se hizo el análisis de clases latentes.
# Este script no es parte del libro: revisa qué trae la base, qué tan bien se
# comportan sus ítems y qué análisis admite. Tarda unos 15 segundos.
#   source("Violencia_Veracruz/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)
library(MASS)

dir_salida <- "Violencia_Veracruz/00_Diagnostico/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Leer la base
# -----------------------------------------------------------------------
# convert.factors = FALSE deja los códigos de Stata (0 = No, 1 = Sí) como números.
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
dim(vera)                                    # 1,089 renglones y 37 columnas

# Los 24 ítems que Scripts.do exporta a Mplus (stata2mplus), en seis bloques. Los
# bloques salen de la redacción de las etiquetas y de las letras de los reactivos
# (14 a-d, 16 a/b/e, 17 a/b/c/e/f, 18 c-f, 19 a-d, 20 a-d): faltan reactivos de la
# serie (16c, 16d, 17d, 18a, 18b), que la base no trae.
bloques <- list(
  infancia  = c("p141", "p142", "p143", "p144"),
  familia   = c("p161", "p162", "p165"),
  pareja    = c("p171", "p172", "p173", "p175", "p176"),
  trabajo   = c("p183", "p184", "p185", "p186"),
  comunidad = c("p191", "p192", "p193", "p194"),
  escuela   = c("p201", "p202", "p203", "p204"))
items <- unlist(bloques)
bloque <- setNames(rep(names(bloques), lengths(bloques)), items)
sociodemo <- c("p1", "p2", "p3", "p4", "p5", "p7", "p9", "p13", "p62")
setdiff(names(vera), c(items, sociodemo))    # c, c_r, id y _merge: lo demás
all(unlist(vera[, items]) %in% c(0, 1, NA))  # los 24 ítems son 0/1

# -----------------------------------------------------------------------
# Paso 2. Un renglón huérfano: id 907
# -----------------------------------------------------------------------
# `_merge` viene del merge de Stata con el archivo de la clase latente: 1,088
# renglones están en los dos archivos (_merge = 3) y uno solo en el segundo (= 2).
table(vera[["_merge"]])
vera[vera[["_merge"]] == 2, c("id", "c", sociodemo)]   # id 907: tiene sociodemográficas, pero ningún ítem ni clase
rowSums(!is.na(vera[vera[["_merge"]] == 2, items]))    # 0 ítems contestados
length(unique(vera$id))                                # 1,089 id distintos (sí es único)
# Ese renglón no aporta nada a un análisis factorial. Todos los ejercicios lo quitan:
# quedan 1,088 mujeres.
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]
nrow(vera)                                   # 1,088

# -----------------------------------------------------------------------
# Paso 3. Los ítems: etiqueta, prevalencia y faltantes
# -----------------------------------------------------------------------
# Las etiquetas de Stata se cortan a 80 caracteres: la redacción de los reactivos
# queda incompleta (p. ej. "...había gol"). Se necesita el cuestionario.
etiquetas <- setNames(trimws(attr(vera, "var.labels")), names(vera))
n_valido <- colSums(!is.na(vera[, items]))
diccionario <- data.frame(
  variable = items, bloque = bloque[items], etiqueta = etiquetas[items],
  n = n_valido, faltantes = nrow(vera) - n_valido,
  casos_si = colSums(vera[, items], na.rm = TRUE),
  prevalencia_pct = round(100 * colMeans(vera[, items], na.rm = TRUE), 1),
  row.names = NULL)
print(diccionario[, -3], row.names = FALSE)
write.csv(diccionario, file.path(dir_salida, "diccionario_items.csv"), row.names = FALSE)
# Son eventos de violencia, así que varios son raros: 8 de los 24 ítems los reporta
# menos del 5% (p144, p165, p173, p183, p184, p185, p186, p203) y p184 solo 16 mujeres.
sum(diccionario$prevalencia_pct < 5)
range(diccionario$casos_si)                  # de 16 a 371 mujeres que dicen "Sí"
# Nadie falla el criterio 90-10 de EMOVI por el lado alto (ninguno pasa de 34%); por el
# lado bajo fallarían 8. Aquí NO se aplica: en violencia el evento raro es justo lo que
# importa, y quitar los cuatro de trabajo borraría un ámbito completo.

# -----------------------------------------------------------------------
# Paso 4. Los faltantes son estructurales: saltos de pregunta
# -----------------------------------------------------------------------
sum(complete.cases(vera[, items]))           # solo 505 de 1,088 contestan los 24 ítems
sort(colSums(is.na(vera[, items])), decreasing = TRUE)[1:12]
# Pareja (313 mujeres), trabajo (249) y escuela (57) faltan por bloques completos.
n_resp <- sapply(bloques, function(v) table(factor(rowSums(!is.na(vera[, v])), levels = 0:5)))
n_resp
sin_bloque <- sapply(bloques, function(v) rowSums(!is.na(vera[, v])) == 0)
colSums(sin_bloque)                          # sin pareja 313, sin trabajo 249, sin escuela 57 (y 5 y 7 sin familia ni comunidad)

# ¿Quién no contesta? Los saltos de pregunta tienen lógica:
#   pareja: casi todas son solteras, separadas, divorciadas o viudas (p9)
#   trabajo: "actualmente o alguna vez": amas de casa que nunca trabajaron (p5)
#   escuela: "cuando asiste o asistió": sin estudios o que no leen (p4, p3)
tabla_p9 <- table(sin_pareja = sin_bloque[, "pareja"], p9 = vera$p9, useNA = "ifany")
tabla_p9                                     # 1 soltera, 2 separada, 3 divorciada, 4 viuda, 5 unión libre, 6 casada
round(prop.table(table(sin_pareja = sin_bloque[, "pareja"], con_pareja_actual = vera$p9 %in% 5:6), 2), 3)
table(sin_trabajo = sin_bloque[, "trabajo"], ama_de_casa = vera$p5 == 2, useNA = "ifany")
table(sin_escuela = sin_bloque[, "escuela"], p4 = vera$p4, useNA = "ifany")   # 45 de las 57 no tienen estudios
faltantes_estructurales <- data.frame(
  bloque = c("pareja", "trabajo", "escuela"), sin_ningun_item = colSums(sin_bloque)[c("pareja", "trabajo", "escuela")],
  pct = round(100 * colMeans(sin_bloque)[c("pareja", "trabajo", "escuela")], 1), row.names = NULL)
faltantes_estructurales
write.csv(faltantes_estructurales, file.path(dir_salida, "faltantes_estructurales.csv"), row.names = FALSE)

# ¿Quien salta un bloque responde distinto en los demás? (prueba de chi cuadrada por ítem;
# por azar se esperaría 1 de cada 20 con p < .05)
probar <- function(falta, otros) {
  p <- sapply(otros, function(v) {
    ok <- !is.na(vera[[v]]); tt <- table(falta[ok], vera[[v]][ok])
    if (any(dim(tt) < 2)) NA else suppressWarnings(chisq.test(tt)$p.value) })
  c(comparados = sum(!is.na(p)), p_menor_05 = sum(p < .05, na.rm = TRUE), esperados_azar = round(.05 * sum(!is.na(p)), 1))
}
t(sapply(c("pareja", "trabajo", "escuela"), function(b) probar(sin_bloque[, b], setdiff(items, bloques[[b]]))))
# Pareja: 1 de 19 (lo esperado por azar). Trabajo: 8 de 20 y escuela: 4 de 20. Quien
# nunca trabajó reporta MÁS violencia (infancia, pareja): los faltantes de trabajo no
# son completamente al azar. Se retoma en 07_FIML.

# -----------------------------------------------------------------------
# Paso 5. ¿Se pueden calcular correlaciones tetracóricas?
# -----------------------------------------------------------------------
# Con eventos raros hay parejas de ítems casi sin mujeres que digan "Sí" en ambos.
n11 <- outer(items, items, Vectorize(function(a, b) sum(vera[[a]] == 1 & vera[[b]] == 1, na.rm = TRUE)))
dimnames(n11) <- list(items, items)
pares <- which(lower.tri(n11), arr.ind = TRUE)
pares <- data.frame(a = items[pares[, 1]], b = items[pares[, 2]], n_si_si = n11[pares])
c(parejas = nrow(pares), con_2_o_menos = sum(pares$n_si_si <= 2), con_5_o_menos = sum(pares$n_si_si <= 5))
head(pares[order(pares$n_si_si), ], 8)       # p184-p172, p203-p194, p185-p203: 0 mujeres
write.csv(pares[pares$n_si_si <= 5, ], file.path(dir_salida, "pares_dispersos.csv"), row.names = FALSE)

# La matriz que usan los modelos ordinales (policórica por pares) no es definida
# positiva: su eigenvalor menor es negativo. Con la correlación de Pearson (phi) sí lo es.
R_pol <- lavCor(vera[, items], ordered = items, missing = "pairwise")
R_phi <- cor(vera[, items], use = "pairwise.complete.obs")
round(c(policorica = min(eigen(R_pol)$values), phi = min(eigen(R_phi)$values)), 3)
# Los coeficientes tetracóricos de los pares sin casos salen de -.40 a -.60 (espurios).
# Consecuencia práctica: KMO, Bartlett y el análisis paralelo se hacen con phi (como en
# EMOVI), y el SRMR de los modelos ordinales sale inflado (ver 02_AFC).
round(KMO(R_phi)$MSA, 2)                     # .79: aceptable

# -----------------------------------------------------------------------
# Paso 6. La clase latente c (análisis de clases latentes de Mplus)
# -----------------------------------------------------------------------
table(vera$c, useNA = "ifany")               # 152, 256 y 680 mujeres
all(vera$c_r == 4 - vera$c)                  # c_r = recode(c, 1=3, 3=1), como en Scripts.do
table(c_r = vera$c_r)
# Perfil de cada clase (proporción que dice "Sí"): c_r = 1 casi no reporta violencia;
# c_r = 3 reporta de todo; c_r = 2 reporta sobre todo violencia en la infancia.
perfil <- round(t(sapply(split(vera[, items], vera$c_r), colMeans, na.rm = TRUE)), 2)
perfil
write.csv(perfil, file.path(dir_salida, "perfil_clases.csv"))
# Ojo: c_r NO es una escala de menos a más violencia en todo. p141-p143 (infancia) son
# MÁS altos en la clase 2 (.92, .76, .93) que en la 3 (.68, .52, .63). La clase 2 es
# "violencia en la infancia"; la 3, "violencia en varios ámbitos" (pareja .50-.64).
# Y como las clases salen de estos mismos 24 ítems, c_r no es un criterio independiente.
round(tapply(rowSums(vera[, items], na.rm = TRUE), vera$c_r, mean), 1)   # 0.8, 4.1 y 7.3 eventos

# -----------------------------------------------------------------------
# Paso 7. Réplica de Scripts.do: regresión logística ordinal de c_r
# -----------------------------------------------------------------------
# `ologit c_r i.p1, or` de Stata == polr() de MASS (exp de los coeficientes).
# Una razón de momios mayor que 1 = más probabilidad de caer en la clase de más violencia.
vera$c_ord <- factor(vera$c_r, ordered = TRUE)
razones <- do.call(rbind, lapply(sociodemo, function(v) {
  d <- vera[!is.na(vera[[v]]), ]
  m <- polr(c_ord ~ factor(d[[v]]), data = d, Hess = TRUE)
  ci <- matrix(suppressMessages(exp(confint(m))), ncol = 2)   # con un solo coeficiente confint() da un vector
  data.frame(variable = v, categoria = sub("^factor\\(d\\[\\[v\\]\\]\\)", "", names(coef(m))),
             n = nrow(d), RM = exp(coef(m)), ic_inf = ci[, 1], ic_sup = ci[, 2], row.names = NULL)
}))
razones[, 4:6] <- round(razones[, 4:6], 2)
razones
write.csv(razones, file.path(dir_salida, "ologit_razones_de_momios.csv"), row.names = FALSE)
# Indígena (p1) RM 2.9; leer y escribir (p3) 0.49; escolaridad (p4) baja de .86 (primaria) a
# .22 (universidad); conocer los derechos de las mujeres (p62) 0.73; recibir dinero (p7) 1.55;
# viuda (p9) 2.3 y unión libre 2.2 contra soltera. La edad (p2) sube hasta 1.6 en 55-64 y la
# edad al primer embarazo (p13) baja (.29 a los 25-29). Son asociaciones de a una variable.
# Se retoman como criterios externos en 04_Confiabilidad_y_Validez.

# -----------------------------------------------------------------------
# Paso 8. Qué admite la base: una prueba rápida de cada ejercicio
# -----------------------------------------------------------------------
medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
modelo6 <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  TRA =~ p183 + p184 + p185 + p186
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'
fit6 <- cfa(modelo6, data = vera, ordered = items, estimator = "WLSMV", missing = "pairwise")
round(fitMeasures(fit6, medidas), 3)         # CFI .987, TLI .985, RMSEA .019: los seis ámbitos se confirman
fit1 <- cfa(paste("VIO =~", paste(items, collapse = " + ")), data = vera, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
round(fitMeasures(fit1, medidas), 3)         # un solo factor: CFI .847, RMSEA .065
fit6g <- cfa(paste(modelo6, "\n VIO =~ INF + FAM + PAR + TRA + COM + ESC"), data = vera, ordered = items,
             estimator = "WLSMV", missing = "pairwise")
round(fitMeasures(fit6g, medidas), 3)        # con un factor general encima: mismo ajuste, 9 gl más
# FIML: lavaan no lo ofrece con ítems ordinales; sí tratándolos como continuos (MLR).
fiml <- try(cfa(modelo6, data = vera, ordered = items, estimator = "WLSMV", missing = "fiml"), silent = TRUE)
cat(gsub("\n.*", "", attr(fiml, "condition")$message), "\n")   # "missing = fiml not available in the categorical setting"

# Grupos para la invarianza: no hay sexo (todas son mujeres), pero sí edad (p2),
# escolaridad (p4), conocer los derechos de las mujeres (p62), leer y escribir (p3) y
# recibir dinero (p7). Un grupo sirve si sus ítems raros tienen casos "Sí" suficientes.
vera$edad_g    <- ifelse(vera$p2 <= 3, "18-44", "45+")
vera$escol_g   <- ifelse(vera$p4 <= 2, "hasta primaria", ifelse(vera$p4 <= 5, "secundaria o más", NA))
vera$derechos  <- ifelse(vera$p62 == 1, "conoce", "no conoce")
vera$lee       <- ifelse(vera$p3 == 1, "lee y escribe", "no lee ni escribe")
vera$dinero    <- ifelse(vera$p7 == 1, "recibe", "no recibe")
grupos <- c("edad_g", "escol_g", "derechos", "lee", "dinero")
viabilidad <- do.call(rbind, lapply(grupos, function(g) {
  do.call(rbind, lapply(split(vera, vera[[g]]), function(d) {
    data.frame(grupo = g, nivel = d[[g]][1], n = nrow(d),
               min_casos_si = min(colSums(d[, items], na.rm = TRUE)),
               item_critico = names(which.min(colSums(d[, items], na.rm = TRUE))), row.names = NULL)
  }))
}))
viabilidad
write.csv(viabilidad, file.path(dir_salida, "viabilidad_grupos.csv"), row.names = FALSE)
# Con las 1,088 mujeres, cada ítem tiene al menos 16 "Sí". Partidas en dos grupos, el ítem
# más raro (casi siempre de trabajo) baja a: edad 9 y 6; escolaridad 3 y 10; derechos 12 y 2; leer
# y escribir 16 y 0; dinero 13 y 2. Edad (18-44 contra 45+; 665 y 421) y escolaridad (449 y
# 618) son los cortes más viables, pero con los cuatro ítems de trabajo el modelo se vuelve
# inadmisible en uno de los grupos. Se prueba en 06_Invarianza_Factorial.
