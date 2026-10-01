# =============================================================================
# Libro SEM · PREP
# 03 - AFC de segundo orden
# =============================================================================
# PENDIENTE: este script se llenará cuando se compartan los trabajos previos
# con el PREP. Por ahora solo deja listo el esqueleto de la carpeta.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/03_AFC_2do_Orden/AFC_2do_Orden.R")
# =============================================================================

library(readstata13)

dir_salida <- "PREP/03_AFC_2do_Orden/output"

# Base de trabajo (no se versiona; ver README de PREP)
prep <- read.dta13("PREP/data/PREP.dta")
