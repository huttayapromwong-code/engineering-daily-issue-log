-- Engineering Daily Issue Log — migration v4
-- เพิ่มตารางสำหรับระบบ Share Report (ลิงก์ read-only เฉพาะรายงาน)
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

create table if not exists shares (
  id uuid primary key default gen_random_uuid(),
  token text unique not null,
  issue_id uuid not null references issues(id) on delete cascade,
  password_hash text,
  expires_at timestamptz,
  revoked boolean not null default false,
  created_at timestamptz not null default now()
);

alter table shares enable row level security;

drop policy if exists "shares_all_anon" on shares;
create policy "shares_all_anon" on shares for all
  using (true) with check (true);

create index if not exists shares_token_idx on shares (token);
