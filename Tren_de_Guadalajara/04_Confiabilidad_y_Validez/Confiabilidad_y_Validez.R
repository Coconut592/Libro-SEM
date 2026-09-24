# =============================================================================
# Libro SEM · Tren de Guadalajara
# 04 - Confiabilidad y validez
# =============================================================================
# Referencias: AFE_CFA.R (alfa de Cronbach y confiabilidad compuesta de
# Dillon-Goldstein) y SEM02_Ejemplo_AFE-AFC.pdf (alfas .82, .87 y .83).
# La VALIDEZ (AVE y Fornell-Larcker) no viene en las referencias: se agrega
# con los criterios de Fornell y Larcker (1981).
#   source("Tren_de_Guadalajara/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Tren_de_Guadalajara/04_Confiabilidad_y_Validez/output"

# -----------------------------------------------------------------------
# Paso 1. Datos y AFC (el mismo de 02_AFC)
# -----------------------------------------------------------------------
tren_completo <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
tren <- tren_completo[complete.cases(tren_completo), ]
tren_reducido <- tren[, -c(1, 9, 13)]

modelo <- 'Acceso  =~ p4 + p5 + p61 + p62
           Tarjeta =~ p63 + p64
           Confort =~ p71 + p73 + p74 + p75'
fit <- sem(modelo, data = tren_reducido, estimator = "ML")

factores <- list(Acceso  = c("p4", "p5", "p61", "p62"),
                 Tarjeta = c("p63", "p64"),
                 Confort = c("p71", "p73", "p74", "p75"))

# -----------------------------------------------------------------------
# Paso 2. Alfa de Cronbach con la covarianza ajustada por el modelo
# -----------------------------------------------------------------------
# Como en la referencia: fitted(fit)$cov es la matriz de covarianzas que
# reproduce el modelo; alpha() de psych acepta una matriz de covarianzas.
covariance <- as.matrix(fitted(fit)$cov)
alfa_modelo <- sapply(factores, function(items)
  alpha(covariance[items, items])$total$raw_alpha)
round(alfa_modelo, 3)

# Alfa con los datos observados. Con todos los casos disponibles
# (306, faltantes por pares) se obtienen los valores del PDF (.82, .87, .83)
alfa_datos <- sapply(factores, function(items)
  alpha(tren_completo[, items])$total$raw_alpha)
round(alfa_datos, 3)

# -----------------------------------------------------------------------
# Paso 3. Confiabilidad compuesta de Dillon-Goldstein (rho de Jöreskog)
# -----------------------------------------------------------------------
#   CC = (suma de cargas std)^2 / [(suma de cargas std)^2 + suma(1 - carga^2)]
stdsol <- standardizedSolution(fit)
cargas <- stdsol[stdsol$op == "=~", c("lhs", "rhs", "est.std")]
cargas

conf_compuesta <- sapply(names(factores), function(f) {
  l <- cargas$est.std[cargas$lhs == f]
  residuales <- 1 - l^2
  sum(l)^2 / (sum(l)^2 + sum(residuales))
})
round(conf_compuesta, 3)

# -----------------------------------------------------------------------
# Paso 4. Validez convergente: Varianza Media Extraída (AVE)
# -----------------------------------------------------------------------
#   AVE = promedio de las cargas estandarizadas al cuadrado.
# Criterio: AVE >= 0.50 (el factor explica al menos la mitad de la
# varianza de sus ítems) y cargas >= 0.50 y significativas.
ave <- sapply(names(factores), function(f)
  mean(cargas$est.std[cargas$lhs == f]^2))
round(ave, 3)

# -----------------------------------------------------------------------
# Paso 5. Validez discriminante: criterio de Fornell-Larcker
# -----------------------------------------------------------------------
# La raíz de la AVE de cada factor debe ser mayor que sus correlaciones
# con los demás factores (cada factor comparte más varianza con sus ítems
# que con otro factor).
phi <- lavInspect(fit, "std")$psi           # correlaciones entre factores
fornell_larcker <- phi
diag(fornell_larcker) <- sqrt(ave[colnames(phi)])
round(fornell_larcker, 3)                   # diagonal = raíz de AVE

# -----------------------------------------------------------------------
# Paso 6. Tabla resumen
# -----------------------------------------------------------------------
resumen <- data.frame(factor = names(factores),
                      n_items = lengths(factores),
                      alfa_datos = alfa_datos,
                      alfa_modelo = alfa_modelo,
                      conf_compuesta = conf_compuesta,
                      AVE = ave,
                      raiz_AVE = sqrt(ave),
                      max_correlacion = apply(abs(phi - diag(diag(phi))), 1, max)[names(factores)])
resumen[, -(1:2)] <- round(resumen[, -(1:2)], 3)
resumen
write.csv(resumen, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)
