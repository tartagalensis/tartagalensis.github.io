# Rediseño de Tartagalensis — diseño

Fecha: 2026-10-10
Estado: borrador para revisión

## Objetivo

Relanzar (rebranding) el blog personal en https://tartagalensis.github.io como un espacio de notas
de opinión y análisis al estilo "Substack propio": lectura cómoda, identidad visual
fuerte y suscripción por mail. Después del rediseño, el flujo habitual será que Franco
pase notas (texto o análisis de sus repos) y se publiquen rápido.

**Éxito =** sitio con identidad "telegrama electoral", una sola sección de notas,
sobre mí actualizado, suscripción funcionando vía Buttondown, y las notas anteriores
publicadas con sus fechas originales.

**Fuera de alcance:** comentarios de lectores, versión en inglés, migrar de Hugo,
redirecciones desde netlify.app (se apaga; los links viejos dejan de andar, aceptado).

## 1. Identidad visual: "Telegrama electoral, acta como marco"

Referencia: mockup aprobado en `.superpowers/brainstorm/.../content/nota-completa.html`.

- **Paleta:** papel `#eef0ea`, tinta `#1d2a3a`, texto `#1f232a`, sello `#8a2a2a`.
- **Tipografías (Google Fonts):** Courier Prime (marco: cabecera, menú, casilleros,
  subtítulos, pie) y Source Serif 4 (título y cuerpo de nota).
- **Regla:** el lenguaje de formulario/acta vive en los bordes; el cuerpo de lectura es
  serif grande (19px, interlineado 1.7, ancho máx. ~700px).
- **Elementos:**
  - Cabecera: `TARTAGALENSIS` en mono + menú `Notas · Sobre mí · Suscribirse`.
  - Encabezado de nota: grilla de casilleros `NOTA N.º · FECHA · TEMA · LECTURA`.
  - Subtítulos (`##`) en mono mayúscula con filete superior.
  - Gráficos en "casillero": recuadro con rótulo = título del gráfico (sin "Fig. N")
    y pie con fuente/link opcional.
  - Citas con filete rojo sello a la izquierda.
  - Suscripción como telegrama: título `TELEGRAMA · SUSCRIPCIÓN`, sello rotado
    `SIN FRANQUEO`, texto: "Si te gustó y querés recibir las notas nuevas cuando salgan,
    suscribite." (puntuación normal, sin "STOP"). Campo de mail + botón `ENVIAR`.
  - Pie: `TARTAGALENSIS · DESDE TARTAGAL, SALTA` + links RSS · LinkedIn · GitHub.
- **Portada:** acta de notas — encabezado tipo formulario (distrito/sección/mesa)
  y tabla `N.º · NOTA · FECHA · TEMA` con todas las notas, más reciente primero.
- **Responsive:** en celular la grilla de casilleros pasa a 2×2; títulos 32px.

## 2. Estructura y contenido

- **Menú:** Notas · Sobre mí · Suscribirse (página `/suscribirse/` con el telegrama; el mismo bloque va al pie de cada nota).
- **Notas:** una sola sección `content/notas/`. Los antiguos "Random" y "Ciencia y
  política" desaparecen como secciones; pasan a ser **temas** (taxonomía Hugo `temas`)
  con página propia de listado. Temas iniciales: Elecciones, Salta, Federalismo,
  Métodos, Desarrollo (ajustables).
- **Numeración:** `NOTA N.º` se calcula por orden cronológico (la más vieja = 01).
- **Lectura:** minutos estimados por Hugo (`.ReadingTime`).
- **Migración de notas existentes:**
  - Las 5 notas restantes (4 de `cienciaypol/`, 1 de `random/`) se mueven a
    `content/notas/` con sus fechas originales ("V0" del relanzamiento) y frontmatter
    normalizado (`temas`, `bajada` opcional).
  - Se borra "Bienvenidos al tren" (`content/post/2020-05-24-…`). La primera nota nueva
    funcionará como "la vuelta".
  - Se elimina el CV (`content/cv/`).
  - Sin redirecciones: el dominio cambia a github.io y netlify.app se apaga, así que no
    hay URLs viejas que preservar.
- **Sobre mí:** en `/sobre-mi/`, solo en español, actualizado, con link a LinkedIn. Claude propone un
  borrador a partir del texto actual; Franco lo corrige.
- **Metadatos del sitio:** título `Tartagalensis`; descripción = frase definida junto
  con el sobre mí. Se eliminan textos genéricos ("A Hugo website", etc.).

## 3. Implementación técnica

- **Tema propio** `themes/tartagalensis/`: plantillas `baseof`, `index` (acta),
  `single` (nota), `list`/`taxonomy` (tema), `about`, parciales (cabecera, telegrama,
  pie, casillero) y un único `css/main.css`. Se deja de usar `hugo-lithium`.
- **Shortcode `casillero`** para gráficos con rótulo y pie:
  `{{< casillero src="…" titulo="…" fuente="…" link="…" >}}`.
  Las imágenes Markdown simples siguen funcionando sin recuadro.
- **Compatibilidad R:** las notas `.Rmd` existentes (con su `.html` renderizado por
  blogdown) siguen funcionando; los análisis nuevos pueden ir como `.Rmd` (blogdown) o
  como `.md` con gráficos exportados a PNG.
- **Hosting: GitHub Pages.** El repo se renombró a `tartagalensis/tartagalensis.github.io`
  (2026-10-10), así que el sitio vive en la raíz `https://tartagalensis.github.io/`
  (`baseURL` en `config.toml`). Workflow `.github/workflows/hugo.yml` (GitHub Actions):
  en cada push a `main` instala una versión fija y moderna de Hugo extended, corre
  `hugo --gc --minify` y publica `public/` con `actions/deploy-pages`. En
  Settings → Pages la fuente debe ser "GitHub Actions" (paso manual de Franco).
- **Sin vistas previas por PR:** las notas se revisan localmente
  (`blogdown::serve_site()` o `hugo server`) antes de subirlas.
- **Netlify** se apaga recién cuando github.io esté publicado y verificado (paso manual
  de Franco).
- **`public/`** sale del repo y entra al `.gitignore` (está desactualizada; el workflow
  la regenera).
- **Buttondown:** Franco crea la cuenta; el formulario apunta al endpoint de embed de
  Buttondown con su usuario. Se configura RSS-to-email sobre el feed de `notas`.
  El feed RSS debe incluir el contenido completo de la nota.
- **Highlight.js / MathJax:** se mantiene resaltado de código para R solo si alguna nota
  lo usa; MathJax se elimina salvo que una nota lo requiera.

## 4. Verificación

- Compilación local sin errores (`hugo` / `blogdown::serve_site()`).
- Revisión visual en escritorio y celular de: portada, una nota `.Rmd` vieja, una `.md`,
  página de tema, sobre mí.
- El workflow de Actions termina en verde y https://tartagalensis.github.io/ sirve el
  sitio nuevo con las 5 notas viejas y sus fechas originales.
- Envío de prueba de suscripción a Buttondown.
- Trabajo en rama `rediseno`; merge a `main` (que publica) recién con aprobación de
  Franco sobre la vista local.

## 5. Después del rediseño (no parte de esta implementación)

Flujo de notas: Franco pasa texto o señala un repo/análisis → Claude arma la nota
(`.md`/`.Rmd`, temas, gráficos en casillero) → revisión → publicación.
