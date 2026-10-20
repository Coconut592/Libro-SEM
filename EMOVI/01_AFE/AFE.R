# =============================================================================
# Libro SEM · EMOVI
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Sin referencia: la tesis (Sánchez Flores, 2019) pasa directo al AFC y construye
# el índice de riqueza del hogar de origen con un CFA (Anexo 2). Aquí se explora
# antes cuántos factores tienen esos ítems en la CDMX en 2023.
#   source("EMOVI/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "EMOVI/01_AFE/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: ESRU-EMOVI 2023, solo la Ciudad de México (entidad = 9)
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
nrow(emovi)                                  # 740 entrevistados de 25 a 64 años

# Riqueza del hogar de origen (a los 14 años): 42 ítems Sí/No sobre la vivienda
# (p26, p29), los bienes (p31) y los activos (p32). Códigos: 1 = Sí, 2 = No, 8 = NS.
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))   # NS pasa a faltante

# Criterio 90-10 de la tesis (Anexo 2): se quedan los ítems que entre 10% y 90% de
# los hogares tenían; fuera lo que casi todos tienen o casi nadie tiene.
prop <- colMeans(emovi[, riqueza], na.rm = TRUE)
items <- names(prop)[prop >= .10 & prop <= .90]
length(items)                                # 29 de 42
round(100 * prop[setdiff(riqueza, items)], 1)   # los 13 que salen: p26b (95%) y 12 con menos de 10%
datos <- emovi[, items]
c(completos = sum(complete.cases(datos)), con_NS = sum(!complete.cases(datos)))   # 651 y 89

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y Bartlett
# -----------------------------------------------------------------------
# Con ítems 0/1 la matriz tetracórica de estos datos no es definida positiva
# (el eigenvalor menor es -0.19) y KMO y Bartlett salen sin sentido sobre ella;
# se hacen con la correlación de Pearson (phi) de los casos completos.
completos <- datos[complete.cases(datos), ]
KMO(completos)$MSA                           # .90: meritorio
cortest.bartlett(cor(completos), n = nrow(completos))   # p < .001

# -----------------------------------------------------------------------
# Paso 3. ¿Cuántos factores? Eigenvalores y análisis paralelo (sobre phi)
# -----------------------------------------------------------------------
eigenvalores <- eigen(cor(completos))$values
round(eigenvalores[1:8], 2)
sum(eigenvalores > 1)                        # Kaiser: 6
set.seed(2023)
ap <- fa.parallel(completos, cor = "cor", fa = "fa", fm = "minres", n.iter = 100, plot = FALSE)
ap$nfact                                     # 6. Con ítems 0/1 estos criterios suelen sobrestimar (factores que
                                             # solo separan ítems fáciles de difíciles): se decide con el ajuste
                                             # y con que cada factor tenga sentido

# Lo que sí funciona con ítems 0/1 es el AFE de lavaan (WLSMV, ordinal): da índices
# de ajuste robustos con 1 a 5 factores y rotación oblimin. (El AFE de psych con
# tetracóricas da RMSEA de .5 aquí porque su matriz no es definida positiva.)
ordinales <- as.data.frame(lapply(completos, ordered))
afe <- lapply(1:5, function(k) suppressWarnings(efa(ordinales, nfactors = k, ordered = names(ordinales),
                                   estimator = "WLSMV", rotation = "oblimin")))
medidas <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
tabla_ajuste <- data.frame(factores = 1:5, t(sapply(afe, function(e) round(fitMeasures(e[[1]], medidas), 3))))
# Varianza residual más baja de un ítem (1 - comunalidad): si es negativa, hay un caso Heywood
tabla_ajuste$residual_min <- sapply(afe, function(e) {
  L <- lavInspect(e[[1]], "est")$lambda; Phi <- lavInspect(e[[1]], "est")$psi
  round(min(1 - rowSums((L %*% Phi) * L)), 3) })
tabla_ajuste
# 1 factor: CFI .954, RMSEA .054; 2: .976, .041; 3: .985, .034; 4: .991, .027; 5: mejora poco.
# (Con 5 factores una varianza residual ya es negativa.)
# Se escoge 3: ajuste bueno, cada factor con sentido y el cuarto (p32e, p32f, p32h,
# las cuentas y tarjetas) ya tiene solo tres ítems.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFE.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Tres factores: cargas de patrón (oblimin)
# -----------------------------------------------------------------------
e3 <- afe[[3]][[1]]
cargas <- round(unclass(lavInspect(e3, "est")$lambda), 2)
cargas <- cargas[order(apply(abs(cargas), 1, which.max), -apply(abs(cargas), 1, max)), ]
colnames(cargas) <- c("F1", "F2", "F3")
cargas
# F1: espacios de la vivienda (jardín, patio, cuarto de lavado, cuarto de TV,
#     cochera, servicio doméstico) y tostador y aspiradora.
# F2: servicios y bienes básicos (agua, baño, boiler, estufa, lavadora, refri,
#     teléfono fijo, TV) y las cuentas y tarjetas (p32e, p32f, p32h).
# F3: tecnología y confort (TV de paga, microondas, celular, computadora, internet).
round(lavInspect(e3, "est")$psi, 2)          # los factores correlacionan de .48 a .63
write.csv(cargas, file.path(dir_salida, "cargas_AFE_3_factores.csv"))
