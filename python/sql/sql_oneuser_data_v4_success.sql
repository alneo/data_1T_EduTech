with
success_acts as
(
select user_id, activity_id, min(created_at) first_success
from exercise_results_v4 erv
where (success = 1) and (activity_id is not null)
group by user_id, activity_id
),
first_views as
(
select user_id, page_id activity_id, attestation, min(created_at) first_view
from activity_history_viewed_v4
where page_type = 'активность'
group by user_id, activity_id, attestation
),
schedule_plus as
(
select sc.course_id, agv.activity_id, sc.date_shown, agv.obyaz_priznak, agv.att_priznak
from schedule_v4 sc
join activities_guide_v4 agv on sc.activivty_id = agv.activity_id
where sc.type = 'активность' and sc.date_shown is not null
)
,
all_acts as
(
select user_id, uv.course_id, activity_id, date_shown, obyaz_priznak, att_priznak
from users_v4 uv
full outer join schedule_plus as sch
on uv.course_id = sch.course_id
),
all_activities as
(
select aa.user_id, aa.course_id, aa.activity_id, date_shown, obyaz_priznak, att_priznak, first_success, first_view
from all_acts aa
left join success_acts sa
on (aa.user_id) = (sa.user_id) and (aa.activity_id) = (sa.activity_id)
left join first_views fa
on (aa.user_id) = (fa.user_id) and (aa.activity_id) = (fa.activity_id)
),
days_table as
(
select date_trunc('day', dd)::date k_day
from generate_series
        (:start_date::timestamp  --'2023-12-01'::timestamp
        , current_date --'2024-06-30'::timestamp
        , '1 day'::interval) dd
)
,
metrics_1 as
(
select
k_day,
t1.date_shown,
t1.user_id,
t1.course_id,
t1.activity_id,
t1.obyaz_priznak,
case
  when  (k_day > t1.date_shown) and (obyaz_priznak = 1) and  ((k_day < t1.first_success) or (t1.first_success is null)) then  k_day-date_trunc('day', t1.date_shown):: date
  else 0
end required_activities_delay,
case
  when  (k_day >= t1.first_success) and (obyaz_priznak = 1) then  1
  else 0
end success_required_done,
case
  when  (k_day >= t1.first_success) and (obyaz_priznak = 0) then  1
  else 0
end success_optional_done,
CASE
  WHEN (obyaz_priznak = 1) AND (k_day = er.created_at::date) THEN
    CASE
      WHEN er.result ~ '^\d+$'  -- Проверяем, что строка состоит только из цифр
      THEN er.result::INTEGER   -- Преобразуем в целое число
      ELSE -1                     -- Если это "Пропуск, возвращаем 0
    END
  ELSE -1
END AS result_required_exercise
from (select * from all_activities where user_id = :user_id and att_priznak = 0) t1
left join public.exercise_results_v4 er
on t1.user_id = er.user_id and t1.activity_id = er.activity_id
cross join days_table
)
,
metrics_2 as
(
select k_day, user_id, course_id,
sum(required_activities_delay) required_activities_delay,
sum(success_required_done) success_required_done,
sum(success_optional_done) success_optional_done,
avg(result_required_exercise) filter (where result_required_exercise >= 0) mean_result_required,
sum(obyaz_priznak) filter(where k_day >= date_shown ) cur_date_required_number,
sum(obyaz_priznak) required_number
from metrics_1
group by user_id, k_day, course_id
order by k_day
)
,
dt as(
select
m2.k_day, m2.user_id, m2.course_id, m2.required_activities_delay, success_required_done,
coalesce ((avg(mean_result_required) over(partition by m2.user_id order by k_day)::int), 0) mean_result_required,
case
	when cur_date_required_number > 0 then coalesce ((100 * (1.0*success_required_done/cur_date_required_number))::int, 0)
	else 0
end cur_date_progress,
100 * (success_required_done + success_optional_done)/(required_number + success_optional_done) current_progress,
course_progress2 real_course_progress,
case
		WHEN users.course_attestation ~ '^\d+$' -- Проверяем, что строка состоит только из цифр
        THEN users.course_attestation::INTEGER  -- Преобразуем в целое число
        ELSE 0                     -- Если это не число, возвращаем 0
end course_attestation
from metrics_2 m2
left join public.users_v4 users
on m2.user_id = users.user_id and m2.course_id = users.course_id
)
,
dt_final as(
select k_day, user_id, course_id, required_activities_delay, success_required_done, mean_result_required, cur_date_progress, current_progress
	, case
		when (cur_date_progress < 30 or mean_result_required < 33) then 0
		when (cur_date_progress between 30 and 60) then 1
		when (cur_date_progress > 60) then 2
	end as status
	, real_course_progress
	, case
		when course_id = 76 then case
							when course_attestation >= 10 then 1 else 0
							end
		when course_id in(77, 82, 83) then case
							when course_attestation >= 60 then 1 else 0
							end
	end course_success
from dt where k_day < current_date
				and user_id in(select distinct user_id from dt where k_day = current_date and abs(current_progress - real_course_progress) <= 10)
)

