-- Engineering Daily Issue Log — migration v2
-- เพิ่มฟิลด์ใหม่สำหรับ Dashboard: Defect Category, Root Cause Category, Machine, Downtime, Qty NG/OK
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run
-- (รันได้ปลอดภัยแม้ว่าเคยรันไปแล้วบางส่วน เพราะใช้ IF NOT EXISTS)

alter table issues add column if not exists defect_category text
  check (defect_category in ('Dimensional','Visual/Cosmetic','Functional','Material','Assembly','Electrical','Other'));

alter table issues add column if not exists root_cause_category text
  check (root_cause_category in ('Man','Machine','Method','Material','Measurement','Environment','Other'));

alter table issues add column if not exists machine text;
alter table issues add column if not exists downtime_minutes numeric check (downtime_minutes is null or downtime_minutes >= 0);
alter table issues add column if not exists qty_ng numeric check (qty_ng is null or qty_ng >= 0);
alter table issues add column if not exists qty_ok numeric check (qty_ok is null or qty_ok >= 0);

-- หมายเหตุ: คอลัมน์ "line" เดิม ยังใช้เก็บ Production Line ต่อไป (แค่เปลี่ยนป้ายชื่อในฟอร์มเป็น "Production Line")
-- ไม่ต้อง migrate ข้อมูลเดิม เพราะคอลัมน์เดิมไม่ได้ถูกลบหรือเปลี่ยนชื่อ
