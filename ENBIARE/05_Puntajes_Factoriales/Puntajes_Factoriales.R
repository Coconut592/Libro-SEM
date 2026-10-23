# =============================================================================
# Libro SEM · ENBIARE
# 05 - Puntajes factoriales
# =============================================================================
# Sin referencia: no hay puntajes publicados. Se calculan, con los modelos de segundo
# orden de 03, los puntajes de los factores de primer orden y de los generales (satisfacción
# con la vida y confianza institucional), su determinación, la comparación con medias
# simples, una versión en escala 0-10 y las medias por tamaño de localidad y entidad
# (con y sin el ponderador, que es donde sí se usa).
#   source("ENBIARE/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(lavaan)
library(ggplot2)

dir_salida <- "ENBIARE/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelos de segundo orden (los de 03)
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
  CIU =~ pa3_11 + pa3_15 + pa3_16 + pa3_17
  SAT =~ NIV + REL + AUT + BAR + CIU'
m_conf <- '
  INT =~ pb1_01 + pb1_02
  POL =~ pb1_04 + pb1_05
  MIL =~ pb1_06 + pb1_07
  JUS =~ pb1_08 + pb1_09
  PLT =~ pb1_10 + pb1_11 + pb1_12
  CONF =~ POL + MIL + JUS + PLT'
fits <- list(SAT = cfa(m_sat, enb, estimator = "MLR", std.lv = TRUE),
             CONF = cfa(m_conf, enb, estimator = "MLR", std.lv = TRUE))

# -----------------------------------------------------------------------
# Paso 2. Puntajes por regresión
# -----------------------------------------------------------------------
# lavPredict(method = "regression") es el método de Mplus: puntajes con media 0 (centrados).
# Como el modelo es de segundo orden, devuelve los de los factores de primer orden y el del general.
# No hay faltantes: las 31,166 personas reciben puntaje de todos los factores.
fs <- lapply(fits, lavPredict, method = "regression")
puntajes <- cbind(fs$SAT, fs$CONF)
dim(puntajes)                                # 31,166 x 12
colSums(is.na(puntajes))                     # 0
resumen <- t(round(sapply(as.data.frame(puntajes), function(x) c(media = mean(x), de = sd(x), min = min(x), max = max(x))), 2))
resumen
# Media 0 y desviaciones de .87 a 2.53. Cada puntaje está en la métrica de su factor: los generales
# (SAT, CONF) tienen varianza 1 (de ahí .91 y .95, por el encogimiento de la regresión) y los de primer
# orden, la varianza que les da el modelo (1 más lo que aporta el general; de ahí desviaciones de 1.1 a 2.5).
# Los mínimos muy bajos (NIV -14.7, AUT -13.1) son las pocas personas que contestaron 0 a casi todo.
write.csv(resumen, file.path(dir_salida, "resumen_puntajes.csv"))

