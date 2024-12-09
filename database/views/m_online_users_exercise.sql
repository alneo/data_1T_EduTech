-- public.m_online_users_exercise исходный текст

CREATE OR REPLACE VIEW public.m_online_users_exercise
AS WITH exercise_data AS (
         SELECT mos.user_id,
            mos.course_id,
            mos.learning_format,
            sh.task_id,
            sh.activivty_id AS activity_id,
            sh.activity_type,
            sh.date_shown AS activity_datetime_shown,
            erv.created_at AS result_datetime,
                CASE
                    WHEN erv.success = 1 THEN GREATEST(erv.created_at, sh.date_shown)
                    ELSE NULL::timestamp without time zone
                END AS result_datetime_upd,
                CASE
                    WHEN erv.success = 1 THEN (erv.created_at - sh.date_shown) < '00:00:00'::interval
                    ELSE NULL::boolean
                END AS is_early_sucsess,
            erv.created_at - sh.date_shown AS datetime_diff,
            erv.result,
            erv.success,
            sh.is_attestation,
            mos.m2_progress,
            mos.m2_attestation,
            mos.m2_attestation_date,
            sh.type,
            sh.date_shown::date AS activity_date_shown,
            erv.created_at::date AS result_date,
            mos.tg_bot
           FROM schedule_v2 sh
             JOIN m_online_students mos ON mos.course_id = sh.course_id
             LEFT JOIN exercise_results_v2 erv ON mos.user_id = erv.user_id AND sh.activivty_id = erv.activity_id
        ), active_users AS (
         SELECT DISTINCT exercise_data.user_id,
            exercise_data.course_id
           FROM exercise_data
          WHERE exercise_data.result_date IS NOT NULL
        ), activity_with_results AS (
         SELECT DISTINCT exercise_data.activity_id
           FROM exercise_data
          WHERE exercise_data.result_date IS NOT NULL
        ), exercise_data_2 AS (
         SELECT row_number() OVER (ORDER BY ed.user_id, ed.course_id, ed.activity_datetime_shown, ed.activity_id, ed.result_datetime) AS rn,
            ed.user_id,
            ed.course_id,
            ed.learning_format,
            ed.task_id,
            ed.activity_id,
            ed.activity_type,
            ed.activity_datetime_shown,
            ed.result_datetime,
            ed.result_datetime_upd,
            ed.is_early_sucsess,
            ed.datetime_diff,
            ed.result,
            ed.success,
            ed.is_attestation,
            ed.m2_progress,
            ed.m2_attestation,
            ed.m2_attestation_date,
            ed.type,
            ed.activity_date_shown,
            ed.result_date,
            ed.tg_bot
           FROM exercise_data ed
          WHERE 1 = 1 AND (EXISTS ( SELECT 1
                   FROM active_users u
                  WHERE u.user_id = ed.user_id AND u.course_id = ed.course_id)) AND (EXISTS ( SELECT 1
                   FROM activity_with_results r
                  WHERE r.activity_id = ed.activity_id))
        ), exercise_data_3 AS (
         SELECT ed.rn,
            ed.user_id,
            ed.course_id,
            ed.learning_format,
            ed.task_id,
            ed.activity_id,
            ed.activity_type,
            ed.activity_datetime_shown,
            ed.result_datetime,
            ed.result_datetime_upd,
            ed.is_early_sucsess,
            ed.datetime_diff,
            ed.result,
            ed.success,
            ed.is_attestation,
            ed.m2_progress,
            ed.m2_attestation,
            ed.m2_attestation_date,
            ed.type,
            ed.activity_date_shown,
            ed.result_date,
            ed.tg_bot,
            first_value(ed.rn) OVER (PARTITION BY ed.user_id, ed.course_id, ed.activity_id ORDER BY ed.result_datetime_upd) AS rn_need,
            count(ed.user_id) OVER (PARTITION BY ed.user_id, ed.course_id, ed.activity_id) AS num_repeat
           FROM exercise_data_2 ed
        ), exercise_data_4 AS (
         SELECT exercise_data_3.rn,
            exercise_data_3.user_id,
            exercise_data_3.course_id,
            exercise_data_3.learning_format,
            exercise_data_3.task_id,
            exercise_data_3.activity_id,
            exercise_data_3.activity_type,
            exercise_data_3.activity_datetime_shown,
            exercise_data_3.result_datetime,
            exercise_data_3.result_datetime_upd,
            exercise_data_3.is_early_sucsess,
            exercise_data_3.datetime_diff,
            exercise_data_3.result,
            exercise_data_3.success,
            exercise_data_3.is_attestation,
            exercise_data_3.m2_progress,
            exercise_data_3.m2_attestation,
            exercise_data_3.m2_attestation_date,
            exercise_data_3.type,
            exercise_data_3.activity_date_shown,
            exercise_data_3.result_date,
            exercise_data_3.tg_bot,
            exercise_data_3.rn_need,
            exercise_data_3.num_repeat
           FROM exercise_data_3
          WHERE exercise_data_3.rn = exercise_data_3.rn_need
        ), grouped_exercise_1 AS (
         SELECT exercise_data_4.user_id,
            exercise_data_4.course_id,
            exercise_data_4.task_id,
            min(exercise_data_4.rn) AS rn,
            min(exercise_data_4.activity_datetime_shown) AS activity_datetime_shown,
            min(exercise_data_4.result_datetime_upd) AS result_datetime_upd,
            max(exercise_data_4.success) AS success,
            sum(exercise_data_4.success) AS num_success,
            count(exercise_data_4.user_id) AS num_activities_all,
            max(exercise_data_4.num_repeat) AS max_num_repeat,
            max(exercise_data_4.is_attestation) AS is_attestation,
            max(exercise_data_4.m2_progress::text) AS m2_progress,
            max(exercise_data_4.m2_attestation::text) AS m2_attestation,
            max(exercise_data_4.m2_attestation_date) AS m2_attestation_date
           FROM exercise_data_4
          GROUP BY exercise_data_4.user_id, exercise_data_4.course_id, exercise_data_4.task_id
        )
SELECT grouped_exercise_1.user_id,
       grouped_exercise_1.course_id,
       grouped_exercise_1.task_id,
       grouped_exercise_1.rn,
       grouped_exercise_1.activity_datetime_shown,
       grouped_exercise_1.result_datetime_upd,
       grouped_exercise_1.success,
       grouped_exercise_1.num_success,
       grouped_exercise_1.num_activities_all,
       grouped_exercise_1.max_num_repeat,
       grouped_exercise_1.is_attestation,
       grouped_exercise_1.m2_progress,
       grouped_exercise_1.m2_attestation,
       grouped_exercise_1.m2_attestation_date
FROM grouped_exercise_1;