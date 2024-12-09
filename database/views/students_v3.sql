-- public.students_v3 исходный текст

CREATE OR REPLACE VIEW public.students_v3
AS WITH t1 AS (
         SELECT uv.user_id
           FROM users_v2 uv
          WHERE (uv.user_id IN ( SELECT DISTINCT users_logs_v2.user_id
                   FROM users_logs_v2
                  WHERE users_logs_v2.comment::text ~~ 'Были хештеги:%онлайн%стали:%онлайн%'::text OR users_logs_v2.comment::text ~~ 'Установлен хештег "#онлайн"'::text OR users_logs_v2.comment::text ~~ 'Были хештеги: , стали:%онлайн%'::text OR users_logs_v2.comment::text ~~ 'Были хештеги%оyлайн%стали:%онлайн%'::text OR users_logs_v2.comment::text ~~ 'Были хештеги%оглайн%стали:%онлайн%'::text)) OR NOT (uv.user_id IN ( SELECT DISTINCT users_logs_v2.user_id
                   FROM users_logs_v2))
          GROUP BY uv.user_id
         HAVING count(uv.course_id) = 1
        )
SELECT uv2.unti_id,
       uv2.user_id,
       uv2.course_id,
       uv2.flow_num,
       uv2.tg_bot,
       uv2.m2_progress,
       uv2.m2_attestation,
       uv2.m2_attestation_date
FROM users_v2 uv2
         JOIN t1 ON uv2.user_id = t1.user_id;