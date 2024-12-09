-- public.schedule_v2 определение

-- Drop table

-- DROP TABLE public.schedule_v2;

CREATE TABLE public.schedule_v2 (
                                    course_id int4 NULL,
                                    "type" varchar(50) NULL,
                                    task_id int4 NULL,
                                    activivty_id int4 NULL,
                                    activity_type varchar(50) NULL,
                                    is_attestation int4 NULL,
                                    visibility varchar(50) NULL,
                                    flows int4 NULL,
                                    date_shown timestamp NULL
);
CREATE INDEX schedule_v2_activivty_id0_idx ON public.schedule_v2 USING btree (activivty_id);
CREATE INDEX schedule_v2_activivty_id_idx ON public.schedule_v2 USING btree (activivty_id, type);
CREATE INDEX schedule_v2_course_id_idx ON public.schedule_v2 USING btree (course_id);
CREATE INDEX schedule_v2_type_idx ON public.schedule_v2 USING btree (type);