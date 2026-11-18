# Steam Player Engagement, 2016 to 2021 (gaming analytics)

**Questions:** When are players most active, what happened in 2020, and which games keep their players?

**Data:** Public TidyTuesday Steam dataset (2021-03-16): 83,631 game-month rows for 1,258 games. A fixed group of 730 games tracked every month from January 2016 to February 2021 keeps totals comparable over time.

**Tools:** SQL (SQLite), Python, an HTML dashboard.

## Key findings
- Average players in March and April 2020 were 47% higher than in 2019 for the same 730 games, and counts stayed above 2019 levels afterward.
- Players are lowest in October (-8% vs an average month) and highest in January (+9%).
- The ten most-played games hold 47% of all players. Counter-Strike: Global Offensive alone holds 17%.
- Terraria (+85%), Football Manager 2020 (+71%), and other open-ended games gained the most from February to April 2020.
- 66% of games with 1,000+ average players in 2016 still had that many in 2020.

## Recommendations
Schedule updates for the autumn dip, budget for ongoing content, pick a niche audience over going head to head with the giants, and prepare for demand spikes.

## Limits
Steam only, and it measures players online, not revenue. The sample leans toward games that stayed popular. There is no genre or price field. The 2020 surge coincided with stay-at-home orders, but the data cannot prove the cause.

## Files
- `analysis.sql`: all queries
- `build_data.py`: downloads the data, runs the SQL, writes `data.json` and `dashboard.html`
- `dashboard.html`: the finished dashboard (open it in a browser)

To rebuild: `python3 build_data.py`
