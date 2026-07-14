-- Engineering Daily Issue Log — migration v7b
-- Bug fix สำหรับ Module 1: migration_v7.sql ยังไม่มี trigger จัดการกรณี "ลบ" แถวต้นทาง
-- ผลคือถ้ามีการลบแถวใน issues / daily_activities / issue_updates แถวที่มิเรอร์ไว้ใน
-- work_items / work_item_updates จะค้างเป็น orphan (พบจากการทดสอบ API จริงหลังรัน v7)
--
-- ไฟล์นี้เพิ่ม AFTER DELETE trigger ให้ลบแถวมิเรอร์ที่ตรงกันออกไปด้วยเสมอ
-- ไม่แก้ไขตารางเดิมหรือ trigger เดิมที่มีอยู่แล้ว เป็นการเพิ่มเติมเท่านั้น
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

create or replace function mirror_issue_delete_to_work_item() returns trigger as $$
begin
  delete from work_items where source_type = 'Issue' and source_id = old.id;
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_issue_delete on issues;
create trigger trg_mirror_issue_delete after delete on issues
for each row execute function mirror_issue_delete_to_work_item();

create or replace function mirror_daily_activity_delete_to_work_item() returns trigger as $$
begin
  delete from work_items where source_type = 'DailyActivity' and source_id = old.id;
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_daily_activity_delete on daily_activities;
create trigger trg_mirror_daily_activity_delete after delete on daily_activities
for each row execute function mirror_daily_activity_delete_to_work_item();

create or replace function mirror_issue_update_delete_to_work_item() returns trigger as $$
begin
  delete from work_item_updates where source_update_id = old.id;
  return old;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_issue_update_delete on issue_updates;
create trigger trg_mirror_issue_update_delete after delete on issue_updates
for each row execute function mirror_issue_update_delete_to_work_item();

-- หมายเหตุ: การลบ issues จะ cascade ลบ issue_updates ของมันเองอยู่แล้ว (on delete cascade เดิม)
-- ซึ่งจะไปยิง trigger ลบ work_item_updates ต่อโดยอัตโนมัติ จึงไม่มี orphan หลงเหลือทั้งสองระดับ
