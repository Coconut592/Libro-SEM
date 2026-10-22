# =============================================================================
# Libro SEM · Violencia Veracruz
# 06 - Invarianza factorial: edad y escolaridad
# =============================================================================
# Sin referencia: Scripts.do compara la clase de violencia entre grupos con una
# regresión ordinal (ologit) pero no prueba antes que los ítems se miden igual en
# esos grupos. Este ejercicio llena ese hueco con los dos cortes que la base permite:
# edad (18-44 contra 45+) y escolaridad (hasta primaria contra secundaria o más).
# No hay variable de sexo (todas son mujeres). Con los cuatro ítems de trabajo, que son
# muy raros, el modelo de seis ámbitos se vuelve INADMISIBLE en uno de los grupos
# (paso 2): se prueba el de cinco ámbitos, sin trabajo (20 ítems).
#   source("Violencia_Veracruz/06_Invarianza_Factorial/Invarianza_Factorial.R")
# =============================================================================

library(readstata13)
library(lavaan)

dir_salida <- "Violencia_Veracruz/06_Invarianza_Factorial/output"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------
# Paso 1. Datos, modelos y grupos
# -----------------------------------------------------------------------
vera <- read.dta13("Violencia_Veracruz/data/BASE_ACLnew.dta", convert.factors = FALSE)
items <- c("p141", "p142", "p143", "p144", "p161", "p162", "p165", "p171", "p172", "p173", "p175", "p176",
           "p183", "p184", "p185", "p186", "p191", "p192", "p193", "p194", "p201", "p202", "p203", "p204")
vera <- vera[rowSums(!is.na(vera[, items])) > 0, ]    # 1,088 mujeres

modelo6 <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  TRA =~ p183 + p184 + p185 + p186
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'
modelo5 <- '
  INF =~ p141 + p142 + p143 + p144
  FAM =~ p161 + p162 + p165
  PAR =~ p171 + p172 + p173 + p175 + p176
  COM =~ p191 + p192 + p193 + p194
  ESC =~ p201 + p202 + p203 + p204'
items5 <- setdiff(items, c("p183", "p184", "p185", "p186"))

# Los grupos. p2: 1 = 18-24, 2 = 25-34, 3 = 35-44, 4 = 45-54, 5 = 55-64. p4: 1 ninguna,
# 2 primaria, 3 secundaria, 4 preparatoria, 5 universidad, 6 otro (5 mujeres, fuera).
vera$edad_g  <- factor(ifelse(vera$p2 <= 3, "18-44", "45+"), levels = c("18-44", "45+"))
vera$escol_g <- factor(ifelse(vera$p4 <= 2, "hasta primaria", ifelse(vera$p4 <= 5, "secundaria o más", NA)),
                       levels = c("hasta primaria", "secundaria o más"))
vera$derechos_g <- factor(vera$p62, levels = 0:1, labels = c("no conoce", "conoce"))   # solo para el paso 2
table(vera$edad_g)                           # 665 de 18 a 44 años y 421 de 45 o más (2 sin dato)
table(vera$escol_g)                          # 449 hasta primaria y 618 de secundaria o más

# -----------------------------------------------------------------------
# Paso 2. Requisito: el modelo debe ser admisible en cada grupo
# -----------------------------------------------------------------------
# "Admisible" = converge y no tiene varianzas negativas (caso Heywood: una carga estandarizada
# mayor que 1). Se prueban los dos modelos en cada grupo por separado.
revisar <- function(modelo, its, variable, nombre_modelo) {
  do.call(rbind, lapply(levels(vera[[variable]]), function(nivel) {
    d <- vera[which(vera[[variable]] == nivel), ]
    f <- suppressWarnings(cfa(modelo, data = d, ordered = its, estimator = "WLSMV", missing = "pairwise"))
    ok <- lavInspect(f, "converged")
    carga_max <- if (ok) max(standardizedSolution(f)$est.std[standardizedSolution(f)$op == "=~"]) else NA
    data.frame(grupo = variable, nivel = nivel, modelo = nombre_modelo, N = nrow(d),
               CFI = if (ok) round(fitMeasures(f, "cfi.scaled"), 3) else NA,
               carga_max = round(carga_max, 3),
               admisible = ok && suppressWarnings(lavInspect(f, "post.check")), row.names = NULL)
  }))
}
admisibilidad <- do.call(rbind, lapply(c("edad_g", "escol_g", "derechos_g"), function(g)
  rbind(revisar(modelo6, items, g, "6 ámbitos"), revisar(modelo5, items5, g, "5 ámbitos (sin trabajo)"))))
