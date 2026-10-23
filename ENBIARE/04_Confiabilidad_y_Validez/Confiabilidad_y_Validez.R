# =============================================================================
# Libro SEM · ENBIARE
# 04 - Confiabilidad y validez
# =============================================================================
# Sin referencia: no hay documento de validez. Se calcula, con los modelos de 02 y 03:
# alfa y omega, confiabilidad compuesta (CR), AVE, validez discriminante (Fornell-Larcker
# y HTMT, dentro de cada escala y entre las dos) y validez de criterio con variables de
# la propia base (satisfacción con la vida, escalón, afecto, depresión y ansiedad).
#   source("ENBIARE/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(lavaan)
library(semTools)
library(psych)

dir_salida <- "ENBIARE/04_Confiabilidad_y_Validez/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelos (los de 02 y 03)
# -----------------------------------------------------------------------
enb <- read.csv("ENBIARE/data/conjunto_de_datos_tenbiare_enbiare_2021.csv",
                fileEncoding = "latin1", na.strings = c("", " "), quote = "\"",
                comment.char = "", stringsAsFactors = FALSE)
names(enb) <- tolower(names(enb))

m_sat <- '
  NIV =~ pa3_01 + pa3_02 + pa3_03 + pa3_08
  REL =~ pa3_04 + pa3_05 + pa3_06 + pa3_07
  AUT =~ pa3_09 + pa3_10 + pa3_12
  BAR =~ pa3_13 + pa3_14
  CIU =~ pa3_11 + pa3_15 + pa3_16 + pa3_17'
m_conf <- '
  INT =~ pb1_01 + pb1_02
  POL =~ pb1_04 + pb1_05
  MIL =~ pb1_06 + pb1_07
  JUS =~ pb1_08 + pb1_09
  PLT =~ pb1_10 + pb1_11 + pb1_12'
segundo <- c(SAT = "SAT =~ NIV + REL + AUT + BAR + CIU", CONF = "CONF =~ POL + MIL + JUS + PLT")
modelos <- list(SAT = m_sat, CONF = m_conf)
fits  <- lapply(modelos, function(m) cfa(m, data = enb, estimator = "MLR", std.lv = TRUE))
fits2 <- lapply(names(modelos), function(nm)
  cfa(paste(modelos[[nm]], segundo[[nm]], sep = "\n"), data = enb, estimator = "MLR", std.lv = TRUE))
names(fits2) <- names(modelos)

# -----------------------------------------------------------------------
# Paso 2. Alfa, omega, confiabilidad compuesta y AVE
# -----------------------------------------------------------------------
# - Alfa de Cronbach con los datos de los ítems del factor.
# - Omega (McDonald): confiabilidad del puntaje del factor con las cargas del modelo
#   (semTools::compRelSEM); con cargas distintas es más justo que el alfa.
# - Confiabilidad compuesta (Dillon-Goldstein): CR = (Σλ)² / [(Σλ)² + Σ(1 - λ²)], con λ estandarizadas.
# - AVE = promedio de λ²; se pide > .50. Fornell-Larcker: la AVE de un factor debe superar su r²
#   más alto con otro factor.
# - HTMT (Henseler et al., 2015) con las correlaciones entre ítems; se pide < .85 (estricto) o < .90.
htmt_matriz <- function(items_por_factor, d) {
  R <- abs(cor(d[, unlist(items_por_factor)], use = "pairwise"))
  fs <- names(items_por_factor)
  dentro <- function(it) { r <- R[it, it, drop = FALSE]; mean(r[lower.tri(r)]) }
  H <- matrix(NA, length(fs), length(fs), dimnames = list(fs, fs))
  for (a in fs) for (b in fs) if (a != b)
    H[a, b] <- mean(R[items_por_factor[[a]], items_por_factor[[b]]]) /
      sqrt(dentro(items_por_factor[[a]]) * dentro(items_por_factor[[b]]))
  H
}
confiabilidad <- function(nm) {
  fit <- fits[[nm]]; s <- standardizedSolution(fit)
  L <- s[s$op == "=~", ]
  items_f <- lapply(split(L$rhs, factor(L$lhs, levels = unique(L$lhs))), identity)
  phi <- lavInspect(fit, "cor.lv")
  omega <- compRelSEM(fit)
  H <- htmt_matriz(items_f, enb)
  do.call(rbind, lapply(names(items_f), function(f) {
    l <- L$est.std[L$lhs == f]
    data.frame(escala = nm, factor = f, k = length(l),
               alfa = suppressWarnings(suppressMessages(psych::alpha(enb[, items_f[[f]]], check.keys = FALSE)))$total$raw_alpha,
               omega = unname(omega[f]),
               CR = sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), AVE = mean(l^2),
               r2_max = max(phi[f, rownames(phi) != f]^2), HTMT_max = max(H[f, ], na.rm = TRUE))
  }))
}
conf <- do.call(rbind, lapply(names(modelos), confiabilidad))
conf$Fornell_Larcker <- conf$AVE > conf$r2_max
num <- c("alfa", "omega", "CR", "AVE", "r2_max", "HTMT_max")
conf[num] <- round(conf[num], 3)
conf
# SAT: α .61-.76, ω .61-.76, CR .61-.77, AVE .40-.45: ningún factor llega a .50 ni pasa Fornell-Larcker.
# CONF: α .72-.90, CR .73-.90, AVE .58-.82: todos cumplen; el caso más justo es JUS-PLT (r² .69, HTMT .84).
write.csv(conf, file.path(dir_salida, "confiabilidad_validez.csv"), row.names = FALSE)

