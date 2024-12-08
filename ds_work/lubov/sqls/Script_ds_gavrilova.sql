-- очистка датасета

--truncate table ds_gavrilova;

-- удаление из расписания офлайн занятий

create temp table schedule_online as ( 
	select 
		schedule_v3.page_id,
		activity_type,
		themes_v3.course_id,
		date_shown,
		deadline,
		COALESCE(obyaz_priznak, 0) as required,
		is_attestation,
		COALESCE(webinar_vvod, 0) as webinar_vvod,
		case 
			when activity_type in (
				select activity_type 
				from exercise_results_v3 
				join pages_v3 
				on exercise_results_v3.page_id = pages_v3.page_id
				join activities_v3
				on pages_v3.activity_id = activities_v3.activity_id
			) then 1
			else 0
		end
		 as exercise
	from schedule_v3
	join pages_v3
	on schedule_v3.page_id = pages_v3.page_id and visibility not like '%офлайн%'
	join tasks_v3
	on pages_v3.task_id = tasks_v3.task_id
	join themes_v3
	on tasks_v3.theme_id = themes_v3.theme_id
	left join activities_v3
	on pages_v3.activity_id = activities_v3.activity_id
);
	

-- определение онлайн-юзеров

create temp table online_users as (
with tags as ( -- уточнение тегов 'онлайн', 'офлайн', 'оплачено'
	SELECT 
	    user_id,
	    CASE 
	        WHEN comment LIKE '%Были хештеги:%онлайн%стали:%' THEN 'онлайн'
	        ELSE 
	        	case
		        	when comment LIKE '%Были хештеги:%офлайн%стали:%' THEN 'офлайн'
		        	else 'онлайн' 
		        end
	    END AS old_tags,
	    CASE 
	        WHEN comment LIKE '%стали:%онлайн%' THEN 'онлайн'
	        else
		        case
			        WHEN comment LIKE '%стали:%офлайн%' THEN 'офлайн'
		        	ELSE 'онлайн'
		        end
	    END AS new_tags,
	    CASE 
	        WHEN comment LIKE '%оплачен%' THEN 1
	        ELSE 0 
	    END AS payment
	FROM users_logs_v3),
tags_groupped AS ( -- определение онлайников без смены формата
	SELECT user_id, max(payment) AS payment 
	FROM tags 
	WHERE old_tags = 'онлайн' and new_tags = 'онлайн'
	GROUP BY user_id),
no_att AS ( -- удаление юзеров без данных об аттестации
	select distinct
		tags_groupped.*,
		attestation_v3.course_id,
		attestation_v3.course_progress,
		attestation_v3.course_attestation,
		attestation_v3.course_attestation_date
	from tags_groupped
	join attestation_v3
	on tags_groupped.user_id = attestation_v3.user_id
	where course_progress != 'Нет данных'),
double_course as ( -- удаление юзеров, записанных на второй курс
	SELECT no_att.*
	FROM no_att
	WHERE course_attestation != 'Не сдана' AND user_id IN (
	    SELECT user_id
	    FROM no_att
	    GROUP BY user_id
	    HAVING COUNT(*) != 1)
	UNION 
	SELECT no_att.*
	FROM no_att
	WHERE user_id NOT IN (
	    SELECT user_id
	    FROM no_att
	    GROUP BY user_id
	    HAVING COUNT(*) != 1))
SELECT 
	users_v3.*, 
	double_course.payment, 
	double_course.course_id,
	course_progress, 
	course_attestation, 
	course_attestation_date, -- объединение с персональной информацией
	min_attestation_rate
FROM double_course
LEFT JOIN users_v3
ON double_course.user_id = users_v3.user_id
join courses_v3
on courses_v3.course_id = double_course.course_id
);


-- создание расписания для каждого онлайн-юзера

create temp table online_users_schedule as (
	select 
		user_id,
		online_users.course_id,
		page_id,
		activity_type,
		date_shown,
		deadline,
		required,
		is_attestation,
		webinar_vvod,
		exercise
	from online_users
	left join  schedule_online
	on schedule_online.course_id = online_users.course_id
);

create temp table online_users_schedule_exercises as (
	select 
		user_id,
		online_users.course_id,
		page_id,
		activity_type,
		date_shown,
		deadline,
		required,
		is_attestation,
		webinar_vvod,
		exercise
	from online_users
	left join  schedule_online
	on schedule_online.course_id = online_users.course_id 
		and activity_type in (
			select distinct activity_type 
			from exercise_results_v3 
			join pages_v3 
			on exercise_results_v3.page_id = pages_v3.page_id
			join activities_v3
			on pages_v3.activity_id = activities_v3.activity_id
		)
);


