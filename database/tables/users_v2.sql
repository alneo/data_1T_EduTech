-- public.users_v2 определение

-- Drop table

-- DROP TABLE public.users_v2;

CREATE TABLE public.users_v2 (
                                 unti_id int4 NULL,
                                 user_id int4 NULL,
                                 course_id int4 NULL,
                                 flow_num float4 NULL,
                                 tg_bot varchar(50) NULL,
                                 m2_progress varchar(50) NULL,
                                 m2_attestation varchar(50) NULL,
                                 m2_attestation_date timestamp NULL
);
CREATE INDEX users_v2_course_id_idx ON public.users_v2 USING btree (course_id);
CREATE INDEX users_v2_user_id_idx ON public.users_v2 USING btree (user_id);
CREATE INDEX users_v2_user_id_idx1 ON public.users_v2 USING btree (user_id, course_id);