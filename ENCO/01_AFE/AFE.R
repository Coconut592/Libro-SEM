# =============================================================================
# Libro SEM · ENCO
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Sin referencia: el documento de INEGI es solo un diccionario y no trae un modelo
# factorial. Aquí se explora cuántas dimensiones tienen los 15 ítems del
# cuestionario básico (P1 a P15) de la ENCO de agosto de 2026.
#   source("ENCO/01_AFE/AFE.R")
# =============================================================================

library(foreign)
library(psych)
library(lavaan)

dir_salida <- "ENCO/01_AFE/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: cuestionario básico (ENCOCB), 2,050 personas de 18+
# -----------------------------------------------------------------------
# Los códigos de las respuestas vienen como texto ("1", "2"...). Tres arreglos:
#  1. "No sabe" a faltante. Su código cambia por pregunta (6, 4, 3 o 7), y en P10
#     el 4 es "No tiene ingresos", que tampoco contesta la pregunta de ahorro.
#  2. Dirección: en el cuestionario el 1 es SIEMPRE la respuesta más optimista
#     (mucho mejor, sí, mayores, aumentará mucho el empleo, disminuirán mucho los
#     precios). Se invierten todas: MAYOR = MÁS CONFIANZA.
#  3. P12 NO se funde: se queda con sus 6 categorías (decisión del proyecto).
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
nrow(cb)                                     # 2,050

items <- paste0("P", 1:15)
codigo_NS <- c(P1 = 6, P2 = 6, P3 = 6, P4 = 6, P5 = 6, P6 = 6, P7 = 4, P8 = 4, P9 = 3, P10 = 3,
               P11 = 6, P12 = 7, P13 = 6, P14 = 4, P15 = 4)
maximo    <- c(P1 = 5, P2 = 5, P3 = 5, P4 = 5, P5 = 5, P6 = 5, P7 = 3, P8 = 3, P9 = 2, P10 = 2,
               P11 = 5, P12 = 6, P13 = 5, P14 = 3, P15 = 3)
x <- cb[, items]
x[] <- lapply(x, as.integer)
for (v in items) x[[v]][x[[v]] == codigo_NS[[v]]] <- NA
x$P10[cb$P10 == "4"] <- NA
for (v in items) x[[v]] <- maximo[[v]] + 1L - x[[v]]

completos <- x[complete.cases(x), ]
c(completos = nrow(completos), con_NS = nrow(x) - nrow(completos))   # 1,935 y 115 (el AFE usa los completos)

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y Bartlett (policóricas)
# -----------------------------------------------------------------------
# Los ítems son ordinales (2 a 6 categorías): se factoriza la matriz policórica.
rho <- suppressWarnings(polychoric(completos)$rho)
round(min(eigen(rho)$values), 2)             # .18: definida positiva (se puede factorizar)
KMO(rho)$MSA                                 # global: .91 (meritorio)
round(KMO(rho)$MSAi, 2)                      # por ítem: de .86 (P6) a .97 (P11), todos arriba de .80
cortest.bartlett(rho, n = nrow(completos))   # χ² = 17,798 (105 gl), p < .001

# -----------------------------------------------------------------------
# Paso 3. ¿Cuántos factores? Eigenvalores, análisis paralelo y ajuste
# -----------------------------------------------------------------------
eigenvalores <- eigen(rho)$values
round(eigenvalores[1:8], 2)                  # 7.34 1.47 0.99 0.92 0.72 0.66 0.57 0.41
sum(eigenvalores > 1)                        # Kaiser: 2
set.seed(2026)
ap <- suppressWarnings(fa.parallel(completos, cor = "poly", fa = "fa", fm = "minres", n.iter = 50, plot = FALSE))
ap$nfact                                     # análisis paralelo: 5

# AFE de lavaan (WLSMV, ordinal, oblimin): da índices de ajuste de 1 a 5 factores
ordinales <- as.data.frame(lapply(completos, ordered))
afe <- lapply(1:5, function(k) suppressWarnings(efa(ordinales, nfactors = k, ordered = items,
                                   estimator = "WLSMV", rotation = "oblimin")))
medidas <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
tabla_ajuste <- data.frame(factores = 1:5, t(sapply(afe, function(e) round(fitMeasures(e[[1]], medidas), 3))))
# Varianza residual más baja de un ítem (1 - comunalidad): si es negativa, hay un caso Heywood
tabla_ajuste$residual_min <- sapply(afe, function(e) {
  L <- lavInspect(e[[1]], "est")$lambda; Phi <- lavInspect(e[[1]], "est")$psi
  round(min(1 - rowSums((L %*% Phi) * L)), 3) })
tabla_ajuste
# 1 factor: CFI .888, RMSEA .147; 2: .931 y .125; 3: .962 y .102; 4: .992 y .053 (SRMR .024);
# 5: .996 y .044. Ninguna varianza residual es negativa (la mínima es .157 con 5 factores).
# Kaiser (2) y el análisis paralelo (5) no coinciden; se escoge 4: con 4 el ajuste ya es
# bueno, cada factor tiene sentido y el quinto solo separa P14 y P15 (auto y casa) en un
# factor de dos ítems.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFE.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cuatro factores: cargas de patrón (oblimin)
# -----------------------------------------------------------------------
e4 <- afe[[4]][[1]]
cargas <- round(unclass(lavInspect(e4, "est")$lambda), 2)
cargas <- cargas[order(apply(abs(cargas), 1, which.max), -apply(abs(cargas), 1, max)), ]
colnames(cargas) <- paste0("F", 1:4)
cargas
# F1 · Hogar hoy: P1 (.82), P3 (.78). Situación económica de usted y del hogar frente a hace 12 meses.
# F2 · Hogar esperado: P2 (.81), P4 (.78). La misma, dentro de 12 meses.
# F3 · País: P6 (.79), P5 (.76) y, más flojos, P13 empleo (.44) y P12 precios (.41).
# F4 · Consumo, ahorro y planes: P9 y P10 (.78), P14 (.78), P15 (.71), P8 (.66), P7 (.57) y P11 (.41).
# P7 y P8 cargan algo en F1 (.37 y .27) y P11 en tres factores (.41, .24 y .21): el ítem menos limpio.
round(lavInspect(e4, "est")$psi, 2)          # los factores correlacionan de .41 a .60
write.csv(cargas, file.path(dir_salida, "cargas_AFE_4_factores.csv"))

# -----------------------------------------------------------------------
# Paso 5. Verificación: el mismo AFE con psych (mínimos residuales, oblimin)
# -----------------------------------------------------------------------
# psych factoriza la matriz policórica; el coeficiente de congruencia mide qué tan
# parecidos son sus factores a los de lavaan (1 = idénticos; arriba de .95, el mismo
# factor).
fa_psych <- suppressWarnings(fa(rho, nfactors = 4, n.obs = nrow(completos), fm = "minres", rotate = "oblimin"))
cong <- factor.congruence(unclass(fa_psych$loadings), unclass(lavInspect(e4, "est")$lambda))
round(apply(abs(cong), 1, max), 3)           # 1.00, .99, 1.00 y 1.00: los mismos cuatro factores
