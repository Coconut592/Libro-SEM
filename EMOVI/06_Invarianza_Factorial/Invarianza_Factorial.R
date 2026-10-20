# =============================================================================
# Libro SEM · EMOVI
# 06 - Invarianza factorial: Riqueza del hogar de origen
# =============================================================================
# Referencia: la tesis compara los coeficientes del SEM entre mujeres y hombres y
# entre 25-40 y 41-64 años con pruebas de Wald, pero NO prueba antes que las
# escalas se miden igual en esos grupos. Este ejercicio llena ese hueco para la
# riqueza del hogar de origen, con los mismos grupos.
#   source("EMOVI/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "EMOVI/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, modelo (igual que en 02_AFC) y grupos
# -----------------------------------------------------------------------
emovi <- read.dta13("EMOVI/data/entrevistado_2023_CDMX.dta", convert.factors = FALSE)
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
for (v in riqueza) emovi[[v]] <- ifelse(emovi[[v]] == 1, 1, ifelse(emovi[[v]] == 2, 0, NA))

modelo <- '
  ESP =~ p29a + p29b + p29c + p29d + p29e + p29f + p26e + p31f + p31g + p32a
  BAS =~ p26a + p26c + p26d + p29g + p31a + p31b + p31c + p31d + p31e + p31m + p31o + p32e + p32f + p32h
  TEC =~ p31h + p31i + p31j + p31k + p31l'
items <- unlist(regmatches(modelo, gregexpr("p[0-9]+[a-o]", modelo)))

# Los grupos de la tesis. sexo: 1 = hombre, 2 = mujer (diccionario 2023).
emovi$sexo_g <- factor(emovi$sexo, levels = 1:2, labels = c("Hombre", "Mujer"))
emovi$edad_g <- factor(ifelse(emovi$edad <= 40, "25-40", "41-64"))
table(emovi$sexo_g)                          # 318 hombres y 422 mujeres
table(emovi$edad_g)                          # 372 de 25 a 40 y 368 de 41 a 64

# -----------------------------------------------------------------------
# Paso 2. Pasos de la invarianza con ítems binarios
# -----------------------------------------------------------------------
# Con ítems 0/1 los umbrales y las cargas se restringen juntos (Millsap y Tein,
# 2004): si el umbral y la carga de un ítem son iguales, el ítem funciona igual.
#   Configural:          misma estructura, todo libre
#   Umbrales + cargas:   umbrales y cargas iguales (equivale a la métrica y escalar juntas)
# Criterio de Chen (2007): ΔCFI de -.010 o menos y ΔRMSEA de .015 o menos.
medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
invarianza <- function(grupo) {
  conf <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise")
  rest <- cfa(modelo, data = emovi, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise",
              group.equal = c("thresholds", "loadings"))
  m <- rbind(round(fitMeasures(conf, medidas), 3), round(fitMeasures(rest, medidas), 3))
  lrt <- suppressMessages(lavTestLRT(conf, rest))   # diferencia de chi2 escalada (Satorra, 2000)
  tabla <- data.frame(grupo = grupo, modelo = c("Configural", "Umbrales + cargas"), m,
                      row.names = NULL)
  names(tabla)[3:8] <- c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR")
  tabla$dCFI <- c(NA, round(tabla$CFI[2] - tabla$CFI[1], 3))
  tabla$dRMSEA <- c(NA, round(tabla$RMSEA[2] - tabla$RMSEA[1], 3))
  tabla$p_LRT <- c(NA, round(lrt$`Pr(>Chisq)`[2], 3))
  tabla
}
tabla <- rbind(invarianza("sexo_g"), invarianza("edad_g"))
tabla
# Sexo: ΔCFI = 0, ΔRMSEA = -.001 y la prueba de chi2 no rechaza (p = .50): hay
#   invarianza de umbrales y cargas.
# Edad: ΔCFI = -.002 y ΔRMSEA = .001, dentro del criterio de Chen, pero la prueba
#   de chi2 sí rechaza (p = .001). Con ~370 por grupo y 29 ítems, la chi2 es
#   sensible a diferencias pequeñas: se acepta la invarianza con esta salvedad.
write.csv(tabla, file.path(dir_salida, "invarianza.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Qué hay detrás: ajuste del modelo en cada grupo por separado
# -----------------------------------------------------------------------
# Antes de comparar conviene saber que el modelo ajusta en cada grupo.
por_grupo <- function(variable, nivel) {
  d <- emovi[emovi[[variable]] == nivel, ]
  f <- cfa(modelo, data = d, ordered = items, estimator = "WLSMV", missing = "pairwise")
  m <- round(fitMeasures(f, c("cfi.scaled", "rmsea.scaled", "srmr")), 3)
  data.frame(grupo = nivel, N = nrow(d), CFI = m[1], RMSEA = m[2], SRMR = m[3], row.names = NULL)
}
ajuste_grupos <- rbind(por_grupo("sexo_g", "Hombre"), por_grupo("sexo_g", "Mujer"),
                       por_grupo("edad_g", "25-40"), por_grupo("edad_g", "41-64"))
ajuste_grupos
write.csv(ajuste_grupos, file.path(dir_salida, "ajuste_por_grupo.csv"), row.names = FALSE)
