-- Engineering Daily Issue Log — migration v6
-- ขยาย daily_activities ให้แสดง "คุณค่าของงานวิศวกรรม" ได้ครบ (Downtime/NG/Cost impact, Process, Priority, Category, เวลาที่ใช้แก้ไข, รูป/ไฟล์แนบ)
-- เพิ่มตาราง production_plans สำหรับ Plan vs Actual
-- เป็น migration แบบ additive ทั้งหมด (เพิ่ม column แบบ nullable/default) ข้อมูลเดิมไม่หาย
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

alter table daily_activities add column if not exists process text;
alter table daily_activities add column if not exists priority text check (priority is null or priority in ('High','Medium','Low'));
alter table daily_activities add column if not exists category text not null default 'Problem' check (category in ('Problem','Trial','Improvement'));
alter table daily_activities add column if not exists start_time time;
alter table daily_activities add column if not exists finish_time time;
alter table daily_activities add column if not exists photo_before text;
alter table daily_activities add column if not exists photo_after text;
alter table daily_activities add column if not exists attachments jsonb default '[]'::jsonb;
alter table daily_activities add column if not exists result_outcome text;
alter table daily_activities add column if not exists downtime_minutes numeric check (downtime_minutes is null or downtime_minutes >= 0);
alter table daily_activities add column if not exists downtime_saved_minutes numeric check (downtime_saved_minutes is null or downtime_saved_minutes >= 0);
alter table daily_activities add column if not exists cost_saving_thb numeric check (cost_saving_thb is null or cost_saving_thb >= 0);
alter table daily_activities add column if not exists ng_reduced_qty numeric check (ng_reduced_qty is null or ng_reduced_qty >= 0);
alter table daily_activities add column if not exists progress int check (progress is null or progress between 0 and 100);

-- Production Plan vs Actual
create table if not exists production_plans (
  id uuid primary key default gen_random_uuid(),
  plan_date date not null,
  line text not null,
  planned_qty numeric not null default 0,
  created_at timestamptz not null default now(),
  unique (plan_date, line)
);
alter table production_plans enable row level security;
drop policy if exists "production_plans_all_anon" on production_plans;
create policy "production_plans_all_anon" on production_plans for all
  using (true) with check (true);
