# =============================================================================
# Libro SEM · PREP
# 04 - Confiabilidad y validez
# =============================================================================
# PENDIENTE: este script se llenará cuando se compartan los trabajos previos
# con el PREP. Por ahora solo deja listo el esqueleto de la carpeta.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/04_Confiabilidad_y_Validez/Confiabilidad_y_Validez.R")
# =============================================================================

library(readstata13)

dir_salida <- "PREP/04_Confiabilidad_y_Validez/output"

# Base de trabajo (no se versiona; ver README de PREP)
prep <- read.dta13("PREP/data/PREP.dta")
