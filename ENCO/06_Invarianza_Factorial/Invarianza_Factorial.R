# =============================================================================
# Libro SEM · ENCO
# 06 - Invarianza factorial: Confianza del consumidor
# =============================================================================
# Sin referencia: el documento de INEGI no trae invarianza. Antes de comparar la
# confianza entre grupos conviene probar que los 15 ítems miden igual en cada uno.
# Grupos: sexo, edad (18-39 / 40-59 / 60+), escolaridad (hasta secundaria / medio
# superior o más) y gran ciudad (CDMX, Guadalajara, Monterrey) contra el resto.
#   source("ENCO/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(foreign)
library(lavaan)

dir_salida <- "ENCO/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, modelo (igual que en 02_AFC) y grupos
# -----------------------------------------------------------------------
# merge() reordena las filas por llave: de aquí en adelante TODO sale de `enco`.
cb <- read.dbf("ENCO/data/encocb_0826.DBF", as.is = TRUE)
cs <- read.dbf("ENCO/data/encocs_0826.DBF", as.is = TRUE)
llave <- c("FOL", "CVE_ENT", "CON", "V_SEL", "N_HOG", "H_MUD", "N_REN")
enco <- merge(cb, cs[, c(llave, "SEX", "EDA", "I_NIV")], by = llave)
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
  CONS =~ P7 + P8 + P9 + P10 + P11 + P14 + P15'

edad <- as.numeric(enco$EDA)
estudios <- suppressWarnings(as.integer(enco$I_NIV)); estudios[estudios == 99] <- NA   # 0 ninguno ... 9 doctorado
d <- x
d$sexo       <- factor(enco$SEX, levels = c("1", "2"), labels = c("Hombre", "Mujer"))
d$edad_g     <- cut(edad, c(17, 39, 59, Inf), labels = c("18-39", "40-59", "60+"))
d$estudios_g <- cut(estudios, c(-1, 3, 9), labels = c("Hasta secundaria", "Medio superior o más"))
d$ciudad_g   <- factor(ifelse(enco$CD %in% c("01", "02", "03"), "Gran ciudad", "Resto"))
lapply(d[c("sexo", "edad_g", "estudios_g", "ciudad_g")], table)
# Sexo 862 / 1,188; edad 773 / 747 / 530; estudios 769 / 1,279 (2 sin dato); ciudad 766 / 1,284.
# "Medio superior o más" incluye normal y carrera técnica (I_NIV 5 y 6); el PDF no dice si
# requirieron preparatoria.

# -----------------------------------------------------------------------
# Paso 2. ¿Qué grupos se pueden usar? Categorías vacías
# -----------------------------------------------------------------------
# lavaan se detiene si una categoría de un ítem no tiene ningún caso en algún grupo
# (no puede estimar su umbral). P12 NO se funde (decisión del proyecto) y su
# categoría "Disminuirán mucho" tiene solo 5 casos en toda la base: eso limita cuántos
# grupos se pueden formar. Se revisa con otras agrupaciones posibles.
vacias <- function(g) {
  bad <- c()
  for (n in levels(g)) {
    z <- x[which(g == n), ]
    for (v in items) {
      t <- table(factor(z[[v]], levels = 1:maximo[[v]]))
      if (any(t == 0)) bad <- c(bad, sprintf("%s [%s]", v, n))
    }
  }
  if (length(bad)) paste(bad, collapse = ", ") else "ninguna"
}
alternativas <- list(
  "Sexo (2)" = d$sexo, "Edad (3)" = d$edad_g, "Estudios (2)" = d$estudios_g, "Gran ciudad (2)" = d$ciudad_g,
  "Edad (4: 18-29 / 30-44 / 45-59 / 60+)" = cut(edad, c(17, 29, 44, 59, Inf)),
  "Estudios (4: primaria o menos ... superior)" = cut(estudios, c(-1, 2, 3, 6, 9)),
  "Ciudad (4: CDMX / Guadalajara / Monterrey / resto)" =
    factor(ifelse(enco$CD == "01", "CDMX", ifelse(enco$CD == "02", "GDL", ifelse(enco$CD == "03", "MTY", "Resto")))))
