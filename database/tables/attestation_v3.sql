-- public.attestation_v3 определение

-- Drop table

-- DROP TABLE public.attestation_v3;

CREATE TABLE public.attestation_v3 (
                                       user_id int4 NULL,
                                       course_id int4 NULL,
                                       flow_num float4 NULL,
                                       course_progress varchar(50) NULL,
                                       course_attestation varchar(50) NULL,
                                       course_attestation_date timestamp NULL,
                                       attestation_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                       CONSTRAINT attestation_m2_v3_pkey PRIMARY KEY (attestation_id)
);


-- public.attestation_v3 внешние включи

ALTER TABLE public.attestation_v3 ADD CONSTRAINT attestation_m2_v3_courses_v3_fk FOREIGN KEY (course_id) REFERENCES public.courses_v3(course_id);
ALTER TABLE public.attestation_v3 ADD CONSTRAINT attestation_m2_v3_flows_v3_fk FOREIGN KEY (flow_num) REFERENCES public.flows_v3(flow_num);
ALTER TABLE public.attestation_v3 ADD CONSTRAINT attestation_m2_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);