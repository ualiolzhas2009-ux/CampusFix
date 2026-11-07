# CampusFix

CampusFix lets students report broken equipment in AITU classrooms by scanning a QR code on the door.
The form opens with the room already filled in; the report goes straight to the facilities staff, who see it
in a real-time admin panel and change its status (New → In progress → Fixed).

Group SE-2621 · Olzhas, Assanali, Sagynaly · ICT Final Project

- **Live site:** https://campusfix-2621.web.app
- **Example QR link:** https://campusfix-2621.web.app/?room=334L
- **Admin panel:** https://campusfix-2621.web.app/#admin
- **QR codes for printing:** https://campusfix-2621.web.app/#qr

## Test accounts

| Role | How to log in |
|---|---|
| Reporter (student, teacher) | No account. Open the QR link above. |
| Staff (admin panel) | E-mail and password are given to the instructor in the LMS submission. They are not stored in this repository. |

## Project structure

```
CampusFix/
├── public/                 the website (published to Firebase Hosting)
│   ├── index.html          report form, admin panel, QR page (one file)
│   ├── img/                logo, category icons (SVG), "how it works" picture (WebP)
│   └── sound/              optional "new report" sound (MP3)
├── firebase.json           hosting settings and security headers
├── firestore.rules         database security rules (only staff read reports)
├── database/
│   ├── schema.sql          relational copy of the data (SQLite)
│   ├── queries.sql         example SQL queries
│   └── campusfix.sqlite    database with test data
└── analysis/
    └── charts.py           the three analysis queries and their charts
```

## How to run

**1. Hosted version.** Open https://campusfix-2621.web.app. Nothing to install.

**2. Locally in demo mode (no Firebase).** In `public/index.html` change `apiKey` to `"PASTE"`, then open the
file with a local server (for example VS Code → *Open with Live Server*). Reports are stored only in this
browser; log in to the admin panel with the demo account shown on the log-in screen.

**3. Your own Firebase copy.**

1. Firebase Console → Firestore Database → *Create database* (region europe-west3, production mode).
2. Authentication → *Get started* → enable **Email/Password**. On the Users tab add a staff user and copy its **User UID**.
3. Firestore → *Start collection* `staff` → Document ID = that UID → field `role` (string) = `admin` → Save.
4. Install Node.js (LTS), open a terminal in this folder and run:

```
npm install -g firebase-tools
firebase login
firebase deploy
```

On Windows PowerShell use `firebase.cmd` instead of `firebase`.

5. Log in to the admin panel **once**: the site then saves the list of buildings and rooms
   (collections `buildings` and `rooms`). Until then reports cannot be sent, because a report
   must point to a room that exists. The list of rooms is at the top of `public/index.html` (`window.BUILDINGS`).

## Admin panel tools

| Button | What it does |
|---|---|
| Buildings & rooms | The room directory |
| Download all reports (CSV) | Opens in Excel |
| Download backup (JSON) | Full copy: buildings, rooms, reports, history |
| Restore from backup | Puts back reports that are missing |
| Fill with test reports / Remove test reports | Adds or deletes 120 test reports (marked `test = true`) |

Click a report number to see who changed its status and when (collection `statusHistory`).
E-mails older than 30 days are deleted automatically when staff open the panel.
Changing a status sends the reporter an e-mail through EmailJS (if they left an address).

## Data analysis

Needs Python 3 and matplotlib:

```
pip install matplotlib
python analysis/charts.py
```

The charts are saved to `analysis/charts/`.

## Technologies

HTML, CSS, Bootstrap 5, JavaScript · Firebase Hosting (HTTPS) · Cloud Firestore · Firebase Authentication ·
Firestore Security Rules · SQLite · Python (matplotlib)

## Known limitations

- R12: uptime is monitored with UptimeRobot since 7 November 2026; a full week of data is still being collected.
