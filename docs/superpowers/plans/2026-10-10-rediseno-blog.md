# Rediseño de Tartagalensis: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Relanzar el blog en https://tartagalensis.github.io con el tema propio "telegrama electoral", una sola sección de notas por temas, sobre mí nuevo y suscripción por Buttondown.

**Architecture:** Sitio Hugo con un tema propio (`themes/tartagalensis/`) escrito con el sistema de plantillas nuevo de Hugo (≥0.146: `layouts/home.html`, `page.html`, `_partials/`, `_shortcodes/`). Las notas viven en `content/notas/` con la taxonomía `temas`. Un workflow de GitHub Actions compila y publica en GitHub Pages en cada push a `main`. La verificación se hace con un script de bash (`scripts/check-site.sh`) que compila el sitio en un directorio temporal y valida el HTML generado con `grep`.

**Tech Stack:** Hugo extended 0.167.0 (Homebrew local, binario oficial en CI), HTML/CSS sin JS, Google Fonts (Courier Prime, Source Serif 4), blogdown/R para las notas `.Rmd`, Buttondown, GitHub Actions + Pages.

**Spec:** `docs/superpowers/specs/2026-10-10-rediseno-blog-design.md`

## Global Constraints

- Versión de Hugo: **0.167.0 extended**, la misma en local (`brew install hugo`) y en CI. Si Homebrew instala otra versión, se usa esa en las dos partes y se actualiza este plan.
- `baseURL = "https://tartagalensis.github.io/"`, `title = "Tartagalensis"`, `languageCode = "es-AR"`.
- Paleta: papel `#eef0ea`, tinta `#1d2a3a`, texto `#1f232a`, sello `#8a2a2a`.
- Tipografías: Courier Prime (marco) y Source Serif 4 (título y cuerpo), desde Google Fonts.
- Cuerpo de nota: 19px, interlineado 1.7, ancho máx. 700px. En celular (≤600px): títulos de 32px, grilla de casilleros 2×2.
- Gráficos: el rótulo es solo el título del gráfico. **Nunca** "Fig. N".
- Telegrama: título `TELEGRAMA · SUSCRIPCIÓN`, sello `SIN FRANQUEO`, texto exacto: "Si te gustó y querés recibir las notas nuevas cuando salgan, suscribite.", botón `ENVIAR`.
- Menú: `Notas · Sobre mí · Suscribirse`. Pie: `TARTAGALENSIS · DESDE TARTAGAL, SALTA` + RSS · LinkedIn · GitHub.
- URLs: notas en `/notas/<slug>/`, temas en `/temas/<tema>/`, sobre mí en `/sobre-mi/`, suscripción en `/suscribirse/`. Sin redirecciones.
- Las notas viejas conservan sus fechas originales.
- Todo el texto visible está en español rioplatense.
- Todo el trabajo va en la rama `rediseno`. `main` se toca recién con aprobación de Franco (Task 9).

## Review Focus

1. **Nota sin `temas` o sin `bajada`:** el casillero TEMA muestra `—` y no se genera un párrafo de bajada vacío. (Test en Task 4.)
2. **Celular a 360px:** ni la portada ni las notas generan scroll horizontal, aunque haya títulos largos, tablas de 4 columnas o imágenes anchas. (Test en Task 5 por CSS e inspección visual en Task 9.)
3. **Notas `.Rmd` viejas con HTML crudo** (embeds de Flourish, notas al pie `#fn1`, imágenes con `src` absolutos a `/cienciaypol/..._files/`): se renderizan dentro del layout nuevo y sus imágenes existen en el build. (Test en Task 2.)
4. **Acentos en temas** ("Política argentina", "Métodos"): las URLs salen sin tildes (`/temas/politica-argentina/`) y no hay links rotos. (Test en Task 5.)
5. **Buttondown sin usuario configurado:** si `params.buttondown` está vacío, no se publica un formulario que postee a una URL rota; el bloque no se muestra y Hugo avisa con `warnf`. (Test en Task 6.)

---

## File Structure

```
config.toml                                  # reescrito (Task 1)
.gitignore                                   # + public/, resources/, .hugo_build.lock
scripts/check-site.sh                        # compila y valida el HTML (crece en cada task)
static/favicon_nuevo.ico                     # rescatado de public/ (Task 1)
static/cienciaypol/*_files/                  # sin cambios: imágenes de notas .Rmd
content/notas/_index.md                      # sección
content/notas/<5 notas>                      # migradas (Task 2)
content/sobre-mi.md                          # Task 7
content/suscribirse.md                       # Task 6
themes/tartagalensis/
  layouts/baseof.html                        # esqueleto HTML, <head>, fuentes, css
  layouts/home.html                          # portada: acta de notas
  layouts/page.html                          # nota (y fallback de páginas)
  layouts/pagina.html                        # layout simple: sobre mí, suscribirse
  layouts/section.html                       # /notas/ (misma acta)
  layouts/term.html                          # /temas/<tema>/
  layouts/taxonomy.html                      # /temas/
  layouts/404.html
  layouts/rss.xml                            # feed con contenido completo
  layouts/_partials/cabecera.html
  layouts/_partials/pie.html
  layouts/_partials/acta.html                # tabla N.º · NOTA · FECHA · TEMA
  layouts/_partials/numero-nota.html         # devuelve "05"
  layouts/_partials/telegrama.html
  layouts/_shortcodes/casillero.html
  static/css/main.css
.github/workflows/hugo.yml                   # Task 8
```

Se eliminan `themes/hugo-lithium/`, `public/`, `content/cv/`, `content/post/`, `static/post/`, `static/random/` y `content/cienciaypol/` y `content/random/` (estas dos se vacían al migrar).

---

### Task 1: Base: Hugo nuevo, config, limpieza y tema mínimo que compila

**Files:**
- Create: `scripts/check-site.sh`, `themes/tartagalensis/layouts/baseof.html`, `themes/tartagalensis/layouts/home.html`, `static/favicon_nuevo.ico`
- Modify: `config.toml` (reemplazo completo), `.gitignore`
- Delete: `themes/hugo-lithium/`, `public/`, `content/cv/`, `content/post/`, `static/post/`, `static/random/`

**Interfaces:**
- Produces: `scripts/check-site.sh`, que exporta las funciones `assert_file <ruta-relativa-a-public>`, `assert_grep <archivo> <regex>` y `refute_grep <archivo> <regex>`, más la variable `$OUT` (directorio del build). Las tasks siguientes agregan checks al final del script, en la sección `# --- checks ---`.
- Produces: `site.Params.description`, `site.Params.buttondown`, `site.Params.linkedin`, `site.Params.github` (en config).

