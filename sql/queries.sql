
-- Step 3: sql/queries.sql
CREATE OR REPLACE TABLE br AS SELECT * FROM 'data/processed/bearing.parquet';
-- Q1: feature trends in the last 10% of life versus the first 10%
SELECT test, ch, AVG((CASE WHEN snap < 0.1 * n_snap THEN rms END)::INT) AS rms_early, AVG((CASE WHEN snap > 0.9 * n_snap THEN rms END)::INT) AS rms_late,
       AVG((CASE WHEN snap > 0.9 * n_snap THEN kurt END)::INT) AS kurt_late FROM br GROUP BY 1, 2;
-- Q2: first snapshot where the health index exceeds 3 (onset of degradation)
SELECT test, ch, MIN(snap) AS onset_snap, MAX(n_snap) AS n_snap FROM br WHERE hi > 3 GROUP BY 1, 2;
-- Q3: rolling features for RUL regression
CREATE OR REPLACE TABLE feat AS
SELECT test, ch, snap, ts, rms, kurt, peak, crest, skew, p2p, hi, rul,
       AVG(rms) OVER (w ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS rms_ma6, rms - LAG(rms, 6) OVER w AS rms_d6,
       AVG(kurt) OVER (w ROWS BETWEEN 5 PRECEDING AND CURRENT ROW) AS kurt_ma6, MAX(peak) OVER (w ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS peak_max12
FROM br WINDOW w AS (PARTITION BY test, ch ORDER BY snap);
SELECT test, COUNT(*) AS n FROM feat GROUP BY 1;
