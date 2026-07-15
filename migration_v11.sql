-- Engineering Daily Issue Log — migration v11
-- เพิ่มคอลัมน์ verified (ยืนยันแล้ว) ให้ตาราง issues
-- ใช้เป็นเกณฑ์ว่า RCA/มาตรการแก้ไขถูกตรวจสอบและยืนยันความถูกต้องแล้วโดย Engineer/Manager
-- ก่อนที่ case นั้นจะถูกนำไปแสดงใน Knowledge Base (เงื่อนไข: status = Closed AND verified = true)
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

alter table issues add column if not exists verified boolean not null default false;

create index if not exists issues_verified_idx on issues (verified);
