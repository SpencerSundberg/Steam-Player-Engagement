"""Builds data.json for the gaming dashboard from the public Steam player-count dataset.
Run:  python3 build_data.py   (downloads the CSV, runs analysis.sql, writes data.json and dashboard.html)
"""
import csv, json, sqlite3, urllib.request, os, re
URL = "https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-03-16/games.csv"
here = os.path.dirname(os.path.abspath(__file__))
csv_path = os.environ.get("GAMES_CSV") or os.path.join(here, "games.csv")
if not os.path.exists(csv_path):
    urllib.request.urlretrieve(URL, csv_path)
con = sqlite3.connect(":memory:")
con.execute("CREATE TABLE raw(gamename, year INT, month, avg REAL, gain REAL, peak REAL, avg_peak_perc)")
def f(x):
    try: return float(x)
    except Exception: return None
rows = list(csv.reader(open(csv_path, encoding="utf-8")))[1:]
con.executemany("INSERT INTO raw VALUES(?,?,?,?,?,?,?)", [(r[0], int(r[1]), r[2], f(r[3]), f(r[4]), f(r[5]), r[6]) for r in rows])
blocks = [b.strip() for b in open(os.path.join(here, "analysis.sql")).read().split("\n\n") if "SELECT" in b or "CREATE" in b]
def clean(b): return "\n".join(l for l in b.splitlines() if not l.startswith("--")).strip().rstrip(";")
con.execute(clean(blocks[0])); con.execute(clean(blocks[1]))
run = lambda i: con.execute(clean(blocks[i])).fetchall()
monthly, season, covid, top, gain, stay = run(2), run(3), run(4), run(5), run(6), run(7)
n_games = con.execute("SELECT COUNT(DISTINCT gamename) FROM monthly").fetchone()[0]
n_rows = con.execute("SELECT COUNT(*) FROM monthly").fetchone()[0]
n_cohort = con.execute("SELECT COUNT(*) FROM cohort").fetchone()[0]
cv = {r[0]: r[1] for r in covid}
mn = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
data = {
  "source": URL, "rows": n_rows, "games": n_games, "cohort": n_cohort,
  "monthly": [{"k": "%d-%02d" % (r[0], r[1]), "v": r[2]} for r in monthly],
  "season": [{"k": mn[r[0]-1], "v": r[1]} for r in season],
  "covid": {"y2019": cv[2019], "y2020": cv[2020], "pct": round(100 * (cv[2020] - cv[2019]) / cv[2019])},
  "top": [{"k": r[0], "v": r[1], "share": r[2]} for r in top],
  "top_share": round(sum(r[2] for r in top), 1),
  "gain": [{"k": r[0], "feb": r[1], "apr": r[2], "v": r[3]} for r in gain],
  "stay": [{"k": str(r[0]), "v": round(100 * r[1] / r[2]), "n": r[1], "of": r[2]} for r in stay],
}
json.dump(data, open(os.path.join(here, "data.json"), "w"), indent=1)
tpl = open(os.path.join(here, "dashboard_template.html")).read()
open(os.path.join(here, "dashboard.html"), "w").write(tpl.replace("/*DATA*/null", json.dumps(data)))
print(json.dumps({k: v for k, v in data.items() if k != "monthly"}, indent=1))
