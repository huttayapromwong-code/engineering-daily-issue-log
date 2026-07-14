-- Engineering Daily Issue Log — migration v7
-- Module 1: Database Foundation (Phase A "Expand" จากเอกสาร Master Schema v2)
--
-- ขอบเขตของไฟล์นี้:
--   1) สร้างตาราง lookup ใหม่ 5 ตาราง (production_lines, machines, products,
--      defect_categories, root_cause_categories) และ seed ค่าจากข้อมูลเดิม
--   2) สร้างตารางหลักใหม่ work_items (partitioned by year บน received_date)
--      ที่รวม issues + daily_activities เป็นมุมมองเดียว รองรับข้อมูล 10+ ปี
--   3) สร้างตารางลูก work_item_updates (รวม issue_updates) และ attachments
--   4) สร้างตาราง audit_log (โครงสร้างพร้อมใช้ แต่ยังไม่ผูก trigger บันทึกอัตโนมัติ)
--   5) Backfill ข้อมูลเดิมทั้งหมดเข้า work_items / work_item_updates
--   6) สร้าง trigger ให้ issues / daily_activities / issue_updates มิเรอร์เข้า
--      work_items / work_item_updates โดยอัตโนมัติทุกครั้งที่มีการเพิ่ม/แก้ไข
--
-- ตารางเดิมทั้งหมด (issues, issue_updates, daily_activities, daily_summaries,
-- production_plans, shares) จะไม่ถูกแก้ไข ลบ หรือเปลี่ยนชื่อในไฟล์นี้แม้แต่บรรทัดเดียว
-- แอปพลิเคชันปัจจุบัน (index.html, report.html, share.html, daily-dashboard.html,
-- executive-dashboard.html, my-performance.html) ยังคงอ่าน/เขียนตารางเดิมเหมือนทุกวันนี้
-- ทุกประการ — ไฟล์นี้ไม่มีผลกระทบต่อการทำงานของเว็บที่ใช้งานอยู่จริง
--
-- เจตนาที่เลื่อนออกไปก่อน (จะทำใน Module ถัดไปเมื่อ Module นี้ผ่านการตรวจสอบ):
--   - ตาราง profiles / Authentication จริง (ปัจจุบันยังใช้ owner เป็นข้อความตามมติเดิม)
--   - Backfill attachments จาก jsonb เดิมของ issues/daily_activities (โครงสร้าง JSON
--     เดิมยังไม่ได้ยืนยันชัดเจน จึงเว้นว่างไว้ก่อนเพื่อกันข้อมูลผิดพลาด — jsonb เดิมใน
--     ตาราง issues/daily_activities ยังอยู่ครบ ไม่มีอะไรสูญหาย)
--   - Trigger บันทึกลง audit_log อัตโนมัติ (สร้างแค่โครงตารางไว้ก่อน)
--   - Partitioning ของ work_item_updates / audit_log (ตาราง work_items ซึ่งเป็นตัวที่
--     ข้อมูลโตเร็วที่สุด ได้ partition ตั้งแต่ตอนนี้แล้ว)
--
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run
-- ไฟล์นี้ปลอดภัยหากรันซ้ำ (ใช้ IF NOT EXISTS / WHERE NOT EXISTS ทุกจุด)

create extension if not exists pgcrypto;

-- ============================================================
-- 1) LOOKUP TABLES
-- ============================================================

create table if not exists production_lines (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  plant_area text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table production_lines enable row level security;
drop policy if exists "production_lines_all_anon" on production_lines;
create policy "production_lines_all_anon" on production_lines for all
  using (true) with check (true);

create table if not exists machines (
  id uuid primary key default gen_random_uuid(),
  line_id uuid references production_lines(id) on delete set null,
  name text not null unique,
  model text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table machines enable row level security;
drop policy if exists "machines_all_anon" on machines;
create policy "machines_all_anon" on machines for all
  using (true) with check (true);
create index if not exists machines_line_idx on machines (line_id);

create table if not exists products (
  id uuid primary key default gen_random_uuid(),
  model_name text not null unique,
  category text,
  created_at timestamptz not null default now()
);
alter table products enable row level security;
drop policy if exists "products_all_anon" on products;
create policy "products_all_anon" on products for all
  using (true) with check (true);

create table if not exists defect_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_active boolean not null default true
);
alter table defect_categories enable row level security;
drop policy if exists "defect_categories_all_anon" on defect_categories;
create policy "defect_categories_all_anon" on defect_categories for all
  using (true) with check (true);

create table if not exists root_cause_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  is_active boolean not null default true
);
alter table root_cause_categories enable row level security;
drop policy if exists "root_cause_categories_all_anon" on root_cause_categories;
create policy "root_cause_categories_all_anon" on root_cause_categories for all
  using (true) with check (true);

