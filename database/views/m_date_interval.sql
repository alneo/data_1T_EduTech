-- public.m_date_interval исходный текст

CREATE OR REPLACE VIEW public.m_date_interval
AS WITH RECURSIVE dates AS (
         SELECT min(m_course_params.min_date_shown) AS dt1,
            max(m_course_params.max_date_shown) AS dt2,
            '1 day'::interval AS "interval"
           FROM m_course_params
        ), pr AS (
         SELECT 1 AS i,
            ( SELECT dates.dt1
                   FROM dates) AS dt
        UNION
         SELECT pr_1.i + 1 AS i,
            (( SELECT dates.dt1
                   FROM dates)) + (( SELECT dates."interval"
                   FROM dates)) * pr_1.i::double precision AS dt
           FROM pr pr_1
          WHERE ((( SELECT dates.dt1
                   FROM dates)) + (( SELECT dates."interval"
                   FROM dates)) * pr_1.i::double precision) <= (( SELECT dates.dt2
                   FROM dates))
        )
SELECT row_number() OVER (ORDER BY pr.dt) AS day_num,
        pr.dt::date AS date_column
FROM pr;