# =============================================================================
# Libro SEM · PREP
# 01 - Análisis Factorial Exploratorio (AFE)
# =============================================================================
# PENDIENTE: este script se llenará cuando se compartan los trabajos previos
# con el PREP. Por ahora solo deja listo el esqueleto de la carpeta.
# Correr con el directorio de trabajo en la raíz del repositorio:
#   source("PREP/01_AFE/AFE.R")
# =============================================================================

library(readstata13)

dir_salida <- "PREP/01_AFE/output"

# Base de trabajo (no se versiona; ver README de PREP)
prep <- read.dta13("PREP/data/PREP.dta")
