-- public.users_v3 определение

-- Drop table

-- DROP TABLE public.users_v3;

CREATE TABLE public.users_v3 (
                                 user_id int4 NOT NULL,
                                 unti_id int4 NULL,
                                 time_zone varchar(50) NULL,
                                 age int4 NULL,
                                 tg_bot varchar(50) NULL,
                                 CONSTRAINT users_v3_pkey PRIMARY KEY (user_id)
);