# =============================================================================
# Libro SEM · ENBIARE
# 03 - AFC de segundo orden
# =============================================================================
# Sin referencia: no hay un modelo de segundo orden publicado de la ENBIARE. Como en
# PREP y ENCO, el factor general se define igual que uno de primer orden:
#   SAT  =~ NIV + REL + AUT + BAR + CIU   (satisfacción con la vida)
#   CONF =~ POL + MIL + JUS + PLT         (confianza institucional; INT queda aparte)
#   source("ENBIARE/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(lavaan)
library(semPlot)

dir_salida <- "ENBIARE/03_AFC_2do_Orden/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelos (los de 02_AFC)
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

medidas <- c("chisq.scaled", "df.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")
ajuste <- function(fit, nombre) {
  m <- round(as.numeric(fitMeasures(fit, medidas)), 3)
  data.frame(modelo = nombre, N = lavInspect(fit, "nobs"), chisq = m[1], gl = m[2],
             CFI = m[3], TLI = m[4], RMSEA = m[5], SRMR = m[6])
}

# -----------------------------------------------------------------------
# Paso 2. Primer orden y segundo orden
# -----------------------------------------------------------------------
# std.lv = TRUE fija en 1 la varianza del factor de segundo orden (y de los de primer
# orden sin padre), como en el Lab 3. En CONF, INT no cuelga de CONF: queda como un
# factor de primer orden que covaría con él (es la confianza en personas, no en instituciones).
fit1 <- lapply(modelos, function(m) cfa(m, data = enb, estimator = "MLR", std.lv = TRUE))
fit2 <- lapply(names(modelos), function(nm)
  cfa(paste(modelos[[nm]], segundo[[nm]], sep = "\n"), data = enb, estimator = "MLR", std.lv = TRUE))
names(fit2) <- names(modelos)
sapply(fit2, lavInspect, "converged")        # TRUE, TRUE
sapply(fit2, function(f) suppressWarnings(lavInspect(f, "post.check")))   # TRUE: sin varianzas negativas

# -----------------------------------------------------------------------
# Paso 3. Solución estandarizada del segundo orden
# -----------------------------------------------------------------------
# El disturbio es la varianza del factor de primer orden que el general NO explica (1 - λ²).
cargas_2o <- do.call(rbind, lapply(names(fit2), function(nm) {
  s <- standardizedSolution(fit2[[nm]])
  d <- s[s$op == "=~" & s$lhs == nm, c("lhs", "rhs", "est.std", "se", "pvalue")]
  d$R2 <- round(d$est.std^2, 3)                 # varianza del factor explicada por el general
  d$disturbio <- round(1 - d$est.std^2, 3)
  d$escala <- nm; d
}))
cargas_2o$est.std <- round(cargas_2o$est.std, 3)
cargas_2o
# SAT: NIV .91, REL .85, AUT .88, BAR .76, CIU .60 (R² de .83, .73, .78, .57 y .36).
# CONF: POL .86, MIL .82, JUS .93, PLT .86 (R² de .66 a .86).
write.csv(cargas_2o, file.path(dir_salida, "cargas_2do_orden.csv"), row.names = FALSE)
# INT (confianza interpersonal) frente al factor general de instituciones
s_conf <- standardizedSolution(fit2$CONF)
s_conf[s_conf$op == "~~" & s_conf$lhs == "INT" & s_conf$rhs == "CONF", c("lhs", "rhs", "est.std")]   # .46

