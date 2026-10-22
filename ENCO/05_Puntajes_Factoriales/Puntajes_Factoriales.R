# =============================================================================
# Libro SEM · ENCO
# 05 - Puntajes factoriales: Confianza del consumidor
# =============================================================================
# Sin referencia: el documento de INEGI no trae puntajes factoriales. Se calculan
# los puntajes de los cuatro factores y del factor general (segundo orden) y se
# comparan con un promedio simple de los ítems, como el indicador de INEGI (el
# ICC promedia cinco de estas preguntas). Aquí SÍ se usa el ponderador FACTOR, que
# es donde corresponde: para estimar medias de la población, no para el modelo.
#   source("ENCO/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(foreign)
library(lavaan)

dir_salida <- "ENCO/05_Puntajes_Factoriales/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos y modelo de segundo orden (igual que en 03)
# -----------------------------------------------------------------------
# merge() reordena las filas por llave: de aquí en adelante TODO sale de `enco`.
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
cs <- read.dbf("ENCO/data/encocs_0826.DBF", as.is = TRUE)
llave <- c("FOL", "CVE_ENT", "CON", "V_SEL", "N_HOG", "H_MUD", "N_REN")
enco <- merge(cb, cs[, c(llave, "SEX", "EDA")], by = llave)
items <- paste0("P", 1:15)
codigo_NS <- c(P1 = 6, P2 = 6, P3 = 6, P4 = 6, P5 = 6, P6 = 6, P7 = 4, P8 = 4, P9 = 3, P10 = 3,
               P11 = 6, P12 = 7, P13 = 6, P14 = 4, P15 = 4)
maximo    <- c(P1 = 5, P2 = 5, P3 = 5, P4 = 5, P5 = 5, P6 = 5, P7 = 3, P8 = 3, P9 = 2, P10 = 2,
               P11 = 5, P12 = 6, P13 = 5, P14 = 3, P15 = 3)
x <- enco[, items]
x[] <- lapply(x, as.integer)
for (v in items) x[[v]][x[[v]] == codigo_NS[[v]]] <- NA
x$P10[enco$P10 == "4"] <- NA
for (v in items) x[[v]] <- maximo[[v]] + 1L - x[[v]]

modelo <- '
  HOGA =~ P1 + P3
  HOGE =~ P2 + P4
  PAIS =~ P5 + P6 + P12 + P13
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15
  CONF =~ HOGA + HOGE + PAIS + CONS'
fit <- cfa(modelo, data = x, ordered = items, estimator = "WLSMV", missing = "pairwise")

# -----------------------------------------------------------------------
# Paso 2. Puntajes (EBM, el método de lavaan para ítems ordinales)
# -----------------------------------------------------------------------
# Con missing = "pairwise" cada persona recibe puntaje aunque haya contestado "No
# sabe" en algún ítem: las 2,050. Tarda unos 40 segundos.
puntajes <- as.data.frame(lavPredict(fit, method = "EBM"))
dim(puntajes)                                # 2,050 x 5 (HOGA, HOGE, PAIS, CONS, CONF)
colSums(is.na(puntajes))                     # 0
round(sapply(puntajes, function(z) c(media = mean(z), de = sd(z), min = min(z), max = max(z))), 2)
# Media cercana a 0 y desviación de .6 a .8: la escala es la de un factor con
# varianza 1, y el puntaje (que se encoge hacia la media) es menos variable.
round(cor(puntajes), 2)                      # entre factores de .67 a .87 (los latentes, de .54 a .79); CONF con CONS, .98

# -----------------------------------------------------------------------
# Paso 3. Contra un promedio simple de los ítems
# -----------------------------------------------------------------------
# Los ítems se reescalan a 0-1 (dividiendo entre su máximo) para promediarlos. El del
# ICC usa las cinco preguntas del indicador de INEGI (P3, P4, P5, P6 y P8), pero NO
# es su fórmula oficial (que no está en estos archivos).
reescala <- function(v) x[[v]] / maximo[[v]]
promedio15 <- rowMeans(sapply(items, reescala), na.rm = TRUE)
promedio5  <- rowMeans(sapply(c("P3", "P4", "P5", "P6", "P8"), reescala), na.rm = TRUE)
comparacion <- data.frame(
  contra = c("Promedio simple de los 15 ítems", "Promedio simple de los 5 ítems del ICC (P3, P4, P5, P6, P8)"),
  r = round(c(cor(puntajes$CONF, promedio15), cor(puntajes$CONF, promedio5)), 3))
comparacion
# CONF correlaciona .971 con el promedio simple de los 15 ítems y .904 con el de los cinco del
# ICC: el puntaje factorial y el promedio dicen casi lo mismo; el factorial pondera cada ítem
# por su carga (P12, con .48, pesa menos) y el promedio los trata por igual.
write.csv(comparacion, file.path(dir_salida, "comparacion_indices.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. ¿Tiene sentido el puntaje? Promedio por edad y sexo, con y sin ponderador
# -----------------------------------------------------------------------
# La confianza debe bajar con la edad. El ponderador FACTOR (población de 18+) da
# la media de la POBLACIÓN; sin él es la media de la muestra.
edad <- as.numeric(enco$EDA)
grupo_edad <- cut(edad, c(17, 29, 44, 59, Inf), labels = c("18-29", "30-44", "45-59", "60+"))
sexo <- factor(enco$SEX, levels = c("1", "2"), labels = c("Hombre", "Mujer"))
w <- as.numeric(enco$FACTOR)
media_por <- function(g) data.frame(grupo = levels(g), n = as.numeric(table(g)),
  muestra = round(as.numeric(tapply(puntajes$CONF, g, mean)), 2),
  poblacion = round(sapply(levels(g), function(n) weighted.mean(puntajes$CONF[g == n], w[g == n])), 2),
  row.names = NULL)
por_grupo <- rbind(cbind(variable = "Edad", media_por(grupo_edad)), cbind(variable = "Sexo", media_por(sexo)))
por_grupo
# La confianza baja con la edad (de .35 a -.25) y los hombres puntúan más alto (.11 contra
# -.07). Con ponderador (población) los promedios cambian en .03 o menos: la media de la
# muestra y la de la población casi coinciden en estos grupos.
write.csv(por_grupo, file.path(dir_salida, "confianza_por_grupo.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Guardar los puntajes con la llave de la persona
# -----------------------------------------------------------------------
# La persona se identifica con las siete variables de identificación (no hay un id único).
salida <- data.frame(enco[, llave], puntajes)
write.csv(salida, file.path(dir_salida, "puntajes_confianza.csv"), row.names = FALSE)
head(salida)
