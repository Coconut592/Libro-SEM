# =============================================================================
# Libro SEM · Habilidades Políticas
# 04 - Confiabilidad y validez
# =============================================================================
# Referencias: capítulo (alfa de Cronbach reportada por Ferris, .90; tipos de
# validez según Nunnally, 1987; validez de constructo con el AFC) y
# presentación (lámina 16: "alpha AS11-AS14, d item" en Stata). El capítulo
# no calcula la confiabilidad compuesta, el AVE, la validez discriminante ni
# la confiabilidad del factor de segundo orden: se agregan siguiendo el
# esquema del proyecto del Tren y de Violencia Guerrero.
#   source("Habilidades_Politicas/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Habilidades_Politicas/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, factores y AFC
# -----------------------------------------------------------------------
hp <- read.dta13("Habilidades_Politicas/data/Cap6_AFC_2orden.dta")
factores <- list(HR = c("HR1", "HR2", "HR3", "HR4", "HR6"),
                 SA = c("SA7", "SA8", "SA9"),
                 AS = c("AS10", "AS11", "AS13", "AS14"),
                 II = c("II16", "II17", "II18"))
items <- unlist(factores)
hp <- hp[, c("Genero", items)]

modelo_1er <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
modelo_2do <- paste(modelo_1er, 'HP =~ HR + SA + AS + II', sep = "\n")
fit_1er <- cfa(modelo_1er, data = hp, estimator = "ML")
fit_2do <- cfa(modelo_2do, data = hp, estimator = "ML")

# =======================================================================
# CONFIABILIDAD
# =======================================================================

# -----------------------------------------------------------------------
# Paso 2. Alfa de Cronbach "a mano" con la matriz de covarianzas
# -----------------------------------------------------------------------
#   alfa = k / (k - 1) * (1 - suma de varianzas / suma de TODOS los elementos)
alfa_manual <- function(vars) {
  S <- cov(hp[, vars])
  k <- length(vars)
  c(k = k,
    suma_varianzas   = sum(diag(S)),
    suma_covarianzas = sum(S) - sum(diag(S)),
    alfa = k / (k - 1) * (1 - sum(diag(S)) / sum(S)))
}
round(cov(hp[, factores$HR]), 3)
round(t(sapply(factores, alfa_manual)), 3)
alfa_manual(items)["alfa"]      # los 15 ítems: .911
# Alfas: HR .83, SA .74, AS .76 e II .82. Criterio: alfa > .70 es deseable
# (Nunnally y Bernstein, 1994). Ferris et al. (2005) reportan .90 para el
# PSI de 18 ítems (lo cita el capítulo): con los 15 ítems sale .91.