-- создание временных рядов для каждого онлайн-юзера

create temp table time_series as (
	select online_users.user_id,
	    generate_series((min(date_shown) + interval '1 day')::date, (max(deadline) + interval '1 day')::date, '1 day'::interval) AS cur_date,
		online_users.course_id,
	    min(date_shown) as start_date,
	    max(deadline) as finish_date,
	    min(deadline) as deadline_first
	from online_users
	join schedule_online
	on schedule_online.course_id = online_users.course_id
	group by
		online_users.user_id,
		online_users.course_id);
		
	
-- добавление метрик авторизации
	
create temp table auth as (
	SELECT
	    time_series.user_id,
	    time_series.cur_date, 
	    count(created_at) as sum_auth,
		min(created_at) as auth_date_first,
		extract(epoch from (cur_date - min(created_at))/86400) as auth_date_first_delay,
		max(created_at) as auth_date_last,
		extract(epoch from (cur_date - max(created_at))/86400) as auth_date_last_delay,
		extract(epoch from (cur_date - min(created_at)) / count(created_at))/86400 as auth_interval
	FROM authorization_v3
	RIGHT JOIN time_series 
	ON authorization_v3.user_id = time_series.user_id AND authorization_v3.created_at <= time_series.cur_date
	GROUP BY 
	    time_series.user_id,
	    time_series.cur_date
);
	
	
 -- добавление открытия активностей и заданий по расписанию

create temp table schedule as (
	select 
	    time_series.user_id,
	    time_series.cur_date,
		count(schedule_online.page_id) as activity_shown,
		sum(required) as activity_required_shown,
		sum(1 - required) as activity_optional_shown,
		sum(is_attestation) as activity_attestation_shown,
		sum(exercise) as exercises_shown,
		sum(exercise * required) as exercises_required_shown,
		sum(exercise * (1 - required)) as exercises_optional_shown,
		sum(exercise * is_attestation) as exercises_attestation_shown
	from time_series
	left join schedule_online
	on schedule_online.course_id = time_series.course_id and schedule_online.date_shown <= time_series.cur_date
	group by
		time_series.user_id,
		cur_date
);
	

 -- работа с заданиями

create temp table exercises as (
	select
		online_users_schedule_exercises.user_id,
		online_users_schedule_exercises.course_id,
		online_users_schedule_exercises.page_id,
		case 
			when created_at notnull then required
		end as required,
		case 
			when created_at notnull then 1 - required
		end as optional,
		case 
			when created_at notnull then is_attestation
		end as is_attestation,
		success::INTEGER,
		required * success as success_required,
		(1 - required) * success as success_optional,
		is_attestation * success as success_attestation,
		case 
			when result notnull and result  NOT IN ('Пропуск', 'На проверке') then required * result::INTEGER
			else null
		end as required_result,
		case 
			when result notnull and result  NOT IN ('Пропуск', 'На проверке') then (1 - required) * result::INTEGER
			else null
		end as optional_result,
		case 
			when result notnull and result  NOT IN ('Пропуск', 'На проверке') then is_attestation * result::INTEGER
			else null
		end as attestation_result,
		case 
			when result notnull and result  NOT IN ('Пропуск', 'На проверке') then result::INTEGER
			else null
		end as result,
		created_at,
--		extract(epoch from (created_at - date_shown)/86400) as exercise_shown_delay,
		extract(epoch from (first_value(created_at) 
			over (partition by exercise_results_v3.user_id, exercise_results_v3.page_id
				order by created_at) - date_shown)/86400)
			as exercise_shown_delay_first,
		case
			when success = 1 then extract(epoch from (created_at - date_shown)/86400)
		end as exercise_success_shown_delay,
--		extract(epoch from (deadline - created_at)/86400) as exercise_deadline_delay,
		case
			when success = 1 then extract(epoch from (deadline - created_at)/86400)
		end as exercise_success_deadline_delay
	from online_users_schedule_exercises
	left join exercise_results_v3
	on online_users_schedule_exercises.user_id = exercise_results_v3.user_id
		and online_users_schedule_exercises.page_id = exercise_results_v3.page_id
);

