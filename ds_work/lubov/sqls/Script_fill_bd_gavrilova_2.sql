-- очистка таблиц

truncate table webinars_logs_v3 cascade;
truncate table attestation_v3 cascade;
truncate table exercise_results_v3 cascade;
truncate table activity_history_viewed_v3 cascade;
truncate table schedule_v3 cascade;
truncate table authorization_v3 cascade;
truncate table pages_v3 cascade;
truncate table tasks_v3 cascade;
truncate table activities_v3 cascade;
truncate table themes_v3 cascade;
truncate table flows_v3 cascade;
truncate table courses_v3 cascade;
truncate table users_logs_v3 cascade;
truncate table users_v3 cascade;


-- заполнение users_v3

insert into users_v3 (user_id, unti_id, time_zone, age, tg_bot)
select distinct user_id, unti_id, "timeZone", age, tg_bot
from users_v4;


-- заполнение authorization_v3

insert into authorization_v3 (user_id, created_at, user_agent, window_size)
SELECT *
FROM authorization_v4
where user_id in (
	select user_id
	from users_v3);

-- заполнение courses_v3

insert into courses_v3 (course_id, course_name, provider, min_attestation_rate)
SELECT DISTINCT course_id, course, provider, 
	case
		when course_id = 76 then 10
		else 60
	end AS min_attestation_rate
FROM activities_guide_v4;

-- заполнение flows_v3 

insert into flows_v3 (flow_num)
SELECT DISTINCT flow_num
FROM users_v4;

-- заполнение themes_v3 ---

insert into themes_v3 (theme_id, theme_name, course_id)
SELECT DISTINCT theme_id, theme, course_id
FROM activities_guide_v4;

-- заполнение tasks_v3 

insert into tasks_v3 (task_id, task_name, theme_id, is_attestation)
SELECT DISTINCT task_id, exercise, theme_id, att_priznak
FROM activities_guide_v4;

-- заполнение activities_v3 ---

insert into activities_v3 (activity_id, activity_type, activity_name, task_id, obyaz_priznak, webinar_vvod)
SELECT DISTINCT
	schedule_v4.activivty_id AS activity_id,
	CASE
		WHEN schedule_v4.activity_type IS NULL THEN activities_guide_v4.activity_type
		ELSE schedule_v4.activity_type
	END AS activity_type,
	activities_guide_v4.activity AS activity_name,
	schedule_v4.task_id,
	CASE 
        	WHEN obyaz_priznak IS NULL THEN 0 
        	ELSE obyaz_priznak 
    	END AS obyaz_priznak,
	CASE
		WHEN activity = 'Вводный вебинар' THEN 1
		ELSE 0
	END AS webinar_vvod
FROM schedule_v4
LEFT JOIN activities_guide_v4
ON schedule_v4.activivty_id = activities_guide_v4.activity_id
WHERE schedule_v4.activivty_id NOTNULL;

-- заполнение pages_v3

insert into pages_v3 (page_id, page_type, task_id, activity_id)
SELECT DISTINCT 
    	CASE 
        	WHEN activivty_id IS NULL THEN schedule_v4.task_id 
        	ELSE activivty_id 
    	END AS page_id,
	type AS page_type, schedule_v4.task_id, activivty_id AS activity_id
FROM schedule_v4
LEFT JOIN activities_guide_v4
ON schedule_v4.task_id = activities_guide_v4.task_id AND schedule_v4.activivty_id = activities_guide_v4.activity_id;

-- заполнение schedule_v3

