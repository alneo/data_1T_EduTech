-- public.m_course_params исходный текст

CREATE OR REPLACE VIEW public.m_course_params
AS WITH activity AS (
         SELECT a_1.course_id,
            count(*) AS num_activity
           FROM ( SELECT DISTINCT schedule_v2.course_id,
                    schedule_v2.activivty_id
                   FROM schedule_v2) a_1
          GROUP BY a_1.course_id
        ), tasks AS (
         SELECT a_1.course_id,
            count(*) AS num_tasks
           FROM ( SELECT DISTINCT schedule_v2.course_id,
                    schedule_v2.task_id
                   FROM schedule_v2) a_1
          GROUP BY a_1.course_id
        ), activity_type AS (
         SELECT a_1.course_id,
            a_1.activity_type,
            count(*) AS num_activity
           FROM ( SELECT DISTINCT schedule_v2.course_id,
                    schedule_v2.activivty_id,
                    schedule_v2.activity_type
                   FROM schedule_v2) a_1
          GROUP BY a_1.course_id, a_1.activity_type
        ), grouping_p AS (
         SELECT schedule_v2.course_id,
            min(schedule_v2.date_shown) AS min_date_shown,
            max(schedule_v2.date_shown) AS max_date_shown
           FROM schedule_v2
          GROUP BY schedule_v2.course_id
        ), attestation_activity_type AS (
         SELECT aa.course_id,
            sum(aa.num_activity) AS num_activity,
            string_agg(((
                CASE
                    WHEN aa.activity_type::text <> ''::text THEN aa.activity_type
                    ELSE 'empty'::character varying
                END::text || '('::text) || aa.num_activity) || ')'::text, ', '::text) AS activity_types
           FROM ( SELECT a_1.course_id,
                    a_1.activity_type,
                    count(*) AS num_activity
                   FROM ( SELECT DISTINCT schedule_v2.course_id,
                            schedule_v2.activivty_id,
                            schedule_v2.activity_type,
                            schedule_v2.is_attestation
                           FROM schedule_v2) a_1
                  WHERE a_1.is_attestation = 1
                  GROUP BY a_1.course_id, a_1.activity_type) aa
          GROUP BY aa.course_id
        )
SELECT g.course_id,
       cv.name,
       g.min_date_shown,
       g.max_date_shown,
       tt.num_tasks,
       a.num_activity,
       aat.num_activity AS num_attestation_activity,
       aat.activity_types AS attestation_activity_types,
       at1.num_activity AS num_webinar_v2,
       at2.num_activity AS num_questions,
       at3.num_activity AS num_exercise,
       at4.num_activity AS num_interactive,
       at5.num_activity AS num_codeexercise,
       at6.num_activity AS num_slide,
       at7.num_activity AS num_empty_activity
FROM grouping_p g
         JOIN courses_v2 cv ON cv.course_id = g.course_id
         LEFT JOIN activity a ON a.course_id = g.course_id
         LEFT JOIN tasks tt ON tt.course_id = g.course_id
         LEFT JOIN attestation_activity_type aat ON aat.course_id = g.course_id
         LEFT JOIN activity_type at1 ON at1.course_id = g.course_id AND at1.activity_type::text = 'webinar_v2'::text
     LEFT JOIN activity_type at2 ON at2.course_id = g.course_id AND at2.activity_type::text = 'questions'::text
    LEFT JOIN activity_type at3 ON at3.course_id = g.course_id AND at3.activity_type::text = 'exercise'::text
    LEFT JOIN activity_type at4 ON at4.course_id = g.course_id AND at4.activity_type::text = 'interactive'::text
    LEFT JOIN activity_type at5 ON at5.course_id = g.course_id AND at5.activity_type::text = 'CodeExercise'::text
    LEFT JOIN activity_type at6 ON at6.course_id = g.course_id AND at6.activity_type::text = 'slide'::text
    LEFT JOIN activity_type at7 ON at7.course_id = g.course_id AND at7.activity_type::text = ''::text;