revision <- data.frame(agrupacion = names(alternativas), categorias_vacias = sapply(alternativas, vacias), row.names = NULL)
revision
# Las cuatro primeras no tienen categorías vacías y se usan. Las otras tres sí (P12, y P1 y
# P3 en las ciudades por separado): con ellas lavaan se detendría.
write.csv(revision, file.path(dir_salida, "categorias_vacias_por_agrupacion.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Pasos de la invarianza con ítems ordinales
# -----------------------------------------------------------------------
#   Configural:          misma estructura, todo libre
#   Umbrales:            umbrales de cada ítem iguales entre grupos
#   Umbrales + cargas:   además, cargas iguales (equivale a la métrica y escalar juntas)
# Los umbrales y las cargas se restringen juntos (Millsap y Tein, 2004) porque P9 y P10
# son binarios: si el umbral y la carga de un ítem son iguales, el ítem funciona igual.
# Criterio de Chen (2007): ΔCFI de -.010 o menos y ΔRMSEA de .015 o menos, contra el
# configural. Modelo de cuatro factores, WLSMV, missing = "pairwise".
medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
invarianza <- function(grupo) {
  dd <- d[!is.na(d[[grupo]]), ]
  conf <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise")
  umbr <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise",
              group.equal = "thresholds")
  rest <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", group = grupo, missing = "pairwise",
              group.equal = c("thresholds", "loadings"))
  m <- rbind(round(fitMeasures(conf, medidas), 3), round(fitMeasures(umbr, medidas), 3),
             round(fitMeasures(rest, medidas), 3))
  lrt_u <- suppressMessages(lavTestLRT(conf, umbr))       # diferencia de χ² escalada (Satorra, 2000)
  lrt_r <- suppressMessages(lavTestLRT(umbr, rest))
  tabla <- data.frame(grupo = grupo, modelo = c("Configural", "Umbrales", "Umbrales + cargas"), m, row.names = NULL)
  names(tabla)[3:8] <- c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR")
  tabla$dCFI <- c(NA, round(tabla$CFI[2:3] - tabla$CFI[1], 3))
  tabla$dRMSEA <- c(NA, round(tabla$RMSEA[2:3] - tabla$RMSEA[1], 3))
  tabla$p_LRT <- c(NA, round(lrt_u$`Pr(>Chisq)`[2], 3), round(lrt_r$`Pr(>Chisq)`[2], 3))   # cada paso contra el anterior
  tabla
}
tabla <- do.call(rbind, lapply(c("sexo", "edad_g", "estudios_g", "ciudad_g"), invarianza))
tabla
# Con el criterio de Chen hay invarianza de umbrales y cargas en los cuatro grupos: ΔCFI de
# -.001 a +.004 (el CFI escalado de WLSMV a veces sube al restringir; lo que cuenta es que no
# baje más de .010) y ΔRMSEA de -.004 a -.014.
# Pero la χ² es más exigente (con 2,050 casos detecta diferencias pequeñas): rechaza la igualdad
# de UMBRALES en los cuatro grupos (p de .000 a .047) y la de cargas en estudios (p = .003) y
# gran ciudad (p = .043); en sexo y edad las cargas no se rechazan (p = .29 y .46). Se acepta la
# invarianza por Chen, con la salvedad de que las diferencias, si las hay, están en los umbrales.
# No se buscó qué umbrales pesan más.
write.csv(tabla, file.path(dir_salida, "invarianza.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 4. Qué hay detrás: ajuste del modelo en cada grupo por separado
# -----------------------------------------------------------------------
# Antes de comparar conviene saber que el modelo ajusta en cada grupo. También se
# muestra la categoría más rara de cualquier ítem (con pocos casos, su umbral es frágil).
por_grupo <- function(variable, nivel) {
  dd <- d[which(d[[variable]] == nivel), ]
  f <- cfa(modelo, data = dd, ordered = items, estimator = "WLSMV", missing = "pairwise")
  m <- round(fitMeasures(f, c("cfi.scaled", "rmsea.scaled", "srmr")), 3)
  minimo <- min(sapply(items, function(v) min(table(factor(dd[[v]], levels = 1:maximo[[v]])))))
  data.frame(variable = variable, grupo = nivel, N = nrow(dd), CFI = m[1], RMSEA = m[2], SRMR = m[3],
             min_casos_por_categoria = minimo, row.names = NULL)
}
ajuste_grupos <- do.call(rbind, lapply(c("sexo", "edad_g", "estudios_g", "ciudad_g"), function(v)
  do.call(rbind, lapply(levels(d[[v]]), function(n) por_grupo(v, n)))))
ajuste_grupos
# CFI de .962 a .984 y RMSEA de .059 a .081 en los nueve grupos; el más flojo es 18-39 (CFI .962,
# RMSEA .081). En varios grupos la categoría más rara tiene 1 a 3 casos (P11, P3, P1): sus
# umbrales son frágiles, otra razón para leer con cautela.
write.csv(ajuste_grupos, file.path(dir_salida, "ajuste_por_grupo.csv"), row.names = FALSE)
