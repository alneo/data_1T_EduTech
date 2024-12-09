-- public.users_logs_v3 определение

-- Drop table

-- DROP TABLE public.users_logs_v3;

CREATE TABLE public.users_logs_v3 (
                                      user_id int4 NULL,
                                      created_at timestamp NULL,
                                      "comment" varchar(256) NULL,
                                      tag_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                      CONSTRAINT users_logs_v3_pkey PRIMARY KEY (tag_id)
);


-- public.users_logs_v3 внешние включи

ALTER TABLE public.users_logs_v3 ADD CONSTRAINT users_logs_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);