#!/usr/bin/env bash
# Compila el sitio en un directorio temporal y valida el HTML generado.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)"
FALLAS=0

if ! hugo --gc --buildDrafts -d "$OUT" > "$OUT.log" 2>&1; then
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

for s in votos-de-isa-2019 defendiendo-las-paso-en-salta el-ultimo-tren migracion-del-voto-2023 desarrollo-con-raices; do
  assert_file "notas/$s/index.html"
done
[ ! -d "$OUT/cienciaypol/votos-de-isa-2019" ] && [ ! -d "$OUT/random" ] || { echo "FALLA: quedan secciones viejas"; FALLAS=$((FALLAS+1)); }
# imágenes absolutas de las notas .Rmd (Review Focus 3)
while IFS= read -r img; do
  [ -n "$img" ] && assert_file "$(printf "%b" "${img//%/\\x}")"
done < <(grep -ohE "src=\"/cienciaypol/[^\"]+\"" content/notas/*.html 2>/dev/null | sed "s/^src=\"\///; s/\"\$//")

assert_file css/main.css
assert_grep index.html 'fonts.googleapis.com/css2\?family=Courier\+Prime'
assert_grep index.html 'class="marca"[^>]*>TARTAGALENSIS<'
assert_grep index.html 'href="/notas/"[^>]*>Notas<'
assert_grep index.html 'href="/sobre-mi/"[^>]*>Sobre mí<'
assert_grep index.html 'href="/suscribirse/"[^>]*>Suscribirse<'
assert_grep index.html 'TARTAGALENSIS · DESDE TARTAGAL, SALTA'
assert_grep index.html 'href="https://github.com/tartagalensis"'
refute_grep index.html 'href=""'

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

assert_grep index.html 'class="acta"'
assert_grep index.html 'MESA N\.º 0005'
assert_grep index.html 'DISTRITO: SALTA'
assert_grep index.html 'Elecciones, federalismo y datos, desde el Norte\.'
# orden: la más nueva primero
primera=$(grep -oE 'href="/notas/[^"]+/"' "$OUT/index.html" | head -1)
[ "$primera" = 'href="/notas/desarrollo-con-raices/"' ] || { echo "FALLA: orden de portada ($primera)"; FALLAS=$((FALLAS+1)); }
refute_grep index.html 'prueba-sin-temas'
assert_file notas/index.html
assert_grep notas/index.html 'class="acta"'
# Review Focus 4: temas sin tildes en la URL
assert_file temas/politica-argentina/index.html
assert_file temas/metodos/index.html
assert_grep temas/metodos/index.html 'votos-de-isa-2019'
refute_grep temas/metodos/index.html 'desarrollo-con-raices'
assert_file temas/index.html
assert_file 404.html
# Review Focus 2: ningún ancho mínimo fijo mayor a 360px
refute_grep css/main.css 'min-width:[4-9][0-9]{2}px'

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
assert_grep index.xml 'Tartagal, cuando hablamos de desarrollo'
refute_grep index.xml 'prueba-sin-temas'
refute_grep index.xml '/sobre-mi/'
# Review Focus 5: sin usuario de Buttondown no hay formulario roto
SIN="$OUT.sinbd"
hugo --config config.toml,scripts/sin-buttondown.toml -d "$SIN" >"$SIN.log" 2>&1
! grep -q 'embed-subscribe' "$SIN/notas/defendiendo-las-paso-en-salta/index.html" || { echo "FALLA: formulario sin usuario"; FALLAS=$((FALLAS+1)); }
grep -q 'buttondown' "$SIN.log" || { echo "FALLA: no avisa que falta buttondown"; FALLAS=$((FALLAS+1)); }

assert_file sobre-mi/index.html
assert_grep sobre-mi/index.html 'linkedin\.com/in/'
refute_grep sobre-mi/index.html 'I am Franco'
[ ! -d "$OUT/about" ] || { echo "FALLA: existe /about/"; FALLAS=$((FALLAS+1)); }
assert_grep index.html 'href="https://(www\.)?linkedin\.com/in/[^"]+"[^>]*>LinkedIn<'

# restos de citas pegadas desde ChatGPT
for f in $(cd "$OUT" && find notas -name index.html); do refute_grep "$f" "contentReference|oaicite"; done

# --- fin checks ---
if [ "$FALLAS" -gt 0 ]; then echo "$FALLAS falla(s). Build en $OUT"; exit 1; fi
echo "OK. Build en $OUT"