select
	user_id, course_id
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '1 weeks') required_activities_delay_1_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '2 weeks') required_activities_delay_2_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '3 weeks') required_activities_delay_3_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '4 weeks') required_activities_delay_4_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '5 weeks') required_activities_delay_5_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '6 weeks') required_activities_delay_6_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '7 weeks') required_activities_delay_7_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '8 weeks') required_activities_delay_8_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '9 weeks') required_activities_delay_9_week
	, min(required_activities_delay) filter (where k_day = :start_date::date + INTERVAL '10 weeks') required_activities_delay_10_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '1 weeks') success_required_done_1_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '2 weeks') success_required_done_2_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '3 weeks') success_required_done_3_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '4 weeks') success_required_done_4_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '5 weeks') success_required_done_5_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '6 weeks') success_required_done_6_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '7 weeks') success_required_done_7_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '8 weeks') success_required_done_8_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '9 weeks') success_required_done_9_week
	, min(success_required_done) filter (where k_day = :start_date::date + INTERVAL '10 weeks') success_required_done_10_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '1 weeks') as mean_result_required_1_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '2 weeks') as mean_result_required_2_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '3 weeks') as mean_result_required_3_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '4 weeks') as mean_result_required_4_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '5 weeks') as mean_result_required_5_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '6 weeks') as mean_result_required_6_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '7 weeks') as mean_result_required_7_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '8 weeks') as mean_result_required_8_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '9 weeks') as mean_result_required_9_week
	, min(mean_result_required) filter (where k_day = :start_date::date + INTERVAL '10 weeks') as mean_result_required_10_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '1 weeks') cur_date_progress_1_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '2 weeks') cur_date_progress_2_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '3 weeks') cur_date_progress_3_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '4 weeks') cur_date_progress_4_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '5 weeks') cur_date_progress_5_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '6 weeks') cur_date_progress_6_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '7 weeks') cur_date_progress_7_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '8 weeks') cur_date_progress_8_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '9 weeks') cur_date_progress_9_week
	, min(cur_date_progress) filter (where k_day = :start_date::date + INTERVAL '10 weeks') cur_date_progress_10_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '1 weeks') current_progress_1_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '2 weeks') current_progress_2_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '3 weeks') current_progress_3_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '4 weeks') current_progress_4_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '5 weeks') current_progress_5_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '6 weeks') current_progress_6_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '7 weeks') current_progress_7_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '8 weeks') current_progress_8_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '9 weeks') current_progress_9_week
	, min(current_progress) filter (where k_day = :start_date::date + INTERVAL '10 weeks') current_progress_10_week
	, max(status) filter(where k_day = :start_date::date + INTERVAL '10 weeks') end_status,
	--- real_course_progress,
	course_success m2_success
from dt_final
group by 1, 2, real_course_progress, course_success;