- [ ] **Step 1: Instalar Hugo y verificar la versión**

```bash
brew install hugo
hugo version
```
Expected: `hugo v0.167.0+extended darwin/arm64 ...`. Si sale otra versión, anotarla y reemplazar 0.167.0 en este plan y en Task 8.

- [ ] **Step 2: Escribir el script de verificación (va a fallar)**

`scripts/check-site.sh`:
```bash
#!/usr/bin/env bash
# Compila el sitio en un directorio temporal y valida el HTML generado.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)"
FALLAS=0

if ! hugo --quiet --gc -d "$OUT" 2> "$OUT.log"; then
  echo "FALLA: hugo no compila"; cat "$OUT.log"; exit 1
fi
if grep -q "ERROR" "$OUT.log"; then
  echo "FALLA: errores en el build"; cat "$OUT.log"; exit 1
fi

assert_file()  { [ -f "$OUT/$1" ] || { echo "FALLA: falta $1"; FALLAS=$((FALLAS+1)); }; }
assert_grep()  { grep -qE "$2" "$OUT/$1" 2>/dev/null || { echo "FALLA: $1 no contiene /$2/"; FALLAS=$((FALLAS+1)); }; }
refute_grep()  { ! grep -qE "$2" "$OUT/$1" 2>/dev/null || { echo "FALLA: $1 contiene /$2/"; FALLAS=$((FALLAS+1)); }; }

# --- checks ---
assert_file index.html
assert_grep index.html '<title>Tartagalensis</title>'
assert_grep index.html 'lang="es-AR"'
refute_grep index.html 'A Hugo website'
assert_file favicon_nuevo.ico
[ ! -d "$OUT/cv" ] || { echo "FALLA: existe /cv/"; FALLAS=$((FALLAS+1)); }
[ ! -d "$OUT/post" ] || { echo "FALLA: existe /post/"; FALLAS=$((FALLAS+1)); }

# --- fin checks ---
if [ "$FALLAS" -gt 0 ]; then echo "$FALLAS falla(s). Build en $OUT"; exit 1; fi
echo "OK. Build en $OUT"
```

```bash
chmod +x scripts/check-site.sh
./scripts/check-site.sh
```
Expected: FALLA. Con el tema lithium y la config vieja, el título sale "A Hugo website" (o la compilación falla con Hugo 0.167 por la config vieja). Cualquiera de las dos cuenta como falla esperada.

- [ ] **Step 3: Rescatar el favicon y borrar lo viejo**

```bash
cp public/favicon_nuevo.ico static/favicon_nuevo.ico
git rm -r -q themes/hugo-lithium public content/cv content/post static/post
rm -rf public static/random
```

- [ ] **Step 4: Reescribir `config.toml`**

```toml
baseURL = "https://tartagalensis.github.io/"
languageCode = "es-AR"
defaultContentLanguage = "es"
title = "Tartagalensis"
theme = "tartagalensis"
removePathAccents = true
enableRobotsTXT = true
ignoreFiles = ["\\.Rmd$", "\\.Rmarkdown$", "_cache$", "\\.knit\\.md$", "\\.utf8\\.md$"]

[permalinks]
  notas = "/notas/:slug/"

[taxonomies]
  tema = "temas"

[outputs]
  home = ["HTML", "RSS"]
  section = ["HTML"]
  taxonomy = ["HTML"]
  term = ["HTML"]

[params]
  description = "Elecciones, federalismo y datos, desde el Norte."
  autor = "Franco Galeano"
  buttondown = "tartagalensis"
  linkedin = ""
  github = "https://github.com/tartagalensis"

[markup.goldmark.renderer]
  unsafe = true
```

`linkedin` queda vacío hasta que Franco pase la URL (Task 7). `description` es una propuesta que se valida en Task 7.

- [ ] **Step 5: Actualizar `.gitignore`**

Agregar al final:
```
public/
resources/
.hugo_build.lock
```

- [ ] **Step 6: Tema mínimo**

`themes/tartagalensis/layouts/baseof.html`:
```html
<!DOCTYPE html>
<html lang="{{ site.LanguageCode }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ if .IsHome }}{{ site.Title }}{{ else }}{{ .Title }} · {{ site.Title }}{{ end }}</title>
  <meta name="description" content="{{ with .Params.bajada }}{{ . }}{{ else }}{{ site.Params.description }}{{ end }}">
  <link rel="icon" href="{{ "favicon_nuevo.ico" | relURL }}">
  {{ with site.Home.OutputFormats.Get "rss" }}<link rel="alternate" type="application/rss+xml" href="{{ .Permalink }}" title="{{ site.Title }}">{{ end }}
</head>
<body>
  {{ block "main" . }}{{ end }}
</body>
</html>
```

`themes/tartagalensis/layouts/home.html`:
```html
{{ define "main" }}<main><h1>{{ site.Title }}</h1></main>{{ end }}
```

- [ ] **Step 7: Correr el check**

```bash
./scripts/check-site.sh
```
Expected: `OK. Build en ...`. Las notas de `content/cienciaypol` y `content/random` se compilan pero todavía no tienen template (los WARN sobre layouts faltantes son esperables en esta task).

- [ ] **Step 8: Commit**

