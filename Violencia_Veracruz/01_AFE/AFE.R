# =============================================================================
# Libro SEM · Violencia Veracruz
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# Sin referencia: Scripts.do pasa de la base directo a un análisis de clases
# latentes en Mplus (24 ítems -> 3 clases), sin explorar la estructura factorial.
# Aquí se explora antes cuántos factores tienen esos 24 ítems de violencia.
#   source("Violencia_Veracruz/01_AFE/AFE.R")
# =============================================================================

library(readstata13)
library(psych)
library(lavaan)

dir_salida <- "Violencia_Veracruz/01_AFE/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos: 1,088 mujeres de Veracruz y 24 ítems Sí/No de violencia
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
bloques <- list(
  infancia  = c("p141", "p142", "p143", "p144"),
  familia   = c("p161", "p162", "p165"),
  pareja    = c("p171", "p172", "p173", "p175", "p176"),
  trabajo   = c("p183", "p184", "p185", "p186"),
  comunidad = c("p191", "p192", "p193", "p194"),
  escuela   = c("p201", "p202", "p203", "p204"))
items <- unlist(bloques)
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # quita el renglón huérfano id 907 (sin ítems)
nrow(vera)                                   # 1,088
datos <- vera[, items]                       # 0 = No, 1 = Sí
sum(complete.cases(datos))                   # solo 505 contestan los 24 (pareja, trabajo y escuela se saltan)

# No se aplica el criterio 90-10 de EMOVI: 8 ítems los reporta menos del 5%, pero en
# violencia el evento raro es justo el objeto de estudio (ver 00_Diagnostico).

# -----------------------------------------------------------------------
# Paso 2. ¿Tiene sentido factorizar? KMO y Bartlett
# -----------------------------------------------------------------------
# La matriz tetracórica de estos datos no es definida positiva (eigenvalor menor
# de -0.32 con lavaan; 23 de 276 parejas de ítems tienen 2 mujeres o menos que digan
# "Sí" en ambos), y KMO y Bartlett salen sin sentido sobre ella. Se hacen con la
# correlación de Pearson (phi) por pares. Para Bartlett, n es el promedio armónico de
# las mujeres que contestan cada pareja de ítems.
phi <- cor(datos, use = "pairwise.complete.obs")
min(eigen(phi)$values)                       # .27: definida positiva
KMO(phi)$MSA                                 # .79: aceptable
n_par <- crossprod(!is.na(datos))
n_armonico <- 1 / mean(1 / n_par[lower.tri(n_par)])
round(n_armonico)                            # 841
cortest.bartlett(phi, n = round(n_armonico)) # chi2(276) = 4,875, p < .001
round(sort(KMO(phi)$MSAi), 2)[1:5]           # los de menor adecuación (.62-.70) son los raros: p194, p185, p193, p184 y p183

# -----------------------------------------------------------------------
# Paso 3. ¿Cuántos factores? Eigenvalores y análisis paralelo (sobre phi)
# -----------------------------------------------------------------------
eigenvalores <- eigen(phi)$values
round(eigenvalores[1:9], 2)
sum(eigenvalores > 1)                        # Kaiser: 8
set.seed(2018)
ap <- fa.parallel(datos, cor = "cor", fa = "fa", fm = "minres", n.iter = 100, plot = FALSE)
ap$nfact                                     # 8. Con ítems 0/1 y eventos raros estos criterios sobrestiman:
                                             # separan ítems por su frecuencia. Se decide con el ajuste

# El AFE de lavaan (WLSMV, ordinal, oblimin, parejas disponibles) da índices de ajuste
# robustos de 1 a 7 factores. (El AFE de psych con tetracóricas no sirve aquí: su matriz
# no es definida positiva.) Se guarda la varianza residual más baja de un ítem
# (1 - comunalidad): si es negativa, hay un caso Heywood.
ordinales <- as.data.frame(lapply(datos, ordered))
afe <- lapply(1:7, function(k) suppressWarnings(efa(ordinales, nfactors = k, ordered = names(ordinales),
                                   estimator = "WLSMV", rotation = "oblimin", missing = "pairwise")))
medidas <- c("chisq.scaled", "df", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
tabla_ajuste <- data.frame(factores = 1:7, t(sapply(afe, function(e) round(fitMeasures(e[[1]], medidas), 3))))
tabla_ajuste$residual_min <- sapply(afe, function(e) {
  L <- lavInspect(e[[1]], "est")$lambda; Phi <- lavInspect(e[[1]], "est")$psi
  round(min(1 - rowSums((L %*% Phi) * L)), 3) })
tabla_ajuste
# 1 factor: CFI .847, RMSEA .065; 2: .911, .052; 3: .958, .038; 4: .978, .029;
# 5: .988, .022; 6: .996, .015; 7: .998, .009 (pero una varianza residual ya es
# negativa: -0.077). El SRMR de todos es alto (.06-.19) por las parejas casi vacías.
# Se examinan 5 y 6: el 5 tiene factores claros y el 6 es el máximo sin caso Heywood.
write.csv(tabla_ajuste, file.path(dir_salida, "ajuste_AFE.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Cinco y seis factores: cargas de patrón (oblimin)
# -----------------------------------------------------------------------
cargas_k <- function(k) {
  e <- afe[[k]][[1]]
  L <- round(unclass(lavInspect(e, "est")$lambda), 2)
  L <- L[order(apply(abs(L), 1, which.max), -apply(abs(L), 1, max)), ]
  colnames(L) <- paste0("F", 1:k)
  L
}
c5 <- cargas_k(5)
c5
# F1: infancia (p141-p144).                      F4: comunidad (p191-p194; p193 es el más flojo, .41).
# F2: familia (p161, p162, p165) y trabajo       F5: escuela (p201-p204).
#     (p183-p186): VIOLENCIA FAMILIAR Y LABORAL en un solo factor.
# F3: pareja (p171-p176).
round(lavInspect(afe[[5]][[1]], "est")$psi, 2)   # los factores correlacionan de .14 a .36
write.csv(c5, file.path(dir_salida, "cargas_AFE_5_factores.csv"))

c6 <- cargas_k(6)
c6
# Con 6 factores infancia, pareja y escuela siguen claros, pero trabajo NO sale como factor
# propio (p183 y p185 cargan en el de familia y p184 en el de escuela) y comunidad se parte en
# dos: p191-p192 por un lado y p193-p194 por otro (con p185 y p175 cargando también ahí).
round(lavInspect(afe[[6]][[1]], "est")$psi, 2)
write.csv(c6, file.path(dir_salida, "cargas_AFE_6_factores.csv"))

# -----------------------------------------------------------------------
# Paso 5. Los seis ámbitos del cuestionario: correlación dentro y fuera de cada bloque
# -----------------------------------------------------------------------
# Correlación policórica por pares (la usan los modelos ordinales). Si los bloques son
# reales, los ítems de un bloque correlacionan más entre sí que con los demás.
R <- lavCor(datos, ordered = items, missing = "pairwise")
dentro_fuera <- t(sapply(bloques, function(v) {
  r <- R[v, v]
  c(k = length(v), r_dentro = mean(r[upper.tri(r)]), r_fuera = mean(R[v, setdiff(items, v)]))
}))
round(dentro_fuera, 2)
# Dentro: infancia .79, familia .76, pareja .72, escuela .70, trabajo .56, comunidad .43.
# Fuera: .22 a .37. Los bloques son nítidos, salvo comunidad y trabajo (los más débiles).
write.csv(round(dentro_fuera, 3), file.path(dir_salida, "correlaciones_dentro_fuera.csv"))
