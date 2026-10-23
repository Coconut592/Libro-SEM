# =============================================================================
# Libro SEM · ENBIARE
# 06 - Invarianza factorial por tamaño de localidad (AFC multigrupo)
# =============================================================================
# Sin referencia: no hay invarianza publicada de la ENBIARE. Se sigue la secuencia estándar
# (Meredith, 1993; Vandenberg y Lance, 2000; Chen, 2007): configural -> métrica -> escalar
# -> estricta, para los modelos de primer orden de satisfacción y confianza, y la de Chen,
# Sousa y West (2005) para el segundo orden.
# La base NO trae sexo ni edad (los grupos habituales): el grupo es el tamaño de localidad
# (`tloc`, 4 grupos de 4,793 a 14,095 personas).
#   source("ENBIARE/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(lavaan)

dir_salida <- "ENBIARE/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, modelos y grupos
# -----------------------------------------------------------------------
enb <- read.csv("ENBIARE/data/conjunto_de_datos_tenbiare_enbiare_2021.csv",
                fileEncoding = "latin1", na.strings = c("", " "), quote = "\"",
                comment.char = "", stringsAsFactors = FALSE)
names(enb) <- tolower(names(enb))

# tloc no trae etiquetas: se supone 1 = localidades de 100 mil habitantes o más ... 4 = menos de 2,500.
enb$tloc_g <- factor(enb$tloc, levels = 1:4, labels = paste0("tloc", 1:4))
table(enb$tloc_g)                            # 14,095 / 4,793 / 4,925 / 7,353
# lavaan numera los grupos en el orden en que aparecen en los datos (no por los niveles del
# factor): se ordena para que el grupo 1 (referencia, media latente 0) sea tloc1.
enb <- enb[order(enb$tloc_g), ]

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
m_sat_2o  <- paste(m_sat,  "SAT =~ NIV + REL + AUT + BAR + CIU", sep = "\n")
m_conf_2o <- paste(m_conf, "CONF =~ POL + MIL + JUS + PLT", sep = "\n")

# MLR por la asimetría de las escalas 0-10 (ver 02). No hay faltantes: FIML no cambiaría nada.
medidas <- c("chisq.scaled", "df", "pvalue.scaled", "cfi.robust", "tli.robust", "rmsea.robust", "srmr")