```bash
git add -A config.toml .gitignore scripts static/favicon_nuevo.ico themes/tartagalensis
git commit -m "Base del rediseño: Hugo 0.167, config nueva y tema mínimo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2: Migrar las 5 notas a `content/notas/`

**Files:**
- Create: `content/notas/_index.md`
- Move: las 5 notas (tabla abajo)
- Modify: el frontmatter de cada nota (en `.Rmd` y `.html` cuando existan los dos)
- Modify: `scripts/check-site.sh` (agrega checks)

**Interfaces:**
- Produces: páginas en `/notas/<slug>/` con `Params.temas` (lista) y, opcionalmente, `Params.bajada`. Las páginas de Task 4 y 5 dependen de estos nombres.

Mapeo (los slugs nuevos son limpios, sin tildes ni restos de "ra-ces"):

| Origen | Destino | slug | temas |
|---|---|---|---|
| `content/cienciaypol/2020-05-18-inferencia-ecológica-en-salta-2019.{Rmd,html}` | `content/notas/2020-05-24-votos-de-isa-2019.{Rmd,html}` | `votos-de-isa-2019` | Elecciones, Salta, Métodos |
| `content/cienciaypol/2021-08-04-defendiendo-las-paso-en-salta.{Rmd,html}` | `content/notas/2020-08-04-defendiendo-las-paso-en-salta.{Rmd,html}` | `defendiendo-las-paso-en-salta` | Elecciones, Salta |
| `content/cienciaypol/2021-09-08-el-ultimo-tren.{Rmd,html}` | `content/notas/2021-09-08-el-ultimo-tren.{Rmd,html}` | `el-ultimo-tren` | Política argentina, Elecciones |
| `content/cienciaypol/2023-10-23-migraci-n-…/index.md` | `content/notas/2023-10-23-migracion-del-voto-2023/index.md` | `migracion-del-voto-2023` | Elecciones, Métodos |
| `content/random/2025-07-03-desarrollo-con-ra-ces-…/index.md` | `content/notas/2025-07-03-desarrollo-con-raices/index.md` | `desarrollo-con-raices` | Desarrollo, Salta |

Las fechas se toman del frontmatter actual (`date:`), que es lo que muestra el sitio vivo. "Defendiendo las PASO" dice `2020-08-04`, aunque su archivo dice 2021: hay que confirmarlo con Franco y, si corresponde, corregirlo a `2021-08-04`.

- [ ] **Step 1: Agregar checks que fallan**

En `scripts/check-site.sh`, antes de `# --- fin checks ---`:
```bash
for s in votos-de-isa-2019 defendiendo-las-paso-en-salta el-ultimo-tren migracion-del-voto-2023 desarrollo-con-raices; do
  assert_file "notas/$s/index.html"
done
[ ! -d "$OUT/cienciaypol/votos-de-isa-2019" ] && [ ! -d "$OUT/random" ] || { echo "FALLA: quedan secciones viejas"; FALLAS=$((FALLAS+1)); }
# imágenes absolutas de las notas .Rmd (Review Focus 3)
for img in $(grep -ohE 'src="/cienciaypol/[^"]+"' content/notas/*.html | sed 's/src="\///; s/"$//'); do
  assert_file "$(printf '%b' "${img//%/\\x}")"
done
```

Run: `./scripts/check-site.sh`. Expected: FALLA, faltan las 5 `notas/.../index.html`. El loop de imágenes no encuentra archivos todavía y no suma fallas.

- [ ] **Step 2: Mover los archivos**

```bash
mkdir -p content/notas
git mv "content/cienciaypol/2020-05-18-inferencia-ecológica-en-salta-2019.Rmd" content/notas/2020-05-24-votos-de-isa-2019.Rmd
git mv "content/cienciaypol/2020-05-18-inferencia-ecológica-en-salta-2019.html" content/notas/2020-05-24-votos-de-isa-2019.html
git mv content/cienciaypol/2021-08-04-defendiendo-las-paso-en-salta.Rmd content/notas/2020-08-04-defendiendo-las-paso-en-salta.Rmd
git mv content/cienciaypol/2021-08-04-defendiendo-las-paso-en-salta.html content/notas/2020-08-04-defendiendo-las-paso-en-salta.html
git mv content/cienciaypol/2021-09-08-el-ultimo-tren.Rmd content/notas/2021-09-08-el-ultimo-tren.Rmd
git mv content/cienciaypol/2021-09-08-el-ultimo-tren.html content/notas/2021-09-08-el-ultimo-tren.html
git mv content/cienciaypol/2023-10-23-migraci-n-del-voto-de-d-nde-vino-la-victoria-de-massa content/notas/2023-10-23-migracion-del-voto-2023
git mv content/random/2025-07-03-desarrollo-con-ra-ces-una-mirada-desde-el-norte content/notas/2025-07-03-desarrollo-con-raices
git status --short content/
```
Luego borrar lo que quede en `content/cienciaypol/` (son PNG sueltos ya duplicados en `static/cienciaypol/*_files/`). Antes de borrar, verificar que cada PNG tenga su copia:
```bash
for f in content/cienciaypol/*.png; do b=$(basename "$f"); find static/cienciaypol -name "$b" | grep -q . && echo "ok $b" || echo "SIN COPIA $b"; done
```
Si alguno dice `SIN COPIA`, moverlo a `static/cienciaypol/<nota>_files/` antes de seguir. Después:
```bash
git rm -r -q content/cienciaypol content/random
```

- [ ] **Step 3: Normalizar el frontmatter**

Formato para todas las notas: se reemplaza el bloque `categories`/`tags` por `temas`, se cambia el `slug` y se conservan `title`, `author` y `date`. En las de `.Rmd`/`.html` se edita **el mismo frontmatter en los dos archivos**.

Ejemplo, `2020-05-24-votos-de-isa-2019.Rmd` y `.html`:
```yaml
---
title: ¿Qué pasó con los votos de Isa en 2019?
author: Franco Galeano
date: '2020-05-24'
slug: votos-de-isa-2019
temas:
  - Elecciones
  - Salta
  - Métodos
---
```
Hacer lo mismo con las otras cuatro según la tabla. En `migracion-del-voto-2023/index.md` corregir además `author: "Package Build"` → `author: "Franco Galeano"`. En `el-ultimo-tren` mantener `author: Franco Galeano, Germán Epelbaum y Bruno Ferronato`.

En `2020-05-24-votos-de-isa-2019.html` borrar la línea con `src="2020-05-18-inferencia-ecológica-en-salta-2019_files/header-attrs/header-attrs.js"`. Es un script relativo de blogdown que no hace falta y daría 404.

`content/notas/_index.md`:
```yaml
---
title: Notas
---
```

- [ ] **Step 4: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`. Si falta alguna imagen `/cienciaypol/...`, revisar el nombre con espacios o `%20` contra `static/cienciaypol/`.

- [ ] **Step 5: Commit**

```bash
git add -A content scripts/check-site.sh
git commit -m "Migra las 5 notas a content/notas con temas

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Estilos, cabecera y pie

**Files:**
- Create: `themes/tartagalensis/static/css/main.css`, `themes/tartagalensis/layouts/_partials/cabecera.html`, `themes/tartagalensis/layouts/_partials/pie.html`
- Modify: `themes/tartagalensis/layouts/baseof.html`
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: `site.Params.github`, `site.Params.linkedin` (Task 1).
- Produces: clases CSS que usan las tasks siguientes: `.wrap`, `.formulario`, `.bajada`, `.cuerpo` (artículo), `.casillero` (`.rotulo`, `.pie`), `.acta` (tabla), `.telegrama` (`.tit`, `.cuerpo-tel`, `.sello`), `.pagina`.

- [ ] **Step 1: Checks que fallan**