insert into schedule_v3 (flow_num, page_id, visibility, date_shown, deadline)
SELECT DISTINCT
	flows AS flow_num,
	CASE 
        	WHEN activivty_id IS NULL THEN schedule_v4.task_id 
        	ELSE activivty_id 
    	END AS page_id,
	schedule_v4.visibility,
	CASE
		WHEN schedule_v4.task_id = 1751
			THEN '2024-09-03 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1665
			THEN '2024-07-02 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1734
			THEN '2024-07-16 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1626
			THEN '2024-07-12 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1709
			THEN '2024-08-01 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1742
			THEN '2024-08-08 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1719
			THEN '2024-08-29 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1787
			THEN '2024-08-28 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1642
			THEN '2024-08-23 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1715
			THEN '2024-08-20 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1688
			THEN '2024-08-22 00:00:00'::timestamp
		WHEN schedule_v4.task_id = 1788
			THEN '2024-08-16 00:00:00'::timestamp
		else
			case
				WHEN theme_id IN (332, 353, 371, 385)
					THEN '2024-06-01 00:00:00'::timestamp
				WHEN theme_id = 392
					THEN '2024-06-07 00:00:00'::timestamp
				WHEN theme_id = 354
					THEN '2024-06-11 00:00:00'::timestamp
				WHEN theme_id = 355
					THEN '2024-06-17 00:00:00'::timestamp
				WHEN theme_id = 333
					THEN '2024-06-21 00:00:00'::timestamp
				WHEN theme_id = 386
					THEN '2024-06-27 00:00:00'::timestamp
				WHEN theme_id = 334
					THEN '2024-07-01 00:00:00'::timestamp
				WHEN theme_id IN (372, 356)
					THEN '2024-07-04 00:00:00'::timestamp
				WHEN theme_id = 387
					THEN '2024-07-18 00:00:00'::timestamp
				WHEN theme_id = 336
					THEN '2024-07-22 00:00:00'::timestamp
				WHEN theme_id = 337
					THEN '2024-07-29 00:00:00'::timestamp
				WHEN theme_id = 376
					THEN '2024-07-30 00:00:00'::timestamp
				WHEN theme_id = 357
					THEN '2024-08-01 00:00:00'::timestamp
				WHEN theme_id = 338
					THEN '2024-08-05 00:00:00'::timestamp
				WHEN theme_id = 373
					THEN '2024-08-06 00:00:00'::timestamp
				WHEN theme_id = 388
					THEN '2024-08-13 00:00:00'::timestamp
				WHEN theme_id = 358
					THEN '2024-08-16 00:00:00'::timestamp
				WHEN theme_id = 390
					THEN '2024-08-29 00:00:00'::timestamp
				WHEN theme_id IN (389, 374)
					THEN '2024-08-22 00:00:00'::timestamp
			end
	END AS date_shown,
	case 
		when schedule_v4.task_id = 1753 then '2024-06-07'::timestamp
		when schedule_v4.task_id = 1817 then '2024-06-15'::timestamp
		else date_shown
	end	AS deadline
FROM schedule_v4
join tasks_v3
on tasks_v3.task_id = schedule_v4.task_id;

-- заполнение activity_history_viewed_v3 ---

insert into activity_history_viewed_v3 (user_id, created_at, page_id)
SELECT user_id, created_at, page_id
FROM activity_history_viewed_v4
where user_id in (
	select user_id
	from users_v3)
and page_id in (
	select page_id
	from pages_v3);

-- заполнение users_logs_v3

insert into users_logs_v3 (user_id, created_at, comment)
SELECT users_v3.user_id, created_at, comment
FROM users_logs_v4
right join users_v3
on users_logs_v4.user_id = users_v3.user_id;

-- заполнение exercise_results_v3

insert into exercise_results_v3 (user_id, page_id, created_at, result, success)
SELECT user_id, activity_id, created_at, result, success
FROM exercise_results_v4
where user_id in (
	select user_id
	from users_v3)
and activity_id in (
	select page_id
	from pages_v3);

-- заполнение attestation_v3 

insert into attestation_v3 (user_id, course_id, flow_num, course_progress, course_attestation, course_attestation_date)
SELECT user_id, course_id, flow_num, course_progress2, course_attestation, course_attestation_date
FROM users_v4;

-- заполнение webinars_logs_v3

insert into webinars_logs_v3 (user_id, datetime, event_name, page_id, conn_format)
select user_id, datetime, event_name, webinar_id, conn_format
from webinars_logs_v4
where user_id in (
	select user_id
	from users_v3)
and webinar_id in (
	select page_id
	from pages_v3);