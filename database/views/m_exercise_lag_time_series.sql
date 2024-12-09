-- public.m_exercise_lag_time_series исходный текст

CREATE OR REPLACE VIEW public.m_exercise_lag_time_series
AS WITH not_complited_tasks_for_date AS (
         SELECT mdi.day_num,
            mdi.date_column,
            u.user_id,
            u.course_id,
            COALESCE(mdi.date_column - moue.activity_datetime_shown::date, 0) AS lag,
            moue.task_id,
            moue.rn,
            moue.activity_datetime_shown,
            moue.result_datetime_upd,
            moue.success,
            moue.num_success,
            moue.num_activities_all,
            moue.max_num_repeat,
            moue.is_attestation,
            moue.m2_progress,
            moue.m2_attestation,
            moue.m2_attestation_date
           FROM m_date_interval mdi
             JOIN ( SELECT DISTINCT m_online_users_exercise.user_id,
                    m_online_users_exercise.course_id
                   FROM m_online_users_exercise) u ON 1 = 1
             LEFT JOIN m_online_users_exercise moue ON u.user_id = moue.user_id AND u.course_id = moue.course_id AND mdi.date_column > moue.activity_datetime_shown::date AND (mdi.date_column < moue.result_datetime_upd::date OR moue.result_datetime_upd IS NULL)
        ), tasks_lag_for_date AS (
         SELECT not_complited_tasks_for_date.user_id,
            not_complited_tasks_for_date.course_id,
            not_complited_tasks_for_date.day_num,
            not_complited_tasks_for_date.date_column,
            sum(not_complited_tasks_for_date.lag) AS sum_lag,
            max(not_complited_tasks_for_date.m2_progress) AS m2_progress,
            max(not_complited_tasks_for_date.m2_attestation) AS m2_attestation,
            max(not_complited_tasks_for_date.m2_attestation_date) AS m2_attestation_date
           FROM not_complited_tasks_for_date
          GROUP BY not_complited_tasks_for_date.user_id, not_complited_tasks_for_date.course_id, not_complited_tasks_for_date.day_num, not_complited_tasks_for_date.date_column
        )
SELECT tasks_lag_for_date.user_id,
       tasks_lag_for_date.course_id,
       tasks_lag_for_date.day_num,
       tasks_lag_for_date.date_column,
       tasks_lag_for_date.sum_lag,
       tasks_lag_for_date.m2_progress,
       tasks_lag_for_date.m2_attestation,
       tasks_lag_for_date.m2_attestation_date
FROM tasks_lag_for_date
ORDER BY tasks_lag_for_date.user_id, tasks_lag_for_date.date_column;