admisibilidad
# 6 ámbitos: solución inadmisible en 45+ (carga máxima 1.014, p186 de trabajo), en "hasta primaria"
# (1.002) y en "no conoce" los derechos (1.106). En el grupo más chico los ítems de trabajo tienen
# entre 3 y 9 mujeres que dicen "Sí" (ver 00_Diagnostico): el bloque no se sostiene al partir la muestra.
# 5 ámbitos (20 ítems): admisible por edad y por escolaridad, pero NO por conocer los derechos de las
# mujeres (281 contra 794; carga 1.078), que se deja fuera.
write.csv(admisibilidad, file.path(dir_salida, "admisibilidad_por_grupo.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 3. Pasos de la invarianza con ítems binarios
# -----------------------------------------------------------------------
# Con ítems 0/1 los umbrales y las cargas se restringen juntos (Millsap y Tein, 2004):
# si el umbral y la carga de un ítem son iguales, el ítem funciona igual en los dos grupos.
#   Configural:          misma estructura, todo libre
#   Umbrales + cargas:   umbrales y cargas iguales (equivale a la métrica y escalar juntas)
# Criterio de Chen (2007): ΔCFI de -.010 o menos y ΔRMSEA de .015 o menos.
medidas <- c("chisq.scaled", "df.scaled", "cfi.scaled", "tli.scaled", "rmsea.scaled", "srmr")
invarianza <- function(grupo, parametrizacion = "delta") {
  d <- vera[!is.na(vera[[grupo]]), ]
  d <- d[order(d[[grupo]]), ]                 # el grupo 1 (referencia) es el primer nivel
  conf <- cfa(modelo5, data = d, ordered = items5, estimator = "WLSMV", group = grupo, missing = "pairwise",
              parameterization = parametrizacion)
  rest <- cfa(modelo5, data = d, ordered = items5, estimator = "WLSMV", group = grupo, missing = "pairwise",
              group.equal = c("thresholds", "loadings"), parameterization = parametrizacion)
  stopifnot(identical(lavInspect(conf, "group.label"), levels(droplevels(d[[grupo]]))))
  m <- rbind(round(fitMeasures(conf, medidas), 3), round(fitMeasures(rest, medidas), 3))
  lrt <- suppressMessages(lavTestLRT(conf, rest))   # diferencia de chi2 escalada (Satorra, 2000)
  tabla <- data.frame(grupo = grupo, modelo = c("Configural", "Umbrales + cargas"), m, row.names = NULL)
  names(tabla)[3:8] <- c("chisq", "gl", "CFI", "TLI", "RMSEA", "SRMR")
  tabla$dCFI <- c(NA, round(tabla$CFI[2] - tabla$CFI[1], 3))
  tabla$dRMSEA <- c(NA, round(tabla$RMSEA[2] - tabla$RMSEA[1], 3))
  tabla$p_LRT <- c(NA, round(lrt$`Pr(>Chisq)`[2], 3))
  tabla
}
tabla <- rbind(invarianza("edad_g"), invarianza("escol_g"))
tabla
# Edad: ΔCFI = 0, ΔRMSEA = -.001 y la chi2 no rechaza (p = .51). Escolaridad: ΔCFI = 0,
# ΔRMSEA = 0 y la chi2 no rechaza (p = .37). Hay invarianza de umbrales y cargas en las dos.
write.csv(tabla, file.path(dir_salida, "invarianza.csv"), row.names = FALSE)

# Robustez: la parametrización theta (la de Millsap y Tein) da el mismo ajuste y la misma prueba
# (la delta de lavaan es la de uso común; ambas son equivalentes en ajuste)
tabla_theta <- rbind(invarianza("edad_g", "theta"), invarianza("escol_g", "theta"))
max(abs(tabla_theta$chisq - tabla$chisq))     # ~0.003
max(abs(tabla_theta$p_LRT - tabla$p_LRT), na.rm = TRUE)

# -----------------------------------------------------------------------
# Paso 4. Qué hay detrás: ajuste del modelo en cada grupo por separado
# -----------------------------------------------------------------------
por_grupo <- function(variable, nivel) {
  d <- vera[which(vera[[variable]] == nivel), ]
  f <- cfa(modelo5, data = d, ordered = items5, estimator = "WLSMV", missing = "pairwise")
  m <- round(fitMeasures(f, c("cfi.scaled", "rmsea.scaled", "srmr")), 3)
  data.frame(grupo = nivel, N = nrow(d), CFI = m[1], RMSEA = m[2], SRMR = m[3], row.names = NULL)
}
ajuste_grupos <- rbind(por_grupo("edad_g", "18-44"), por_grupo("edad_g", "45+"),
                       por_grupo("escol_g", "hasta primaria"), por_grupo("escol_g", "secundaria o más"))
ajuste_grupos
# CFI de .985 a .992 y RMSEA de .018 a .027 en los cuatro grupos; SRMR de .105 a .123 (el mismo problema
# de las parejas casi vacías que en 02_AFC). El más flojo es 45+ (CFI .985, SRMR .123).
write.csv(ajuste_grupos, file.path(dir_salida, "ajuste_por_grupo.csv"), row.names = FALSE)

# -----------------------------------------------------------------------
# Paso 5. Lo que NO se hace: comparar medias latentes
# -----------------------------------------------------------------------
# Con umbrales y cargas iguales, la media y la varianza de cada factor en el segundo grupo se
# podrían estimar, pero aquí no están bien identificadas (errores estándar enormes y valores que
# cambian de delta a theta, p. ej. la varianza de PAR en 45+ sale 6.9 o 24.0). No se interpretan:
# para comparar niveles de violencia entre grupos conviene usar los puntajes de 05 con cautela.