-- Seed หมวดหมู่คงที่จาก CHECK constraint เดิมของ issues (ให้ครบทุกค่าแม้ยังไม่มีใครใช้)
insert into defect_categories (name) values
  ('Dimensional'), ('Visual/Cosmetic'), ('Functional'), ('Material'),
  ('Assembly'), ('Electrical'), ('Other')
on conflict (name) do nothing;

insert into root_cause_categories (name) values
  ('Man'), ('Machine'), ('Method'), ('Material'),
  ('Measurement'), ('Environment'), ('Other')
on conflict (name) do nothing;

-- Seed Production Line จากข้อความอิสระในตารางเดิมทั้งหมด
insert into production_lines (name)
select distinct trim(v.line) from (
  select line from issues where line is not null and trim(line) <> ''
  union
  select line from daily_activities where line is not null and trim(line) <> ''
  union
  select line from production_plans where line is not null and trim(line) <> ''
) v
on conflict (name) do nothing;

-- Seed Product จากข้อความอิสระในตารางเดิม
insert into products (model_name)
select distinct trim(v.product) from (
  select product from issues where product is not null and trim(product) <> ''
  union
  select product from daily_activities where product is not null and trim(product) <> ''
) v
on conflict (model_name) do nothing;

-- Seed Machine จากข้อความอิสระในตารางเดิม พร้อมผูก Line ให้ถ้าหาคู่ตรงได้
insert into machines (name, line_id)
select distinct on (trim(v.machine)) trim(v.machine), pl.id
from (
  select machine, line from issues where machine is not null and trim(machine) <> ''
  union
  select machine, line from daily_activities where machine is not null and trim(machine) <> ''
) v
left join production_lines pl on pl.name = trim(v.line)
on conflict (name) do nothing;

-- ============================================================
-- 2) WORK_ITEMS — ตารางหลักรวม Problem Management + Daily Activity
--    Partition by RANGE (received_date) รายปี รองรับ 10+ ปี
-- ============================================================

create table if not exists work_items (
  id uuid not null default gen_random_uuid(),
  received_date date not null default current_date,
  code text,
  source_type text not null check (source_type in ('Issue','DailyActivity')),
  source_id uuid not null,
  category text not null default 'Problem' check (category in ('Problem','Trial','Improvement')),
  title text,
  description text,
  line_id uuid references production_lines(id) on delete set null,
  machine_id uuid references machines(id) on delete set null,
  product_id uuid references products(id) on delete set null,
  process text,
  defect_category_id uuid references defect_categories(id) on delete set null,
  root_cause_category_id uuid references root_cause_categories(id) on delete set null,
  root_cause text,
  why1 text, why2 text, why3 text, why4 text, why5 text,
  corrective_action text,
  preventive_action text,
  result_outcome text,
  owner_name text,
  priority text check (priority is null or priority in ('High','Medium','Low')),
  severity text check (severity is null or severity in ('Critical','Major','Minor')),
  status text not null default 'Open' check (status in ('Open','In Progress','Closed')),
  due_date date,
  resolved_date date,
  start_time time,
  finish_time time,
  qty_ok numeric check (qty_ok is null or qty_ok >= 0),
  qty_ng numeric check (qty_ng is null or qty_ng >= 0),
  downtime_minutes numeric check (downtime_minutes is null or downtime_minutes >= 0),
  downtime_saved_minutes numeric check (downtime_saved_minutes is null or downtime_saved_minutes >= 0),
  cost_saving_thb numeric check (cost_saving_thb is null or cost_saving_thb >= 0),
  ng_reduced_qty numeric check (ng_reduced_qty is null or ng_reduced_qty >= 0),
  progress int check (progress is null or progress between 0 and 100),
  photo_before text,
  photo_after text,
  attachments jsonb default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (id, received_date)
) partition by range (received_date);

-- สร้าง partition รายปีล่วงหน้า 2020-2040 (ย้อนหลัง 6 ปี + อนาคต 14 ปี ครอบคลุมเกิน 10 ปีตามข้อกำหนด)
do $$
declare y int;
begin
  for y in 2020..2040 loop
    execute format(
      'create table if not exists work_items_%s partition of work_items for values from (%L) to (%L)',
      y, make_date(y, 1, 1), make_date(y + 1, 1, 1)
    );
  end loop;
end $$;

-- ดักข้อมูลที่วันที่หลุดช่วงด้านบน (กันข้อมูลตกหล่นแทนที่จะ error)
create table if not exists work_items_default partition of work_items default;

