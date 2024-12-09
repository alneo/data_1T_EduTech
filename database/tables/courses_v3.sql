-- public.courses_v3 определение

-- Drop table

-- DROP TABLE public.courses_v3;

CREATE TABLE public.courses_v3 (
                                   course_id int4 NOT NULL,
                                   course_name varchar NULL,
                                   provider varchar NULL,
                                   min_attestation_rate int4 NULL,
                                   CONSTRAINT courses_v3_pkey PRIMARY KEY (course_id)
);