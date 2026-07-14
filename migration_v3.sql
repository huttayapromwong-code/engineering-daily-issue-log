-- Engineering Daily Issue Log — migration v3
-- เพิ่มฟิลด์สำหรับ MES-style Dashboard: Due Date, Product, Customer, Department, 5-Why, Attachments
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

alter table issues add column if not exists due_date date;
alter table issues add column if not exists product text;
alter table issues add column if not exists customer text;
alter table issues add column if not exists department text;
alter table issues add column if not exists why1 text;
alter table issues add column if not exists why2 text;
alter table issues add column if not exists why3 text;
alter table issues add column if not exists why4 text;
alter table issues add column if not exists why5 text;
alter table issues add column if not exists attachments jsonb default '[]'::jsonb;

-- แยกประเภทบันทึกความคืบหน้า: progress (ปกติ) / approval (บันทึกอนุมัติ/ตรวจสอบ)
alter table issue_updates add column if not exists type text not null default 'progress'
  check (type in ('progress','approval'));
