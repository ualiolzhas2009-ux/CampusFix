-- CampusFix: queries to run in DB Browser for SQLite (tab "Execute SQL")
PRAGMA foreign_keys = ON;

-- 1. How many reports in each category (GROUP BY)
SELECT category, COUNT(*) AS reports
FROM reports
GROUP BY category
ORDER BY reports DESC;

-- 2. How many reports in each room, and how many are still open
SELECT room_id,
       COUNT(*)                                        AS total,
       SUM(CASE WHEN status <> 'Fixed' THEN 1 ELSE 0 END) AS still_open
FROM reports
GROUP BY room_id
ORDER BY total DESC;

-- 3. Reports per status
SELECT status, COUNT(*) AS reports FROM reports GROUP BY status;

-- 4. JOIN: open reports with the room's floor and type
SELECT r.code, r.room_id, ro.floor, ro.room_type, r.category, r.status, r.created_at
FROM reports r
JOIN rooms ro ON ro.room_id = r.room_id
WHERE r.status <> 'Fixed'
ORDER BY r.created_at DESC;

-- 5. Full history of one report: who changed the status and when
SELECT r.code, h.from_status, h.to_status, s.full_name, h.changed_at
FROM status_history h
JOIN reports r ON r.report_id = h.report_id
JOIN staff   s ON s.staff_id  = h.staff_id
WHERE r.code = (SELECT code FROM reports WHERE status = 'Fixed' LIMIT 1)
ORDER BY h.changed_at;

-- 6. Which technician fixed the most reports
SELECT s.full_name, COUNT(*) AS fixed
FROM status_history h
JOIN staff s ON s.staff_id = h.staff_id
WHERE h.to_status = 'Fixed'
GROUP BY s.full_name
ORDER BY fixed DESC;

-- 7. Average time from report to "Fixed", in hours, by category
SELECT r.category,
       ROUND(AVG((julianday(h.changed_at) - julianday(r.created_at)) * 24), 1) AS avg_hours_to_fix
FROM reports r
JOIN status_history h ON h.report_id = r.report_id AND h.to_status = 'Fixed'
GROUP BY r.category
ORDER BY avg_hours_to_fix;

-- 8. Privacy check: no e-mail may be older than 30 days (should return 0)
SELECT COUNT(*) AS old_emails
FROM reports
WHERE reporter_email IS NOT NULL AND created_at < datetime('2026-10-10', '-30 days');

-- ===== Constraint tests (each one should FAIL with an error) =====
-- FOREIGN KEY: a room that does not exist
-- INSERT INTO reports (code, room_id, category, created_at) VALUES ('TEST01', '999X', 'Lights', '2026-10-10 10:00:00');
-- CHECK: a category that is not in the list
-- INSERT INTO reports (code, room_id, category, created_at) VALUES ('TEST02', '334L', 'Coffee', '2026-10-10 10:00:00');
-- UNIQUE: the same report number twice
-- INSERT INTO reports (code, room_id, category, created_at) VALUES ('1WLNER', '334L', 'Lights', '2026-10-10 10:00:00');
-- RESTRICT: delete a room that still has reports
-- DELETE FROM rooms WHERE room_id = '334L';

-- CASCADE: deleting a report also deletes its history lines (this one WORKS; run it on a copy)
-- DELETE FROM reports WHERE code = '...';
