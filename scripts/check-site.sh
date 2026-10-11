#!/usr/bin/env bash
# Compila el sitio en un directorio temporal y valida el HTML generado.
set -uo pipefail
cd "$(dirname "$0")/.."
OUT="$(mktemp -d)"
FALLAS=0

if ! hugo --gc -d "$OUT" > "$OUT.log" 2>&1; then
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

# --- fin checks ---
if [ "$FALLAS" -gt 0 ]; then echo "$FALLAS falla(s). Build en $OUT"; exit 1; fi
echo "OK. Build en $OUT"
