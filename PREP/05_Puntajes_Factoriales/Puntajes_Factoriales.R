# =============================================================================
# Libro SEM · PREP
# 05 - Puntajes factoriales
# =============================================================================
# PENDIENTE: este script se llenará cuando se compartan los trabajos previos
# con el PREP. Por ahora solo deja listo el esqueleto de la carpeta.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/05_Puntajes_Factoriales/Puntajes_Factoriales.R")
# =============================================================================

library(readstata13)

dir_salida <- "PREP/05_Puntajes_Factoriales/output"

# Base de trabajo (no se versiona; ver README de PREP)
prep <- read.dta13("PREP/data/PREP.dta")
