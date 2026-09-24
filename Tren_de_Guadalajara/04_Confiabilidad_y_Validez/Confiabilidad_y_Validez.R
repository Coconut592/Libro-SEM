# =============================================================================
# Libro SEM · Tren de Guadalajara
# 04 - Confiabilidad y validez
# =============================================================================
# Referencias: SEM06_Confiabilidad_y_Validez.pdf (alfa de Cronbach manual y
# por ítem, confiabilidad compuesta de Dillon-Goldstein, KR-20 y tipos de
# validez), AFE_CFA.R (alfa con la covarianza del modelo y confiabilidad
# compuesta) y SEM02_Ejemplo_AFE-AFC.pdf (alfas .82, .87 y .83).
#
# El PDF presenta la validez de forma conceptual (contenido, criterio y
# constructo), sin cálculos. La AVE y el criterio de Fornell-Larcker (paso
# 10) NO vienen en las referencias: se agregan como apoyo cuantitativo a la
# validez de constructo.
#   source("Tren_de_Guadalajara/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Tren_de_Guadalajara/04_Confiabilidad_y_Validez/output"

# -----------------------------------------------------------------------
# Paso 1. Datos, factores y AFC
# -----------------------------------------------------------------------
# - Alfa de Cronbach: los 306 usuarios con covarianzas por pares, igual que
#   el comando alpha de Stata del PDF ("obs=pairwise").
# - Confiabilidad compuesta y validez: el AFC de 02_AFC (170 completos).
tren_completo <- read.dta13("Tren_de_Guadalajara/data/imsctren2006.dta")
tren <- tren_completo[complete.cases(tren_completo), ]
tren_reducido <- tren[, -c(1, 9, 13)]

factores <- list(Acceso  = c("p4", "p5", "p61", "p62"),
                 Tarjeta = c("p63", "p64"),
                 Confort = c("p71", "p73", "p74", "p75"))

modelo <- 'Acceso  =~ p4 + p5 + p61 + p62
           Tarjeta =~ p63 + p64
           Confort =~ p71 + p73 + p74 + p75'
fit <- sem(modelo, data = tren_reducido, estimator = "ML")

# =======================================================================
# CONFIABILIDAD
# =======================================================================

# -----------------------------------------------------------------------
# Paso 2. Alfa de Cronbach "a mano" con la matriz de covarianzas
# -----------------------------------------------------------------------
#   alfa = k / (k - 1) * (1 - suma de varianzas / suma de TODOS los elementos)
# La diagonal tiene las varianzas; fuera de ella, las covarianzas.
alfa_manual <- function(items) {
  S <- cov(tren_completo[, items], use = "pairwise.complete.obs")
  k <- length(items)
  c(k = k,
    suma_varianzas   = sum(diag(S)),
    suma_covarianzas = sum(S) - sum(diag(S)),
    alfa = k / (k - 1) * (1 - sum(diag(S)) / sum(S)))
}
round(cov(tren_completo[, factores$Acceso], use = "pairwise.complete.obs"), 3)
round(t(sapply(factores, alfa_manual)), 3)
# Criterio: alfa > 0.70 es deseable (Nunnally y Bernstein, 1994)