# -----------------------------------------------------------------------
# Paso 3. Determinación de los puntajes (FSDETERMINACY)
# -----------------------------------------------------------------------
# Correlación entre el puntaje estimado y el factor verdadero:
#   ρ = sqrt( diag(Φ Λ' Σ⁻¹ Λ Φ) / diag(Φ) ), con Φ la covarianza de TODOS los factores
# (en un modelo de segundo orden, Φ = (I - B)⁻¹ Ψ (I - B)⁻ᵀ). >= .90 = confiable.
determinacion <- function(fit) {
  est <- lavInspect(fit, "est"); Sigma <- lavInspect(fit, "implied")$cov
  Lam <- est$lambda; IB <- solve(diag(nrow(est$beta)) - est$beta)
  Phi <- IB %*% est$psi %*% t(IB)
  sqrt(diag(Phi %*% t(Lam) %*% solve(Sigma) %*% Lam %*% Phi) / diag(Phi))
}
det_todas <- c(determinacion(fits$SAT), determinacion(fits$CONF))
det_tab <- data.frame(factor = colnames(puntajes), determinacion = round(det_todas[colnames(puntajes)], 3), row.names = NULL)
det_tab$nivel <- cut(det_tab$determinacion, c(0, .80, .90, 1), labels = c("< .80", ".80-.90", ">= .90"))
det_tab
# Generales: SAT .913 y CONF .950. Primer orden: de .84 (BAR, 2 ítems) a .97 (POL). Ocho de los doce
# llegan a .90 (NIV, REL, SAT, POL, MIL, JUS, PLT y CONF); AUT, BAR, CIU e INT quedan entre .80 y .90 y
# ninguno baja de .80.
write.csv(det_tab, file.path(dir_salida, "determinacion.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Contra medias simples de los ítems
# -----------------------------------------------------------------------
items_f <- list(NIV = c("pa3_01", "pa3_02", "pa3_03", "pa3_08"), REL = sprintf("pa3_%02d", 4:7),
                AUT = c("pa3_09", "pa3_10", "pa3_12"), BAR = c("pa3_13", "pa3_14"),
                CIU = c("pa3_11", "pa3_15", "pa3_16", "pa3_17"), SAT = sprintf("pa3_%02d", 1:17),
                INT = c("pb1_01", "pb1_02"), POL = c("pb1_04", "pb1_05"), MIL = c("pb1_06", "pb1_07"),
                JUS = c("pb1_08", "pb1_09"), PLT = sprintf("pb1_%02d", 10:12), CONF = sprintf("pb1_%02d", 4:12))
media_simple <- sapply(items_f, function(it) rowMeans(enb[, it]))
comparacion <- data.frame(factor = names(items_f),
  r_con_media_simple = round(sapply(names(items_f), function(f) cor(puntajes[, f], media_simple[, f])), 3), row.names = NULL)
comparacion
# El puntaje correlaciona de .92 (AUT) a .99 (PLT y CONF) con la media simple de sus ítems (SAT .97):
# con cargas parecidas, el promedio y el puntaje ordenan casi igual.
write.csv(comparacion, file.path(dir_salida, "comparacion_media_simple.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Puntajes en escala original (0-10): media ponderada por las cargas
# -----------------------------------------------------------------------
# Cálculo del Lab 5: media ponderada = Σ(peso * ítem) / Σ(peso). Para un factor de primer orden el
# peso de cada ítem es su carga sin estandarizar; para el general, la carga del ítem por la del
# factor de primer orden en el general. El resultado vive en la escala 0-10 de las preguntas.
pesos_general <- function(fit, general) {
  est <- lavInspect(fit, "est"); gam <- est$beta[, general]; gam <- gam[gam != 0]
  Lam <- est$lambda[, names(gam), drop = FALSE]
  w <- Lam %*% gam; w[w[, 1] != 0, 1]       # peso de cada ítem del general (λ * γ)
}
w_sat <- pesos_general(fits$SAT, "SAT"); w_conf <- pesos_general(fits$CONF, "CONF")
ponderada <- function(it, w) as.numeric(as.matrix(enb[, it]) %*% w[it] / sum(w[it]))
escala10 <- data.frame(SAT_0_10 = ponderada(names(w_sat), w_sat), CONF_0_10 = ponderada(names(w_conf), w_conf))
round(sapply(escala10, function(x) c(media = mean(x), de = sd(x), min = min(x), max = max(x))), 2)
# SAT_0_10: media 8.03, de 1.20; CONF_0_10: media 4.79, de 2.47.
round(cor(escala10$SAT_0_10, puntajes[, "SAT"]), 3); round(cor(escala10$CONF_0_10, puntajes[, "CONF"]), 3)   # .978 y .995

# -----------------------------------------------------------------------
# Paso 6. Medias por tamaño de localidad y por entidad, con y sin ponderador
# -----------------------------------------------------------------------
# Aquí sí se pondera: la media de la población no es la de la muestra (los pesos van de 122
# a 45,955). Se reportan las dos. No se calculan errores estándar de diseño (haría falta el paquete
# survey con estrato y UPM); con 31 mil casos y pocas UPM por grupo, las diferencias pequeñas no
# deben leerse como significativas.
d <- data.frame(escala10, puntajes[, c("SAT", "CONF")], tloc = enb$tloc, ent = enb$ent, peso = enb$fac_ele)
media_grupo <- function(v, g) {
  data.frame(grupo = sort(unique(d[[g]])),
             sin_peso = round(as.numeric(tapply(d[[v]], d[[g]], mean)), 2),
             ponderada = round(sapply(sort(unique(d[[g]])), function(k) weighted.mean(d[[v]][d[[g]] == k], d$peso[d[[g]] == k])), 2),
             n = as.numeric(table(d[[g]])))
}
por_tloc <- rbind(cbind(variable = "SAT_0_10", media_grupo("SAT_0_10", "tloc")),
                  cbind(variable = "CONF_0_10", media_grupo("CONF_0_10", "tloc")))
por_tloc
c(SAT_sin_peso = round(mean(d$SAT_0_10), 2), SAT_ponderada = round(weighted.mean(d$SAT_0_10, d$peso), 2),
  CONF_sin_peso = round(mean(d$CONF_0_10), 2), CONF_ponderada = round(weighted.mean(d$CONF_0_10, d$peso), 2))
# Nacional: SAT 8.03 sin ponderar y 8.01 ponderada; CONF 4.79 y 4.65. Por tamaño de localidad la
# satisfacción casi no varía (ponderada, de 7.98 a 8.07) y la confianza institucional SÍ: sube de 4.33 en las
# localidades de tamaño 1 a 5.16 en las de tamaño 4 (sin etiquetas: se supone de las más grandes a las
# más chicas). Ponderar baja la confianza hasta .2: las localidades grandes pesan más en la población.
write.csv(por_tloc, file.path(dir_salida, "medias_por_tloc.csv"), row.names = FALSE)

# Catálogo de entidades de INEGI (el diccionario de la ENBIARE no trae etiquetas de valor)
entidades <- c("Aguascalientes", "Baja California", "Baja California Sur", "Campeche", "Coahuila", "Colima",
               "Chiapas", "Chihuahua", "Ciudad de México", "Durango", "Guanajuato", "Guerrero", "Hidalgo",
               "Jalisco", "México", "Michoacán", "Morelos", "Nayarit", "Nuevo León", "Oaxaca", "Puebla",
               "Querétaro", "Quintana Roo", "San Luis Potosí", "Sinaloa", "Sonora", "Tabasco", "Tamaulipas",
               "Tlaxcala", "Veracruz", "Yucatán", "Zacatecas")
por_ent <- cbind(media_grupo("SAT_0_10", "ent")[, c("grupo", "sin_peso", "ponderada", "n")],
                 conf_ponderada = media_grupo("CONF_0_10", "ent")$ponderada)
names(por_ent)[1:3] <- c("ent", "SAT_sin_peso", "SAT_ponderada"); por_ent$entidad <- entidades[por_ent$ent]
por_ent <- por_ent[order(-por_ent$SAT_ponderada), ]
head(por_ent, 5); tail(por_ent, 5)
# Mayor satisfacción ponderada: Coahuila (8.43), Nuevo León (8.38), Colima (8.36), Nayarit (8.35) y Sinaloa
# (8.29). Menor: Puebla (7.68), Ciudad de México (7.72), Tabasco y Oaxaca (7.83) y Tlaxcala (7.85). De la
# primera a la última, .75 puntos en la escala 0-10. La confianza institucional más baja es la de la
# Ciudad de México (3.53).
write.csv(por_ent, file.path(dir_salida, "medias_por_entidad.csv"), row.names = FALSE)

g <- ggplot(por_ent, aes(SAT_ponderada, reorder(entidad, SAT_ponderada))) + geom_point() +
  geom_vline(xintercept = weighted.mean(d$SAT_0_10, d$peso), linetype = 2) +
  labs(x = "Satisfacción con la vida (0-10, media ponderada)", y = NULL, title = "Satisfacción por entidad")
ggsave(file.path(dir_salida, "satisfaccion_por_entidad.png"), g, width = 7, height = 7)

# -----------------------------------------------------------------------
# Paso 7. Guardar los puntajes con la llave de la persona
# -----------------------------------------------------------------------
# La llave es (folio, hogar): folio es la vivienda y se repite cuando hay varios hogares.
salida <- data.frame(folio = enb$folio, hogar = enb$hogar, round(puntajes, 4), escala10)
write.csv(salida, file.path(dir_salida, "puntajes_ENBIARE.csv"), row.names = FALSE)
head(salida)
