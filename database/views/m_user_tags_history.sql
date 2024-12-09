-- public.m_user_tags_history исходный текст

CREATE OR REPLACE VIEW public.m_user_tags_history
AS WITH users_logs_1 AS (
         SELECT users_logs_v2.user_id,
            users_logs_v2.created_at,
            users_logs_v2.event,
            users_logs_v2.comment,
            split_part(users_logs_v2.comment::text, ', стали:'::text, 1) AS old_tags,
            split_part(users_logs_v2.comment::text, ', стали:'::text, 2) AS new_tags
           FROM users_logs_v2
          WHERE NOT users_logs_v2.comment::text ~~ '%Установлен%'::text
          ORDER BY users_logs_v2.created_at
        ), users_logs_2 AS (
         SELECT users_logs_1.user_id,
            users_logs_1.created_at,
            users_logs_1.event,
            users_logs_1.comment,
            "substring"(unnest(string_to_array(users_logs_1.old_tags, '#'::text)), 'о.лайн'::text) AS old_tag,
            users_logs_1.new_tags
           FROM users_logs_1
        ), users_logs_3 AS (
         SELECT users_logs_2.user_id,
            users_logs_2.created_at,
            users_logs_2.event,
            users_logs_2.comment,
            replace(replace(users_logs_2.old_tag, 'оyлайн'::text, 'онлайн'::text), 'оглайн'::text, 'онлайн'::text) AS old_tag,
            "substring"(unnest(string_to_array(users_logs_2.new_tags, '#'::text)), 'о.лайн'::text) AS new_tag
           FROM users_logs_2
        ), users_logs_4 AS (
         SELECT users_logs_3.user_id,
            users_logs_3.created_at,
            users_logs_3.event,
            users_logs_3.comment,
            users_logs_3.old_tag,
            users_logs_3.new_tag,
            lead(users_logs_3.user_id, 1) OVER (PARTITION BY users_logs_3.user_id, users_logs_3.created_at) AS lead_val
           FROM users_logs_3
          WHERE users_logs_3.old_tag <> ''::text AND users_logs_3.new_tag <> ''::text
        ), users_logs_5 AS (
         SELECT users_logs_4.user_id,
            users_logs_4.created_at,
            users_logs_4.event,
            users_logs_4.comment,
            users_logs_4.old_tag,
            users_logs_4.new_tag
           FROM users_logs_4
          WHERE users_logs_4.lead_val IS NULL
        ), users_logs_6 AS (
         SELECT users_logs_3.user_id,
            users_logs_3.created_at,
            users_logs_3.event,
            users_logs_3.comment,
            'онлайн'::text AS old_tag,
            users_logs_3.new_tag
           FROM users_logs_3
          WHERE users_logs_3.new_tag <> ''::text
          GROUP BY users_logs_3.user_id, users_logs_3.created_at, users_logs_3.event, users_logs_3.comment, users_logs_3.new_tag
         HAVING string_agg(users_logs_3.old_tag, ', '::text) IS NULL
        ), users_logs_7 AS (
         SELECT users_logs_v2.user_id,
            users_logs_v2.created_at,
            users_logs_v2.event,
            users_logs_v2.comment,
            'онлайн'::text AS old_tag,
            'онлайн'::text AS new_tag
           FROM users_logs_v2
          WHERE users_logs_v2.comment::text ~~ '%Установлен%'::text
        ), users_logs_8 AS (
         SELECT users_logs_5.user_id,
            users_logs_5.created_at,
            users_logs_5.event,
            users_logs_5.comment,
            users_logs_5.old_tag,
            users_logs_5.new_tag
           FROM users_logs_5
        UNION ALL
         SELECT users_logs_6.user_id,
            users_logs_6.created_at,
            users_logs_6.event,
            users_logs_6.comment,
            users_logs_6.old_tag,
            users_logs_6.new_tag
           FROM users_logs_6
        UNION ALL
         SELECT users_logs_7.user_id,
            users_logs_7.created_at,
            users_logs_7.event,
            users_logs_7.comment,
            users_logs_7.old_tag,
            users_logs_7.new_tag
           FROM users_logs_7
        ), interval_1 AS (
         SELECT users_logs_8.user_id,
            users_logs_8.comment,
            users_logs_8.created_at AS from_datetime,
            COALESCE(lead(users_logs_8.created_at, 1) OVER (PARTITION BY users_logs_8.user_id ORDER BY users_logs_8.created_at), '2500-01-01 00:00:00'::timestamp without time zone) AS to_datetime,
            users_logs_8.old_tag AS last_tag,
            users_logs_8.new_tag AS tag,
            lag(users_logs_8.user_id, 1) OVER (PARTITION BY users_logs_8.user_id ORDER BY users_logs_8.created_at) AS lag1
           FROM users_logs_8
        ), interval_2 AS (
         SELECT interval_1.user_id,
            'БЕРЕМ ЗНАЧЕНИЕ БЫЛО: '::text || interval_1.comment::text AS comment,
            '1900-01-01 00:00:00'::timestamp without time zone AS from_datetime,
            interval_1.from_datetime AS to_datetime,
            interval_1.last_tag,
            interval_1.last_tag AS tag
           FROM interval_1
          WHERE interval_1.lag1 IS NULL
        ), interval_3 AS (
         SELECT interval_1.user_id,
            interval_1.comment,
            interval_1.from_datetime,
            interval_1.to_datetime,
            interval_1.last_tag,
            interval_1.tag
           FROM interval_1
        UNION ALL
         SELECT interval_2.user_id,
            interval_2.comment,
            interval_2.from_datetime,
            interval_2.to_datetime,
            interval_2.last_tag,
            interval_2.tag
           FROM interval_2
        ), users_logs_hist AS (
         SELECT DISTINCT COALESCE(l.user_id, uv.user_id) AS user_id,
            COALESCE(l.from_datetime, '1900-01-01 00:00:00'::timestamp without time zone) AS from_datetime,
            COALESCE(l.to_datetime, '2500-01-01 00:00:00'::timestamp without time zone) AS to_datetime,
            COALESCE(l.last_tag, 'онлайн'::text) AS last_tag,
            COALESCE(l.tag, 'онлайн'::text) AS tag,
            l.user_id IS NOT NULL AS from_users_logs,
            COALESCE(l.comment, 'нет логов'::character varying) AS comment
           FROM users_v2 uv
             LEFT JOIN interval_3 l ON uv.user_id = l.user_id
        )
SELECT users_logs_hist.user_id,
       users_logs_hist.from_datetime,
       users_logs_hist.to_datetime,
       users_logs_hist.last_tag,
       users_logs_hist.tag,
       users_logs_hist.from_users_logs,
       users_logs_hist.comment
FROM users_logs_hist
ORDER BY users_logs_hist.user_id, users_logs_hist.from_datetime;