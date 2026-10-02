# =============================================================================
# Libro SEM · Violencia Guerrero
# 04 - Confiabilidad y validez
# =============================================================================
# Sin referencia propia. Se sigue el mismo esquema que en el Tren (SEM06):
# alfa de Cronbach a mano y por ítem, alfa con la covarianza del modelo,
# confiabilidad compuesta de Dillon-Goldstein, KR-20 y los tipos de validez
# (contenido, criterio y constructo). Complementos que en el Tren no se
# usaron: razón HTMT, validez nomológica y la confiabilidad del factor de
# segundo orden G.
#   source("Violencia_Guerrero/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Violencia_Guerrero/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, factores y AFC
# -----------------------------------------------------------------------
# - Alfa de Cronbach: las 294 personas con covarianzas por pares, igual que
#   el comando alpha de Stata ("obs = pairwise").
# - Confiabilidad compuesta y validez: el AFC de 12 factores de 02_AFC
#   (MLR + FIML, 294 personas).
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")

factores <- list(
  pareja      = c("a1", "a2", "a3", "a4"),
  familia     = c("a5", "a6", "a7", "a8"),
  economia    = c("a9", "a10", "a11", "a12"),
  social      = c("a13", "a14", "a15", "a16"),
  personal    = c("a17", "a18", "a19", "a20"),
  trabajo     = c("a21", "a22", "a23", "a24"),
  cohesion    = c("b1", "b2", "b3", "b4", "b9"),
  confianza   = c("b10", "b11", "b12", "b13"),
  inseguridad = c("c4", "c5", "c6", "c7", "c8"),
  riesgo      = c("c11", "c12", "c13"),
  libertad    = c("c19", "c20"),
  desempeno   = c("f2", "f3", "f4"))
items <- unlist(factores)

modelo <- '
  pareja      =~ a1 + a2 + a3 + a4
  familia     =~ a5 + a6 + a7 + a8
  economia    =~ a9 + a10 + a11 + a12
  social      =~ a13 + a14 + a15 + a16
  personal    =~ a17 + a18 + a19 + a20
  trabajo     =~ a21 + a22 + a23 + a24
  cohesion    =~ b1 + b2 + b3 + b4 + b9
  confianza   =~ b10 + b11 + b12 + b13
  inseguridad =~ c4 + c5 + c6 + c7 + c8
  riesgo      =~ c11 + c12 + c13
  libertad    =~ c19 + c20
  desempeno   =~ f2 + f3 + f4'
fit <- cfa(modelo, data = guerrero, estimator = "MLR", missing = "fiml")   # ~1 minuto

# =======================================================================
# CONFIABILIDAD
# =======================================================================

# -----------------------------------------------------------------------
# Paso 2. Alfa de Cronbach "a mano" con la matriz de covarianzas
# -----------------------------------------------------------------------
#   alfa = k / (k - 1) * (1 - suma de varianzas / suma de TODOS los elementos)
# La diagonal tiene las varianzas; fuera de ella, las covarianzas.
alfa_manual <- function(items) {
  S <- cov(guerrero[, items], use = "pairwise.complete.obs")
  k <- length(items)
  c(k = k,
    suma_varianzas   = sum(diag(S)),
    suma_covarianzas = sum(S) - sum(diag(S)),
    alfa = k / (k - 1) * (1 - sum(diag(S)) / sum(S)))
}
round(cov(guerrero[, factores$pareja], use = "pairwise.complete.obs"), 3)
tabla_alfa <- round(t(sapply(factores, alfa_manual)), 3)
tabla_alfa
# Criterio: alfa > 0.70 es deseable (Nunnally y Bernstein, 1994). Con solo 2
# ítems (libertad) el alfa equivale a la fórmula de Spearman-Brown.

# -----------------------------------------------------------------------
# Paso 3. Alfa con estadísticas por ítem (equivale a "alpha ..., d item")
# -----------------------------------------------------------------------
# raw.r = correlación ítem-test; r.drop = correlación ítem-resto;
# raw_alpha en alpha.drop = alfa si se elimina el ítem. Si el alfa sube al
# quitar un ítem, ese ítem resta consistencia a la escala. Con 2 ítems no
# se calcula (quedaría uno solo). max = 11: las escalas tienen 10 valores y
# alpha() avisa si max no es mayor.
por_item <- lapply(names(factores), function(f) {
  a <- alpha(guerrero[, factores[[f]]], warnings = FALSE, max = 11)
  data.frame(factor = f, item = factores[[f]],
             n = a$item.stats$n,
             item_test = a$item.stats$raw.r,
             item_resto = a$item.stats$r.drop,
             alfa_sin_item = if (length(factores[[f]]) > 2) a$alpha.drop$raw_alpha else NA,
             alfa_escala = a$total$raw_alpha)
})
por_item <- do.call(rbind, por_item)
por_item[, 4:7] <- round(por_item[, 4:7], 3)
por_item
write.csv(por_item, file.path(dir_salida, "alfa_por_item.csv"), row.names = FALSE)

