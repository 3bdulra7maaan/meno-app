-- Additive V1.2.1 production-readiness migration. Apply before deploying
-- the paged Flutter client. No existing question, answer or vote is changed.

create index if not exists questions_approved_cursor_idx
  on public.questions (created_at desc, id desc)
  where status = 'approved';

create index if not exists questions_approved_category_cursor_idx
  on public.questions (category, created_at desc, id desc)
  where status = 'approved';

create or replace function public.normalize_meno_search_text(input_text text)
returns text
language sql
immutable
set search_path = public
as $$
  select trim(regexp_replace(
    regexp_replace(
      translate(
        lower(coalesce(input_text, '')),
        'أإآٱىؤئة',
        'اااايويه'
      ),
      '[ً-ٰٟۖ-ۭـ]', '', 'g'
    ),
    '[^a-z0-9ء-ي]+', ' ', 'g'
  ));
$$;

create or replace function public.approved_question_page(
  search_input text default '',
  category_input text default null,
  cursor_created_at timestamptz default null,
  cursor_id uuid default null,
  page_size integer default 20
)
returns table (
  id uuid,
  title text,
  body text,
  category text,
  author_name text,
  is_anonymous boolean,
  status public.question_status,
  created_at timestamptz,
  answer_count bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  with requested as (
    select public.normalize_meno_search_text(left(search_input, 120)) as term
  ), page as materialized (
    select q.id, q.title, q.body, q.category, q.author_name,
      q.is_anonymous, q.status, q.created_at
    from public.questions q cross join requested r
    where q.status = 'approved'
      and (category_input is null or q.category = category_input)
      and (
        cursor_created_at is null or cursor_id is null
        or (q.created_at, q.id) < (cursor_created_at, cursor_id)
      )
      and (
        r.term = '' or not exists (
          select 1
          from unnest(string_to_array(r.term, ' ')) as term(value)
          where public.normalize_meno_search_text(
            q.title || ' ' || q.body || ' ' || q.category
          ) not like '%' || term.value || '%'
        )
      )
    order by q.created_at desc, q.id desc
    limit least(greatest(coalesce(page_size, 20), 1), 50) + 1
  )
  select page.id, page.title, page.body, page.category, page.author_name,
    page.is_anonymous, page.status, page.created_at,
    (select count(*) from public.answers a
      where a.question_id = page.id and not a.is_hidden) as answer_count
  from page
  order by page.created_at desc, page.id desc;
$$;

revoke all on function public.approved_question_page(
  text, text, timestamptz, uuid, integer
) from public;
grant execute on function public.approved_question_page(
  text, text, timestamptz, uuid, integer
) to anon, authenticated;