create temp table exercises_groupped as (
	select  
	    time_series.user_id,
	    time_series.cur_date,
		coalesce(sum(success), 0) as success_done,
		coalesce(sum(success_required), 0) as success_required_done,
		coalesce(sum(success_optional), 0) as success_optional_done,
		coalesce(sum(success_attestation), 0) as success_attestation_done,
		min(created_at) as first_attempt,
		min(created_at) filter (where required = 1) as first_required_attempt,
		min(created_at) filter (where required = 0) as first_optional_attempt,
		min(created_at) filter (where is_attestation = 1) as first_attestation_attempt,
		count(created_at) as exercise_attempts,
		coalesce(sum(required), 0) as exercise_required_attempts,
		coalesce(sum(optional), 0) as exercise_optional_attempts,
		coalesce(sum(is_attestation), 0) as exercise_attestation_attempts,
		coalesce(avg(result), 0) as exercise_result,
		coalesce(avg(required_result), 0) as exercise_required_result,
		coalesce(avg(optional_result), 0) as exercise_optional_result,
		coalesce(avg(attestation_result), 0) as exercise_attestation_result,
		extract(epoch from (cur_date - max(created_at))/86400) as exercise_date_last_delay,
		avg(exercise_shown_delay_first) as exercise_shown_delay_first_mean,
		avg(exercise_success_shown_delay) as exercise_success_shown_delay_mean,
		avg(exercise_success_deadline_delay) as exercise_success_deadline_delay_mean
	from time_series
	left join exercises
	on exercises.user_id = time_series.user_id and exercises.course_id = time_series.course_id and created_at <= time_series.cur_date
	group by
		time_series.user_id,
		cur_date
);

 -- работа с активностями

create temp table webinars as (
	with webinars_logs as ( -- определение часов просмотра вебинаров
		SELECT 
		    user_id, 
		    page_id,
		    event_name, 
		    conn_format,
		    CASE 
		        WHEN event_name = 'Подключение' THEN 
		            CASE 
		                WHEN user_id = LEAD(user_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND page_id = LEAD(page_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND event_name != LEAD(event_name) OVER (PARTITION BY user_id ORDER BY datetime) 
		                THEN LEAD(conn_format) OVER (PARTITION BY user_id ORDER BY datetime)
		                ELSE conn_format 
		            END
		        ELSE 
		            CASE 
		                WHEN user_id = LAG(user_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND page_id = LAG(page_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND event_name != LAG(event_name) OVER (PARTITION BY user_id ORDER BY datetime) 
		                THEN NULL
		                ELSE conn_format 
		            END
		    END AS disconn_format,
		    datetime as conn_date,
		    CASE 
		        WHEN event_name = 'Подключение' THEN 
		            CASE 
		                WHEN user_id = LEAD(user_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND page_id = LEAD(page_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND event_name != LEAD(event_name) OVER (PARTITION BY user_id ORDER BY datetime) 
		                THEN LEAD(datetime) OVER (PARTITION BY user_id ORDER BY datetime)
		                ELSE datetime
		            END
		        ELSE 
		            CASE 
		                WHEN user_id = LAG(user_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND page_id = LAG(page_id) OVER (PARTITION BY user_id ORDER BY datetime) 
		                     AND event_name != LAG(event_name) OVER (PARTITION BY user_id ORDER BY datetime) 
		                THEN NULL
		                ELSE datetime 
		            END
		    END AS disconn_date
		FROM webinars_logs_v3
		ORDER BY user_id, page_id, datetime)
	select
		user_id,
		page_id,
		conn_date as created_at, 
		case 
			when conn_format = 'онлайн' or disconn_format = 'онлайн' then 'онлайн'
			else 'офлайн'
		end as conn_format,
		extract(epoch from (disconn_date - conn_date)/86400) as web_view_hours
	from webinars_logs
	where disconn_date notnull
	union --all -- объединение с просмотром активностей
	select activity_history_viewed_v3.user_id, 
		activity_history_viewed_v3.page_id, 
		activity_history_viewed_v3.created_at,
		null as conn_format,
		null as web_view_hours
	from activity_history_viewed_v3
	where user_id in (select user_id from online_users)
	order by user_id, page_id, created_at
);


create temp table activities as (
	select
		online_users_schedule.user_id,
		online_users_schedule.course_id,
		online_users_schedule.page_id,
		case 
			when created_at notnull then required
		end as view_required,
		case 
			when created_at notnull then 1 - required
		end as view_optional,
		case 
			when created_at notnull then is_attestation
		end as view_attestation,
		case 
			when created_at notnull and (online_users_schedule.page_id != lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)
				or (lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)) is null) then 1
		end as viewed,
		case 
			when created_at notnull and (online_users_schedule.page_id != lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)
				or (lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)) is null)
			then required
		end as viewed_required,
		case 
			when created_at notnull and (online_users_schedule.page_id != lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)
				or (lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)) is null)
			then 1 - required
		end as viewed_optional,
		case 
			when created_at notnull and (online_users_schedule.page_id != lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)
				or (lag(online_users_schedule.page_id)
				over (partition by online_users_schedule.user_id order by online_users_schedule.page_id, created_at)) is null)
			then is_attestation
		end as viewed_attestation,
		created_at,
		extract(epoch from (first_value(created_at) 
			over (partition by webinars.user_id, webinars.page_id
				order by created_at) - date_shown)/86400)
			as view_shown_delay_first
	from online_users_schedule
	left join webinars
	on online_users_schedule.user_id = webinars.user_id
		and online_users_schedule.page_id = webinars.page_id
);

