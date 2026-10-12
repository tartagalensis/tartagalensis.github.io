"""
Genera static/compartir.png (1200x630), la imagen que muestran Facebook, WhatsApp,
X, etc. al compartir un link del blog cuando la nota no tiene gráfico propio.

Uso: /usr/bin/python3 scripts/imagen-compartir.py
"""

from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

PAPEL, TINTA, SELLO = "#eef0ea", "#1d2a3a", "#8a2a2a"
SALIDA = Path(__file__).resolve().parent.parent / "static" / "compartir.png"

fig = plt.figure(figsize=(12, 6.3), dpi=100, facecolor=PAPEL)
ax = fig.add_axes((0, 0, 1, 1))
ax.set_xlim(0, 1200)
ax.set_ylim(0, 630)
ax.axis("off")

# Marco doble de formulario
ax.add_patch(Rectangle((40, 40), 1120, 550, fill=False, ec=TINTA, lw=3))
ax.add_patch(Rectangle((52, 52), 1096, 526, fill=False, ec=TINTA, lw=1))
ax.plot([52, 1148], [490, 490], color=TINTA, lw=1)

f = dict(family="Courier New", color=TINTA)
ax.text(80, 528, "DISTRITO: SALTA   SECCIÓN: GRAL. SAN MARTÍN", fontsize=17, va="center", **f)
ax.text(600, 330, "TARTAGALENSIS", fontsize=78, fontweight="bold", ha="center", va="center", **f)
ax.text(600, 225, "ACTA DE NOTAS · ESCRUTINIO PERMANENTE", fontsize=19, ha="center", va="center", **f)
ax.text(600, 140, "Mis dos centavos sobre lo que pasa, desde el Norte.", fontsize=24,
        ha="center", va="center", family="serif", style="italic", color=TINTA)

# Sello
ax.text(1010, 528, "SIN FRANQUEO", fontsize=18, fontweight="bold", ha="center", va="center",
        rotation=-6, family="Courier New", color=SELLO,
        bbox=dict(boxstyle="square,pad=0.35", fc="none", ec=SELLO, lw=2.5))

fig.savefig(SALIDA, dpi=100, facecolor=PAPEL)
print(SALIDA)
