# =============================================================================
# Libro SEM · Habilidades Políticas
# 07 - Datos faltantes: FIML
# =============================================================================
# Referencias: capítulo (Anexo 1 y 2: "Missing are all (-9999)" y ESTIMATOR =
# ML en Mplus) y la presentación (R con lavaan).
#
# La base NO tiene datos faltantes: los 356 estudiantes contestaron los 15
# ítems. La instrucción "Missing are all (-9999)" de Mplus no encuentra nada
# que declarar. Con datos completos, FIML y ML son lo mismo (paso 2). Para
# poder mostrar qué hace FIML, el paso 3 le QUITA datos a la base a propósito
# (faltantes simulados) y compara eliminación por lista contra FIML con la
# solución completa como referencia. Es un ejercicio didáctico: los resultados
# del paso 3 no son datos reales.
#   source("Habilidades_Politicas/07_FIML/FIML.R")      # ~10 min (el paso 4)
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Habilidades_Politicas/07_FIML/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. ¿Cuántos datos faltan y dónde?
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
items <- c("HR1", "HR2", "HR3", "HR4", "HR6", "SA7", "SA8", "SA9",
           "AS10", "AS11", "AS13", "AS14", "II16", "II17", "II18")
hp <- hp[, c("Genero", items)]

sum(is.na(hp))                  # 0 faltantes
sum(hp[, items] == -9999)       # 0: ni siquiera el código de faltante de Mplus
sum(complete.cases(hp))         # 356 de 356
# Eliminación por lista (listwise) y FIML usarían los mismos 356 casos.

modelo <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18
  HP =~ HR + SA + AS + II'

# -----------------------------------------------------------------------
# Paso 2. Con datos completos, FIML = ML
# -----------------------------------------------------------------------
fit_ml   <- cfa(modelo, data = hp)                       # ML, como en el capítulo
fit_fiml <- cfa(modelo, data = hp, missing = "fiml")     # FIML
medidas <- c("ntotal", "chisq", "df", "cfi", "tli", "rmsea", "srmr")
rbind(ML = fitMeasures(fit_ml, medidas), FIML = fitMeasures(fit_fiml, medidas))
# Mismas medidas de ajuste (chi2 = 246.604, 86 gl) y las mismas estimaciones:
max(abs(coef(fit_ml) - coef(fit_fiml)[names(coef(fit_ml))]))    # ~1e-15

# -----------------------------------------------------------------------
# Paso 3. Un ejemplo: quitar datos y ver qué pasa
# -----------------------------------------------------------------------
# Dos mecanismos de faltantes:
#  MCAR (completamente al azar): cada respuesta de los 15 ítems se pierde con
#   probabilidad de 5%, sin relación con nada.
#  MAR (al azar, dado lo observado): los 12 ítems de HR, SA y AS se pierden
#   con más probabilidad cuando la persona puntúa ALTO en Influencia
#   interpersonal (II16-II18, siempre observados). Promedio de faltantes: 7%.
#   Es el caso que sesga el listwise y que FIML corrige, porque FIML usa II.
faltantes_mcar <- function(d, p = .05) {
  for (v in items) d[[v]][runif(nrow(d)) < p] <- NA
  d
}
faltantes_mar <- function(d) {
  z <- as.numeric(scale(rowMeans(d[, c("II16", "II17", "II18")])))
  for (v in setdiff(items, c("II16", "II17", "II18")))
    d[[v]][runif(nrow(d)) < plogis(-2.7 + 1.0 * z)] <- NA
  d
}

set.seed(2026)
d_mcar <- faltantes_mcar(hp)
d_mar  <- faltantes_mar(hp)
# Casos completos y porcentaje de datos perdidos
rbind(MCAR = c(completos = sum(complete.cases(d_mcar[, items])),
               pct_faltante = 100 * mean(is.na(d_mcar[, items]))),
      MAR  = c(completos = sum(complete.cases(d_mar[, items])),
               pct_faltante = 100 * mean(is.na(d_mar[, items]))))
# Con 5% de respuestas perdidas (MCAR), el listwise tira el 54% de la muestra
# (se queda con 163); con MAR (7% perdido) se queda con 151 (42%).

# Patrones de faltantes (1 = falta) con MAR
sort(table(apply(is.na(d_mar[, items]) * 1, 1, paste, collapse = "")), decreasing = TRUE)[1:5]

# Un ajuste con cada método. Cargas estandarizadas de segundo orden:
cargas_HP <- function(fit) {
  s <- standardizedSolution(fit)
  s <- s[s$lhs == "HP" & s$op == "=~", ]
  setNames(s$est.std, s$rhs)
}
ilustracion <- function(d) {
  l <- cfa(modelo, data = d, missing = "listwise")
  f <- cfa(modelo, data = d, missing = "fiml")
  rbind(listwise = c(N = lavInspect(l, "nobs"), cargas_HP(l)),
        FIML     = c(N = lavInspect(f, "nobs"), cargas_HP(f)))
}
tabla_ilustrada <- rbind(completo = c(N = 356, cargas_HP(fit_ml)),
                         MCAR_listwise = ilustracion(d_mcar)["listwise", ],
                         MCAR_FIML     = ilustracion(d_mcar)["FIML", ],
                         MAR_listwise  = ilustracion(d_mar)["listwise", ],
                         MAR_FIML      = ilustracion(d_mar)["FIML", ])
