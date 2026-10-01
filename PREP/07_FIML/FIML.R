# =============================================================================
# Libro SEM · PREP
# 07 - Datos faltantes: listwise vs FIML
# =============================================================================
# PENDIENTE: este script se llenará cuando se compartan los trabajos previos
# con el PREP. Por ahora solo deja listo el esqueleto de la carpeta.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/07_FIML/FIML.R")
# =============================================================================

library(readstata13)

dir_salida <- "PREP/07_FIML/output"

# Base de trabajo (no se versiona; ver README de PREP)
prep <- read.dta13("PREP/data/PREP.dta")
