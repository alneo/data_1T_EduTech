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
select distinct users_v2.user_id, unti_id, time_zone, age, tg_bot
from users_v2
left join users_age_timezone_v2
on users_v2.user_id = users_age_timezone_v2.user_id;


-- заполнение authorization_v3

insert into authorization_v3 (user_id, created_at, user_agent, window_size)
SELECT *
FROM authorization_v2
where user_id in (
	select user_id
	from users_v3);

-- заполнение courses_v3

insert into courses_v3 (course_id, course_name, provider, min_attestation_rate)
SELECT DISTINCT course_id, course, provider, 50 AS min_attestation_rate
FROM activities_guide_v2;

-- заполнение flows_v3 

insert into flows_v3 (flow_num)
SELECT DISTINCT flow_num
FROM users_v2;

-- заполнение themes_v3 ---

insert into themes_v3 (theme_id, theme_name, course_id)
SELECT DISTINCT theme_id, theme, course_id
FROM activities_guide_v2;

-- заполнение tasks_v3 

insert into tasks_v3 (task_id, task_name, theme_id, is_attestation)
SELECT DISTINCT task_id, exercise, theme_id, att_priznak
FROM activities_guide_v2;

-- заполнение activities_v3 ---

insert into activities_v3 (activity_id, activity_type, activity_name, task_id, obyaz_priznak, webinar_vvod)
SELECT DISTINCT
	schedule_v2.activivty_id AS activity_id,
	CASE
		WHEN schedule_v2.activity_type IS NULL THEN activities_guide_v2.activity_type
		ELSE schedule_v2.activity_type
	END AS activity_type,
	activities_guide_v2.activity AS activity_name,
	schedule_v2.task_id,
	CASE 
        	WHEN obyaz_priznak IS NULL THEN 0 
        	ELSE obyaz_priznak 
    	END AS obyaz_priznak,
	CASE
		WHEN activity = 'Вводный вебинар' THEN 1
		ELSE 0
	END AS webinar_vvod
FROM schedule_v2
LEFT JOIN activities_guide_v2
ON schedule_v2.activivty_id = activities_guide_v2.activity_id
WHERE schedule_v2.activivty_id NOTNULL;

-- заполнение pages_v3

insert into pages_v3 (page_id, page_type, task_id, activity_id)
SELECT DISTINCT 
    	CASE 
        	WHEN activivty_id IS NULL THEN schedule_v2.task_id 
        	ELSE activivty_id 
    	END AS page_id,
	type AS page_type, schedule_v2.task_id, activivty_id AS activity_id
FROM schedule_v2
LEFT JOIN activities_guide_v2
ON schedule_v2.task_id = activities_guide_v2.task_id AND schedule_v2.activivty_id = activities_guide_v2.activity_id;

-- заполнение schedule_v3

insert into schedule_v3 (flow_num, page_id, visibility, date_shown, deadline)
SELECT DISTINCT
	flows AS flow_num,
	CASE 
        	WHEN activivty_id IS NULL THEN task_id 
        	ELSE activivty_id 
    	END AS page_id,
	visibility,
	CASE
		WHEN task_id IN (3015,1644,1963,2253)
			THEN '2024-01-20 00:00:00'::timestamp
		WHEN task_id IN (81,2572,82,2573,84,2574,2575,86,2576,2622,2623,2624,2625,2626,2627,2628,
				2629,2630,2631,2632,2633,2634,2635,2636,2637,2243,2244,2578,2245,2579,2246,2580,2247,2581,2582)
			THEN '2023-12-01 00:00:00'::timestamp
		WHEN task_id IN (85,678,680,681,691,2577,2587,2248,2583,2584,2249,2585,2250,2251,2252)
			THEN '2024-01-10 00:00:00'::timestamp
		WHEN task_id IN (1617,2593,1620,2595,1623,1625,2598)
			THEN '2023-11-30 00:00:00'::timestamp
		WHEN task_id IN (1628,2614,2615,1633,2616,2617,1638,2618,1641,2619)
			THEN '2023-12-24 00:00:00'::timestamp
	END AS date_shown,
	date_shown AS deadline
FROM schedule_v2;

-- заполнение activity_history_viewed_v3 ---

insert into activity_history_viewed_v3 (user_id, created_at, page_id)
SELECT user_id, created_at, page_id
FROM activity_history_viewed_v2
where user_id in (
	select user_id
	from users_v3)
and page_id in (
	select page_id
	from pages_v3);

-- заполнение users_logs_v3

insert into users_logs_v3 (user_id, created_at, comment)
SELECT users_v3.user_id, created_at, comment
FROM users_logs_v2
right join users_v3
on users_logs_v2.user_id = users_v3.user_id;

-- заполнение exercise_results_v3

insert into exercise_results_v3 (user_id, page_id, created_at, result, success)
SELECT user_id, activity_id, created_at, result, success
FROM exercise_results_v2
where user_id in (
	select user_id
	from users_v3)
and activity_id in (
	select page_id
	from pages_v3);

-- заполнение attestation_v3 

insert into attestation_v3 (user_id, course_id, flow_num, course_progress, course_attestation, course_attestation_date)
SELECT user_id, course_id, flow_num, m2_progress, m2_attestation, m2_attestation_date
FROM users_v2;

-- заполнение webinars_logs_v3

insert into webinars_logs_v3 (user_id, datetime, event_name, page_id, conn_format)
select user_id, datetime, event_name, webinar_id, conn_format
from webinars_logs_v2
where user_id in (
	select user_id
	from users_v3)
and webinar_id in (
	select page_id
	from pages_v3);

