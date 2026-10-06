# =============================================================================
# Libro SEM · Violencia Guerrero
# 02 - Validación cruzada del AFC (opcional)
# =============================================================================
# El AFE (01_AFE) y el AFC (AFC.R) usan la misma muestra, así que el AFC no es
# una confirmación independiente. Aquí se prueba qué pasa al dividir la
# muestra al azar en dos mitades de 147 personas: AFE en una mitad y AFC de la
# estructura por bloques en la otra. Se repite con tres particiones.
# Es opcional: no se usa en el resto del proyecto. Tarda unos 5 minutos.
#   source("Violencia_Guerrero/02_AFC/Validacion_cruzada.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo
# -----------------------------------------------------------------------
guerrero <- read.dta13("Violencia_Guerrero/data/cap4_GRO.dta")
items <- setdiff(names(guerrero), "folio")

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
bloque <- setNames(rep(names(factores), lengths(factores)), unlist(factores))[items]
modelo <- paste(sapply(names(factores), function(f)
  paste(f, "=~", paste(factores[[f]], collapse = " + "))), collapse = "\n")

# -----------------------------------------------------------------------
# Paso 2. Referencia: la muestra completa con las mismas medidas
# -----------------------------------------------------------------------
# ML con FIML y medidas estándar (no robustas: las robustas con FIML tardan
# más de 2 minutos cada vez).
medidas <- c("cfi", "tli", "rmsea", "srmr")
fit_completo <- cfa(modelo, data = guerrero, estimator = "ML", missing = "fiml")
round(fitMeasures(fit_completo, medidas), 3)

# -----------------------------------------------------------------------
# Paso 3. AFE en una mitad y AFC en la otra
# -----------------------------------------------------------------------
# Para cada partición (semilla): mitad A = 147 personas al azar, mitad B = el
# resto.
#  - AFE de 12 factores en A (ML, oblimin, matriz FIML como en 01_AFE). Se
#    cuenta cuántos de los 46 ítems tienen su factor dominante en el mismo
#    factor que el resto de su bloque, cuántos factores distintos son
#    dominantes (12 = uno por bloque) y la segunda carga más alta.
#  - AFC de la estructura por bloques en B (ML + FIML).
validar <- function(semilla) {
  set.seed(semilla)
  orden <- sample(nrow(guerrero))
  mitad_A <- guerrero[orden[1:147], items]
  mitad_B <- guerrero[orden[148:294], items]
  R_A <- as.matrix(lavCor(mitad_A, missing = "fiml", output = "cor"))
  afe <- fa(R_A, nfactors = 12, n.obs = nrow(mitad_A), fm = "ml",
            rotate = "oblimin", max.iter = 5000)
  cargas <- unclass(afe$loadings)
  dominante <- colnames(cargas)[apply(abs(cargas), 1, which.max)]
  fit <- cfa(modelo, data = mitad_B, estimator = "ML", missing = "fiml")
  carga_B <- standardizedSolution(fit)
  carga_B <- carga_B$est.std[carga_B$op == "=~"]
  c(semilla = semilla,
    factores_dominantes = length(unique(dominante)),
    items_en_su_bloque = sum(sapply(split(dominante, bloque), function(d) max(table(d)))),
    segunda_carga_max = max(apply(abs(cargas), 1, function(r) sort(r, decreasing = TRUE)[2])),
    fitMeasures(fit, medidas),
    carga_min_B = min(carga_B), carga_max_B = max(carga_B))
}
resultados <- t(sapply(c(101, 102, 103), validar))
round(resultados, 3)
# Con mitades de 147 personas el AFE recupera casi todos los ítems en su bloque
# (44 a 46 de 46) aunque no siempre con 12 factores bien separados, y el AFC en
# la otra mitad ajusta peor y de forma menos estable que con las 294 (el
# modelo tiene 158 parámetros): la estructura se replica, pero no hay muestra
# para dividirla. Alguna partición puede dar una carga mayor que 1 (varianza
# residual negativa) y lavaan avisa.
