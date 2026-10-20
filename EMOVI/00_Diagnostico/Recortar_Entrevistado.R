# =============================================================================
# Libro SEM · EMOVI
# 00 - Recortar el Entrevistado 2023 a la Ciudad de México (para poder subirlo)
# =============================================================================
# El archivo completo pesa ~39 MB y no se puede adjuntar. La tesis usa solo la
# CDMX, así que se queda con esas filas y se quitan las columnas de texto libre
# (descripción de oficios y tareas), que son las que más pesan. Deja un .dta chico
# y un resumen en texto (por si tampoco se puede subir el .dta, se pega el resumen).
#   source("EMOVI/00_Diagnostico/Recortar_Entrevistado.R")
# =============================================================================

library(readstata13)

archivo <- "EMOVI/data/entrevistado_2023.dta"       # cambia el nombre si el tuyo es otro
salida  <- "EMOVI/data/entrevistado_2023_CDMX.dta"
resumen <- "EMOVI/data/resumen_entrevistado_CDMX.txt"

# -----------------------------------------------------------------------
# Paso 1. Leer el archivo completo
# -----------------------------------------------------------------------
ent <- read.dta13(archivo, convert.factors = FALSE)
cat("Completo:", nrow(ent), "filas y", ncol(ent), "columnas\n")   # el diccionario dice 294 columnas
stopifnot("entidad" %in% names(ent))
print(table(ent$entidad))                            # la Ciudad de México es la 9

# -----------------------------------------------------------------------
# Paso 2. Quedarse con la CDMX y sin las columnas de texto libre
# -----------------------------------------------------------------------
# Texto libre = columnas de texto con más de 20 caracteres. Los códigos cortos
# (p48_SINCO, etc.) se conservan.
es_largo <- sapply(ent, function(x) is.character(x) && max(nchar(x, type = "bytes"), 0, na.rm = TRUE) > 20)
cat("Columnas de texto que se quitan:", paste(names(ent)[es_largo], collapse = ", "), "\n")
cdmx <- ent[ent$entidad %in% 9, !es_largo]
stopifnot(nrow(cdmx) > 0)
cat("CDMX:", nrow(cdmx), "filas y", ncol(cdmx), "columnas\n")

save.dta13(cdmx, salida)
cat("Guardado:", salida, "-", round(file.size(salida) / 1e6, 1), "MB\n")

# -----------------------------------------------------------------------
# Paso 3. Resumen en texto (para pegarlo aquí si el .dta aún pesa demasiado)
# -----------------------------------------------------------------------
rango <- function(pref, ini, fin) paste0(pref, letters[match(ini, letters):match(fin, letters)])

# Variables clave: casos, faltantes y valores (o rango si son muchos valores)
clave <- c("sexo", "cohorte", "edad", "ocup", "clase", "clasep", "clasem", "clase1",
           "educ", "educp", "educm", "p9", "p10", "p42a", "p42b", "p43a", "p43b",
           "p77", "p25", "p30", "p103", "p104", "ingc_pc", "factor")
resumir <- function(v) {
  if (!v %in% names(cdmx)) return(paste0(v, " | NO ESTÁ"))
  x <- cdmx[[v]]; tb <- table(x, useNA = "ifany")
  paste0(v, " | NA=", sum(is.na(x)), " | ",
         if (length(tb) <= 14) paste(names(tb), tb, sep = ":", collapse = "  ")
         else paste("rango", paste(round(range(x, na.rm = TRUE), 1), collapse = " a ")))
}

# Ítems de riqueza del hogar de origen: % de "Sí" entre quienes contestan Sí/No,
# y cuántos dijeron NS (8) o faltan
riqueza <- c(rango("p26", "a", "e"), rango("p29", "a", "g"), rango("p31", "a", "o"), rango("p32", "a", "o"))
riq <- function(v) {
  if (!v %in% names(cdmx)) return(paste0(v, " | NO ESTÁ"))
  x <- cdmx[[v]]
  sprintf("%s | Sí = %4.1f%% | NS = %d | NA = %d", v, 100 * mean(x[x %in% 1:2] == 1), sum(x %in% 8), sum(is.na(x)))
}

writeLines(c(sprintf("Completo: %d x %d | CDMX: %d x %d | texto quitado: %d columnas",
                     nrow(ent), ncol(ent), nrow(cdmx), ncol(cdmx), sum(es_largo)),
             "", "== Variables clave (CDMX) ==", sapply(clave, resumir),
             "", "== Riqueza del hogar de origen (CDMX) ==", sapply(riqueza, riq)), resumen)
cat(readLines(resumen), sep = "\n")
cat("\nListo. Sube", salida, "(o pega el resumen de", resumen, ")\n")
