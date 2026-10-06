# =============================================================================
# Libro SEM · Habilidades Políticas
# 00 - Diagnóstico: ¿qué tenemos y qué falta?
# =============================================================================
# Referencias: capítulo "Validación del inventario de habilidades políticas de
# Ferris mediante análisis factorial de segundo orden" (López-Lemus y Zavala;
# PDF), su presentación (PPTX) y la base Cap6_AFC_2orden.dta.
#
# Este script (1) revisa qué trae la base, (2) comprueba las condiciones que
# el capítulo pide para un AFC (su Tabla 2) y (3) intenta reproducir los
# números publicados (su Tabla 5 y los índices de ajuste).
#   source("Habilidades_Politicas/00_Diagnostico/Diagnostico.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Habilidades_Politicas/00_Diagnostico/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. ¿Qué trae la base?
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
dim(hp)                      # 356 filas y 16 columnas
names(hp)                    # Genero y 15 ítems (faltan HR5, AS12 e II15)
sapply(hp, class)
varlabel(hp)                 # etiquetas de variable: vacías
attr(hp, "label.table")      # etiquetas de valor: no hay
colSums(is.na(hp))           # ningún faltante
sum(duplicated(hp))          # renglones idénticos (no hay identificador)

# Género: el .dta guarda 1 y 2 sin etiqueta. El capítulo reporta 161 hombres
# y 195 mujeres, así que 1 = hombre y 2 = mujer (se deduce de las frecuencias).
table(hp$Genero)

items <- setdiff(names(hp), "Genero")
rango <- t(sapply(hp[, items], range))
colnames(rango) <- c("min", "max")
rango                        # todos entre 1 y 7 (Likert de 7 puntos)

# Descriptivos y forma de los ítems
descriptivos <- describe(hp[, items])[, c("n", "mean", "sd", "skew", "kurtosis")]
descriptivos$pct_max <- sapply(hp[, items], function(x) 100 * mean(x == max(x)))
descriptivos$pct_min <- sapply(hp[, items], function(x) 100 * mean(x == min(x)))
round(descriptivos, 2)       # asimetría negativa: se contesta hacia "de acuerdo"
write.csv(round(descriptivos, 3), file.path(dir_salida, "descriptivos_items.csv"))

# -----------------------------------------------------------------------
# Paso 2. Condiciones para el AFC (Tabla 2 del capítulo)
# -----------------------------------------------------------------------
modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
modelo_2do <- paste(modelo_1er, 'HP =~ HR + SA + AS + II', sep = "\n")

# a) Factores con sustento teórico: sí (Ferris et al., 2005).
# b) Más de 2 variables por factor: 5, 3, 4 y 3.
# c) KMO > .50
KMO(hp[, items])$MSAi
KMO(hp[, items])$MSA
# d) Al menos 5 observaciones por indicador: 356 / 15 = 23.7
nrow(hp) / length(items)
# e) Datos perdidos: ninguno (ver arriba).
# f) Multicolinealidad entre las variables latentes (correlaciones > .85 o .90
#    son una señal de alarma: los factores no se distinguen).
fit_1er <- cfa(modelo_1er, data = hp)
round(lavInspect(fit_1er, "cor.lv"), 3)   # la mayor: SA-AS = .885
# g) Normalidad multivariada (la pide ML)
mardia(hp[, items], plot = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Reproducir lo publicado: cargas de la Tabla 5 (versión de 15 ítems)
# -----------------------------------------------------------------------
# Valores de la Tabla 5 del capítulo (cargas estandarizadas y error estándar)
publicado <- data.frame(
  rhs = c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9", "AS10", "AS11",
          "AS13", "AS14", "II16", "II17", "II18"),
  carga_pub = c(.647, .751, .755, .710, .671, .723, .739, .638, .693, .626,
                .655, .664, .735, .785, .810),
  ee_pub    = c(.036, .029, .028, .031, .034, .033, .031, .037, .034, .039,
                .036, .036, .030, .027, .026))
segundo_pub <- data.frame(rhs = c("HR", "SA", "AS", "II"),
                          carga_pub = c(.824, .933, .949, .805),
                          ee_pub = c(.030, .028, .027, .032))

fit_2do <- cfa(modelo_2do, data = hp)      # ML, como ESTIMATOR=ML de Mplus
std <- standardizedSolution(fit_2do)
std <- std[std$op == "=~", c("lhs", "rhs", "est.std", "se")]

# a) Cruce por etiqueta, tal como está impreso en la tabla
comparar <- function(pub, std, por = "rhs") {
  r <- merge(pub, std, by.x = por, by.y = "rhs", sort = FALSE)
  r$dif_carga <- round(r$est.std - r$carga_pub, 3)
  r$dif_ee <- round(r$se - r$ee_pub, 3)
  r
}
tabla5 <- rbind(comparar(publicado, std[std$lhs != "HP", ]),
                comparar(segundo_pub, std[std$lhs == "HP", ]))