# -----------------------------------------------------------------------
# Paso 3. Alfa con estadísticas por ítem (equivale a "alpha ..., d item")
# -----------------------------------------------------------------------
# raw.r = correlación ítem-test; r.drop = correlación ítem-resto;
# raw_alpha en alpha.drop = alfa si se elimina el ítem. Si el alfa sube al
# quitar un ítem, ese ítem resta consistencia a la escala.
por_item <- lapply(names(factores), function(f) {
  a <- alpha(tren_completo[, factores[[f]]], warnings = FALSE)
  data.frame(factor = f, item = factores[[f]],
             n = a$item.stats$n,
             item_test = a$item.stats$raw.r,
             item_resto = a$item.stats$r.drop,
             alfa_sin_item = a$alpha.drop$raw_alpha,
             alfa_escala = a$total$raw_alpha)
})
por_item <- do.call(rbind, por_item)
por_item[, 4:7] <- round(por_item[, 4:7], 3)
por_item
write.csv(por_item, file.path(dir_salida, "alfa_por_item.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Alfa con la covarianza ajustada por el modelo (AFE_CFA.R)
# -----------------------------------------------------------------------
# fitted(fit)$cov es la matriz de covarianzas que reproduce el AFC.
covariance <- as.matrix(fitted(fit)$cov)
alfa_modelo <- sapply(factores, function(items)
  alpha(covariance[items, items])$total$raw_alpha)
round(alfa_modelo, 3)

# -----------------------------------------------------------------------
# Paso 5. Confiabilidad compuesta (omega de Dillon-Goldstein)
# -----------------------------------------------------------------------
#   CC = (suma lambda)^2 / [(suma lambda)^2 + suma var(e)],  var(e) = 1 - lambda^2
# con lambda = cargas estandarizadas. Se arma la tabla como en el PDF.
stdsol <- standardizedSolution(fit)
tabla_cc <- stdsol[stdsol$op == "=~", c("lhs", "rhs", "est.std")]
names(tabla_cc) <- c("factor", "item", "coeficiente")
tabla_cc$residual <- 1 - tabla_cc$coeficiente^2
tabla_cc[, 3:4] <- round(tabla_cc[, 3:4], 3)
tabla_cc

conf_compuesta <- sapply(names(factores), function(f) {
  l <- tabla_cc$coeficiente[tabla_cc$factor == f]
  e <- tabla_cc$residual[tabla_cc$factor == f]
  sum(l)^2 / (sum(l)^2 + sum(e))
})
round(conf_compuesta, 3)
write.csv(tabla_cc, file.path(dir_salida, "confiabilidad_compuesta.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. KR-20: no aplica
# -----------------------------------------------------------------------
# KR-20 es la consistencia interna para ítems dicotómicos (0/1). Aquí los
# ítems son escalas de 1 a 10, así que la medida correcta es el alfa.
sapply(tren_completo[, unlist(factores)], function(x) length(unique(na.omit(x))))

# =======================================================================
# VALIDEZ
# =======================================================================

# -----------------------------------------------------------------------
# Paso 7. Validez de contenido (cualitativa)
# -----------------------------------------------------------------------
# No se calcula: se argumenta revisando que cada ítem pertenezca al dominio
# de su factor (ver el glosario del README del proyecto). Por ejemplo, los
# ítems de Confort cubren seguridad (p71, p73) y comodidad (p74, p75).

# -----------------------------------------------------------------------
# Paso 8. Validez de criterio: no es posible con esta base
# -----------------------------------------------------------------------
# Requiere un criterio externo que mida lo mismo (otro instrumento de
# satisfacción, una calificación global del servicio, uso posterior del
# tren...). El .dta no trae ninguno: p72 y p8 son otros aspectos del
# servicio, no una medida externa de la satisfacción.

# -----------------------------------------------------------------------
# Paso 9. Validez de constructo: teoría + correlaciones + interpretación
# -----------------------------------------------------------------------
# A. Teoría: tres dimensiones de la calidad del servicio (Palacios y
#    Vargas, 2009): Acceso, Tarjeta y Confort.
# B. Correlaciones: los ítems de un mismo factor deben correlacionar más
#    entre sí que con los ítems de otros factores.
R <- cor(tren_completo[, unlist(factores)], use = "pairwise.complete.obs")
round(R, 2)
correlaciones <- data.frame(
  factor = names(factores),
  r_media_dentro = sapply(factores, function(i) {
    r <- R[i, i]; mean(r[upper.tri(r)]) }),                  # entre ítems del factor
  r_media_fuera  = sapply(factores, function(i)
    mean(R[i, setdiff(colnames(R), i)])))                     # con ítems de otros factores
correlaciones[, 2:3] <- round(correlaciones[, 2:3], 3)
correlaciones
# C. Interpretación empírica: el AFE (01_AFE) recupera los tres factores y
#    el AFC (02_AFC) confirma cargas >= .64, todas significativas.

# -----------------------------------------------------------------------
# Paso 10. Complemento (no viene en las referencias): AVE y Fornell-Larcker
# -----------------------------------------------------------------------
# Convergente: AVE = promedio de lambda^2 >= 0.50.
# Discriminante: raíz de AVE > correlación con los demás factores.
ave <- sapply(names(factores), function(f)
  mean(tabla_cc$coeficiente[tabla_cc$factor == f]^2))
phi <- lavInspect(fit, "std")$psi          # correlaciones entre factores
fornell_larcker <- phi
diag(fornell_larcker) <- sqrt(ave[colnames(phi)])
round(fornell_larcker, 3)                  # diagonal = raíz de AVE

# -----------------------------------------------------------------------
# Paso 11. Tabla resumen
# -----------------------------------------------------------------------
resumen <- data.frame(factor = names(factores),
                      n_items = lengths(factores),
                      alfa = sapply(factores, function(i) alfa_manual(i)["alfa"]),
                      alfa_modelo = alfa_modelo,
                      conf_compuesta = conf_compuesta,
                      AVE = ave,
                      raiz_AVE = sqrt(ave),
                      max_correlacion = apply(abs(phi - diag(diag(phi))), 1, max)[names(factores)])
resumen[, -(1:2)] <- round(resumen[, -(1:2)], 3)
resumen
write.csv(resumen, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)