# ¿Algún ítem resta consistencia? (el alfa sube al quitarlo)
por_item[!is.na(por_item$alfa_sin_item) & por_item$alfa_sin_item > por_item$alfa_escala, ]

# -----------------------------------------------------------------------
# Paso 4. Alfa con la covarianza ajustada por el modelo
# -----------------------------------------------------------------------
# fitted(fit)$cov es la matriz de covarianzas que reproduce el AFC.
covariance <- as.matrix(fitted(fit)$cov)
alfa_modelo <- sapply(factores, function(items)
  alpha(covariance[items, items], warnings = FALSE)$total$raw_alpha)
round(alfa_modelo, 3)

# -----------------------------------------------------------------------
# Paso 5. Confiabilidad compuesta (omega de Dillon-Goldstein)
# -----------------------------------------------------------------------
#   CC = (suma lambda)^2 / [(suma lambda)^2 + suma var(e)],  var(e) = 1 - lambda^2
# con lambda = cargas estandarizadas del AFC. (semTools::compRelSEM() usa las
# cargas sin estandarizar y da casi lo mismo: la diferencia máxima es .006.)
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
range(sapply(guerrero[, items], function(x) length(unique(na.omit(x)))))

# =======================================================================
# VALIDEZ
# =======================================================================

# -----------------------------------------------------------------------
# Paso 7. Validez de contenido (cualitativa)
# -----------------------------------------------------------------------
# No se calcula: se argumenta revisando que cada ítem pertenezca al dominio
# de su factor (ver el glosario del README del proyecto). Hay una limitación:
# no se tiene el cuestionario original, solo las etiquetas de las variables,
# y la base trae una selección de los ítems (b5-b8, c9-c10... no están).

# -----------------------------------------------------------------------
# Paso 8. Validez de criterio: no es posible con esta base
# -----------------------------------------------------------------------
# Requiere un criterio externo que mida lo mismo (otro instrumento, un
# indicador objetivo como denuncias o delitos en la localidad, conducta
# posterior...). El .dta solo trae los ítems de los instrumentos: ningún
# factor puede validarse contra algo ajeno a ellos.

# -----------------------------------------------------------------------
# Paso 9. Validez de constructo: teoría + correlaciones + interpretación
# -----------------------------------------------------------------------
# A. Teoría / contenido: seis dominios de satisfacción con la vida, y seis
#    percepciones sobre vecinos, autoridades, seguridad y gobierno.
# B. Correlaciones: los ítems de un mismo factor deben correlacionar más
#    entre sí que con los ítems de otros factores.
R <- cor(guerrero[, items], use = "pairwise.complete.obs")
correlaciones <- data.frame(
  factor = names(factores),
  r_media_dentro = sapply(factores, function(i) {
    r <- R[i, i]; mean(r[upper.tri(r)]) }),                  # entre ítems del factor
  r_media_fuera  = sapply(factores, function(i)
    mean(R[i, setdiff(colnames(R), i)])))                     # con ítems de otros factores
correlaciones[, 2:3] <- round(correlaciones[, 2:3], 3)
correlaciones
# C. Interpretación empírica: el AFE (01_AFE) recupera los 12 factores sin
#    cargas cruzadas y el AFC (02_AFC) confirma cargas >= .64, todas
#    significativas.

# -----------------------------------------------------------------------
# Paso 10. Validez convergente: AVE
# -----------------------------------------------------------------------
# AVE = varianza promedio extraída = promedio de lambda^2. Se espera >= 0.50
# (el factor explica al menos la mitad de la varianza de sus ítems).
# semTools::reliability() calcula la AVE con las cargas sin estandarizar y
# difiere como máximo .011.
ave <- sapply(names(factores), function(f)
  mean(tabla_cc$coeficiente[tabla_cc$factor == f]^2))
round(ave, 3)

# -----------------------------------------------------------------------
# Paso 11. Validez discriminante: Fornell-Larcker y HTMT
# -----------------------------------------------------------------------
# Fornell-Larcker: la raíz de AVE de cada factor debe ser mayor que su
# correlación con cualquier otro factor.
phi <- lavInspect(fit, "cor.lv")           # correlaciones entre factores
fornell_larcker <- phi
diag(fornell_larcker) <- sqrt(ave[colnames(phi)])
round(fornell_larcker, 3)                  # diagonal = raíz de AVE
max_correlacion <- apply(abs(phi - diag(diag(phi))), 1, max)[names(factores)]
sqrt(ave) > max_correlacion                # TRUE = cumple

