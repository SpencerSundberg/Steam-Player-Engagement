-- Steam player engagement analysis (public TidyTuesday dataset, 2021-03-16)
-- Table `raw` holds one row per game per month: average and peak concurrent players.

-- 1. Clean monthly table with a numeric month and a date key
CREATE TABLE monthly AS
SELECT gamename, year, 
       CASE month WHEN 'January' THEN 1 WHEN 'February' THEN 2 WHEN 'March' THEN 3 WHEN 'April' THEN 4
                  WHEN 'May' THEN 5 WHEN 'June' THEN 6 WHEN 'July' THEN 7 WHEN 'August' THEN 8
                  WHEN 'September' THEN 9 WHEN 'October' THEN 10 WHEN 'November' THEN 11 ELSE 12 END AS mo,
       avg AS avg_players, peak AS peak_players
FROM raw;

-- 2. Fixed group of games tracked every month from Jan 2016 to Feb 2021 (so totals are comparable over time)
CREATE TABLE cohort AS
SELECT gamename FROM monthly
WHERE (year > 2016 OR year = 2016) AND (year < 2021 OR (year = 2021 AND mo <= 2))
GROUP BY gamename
HAVING COUNT(*) = 62;

-- 3. Total average players per month for that group, in millions
SELECT year, mo, ROUND(SUM(avg_players) / 1e6, 2) AS players_millions
FROM monthly WHERE gamename IN (SELECT gamename FROM cohort) AND year >= 2016
GROUP BY year, mo ORDER BY year, mo;

-- 4. Seasonality: each month's total divided by that year's monthly average, 2016-2019
SELECT mo, ROUND(AVG(idx), 3) AS seasonal_index FROM (
  SELECT m.year, m.mo, m.tot / (SELECT SUM(avg_players) / 12.0 FROM monthly x WHERE x.year = m.year AND x.gamename IN (SELECT gamename FROM cohort)) AS idx
  FROM (SELECT year, mo, SUM(avg_players) AS tot FROM monthly
        WHERE gamename IN (SELECT gamename FROM cohort) AND year BETWEEN 2016 AND 2019 GROUP BY year, mo) m
) GROUP BY mo ORDER BY mo;

-- 5. The 2020 surge: March and April, 2020 versus 2019, same group of games
SELECT year, ROUND(SUM(avg_players) / 1e6, 2) AS players_millions
FROM monthly WHERE gamename IN (SELECT gamename FROM cohort) AND year IN (2019, 2020) AND mo IN (3, 4)
GROUP BY year;

-- 6. Ten most-played games of 2020 and their share of all players
SELECT gamename, ROUND(AVG(avg_players)) AS avg_players,
       ROUND(100.0 * SUM(avg_players) / (SELECT SUM(avg_players) FROM monthly WHERE year = 2020), 1) AS share_pct
FROM monthly WHERE year = 2020
GROUP BY gamename ORDER BY SUM(avg_players) DESC LIMIT 10;

-- 7. Biggest gainers, February to April 2020 (games with at least 20,000 average players in February)
SELECT a.gamename, ROUND(a.avg_players) AS feb, ROUND(b.avg_players) AS apr,
       ROUND(100.0 * (b.avg_players - a.avg_players) / a.avg_players) AS change_pct
FROM monthly a JOIN monthly b ON a.gamename = b.gamename
WHERE a.year = 2020 AND a.mo = 2 AND b.year = 2020 AND b.mo = 4 AND a.avg_players >= 20000
ORDER BY change_pct DESC LIMIT 8;

-- 8. Staying power: of games with 1,000+ average players in 2016, how many still had 1,000+ in each later year
SELECT y.year, COUNT(*) AS still_active,
       (SELECT COUNT(*) FROM (SELECT gamename FROM monthly WHERE year = 2016 GROUP BY gamename HAVING AVG(avg_players) >= 1000)) AS started
FROM (SELECT gamename, year FROM monthly WHERE year BETWEEN 2017 AND 2020 GROUP BY gamename, year HAVING AVG(avg_players) >= 1000) y
WHERE y.gamename IN (SELECT gamename FROM monthly WHERE year = 2016 GROUP BY gamename HAVING AVG(avg_players) >= 1000)
GROUP BY y.year ORDER BY y.year;
