-- public.users_v4 определение

-- Drop table

-- DROP TABLE public.users_v4;

CREATE TABLE public.users_v4 (
                                 unti_id int4 NULL,
                                 user_id int4 NULL,
                                 course_id int4 NULL,
                                 flow_num float4 NULL,
                                 tg_bot varchar(50) NULL,
                                 "timeZone" varchar(50) NULL,
                                 age int4 NULL,
                                 "M1_progress" varchar(50) NULL,
                                 "M1_attestation" varchar(50) NULL,
                                 "M1_attestation_date" timestamp NULL,
                                 m2_progress varchar(50) NULL,
                                 m2_attestation varchar(50) NULL,
                                 course_progress2 int4 NULL,
                                 m2_attestation_date timestamp NULL,
                                 course_attestation varchar(50) NULL,
                                 course_attestation_date timestamp NULL
);