round(tabla_ilustrada, 3)
# En este conjunto de datos, con MAR el listwise subestima las cargas de II
# (.720 contra .805 completo) y de HR (.763 contra .824) en HP, y el FIML queda
# casi igual que el completo (.797 y .837). Con MCAR ninguno está sesgado de
# forma sistemática (el listwise solo es más ruidoso: AS .982 contra .949).
# Un solo conjunto no basta: el paso 4 lo repite 200 veces.

# -----------------------------------------------------------------------
# Paso 4. Repetir 200 veces: sesgo, error y errores estándar
# -----------------------------------------------------------------------
# La "verdad" es la solución con los 356 casos completos. Para cada réplica
# se quitan datos y se ajusta con listwise y con FIML; se guardan las 19
# cargas estandarizadas (15 de primer orden y 4 de segundo), sus errores
# estándar y si la solución es admisible (convergió y sin varianzas
# negativas).
cargas_std <- function(fit) {
  s <- standardizedSolution(fit)
  s <- s[s$op == "=~", ]
  data.frame(par = paste(s$lhs, s$rhs), est = s$est.std, ee = s$se)
}
referencia <- cargas_std(fit_ml)

una_replica <- function(d, metodo) {
  fit <- tryCatch(suppressWarnings(
    cfa(modelo, data = d, missing = if (metodo == "FIML") "fiml" else "listwise")),
    error = function(e) NULL)
  if (is.null(fit) || !lavInspect(fit, "converged"))
    return(data.frame(par = referencia$par, est = NA, ee = NA, n = NA, admisible = FALSE))
  r <- cargas_std(fit)
  r$n <- lavInspect(fit, "nobs")
  r$admisible <- suppressWarnings(lavInspect(fit, "post.check"))
  r
}

n_rep <- 200
set.seed(2026)
resultados <- list()
for (mecanismo in c("MCAR", "MAR")) {
  for (i in seq_len(n_rep)) {
    d <- if (mecanismo == "MCAR") faltantes_mcar(hp) else faltantes_mar(hp)
    for (metodo in c("listwise", "FIML")) {
      r <- una_replica(d, metodo)
      resultados[[length(resultados) + 1]] <- cbind(mecanismo = mecanismo, metodo = metodo,
                                                    rep = i, r)
    }
  }
}
resultados <- do.call(rbind, resultados)
resultados <- merge(resultados, setNames(referencia[, 1:2], c("par", "est_completo")), by = "par")
resultados$sesgo <- resultados$est - resultados$est_completo

# Resumen por mecanismo y método
resumen <- do.call(rbind, lapply(split(resultados, list(resultados$mecanismo, resultados$metodo)),
  function(r) {
    data.frame(mecanismo = r$mecanismo[1], metodo = r$metodo[1],
               casos_medios = mean(r$n[!duplicated(r$rep)], na.rm = TRUE),
               pct_admisible = 100 * mean(r$admisible[!duplicated(r$rep)]),
               sesgo_medio = mean(r$sesgo, na.rm = TRUE),
               sesgo_abs_medio = mean(abs(r$sesgo), na.rm = TRUE),
               RMSE = sqrt(mean(r$sesgo^2, na.rm = TRUE)),
               ee_media = mean(r$ee, na.rm = TRUE))
  }))
rownames(resumen) <- NULL
resumen[, -(1:2)] <- round(resumen[, -(1:2)], 3)
resumen
# MCAR: ninguno tiene sesgo, pero el listwise usa 165 casos de 356 (46%), su
# error (RMSE .044) es 4 veces el de FIML (.011) y sus errores estándar 40%
# mayores (.046 contra .033); y en 18% de las réplicas la solución es
# inadmisible (0% con FIML).
# MAR: el listwise tiene sesgo (-.04 en las cargas de HR, AS e II sobre HP;
# RMSE .054) y 23% de soluciones inadmisibles; FIML no tiene sesgo (<= .005).

# Sesgo medio por carga de segundo orden (HR, SA, AS, II sobre HP). Con MAR el
# listwise subestima .04 a .05 tres de las cuatro (sobrestima SA, +.04).
sesgo_HP <- aggregate(sesgo ~ mecanismo + metodo + par, data = resultados[grepl("^HP", resultados$par), ],
                      FUN = mean)
sesgo_HP$sesgo <- round(sesgo_HP$sesgo, 3)
reshape(sesgo_HP, idvar = c("mecanismo", "metodo"), timevar = "par", direction = "wide")

write.csv(resumen, file.path(dir_salida, "resumen_simulacion.csv"), row.names = FALSE)
write.csv(round(tabla_ilustrada, 3), file.path(dir_salida, "ejemplo_un_conjunto.csv"))
write.csv(sesgo_HP, file.path(dir_salida, "sesgo_cargas_segundo_orden.csv"), row.names = FALSE)
