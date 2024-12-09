-- public.dataset_v исходный текст

CREATE OR REPLACE VIEW public.dataset_v
AS WITH t1 AS (
         SELECT students_v2.user_id,
            count(students_v2.course_id) AS count
           FROM students_v2
          GROUP BY students_v2.user_id
         HAVING count(students_v2.course_id) > 1
        ), filtered_users AS (
         SELECT students_v2.user_id,
            students_v2.course_id
           FROM students_v2
          WHERE (students_v2.user_id IN ( SELECT activity_history_viewed_v2.user_id
                   FROM activity_history_viewed_v2)) AND (students_v2.user_id IN ( SELECT authorization_v2.user_id
                   FROM authorization_v2)) AND (students_v2.user_id IN ( SELECT exercise_results_v2.user_id
                   FROM exercise_results_v2)) AND (students_v2.user_id IN ( SELECT webinars_logs_v2.user_id
                   FROM webinars_logs_v2)) AND NOT (students_v2.user_id IN ( SELECT t1.user_id
                   FROM t1))
        ), cross_schedule AS (
         SELECT filtered_users.user_id,
            sv.course_id,
            sv.type,
            sv.activity_type,
            sv.task_id,
            sv.activivty_id,
            sv.date_shown
           FROM schedule_v2 sv
             FULL JOIN filtered_users ON filtered_users.course_id = sv.course_id
        ), cross_history AS (
         SELECT cross_schedule.user_id,
            cross_schedule.course_id,
            cross_schedule.type,
            cross_schedule.activity_type,
            cross_schedule.task_id,
            cross_schedule.activivty_id,
            cross_schedule.date_shown,
            ahvv.created_at,
            ahvv.module,
            ahvv.attestation
           FROM cross_schedule
             LEFT JOIN activity_history_viewed_v2 ahvv ON ahvv.user_id = cross_schedule.user_id AND ahvv.page_id = cross_schedule.task_id
          WHERE cross_schedule.type::text = 'занятие'::text
        UNION
         SELECT cross_schedule.user_id,
            cross_schedule.course_id,
            cross_schedule.type,
            cross_schedule.activity_type,
            cross_schedule.task_id,
            cross_schedule.activivty_id,
            cross_schedule.date_shown,
            ahvv.created_at,
            ahvv.module,
            ahvv.attestation
           FROM cross_schedule
             LEFT JOIN activity_history_viewed_v2 ahvv ON ahvv.user_id = cross_schedule.user_id AND ahvv.page_id = cross_schedule.activivty_id
          WHERE cross_schedule.type::text = 'активность'::text
        ), events AS (
         SELECT ulv.user_id,
            ulv.created_at AS "time",
            ulv.event,
            ''::text AS type,
            ''::text AS activity_type,
            0 AS task_id,
            0 AS activity_id,
            0 AS result,
            0 AS success,
            0 AS m2_progress,
            0 AS m2_attestation
           FROM users_logs_v2 ulv
          WHERE (ulv.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        UNION
         SELECT students_v2.user_id,
            students_v2.m2_attestation_date AS "time",
            'attestation'::character varying AS event,
            ''::text AS type,
            ''::text AS activity_type,
            0 AS task_id,
            0 AS activity_id,
            0 AS result,
            0 AS success,
                CASE
                    WHEN students_v2.m2_progress::text = 'Нет данных'::text THEN '-1'::integer
                    ELSE students_v2.m2_progress::integer
                END AS m2_progress,
                CASE
                    WHEN students_v2.m2_attestation::text = 'Не сдана'::text THEN '-1'::integer
                    ELSE students_v2.m2_attestation::integer
                END AS m2_attestation
           FROM students_v2
          WHERE (students_v2.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        UNION
         SELECT activity_history_viewed_v2.user_id,
            activity_history_viewed_v2.created_at AS "time",
            'history'::character varying AS event,
            activity_history_viewed_v2.page_type AS type,
            activity_history_viewed_v2.activity_type,
            0 AS task_id,
            NULL::integer AS activity_id,
            0 AS result,
            0 AS success,
            0 AS m2_progress,
            0 AS m2_attestation
           FROM activity_history_viewed_v2
          WHERE activity_history_viewed_v2.page_type::text = 'занятие'::text AND (activity_history_viewed_v2.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        UNION
         SELECT ahvv.user_id,
            ahvv.created_at AS "time",
            'history'::character varying AS event,
            ahvv.page_type AS type,
            ahvv.activity_type,
            sv.task_id,
            ahvv.page_id AS activity_id,
            0 AS result,
            0 AS success,
            0 AS m2_progress,
            0 AS m2_attestation
           FROM activity_history_viewed_v2 ahvv
             LEFT JOIN schedule_v2 sv ON ahvv.page_id = sv.activivty_id
          WHERE ahvv.page_type::text = 'активность'::text AND (ahvv.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        UNION
         SELECT erv.user_id,
            erv.created_at AS "time",
            'results'::character varying AS event,
            ''::text AS type,
            ''::text AS activity_type,
            0 AS task_id,
            erv.activity_id,
                CASE
                    WHEN erv.result::text = 'Пропуск'::text THEN '-1'::integer
                    ELSE erv.result::integer
                END AS result,
            erv.success,
            0 AS m2_progress,
            0 AS m2_attestation
           FROM exercise_results_v2 erv
          WHERE (erv.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        UNION
         SELECT webinars_logs_v2.user_id,
            webinars_logs_v2.datetime AS "time",
            webinars_logs_v2.event_name AS event,
            'Вебинар'::text AS type,
            ''::text AS activity_type,
            0 AS task_id,
            webinars_logs_v2.webinar_id AS activity_id,
            0 AS result,
            0 AS success,
            0 AS m2_progress,
            0 AS m2_attestation
           FROM webinars_logs_v2
          WHERE (webinars_logs_v2.user_id IN ( SELECT filtered_users.user_id
                   FROM filtered_users))
        ), success_users AS (
         SELECT events.user_id
           FROM events
          WHERE events.m2_attestation >= 50
        ), events_with_personal_info AS (
         SELECT ev.user_id,
            users.course_id,
            ev."time",
            ev.event,
            ev.type,
            ev.activity_type,
            ev.task_id,
            ev.activity_id,
            ev.result,
            ev.success,
            ev.m2_progress,
            ev.m2_attestation,
            uat.time_zone,
            uat.age
           FROM events ev
             LEFT JOIN users_v2 users ON ev.user_id = users.user_id
             LEFT JOIN users_age_timezone_v2 uat ON ev.user_id = uat.user_id
          ORDER BY ev.user_id, ev."time"
        )
SELECT events_with_personal_info.user_id,
       events_with_personal_info.course_id,
       events_with_personal_info."time",
       events_with_personal_info.event,
       events_with_personal_info.type,
       events_with_personal_info.activity_type,
       events_with_personal_info.task_id,
       events_with_personal_info.activity_id,
       events_with_personal_info.result,
       events_with_personal_info.success,
       events_with_personal_info.m2_progress,
       events_with_personal_info.m2_attestation,
       events_with_personal_info.time_zone,
       events_with_personal_info.age
FROM events_with_personal_info;