```bash
assert_file css/main.css
assert_grep index.html 'fonts.googleapis.com/css2\?family=Courier\+Prime'
assert_grep index.html 'class="marca"[^>]*>TARTAGALENSIS<'
assert_grep index.html 'href="/notas/"[^>]*>Notas<'
assert_grep index.html 'href="/sobre-mi/"[^>]*>Sobre mí<'
assert_grep index.html 'href="/suscribirse/"[^>]*>Suscribirse<'
assert_grep index.html 'TARTAGALENSIS · DESDE TARTAGAL, SALTA'
assert_grep index.html 'href="https://github.com/tartagalensis"'
refute_grep index.html 'href=""'
```
Run: `./scripts/check-site.sh`. Expected: FALLA.

- [ ] **Step 2: Partials**

`_partials/cabecera.html`:
```html
<header class="cabecera">
  <div class="wrap fila">
    <a class="marca" href="{{ "/" | relURL }}">TARTAGALENSIS</a>
    <nav>
      <a href="{{ "/notas/" | relURL }}">Notas</a>
      <a href="{{ "/sobre-mi/" | relURL }}">Sobre mí</a>
      <a href="{{ "/suscribirse/" | relURL }}">Suscribirse</a>
    </nav>
  </div>
</header>
```

`_partials/pie.html` (LinkedIn sale solo si está configurado: así se evita el `href=""`):
```html
<footer class="pie-sitio">
  <div class="wrap">
    <span>TARTAGALENSIS · DESDE TARTAGAL, SALTA</span>
    <span>
      <a href="{{ "/index.xml" | relURL }}">RSS</a>
      {{ with site.Params.linkedin }} · <a href="{{ . }}">LinkedIn</a>{{ end }}
      {{ with site.Params.github }} · <a href="{{ . }}">GitHub</a>{{ end }}
    </span>
  </div>
</footer>
```

- [ ] **Step 3: baseof con fuentes, CSS, cabecera y pie**

En `baseof.html`, agregar dentro de `<head>` antes de `</head>`:
```html
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Courier+Prime:wght@400;700&family=Source+Serif+4:ital,opsz,wght@0,8..60,400;0,8..60,700;1,8..60,400&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="{{ "css/main.css" | relURL }}">
```
y reemplazar el `<body>` por:
```html
<body>
  {{ partial "cabecera.html" . }}
  {{ block "main" . }}{{ end }}
  {{ partial "pie.html" . }}
</body>
```

- [ ] **Step 4: `static/css/main.css`**

```css
:root{
  --papel:#eef0ea; --tinta:#1d2a3a; --texto:#1f232a; --sello:#8a2a2a;
  --gris:#4a5260; --suave:#3b4250; --casillero:#f7f8f4;
  --mono:'Courier Prime','Courier New',monospace;
  --serif:'Source Serif 4',Georgia,serif;
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--papel);color:var(--texto);font-family:var(--serif);overflow-wrap:break-word}
a{color:var(--tinta)}
img,iframe,video{max-width:100%;height:auto}
.wrap{max-width:700px;margin:0 auto;padding:0 20px}
main.wrap{min-height:60vh}

/* Cabecera */
.cabecera{border-bottom:2px solid var(--tinta)}
.cabecera .fila{display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:8px 16px;padding:14px 20px}
.marca{font-family:var(--mono);font-weight:700;font-size:20px;letter-spacing:2px;text-decoration:none;color:var(--tinta)}
.cabecera nav a{font-family:var(--mono);margin-left:18px;text-decoration:none;text-transform:uppercase;font-size:13px;letter-spacing:1px}
.cabecera nav a:first-child{margin-left:0}
.cabecera nav a:hover{text-decoration:underline}

/* Encabezado de nota: casilleros del acta */
.formulario{margin-top:44px;border:2px solid var(--tinta);font-family:var(--mono);color:var(--tinta);font-size:13px;display:grid;grid-template-columns:repeat(4,1fr)}
.formulario div{padding:8px 10px;border-right:1px solid var(--tinta);min-width:0}
.formulario div:last-child{border-right:none}
.formulario span{display:block;font-size:10px;letter-spacing:1px;opacity:.7}
.formulario a{text-decoration:none}
.formulario a:hover{text-decoration:underline}
h1{font-family:var(--serif);font-size:44px;line-height:1.08;letter-spacing:-0.5px;margin:28px 0 12px;color:var(--tinta)}
.bajada{font-size:21px;line-height:1.45;font-style:italic;color:var(--suave);margin:0 0 30px}
.firma{font-family:var(--mono);font-size:13px;color:var(--gris);margin:0 0 30px}

/* Cuerpo */
.cuerpo p,.cuerpo li{font-size:19px;line-height:1.7}
.cuerpo p{margin:0 0 1.2em}
.cuerpo h2,.cuerpo h3{font-family:var(--mono);font-size:15px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--tinta);border-top:1px solid var(--tinta);padding-top:14px;margin:2.2em 0 1em}
.cuerpo h3{border-top-style:dotted}
.cuerpo blockquote{margin:1.6em 0;padding:4px 0 4px 18px;border-left:3px solid var(--sello);font-style:italic;color:var(--suave)}
.cuerpo blockquote p{font-size:18px}
.cuerpo img{display:block;margin:1.6em auto}
.cuerpo table{border-collapse:collapse;font-family:var(--mono);font-size:14px;display:block;overflow-x:auto;max-width:100%}
.cuerpo th,.cuerpo td{border:1px solid var(--tinta);padding:4px 8px}
.cuerpo pre{background:var(--casillero);border:1px solid var(--tinta);padding:12px;overflow-x:auto;font-size:14px}
.cuerpo code{font-family:var(--mono)}
.cuerpo .footnotes{font-size:15px;border-top:1px dotted var(--tinta);margin-top:3em;padding-top:1em}
.cuerpo .footnotes p,.cuerpo .footnotes li{font-size:15px}

/* Gráfico en casillero */
.casillero{margin:2em 0;border:2px solid var(--tinta);background:var(--casillero)}
.casillero .rotulo{font-family:var(--mono);font-size:13px;color:var(--tinta);padding:8px 12px;border-bottom:1px solid var(--tinta)}
.casillero img{display:block;width:100%;height:auto;margin:0}
.casillero .pie{font-family:var(--mono);font-size:12px;padding:8px 12px;border-top:1px dotted var(--tinta);color:var(--gris)}

/* Portada: acta */
.acta-cab{margin-top:44px;border:2px solid var(--tinta);border-bottom:none;font-family:var(--mono);color:var(--tinta)}
.acta-cab .datos{display:flex;justify-content:space-between;flex-wrap:wrap;gap:4px 12px;font-size:11px;padding:8px 12px;border-bottom:1px solid var(--tinta)}
.acta-cab .nombre{font-family:var(--serif);font-weight:700;font-size:40px;padding:10px 12px 0;margin:0}
.acta-cab .sub{font-size:12px;letter-spacing:1px;padding:2px 12px 12px}
.acta-cab .presentacion{font-family:var(--serif);font-style:italic;font-size:18px;color:var(--suave);padding:0 12px 14px;margin:0}
.acta{width:100%;border-collapse:collapse;border:2px solid var(--tinta);font-family:var(--mono);color:var(--tinta);font-size:15px;table-layout:fixed}
.acta th{text-align:left;font-size:11px;letter-spacing:1px;font-weight:400;padding:6px 8px;border-bottom:1px solid var(--tinta)}
.acta td{padding:8px;border-bottom:1px dotted var(--tinta);vertical-align:top}
.acta tr:last-child td{border-bottom:none}
.acta .n{width:52px}
.acta .f{width:96px;text-align:right}
.acta .t{width:170px}
.acta td.f{text-align:right}
.acta a{text-decoration:none}
.acta a:hover{text-decoration:underline}
.titulo-lista{font-family:var(--mono);font-size:15px;text-transform:uppercase;letter-spacing:1px;color:var(--tinta);margin:44px 0 12px}

/* Telegrama */
.telegrama{margin:56px 0 40px;border:2px solid var(--tinta);font-family:var(--mono);color:var(--tinta);position:relative}
.telegrama .tit{padding:10px 14px;border-bottom:1px solid var(--tinta);font-weight:700;letter-spacing:2px}
.telegrama .cuerpo-tel{padding:14px}
.telegrama p{font-size:15px;line-height:1.5;margin:0 0 12px}
.telegrama form{display:flex;border:1px solid var(--tinta)}
.telegrama input{flex:1;min-width:0;border:none;background:transparent;font-family:var(--mono);font-size:15px;padding:10px;color:var(--tinta)}
.telegrama button{border:none;border-left:1px solid var(--tinta);background:var(--tinta);color:var(--papel);font-family:var(--mono);font-weight:700;letter-spacing:1px;padding:0 16px;cursor:pointer}
.sello{position:absolute;right:16px;top:-14px;background:var(--papel);color:var(--sello);border:2px solid var(--sello);font-weight:700;font-size:12px;padding:2px 8px;transform:rotate(-4deg);letter-spacing:1px}

/* Páginas simples */
.pagina{padding-top:12px}

/* Pie */
.pie-sitio{border-top:2px solid var(--tinta);font-family:var(--mono);font-size:12px;color:var(--tinta);padding:16px 0 40px;margin-top:40px}
.pie-sitio .wrap{display:flex;justify-content:space-between;flex-wrap:wrap;gap:8px}

@media (max-width:600px){
  h1{font-size:32px}
  .bajada{font-size:18px}
  .cuerpo p,.cuerpo li{font-size:18px}
  .formulario{grid-template-columns:1fr 1fr}
  .formulario div:nth-child(2){border-right:none}
  .formulario div:nth-child(-n+2){border-bottom:1px solid var(--tinta)}
  .cabecera nav a{margin-left:10px;font-size:11px}
  .acta-cab .nombre{font-size:28px}
  .acta{font-size:13px}
  .acta .t,.acta td.t{display:none}
  .acta .n{width:36px}
  .acta .f{width:78px}
}
```