tabla5[tabla5$dif_carga != 0, c("rhs", "carga_pub", "est.std", "dif_carga")]
# Tres ítems no coinciden: AS10 (.693 publicado, .655 en R), AS11 (.626 contra
# .693) y AS13 (.655 contra .626). Los TRES valores publicados sí existen en
# el modelo, pero en otro ítem: la tabla trae las cargas en el orden de las
# columnas de la base (AS11, AS13, AS10, AS14; el orden del Anexo 2) con las
# etiquetas en orden numérico (AS10, AS11, AS13, AS14). La lámina 17 de la
# presentación (la salida de R) las trae bien.

# b) Cruce por orden de columnas: la fila "AS10" de la tabla es AS11, la
#    "AS11" es AS13 y la "AS13" es AS10
publicado$rhs_columna <- publicado$rhs
publicado$rhs_columna[publicado$rhs %in% c("AS10", "AS11", "AS13")] <-
  c("AS11", "AS13", "AS10")
segundo_pub$rhs_columna <- segundo_pub$rhs
tabla5_orden <- rbind(comparar(publicado, std[std$lhs != "HP", ], por = "rhs_columna"),
                      comparar(segundo_pub, std[std$lhs == "HP", ], por = "rhs_columna"))
max(abs(tabla5_orden$dif_carga))   # menos de .001: las 19 cargas se reproducen
range(tabla5_orden$dif_ee)         # errores estándar: dentro de .001
# Las cargas publicadas de primer y segundo orden se reproducen con la base.

# -----------------------------------------------------------------------
# Paso 4. Reproducir lo publicado: índices de ajuste
# -----------------------------------------------------------------------
medidas <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "bic2")
# a) El modelo bien especificado, con los 15 ítems
ajuste_15 <- fitMeasures(fit_2do, medidas)

# b) El capítulo reporta chi2 = 273.894 con 101 gl. Con 15 ítems el modelo
#    tiene 86 gl (120 momentos - 34 parámetros), no 101. La diferencia (15)
#    es lo que agrega UNA variable más: con Genero como variable 16 hay
#    136 momentos y 35 parámetros (la varianza de Genero) = 101 gl.
#    La sintaxis del Anexo 2 declara Genero en NAMES y no trae USEVARIABLES:
#    Mplus usa entonces todas las variables de NAMES y deja a Genero sin
#    relación con nada. Se reproduce agregándola con su varianza libre y
#    sin covarianzas.
fit_genero <- cfa(paste(modelo_2do, "Genero ~~ Genero", sep = "\n"), data = hp)
ajuste_genero <- fitMeasures(fit_genero, medidas)

# c) El BIC ajustado de Mplus (17026.484) incluye las medias (Mplus las
#    estima siempre): 16 interceptos más.
fit_genero_medias <- cfa(paste(modelo_2do, "Genero ~~ Genero", sep = "\n"),
                         data = hp, meanstructure = TRUE)
fitMeasures(fit_genero_medias, "bic2")

publicado_ajuste <- c(chisq = 273.894, df = 101, cfi = .926, tli = .912,
                      rmsea = .069, srmr = .048, bic2 = 17026.484)
# El BIC ajustado de las tres filas incluye la estructura de medias, como Mplus
fit_15_medias <- cfa(modelo_2do, data = hp, meanstructure = TRUE)
comparacion <- rbind(`Capítulo (Mplus)`      = publicado_ajuste,
                     `lavaan con Genero`     = c(ajuste_genero[1:6],
                                                 bic2 = fitMeasures(fit_genero_medias, "bic2")),
                     `lavaan sin Genero`     = c(ajuste_15[1:6],
                                                 bic2 = fitMeasures(fit_15_medias, "bic2")))
round(comparacion, 3)
# Con Genero: coinciden chi2, gl, CFI, TLI, RMSEA y BIC ajustado. El SRMR
# publicado (.048) es el del modelo SIN Genero (con ella sale .051).
# Sin Genero (el modelo que describe el capítulo): chi2(86) = 246.604,
# CFI = .931, TLI = .915, RMSEA = .072, SRMR = .048. Es lo que reporta la
# lámina 19 de la presentación en la columna "R" (que escribe 89 gl; con
# esa chi2 el modelo solo puede tener 86).

# -----------------------------------------------------------------------
# Paso 5. Lo que NO se puede reproducir
# -----------------------------------------------------------------------
# El primer modelo del capítulo (18 reactivos: chi2 = 500.161, 150 gl, CFI
# = .875) usa los ítems 5, 12 y 15, que la base no trae. Solo está la
# versión de 15 ítems.
items_18 <- c(paste0("HR", 1:6), paste0("SA", 7:9), paste0("AS", 10:14), paste0("II", 15:18))
setdiff(items_18, names(hp))   # HR5, AS12 e II15

write.csv(tabla5, file.path(dir_salida, "replica_tabla5_por_etiqueta.csv"), row.names = FALSE)
write.csv(tabla5_orden, file.path(dir_salida, "replica_tabla5_por_orden_de_columna.csv"), row.names = FALSE)
write.csv(round(comparacion, 3), file.path(dir_salida, "replica_ajuste.csv"))
