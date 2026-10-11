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

# --- fin checks ---
if [ "$FALLAS" -gt 0 ]; then echo "$FALLAS falla(s). Build en $OUT"; exit 1; fi
echo "OK. Build en $OUT"