- [ ] **Step 5: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add -A themes/tartagalensis scripts/check-site.sh
git commit -m "Tema: estilos telegrama, cabecera y pie

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Página de nota, numeración y shortcode `casillero`

**Files:**
- Create: `themes/tartagalensis/layouts/page.html`, `themes/tartagalensis/layouts/_partials/numero-nota.html`, `themes/tartagalensis/layouts/_shortcodes/casillero.html`
- Create (fixture de test): `content/notas/_prueba-sin-temas.md` con `draft: true` (se compila solo con `--buildDrafts` dentro del script)
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: `Params.temas`, `Params.bajada`, `.ReadingTime`, CSS de Task 3.
- Produces: `partial "numero-nota.html" $page` → string `"01".."NN"`, por orden cronológico de las notas publicadas (sin drafts; un draft devuelve "00"). La usa Task 5 (acta).
- Produces: el shortcode `{{< casillero src="…" titulo="…" fuente="…" link="…" >}}`. `src` y `titulo` son obligatorios; `fuente` y `link`, opcionales.

- [ ] **Step 1: Checks que fallan**

Fixture `content/notas/_prueba-sin-temas.md`. Es un draft, nunca se publica, y prueba el Review Focus 1 y el shortcode:
```markdown
---
title: Prueba sin temas
date: 2000-01-01
slug: prueba-sin-temas
draft: true
---
Texto de prueba.

{{< casillero src="/cienciaypol/2021-08-04-defendiendo-las-paso-en-salta_files/Listas a diputados nacionales en Salta 1983-2019@2x.png" titulo="Listas a diputados nacionales en Salta, 1983–2019" fuente="Elaboración propia" >}}
```
En `scripts/check-site.sh`, cambiar la línea del build a `hugo --quiet --gc --buildDrafts -d "$OUT"` y agregar un check de que el draft no se filtra en el build real. Al final del script, antes de `# --- fin checks ---`:
```bash
P=notas/defendiendo-las-paso-en-salta/index.html
assert_grep $P 'class="formulario"'
assert_grep $P '<span>NOTA N\.º</span>02'
assert_grep $P '<span>FECHA</span>04/08/2020'
assert_grep $P 'href="/temas/elecciones/"'
assert_grep $P '<span>LECTURA</span>[0-9]+ MIN'
assert_grep $P '<h1>Defendiendo las PASO en Salta</h1>'
assert_grep notas/votos-de-isa-2019/index.html '<span>NOTA N\.º</span>01'
assert_grep notas/desarrollo-con-raices/index.html '<span>NOTA N\.º</span>05'
assert_grep notas/el-ultimo-tren/index.html 'Germán Epelbaum'
# Review Focus 1: sin temas ni bajada
D=notas/prueba-sin-temas/index.html
assert_grep $D '<span>TEMA</span>—'
refute_grep $D 'class="bajada"'
# shortcode
assert_grep $D 'class="casillero"'
assert_grep $D 'class="rotulo">Listas a diputados nacionales en Salta, 1983–2019<'
refute_grep $D '[Ff]ig\.'
# el draft no debe salir en el build real
hugo --quiet -d "$OUT.real" >/dev/null 2>&1
[ ! -d "$OUT.real/notas/prueba-sin-temas" ] || { echo "FALLA: el draft se publica"; FALLAS=$((FALLAS+1)); }
```
Run: `./scripts/check-site.sh`. Expected: FALLA (no hay `page.html`).

- [ ] **Step 2: `_partials/numero-nota.html`**

