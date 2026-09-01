create type public.question_status as enum ('pending', 'approved', 'rejected');

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  author_name text,
  title text not null check (char_length(title) between 8 and 120),
  body text not null check (char_length(body) <= 500),
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
  body text not null,
  helpful_count integer not null default 0 check (helpful_count >= 0),
  created_at timestamptz not null default now()
);

create table public.helpful_votes (
  answer_id uuid not null references public.answers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (answer_id, user_id)
);

alter table public.questions enable row level security;
alter table public.answers enable row level security;
alter table public.helpful_votes enable row level security;

create policy "Public reads approved questions" on public.questions for select using (status = 'approved');
create policy "Authenticated users submit questions" on public.questions for insert to authenticated with check (status = 'pending' and user_id = auth.uid());
create policy "Public reads answers to approved questions" on public.answers for select using (exists (select 1 from public.questions q where q.id = question_id and q.status = 'approved'));
create policy "Authenticated users submit answers" on public.answers for insert to authenticated with check (user_id = auth.uid());
create policy "Users manage own helpful votes" on public.helpful_votes for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Grant service-role users/admin tooling permission to moderate by updating status.
-- Never expose the service-role key in the Flutter app.

create or replace function public.toggle_helpful(answer_id_input uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from helpful_votes where answer_id = answer_id_input and user_id = auth.uid()) then
    delete from helpful_votes where answer_id = answer_id_input and user_id = auth.uid();
    update answers set helpful_count = greatest(helpful_count - 1, 0) where id = answer_id_input;
  else
    insert into helpful_votes(answer_id, user_id) values (answer_id_input, auth.uid());
    update answers set helpful_count = helpful_count + 1 where id = answer_id_input;
  end if;
end;
$$;
