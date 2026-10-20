# =============================================================================
# Libro SEM · EMOVI
# 04 - Confiabilidad y validez: Riqueza del hogar de origen
# =============================================================================
# Referencia: la tesis reporta KR-20 (.88, "cercano o mayor a .7") para el índice
# de riqueza y α y Ω para sus otras latentes. No trae validez discriminante ni de
# criterio; se agregan aquí (AVE, Fornell-Larcker, HTMT y correlaciones con
# criterios externos).
#   source("EMOVI/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)
library(lavaan)
library(psych)

dir_salida <- "EMOVI/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo (igual que en 02_AFC)
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))

factores <- list(
  ESP = c("p29a", "p29b", "p29c", "p29d", "p29e", "p29f", "p26e", "p31f", "p31g", "p32a"),
  BAS = c("p26a", "p26c", "p26d", "p29g", "p31a", "p31b", "p31c", "p31d", "p31e", "p31m", "p31o", "p32e", "p32f", "p32h"),
  TEC = c("p31h", "p31i", "p31j", "p31k", "p31l"))
modelo <- paste(sapply(names(factores), function(f) paste(f, "=~", paste(factores[[f]], collapse = " + "))), collapse = "\n")
items <- unlist(factores)
fit <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV", missing = "pairwise")

# -----------------------------------------------------------------------
# Paso 2. Confiabilidad: KR-20, confiabilidad compuesta (CR) y AVE
# -----------------------------------------------------------------------
# KR-20 = alfa de Cronbach con ítems 0/1 (casos completos del factor).
# CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)], con las cargas estandarizadas.
# AVE = promedio de λ²; se pide > .50.
s <- standardizedSolution(fit)
fi <- lavInspect(fit, "cor.lv")
conf <- do.call(rbind, lapply(names(factores), function(f) {
  l <- s$est.std[s$op == "=~" & s$lhs == f]
  data.frame(factor = f, k = length(l),
             KR20 = suppressWarnings(psych::alpha(emovi[, factores[[f]]], check.keys = FALSE))$total$raw_alpha,
             CR = sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), AVE = mean(l^2),
             r2_max = max(fi[f, rownames(fi) != f]^2))
}))
conf$AVE_supera_r2 <- conf$AVE > conf$r2_max
conf[, c("KR20", "CR", "AVE", "r2_max")] <- round(conf[, c("KR20", "CR", "AVE", "r2_max")], 3)
conf
# KR-20 de .75 (ESP) a .85 (TEC) y CR de .90 a .96: confiabilidad alta (la tesis: .88).
# La AVE de ESP (.48) no llega a .50; la de BAS es .56 y la de TEC .81.
# Fornell-Larcker: la AVE de cada factor debe superar su r² más alto con otro factor
# (.66, el de ESP-BAS). ESP (.48) y BAS (.56) NO lo cumplen y TEC (.81) sí; ver HTMT.
write.csv(conf, file.path(dir_salida, "confiabilidad.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Validez discriminante: HTMT (correlaciones tetracóricas)
# -----------------------------------------------------------------------
# HTMT = promedio de las correlaciones entre ítems de dos factores / raíz del
# producto de los promedios de las correlaciones dentro de cada factor.
# Se pide < .85 (estricto) o < .90.
R <- lavCor(emovi[, items], ordered = items, missing = "pairwise")
dentro <- function(v) mean(R[v, v][lower.tri(R[v, v])])
htmt <- function(a, b) mean(R[factores[[a]], factores[[b]]]) / sqrt(dentro(factores[[a]]) * dentro(factores[[b]]))
parejas <- t(combn(names(factores), 2))
tabla_htmt <- data.frame(par = paste(parejas[, 1], parejas[, 2], sep = " - "),
                         r_factores = round(mapply(function(a, b) fi[a, b], parejas[, 1], parejas[, 2]), 2),
                         HTMT = round(mapply(htmt, parejas[, 1], parejas[, 2]), 2))
tabla_htmt
# HTMT de .80 (ESP-BAS), .69 (ESP-TEC) y .83 (BAS-TEC): los tres bajo .85. Por HTMT
# los factores se distinguen; por Fornell-Larcker, ESP y BAS no del todo. Comparten
# mucho (r de .69 a .81), que es lo que justifica el segundo orden (ver 03).
write.csv(tabla_htmt, file.path(dir_salida, "htmt.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Validez de criterio: el puntaje contra variables externas
# -----------------------------------------------------------------------
# Puntaje de riqueza (segundo orden). Criterios con los que debería ir en positivo:
# lugar que el entrevistado da al hogar de los 14 años en la escala de 1 a 10
# (p104), educación del padre y de la madre (educp, educm, 4 categorías) y clase
# ocupacional del padre (clasep). Menos relacionados: la posición actual (p103) y
# el ingreso per cápita actual (ingc_pc, en logaritmo).
fit2 <- cfa(paste(modelo, "\n RIQ =~ ESP + BAS + TEC"), data = emovi, ordered = items,
            estimator = "WLSMV", missing = "pairwise")
riq <- as.numeric(lavPredict(fit2, method = "EBM")[, "RIQ"])
criterios <- data.frame(p104 = emovi$p104, educp = emovi$educp, educm = emovi$educm,
                        clasep = emovi$clasep, p103 = emovi$p103, ln_ingreso = log(emovi$ingc_pc))
validez <- data.frame(criterio = names(criterios),
  spearman = round(sapply(criterios, function(y) cor(riq, y, use = "pairwise.complete.obs", method = "spearman")), 2),
  n = sapply(criterios, function(y) sum(!is.na(y))))
rownames(validez) <- NULL
validez
# Todos positivos: p104 .46, educp .38, educm .52, clasep .26, p103 .28, ingreso .33.
# El criterio más cercano (la posición del hogar a los 14 años) correlaciona .46.
write.csv(validez, file.path(dir_salida, "validez_criterio.csv"), row.names = FALSE)
