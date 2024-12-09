-- public.webinars_logs_v3 определение

-- Drop table

-- DROP TABLE public.webinars_logs_v3;

CREATE TABLE public.webinars_logs_v3 (
                                         user_id int4 NULL,
                                         datetime timestamp NULL,
                                         event_name varchar(50) NULL,
                                         page_id int4 NULL,
                                         conn_format varchar(50) NULL,
                                         webinars_logs_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                         CONSTRAINT webinars_logs_v3_pkey PRIMARY KEY (webinars_logs_id)
);


-- public.webinars_logs_v3 внешние включи

ALTER TABLE public.webinars_logs_v3 ADD CONSTRAINT webinars_logs_v3_pages_v3_fk FOREIGN KEY (page_id) REFERENCES public.pages_v3(page_id);
ALTER TABLE public.webinars_logs_v3 ADD CONSTRAINT webinars_logs_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);