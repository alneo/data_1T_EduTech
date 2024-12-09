-- public.m_online_students исходный текст

CREATE OR REPLACE VIEW public.m_online_students
AS WITH users AS (
         SELECT DISTINCT uv.unti_id,
            uv.user_id,
            uv.course_id,
            uv.flow_num,
            uv.tg_bot,
            uv.m2_progress,
            uv.m2_attestation,
            uv.m2_attestation_date,
            utags.tag AS learning_format
           FROM users_v2 uv
             JOIN m_course_params cp ON cp.course_id = uv.course_id
             JOIN m_user_tags_history utags ON uv.user_id = utags.user_id AND NOT (utags.to_datetime <= cp.min_date_shown OR utags.from_datetime >= cp.max_date_shown)
        ), grouped AS (
         SELECT u_1.user_id,
            sum(
                CASE
                    WHEN u_1.learning_format <> 'онлайн'::text THEN 1
                    ELSE 0
                END) AS offline_tags
           FROM users u_1
          GROUP BY u_1.user_id
        )
SELECT u.unti_id,
       u.user_id,
       u.course_id,
       u.flow_num,
       u.tg_bot,
       u.m2_progress,
       u.m2_attestation,
       u.m2_attestation_date,
       u.learning_format
FROM users u
WHERE (u.user_id IN ( SELECT grouped.user_id
                      FROM grouped
                      WHERE grouped.offline_tags = 0));