# La AVE de SAT depende del estimador. Con WLSMV (los 11 puntos como ordinales) las cargas suben:
sens_ave <- do.call(rbind, lapply(names(modelos), function(nm) {
  items <- unique(unlist(regmatches(modelos[[nm]], gregexpr("p[ab][0-9]_[0-9]+", modelos[[nm]]))))
  d <- enb; d[items] <- lapply(d[items], ordered)
  s <- standardizedSolution(cfa(modelos[[nm]], d, ordered = items, estimator = "WLSMV", std.lv = TRUE))
  L <- s[s$op == "=~", ]
  do.call(rbind, lapply(unique(L$lhs), function(f) { l <- L$est.std[L$lhs == f]
    data.frame(escala = nm, factor = f, CR_WLSMV = round(sum(l)^2 / (sum(l)^2 + sum(1 - l^2)), 3), AVE_WLSMV = round(mean(l^2), 3)) }))
}))
sens_ave <- merge(conf[, c("escala", "factor", "CR", "AVE")], sens_ave, sort = FALSE)
sens_ave
# SAT: la AVE sube de .41-.45 a .49-.54 y la CR de .61-.77 a .70-.82: REL (.535) y BAR (.543) pasan de .50
# y NIV, AUT y CIU quedan en .49. CONF sube todavía más (AVE .60-.87). El "AVE < .50" de SAT depende del estimador.
write.csv(sens_ave, file.path(dir_salida, "sensibilidad_AVE_WLSMV.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Confiabilidad del segundo orden
# -----------------------------------------------------------------------
# omega jerárquico (ω_h): proporción de la varianza del puntaje total que se debe al factor general.
# omega total (ω_t): proporción debida a todos los factores (general + de grupo).
# ω_h / ω_t: qué parte de la varianza confiable es del factor general.
# Se calcula con semTools y con la fórmula a mano (1'ΛΓ)² / 1'Σ1 para comprobarlo. En CONF el
# puntaje total es el de los 9 ítems de los cuatro factores institucionales (INT no cuelga del general).
omega_2o <- do.call(rbind, lapply(names(fits2), function(nm) {
  f <- fits2[[nm]]
  r <- compRelSEM(f, higher = nm, return.total = TRUE)
  est <- lavInspect(f, "est"); primeros <- setdiff(colnames(est$lambda), nm)
  Gam <- est$beta[primeros, nm]; Gam <- Gam[Gam != 0]            # factores que cuelgan del general
  Lam <- est$lambda[, names(Gam)]; its <- rownames(Lam)[rowSums(Lam != 0) > 0]
  S <- lavInspect(f, "implied")$cov[its, its]                    # solo los ítems de esos factores
  omega_h <- sum(Lam[its, ] %*% Gam)^2 / sum(S)
  data.frame(escala = nm, omega_h_semTools = round(unname(r[nm]), 3), omega_h_a_mano = round(omega_h, 3),
             omega_total = round(unname(r["total"]), 3), prop_general = round(unname(r[nm] / r["total"]), 3))
}))
omega_2o
# SAT: ω_h .79 (semTools .785), ω_t .89: el factor general explica el 88 % de la varianza confiable
# del puntaje total. CONF: ω_h .89, ω_t .96 (92 %). La fórmula a mano coincide con semTools a .005
# (semTools usa la varianza observada en el denominador).
write.csv(omega_2o, file.path(dir_salida, "omega_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Validez discriminante entre las dos escalas
# -----------------------------------------------------------------------
# ¿La satisfacción y la confianza son constructos distintos? (a) HTMT entre las dos escalas con
# todos sus ítems; (b) correlación entre los dos factores generales en un modelo conjunto.
items_sat  <- sprintf("pa3_%02d", 1:17); items_conf <- sprintf("pb1_%02d", c(1, 2, 4:12))
htmt_escalas <- htmt_matriz(list(SAT = items_sat, CONF = items_conf), enb)["SAT", "CONF"]
round(htmt_escalas, 2)                       # .44: por debajo de .85
conjunto <- cfa(paste(m_sat, m_conf, segundo["SAT"], segundo["CONF"], sep = "\n"), data = enb, estimator = "MLR", std.lv = TRUE)
c(converge = lavInspect(conjunto, "converged"), round(fitMeasures(conjunto, c("cfi.robust", "rmsea.robust", "srmr")), 3))
s_conj <- standardizedSolution(conjunto)
cor_escalas <- s_conj[s_conj$op == "~~" & ((s_conj$lhs == "SAT" & s_conj$rhs == "CONF") | (s_conj$lhs == "CONF" & s_conj$rhs == "SAT")),
                      c("lhs", "rhs", "est.std", "se")]
cor_escalas                                  # r latente SAT-CONF = .34 (r² = .12): distintas, y mucho menos que las AVE de cada una
write.csv(data.frame(HTMT_SAT_CONF = round(htmt_escalas, 3), r_latente_SAT_CONF = round(cor_escalas$est.std, 3)),
          file.path(dir_salida, "discriminante_entre_escalas.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Validez de criterio con variables de la propia base
# -----------------------------------------------------------------------
# Criterios: pa1 (satisfacción con su vida hoy), pa5 (escalón en que ubica su vida), afecto
# positivo (media de pa4_01 a pa4_05), afecto negativo (pa4_06 a pa4_10), depresión (CESD-7,
# pd2_1 a pd2_7, con pd2_6 invertida) y ansiedad (GAD-2, pd3_1 y pd3_2).
# Esperado: la satisfacción va en positivo con pa1, pa5 y afecto positivo, y en negativo con
# afecto negativo, depresión y ansiedad. La confianza institucional, mucho menos relacionada con
# el bienestar (validez discriminante). Se usan los puntajes de los modelos de 2.º orden.
puntajes <- cbind(lavPredict(fits2$SAT), lavPredict(fits2$CONF)[, c("INT", "POL", "MIL", "JUS", "PLT", "CONF")])
puntajes <- puntajes[, !duplicated(colnames(puntajes))]
criterios <- data.frame(
  pa1 = enb$pa1, pa5 = enb$pa5,
  afecto_pos = rowMeans(enb[, sprintf("pa4_%02d", 1:5)]), afecto_neg = rowMeans(enb[, sprintf("pa4_%02d", 6:10)]),
  depresion = rowMeans(cbind(enb[, paste0("pd2_", c(1:5, 7))], 3 - enb$pd2_6)), ansiedad = rowMeans(enb[, paste0("pd3_", 1:2)]))
validez <- round(cor(puntajes, criterios, method = "spearman"), 2)
validez
# SAT: pa1 .60, pa5 .57, afecto positivo .51; afecto negativo -.31, depresión -.36, ansiedad -.30. Por
# factor, de NIV (.61 con pa1) a CIU (.37): el entorno se parece menos al bienestar personal.
# CONF: de -.07 a .19 (el mayor, con pa5): no es bienestar. INT (confianza en personas) se acerca más
# al bienestar (.20 a .26 con pa1, pa5 y afecto positivo) que la confianza institucional.
write.csv(validez, file.path(dir_salida, "validez_criterio.csv"))
# Correlación entre los propios criterios (como referencia del techo esperable)
round(cor(criterios, method = "spearman"), 2)

# -----------------------------------------------------------------------
# Paso 6. Lo que NO se calcula aquí
# -----------------------------------------------------------------------
# KR-20: es para ítems 0/1; estos van de 0 a 10. Validez de contenido: no hay documento del
# instrumento en los archivos; el cuestionario está en la ENBIARE de INEGI.
