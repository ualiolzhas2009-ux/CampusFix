"""Part C: run the three SQL queries on the Assignment 3 database and draw one chart per question (EN + RU)."""
import os
import sqlite3
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm

DB = os.path.join(os.path.dirname(__file__), "..", "database", "campusfix.sqlite")
OUT = os.path.join(os.path.dirname(__file__), "charts") + os.sep
os.makedirs(OUT, exist_ok=True)
for f in fm.findSystemFonts():
    if "DejaVuSans" in f:
        fm.fontManager.addfont(f)
plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10, "axes.edgecolor": "#898781",
                     "axes.labelcolor": "#52514e", "xtick.color": "#52514e", "ytick.color": "#52514e",
                     "axes.spines.top": False, "axes.spines.right": False, "figure.facecolor": "white"})
INK, MUTED, BAR = "#0b0b0b", "#898781", "#2f3b8f"

Q1 = """SELECT category, COUNT(*) AS reports
FROM reports
GROUP BY category
ORDER BY reports DESC;"""

Q2 = """SELECT date(created_at, 'weekday 0', '-6 days') AS week_start,
       COUNT(*) AS reports
FROM reports
GROUP BY week_start
ORDER BY week_start;"""

Q3 = """SELECT r.category,
       COUNT(*) AS fixed_reports,
       ROUND(AVG((julianday(h.changed_at) - julianday(r.created_at)) * 24), 1) AS avg_hours_to_fix
FROM reports r
JOIN status_history h ON h.report_id = r.report_id AND h.to_status = 'Fixed'
GROUP BY r.category
ORDER BY avg_hours_to_fix DESC;"""

con = sqlite3.connect(DB)
r1 = con.execute(Q1).fetchall()
r2 = con.execute(Q2).fetchall()
r3 = con.execute(Q3).fetchall()
TOTAL = con.execute("SELECT COUNT(*) FROM reports").fetchone()[0]
FIXED = con.execute("SELECT COUNT(*) FROM reports WHERE status='Fixed'").fetchone()[0]
RANGE = con.execute("SELECT date(MIN(created_at)), date(MAX(created_at)) FROM reports").fetchone()

CAT_RU = {"Socket": "Розетка", "Computer": "Компьютер", "Projector": "Проектор", "Air conditioner": "Кондиционер",
          "Other": "Другое", "Restroom": "Туалет", "Furniture": "Мебель", "Lights": "Свет"}
TXT = {
    "en": dict(t1="Which equipment is reported most often?", x1="Number of reports",
               t2="How many reports arrive each week?", y2="Reports per week", x2="Week starting (2026)",
               t3="How long does a fix take, by category?", x3="Average time from report to Fixed (hours)",
               src=f"Source: CampusFix database (Assignment 3), {TOTAL} test reports, {RANGE[0]} – {RANGE[1]}.",
               src3=f"Source: CampusFix database (Assignment 3), {FIXED} fixed test reports; n = number of fixed reports.",
               part="first {} days", n="n"),
    "ru": dict(t1="Какое оборудование ломается чаще всего?", x1="Количество заявок",
               t2="Сколько заявок приходит каждую неделю?", y2="Заявок в неделю", x2="Неделя, начиная с (2026)",
               t3="Сколько длится ремонт, по категориям?", x3="Среднее время от заявки до Fixed (часы)",
               src=f"Источник: база CampusFix (Задание 3), {TOTAL} тестовых заявок, {RANGE[0]} – {RANGE[1]}.",
               src3=f"Источник: база CampusFix (Задание 3), {FIXED} исправленных тестовых заявок; n — число исправленных.",
               part="первые {} дн.", n="n"),
}


def finish(fig, ax, title, src, path):
    ax.set_title(title, loc="left", fontsize=12.5, fontweight="bold", color=INK, pad=12)
    ax.grid(axis="x" if ax.get_xlim()[1] > 5 else "y", color="#e6e5e1", linewidth=0.8)
    ax.set_axisbelow(True)
    fig.text(0.01, 0.01, src, fontsize=8, color=MUTED)
    fig.tight_layout(rect=(0, 0.04, 1, 1))
    fig.savefig(path, dpi=200)
    plt.close(fig)