alter table work_items enable row level security;
drop policy if exists "work_items_all_anon" on work_items;
create policy "work_items_all_anon" on work_items for all
  using (true) with check (true);

create index if not exists work_items_status_idx on work_items (status);
create index if not exists work_items_category_idx on work_items (category);
create index if not exists work_items_line_idx on work_items (line_id);
create index if not exists work_items_owner_idx on work_items (owner_name);
create index if not exists work_items_source_idx on work_items (source_type, source_id);

-- ============================================================
-- 3) WORK_ITEM_UPDATES — รวม issue_updates (ไม่ partition ในเฟสนี้ ปริมาณต่ำกว่ามาก)
-- ============================================================

create table if not exists work_item_updates (
  id uuid primary key default gen_random_uuid(),
  work_item_id uuid not null,
  work_item_date date not null,
  update_date date not null default current_date,
  type text not null default 'progress' check (type in ('progress','approval')),
  note text,
  progress int check (progress is null or progress between 0 and 100),
  photo_url text,
  source_update_id uuid unique,
  created_at timestamptz not null default now(),
  foreign key (work_item_id, work_item_date) references work_items (id, received_date) on delete cascade
);
alter table work_item_updates enable row level security;
drop policy if exists "work_item_updates_all_anon" on work_item_updates;
create policy "work_item_updates_all_anon" on work_item_updates for all
  using (true) with check (true);
create index if not exists work_item_updates_wi_idx on work_item_updates (work_item_id);

-- ============================================================
-- 4) ATTACHMENTS — normalize jsonb เดิม (โครงตารางพร้อมใช้ ยังไม่ backfill ในเฟสนี้)
-- ============================================================

create table if not exists attachments (
  id uuid primary key default gen_random_uuid(),
  work_item_id uuid not null,
  work_item_date date not null,
  file_name text,
  file_url text not null,
  file_type text,
  uploaded_by text,
  uploaded_at timestamptz not null default now(),
  foreign key (work_item_id, work_item_date) references work_items (id, received_date) on delete cascade
);
alter table attachments enable row level security;
drop policy if exists "attachments_all_anon" on attachments;
create policy "attachments_all_anon" on attachments for all
  using (true) with check (true);
create index if not exists attachments_wi_idx on attachments (work_item_id);

-- ============================================================
-- 5) AUDIT_LOG — โครงตารางสำหรับการตรวจสอบย้อนหลัง (ยังไม่ผูก trigger ในเฟสนี้)
-- ============================================================

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  table_name text not null,
  record_id uuid not null,
  action text not null check (action in ('INSERT','UPDATE','DELETE')),
  changed_by text,
  old_value jsonb,
  new_value jsonb,
  changed_at timestamptz not null default now()
);
alter table audit_log enable row level security;
drop policy if exists "audit_log_all_anon" on audit_log;
create policy "audit_log_all_anon" on audit_log for all
  using (true) with check (true);
create index if not exists audit_log_table_record_idx on audit_log (table_name, record_id);
create index if not exists audit_log_changed_at_idx on audit_log (changed_at);

-- ============================================================
-- 6) BACKFILL — คัดลอกข้อมูลเดิมทั้งหมดเข้า work_items / work_item_updates
--    (ตารางต้นทางไม่ถูกแก้ไขใด ๆ ในขั้นตอนนี้)
-- ============================================================

insert into work_items (
  received_date, code, source_type, source_id, category, title, description,
  line_id, machine_id, product_id, defect_category_id, root_cause_category_id,
  root_cause, why1, why2, why3, why4, why5, corrective_action, preventive_action,
  owner_name, severity, status, due_date, resolved_date,
  qty_ok, qty_ng, downtime_minutes, progress, photo_before, photo_after, attachments,
  created_at, updated_at
)
select
  i.received_date, i.code, 'Issue', i.id, 'Problem', i.title, i.description,
  pl.id, mc.id, pd.id, dc.id, rc.id,
  i.root_cause, i.why1, i.why2, i.why3, i.why4, i.why5, i.corrective_action, i.preventive_action,
  i.owner, i.severity, i.status, i.due_date, i.resolved_date,
  i.qty_ok, i.qty_ng, i.downtime_minutes, i.progress, i.photo_before, i.photo_after,
  coalesce(i.attachments, '[]'::jsonb),
  i.created_at, i.updated_at
from issues i
left join production_lines pl on pl.name = trim(i.line)
left join machines mc on mc.name = trim(i.machine)
left join products pd on pd.model_name = trim(i.product)
left join defect_categories dc on dc.name = i.defect_category
left join root_cause_categories rc on rc.name = i.root_cause_category
where not exists (
  select 1 from work_items w where w.source_type = 'Issue' and w.source_id = i.id
);

