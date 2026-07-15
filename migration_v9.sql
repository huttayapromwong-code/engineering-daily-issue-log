-- Engineering Daily Issue Log — migration v9
-- เปิดใช้งาน Supabase Auth จริง + ปิดช่องโหว่ RLS ที่เปิดกว้างให้ anon อ่าน/เขียน/ลบได้ทุกตาราง
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run
--
-- ก่อนรัน: เปิด Email/Password provider ที่ Supabase Dashboard > Authentication > Providers
-- หลังรัน: ทุกหน้าในระบบ (ยกเว้น login.html และ share.html) ต้อง sign in ก่อนถึงจะใช้งานได้

-- ============================================================
-- 1) PROFILES — ข้อมูลผู้ใช้ต่อคน (แทน localStorage "eng-log-my-name" เดิม)
-- ============================================================
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

drop policy if exists "profiles_select_authenticated" on profiles;
create policy "profiles_select_authenticated" on profiles for select
  using (auth.role() = 'authenticated');

drop policy if exists "profiles_insert_own" on profiles;
create policy "profiles_insert_own" on profiles for insert
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own" on profiles for update
  using (auth.uid() = id) with check (auth.uid() = id);

-- สร้าง profile row อัตโนมัติเมื่อมีผู้ใช้ใหม่ signup
create or replace function handle_new_user() returns trigger as $$
begin
  insert into public.profiles (id, display_name) values (new.id, split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_auth_user_created on auth.users;
create trigger trg_auth_user_created after insert on auth.users
for each row execute function handle_new_user();

-- ============================================================
-- 2) ปิดช่องโหว่: เปลี่ยนทุกตารางจาก "anon อ่าน/เขียนได้หมด" เป็น "ต้อง login (authenticated) เท่านั้น"
-- ============================================================
do $$
declare
  t text;
  tables text[] := array[
    'issues', 'issue_updates', 'daily_activities', 'daily_summaries', 'production_plans',
    'production_lines', 'machines', 'products', 'defect_categories', 'root_cause_categories',
    'work_items', 'work_item_updates', 'attachments', 'audit_log'
  ];
begin
  foreach t in array tables loop
    execute format('drop policy if exists %I on %I', t || '_all_anon', t);
    execute format(
      'create policy %I on %I for all using (auth.role() = %L) with check (auth.role() = %L)',
      t || '_authenticated', t, 'authenticated', 'authenticated'
    );
  end loop;
end $$;

-- shares: ตารางเองต้อง login ถึงจะเข้าได้โดยตรง (จัดการลิงก์แชร์)
-- ผู้รับลิงก์ภายนอกจะไม่เข้าตารางนี้ตรงๆ อีกต่อไป แต่ใช้ RPC get_shared_report() ด้านล่างแทน
drop policy if exists "shares_all_anon" on shares;
create policy "shares_authenticated" on shares for all
  using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- storage (รูปแนบ): อัปโหลดต้อง login, อ่านยังเปิดสาธารณะเหมือนเดิม (URL เดารูปแบบไม่ได้ เป็น UUID)
drop policy if exists "issue_photos_anon_write" on storage.objects;
create policy "issue_photos_authenticated_write" on storage.objects
  for insert to authenticated with check (bucket_id = 'issue-photos');

-- ============================================================
-- 3) RPC สำหรับหน้า share.html — อ่านรายงานแบบ read-only โดยไม่ต้อง login
--    (security definer: รันด้วยสิทธิ์เจ้าของฟังก์ชัน ตรวจ token/password/expiry เองในฟังก์ชัน
--     แทนที่จะเปิด RLS ให้ anon เข้าตาราง issues/issue_updates/shares ตรงๆ)
-- ============================================================
create or replace function get_shared_report(p_token text, p_password text default null)
returns jsonb as $$
declare
  v_share shares%rowtype;
  v_issue jsonb;
  v_updates jsonb;
begin
  select * into v_share from shares where token = p_token;

  if not found then
    return jsonb_build_object('error', 'not_found');
  end if;
  if v_share.revoked then
    return jsonb_build_object('error', 'revoked');
  end if;
  if v_share.expires_at is not null and v_share.expires_at < now() then
    return jsonb_build_object('error', 'expired');
  end if;
  if v_share.password_hash is not null then
    if p_password is null or encode(digest(p_password, 'sha256'), 'hex') <> v_share.password_hash then
      return jsonb_build_object('error', 'password_required');
    end if;
  end if;

  select to_jsonb(i) into v_issue from issues i where i.id = v_share.issue_id;
  if v_issue is null then
    return jsonb_build_object('error', 'issue_not_found');
  end if;

  select coalesce(jsonb_agg(to_jsonb(u) order by u.update_date desc), '[]'::jsonb)
    into v_updates from issue_updates u where u.issue_id = v_share.issue_id;

  return jsonb_build_object('issue', v_issue, 'updates', v_updates);
end;
$$ language plpgsql security definer set search_path = public;

-- ให้ anon (ผู้รับลิงก์แชร์ ไม่ต้อง login) เรียก RPC นี้ได้
grant execute on function get_shared_report(text, text) to anon, authenticated;
