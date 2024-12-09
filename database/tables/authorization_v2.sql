-- public.authorization_v2 определение

-- Drop table

-- DROP TABLE public.authorization_v2;

CREATE TABLE public.authorization_v2 (
                                         user_id int4 NULL,
                                         created_at timestamp NULL,
                                         user_agent varchar(256) NULL,
                                         window_size varchar(50) NULL
);