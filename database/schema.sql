-- CampusFix database schema (SQLite)
-- Relational copy of the Cloud Firestore data, used for SQL queries and offline work.
PRAGMA foreign_keys = ON;

-- Classrooms that have a QR sticker
CREATE TABLE rooms (
    room_id    TEXT    PRIMARY KEY CHECK (length(room_id) BETWEEN 2 AND 20),   -- code on the QR sticker, e.g. '334L'
    building   TEXT    NOT NULL DEFAULT 'AITU main building',
    floor      INTEGER NOT NULL CHECK (floor BETWEEN 0 AND 10),
    room_type  TEXT    NOT NULL CHECK (room_type IN ('Room', 'Open space'))
);

-- Facilities staff who log in to the admin panel
CREATE TABLE staff (
    staff_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name     TEXT    NOT NULL,
    email         TEXT    NOT NULL UNIQUE CHECK (email LIKE '%_@_%._%'),
    role          TEXT    NOT NULL CHECK (role IN ('admin', 'manager', 'technician')),
    password_hash TEXT    NOT NULL CHECK (password_hash LIKE 'pbkdf2_sha256$%'),   -- never the plain password
    created_at    TEXT    NOT NULL
);

-- Reports sent from the QR form (main table)
CREATE TABLE reports (
    report_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    code           TEXT    NOT NULL UNIQUE CHECK (length(code) = 6),            -- number shown to the student, e.g. '1WLNER'
    room_id        TEXT    NOT NULL REFERENCES rooms (room_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    category       TEXT    NOT NULL CHECK (category IN ('Projector', 'Computer', 'Socket', 'Furniture',
                                                       'Air conditioner', 'Restroom', 'Lights', 'Other')),
    description    TEXT    NOT NULL DEFAULT '' CHECK (length(description) <= 300),
    has_photo      INTEGER NOT NULL DEFAULT 0 CHECK (has_photo IN (0, 1)),
    reporter_email TEXT    CHECK (reporter_email IS NULL OR reporter_email LIKE '%_@_%._%'),  -- optional, deleted after 30 days
    status         TEXT    NOT NULL DEFAULT 'New' CHECK (status IN ('New', 'In progress', 'Fixed')),
    created_at     TEXT    NOT NULL,
    updated_at     TEXT    CHECK (updated_at IS NULL OR updated_at >= created_at)
);

-- Every status change: which staff member changed which report, and when.
-- Linking table that resolves the many-to-many relationship between staff and reports.
CREATE TABLE status_history (
    history_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    report_id   INTEGER NOT NULL REFERENCES reports (report_id) ON DELETE CASCADE,
    staff_id    INTEGER NOT NULL REFERENCES staff (staff_id) ON DELETE RESTRICT,
    from_status TEXT    NOT NULL CHECK (from_status IN ('New', 'In progress', 'Fixed')),
    to_status   TEXT    NOT NULL CHECK (to_status IN ('New', 'In progress', 'Fixed')),
    changed_at  TEXT    NOT NULL,
    CHECK (from_status <> to_status)
);

CREATE INDEX idx_reports_room   ON reports (room_id);
CREATE INDEX idx_reports_status ON reports (status);
CREATE INDEX idx_history_report ON status_history (report_id);
