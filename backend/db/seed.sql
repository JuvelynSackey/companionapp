-- ============================================================
-- Demo data for the Campus Companion App.
-- Mirrors the figures shown in the proposal's UI mock-ups so the
-- running app matches the screenshots in the report.
--
-- Users are created by src/utils/setupDb.js (passwords must be
-- bcrypt-hashed in code, not stored as literals in SQL).
-- ============================================================

-- ---------- Courses ----------
INSERT INTO courses (course_code, course_title, lecturer_name, credit_hours) VALUES
  ('DCIT 201', 'Mathematics',        'Prof. A. Mensah',  3),
  ('DCIT 202', 'Physics',            'Prof. K. Boateng', 3),
  ('DCIT 203', 'English Literature', 'Prof. Y. Asante',  2),
  ('DCIT 205', 'Computer Science',   'Prof. E. Darko',   3);

-- ---------- Timetable for the demo student (Friday, per mock-up) ----------
INSERT INTO schedules (user_id, course_id, day_of_week, start_time, end_time, room)
SELECT u.user_id, c.course_id, s.day_of_week, s.start_time, s.end_time, s.room
FROM (VALUES
    ('DCIT 201', 5, TIME '10:00', TIME '11:30', 'Room 204'),
    ('DCIT 202', 5, TIME '13:00', TIME '14:30', 'Lab 3'),
    ('DCIT 203', 5, TIME '15:30', TIME '17:00', 'Block B'),
    ('DCIT 205', 5, TIME '17:00', TIME '18:30', 'ICT Lab'),
    -- a second day so the weekly view has something to show
    ('DCIT 201', 2, TIME '08:00', TIME '09:30', 'Room 204'),
    ('DCIT 205', 3, TIME '11:00', TIME '12:30', 'ICT Lab')
  ) AS s(course_code, day_of_week, start_time, end_time, room)
JOIN courses c ON c.course_code = s.course_code
CROSS JOIN (SELECT user_id FROM users WHERE email = 'student@ug.edu.gh') u;

-- ---------- Grades (scores taken from the Grades mock-up) ----------
INSERT INTO grades (user_id, course_id, score)
SELECT u.user_id, c.course_id, g.score
FROM (VALUES
    ('DCIT 201', 85.00),
    ('DCIT 202', 74.00),
    ('DCIT 203', 79.00),
    ('DCIT 205', 92.00)
  ) AS g(course_code, score)
JOIN courses c ON c.course_code = g.course_code
CROSS JOIN (SELECT user_id FROM users WHERE email = 'student@ug.edu.gh') u;

-- ---------- Clubs ----------
INSERT INTO clubs (name, description) VALUES
  ('Computer Science Society', 'Talks, hackathons and study groups for CS and IT students.'),
  ('Debate Union',             'Weekly debates and inter-hall competitions.'),
  ('Photography Club',         'Campus photo walks and darkroom sessions.');

-- ---------- Announcements ----------
INSERT INTO announcements (title, message, category, posted_by)
SELECT a.title, a.message, a.category, u.user_id
FROM (VALUES
    ('Exam notice',
     'Mid-term exams scheduled for April 5-10. Check your timetable.',
     'academic'),
    ('Library hours update',
     'Extended hours until 10 PM starting next week.',
     'general')
  ) AS a(title, message, category)
CROSS JOIN (SELECT user_id FROM users WHERE email = 'admin@ug.edu.gh') u;

-- ---------- Events ----------
INSERT INTO events (title, description, event_date, location, club_id, created_by)
SELECT e.title, e.description, e.event_date, e.location, c.club_id, u.user_id
FROM (VALUES
    ('Tech Talk',  'Industry speakers on careers in software.',
     TIMESTAMPTZ '2026-04-02 14:00+00', 'Auditorium', 'Computer Science Society'),
    ('Club fair',  'Meet every student society on campus.',
     TIMESTAMPTZ '2026-04-07 09:00+00', 'Main hall',  'Debate Union')
  ) AS e(title, description, event_date, location, club_name)
JOIN clubs c ON c.name = e.club_name
CROSS JOIN (SELECT user_id FROM users WHERE email = 'admin@ug.edu.gh') u;

-- ---------- Campus map locations ----------
-- NOTE: these coordinates are approximate placeholders for UG Legon.
-- Replace them with real GPS readings taken on campus before the demo.
INSERT INTO locations (name, category, description, latitude, longitude) VALUES
  ('Balme Library',            'library',      'Main university library.',            5.650800, -0.186600),
  ('Great Hall',               'other',        'Ceremonies and congregation.',        5.652200, -0.186900),
  ('Department of Computer Science', 'office', 'DCIT departmental offices.',          5.654100, -0.187600),
  ('ICT Lab',                  'laboratory',   'Computer laboratory, Block B.',       5.653800, -0.187200),
  ('Night Market',             'cafeteria',    'Food vendors and shops.',             5.648900, -0.184300),
  ('Commonwealth Hall',        'hostel',       'Undergraduate hall of residence.',    5.651500, -0.189100);