# -----------------------------------------------------------------------
# Paso 4. Comparación con el primer orden
# -----------------------------------------------------------------------
# El segundo orden restringe las correlaciones entre los factores de primer orden. SAT: 10
# correlaciones se explican con 5 cargas (5 gl más). CONF: las 6 correlaciones entre los cuatro
# institucionales con 4 cargas (2 gl) y las 4 de INT con ellos con una sola (3 gl): 5 gl más.
# Con 31 mil casos la diferencia de χ² siempre es significativa; se mira la
# caída de CFI (Chen, 2007: <= .010 es aceptable) y del RMSEA.
tabla <- do.call(rbind, lapply(names(modelos), function(nm) {
  a <- ajuste(fit1[[nm]], paste(nm, "1er orden")); b <- ajuste(fit2[[nm]], paste(nm, "2do orden"))
  lrt <- suppressMessages(lavTestLRT(fit1[[nm]], fit2[[nm]]))   # Satorra-Bentler
  b$dCFI <- round(b$CFI - a$CFI, 3); b$dRMSEA <- round(b$RMSEA - a$RMSEA, 3)
  b$dchisq <- round(lrt$`Chisq diff`[2], 1); b$gl_dif <- lrt$`Df diff`[2]; b$p <- signif(lrt$`Pr(>Chisq)`[2], 2)
  a[c("dCFI", "dRMSEA", "dchisq", "gl_dif", "p")] <- NA
  rbind(a, b)
}))
tabla
# SAT: CFI .952 -> .938 (ΔCFI -.014, algo más que el límite de .010) y RMSEA .047 -> .053.
# CONF: CFI .968 -> .962 (ΔCFI -.006, dentro) y RMSEA .088 -> .090.
write.csv(tabla, file.path(dir_salida, "ajuste_1er_vs_2do_orden.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. ¿Un solo factor general en satisfacción?
# -----------------------------------------------------------------------
# CIU (ciudad y país) carga solo .60 y BAR .76 en el factor general, y los factores
# "personales" (NIV, REL, AUT) correlacionan de .74 a .82 entre sí pero menos con BAR y CIU.
# Se prueba una variante con dos factores de segundo orden: personal y entorno.
m_dos <- paste(m_sat, "PER =~ NIV + REL + AUT", "ENT =~ BAR + CIU", sep = "\n")
fit_dos <- cfa(m_dos, data = enb, estimator = "MLR", std.lv = TRUE)
s_dos <- standardizedSolution(fit_dos)
variantes <- rbind(ajuste(fit1$SAT, "SAT 1er orden"), ajuste(fit2$SAT, "SAT 2do orden, 1 general"),
                   ajuste(fit_dos, "SAT 2do orden, personal + entorno"))
variantes$gl_extra <- variantes$gl - variantes$gl[1]
variantes
s_dos[s_dos$op == "=~" & s_dos$lhs %in% c("PER", "ENT"), c("lhs", "rhs", "est.std")]   # PER .93, .87, .88; ENT .94, .74
round(s_dos$est.std[s_dos$op == "~~" & s_dos$lhs == "PER" & s_dos$rhs == "ENT"], 2)     # .75
# Con dos de segundo orden (personal: NIV, REL, AUT; entorno: BAR, CIU, que correlacionan .75)
# el ajuste es prácticamente el del primer orden (CFI .950, RMSEA .048, ΔCFI -.002). El
# factor general único pierde .014 de CFI porque ENT y PER no son del todo el mismo factor.
# Se mantiene el general único para los ejercicios (04 a 06), con esta salvedad.
write.csv(variantes, file.path(dir_salida, "variantes_SAT.csv"), row.names = FALSE)

# Confianza: INT dentro del factor general da exactamente el mismo modelo (solo cambia el
# parametrizado): su carga en CONF es la correlación de .46.
fit_5 <- cfa(paste(m_conf, "CONF =~ INT + POL + MIL + JUS + PLT", sep = "\n"), data = enb, estimator = "MLR", std.lv = TRUE)
rbind(ajuste(fit2$CONF, "CONF, INT aparte"), ajuste(fit_5, "CONF, INT dentro"))     # idénticos
standardizedSolution(fit_5)[standardizedSolution(fit_5)$op == "=~" & standardizedSolution(fit_5)$lhs == "CONF",
                            c("rhs", "est.std")]

# -----------------------------------------------------------------------
# Paso 6. Sensibilidad: ordinal (WLSMV)
# -----------------------------------------------------------------------
sens <- do.call(rbind, lapply(names(modelos), function(nm) {
  items <- unique(unlist(regmatches(modelos[[nm]], gregexpr("p[ab][0-9]_[0-9]+", modelos[[nm]]))))
  d <- enb; d[items] <- lapply(d[items], ordered)
  f1 <- cfa(modelos[[nm]], d, ordered = items, estimator = "WLSMV", std.lv = TRUE)
  f2 <- cfa(paste(modelos[[nm]], segundo[[nm]], sep = "\n"), d, ordered = items, estimator = "WLSMV", std.lv = TRUE)
  m <- function(f) round(as.numeric(fitMeasures(f, c("cfi.scaled", "rmsea.scaled"))), 3)
  s2 <- standardizedSolution(f2)
  data.frame(escala = nm, CFI_1er = m(f1)[1], CFI_2do = m(f2)[1], dCFI = m(f2)[1] - m(f1)[1],
             cargas_2do = paste(round(s2$est.std[s2$op == "=~" & s2$lhs == nm], 2), collapse = " · "))
}))
sens
# Con WLSMV el segundo orden de CONF no pierde nada (CFI .980 -> .981) y sus cargas son parecidas
# (.82 a .95). El de SAT pierde más que con MLR: CFI .966 -> .941 (ΔCFI -.025), con cargas de .65
# (CIU) a .91 (NIV). Con el estimador ordinal el factor general único de satisfacción queda más
# lejos del primer orden; refuerza la salvedad del paso 5.
write.csv(sens, file.path(dir_salida, "sensibilidad_2do_orden_WLSMV.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 7. Diagramas
# -----------------------------------------------------------------------
for (nm in names(fit2)) {
  png(file.path(dir_salida, paste0("diagrama_2do_orden_", nm, ".png")), width = 1400, height = 800)
  semPaths(fit2[[nm]], whatLabels = "std", edge.label.cex = 0.9, layout = "tree2")
  dev.off()
}