for lang, t in TXT.items():
    name = (lambda c: CAT_RU[c]) if lang == "ru" else (lambda c: c)
    # Chart 1: horizontal bar, categories sorted
    fig, ax = plt.subplots(figsize=(7.2, 3.9))
    cats = [name(c) for c, _ in r1][::-1]
    vals = [v for _, v in r1][::-1]
    bars = ax.barh(cats, vals, color=BAR, height=0.6)
    for b_, v in zip(bars, vals):
        ax.text(v + 0.4, b_.get_y() + b_.get_height() / 2, str(v), va="center", fontsize=9, color=INK)
    ax.set_xlabel(t["x1"])
    ax.grid(axis="x", color="#e6e5e1"); ax.set_axisbelow(True)
    ax.spines["left"].set_visible(False); ax.tick_params(axis="y", length=0)
    ax.set_xlim(0, max(vals) * 1.12)
    finish(fig, ax, t["t1"], t["src"], OUT + f"c1_{lang}.png")

    # Chart 2: line, reports per week
    fig, ax = plt.subplots(figsize=(7.2, 3.6))
    weeks = [w for w, _ in r2]
    vals = [v for _, v in r2]
    labels = [f"{w[8:10]}.{w[5:7]}" for w in weeks]
    ax.plot(range(len(vals)), vals, color=BAR, linewidth=2, marker="o", markersize=5)
    ax.set_xticks(range(len(vals)), labels)
    ax.set_ylabel(t["y2"]); ax.set_xlabel(t["x2"])
    ax.set_ylim(0, max(vals) + 4)
    ax.grid(axis="y", color="#e6e5e1"); ax.set_axisbelow(True)
    imax = vals.index(max(vals))
    ax.annotate(str(max(vals)), (imax, max(vals)), textcoords="offset points", xytext=(0, 7), ha="center",
                fontsize=9, color=INK)
    imin = vals.index(min(vals[1:-1]))
    ax.annotate(str(vals[imin]), (imin, vals[imin]), textcoords="offset points", xytext=(0, -15), ha="center",
                fontsize=9, color=INK)
    # first and last week are partial
    ax.annotate(t["part"].format(5), (0, vals[0]), textcoords="offset points", xytext=(4, -15), fontsize=7.5,
                color=MUTED)
    ax.annotate(t["part"].format(6), (len(vals) - 1, vals[-1]), textcoords="offset points", xytext=(-40, 9),
                fontsize=7.5, color=MUTED)
    finish(fig, ax, t["t2"], t["src"], OUT + f"c2_{lang}.png")

    # Chart 3: horizontal bar, average hours to fix, with n
    fig, ax = plt.subplots(figsize=(7.2, 3.9))
    rows = r3[::-1]
    cats = [f"{name(c)}  ({t['n']} = {n})" for c, n, _ in rows]
    vals = [h for _, _, h in rows]
    bars = ax.barh(cats, vals, color=BAR, height=0.6)
    for b_, v in zip(bars, vals):
        ax.text(v + 1, b_.get_y() + b_.get_height() / 2, f"{v:.1f}" if lang == "en" else f"{v:.1f}".replace(".", ","),
                va="center", fontsize=9, color=INK)
    ax.set_xlabel(t["x3"])
    ax.grid(axis="x", color="#e6e5e1"); ax.set_axisbelow(True)
    ax.spines["left"].set_visible(False); ax.tick_params(axis="y", length=0)
    ax.set_xlim(0, max(vals) * 1.12)
    finish(fig, ax, t["t3"], t["src3"], OUT + f"c3_{lang}.png")

print("Q1", r1); print("Q2", r2); print("Q3", r3); print(TOTAL, FIXED, RANGE)