# -----------------------------------------------------------------------
# Paso 2. Requisito: el modelo debe ajustar en cada grupo por separado
# -----------------------------------------------------------------------
por_grupo <- do.call(rbind, lapply(c("SAT", "CONF"), function(nm) {
  m <- if (nm == "SAT") m_sat else m_conf
  do.call(rbind, lapply(levels(enb$tloc_g), function(g) {
    f <- suppressWarnings(cfa(m, data = enb[enb$tloc_g == g, ], estimator = "MLR"))
    x <- fitMeasures(f, c("cfi.robust", "tli.robust", "rmsea.robust", "srmr"))
    data.frame(escala = nm, grupo = g, N = lavInspect(f, "nobs"), CFI = round(x[1], 3), TLI = round(x[2], 3),
               RMSEA = round(x[3], 3), SRMR = round(x[4], 3),
               admisible = suppressWarnings(lavInspect(f, "post.check")), row.names = NULL)
  }))
}))
por_grupo
# SAT: CFI de .943 a .958 y RMSEA de .046 a .050; CONF: CFI de .959 a .975 y RMSEA de .080 a .099 (el RMSEA
# alto de siempre, ver 02). Los ocho ajustan parecido (el más flojo, SAT en tloc4) y son admisibles.
write.csv(por_grupo, file.path(dir_salida, "ajuste_por_grupo.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Secuencia de modelos anidados (primer orden)
# -----------------------------------------------------------------------
# group.equal agrega restricciones de igualdad entre los 4 grupos.
secuencia <- function(modelo) {
  ajustar <- function(...) suppressWarnings(cfa(modelo, data = enb, group = "tloc_g", estimator = "MLR", ...))
  list(configural = ajustar(),
       metrica    = ajustar(group.equal = "loadings"),
       escalar    = ajustar(group.equal = c("loadings", "intercepts")),
       estricta   = ajustar(group.equal = c("loadings", "intercepts", "residuals")))
}
mod_sat  <- secuencia(m_sat)
mod_conf <- secuencia(m_conf)
stopifnot(identical(lavInspect(mod_sat$configural, "group.label"), levels(enb$tloc_g)))

# -----------------------------------------------------------------------
# Paso 4. Comparar los modelos
# -----------------------------------------------------------------------
# - Diferencia de χ² escalada (Satorra-Bentler), por usar MLR.
# - Chen (2007): se acepta el nivel si el CFI no baja más de .010 y el RMSEA no sube más de .015
#   respecto al modelo anterior (con muestras grandes y desiguales, como aquí, se mira además .005).
# Los cambios se calculan con los índices sin redondear.
tabla_ajuste <- function(modelos, med = medidas) {
  ajuste <- t(sapply(modelos, fitMeasures, med))
  cfi <- ajuste[, "cfi.robust"]; rmsea <- ajuste[, "rmsea.robust"]
  out <- cbind(round(ajuste, 3), delta_cfi = round(c(NA, diff(cfi)), 3), delta_rmsea = round(c(NA, diff(rmsea)), 3))
  out
}
ajuste_sat  <- tabla_ajuste(mod_sat);  ajuste_sat
ajuste_conf <- tabla_ajuste(mod_conf); ajuste_conf
# SAT: configural CFI .953; métrica .952 (-.001); escalar .942 (-.010, justo en el límite; ΔRMSEA +.003);
# estricta .927 (-.015, no pasa). CONF: configural .967; métrica .967 (.000); escalar .967 (-.001); estricta
# .964 (-.003): pasan las cuatro (y el RMSEA baja de .089 a .076).
lavTestLRT(mod_sat$configural, mod_sat$metrica, mod_sat$escalar, mod_sat$estricta, method = "satorra.bentler.2001")
lavTestLRT(mod_conf$configural, mod_conf$metrica, mod_conf$escalar, mod_conf$estricta, method = "satorra.bentler.2001")
# Con 31 mil casos la χ² rechaza hasta lo más pequeño (SAT, todos los pasos p < .001; CONF, la métrica
# p = .016 y los demás p < .001): se juzga con Chen.

# -----------------------------------------------------------------------
# Paso 5. Satisfacción: invarianza escalar parcial
# -----------------------------------------------------------------------
# La escalar de SAT pasa justo en el límite (ΔCFI -.010) y la estricta no. Se busca qué interceptos
# se alejan más (prueba score sobre las restricciones de la escalar) y se liberan de uno en uno.
nombre_param <- function(f) { pt <- parTable(f); setNames(paste(pt$lhs, pt$op), pt$plabel) }
ts_esc <- suppressWarnings(lavTestScore(mod_sat$escalar)$uni)
np <- nombre_param(mod_sat$escalar)
ts_esc$par <- np[ts_esc$lhs]
ts_int <- ts_esc[grepl("^pa3_[0-9]+ ~1$", ts_esc$par), ]
agr <- aggregate(X2 ~ par, ts_int, max)
head(agr[order(-agr$X2), ], 6)
# Los mayores: pa3_16 (servicios públicos, X² = 497), pa3_11 (seguridad, 301), pa3_13 y pa3_14 (vivienda y
# vecindario, 178 cada uno), pa3_10 (libertad, 108) y pa3_04 (64). Los dos primeros son de ciudad y país.

# Se liberan, acumulando, los 1, 2 y 3 peores interceptos y se mira el CFI contra la métrica.
orden <- agr$par[order(-agr$X2)]
parcial <- lapply(1:3, function(k) {
  libres <- orden[1:k]
  f <- suppressWarnings(cfa(m_sat, data = enb, group = "tloc_g", estimator = "MLR",
                            group.equal = c("loadings", "intercepts"), group.partial = libres))
  list(libres = libres, fit = f)
})
cfi_metrica <- fitMeasures(mod_sat$metrica, "cfi.robust"); rmsea_metrica <- fitMeasures(mod_sat$metrica, "rmsea.robust")
tabla_parcial <- do.call(rbind, lapply(1:3, function(k) {
  x <- fitMeasures(parcial[[k]]$fit, c("cfi.robust", "rmsea.robust", "srmr"))
  data.frame(interceptos_libres = paste(sub(" ~1", "", parcial[[k]]$libres), collapse = ", "),
             CFI = round(x[1], 3), RMSEA = round(x[2], 3), SRMR = round(x[3], 3),
             dCFI_vs_metrica = round(x[1] - cfi_metrica, 3), dRMSEA_vs_metrica = round(x[2] - rmsea_metrica, 3), row.names = NULL)
}))
tabla_parcial
# Liberar pa3_16 deja el CFI en .947 (-.005 contra la métrica); con pa3_11, .948 (-.004); con pa3_14, .950
# (-.002): liberando 1 a 3 de los 17 interceptos, la invarianza escalar parcial se sostiene con holgura.
write.csv(tabla_parcial, file.path(dir_salida, "invarianza_parcial_SAT.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 6. Diferencias en las medias latentes (modelo escalar)
# -----------------------------------------------------------------------
# Con invarianza escalar se pueden comparar las medias de los factores: la de tloc1 se fija en 0 y
# las de los otros tres grupos se estiman. d = diferencia / desviación típica del factor en tloc1.
medias_latentes <- function(modelos, factores) {
  f <- modelos$escalar
  pe <- parameterEstimates(f); lv1 <- diag(lavInspect(f, "cov.lv")[[1]])
  m <- pe[pe$op == "~1" & pe$lhs %in% factores & pe$group > 1, c("lhs", "group", "est", "se", "z", "pvalue")]
  m$grupo <- levels(enb$tloc_g)[m$group]; m$d <- round(m$est / sqrt(lv1[m$lhs]), 2)
  m[, c("lhs", "grupo", "est", "se", "z", "pvalue", "d")]
}
dif_sat  <- medias_latentes(mod_sat,  c("NIV", "REL", "AUT", "BAR", "CIU"))
dif_conf <- medias_latentes(mod_conf, c("INT", "POL", "MIL", "JUS", "PLT"))
dif_sat[, c("est", "se", "z", "pvalue")]  <- round(dif_sat[, c("est", "se", "z", "pvalue")], 3)
dif_conf[, c("est", "se", "z", "pvalue")] <- round(dif_conf[, c("est", "se", "z", "pvalue")], 3)
dif_sat; dif_conf
# SAT (contra tloc1): en tloc4, nivel de vida y logros baja .45 (d = -.33), autonomía .16 (-.13), relaciones .14
# (-.10) y hogar y vecindario .09 (-.08); ciudad y país SUBE .28 (+.16). En tloc2 y tloc3, |d| <= .16. Ojo: los
# interceptos que menos se sostienen son los de ciudad y país (pa3_16 y pa3_11), así que esa media se lee con cautela.
# CONF: sube al bajar el tamaño de la localidad (como en 05): en tloc4, fuerzas armadas +.72 (d = .25),
# justicia +.73 (.27), política +.89 (.34), policías +.47 (.19); la confianza interpersonal BAJA un poco (d = -.07 a -.12).

# -----------------------------------------------------------------------
# Paso 7. Invarianza de los modelos de segundo orden
# -----------------------------------------------------------------------
# Secuencia (Chen, Sousa y West, 2005):
#  1 configural
#  2 cargas de primer orden iguales
#  3 + cargas de segundo orden iguales
#  4 + interceptos de los ítems iguales
#  5 + interceptos de las dimensiones iguales (la media del general queda libre en los grupos 2 a 4: así
#      se estiman las diferencias en SAT / CONF)
#  6 + varianzas residuales de los ítems iguales
#  7 + varianzas residuales de las dimensiones (disturbios) iguales
# En lavaan "loadings" incluye las de segundo orden; para separar el paso 2 se liberan con group.partial.
segundo_orden <- function(modelo, general, dimensiones, libres_2do, extra_media = "") {
  ajustar <- function(m = modelo, ...) suppressWarnings(cfa(m, data = enb, group = "tloc_g", estimator = "MLR", ...))
  fija0 <- paste(paste0(dimensiones, " ~ 0*1"), collapse = "; ")
  m_int <- paste(modelo, fija0, paste0(general, " ~ c(0, NA, NA, NA)*1"), extra_media, sep = "\n")
  list(`1 configural`            = ajustar(),
       `2 cargas 1er orden`      = ajustar(group.equal = "loadings", group.partial = libres_2do),
       `3 + cargas 2do orden`    = ajustar(group.equal = "loadings"),
       `4 + interceptos ítems`   = ajustar(group.equal = c("loadings", "intercepts")),
       `5 + interceptos dimens.` = ajustar(m_int, group.equal = c("loadings", "intercepts")),
       `6 + residuos ítems`      = ajustar(m_int, group.equal = c("loadings", "intercepts", "residuals")),
       `7 + disturbios`          = ajustar(m_int, group.equal = c("loadings", "intercepts", "residuals", "lv.variances")))
}
# SAT: la carga marcadora de NIV queda fija en 1; se liberan las otras 4
mod2_sat <- segundo_orden(m_sat_2o, "SAT", c("NIV", "REL", "AUT", "BAR", "CIU"),
                          c("SAT =~ REL", "SAT =~ AUT", "SAT =~ BAR", "SAT =~ CIU"))
# CONF: INT no cuelga del general; su media se libera en los grupos 2 a 4 como la del general
mod2_conf <- segundo_orden(m_conf_2o, "CONF", c("POL", "MIL", "JUS", "PLT"),
                           c("CONF =~ MIL", "CONF =~ JUS", "CONF =~ PLT"), extra_media = "INT ~ c(0, NA, NA, NA)*1")
ajuste2_sat  <- tabla_ajuste(mod2_sat);  ajuste2_sat
ajuste2_conf <- tabla_ajuste(mod2_conf); ajuste2_conf
lavTestLRT(mod2_sat[[1]], mod2_sat[[2]], mod2_sat[[3]], mod2_sat[[4]], mod2_sat[[5]], mod2_sat[[6]], mod2_sat[[7]],
           method = "satorra.bentler.2001")
lavTestLRT(mod2_conf[[1]], mod2_conf[[2]], mod2_conf[[3]], mod2_conf[[4]], mod2_conf[[5]], mod2_conf[[6]], mod2_conf[[7]],
           method = "satorra.bentler.2001")
# SAT: configural CFI .938; cargas de 1er orden -.001; cargas de 2.º orden .000; interceptos de los ítems -.010
# (en el límite); interceptos de las dimensiones -.004; residuos de los ítems -.014 (NO pasa); disturbios -.004.
# CONF: configural .961 y ningún paso baja más de .003 (los siete pasos pasan, hasta los disturbios iguales).
# La χ² rechaza todos los pasos (p < .01), como siempre con 31 mil casos.

# Diferencias en el factor general (modelo del paso 5: interceptos de las dimensiones iguales)
dif_general <- function(modelos, general) {
  f <- modelos[[5]]; pe <- parameterEstimates(f); lv1 <- sqrt(lavInspect(f, "cov.lv")[[1]][general, general])
  m <- pe[pe$op == "~1" & pe$lhs == general & pe$group > 1, c("lhs", "group", "est", "se", "z", "pvalue")]
  m$grupo <- levels(enb$tloc_g)[m$group]; m$d <- round(m$est / lv1, 2)
  m[, c("lhs", "grupo", "est", "se", "z", "pvalue", "d")]
}
dg <- rbind(dif_general(mod2_sat, "SAT"), dif_general(mod2_conf, "CONF"))
dg[, c("est", "se", "z", "pvalue")] <- round(dg[, c("est", "se", "z", "pvalue")], 3)
dg
# SAT contra tloc1: tloc2 -.07 (d = -.06), tloc3 -.11 (-.08), tloc4 -.22 (-.17). CONF: +.20 (.09), +.41 (.19), +.65 (.30).
# La satisfacción general casi no cambia con el tamaño de localidad; la confianza institucional sube de a poco hasta
# tres décimas de desviación en las localidades más chicas.

# -----------------------------------------------------------------------
# Paso 8. Guardar resultados
# -----------------------------------------------------------------------
write.csv(cbind(modelo = rownames(ajuste_sat), ajuste_sat),   file.path(dir_salida, "ajuste_invarianza_SAT.csv"), row.names = FALSE)
write.csv(cbind(modelo = rownames(ajuste_conf), ajuste_conf), file.path(dir_salida, "ajuste_invarianza_CONF.csv"), row.names = FALSE)
write.csv(cbind(modelo = rownames(ajuste2_sat), ajuste2_sat), file.path(dir_salida, "ajuste_invarianza_2do_orden_SAT.csv"), row.names = FALSE)
write.csv(cbind(modelo = rownames(ajuste2_conf), ajuste2_conf), file.path(dir_salida, "ajuste_invarianza_2do_orden_CONF.csv"), row.names = FALSE)
write.csv(rbind(cbind(escala = "SAT", dif_sat), cbind(escala = "CONF", dif_conf)),
          file.path(dir_salida, "medias_latentes_primer_orden.csv"), row.names = FALSE)
write.csv(dg, file.path(dir_salida, "medias_latentes_general.csv"), row.names = FALSE)
