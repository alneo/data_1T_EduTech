--скрипт из загруженной таблицы table_glu_dt_v3. Переменные:
--:date - дата среза, дата, которую вводит пользователь вебки
--:user_id - user_id
SELECT user_id, status
FROM table_glu_dt_v3
WHERE k_day = :date::date and user_id = :user_id


--полный скрипт из исходных таблиц
with 
success_acts as 
(
select user_id, activity_id, min(created_at) first_success
from exercise_results_v2 erv 
where (success = 1) and (activity_id is not null)
group by user_id, activity_id
),
first_views as 
(
select user_id, page_id activity_id, attestation, min(created_at) first_view
from activity_history_viewed_v2
where page_type = 'активность'
group by user_id, activity_id, attestation
),
schedule_plus as 
(
select sc.course_id, agv.activity_id, sc.date_shown, agv.obyaz_priznak, agv.att_priznak 
from schedule_v2 sc
join activities_guide_v2 agv on sc.activivty_id = agv.activity_id 
where sc.type = 'активность'
),
all_acts as
(
select user_id, uv.course_id, activity_id, date_shown, obyaz_priznak, att_priznak
from users_v2 uv
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
        , :finish_date::timestamp --current_date --
        , '1 day'::interval) dd 
),
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
END AS result_required_exercise,
k_day - :start_date::date start_day_lag
from (select * from all_activities where /*user_id = :user_id and */att_priznak = 0) t1
left join public.exercise_results_v2 er
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
sum(obyaz_priznak) required_number,
avg(start_day_lag) start_day_lag
from metrics_1
group by user_id, k_day, course_id
order by k_day
)
,
dt as(
select 
m2.k_day, m2.user_id, m2.course_id, m2.required_activities_delay, success_required_done, success_optional_done,
coalesce ((avg(mean_result_required) over(partition by m2.user_id order by k_day)::int), 0) mean_result_required,
case 
	when start_day_lag > 0 then 1.0*(success_required_done + success_optional_done)/ start_day_lag
	else 0
end as cur_date_speed,
coalesce ((100 * (1.0*success_required_done/cur_date_required_number))::int, 0) cur_date_progress,
100 * (success_required_done + success_optional_done)/(required_number + success_optional_done) current_progress,
case 
	WHEN m2_progress ~ '^\d+$' -- Проверяем, что строка состоит только из цифр
        THEN m2_progress::INTEGER  -- Преобразуем в целое число
        ELSE 0                     -- Если это не число, возвращаем 0
end m2_progress,
case 
		WHEN m2_attestation ~ '^\d+$' -- Проверяем, что строка состоит только из цифр
        THEN m2_attestation::INTEGER  -- Преобразуем в целое число
        ELSE 0                     -- Если это не число, возвращаем 0
end m2_attestation
from metrics_2 m2
left join public.users_v2 users
on m2.user_id = users.user_id and m2.course_id = users.course_id
)
,
dt_final as(
select k_day, user_id, course_id, required_activities_delay, success_required_done, success_optional_done, mean_result_required
	, round(cur_date_speed, 2) cur_date_speed
	, round((avg(cur_date_speed) over(partition by user_id order by k_day)), 2) avg_speed
	, cur_date_progress
	, current_progress
	, case 
		when (cur_date_progress < 30 or mean_result_required < 33) then 0 
		when (cur_date_progress between 30 and 60) then 1
		when (cur_date_progress > 60) then 2
	end as status
	, m2_progress
	, case 
		when m2_progress > 49 and m2_attestation > 49 then 1
		else 0
	end m2_success	
from dt where k_day < :finish_date
--				and user_id in(select distinct user_id from dt where k_day = :finish_date and abs(current_progress - m2_progress) <= 10)
)

SELECT user_id, status
FROM dt_final
WHERE k_day = :date::date and user_id = :user_id