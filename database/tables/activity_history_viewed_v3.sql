-- public.activity_history_viewed_v3 определение

-- Drop table

-- DROP TABLE public.activity_history_viewed_v3;

CREATE TABLE public.activity_history_viewed_v3 (
                                                   user_id int4 NULL,
                                                   created_at timestamp NULL,
                                                   page_id int4 NULL,
                                                   activity_viewed_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                                   CONSTRAINT activity_history_viewed_v3_pkey PRIMARY KEY (activity_viewed_id)
);


-- public.activity_history_viewed_v3 внешние включи

ALTER TABLE public.activity_history_viewed_v3 ADD CONSTRAINT activity_history_viewed_v3_pages_v3_fk FOREIGN KEY (page_id) REFERENCES public.pages_v3(page_id);
ALTER TABLE public.activity_history_viewed_v3 ADD CONSTRAINT activity_history_viewed_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);