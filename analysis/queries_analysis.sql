-- CampusFix data analysis (Stage 2, Part C) — author: Sagynaly
-- Run on database/campusfix.sqlite (DB Browser for SQLite → "Execute SQL"),
-- or run analysis/charts.py to get the three charts.

-- Q1. Which problems are reported most often?
SELECT category, COUNT(*) AS reports
FROM reports
GROUP BY category
ORDER BY reports DESC;

-- Q2. How many reports come in each week? (weeks start on Monday)
-- Fix: 'weekday 0', '-6 days' gives the Monday of the same week.
-- The first version used 'weekday 1', '-7 days', which moved Monday reports to the week before.
SELECT date(created_at, 'weekday 0', '-6 days') AS week_start,
       COUNT(*) AS reports
FROM reports
GROUP BY week_start
ORDER BY week_start;

-- Q3. Which problems take the longest to fix? (average hours from report to "Fixed")
SELECT r.category,
       COUNT(*) AS fixed_reports,
       ROUND(AVG((julianday(h.changed_at) - julianday(r.created_at)) * 24), 1) AS avg_hours_to_fix
FROM reports r
JOIN status_history h ON h.report_id = r.report_id AND h.to_status = 'Fixed'
GROUP BY r.category
ORDER BY avg_hours_to_fix DESC;
