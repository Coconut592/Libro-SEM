# Libro SEM

Material en R para el libro de Modelos de Ecuaciones Estructurales (SEM). Cada proyecto es una
carpeta independiente con sus scripts, su carpeta `data/` y su propio `README.md`.

| Proyecto | Carpeta | Estado |
|---|---|---|
| Datos Violencia Veracruz | `Datos_Violencia_Veracruz/` | 🔄 Análisis exploratorio listo |

## Cómo trabajar en VSCode

1. Instala R (≥ 4.1) y la extensión **R** (REditorSupport) de VSCode; en R:
   `install.packages(c("languageserver", "httpgd"))`.
2. Abre **la raíz de este repositorio** en VSCode: todas las rutas de los scripts son relativas a ella.
3. Sigue el `README.md` de cada proyecto.

## Datos

Los microdatos (`.dta`, `.csv`, etc.) **no se versionan** (ver `.gitignore`): cada quien copia la base
a la carpeta `data/` del proyecto correspondiente.