# -----------------------------------------------------------------------
# Paso 3. Alfa con estadísticas por ítem (equivale a "alpha ..., d item")
# -----------------------------------------------------------------------
# item_resto = correlación del ítem con el resto de su escala; alfa_sin_item
# = alfa si se elimina. Si el alfa sube al quitar un ítem, ese ítem resta.
por_item <- lapply(names(factores), function(f) {
  a <- alpha(hp[, factores[[f]]], warnings = FALSE)
  data.frame(factor = f, item = factores[[f]],
             item_test = a$item.stats$raw.r,
             item_resto = a$item.stats$r.drop,
             alfa_sin_item = a$alpha.drop$raw_alpha,
             alfa_escala = a$total$raw_alpha)
})
por_item <- do.call(rbind, por_item)
por_item[, 3:6] <- round(por_item[, 3:6], 3)
por_item
# Ningún ítem mejora la escala al quitarlo; la correlación ítem-resto va
# de .50 (SA9) a .70 (II18).
write.csv(por_item, file.path(dir_salida, "alfa_por_item.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Confiabilidad compuesta (omega de Dillon-Goldstein)
# -----------------------------------------------------------------------
#   CC = (suma lambda)^2 / [(suma lambda)^2 + suma var(e)],  var(e) = 1 - lambda^2
# con lambda = cargas estandarizadas del AFC de primer orden.
std <- standardizedSolution(fit_1er)
tabla_cc <- std[std$op == "=~", c("lhs", "rhs", "est.std")]
names(tabla_cc) <- c("factor", "item", "coeficiente")
tabla_cc$residual <- 1 - tabla_cc$coeficiente^2

conf_compuesta <- sapply(names(factores), function(f) {
  l <- tabla_cc$coeficiente[tabla_cc$factor == f]
  e <- tabla_cc$residual[tabla_cc$factor == f]
  sum(l)^2 / (sum(l)^2 + sum(e))
})
round(conf_compuesta, 3)    # HR .83, SA .74, AS .76, II .82 (casi igual que el alfa)
tabla_cc[, 3:4] <- round(tabla_cc[, 3:4], 3)
write.csv(tabla_cc, file.path(dir_salida, "confiabilidad_compuesta.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Confiabilidad del factor general (segundo orden)
# -----------------------------------------------------------------------
# a) Confiabilidad compuesta de HP a partir de las cargas de segundo orden
std2 <- standardizedSolution(fit_2do)
gamma <- setNames(std2$est.std[std2$lhs == "HP" & std2$op == "=~"],
                  std2$rhs[std2$lhs == "HP" & std2$op == "=~"])
cc_HP <- sum(gamma)^2 / (sum(gamma)^2 + sum(1 - gamma^2))
cc_HP                          # .932

# b) Omega total y omega jerárquico de la escala de 15 ítems. Cada ítem tiene
#    una parte debida a HP (carga del ítem x carga de su dimensión), otra
#    propia de su dimensión y un error.
#      omega total  = proporción de la varianza del total debida a todos los factores
#      omega jerárq = proporción debida SOLO a HP (factor general)
lambda <- setNames(std2$est.std[std2$op == "=~" & std2$rhs %in% items],
                   std2$rhs[std2$op == "=~" & std2$rhs %in% items])
dimension <- setNames(std2$lhs[std2$op == "=~" & std2$rhs %in% items],
                      std2$rhs[std2$op == "=~" & std2$rhs %in% items])
lambda <- lambda[items]; dimension <- dimension[items]
Sigma <- lavInspect(fit_2do, "implied")$cov
Sigma <- cov2cor(Sigma)[items, items]                     # correlaciones implicadas por el modelo
var_total <- sum(Sigma)
carga_HP <- lambda * gamma[dimension]
omega_total <- 1 - sum(1 - lambda^2) / var_total
omega_jerarquico <- sum(carga_HP)^2 / var_total
round(c(omega_total = omega_total, omega_jerarquico = omega_jerarquico,
        proporcion_por_HP = omega_jerarquico / omega_total), 3)
# La escala total es muy confiable (omega total .93) y el 92% de esa
# confiabilidad se debe al factor general (omega jerárquico .85): sumar los
# 15 ítems mide sobre todo HP, y lo que las dimensiones agregan es poco.

# -----------------------------------------------------------------------
# Paso 6. Alfa con la covarianza ajustada por el modelo
# -----------------------------------------------------------------------
covarianza <- as.matrix(fitted(fit_1er)$cov)
alfa_modelo <- sapply(factores, function(v) alpha(covarianza[v, v])$total$raw_alpha)
round(alfa_modelo, 3)

# -----------------------------------------------------------------------
# Paso 7. KR-20: no aplica
# -----------------------------------------------------------------------
# KR-20 es para ítems dicotómicos (0/1). Aquí son escalas de 1 a 7.
sapply(hp[, items], function(x) length(unique(x)))

# =======================================================================
# VALIDEZ
# =======================================================================

# -----------------------------------------------------------------------
# Paso 8. Validez de contenido (cualitativa)
# -----------------------------------------------------------------------
# No se calcula: se argumenta. Los 15 ítems son una versión recortada del
# PSI de 18 (se quitaron HR5, AS12 e II15), y cada dimensión conserva ítems
# que cubren su definición (ver el glosario del README). El
# capítulo describe la traducción: dos traducciones independientes y revisión
# de una especialista en psicología.

# -----------------------------------------------------------------------
# Paso 9. Validez de criterio: no es posible con esta base
# -----------------------------------------------------------------------
# Requiere un criterio externo que mida lo mismo o algo predicho por el
# constructo (desempeño, ascensos, otro instrumento de efectividad social).
# La base solo trae el género y los 15 ítems.

# -----------------------------------------------------------------------
# Paso 10. Validez de constructo: teoría + correlaciones + AFC
# -----------------------------------------------------------------------
# A. Teoría: cuatro dimensiones de la habilidad política (Ferris et al., 2005).
# B. Correlaciones: los ítems de una dimensión deben correlacionar más entre
#    sí que con los de otras dimensiones.
R <- cor(hp[, items])
round(R, 2)
correlaciones <- data.frame(
  factor = names(factores),
  r_media_dentro = sapply(factores, function(i) { r <- R[i, i]; mean(r[upper.tri(r)]) }),
  r_media_fuera  = sapply(factores, function(i) mean(R[i, setdiff(colnames(R), i)])))
correlaciones[, 2:3] <- round(correlaciones[, 2:3], 3)
correlaciones
# Dentro: .44 a .60; fuera: .37 a .40. La diferencia va de .05 (AS) a .22
# (II): hay estructura, pero es pequeña salvo en II y HR, porque los ítems
# de dimensiones distintas están bastante correlacionados entre sí.

# -----------------------------------------------------------------------
# Paso 11. Validez convergente: AVE
# -----------------------------------------------------------------------
# AVE = promedio de lambda^2 (varianza que el factor extrae de sus ítems);
# se pide >= .50. Fornell y Larcker (1981): con AVE < .50 pero confiabilidad
# compuesta > .60 la validez convergente todavía es aceptable.
ave <- sapply(names(factores), function(f)
  mean(tabla_cc$coeficiente[tabla_cc$factor == f]^2))
round(ave, 3)
# HR .50 y II .61 cumplen; SA (.49) queda al límite y AS (.44) por debajo de
# .50. Con confiabilidad compuesta de .74 a .83 (todas > .60) la validez
# convergente es aceptable por el criterio de Fornell y Larcker.

# -----------------------------------------------------------------------
# Paso 12. Validez discriminante
# -----------------------------------------------------------------------
# a) Fornell-Larcker: la raíz del AVE de cada factor debe ser MAYOR que sus
#    correlaciones con los demás factores.
phi <- lavInspect(fit_1er, "cor.lv")
fornell_larcker <- phi
diag(fornell_larcker) <- sqrt(ave[colnames(phi)])
round(fornell_larcker, 3)       # diagonal = raíz de AVE
# Se cumple en UN solo par de seis: HR-II (.66, por debajo de las raíces .71
# y .78). Fallan SA-AS (.89 contra raíces de .70 y .66), HR-SA, HR-AS, SA-II
# y AS-II.

# b) HTMT (Henseler et al., 2015): razón de correlaciones entre ítems de
#    distintos factores y dentro de cada factor. Se pide < .85 (o < .90).
htmt <- function(R, factores) {
  nf <- names(factores)
  res <- matrix(NA, length(nf), length(nf), dimnames = list(nf, nf))
  mono <- sapply(factores, function(v) { r <- R[v, v]; mean(r[upper.tri(r)]) })
  for (i in nf) for (j in nf) if (i != j) {
    hetero <- mean(R[factores[[i]], factores[[j]]])
    res[i, j] <- hetero / sqrt(mono[i] * mono[j])
  }
  res
}
round(htmt(R, factores), 3)
# HTMT de .67 a .90. Solo SA-AS pasa de .85 (.90, en el límite de .90); los
# demás pares quedan por debajo de .80.

# c) Prueba de chi-cuadrada (Anderson y Gerbing): se fija la correlación de
#    cada par de factores en 1 y se compara con el modelo libre. Si el
#    ajuste empeora de forma significativa, los factores son distintos.
modelo_std <- '
  HR =~ HR1 + HR2 + HR3 + HR4 + HR6
  SA =~ SA7 + SA8 + SA9
  AS =~ AS10 + AS11 + AS13 + AS14
  II =~ II16 + II17 + II18'
libre <- cfa(modelo_std, data = hp, std.lv = TRUE)
pares <- combn(names(factores), 2, simplify = FALSE)
# (lavaan avisa que la matriz de los factores no es definida positiva: es
# lo esperado con una correlación fijada en 1; el aviso se silencia.)
prueba_pares <- t(sapply(pares, function(p) {
  restringido <- suppressWarnings(
    cfa(paste(modelo_std, paste0(p[1], " ~~ 1*", p[2]), sep = "\n"),
        data = hp, std.lv = TRUE))
  d <- lavTestLRT(libre, restringido)
  c(correlacion = unname(phi[p[1], p[2]]), delta_chi2 = d$`Chisq diff`[2],
    p = d$`Pr(>Chisq)`[2])
}))
rownames(prueba_pares) <- sapply(pares, paste, collapse = "-")
round(prueba_pares, 4)
# Los 6 pares son significativamente distintos de 1 (Delta chi2 de 12 a 161,
# p < .001): estadísticamente SON factores distintos, aunque SA-AS (.885)
# es el par más cercano (Delta chi2 = 12.3, el menor).

# Conclusión de la validez de constructo: la estructura de cuatro dimensiones
# se confirma (02_AFC) y las dimensiones son estadísticamente distintas (prueba
# de chi2), pero el criterio de Fornell-Larcker falla en 5 de 6 pares y SA-AS
# roza el límite del HTMT: la validez discriminante es débil, y un factor
# general (HP) es la lectura natural (03_AFC_2do_Orden).

# -----------------------------------------------------------------------
# Paso 13. Tabla resumen
# -----------------------------------------------------------------------
resumen <- data.frame(factor = names(factores),
                      n_items = lengths(factores),
                      alfa = sapply(factores, function(i) alfa_manual(i)["alfa"]),
                      alfa_modelo = alfa_modelo,
                      conf_compuesta = conf_compuesta,
                      AVE = ave,
                      raiz_AVE = sqrt(ave),
                      max_correlacion = apply(abs(phi - diag(diag(phi))), 1, max)[names(factores)],
                      max_HTMT = apply(htmt(R, factores), 1, max, na.rm = TRUE)[names(factores)])
resumen[, -(1:2)] <- round(resumen[, -(1:2)], 3)
resumen
write.csv(resumen, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)
write.csv(round(htmt(R, factores), 3), file.path(dir_salida, "HTMT.csv"))
write.csv(round(fornell_larcker, 3), file.path(dir_salida, "fornell_larcker.csv"))
write.csv(round(prueba_pares, 4), file.path(dir_salida, "prueba_chi2_discriminante.csv"))