create temp table activities_groupped as (
	select  
	    time_series.user_id,
	    time_series.cur_date,
		coalesce(count(created_at), 0) as total_views,
		coalesce(sum(view_required), 0) as required_views,
		coalesce(sum(view_optional), 0) as optional_views,
		coalesce(sum(view_attestation), 0) as attestation_views,
		coalesce(sum(viewed), 0) as viewed,
		coalesce(sum(viewed_required), 0) as viewed_required,
		coalesce(sum(viewed_optional), 0) as viewed_optional,
		coalesce(sum(viewed_attestation), 0) as viewed_attestation,
		min(created_at) as first_view,
		min(created_at) filter (where view_required = 1) as first_required_view,
		min(created_at) filter (where view_required = 0) as first_optional_view,
		min(created_at) filter (where view_attestation = 1) as first_attestation_view,
		max(created_at) as view_last,
		avg(view_shown_delay_first) as view_shown_delay_first_mean,
		extract(epoch from (cur_date - max(created_at))/86400) as view_last_delay,
		extract(epoch from (max(created_at) - min(created_at))/86400) as view_interval
	from time_series
	left join activities
	on activities.user_id = time_series.user_id and activities.course_id = time_series.course_id and created_at <= time_series.cur_date
	group by
		time_series.user_id,
		cur_date
);


-- соединение всех таблиц