```html
{{- $n := 0 -}}
{{- range $i, $p := (where (where site.RegularPages "Section" "notas") "Draft" false).ByDate -}}
  {{- if eq $p.RelPermalink $.RelPermalink }}{{ $n = add $i 1 }}{{ end -}}
{{- end -}}
{{- return (printf "%02d" $n) -}}
```

- [ ] **Step 3: `page.html`**

```html
{{ define "main" }}
<main class="wrap">
  <div class="formulario">
    <div><span>NOTA N.º</span>{{ partial "numero-nota.html" . }}</div>
    <div><span>FECHA</span>{{ .Date.Format "02/01/2006" }}</div>
    <div><span>TEMA</span>{{ with .GetTerms "temas" }}{{ range $i, $t := . }}{{ if $i }} · {{ end }}<a href="{{ $t.RelPermalink }}">{{ upper $t.LinkTitle }}</a>{{ end }}{{ else }}—{{ end }}</div>
    <div><span>LECTURA</span>{{ .ReadingTime }} MIN</div>
  </div>
  <h1>{{ .Title }}</h1>
  {{ with .Params.bajada }}<p class="bajada">{{ . }}</p>{{ end }}
  {{ with .Params.author }}{{ if ne . site.Params.autor }}<p class="firma">Por {{ . }}</p>{{ end }}{{ end }}
  <article class="cuerpo">
    {{ .Content }}
  </article>
  {{ partial "telegrama.html" . }}
</main>
{{ end }}
```
Para que compile antes de Task 6, crear `_partials/telegrama.html` vacío (con un solo comentario `{{/* Task 6 */}}`).

- [ ] **Step 4: `_shortcodes/casillero.html`**

```html
{{- $src := .Get "src" | default "" -}}
{{- $titulo := .Get "titulo" | default "" -}}
{{- if or (eq $src "") (eq $titulo "") -}}
  {{- errorf "casillero: faltan src o titulo en %s" .Position -}}
{{- end -}}
<figure class="casillero">
  <div class="rotulo">{{ $titulo }}</div>
  <img src="{{ $src | relURL }}" alt="{{ $titulo }}" loading="lazy">
  {{- if or (.Get "fuente") (.Get "link") }}
  <div class="pie">{{ with .Get "fuente" }}Fuente: {{ . }}{{ end }}{{ if and (.Get "fuente") (.Get "link") }} · {{ end }}{{ with .Get "link" }}<a href="{{ . }}">ver interactivo</a>{{ end }}</div>
  {{- end }}
</figure>
```
Agregar al CSS (`.casillero` es un `<figure>`): `figure.casillero{margin-left:0;margin-right:0}`.

- [ ] **Step 5: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add -A themes/tartagalensis scripts/check-site.sh content/notas/_prueba-sin-temas.md
git commit -m "Tema: página de nota con casilleros, numeración y shortcode casillero

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: Portada (acta), listado de notas y páginas de tema

**Files:**
- Create: `themes/tartagalensis/layouts/_partials/acta.html`, `section.html`, `term.html`, `taxonomy.html`, `404.html`
- Modify: `themes/tartagalensis/layouts/home.html`
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: `partial "numero-nota.html"` (Task 4), `Params.temas`.
- Produces: `partial "acta.html" (dict "paginas" $paginas)`, que renderiza la tabla de notas, de la más nueva a la más vieja.

- [ ] **Step 1: Checks que fallan**

```bash
assert_grep index.html 'class="acta"'
assert_grep index.html 'MESA N\.º 0005'
assert_grep index.html 'DISTRITO: SALTA'
assert_grep index.html 'Elecciones, federalismo y datos, desde el Norte\.'
# orden: la más nueva primero
primera=$(grep -oE 'href="/notas/[^"]+/"' "$OUT/index.html" | head -1)
[ "$primera" = 'href="/notas/desarrollo-con-raices/"' ] || { echo "FALLA: orden de portada ($primera)"; FALLAS=$((FALLAS+1)); }
refute_grep index.html 'prueba-sin-temas'   # drafts fuera del acta aunque se compilen con -D
assert_file notas/index.html
assert_grep notas/index.html 'class="acta"'
# Review Focus 4: temas sin tildes en la URL
assert_file temas/politica-argentina/index.html
assert_file temas/metodos/index.html
assert_grep temas/metodos/index.html 'votos-de-isa-2019'
refute_grep temas/metodos/index.html 'desarrollo-con-raices'
assert_file temas/index.html
assert_file 404.html
# Review Focus 2: la tabla del acta nunca fuerza ancho fijo en px mayor a 360
refute_grep css/main.css 'min-width:[4-9][0-9]{2}px'
```
Run: `./scripts/check-site.sh`. Expected: FALLA.

- [ ] **Step 2: `_partials/acta.html`**

```html
<table class="acta">
  <thead><tr><th class="n">N.º</th><th>NOTA</th><th class="t">TEMA</th><th class="f">FECHA</th></tr></thead>
  <tbody>
  {{- range (where .paginas "Draft" false).ByDate.Reverse }}
    <tr>
      <td class="n">{{ partial "numero-nota.html" . }}</td>
      <td><a href="{{ .RelPermalink }}">{{ .Title }}</a></td>
      <td class="t">{{ with .GetTerms "temas" }}{{ (index . 0).LinkTitle }}{{ else }}—{{ end }}</td>
      <td class="f">{{ .Date.Format "02/01/06" }}</td>
    </tr>
  {{- end }}
  </tbody>
</table>
```

- [ ] **Step 3: `home.html`**

```html
{{ define "main" }}
{{ $notas := where site.RegularPages "Section" "notas" }}
{{ $publicadas := where $notas "Draft" false }}
<main class="wrap">
  <div class="acta-cab">
    <div class="datos"><span>DISTRITO: SALTA</span><span>SECCIÓN: GRAL. SAN MARTÍN</span><span>MESA N.º {{ printf "%04d" (len $publicadas) }}</span></div>
    <h1 class="nombre">TARTAGALENSIS</h1>
    <div class="sub">ACTA DE NOTAS · ESCRUTINIO PERMANENTE</div>
    <p class="presentacion">{{ site.Params.description }}</p>
  </div>
  {{ partial "acta.html" (dict "paginas" $notas) }}
  {{ partial "telegrama.html" . }}
</main>
{{ end }}
```

- [ ] **Step 4: `section.html`, `term.html`, `taxonomy.html`, `404.html`**

