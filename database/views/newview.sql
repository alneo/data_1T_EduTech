-- public.newview исходный текст

CREATE OR REPLACE VIEW public.newview
AS WITH weekly_counts AS (
         SELECT dataset_h_v3.user_id,
            date_trunc('week'::text, dataset_h_v3.date_shown) AS week_start,
            count(DISTINCT dataset_h_v3.activivty_id) AS weekly_activity_count,
            count(DISTINCT dataset_h_v3.task_id) AS weekly_task_count
           FROM dataset_h_v3
          GROUP BY dataset_h_v3.user_id, (date_trunc('week'::text, dataset_h_v3.date_shown))
        ), weekly_completed_counts AS (
         SELECT dataset_h_v3.user_id,
            date_trunc('week'::text, dataset_h_v3.created_at) AS week_start,
            count(DISTINCT dataset_h_v3.activivty_id) AS weekly_completed_activity_count,
            count(DISTINCT dataset_h_v3.task_id) AS weekly_completed_task_count
           FROM dataset_h_v3
          WHERE dataset_h_v3.created_at IS NOT NULL
          GROUP BY dataset_h_v3.user_id, (date_trunc('week'::text, dataset_h_v3.created_at))
        ), delay_calculations AS (
         SELECT dataset_h_v3.user_id,
            dataset_h_v3.activivty_id,
            sum(date_part('day'::text, dataset_h_v3.created_at - dataset_h_v3.date_shown)) AS total_completion_delay_days
           FROM dataset_h_v3
          WHERE dataset_h_v3.created_at IS NOT NULL AND dataset_h_v3.date_shown IS NOT NULL AND dataset_h_v3.is_attestation = 1
          GROUP BY dataset_h_v3.user_id, dataset_h_v3.activivty_id
        ), unviewed_delay AS (
         SELECT dataset_h_v3.user_id,
            sum(date_part('day'::text, now() - dataset_h_v3.date_shown::timestamp with time zone)) AS total_unviewed_delay
           FROM dataset_h_v3
          WHERE dataset_h_v3.created_at IS NULL AND dataset_h_v3.date_shown IS NOT NULL AND dataset_h_v3.is_attestation = 1
          GROUP BY dataset_h_v3.user_id
        ), last_submission AS (
         SELECT dataset_h_v3.user_id,
            max(dataset_h_v3.created_at) AS last_submission_time
           FROM dataset_h_v3
          GROUP BY dataset_h_v3.user_id
        ), average_score AS (
         SELECT dataset_h_v3.user_id,
            avg(
                CASE
                    WHEN dataset_h_v3.result IS NOT NULL AND dataset_h_v3.is_attestation = 1 THEN dataset_h_v3.result::double precision
                    ELSE NULL::double precision
                END) AS average_score
           FROM dataset_h_v3
          WHERE dataset_h_v3.result IS NOT NULL
          GROUP BY dataset_h_v3.user_id
        )
SELECT d.user_id,
       d.course_id,
       d.type,
       d.activity_type,
       d.task_id,
       d.activivty_id,
       d.date_shown,
       d.is_attestation,
       d.created_at,
       d.module,
       d.attestation,
       d.result_time,
       d.result,
       d.success,
       d.obyaz_priznak,
       d.tg_bot,
       d.m2_progress,
       d.m2_attestation_date,
       d.m2_attestation,
       d.age,
       d.time_zone,
       wc.week_start,
       wc.weekly_activity_count,
       wc.weekly_task_count,
       wcc.weekly_completed_activity_count,
       wcc.weekly_completed_task_count,
       dc.total_completion_delay_days,
       uvd.total_unviewed_delay,
       ls.last_submission_time,
       avg_score.average_score
FROM dataset_h_v3 d
         LEFT JOIN weekly_counts wc ON d.user_id = wc.user_id AND date_trunc('week'::text, d.date_shown) = wc.week_start
         LEFT JOIN weekly_completed_counts wcc ON d.user_id = wcc.user_id AND date_trunc('week'::text, d.date_shown) = wcc.week_start
         LEFT JOIN delay_calculations dc ON d.user_id = dc.user_id AND d.activivty_id = dc.activivty_id
         LEFT JOIN unviewed_delay uvd ON d.user_id = uvd.user_id
         LEFT JOIN last_submission ls ON d.user_id = ls.user_id
         LEFT JOIN average_score avg_score ON d.user_id = avg_score.user_id
ORDER BY d.user_id, d.date_shown;