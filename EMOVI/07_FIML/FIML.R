# =============================================================================
# Libro SEM · EMOVI
# 07 - FIML: Origen social con datos faltantes
# =============================================================================
# Referencia: la tesis (Sánchez Flores, 2019) estima con FIML porque el ISEI de la
# madre solo existe en 1,149 de 3,117 casos y el de la ocupación actual en 1,911;
# recortar a los casos completos "podría sesgar los estimadores" (Vargas y Lorenz,
# 2015). Aquí se hace el AFC de Origen social con sus indicadores de la CDMX 2023 y
# se compara listwise contra FIML.
#   source("EMOVI/07_FIML/FIML.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "EMOVI/07_FIML/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: los cinco indicadores de Origen social
# -----------------------------------------------------------------------
# La tesis usa ISEI del padre y de la madre, índice de riqueza, máximo nivel
# educativo de los padres y sus años de escolaridad. Con las decisiones del
# proyecto (6 clases ocupacionales, sin ISEI) quedan:
#   clasep, clasem  clase ocupacional del padre y de la madre (1 a 6)
#   educp, educm    nivel educativo del padre y de la madre (1 a 4)
#   riq             índice de riqueza del hogar de origen (puntaje del segundo orden, 05)
# Las clases se tratan como numéricas (1 agrícolas ... 6 no manual alta calificación):
# lavaan no ofrece FIML con ítems ordinales, solo con indicadores continuos.
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))
medidas_riq <- '
  ESP =~ p29a + p29b + p29c + p29d + p29e + p29f + p26e + p31f + p31g + p32a
  BAS =~ p26a + p26c + p26d + p29g + p31a + p31b + p31c + p31d + p31e + p31m + p31o + p32e + p32f + p32h
  TEC =~ p31h + p31i + p31j + p31k + p31l
  RIQ =~ ESP + BAS + TEC'
items <- unlist(regmatches(medidas_riq, gregexpr("p[0-9]+[a-o]", medidas_riq)))
fit_riq <- cfa(medidas_riq, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")
emovi$riq <- as.numeric(lavPredict(fit_riq, method = "EBM")[, "RIQ"])

indicadores <- c("riq", "educp", "educm", "clasep", "clasem")
datos <- emovi[, indicadores]

# -----------------------------------------------------------------------
# Paso 2. Cuántos datos faltan
# -----------------------------------------------------------------------
faltantes <- data.frame(indicador = indicadores, n_NA = colSums(is.na(datos)),
                        pct_NA = round(100 * colMeans(is.na(datos)), 1), row.names = NULL)
faltantes                                    # clasem 56%, educp 20%, clasep 20%, educm 15%, riq 0%
c(completos = sum(complete.cases(datos)), con_algun_dato = sum(rowSums(!is.na(datos)) > 0))   # 195 y 740
# Con listwise se queda el 26% de la muestra (195 de 740). La falta de clasem no es
# casual: 340 de los 416 que no la tienen son madres que "nunca trabajaron" (p51 = 7).
table(sin_clasem = is.na(emovi$clasem), p51 = emovi$p51, useNA = "ifany")[, c("1", "7", "8", "9", "10")]
write.csv(faltantes, file.path(dir_salida, "faltantes.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. AFC de Origen social: listwise contra FIML
# -----------------------------------------------------------------------
# MLR (errores estándar robustos) y std.lv = TRUE (varianza del factor = 1).
modelo <- "OS =~ riq + educp + educm + clasep + clasem"
fit_lw   <- cfa(modelo, data = datos, estimator = "MLR", std.lv = TRUE)                       # listwise
fit_fiml <- cfa(modelo, data = datos, estimator = "MLR", std.lv = TRUE, missing = "fiml")    # FIML

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(f, nombre) {
  m <- as.numeric(round(fitMeasures(f, medidas), 3))
  data.frame(modelo = nombre, N = lavInspect(f, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}
tabla_ajuste <- rbind(ajuste(fit_lw, "Listwise"), ajuste(fit_fiml, "FIML"))
tabla_ajuste
# N: 195 contra 740 (3.8 veces más casos). El ajuste de FIML es algo peor (CFI .956,
# RMSEA .098 contra .976 y .077): con más casos, la prueba ve más detalle.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_listwise_vs_fiml.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cargas estandarizadas y errores estándar
# -----------------------------------------------------------------------
carga <- function(f) { s <- standardizedSolution(f); s[s$op == "=~", "est.std"] }
ee <- function(f) { p <- parameterEstimates(f); p[p$op == "=~", "se"] }
comparacion <- data.frame(indicador = indicadores, carga_listwise = round(carga(fit_lw), 2),
                          carga_FIML = round(carga(fit_fiml), 2),
                          ee_listwise = round(ee(fit_lw), 3), ee_FIML = round(ee(fit_fiml), 3))
comparacion$razon_ee <- round(comparacion$ee_FIML / comparacion$ee_listwise, 2)
comparacion
# Las cargas casi no cambian (diferencias de .00 a .05: clasem .65 contra .60, clasep
# .45 contra .41, educm .81 contra .78) y los errores estándar bajan a cerca de dos
# tercios (.63 en promedio): se gana precisión sin mover el resultado. El indicador
# más débil es la clase del padre (.41). Con tan pocas clases, tratarla como numérica
# es una simplificación; sin ISEI, esta latente es menos fina que la de la tesis.
round(mean(comparacion$razon_ee), 2)
write.csv(comparacion, file.path(dir_salida, "cargas_listwise_vs_fiml.csv"), row.names = FALSE)
