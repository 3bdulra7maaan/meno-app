-- Meno Phase 2 fresh-project schema. Run once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.question_status as enum ('pending', 'approved', 'rejected');

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  author_name text,
  title text not null check (char_length(title) between 8 and 120),
  body text not null check (char_length(body) between 1 and 500),
  category text not null,
  is_anonymous boolean not null default false,
  status public.question_status not null default 'pending',
  created_at timestamptz not null default now()
);

create table public.answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  author_name text,
  body text not null check (char_length(body) between 1 and 1000),
  helpful_count integer not null default 0 check (helpful_count >= 0),
  created_at timestamptz not null default now()
);

create table public.helpful_votes (
  answer_id uuid not null references public.answers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (answer_id, user_id)
);

create index questions_status_created_at_idx
  on public.questions(status, created_at desc);
create index answers_question_created_at_idx
  on public.answers(question_id, created_at);

alter table public.questions enable row level security;
alter table public.answers enable row level security;
alter table public.helpful_votes enable row level security;

create policy "Anyone reads approved questions"
  on public.questions for select
  to anon, authenticated
  using (status = 'approved');

create policy "Users read their own submitted questions"
  on public.questions for select
  to authenticated
  using (user_id = auth.uid());

create policy "Anonymous sessions submit pending questions"
  on public.questions for insert
  to authenticated
  with check (user_id = auth.uid() and status = 'pending');

create policy "Anyone reads answers to approved questions"
  on public.answers for select
  to anon, authenticated
  using (
    exists (
      select 1 from public.questions q
      where q.id = question_id and q.status = 'approved'
    )
  );

create policy "Anonymous sessions answer approved questions"
  on public.answers for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.questions q
      where q.id = question_id and q.status = 'approved'
    )
  );

create policy "Users read their own helpful votes"
  on public.helpful_votes for select
  to authenticated
  using (user_id = auth.uid());

create or replace function public.toggle_helpful(answer_id_input uuid)
returns table(is_helpful boolean, helpful_count integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1
    from public.answers a
    join public.questions q on q.id = a.question_id
    where a.id = answer_id_input and q.status = 'approved'
  ) then
    raise exception 'Answer is not available';
  end if;

  if exists (
    select 1 from public.helpful_votes
    where answer_id = answer_id_input and user_id = current_user_id
  ) then
    delete from public.helpful_votes
    where answer_id = answer_id_input and user_id = current_user_id;
    update public.answers
    set helpful_count = greatest(public.answers.helpful_count - 1, 0)
    where id = answer_id_input;
    is_helpful := false;
  else
    insert into public.helpful_votes(answer_id, user_id)
    values (answer_id_input, current_user_id);
    update public.answers
    set helpful_count = public.answers.helpful_count + 1
    where id = answer_id_input;
    is_helpful := true;
  end if;

  select a.helpful_count into helpful_count
  from public.answers a where a.id = answer_id_input;
  return next;
end;
$$;

revoke all on function public.toggle_helpful(uuid) from public, anon;
grant execute on function public.toggle_helpful(uuid) to authenticated;

grant usage on schema public to anon, authenticated;
grant select on public.questions, public.answers to anon, authenticated;
grant insert on public.questions, public.answers to authenticated;
grant select on public.helpful_votes to anon, authenticated;

-- Moderation intentionally has no client-side update policy. Approve or reject
-- questions from Supabase Table Editor, or from a trusted server using service_role.
