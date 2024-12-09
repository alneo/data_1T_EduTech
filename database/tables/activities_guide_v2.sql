-- public.activities_guide_v2 определение

-- Drop table

-- DROP TABLE public.activities_guide_v2;

CREATE TABLE public.activities_guide_v2 (
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
CREATE INDEX activities_guide_v2_activity_id_idx ON public.activities_guide_v2 USING btree (activity_id);