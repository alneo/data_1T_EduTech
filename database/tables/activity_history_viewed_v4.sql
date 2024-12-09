-- public.activity_history_viewed_v4 определение

-- Drop table

-- DROP TABLE public.activity_history_viewed_v4;

CREATE TABLE public.activity_history_viewed_v4 (
                                                   user_id int4 NULL,
                                                   created_at timestamp NULL,
                                                   page_type varchar(50) NULL,
                                                   page_id int4 NULL,
                                                   "module" int4 NULL,
                                                   attestation int4 NULL,
                                                   activity_type varchar(50) NULL
);