insert into work_items (
  received_date, code, source_type, source_id, category, title, description,
  line_id, machine_id, product_id, process,
  root_cause, corrective_action, preventive_action, result_outcome,
  owner_name, priority, status,
  start_time, finish_time, qty_ok, qty_ng, downtime_minutes, downtime_saved_minutes,
  cost_saving_thb, ng_reduced_qty, progress, photo_before, photo_after, attachments,
  created_at, updated_at
)
select
  d.activity_date, null, 'DailyActivity', d.id, d.category, d.problem, d.description,
  pl.id, mc.id, pd.id, d.process,
  d.root_cause, d.corrective_action, d.preventive_action, d.result_outcome,
  d.owner, d.priority, d.status,
  d.start_time, d.finish_time, d.qty_ok, d.qty_ng, d.downtime_minutes, d.downtime_saved_minutes,
  d.cost_saving_thb, d.ng_reduced_qty, d.progress, d.photo_before, d.photo_after,
  coalesce(d.attachments, '[]'::jsonb),
  d.created_at, d.created_at
from daily_activities d
left join production_lines pl on pl.name = trim(d.line)
left join machines mc on mc.name = trim(d.machine)
left join products pd on pd.model_name = trim(d.product)
where not exists (
  select 1 from work_items w where w.source_type = 'DailyActivity' and w.source_id = d.id
);

insert into work_item_updates (work_item_id, work_item_date, update_date, type, note, progress, photo_url, source_update_id, created_at)
select w.id, w.received_date, u.update_date, u.type, u.note, u.progress, u.photo_url, u.id, u.created_at
from issue_updates u
join work_items w on w.source_type = 'Issue' and w.source_id = u.issue_id
where not exists (
  select 1 from work_item_updates wu where wu.source_update_id = u.id
);

-- ============================================================
-- 7) TRIGGERS — มิเรอร์ข้อมูลใหม่จากตารางเดิมเข้า work_items อัตโนมัติ
--    (แอปเดิมไม่ต้องแก้โค้ดใด ๆ ยังเขียนเข้า issues/daily_activities/issue_updates เหมือนเดิม)
-- ============================================================

create or replace function mirror_issue_to_work_item() returns trigger as $$
declare
  v_line_id uuid; v_machine_id uuid; v_product_id uuid; v_defect_id uuid; v_rc_id uuid;
  v_existing_id uuid; v_existing_date date;
begin
  select id into v_line_id from production_lines where name = trim(new.line);
  select id into v_machine_id from machines where name = trim(new.machine);
  select id into v_product_id from products where model_name = trim(new.product);
  select id into v_defect_id from defect_categories where name = new.defect_category;
  select id into v_rc_id from root_cause_categories where name = new.root_cause_category;

  select id, received_date into v_existing_id, v_existing_date
    from work_items where source_type = 'Issue' and source_id = new.id limit 1;

  if v_existing_id is not null then
    update work_items set
      code = new.code, title = new.title, description = new.description,
      line_id = v_line_id, machine_id = v_machine_id, product_id = v_product_id,
      defect_category_id = v_defect_id, root_cause_category_id = v_rc_id,
      root_cause = new.root_cause, why1 = new.why1, why2 = new.why2, why3 = new.why3,
      why4 = new.why4, why5 = new.why5,
      corrective_action = new.corrective_action, preventive_action = new.preventive_action,
      owner_name = new.owner, severity = new.severity, status = new.status,
      due_date = new.due_date, resolved_date = new.resolved_date,
      qty_ok = new.qty_ok, qty_ng = new.qty_ng, downtime_minutes = new.downtime_minutes,
      progress = new.progress, photo_before = new.photo_before, photo_after = new.photo_after,
      attachments = coalesce(new.attachments, '[]'::jsonb), updated_at = new.updated_at
    where id = v_existing_id and received_date = v_existing_date;
  else
    insert into work_items (
      received_date, code, source_type, source_id, category, title, description,
      line_id, machine_id, product_id, defect_category_id, root_cause_category_id,
      root_cause, why1, why2, why3, why4, why5, corrective_action, preventive_action,
      owner_name, severity, status, due_date, resolved_date,
      qty_ok, qty_ng, downtime_minutes, progress, photo_before, photo_after, attachments,
      created_at, updated_at
    ) values (
      new.received_date, new.code, 'Issue', new.id, 'Problem', new.title, new.description,
      v_line_id, v_machine_id, v_product_id, v_defect_id, v_rc_id,
      new.root_cause, new.why1, new.why2, new.why3, new.why4, new.why5,
      new.corrective_action, new.preventive_action,
      new.owner, new.severity, new.status, new.due_date, new.resolved_date,
      new.qty_ok, new.qty_ng, new.downtime_minutes, new.progress, new.photo_before, new.photo_after,
      coalesce(new.attachments, '[]'::jsonb), new.created_at, new.updated_at
    );
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_issue on issues;
create trigger trg_mirror_issue after insert or update on issues
for each row execute function mirror_issue_to_work_item();

