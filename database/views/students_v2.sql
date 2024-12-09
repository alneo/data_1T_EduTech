-- public.students_v2 исходный текст

CREATE OR REPLACE VIEW public.students_v2
AS WITH t1 AS (
         SELECT DISTINCT logs.user_id,
            logs.created_at,
            logs.comment
           FROM users_logs_v2 logs
          WHERE logs.comment::text ~~ 'Были хештеги:%онлайн%стали:%онлайн%'::text OR logs.comment::text ~~ 'Установлен хештег "#онлайн"'::text OR logs.comment::text ~~ 'Были хештеги: , стали:%онлайн%'::text OR logs.comment::text ~~ 'Были хештеги%оyлайн%стали:%онлайн%'::text OR logs.comment::text ~~ 'Были хештеги%оглайн%стали:%онлайн%'::text
        )
SELECT users_v2.unti_id,
       users_v2.user_id,
       users_v2.course_id,
       users_v2.flow_num,
       users_v2.tg_bot,
       users_v2.m2_progress,
       users_v2.m2_attestation,
       users_v2.m2_attestation_date
FROM users_v2
WHERE (users_v2.user_id IN ( SELECT DISTINCT t1.user_id
                             FROM t1));