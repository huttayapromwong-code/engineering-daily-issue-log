-- Engineering Daily Issue Log — migration v10
-- เพิ่มคอลัมน์ shift (กะการทำงาน) ให้ตาราง issues เพื่อรองรับตัวกรองกะใน Analytics/Dashboard
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

alter table issues add column if not exists shift text check (shift is null or shift in ('Day', 'Night'));

create index if not exists issues_shift_idx on issues (shift);