`section.html`:
```html
{{ define "main" }}
<main class="wrap">
  <h2 class="titulo-lista">Todas las notas</h2>
  {{ partial "acta.html" (dict "paginas" .RegularPages) }}
</main>
{{ end }}
```
`term.html`:
```html
{{ define "main" }}
<main class="wrap">
  <h2 class="titulo-lista">Tema: {{ .Title }}</h2>
  {{ partial "acta.html" (dict "paginas" .Pages) }}
</main>
{{ end }}
```
`taxonomy.html`:
```html
{{ define "main" }}
<main class="wrap">
  <h2 class="titulo-lista">Temas</h2>
  <table class="acta">
    <thead><tr><th>TEMA</th><th class="f">NOTAS</th></tr></thead>
    <tbody>{{ range .Data.Terms.Alphabetical }}<tr><td><a href="{{ .Page.RelPermalink }}">{{ .Page.Title }}</a></td><td class="f">{{ len (where .Pages "Draft" false) }}</td></tr>{{ end }}</tbody>
  </table>
</main>
{{ end }}
```
`404.html`:
```html
{{ define "main" }}
<main class="wrap">
  <div class="formulario" style="grid-template-columns:1fr"><div><span>ESTADO</span>MESA NO ENCONTRADA</div></div>
  <h1>Esta página no existe</h1>
  <p class="bajada">Puede que la nota se haya mudado. <a href="{{ "/" | relURL }}">Volver al acta de notas.</a></p>
</main>
{{ end }}
```

- [ ] **Step 5: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 6: Mirarlo**

Run: `hugo server --buildDrafts=false`. Abrir http://localhost:1313/, una nota y `/temas/elecciones/`, primero a ancho completo y después a 360px en las herramientas de desarrollador: no tiene que haber scroll horizontal (Review Focus 2).

- [ ] **Step 7: Commit**

```bash
git add -A themes/tartagalensis scripts/check-site.sh
git commit -m "Tema: portada acta, listado de notas y páginas de tema

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: Telegrama, página de suscripción y RSS completo

**Files:**
- Modify: `themes/tartagalensis/layouts/_partials/telegrama.html`
- Create: `content/suscribirse.md`, `themes/tartagalensis/layouts/pagina.html`, `themes/tartagalensis/layouts/rss.xml`
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: `site.Params.buttondown` (Task 1).
- Produces: `layout: pagina` para páginas sueltas, que también usa Task 7. Feed en `/index.xml` solo con notas y con el contenido completo.

- [ ] **Step 1: Checks que fallan**

```bash
P=notas/defendiendo-las-paso-en-salta/index.html
assert_grep $P 'class="telegrama"'
assert_grep $P 'TELEGRAMA · SUSCRIPCIÓN'
assert_grep $P 'SIN FRANQUEO'
assert_grep $P 'Si te gustó y querés recibir las notas nuevas cuando salgan, suscribite\.'
assert_grep $P 'action="https://buttondown\.com/api/emails/embed-subscribe/tartagalensis"'
assert_grep $P '>ENVIAR<'
refute_grep $P 'STOP'
assert_file suscribirse/index.html
assert_grep suscribirse/index.html 'class="telegrama"'
assert_file index.xml
assert_grep index.xml '<link>https://tartagalensis.github.io/notas/desarrollo-con-raices/</link>'
assert_grep index.xml 'Tartagal, cuando hablamos de desarrollo'   # contenido completo, no resumen
refute_grep index.xml 'prueba-sin-temas'
refute_grep index.xml '/sobre-mi/'
# Review Focus 5: sin usuario de Buttondown no hay formulario roto
SIN="$OUT.sinbd"
HUGO_PARAMS_BUTTONDOWN="" hugo --quiet -d "$SIN" >/dev/null 2>"$SIN.log"
! grep -q 'embed-subscribe' "$SIN/notas/defendiendo-las-paso-en-salta/index.html" || { echo "FALLA: formulario sin usuario"; FALLAS=$((FALLAS+1)); }
grep -q 'buttondown' "$SIN.log" || { echo "FALLA: no avisa que falta buttondown"; FALLAS=$((FALLAS+1)); }
```
Run: `./scripts/check-site.sh`. Expected: FALLA.

Nota: Hugo lee `HUGO_PARAMS_BUTTONDOWN` como override de `params.buttondown`. Si con una variable vacía no logra pisar el valor, usar `hugo --config config.toml,scripts/sin-buttondown.toml` con un archivo `scripts/sin-buttondown.toml` que contenga `[params]\n  buttondown = ""`.

- [ ] **Step 2: `_partials/telegrama.html`**

```html
{{- with site.Params.buttondown -}}
<section class="telegrama" id="suscribirse">
  <div class="sello">SIN FRANQUEO</div>
  <div class="tit">TELEGRAMA · SUSCRIPCIÓN</div>
  <div class="cuerpo-tel">
    <p>Si te gustó y querés recibir las notas nuevas cuando salgan, suscribite.</p>
    <form action="https://buttondown.com/api/emails/embed-subscribe/{{ . }}" method="post" target="_blank">
      <label for="bd-email" style="position:absolute;left:-9999px">Tu correo</label>
      <input type="email" name="email" id="bd-email" placeholder="tu@correo.com" required>
      <input type="hidden" value="1" name="embed">
      <button type="submit">ENVIAR</button>
    </form>
  </div>
</section>
{{- else -}}
{{- warnf "params.buttondown está vacío: no se muestra el telegrama de suscripción" -}}
{{- end -}}
```
`warnf` se imprime una vez por página. Si el log queda muy cargado, se puede cambiar por `warnidf`, pero no es necesario.

- [ ] **Step 3: `pagina.html` y `content/suscribirse.md`**

`pagina.html`:
```html
{{ define "main" }}
<main class="wrap pagina">
  <h1>{{ .Title }}</h1>
  <article class="cuerpo">{{ .Content }}</article>
  {{ if .Params.telegrama }}{{ partial "telegrama.html" . }}{{ end }}
</main>
{{ end }}
```
`content/suscribirse.md`:
```markdown
---
title: Suscribirse
layout: pagina
url: /suscribirse/
telegrama: true
---
Cada vez que publico una nota nueva, te llega al correo. Sin spam: podés darte de baja cuando quieras desde el mismo mail.
```

- [ ] **Step 4: `rss.xml`**

```xml
{{- $notas := where (where site.RegularPages "Section" "notas") "Draft" false -}}
{{- printf "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>" | safeHTML }}
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>{{ site.Title }}</title>
    <link>{{ site.Home.Permalink }}</link>
    <description>{{ site.Params.description }}</description>
    <language>{{ site.LanguageCode }}</language>
    {{ with $notas }}<lastBuildDate>{{ (index $notas.ByDate.Reverse 0).Date.Format "Mon, 02 Jan 2006 15:04:05 -0700" | safeHTML }}</lastBuildDate>{{ end }}
    <atom:link href="{{ .Permalink }}" rel="self" type="application/rss+xml" />
    {{- range first 20 $notas.ByDate.Reverse }}
    <item>
      <title>{{ .Title }}</title>
      <link>{{ .Permalink }}</link>
      <pubDate>{{ .Date.Format "Mon, 02 Jan 2006 15:04:05 -0700" | safeHTML }}</pubDate>
      <guid>{{ .Permalink }}</guid>
      <description>{{ .Content | transform.XMLEscape | safeHTML }}</description>
    </item>
    {{- end }}
  </channel>
