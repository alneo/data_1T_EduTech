-- public.schedule_v4 определение

-- Drop table

-- DROP TABLE public.schedule_v4;

CREATE TABLE public.schedule_v4 (
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