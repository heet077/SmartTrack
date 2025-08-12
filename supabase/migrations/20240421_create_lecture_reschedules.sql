-- Enable the pg_cron extension
create extension if not exists pg_cron;

-- Create lecture_reschedules table
create table if not exists lecture_reschedules (
  id uuid primary key,
  original_schedule_id uuid not null references course_schedule_slots(id),
  course_id uuid not null references courses(id),
  instructor_id uuid not null references instructors(id),
  original_datetime timestamp with time zone not null,
  rescheduled_datetime timestamp with time zone not null,
  classroom text not null,
  expiry_date timestamp with time zone not null,
  created_at timestamp with time zone not null default now(),
  constraint lecture_reschedules_unique_schedule unique (original_schedule_id, rescheduled_datetime)
);

-- Add RLS policies
alter table lecture_reschedules enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Instructors can view their own reschedules" on lecture_reschedules;
drop policy if exists "Instructors can create reschedules" on lecture_reschedules;
drop policy if exists "Instructors can delete their own reschedules" on lecture_reschedules;

-- Create policies
create policy "Instructors can view their own reschedules"
  on lecture_reschedules for select
  using (instructor_id = auth.uid());

create policy "Instructors can create reschedules"
  on lecture_reschedules for insert
  with check (instructor_id = auth.uid());

create policy "Instructors can delete their own reschedules"
  on lecture_reschedules for delete
  using (instructor_id = auth.uid());

-- Drop existing function and trigger
drop trigger if exists cleanup_expired_reschedules_trigger on lecture_reschedules;
drop function if exists cleanup_expired_reschedules();

-- Create function to clean up expired reschedules
create function cleanup_expired_reschedules()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Delete expired reschedules
  delete from lecture_reschedules
  where expiry_date < now();
  
  return new;
end;
$$;

-- Create trigger to clean up expired reschedules on any operation
create trigger cleanup_expired_reschedules_trigger
  after insert or update or delete
  on lecture_reschedules
  for each statement
  execute function cleanup_expired_reschedules();

-- Drop existing conflict check function
drop function if exists check_lecture_schedule_conflict(timestamp with time zone, text);

-- Create function to check for conflicts
create function check_lecture_schedule_conflict(
  p_rescheduled_datetime timestamp with time zone,
  p_classroom text
)
returns table (
  has_conflict boolean,
  conflict_details jsonb
)
language plpgsql
security definer
as $$
declare
  v_conflict_details jsonb;
begin
  -- Check for existing schedule at the same time and classroom
  select jsonb_build_object(
    'course', jsonb_build_object(
      'id', c.id,
      'code', c.code,
      'name', c.name
    ),
    'instructor', jsonb_build_object(
      'id', i.id,
      'name', i.name,
      'short_name', i.short_name
    ),
    'schedule', jsonb_build_object(
      'classroom', cs.classroom,
      'start_time', cs.start_time,
      'end_time', cs.end_time
    )
  )
  into v_conflict_details
  from course_schedule_slots cs
  join instructor_course_assignments ica on cs.assignment_id = ica.id
  join courses c on ica.course_id = c.id
  join instructors i on ica.instructor_id = i.id
  where cs.classroom = p_classroom
    and extract(dow from p_rescheduled_datetime) = cs.day_of_week
    and to_char(p_rescheduled_datetime, 'HH24:MI:SS') = cs.start_time::text;

  if v_conflict_details is not null then
    return query select true as has_conflict, v_conflict_details as conflict_details;
  else
    return query select false as has_conflict, null::jsonb as conflict_details;
  end if;
end;
$$; 