-- public.dataset_h_v3 исходный текст

CREATE OR REPLACE VIEW public.dataset_h_v3
AS WITH cross_schedule AS (
         SELECT sv2.user_id,
            sv_1.course_id,
            sv_1.type,
            sv_1.activity_type,
            sv_1.task_id,
            sv_1.activivty_id,
            sv_1.date_shown,
            sv_1.is_attestation
           FROM schedule_v2 sv_1
             FULL JOIN students_v3 sv2 ON sv2.course_id = sv_1.course_id
        ), cross_history AS (
         SELECT cross_schedule.user_id,
            cross_schedule.course_id,
            cross_schedule.type,
            cross_schedule.activity_type,
            cross_schedule.task_id,
            cross_schedule.activivty_id,
            cross_schedule.date_shown,
            cross_schedule.is_attestation,
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
            cross_schedule.is_attestation,
            ahvv.created_at,
            ahvv.module,
            ahvv.attestation
           FROM cross_schedule
             LEFT JOIN activity_history_viewed_v2 ahvv ON ahvv.user_id = cross_schedule.user_id AND ahvv.page_id = cross_schedule.activivty_id
          WHERE cross_schedule.type::text = 'активность'::text
        ), history_results AS (
         SELECT cross_history.user_id,
            cross_history.course_id,
            cross_history.type,
            cross_history.activity_type,
            cross_history.task_id,
            cross_history.activivty_id,
            cross_history.date_shown,
            cross_history.is_attestation,
            cross_history.created_at,
            cross_history.module,
            cross_history.attestation,
            erv.created_at AS result_time,
                CASE
                    WHEN erv.result::text = 'Пропуск'::text THEN '-1'::integer
                    ELSE erv.result::integer
                END AS result,
            erv.success
           FROM cross_history
             LEFT JOIN exercise_results_v2 erv ON erv.user_id = cross_history.user_id AND erv.activity_id = cross_history.activivty_id
        )
SELECT history_results.user_id,
       history_results.course_id,
       history_results.type,
       history_results.activity_type,
       history_results.task_id,
       history_results.activivty_id,
       history_results.date_shown,
       history_results.is_attestation,
       history_results.created_at,
       history_results.module,
       history_results.attestation,
       history_results.result_time,
       history_results.result,
       history_results.success,
       agv.obyaz_priznak,
       sv.tg_bot,
       CASE
           WHEN sv.m2_progress::text = 'Нет данных'::text THEN '-1'::integer
            ELSE sv.m2_progress::integer
END AS m2_progress,
    sv.m2_attestation_date,
        CASE
            WHEN sv.m2_attestation::text = 'Не сдана'::text THEN '-1'::integer
            ELSE sv.m2_attestation::integer
END AS m2_attestation,
    uatv.age,
    uatv.time_zone
   FROM history_results
     LEFT JOIN students_v3 sv ON sv.user_id = history_results.user_id
     LEFT JOIN users_age_timezone_v2 uatv ON history_results.user_id = uatv.user_id
     LEFT JOIN activities_guide_v2 agv ON agv.activity_id = history_results.activivty_id
  ORDER BY history_results.user_id, history_results.date_shown;