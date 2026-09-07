-- Non-destructive fix: branch on the table before reading table-specific fields.
create or replace function public.audit_moderation_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  audit_action text;
  audit_type text;
begin
  if not public.is_meno_admin() then
    return new;
  end if;

  if tg_table_name = 'questions' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    audit_action := 'status:' || new.status::text;
    audit_type := 'question';
  elsif tg_table_name = 'answers' then
    if old.is_hidden is not distinct from new.is_hidden then
      return new;
    end if;
    audit_action := case when new.is_hidden then 'hide' else 'restore' end;
    audit_type := 'answer';
  elsif tg_table_name = 'answer_reports' then
    if old.status is not distinct from new.status then
      return new;
    end if;
    audit_action := 'status:' || new.status;
    audit_type := 'report';
  else
    return new;
  end if;

  insert into public.moderation_actions(
    actor_user_id, object_type, object_id, action
  ) values (auth.uid(), audit_type, new.id, audit_action);
  return new;
end;
$$;
