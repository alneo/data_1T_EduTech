WITH success_acts AS (
         SELECT erv.user_id,
            erv.activity_id,
            min(erv.created_at) AS first_success
           FROM exercise_results_v2 erv
          WHERE erv.success = 1 AND erv.activity_id IS NOT NULL
          GROUP BY erv.user_id, erv.activity_id
        ), first_views AS (
         SELECT activity_history_viewed_v2.user_id,
            activity_history_viewed_v2.page_id AS activity_id,
            activity_history_viewed_v2.attestation,
            min(activity_history_viewed_v2.created_at) AS first_view
           FROM activity_history_viewed_v2
          WHERE activity_history_viewed_v2.page_type::text = 'активность'::text
          GROUP BY activity_history_viewed_v2.user_id, activity_history_viewed_v2.page_id, activity_history_viewed_v2.attestation
        ), schedule_plus AS (
         SELECT sc.course_id,
            agv.activity_id,
            sc.date_shown,
            agv.obyaz_priznak,
            agv.att_priznak
           FROM schedule_v2 sc
             JOIN activities_guide_v2 agv ON sc.activivty_id = agv.activity_id
          WHERE sc.type::text = 'активность'::text
        ), all_acts AS (
         SELECT uv.user_id,
            uv.course_id,
            sch.activity_id,
            sch.date_shown,
            sch.obyaz_priznak,
            sch.att_priznak
           FROM users_v2 uv
             FULL JOIN schedule_plus sch ON uv.course_id = sch.course_id
        ), all_activities AS (
         SELECT aa.user_id,
            aa.course_id,
            aa.activity_id,
            aa.date_shown,
            aa.obyaz_priznak,
            aa.att_priznak,
            sa.first_success,
            fa.first_view
           FROM all_acts aa
             LEFT JOIN success_acts sa ON aa.user_id = sa.user_id AND aa.activity_id = sa.activity_id
             LEFT JOIN first_views fa ON aa.user_id = fa.user_id AND aa.activity_id = fa.activity_id
        ), days_table AS (
         SELECT date_trunc('day'::text, dd.dd)::date AS k_day
           FROM generate_series('2023-12-01 00:00:00'::timestamp without time zone, '2024-06-30 00:00:00'::timestamp without time zone, '1 day'::interval) dd(dd)
        ), metrics_1 AS (
         SELECT days_table.k_day,
            t1.date_shown,
            t1.user_id,
            t1.course_id,
            t1.activity_id,
            t1.obyaz_priznak,
                CASE
                    WHEN days_table.k_day > t1.date_shown AND t1.obyaz_priznak = 1 AND (days_table.k_day < t1.first_success OR t1.first_success IS NULL) THEN days_table.k_day - date_trunc('day'::text, t1.date_shown)::date
                    ELSE 0
                END AS required_activities_delay,
                CASE
                    WHEN days_table.k_day >= t1.first_success AND t1.obyaz_priznak = 1 THEN 1
                    ELSE 0
                END AS success_required_done,
                CASE
                    WHEN days_table.k_day >= t1.first_success AND t1.obyaz_priznak = 0 THEN 1
                    ELSE 0
                END AS success_optional_done,
                CASE
                    WHEN t1.obyaz_priznak = 1 AND days_table.k_day = er.created_at::date THEN
                    CASE
                        WHEN er.result::text ~ '^\d+$'::text THEN er.result::integer
                        ELSE '-1'::integer
                    END
                    ELSE '-1'::integer
                END AS result_required_exercise,
            days_table.k_day - '2023-12-01'::date AS start_day_lag
           FROM ( SELECT all_activities.user_id,
                    all_activities.course_id,
                    all_activities.activity_id,
                    all_activities.date_shown,
                    all_activities.obyaz_priznak,
                    all_activities.att_priznak,
                    all_activities.first_success,
                    all_activities.first_view
                   FROM all_activities
                  WHERE all_activities.att_priznak = 0) t1
             LEFT JOIN exercise_results_v2 er ON t1.user_id = er.user_id AND t1.activity_id = er.activity_id
             CROSS JOIN days_table
        ), metrics_2 AS (
         SELECT metrics_1.k_day,
            metrics_1.user_id,
            metrics_1.course_id,
            sum(metrics_1.required_activities_delay) AS required_activities_delay,
            sum(metrics_1.success_required_done) AS success_required_done,
            sum(metrics_1.success_optional_done) AS success_optional_done,
            avg(metrics_1.result_required_exercise) FILTER (WHERE metrics_1.result_required_exercise >= 0) AS mean_result_required,
            sum(metrics_1.obyaz_priznak) FILTER (WHERE metrics_1.k_day >= metrics_1.date_shown) AS cur_date_required_number,
            sum(metrics_1.obyaz_priznak) AS required_number,
            avg(metrics_1.start_day_lag) AS start_day_lag
           FROM metrics_1
          GROUP BY metrics_1.user_id, metrics_1.k_day, metrics_1.course_id
          ORDER BY metrics_1.k_day
        ), dt AS (
         SELECT m2.k_day,
            m2.user_id,
            m2.course_id,
            m2.required_activities_delay,
            m2.success_required_done,
            m2.success_optional_done,
            COALESCE(avg(m2.mean_result_required) OVER (PARTITION BY m2.user_id ORDER BY m2.k_day)::integer, 0) AS mean_result_required,
                CASE
                    WHEN m2.start_day_lag > 0::numeric THEN 1.0 * (m2.success_required_done + m2.success_optional_done)::numeric / m2.start_day_lag
                    ELSE 0::numeric
                END AS cur_date_speed,
            COALESCE((100::numeric * (1.0 * m2.success_required_done::numeric / m2.cur_date_required_number::numeric))::integer, 0) AS cur_date_progress,
            100 * (m2.success_required_done + m2.success_optional_done) / (m2.required_number + m2.success_optional_done) AS current_progress,
                CASE
                    WHEN users.m2_progress::text ~ '^\d+$'::text THEN users.m2_progress::integer
                    ELSE 0
                END AS m2_progress,
                CASE
                    WHEN users.m2_attestation::text ~ '^\d+$'::text THEN users.m2_attestation::integer
                    ELSE 0
                END AS m2_attestation
           FROM metrics_2 m2
             LEFT JOIN users_v2 users ON m2.user_id = users.user_id AND m2.course_id = users.course_id
        ), dt_final AS (
         SELECT dt.k_day,
            dt.user_id,
            dt.course_id,
            dt.required_activities_delay,
            dt.success_required_done,
            dt.success_optional_done,
            dt.mean_result_required,
            round(dt.cur_date_speed, 2) AS cur_date_speed,
            round(avg(dt.cur_date_speed) OVER (PARTITION BY dt.user_id ORDER BY dt.k_day), 2) AS avg_speed,
            dt.cur_date_progress,
            dt.current_progress,
                CASE
                    WHEN dt.cur_date_progress < 30 OR dt.mean_result_required < 33 THEN 0
                    WHEN dt.cur_date_progress >= 30 AND dt.cur_date_progress <= 60 THEN 1
                    WHEN dt.cur_date_progress > 60 THEN 2
                    ELSE NULL::integer
                END AS status,
            dt.m2_progress,
                CASE
                    WHEN dt.m2_progress > 49 AND dt.m2_attestation > 49 THEN 1
                    ELSE 0
                END AS m2_success
           FROM dt
          WHERE dt.k_day < '2024-06-30'::date AND (dt.user_id IN ( SELECT DISTINCT dt_1.user_id
                   FROM dt dt_1
                  WHERE dt_1.k_day = '2024-06-30'::date AND abs(dt_1.current_progress - dt_1.m2_progress) <= 10)) AND (dt.user_id IN ( SELECT uv.user_id
                   FROM users_v2 uv
                  WHERE (uv.user_id IN ( SELECT DISTINCT users_logs_v2.user_id
                           FROM users_logs_v2
                          WHERE users_logs_v2.comment::text ~~ 'Были хештеги:%онлайн%стали:%онлайн%'::text 
				OR users_logs_v2.comment::text ~~ 'Установлен хештег "#онлайн"'::text 
				OR users_logs_v2.comment::text ~~ 'Были хештеги: , стали:%онлайн%'::text 
				OR users_logs_v2.comment::text ~~ 'Были хештеги%оyлайн%стали:%онлайн%'::text 
				OR users_logs_v2.comment::text ~~ 'Были хештеги%оглайн%стали:%онлайн%'::text)) 
				OR NOT (uv.user_id IN ( SELECT DISTINCT users_logs_v2.user_id FROM users_logs_v2))
                  GROUP BY uv.user_id
                 HAVING count(uv.course_id) = 1))
        )
 SELECT dt_final.k_day,
    dt_final.user_id,
    dt_final.course_id,
    dt_final.required_activities_delay,
    dt_final.success_required_done,
    dt_final.success_optional_done,
    dt_final.mean_result_required,
    dt_final.cur_date_speed,
    dt_final.avg_speed,
    dt_final.cur_date_progress,
    dt_final.current_progress,
    dt_final.status,
    dt_final.m2_progress,
    dt_final.m2_success
   FROM dt_final;