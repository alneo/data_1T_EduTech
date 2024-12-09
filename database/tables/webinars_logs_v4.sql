-- public.webinars_logs_v4 определение

-- Drop table

-- DROP TABLE public.webinars_logs_v4;

CREATE TABLE public.webinars_logs_v4 (
                                         user_id int4 NULL,
                                         datetime timestamp NULL,
                                         event_name varchar(50) NULL,
                                         webinar_id int4 NULL,
                                         conn_format varchar(50) NULL,
                                         webinar_vvod int4 NULL,
                                         "module" int4 NULL
);