--insert into ds_gavrilova ( -- заполнение датасета (раскомментировать в случае дообучения модели)
--	user_id, 
--	cur_date,
--	time_zone,
--	age,
--	tg_bot,
--	payment,
--	course_id,
--	day_from_start, 
--	day_to_finish,
--	auth_date_last_delay,
--	auth_interval,
--	exercise_rate,
--	exercise_required_rate,
--	exercise_optional_rate, 
--	exercise_attestation_rate,
--	exercise_attempts_mean,
--	exercise_required_attempts_mean,
--	exercise_optional_attempts_mean,
--	exercise_attestation_attempts,
--	exercise_attempts_interval_mean,
--	exercise_required_attempts_interval_mean,
--	exercise_optional_attempts_interval_mean,
--	exercise_attestation_attempts_interval_mean,
--	exercise_result,
--	exercise_required_result,
--	exercise_optional_result,
--	exercise_attestation_result,
--	exercise_date_last_delay,
--	exercise_shown_delay_first_mean,
--	exercise_success_shown_delay_mean,
--	exercise_success_deadline_delay_mean,
--	progress,
--	view_rate,
--	view_required_rate,
--	view_optional_rate,
--	view_attestation_rate,
--	activity_views_mean,
--	activity_required_views_mean,
--	activity_optional_views_mean,
--	activity_attestation_views_mean,
--	activity_view_date_last_delay,
--	activity_views_interval,
--	activity_view_shown_delay_first_mean,
--	target)
	select
		time_series.user_id, -- id юзера
		time_series.cur_date, -- дата исследования
		NULLIF(replace(online_users.time_zone, ':00', ''), '')::INTEGER as time_zone, -- временная зона юзера
		online_users.age, -- возраст юзера
		case
			when online_users.tg_bot = 'остановлен' then 2
			when online_users.tg_bot = 'подключен' then 1
			else 0
		end as tg_bot, -- подключен ли тг бот
		online_users.payment, -- оплачен ли курс
		time_series.course_id, -- номер курса
	    extract(epoch from (time_series.cur_date - time_series.start_date))/86400 as day_from_start, -- день обучения
	    ceil(extract(epoch from (time_series.finish_date - time_series.cur_date))/86400) as day_to_finish, -- день до окончания курса
	    -- authorization
	--	auth.sum_auth,
	--	coalesce(auth_date_first_delay, first_value(auth_date_first_delay) -- не используется
	--		over (partition by auth.cur_date order by auth.auth_date_first)) as auth_date_first_delay, -- не используется
		coalesce(auth_date_last_delay, first_value(auth_date_first_delay)
			over (partition by auth.cur_date order by auth.auth_date_first)) as auth_date_last_delay, -- оклонение даты последней авторизации от даты cur_date
		coalesce(extract(epoch from (time_series.cur_date - auth_date_first) / sum_auth)/86400, first_value(auth_date_first_delay)
			over (partition by auth.cur_date order by auth.auth_date_first)) as auth_interval, -- средний интервал между авторизациями
		-- exercises
		case 
			when exercises_shown != 0 then success_done::numeric / exercises_shown::numeric * 100
			when exercises_shown = 0 and success_done = 0 then 0
			else 100
		end as exercise_rate, -- % успешно сданных заданий на дату cur_date
		case 
			when exercises_required_shown != 0 then success_required_done::numeric / exercises_required_shown::numeric * 100
			when exercises_required_shown = 0 and success_required_done = 0 then 0
			else 100
		end as exercise_required_rate, -- % успешно сданных обязательных заданий на дату cur_date
		case 
			when exercises_optional_shown != 0 then success_optional_done::numeric / exercises_optional_shown::numeric * 100
			when exercises_optional_shown = 0 and success_optional_done = 0 then 0
			else 100
		end as exercise_optional_rate, -- % успешно сданных необязательных заданий на дату cur_date
		case 
			when exercises_attestation_shown != 0 then success_attestation_done::numeric / exercises_attestation_shown::numeric * 100
			when exercises_attestation_shown = 0 and success_attestation_done = 0 then 0
			else 100
		end as exercise_attestation_rate, -- % успешно сданных аттестационных заданий на дату cur_date
		exercise_attempts::numeric / exercises_shown::numeric as exercise_attempts_mean, -- среднее кол-во попыток сдачи заданий на дату cur_date
		case 
			when exercises_required_shown != 0 then exercise_required_attempts::numeric / exercises_required_shown::numeric
			else exercise_required_attempts
		end as exercise_required_attempts_mean, -- среднее кол-во попыток сдачи обязательных заданий на дату cur_date
		case 
			when exercises_optional_shown != 0 then exercise_optional_attempts::numeric / exercises_optional_shown::numeric
			else exercise_optional_attempts
		end as exercise_optional_attempts_mean, -- среднее кол-во попыток сдачи необязательных заданий на дату cur_date
		case 
			when exercises_attestation_shown != 0 then exercise_attestation_attempts::numeric / exercises_attestation_shown::numeric
			else exercise_attestation_attempts
		end as exercise_attestation_attempts, -- среднее кол-во попыток сдачи аттестационных заданий на дату cur_date
		case
			when exercise_attempts != 0 then extract(epoch from (time_series.cur_date - first_attempt)) / 86400 / exercise_attempts::numeric
			else extract(epoch from (time_series.cur_date - time_series.start_date))/86400
		end as exercise_attempts_interval_mean, -- средний интервал между попытками сдачи заданий
		case
			when exercise_required_attempts != 0 then extract(epoch from (time_series.cur_date - first_required_attempt)) / 86400 / exercise_required_attempts::numeric
			else extract(epoch from (time_series.cur_date - time_series.start_date))/86400
		end as exercise_required_attempts_interval_mean, -- средний интервал между попытками сдачи обязательных заданий
		case
			when exercise_optional_attempts != 0 then extract(epoch from (time_series.cur_date - first_optional_attempt)) / 86400 / exercise_optional_attempts::numeric
			else extract(epoch from (time_series.cur_date - time_series.start_date))/86400
		end as exercise_optional_attempts_interval_mean, -- средний интервал между попытками сдачи необязательных заданий
		case
			when exercise_attestation_attempts != 0 then extract(epoch from (time_series.cur_date - first_attestation_attempt)) / 86400 / exercise_attestation_attempts::numeric
			else extract(epoch from (time_series.cur_date - time_series.start_date))/86400
		end as exercise_attestation_attempts_interval_mean, -- средний интервал между попытками сдачи аттестационных заданий
		exercise_result, -- средний результат по заданиям на дату cur_date
		exercise_required_result, -- средний результат по обязательным заданиям на дату cur_date
		exercise_optional_result, -- средний результат по необязательным заданиям на дату cur_date
		exercise_attestation_result, -- средний результат по аттестационным заданиям на дату cur_date
		coalesce(exercises_groupped.exercise_date_last_delay,
			extract(epoch from (time_series.cur_date - time_series.start_date))/86400)
			as exercise_date_last_delay, -- отклонение даты последней сдачи задания от cur_date
		coalesce(exercises_groupped.exercise_shown_delay_first_mean,
			extract(epoch from (time_series.cur_date - time_series.start_date))/86400)
			as exercise_shown_delay_first_mean, -- среднее отклонение даты ПЕРВОЙ сдачи заданий от их открытия в днях
		coalesce(exercises_groupped.exercise_success_shown_delay_mean,
			extract(epoch from (time_series.cur_date - time_series.start_date))/86400)
			as exercise_success_shown_delay_mean, -- среднее отклонение даты успешной сдачи заданий от их открытия в днях
		coalesce(exercises_groupped.exercise_success_deadline_delay_mean,
			extract(epoch from (time_series.cur_date - time_series.deadline_first))/86400)
			as exercise_success_deadline_delay_mean, -- средняя задержка успешной сдачи заданий от их дедлайна в днях
		(success_required_done::numeric + success_optional_done::numeric) / (exercises_required_shown::numeric + success_optional_done::numeric) * 100
			as progress, -- прогресс выполнения заданий на дату cur_date
		-- activities
		viewed::numeric / activity_shown::numeric * 100 as view_rate, -- % просмотренных занятий на дату cur_date
		case 
			when activity_required_shown != 0 then viewed_required::numeric / activity_required_shown::numeric * 100
			else 0
		end as view_required_rate, -- % просмотренных обязательных занятий на дату cur_date
		case 
			when activity_optional_shown != 0 then viewed_optional::numeric / activity_optional_shown::numeric * 100
			else 0
		end as view_optional_rate, -- % просмотренных необязательных занятий на дату cur_date
		case 
			when activity_attestation_shown != 0 then viewed_attestation::numeric / activity_attestation_shown::numeric * 100
			else 0
		end as view_attestation_rate, -- % просмотренных аттестационных занятий на дату cur_date
		total_views::numeric / activity_shown::numeric as activity_views_mean, -- среднее кол-во просмотров одного занятия на дату cur_date
		case 
			when activity_required_shown != 0 then required_views::numeric / activity_required_shown::numeric
			else required_views
		end as activity_required_views_mean, -- среднее кол-во просмотров одного обязательного занятия на дату cur_date
		case 
			when activity_optional_shown != 0 then optional_views::numeric / activity_optional_shown::numeric
			else optional_views
		end as activity_optional_views_mean, -- среднее кол-во просмотров одного необязательного занятия на дату cur_date
		case 
			when activity_attestation_shown != 0 then attestation_views::numeric / activity_attestation_shown::numeric
			else attestation_views
		end as activity_attestation_views_mean, -- среднее кол-во просмотров одного аттестационного занятия на дату cur_date
		coalesce(view_last_delay, extract(epoch from (time_series.cur_date - start_date)) / 86400)
			as activity_view_date_last_delay, -- отклонение даты последнего просмотра занятия от cur_date
		coalesce(view_interval, extract(epoch from (time_series.cur_date - start_date)) / 86400)
			as activity_views_interval, -- средний интервал между просмотрами занятия
		coalesce(view_shown_delay_first_mean, extract(epoch from (time_series.cur_date - start_date)) / 86400)
			as activity_view_shown_delay_first_mean, -- среднее отклонение даты ПЕРВОГО просмотра занятия от его открытия в днях
		case 
			when course_progress::INTEGER >= 50
				and (course_attestation != 'Не сдана' and course_attestation::INTEGER >= min_attestation_rate) then 1
			else 0
		end as target
	from time_series
	left join auth
	on time_series.user_id = auth.user_id and time_series.cur_date = auth.cur_date
	left join schedule
	on time_series.user_id = schedule.user_id and time_series.cur_date = schedule.cur_date
	left join exercises_groupped
	on time_series.user_id = exercises_groupped.user_id and time_series.cur_date = exercises_groupped.cur_date
	left join activities_groupped
	on time_series.user_id = activities_groupped.user_id and time_series.cur_date = activities_groupped.cur_date
	left join online_users
	on time_series.user_id = online_users.user_id
	order by time_series.user_id, time_series.cur_date;

