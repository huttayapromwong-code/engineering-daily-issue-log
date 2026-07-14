-- Engineering Daily Issue Log — ลบข้อมูลทดสอบ (Mock Data) ทั้งหมด
-- ใช้เมื่อทดสอบเสร็จแล้วต้องการล้างข้อมูลปลอมออกจากระบบจริง
-- ข้อมูลจริงจะไม่ถูกกระทบ เพราะข้อมูลทดสอบทุกแถวมีคำนำหน้า "[MOCK]" ที่ title/problem เท่านั้น
-- วิธีใช้: คัดลอกไปวางใน Supabase > SQL Editor > New query แล้วกด Run (เมื่อพร้อมลบจริงเท่านั้น)

delete from daily_activities where problem like '[MOCK]%';
delete from issues where title like '[MOCK]%';

-- work_items / work_item_updates ที่มิเรอร์ไว้จะถูกลบตามอัตโนมัติ
-- ผ่าน trigger จาก migration_v7b.sql (trg_mirror_daily_activity_delete, trg_mirror_issue_delete)
-- ไม่ต้องลบ work_items ด้วยตนเอง

-- ตรวจสอบผลหลังลบ (ไม่บังคับ):
-- select count(*) from work_items where title like '[MOCK]%';  -- ควรได้ 0