# HTMT (Henseler, Ringle y Sarstedt, 2015): cociente entre la correlación
# media de los ítems de dos factores distintos y la media geométrica de las
# correlaciones dentro de cada factor. Se espera < 0.85 (criterio estricto)
# o < 0.90. (semTools::htmt() da lo mismo con htmt2 = FALSE; por defecto
# calcula HTMT2, que usa medias geométricas y da valores menores.)
htmt <- function(a, b) {
  entre   <- mean(abs(R[a, b]))
  dentro_a <- mean(abs(R[a, a][lower.tri(R[a, a])]))
  dentro_b <- mean(abs(R[b, b][lower.tri(R[b, b])]))
  entre / sqrt(dentro_a * dentro_b)
}
nombres <- names(factores)
HTMT <- sapply(nombres, function(b) sapply(nombres, function(a)
  if (a == b) NA else htmt(factores[[a]], factores[[b]])))
round(HTMT, 2)
max_htmt <- apply(HTMT, 1, max, na.rm = TRUE)
round(max(HTMT, na.rm = TRUE), 3)

# -----------------------------------------------------------------------
# Paso 12. Validez nomológica: ¿las correlaciones entre factores tienen el
#          signo que se espera por su contenido?
# -----------------------------------------------------------------------
# Expectativas planteadas por el contenido de los factores (no vienen de
# una referencia y se formularon con la base ya explorada: es una revisión
# de consistencia, no una prueba independiente):
# - los seis dominios de satisfacción se relacionan positivamente;
# - cohesión vecinal con confianza en las autoridades y con la satisfacción
#   con la vida social; confianza con desempeño del gobierno; inseguridad con
#   riesgo percibido: positivas;
# - inseguridad y riesgo con confianza, desempeño y cohesión: negativas.
sat <- c("pareja", "familia", "economia", "social", "personal", "trabajo")
dentro <- t(combn(sat, 2))
esperado <- rbind(
  data.frame(a = dentro[, 1], b = dentro[, 2], esperado = "+"),
  data.frame(a = c("cohesion", "confianza", "cohesion", "inseguridad"),
             b = c("confianza", "desempeno", "social", "riesgo"), esperado = "+"),
  data.frame(expand.grid(a = c("inseguridad", "riesgo"),
                         b = c("confianza", "desempeno", "cohesion"),
                         stringsAsFactors = FALSE), esperado = "-"))
esperado$r <- round(mapply(function(a, b) phi[a, b], esperado$a, esperado$b), 3)
esperado$cumple <- sign(esperado$r) == ifelse(esperado$esperado == "+", 1, -1)
table(esperado$cumple)
esperado[order(abs(esperado$r))[1:5], ]    # las cinco más débiles
write.csv(esperado, file.path(dir_salida, "validez_nomologica.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 13. Complemento: confiabilidad y AVE del factor de segundo orden G
# -----------------------------------------------------------------------
# G = Satisfacción con la vida (03_AFC_2do_Orden). La misma fórmula del paso 5
# usando las seis cargas de G sobre los dominios, como si fueran "ítems".
modelo_2do <- paste(
  '  pareja   =~ a1 + a2 + a3 + a4
  familia  =~ a5 + a6 + a7 + a8
  economia =~ a9 + a10 + a11 + a12
  social   =~ a13 + a14 + a15 + a16
  personal =~ a17 + a18 + a19 + a20
  trabajo  =~ a21 + a22 + a23 + a24',
  'G =~ pareja + familia + economia + social + personal + trabajo', sep = "\n")
fit_2do <- cfa(modelo_2do, data = guerrero, estimator = "MLR", missing = "fiml")
std2 <- standardizedSolution(fit_2do)
carga_G <- std2$est.std[std2$lhs == "G" & std2$op == "=~"]
cc_G  <- sum(carga_G)^2 / (sum(carga_G)^2 + sum(1 - carga_G^2))
ave_G <- mean(carga_G^2)
round(c(CC_G = cc_G, AVE_G = ave_G), 3)
# G es confiable (CC > .80), pero su AVE queda debajo de .50: pareja y
# familia cargan poco en G (.39 y .45, ver 03_AFC_2do_Orden).

# -----------------------------------------------------------------------
# Paso 14. Tabla resumen
# -----------------------------------------------------------------------
resumen <- data.frame(factor = names(factores),
                      n_items = lengths(factores),
                      alfa = sapply(factores, function(i) alfa_manual(i)["alfa"]),
                      alfa_modelo = alfa_modelo,
                      conf_compuesta = conf_compuesta,
                      AVE = ave,
                      raiz_AVE = sqrt(ave),
                      max_correlacion = max_correlacion,
                      max_HTMT = max_htmt)
resumen[, -(1:2)] <- round(resumen[, -(1:2)], 3)
resumen
write.csv(resumen, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)
write.csv(round(fornell_larcker, 3), file.path(dir_salida, "fornell_larcker.csv"))
write.csv(round(HTMT, 3), file.path(dir_salida, "htmt.csv"))
