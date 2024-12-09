-- public.activities_guide_v4 определение

-- Drop table

-- DROP TABLE public.activities_guide_v4;

CREATE TABLE public.activities_guide_v4 (
                                            course_id int4 NULL,
                                            course varchar NULL,
                                            provider varchar NULL,
                                            modul int4 NULL,
                                            theme_id int4 NULL,
                                            theme varchar NULL,
                                            task_id int4 NULL,
                                            exercise varchar NULL,
                                            task_position int4 NULL,
                                            att_priznak int4 NULL,
                                            activity_id int4 NULL,
                                            activity_type varchar NULL,
                                            activity varchar NULL,
                                            obyaz_priznak int4 NULL,
                                            visibility varchar NULL
);