create or replace function mirror_daily_activity_to_work_item() returns trigger as $$
declare
  v_line_id uuid; v_machine_id uuid; v_product_id uuid;
  v_existing_id uuid; v_existing_date date;
begin
  select id into v_line_id from production_lines where name = trim(new.line);
  select id into v_machine_id from machines where name = trim(new.machine);
  select id into v_product_id from products where model_name = trim(new.product);

  select id, received_date into v_existing_id, v_existing_date
    from work_items where source_type = 'DailyActivity' and source_id = new.id limit 1;

  if v_existing_id is not null then
    update work_items set
      title = new.problem, description = new.description,
      line_id = v_line_id, machine_id = v_machine_id, product_id = v_product_id,
      process = new.process, category = new.category,
      root_cause = new.root_cause, corrective_action = new.corrective_action,
      preventive_action = new.preventive_action, result_outcome = new.result_outcome,
      owner_name = new.owner, priority = new.priority, status = new.status,
      start_time = new.start_time, finish_time = new.finish_time,
      qty_ok = new.qty_ok, qty_ng = new.qty_ng,
      downtime_minutes = new.downtime_minutes, downtime_saved_minutes = new.downtime_saved_minutes,
      cost_saving_thb = new.cost_saving_thb, ng_reduced_qty = new.ng_reduced_qty,
      progress = new.progress, photo_before = new.photo_before, photo_after = new.photo_after,
      attachments = coalesce(new.attachments, '[]'::jsonb), updated_at = now()
    where id = v_existing_id and received_date = v_existing_date;
  else
    insert into work_items (
      received_date, code, source_type, source_id, category, title, description,
      line_id, machine_id, product_id, process,
      root_cause, corrective_action, preventive_action, result_outcome,
      owner_name, priority, status,
      start_time, finish_time, qty_ok, qty_ng, downtime_minutes, downtime_saved_minutes,
      cost_saving_thb, ng_reduced_qty, progress, photo_before, photo_after, attachments,
      created_at, updated_at
    ) values (
      new.activity_date, null, 'DailyActivity', new.id, new.category, new.problem, new.description,
      v_line_id, v_machine_id, v_product_id, new.process,
      new.root_cause, new.corrective_action, new.preventive_action, new.result_outcome,
      new.owner, new.priority, new.status,
      new.start_time, new.finish_time, new.qty_ok, new.qty_ng, new.downtime_minutes, new.downtime_saved_minutes,
      new.cost_saving_thb, new.ng_reduced_qty, new.progress, new.photo_before, new.photo_after,
      coalesce(new.attachments, '[]'::jsonb), new.created_at, new.created_at
    );
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_daily_activity on daily_activities;
create trigger trg_mirror_daily_activity after insert or update on daily_activities
for each row execute function mirror_daily_activity_to_work_item();

create or replace function mirror_issue_update_to_work_item() returns trigger as $$
declare v_work_item_id uuid; v_work_item_date date;
begin
  select id, received_date into v_work_item_id, v_work_item_date
    from work_items where source_type = 'Issue' and source_id = new.issue_id limit 1;

  if v_work_item_id is not null then
    insert into work_item_updates (work_item_id, work_item_date, update_date, type, note, progress, photo_url, source_update_id, created_at)
    values (v_work_item_id, v_work_item_date, new.update_date, new.type, new.note, new.progress, new.photo_url, new.id, new.created_at)
    on conflict (source_update_id) do nothing;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_mirror_issue_update on issue_updates;
create trigger trg_mirror_issue_update after insert on issue_updates
for each row execute function mirror_issue_update_to_work_item();

-- ============================================================
-- ตรวจสอบผลลัพธ์ด้วยตนเองหลังรัน (ไม่บังคับ — คัดลอกไปรันแยกได้):
--
-- select count(*) from work_items;                                -- ควร = count(issues) + count(daily_activities)
-- select (select count(*) from issues) + (select count(*) from daily_activities) as expected;
-- select count(*) from work_item_updates;                         -- ควร = count(issue_updates)
-- select source_type, count(*) from work_items group by source_type;
-- ============================================================
