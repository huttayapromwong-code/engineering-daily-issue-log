-- Engineering Daily Issue Log — migration v8
-- เพิ่มคอลัมน์ customer, lot_no ใน work_items (เพื่อรองรับ Case Card ในรายงาน Management Report)
-- Additive ทั้งหมด — ไม่กระทบตารางเดิม (issues, daily_activities) หรือข้อมูลที่มีอยู่
--
-- หมายเหตุ:
--   - customer: มิเรอร์จาก issues.customer อัตโนมัติ (คอลัมน์นี้มีอยู่แล้วใน issues)
--   - lot_no: เป็นข้อมูลใหม่ที่ไม่เคยถูกบันทึกไว้ที่ไหนมาก่อน (ไม่มีทั้งใน issues และ daily_activities)
--     จึงจะเป็นค่าว่างสำหรับข้อมูลเดิมทั้งหมด จนกว่าจะมีการเพิ่มช่องกรอก Lot No.
--     ที่ฟอร์มบันทึกข้อมูลจริง (อยู่นอกขอบเขตของการปรับปรุงรายงานครั้งนี้)
--
-- วิธีใช้: คัดลอกทั้งไฟล์นี้ไปวางใน Supabase > SQL Editor > New query แล้วกด Run

alter table work_items add column if not exists customer text;
alter table work_items add column if not exists lot_no text;
alter table work_items add column if not exists remark text;

-- อัปเดต trigger function ให้มิเรอร์ customer จาก issues (insert/update)
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
      attachments = coalesce(new.attachments, '[]'::jsonb), updated_at = new.updated_at,
      customer = new.customer
    where id = v_existing_id and received_date = v_existing_date;
  else
    insert into work_items (
      received_date, code, source_type, source_id, category, title, description,
      line_id, machine_id, product_id, defect_category_id, root_cause_category_id,
      root_cause, why1, why2, why3, why4, why5, corrective_action, preventive_action,
      owner_name, severity, status, due_date, resolved_date,
      qty_ok, qty_ng, downtime_minutes, progress, photo_before, photo_after, attachments,
      created_at, updated_at, customer
    ) values (
      new.received_date, new.code, 'Issue', new.id, 'Problem', new.title, new.description,
      v_line_id, v_machine_id, v_product_id, v_defect_id, v_rc_id,
      new.root_cause, new.why1, new.why2, new.why3, new.why4, new.why5,
      new.corrective_action, new.preventive_action,
      new.owner, new.severity, new.status, new.due_date, new.resolved_date,
      new.qty_ok, new.qty_ng, new.downtime_minutes, new.progress, new.photo_before, new.photo_after,
      coalesce(new.attachments, '[]'::jsonb), new.created_at, new.updated_at, new.customer
    );
  end if;
  return new;
end;
$$ language plpgsql;

-- อัปเดต trigger function ให้มิเรอร์ remark จาก daily_activities (insert/update)
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
      attachments = coalesce(new.attachments, '[]'::jsonb), updated_at = now(),
      remark = new.remark
    where id = v_existing_id and received_date = v_existing_date;
  else
    insert into work_items (
      received_date, code, source_type, source_id, category, title, description,
      line_id, machine_id, product_id, process,
      root_cause, corrective_action, preventive_action, result_outcome,
      owner_name, priority, status,
      start_time, finish_time, qty_ok, qty_ng, downtime_minutes, downtime_saved_minutes,
      cost_saving_thb, ng_reduced_qty, progress, photo_before, photo_after, attachments,
      created_at, updated_at, remark
    ) values (
      new.activity_date, null, 'DailyActivity', new.id, new.category, new.problem, new.description,
      v_line_id, v_machine_id, v_product_id, new.process,
      new.root_cause, new.corrective_action, new.preventive_action, new.result_outcome,
      new.owner, new.priority, new.status,
      new.start_time, new.finish_time, new.qty_ok, new.qty_ng, new.downtime_minutes, new.downtime_saved_minutes,
      new.cost_saving_thb, new.ng_reduced_qty, new.progress, new.photo_before, new.photo_after,
      coalesce(new.attachments, '[]'::jsonb), new.created_at, new.created_at, new.remark
    );
  end if;
  return new;
end;
$$ language plpgsql;

-- Backfill customer/remark สำหรับข้อมูลเดิมที่มิเรอร์ไว้แล้วก่อนหน้า migration นี้
update work_items w
set customer = i.customer
from issues i
where w.source_type = 'Issue' and w.source_id = i.id and i.customer is not null;

update work_items w
set remark = d.remark
from daily_activities d
where w.source_type = 'DailyActivity' and w.source_id = d.id and d.remark is not null;
