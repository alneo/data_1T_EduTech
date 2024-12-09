-- public.users_logs_v4 определение

-- Drop table

-- DROP TABLE public.users_logs_v4;

CREATE TABLE public.users_logs_v4 (
                                      user_id int4 NULL,
                                      created_at timestamp NULL,
                                      "event" varchar(50) NULL,
                                      "comment" varchar(256) NULL
);