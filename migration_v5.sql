-- Engineering Daily Issue Log — migration v5
-- เพิ่มตารางใหม่สำหรับ "Daily Dashboard" (แยกจาก issues table เดิมโดยสิ้นเชิง ไม่กระทบข้อมูล/ฟังก์ชันเดิม)
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

create table if not exists daily_activities (
  id uuid primary key default gen_random_uuid(),
  activity_date date not null default current_date,
  activity_time time,
  line text,
  machine text,
  product text,
  problem text,
  description text,
  root_cause text,
  corrective_action text,
  preventive_action text,
  owner text,
  status text not null default 'Open' check (status in ('Open','In Progress','Closed')),
  remark text,
  qty_ok numeric check (qty_ok is null or qty_ok >= 0),
  qty_ng numeric check (qty_ng is null or qty_ng >= 0),
  created_at timestamptz not null default now()
);

alter table daily_activities enable row level security;
drop policy if exists "daily_activities_all_anon" on daily_activities;
create policy "daily_activities_all_anon" on daily_activities for all
  using (true) with check (true);

create index if not exists daily_activities_date_idx on daily_activities (activity_date);

-- เก็บ Daily Summary ที่ระบบสร้างอัตโนมัติ (1 แถวต่อ 1 วัน)
create table if not exists daily_summaries (
  id uuid primary key default gen_random_uuid(),
  summary_date date not null unique,
  summary_text text not null,
  generated_at timestamptz not null default now()
);

alter table daily_summaries enable row level security;
drop policy if exists "daily_summaries_all_anon" on daily_summaries;
create policy "daily_summaries_all_anon" on daily_summaries for all
  using (true) with check (true);