</rss>
```

- [ ] **Step 5: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 6: Commit**

```bash
git add -A themes/tartagalensis content/suscribirse.md scripts
git commit -m "Telegrama de suscripción con Buttondown, página /suscribirse/ y RSS completo

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Sobre mí y descripción del sitio (con Franco)

**Files:**
- Create: `content/sobre-mi.md`
- Delete: `content/about.md`
- Modify: `config.toml` (`params.linkedin`, `params.description` si Franco la cambia)
- Modify: `scripts/check-site.sh`

**Interfaces:**
- Consumes: `layout: pagina` (Task 6).

- [ ] **Step 1: Pedirle a Franco** la URL de LinkedIn, que confirme o cambie la descripción ("Elecciones, federalismo y datos, desde el Norte.") y que corrija el borrador de abajo. Esta task no se commitea sin su OK sobre el texto.

- [ ] **Step 2: Checks que fallan**

```bash
assert_file sobre-mi/index.html
assert_grep sobre-mi/index.html 'linkedin\.com/in/'
refute_grep sobre-mi/index.html 'I am Franco'
[ ! -d "$OUT/about" ] || { echo "FALLA: existe /about/"; FALLAS=$((FALLAS+1)); }
assert_grep index.html 'href="https://(www\.)?linkedin\.com/in/[^"]+"[^>]*>LinkedIn<'
```
Run: `./scripts/check-site.sh`. Expected: FALLA.

- [ ] **Step 3: Borrador de `content/sobre-mi.md`** (propuesta basada en el `about.md` actual; reemplazar con la versión que apruebe Franco)

```markdown
---
title: Sobre mí
layout: pagina
url: /sobre-mi/
telegrama: true
---
Soy Franco Galeano —en redes, Tartagalensis—, politólogo por la Universidad Torcuato Di Tella y científico de datos nacido en [Tartagal](https://www.google.com/maps?q=tartagal), Salta.

Escribo sobre elecciones, federalismo y democracia, casi siempre con datos de por medio y casi siempre mirando desde el Norte. Algunas notas son análisis con modelos y gráficos; otras son opinión pura.

También me gustan los deportes y lo que los datos tienen para decir de ellos, sobre todo en básquet, rugby y fútbol.

Si querés conocer mi recorrido profesional, está en [LinkedIn](URL_DE_LINKEDIN). El código de mis análisis está en [GitHub](https://github.com/tartagalensis).
```
Reemplazar `URL_DE_LINKEDIN` por la URL real, y cargar la misma en `config.toml` → `params.linkedin`. Después: `git rm content/about.md`.

- [ ] **Step 4: Correr el check**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 5: Commit**

```bash
git add -A content config.toml scripts/check-site.sh
git commit -m "Sobre mí nuevo en /sobre-mi/ y link a LinkedIn

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Publicación con GitHub Actions + Pages

**Files:**
- Create: `.github/workflows/hugo.yml`

**Interfaces:**
- Consumes: versión de Hugo de Global Constraints.

- [ ] **Step 1: Workflow**

```yaml
name: Publicar sitio

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      HUGO_VERSION: 0.167.0
    steps:
      - uses: actions/checkout@v4
      - name: Instalar Hugo
        run: |
          wget -q -O hugo.deb "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-amd64.deb"
          sudo dpkg -i hugo.deb
          hugo version
      - name: Verificar
        run: ./scripts/check-site.sh
      - name: Compilar
        run: hugo --gc --minify
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - id: deployment
        uses: actions/deploy-pages@v4
```

Sobre el paso "Verificar": el CI corre el mismo script que en local, así que un build roto no se publica.

- [ ] **Step 2: Validar el YAML localmente**

Run: `ruby -ryaml -e 'YAML.load_file(".github/workflows/hugo.yml"); puts "ok"'`
Expected: `ok`.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/hugo.yml
git commit -m "Workflow de GitHub Actions para publicar en Pages

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4: Paso manual de Franco**

En https://github.com/tartagalensis/tartagalensis.github.io/settings/pages → **Build and deployment → Source: GitHub Actions**.

---

### Task 9: Revisión final, merge y apagado de Netlify

**Files:** ninguno nuevo.

- [ ] **Step 1: Verificación completa**

Run: `./scripts/check-site.sh`. Expected: `OK`.

- [ ] **Step 2: Revisión visual con Franco**

Run: `hugo server`. Revisar a ancho de escritorio y a 360px:
1. La portada.
2. `/notas/votos-de-isa-2019/`, la nota `.Rmd` con más imágenes y notas al pie.
3. `/notas/migracion-del-voto-2023/`, que tiene embeds de Flourish.
4. `/temas/elecciones/`.
5. `/sobre-mi/` y `/suscribirse/`.
6. Una URL inexistente, que tiene que mostrar el 404.

Corregir lo que marque Franco antes de seguir.

- [ ] **Step 3: Revisión del branch completo** con `superpowers:requesting-code-review`.

- [ ] **Step 4: Merge y push (con OK explícito de Franco)**

```bash
git checkout main
git merge --no-ff rediseno -m "Rediseño: tema telegrama, notas por temas, suscripción

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
git push origin main
```

- [ ] **Step 5: Verificar la publicación**

Ver el run en https://github.com/tartagalensis/tartagalensis.github.io/actions (debe terminar en verde) y después:
```bash
curl -s https://tartagalensis.github.io/ | grep -o '<title>[^<]*</title>'
curl -s -o /dev/null -w "%{http_code}\n" https://tartagalensis.github.io/notas/defendiendo-las-paso-en-salta/
```
Expected: `<title>Tartagalensis</title>` y `200`.

- [ ] **Step 6: Pasos manuales de Franco**

1. Crear la cuenta de Buttondown con el usuario `tartagalensis` (o actualizar `params.buttondown` si eligió otro). En Settings → RSS-to-email, cargar `https://tartagalensis.github.io/index.xml`.
2. Probar una suscripción con su propio mail.
3. Apagar el sitio de Netlify: Site configuration → Delete project (o "Stop builds").
