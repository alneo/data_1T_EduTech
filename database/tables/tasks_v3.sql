-- public.tasks_v3 определение

-- Drop table

-- DROP TABLE public.tasks_v3;

CREATE TABLE public.tasks_v3 (
                                 task_id int4 NOT NULL,
                                 task_name varchar NULL,
                                 theme_id int4 NULL,
                                 is_attestation int4 NULL,
                                 CONSTRAINT tasks_v3_pkey PRIMARY KEY (task_id)
);


-- public.tasks_v3 внешние включи

ALTER TABLE public.tasks_v3 ADD CONSTRAINT tasks_v3_themes_v3_fk FOREIGN KEY (theme_id) REFERENCES public.themes_v3(theme_id);