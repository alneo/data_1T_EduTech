-- public.authorization_v3 определение

-- Drop table

-- DROP TABLE public.authorization_v3;

CREATE TABLE public.authorization_v3 (
                                         user_id int4 NULL,
                                         created_at timestamp NULL,
                                         user_agent varchar(256) NULL,
                                         window_size varchar(50) NULL,
                                         authorization_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                         CONSTRAINT authorization_v3_pkey PRIMARY KEY (authorization_id)
);


-- public.authorization_v3 внешние включи

ALTER TABLE public.authorization_v3 ADD CONSTRAINT authorization_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);