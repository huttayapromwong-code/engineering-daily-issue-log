-- Engineering Daily Issue Log — database schema
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

create extension if not exists pgcrypto;

-- ตารางหลัก: 1 แถว = 1 ปัญหา/งาน
create table if not exists issues (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  title text not null,
  description text,
  line text,
  severity text not null default 'Minor' check (severity in ('Critical','Major','Minor')),
  owner text,
  status text not null default 'Open' check (status in ('Open','In Progress','Closed')),
  received_date date not null default current_date,
  resolved_date date,
  progress int not null default 0 check (progress between 0 and 100),
  root_cause text,
  corrective_action text,
  preventive_action text,
  photo_before text,
  photo_after text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ตารางบันทึกความคืบหน้ารายวัน: หลายแถวต่อ 1 ปัญหา (ลงบันทึกเบาๆ ได้ทุกวัน)
create table if not exists issue_updates (
  id uuid primary key default gen_random_uuid(),
  issue_id uuid not null references issues(id) on delete cascade,
  update_date date not null default current_date,
  note text,
  progress int check (progress between 0 and 100),
  photo_url text,
  created_at timestamptz not null default now()
);

-- สร้างรหัสงานอัตโนมัติ เช่น ENG-0001, ENG-0002, ...
create sequence if not exists issue_code_seq;

create or replace function set_issue_code() returns trigger as $$
begin
  if new.code is null then
    new.code := 'ENG-' || lpad(nextval('issue_code_seq')::text, 4, '0');
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_issue_code on issues;
create trigger trg_issue_code before insert on issues
for each row execute function set_issue_code();

-- อัปเดตเวลาแก้ไขล่าสุดอัตโนมัติ
create or replace function bump_updated_at() returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_issue_updated on issues;
create trigger trg_issue_updated before update on issues
for each row execute function bump_updated_at();

-- เปิดใช้งาน Row Level Security
-- หมายเหตุ: ตั้งเป็นเปิดกว้าง (ใครมีลิงก์เว็บก็อ่าน/เขียนได้) เหมาะกับทีมงานภายในที่ใช้ลิงก์เดียวกัน
-- ถ้าต้องการจำกัดสิทธิ์ตามผู้ใช้ในอนาคต ค่อยเพิ่ม Supabase Auth ทีหลังได้
alter table issues enable row level security;
alter table issue_updates enable row level security;

drop policy if exists "issues_all_anon" on issues;
create policy "issues_all_anon" on issues for all
  using (true) with check (true);

drop policy if exists "issue_updates_all_anon" on issue_updates;
create policy "issue_updates_all_anon" on issue_updates for all
  using (true) with check (true);

-- ที่เก็บรูปภาพ (ก่อนแก้/หลังแก้/ระหว่างดำเนินการ)
insert into storage.buckets (id, name, public)
values ('issue-photos', 'issue-photos', true)
on conflict (id) do nothing;

drop policy if exists "issue_photos_public_read" on storage.objects;
create policy "issue_photos_public_read" on storage.objects
  for select using (bucket_id = 'issue-photos');

drop policy if exists "issue_photos_anon_write" on storage.objects;
create policy "issue_photos_anon_write" on storage.objects
  for insert with check (bucket_id = 'issue-photos');
