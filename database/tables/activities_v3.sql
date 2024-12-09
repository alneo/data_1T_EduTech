-- public.activities_v3 определение

-- Drop table

-- DROP TABLE public.activities_v3;

CREATE TABLE public.activities_v3 (
                                      activity_id int4 NOT NULL,
                                      activity_type varchar NULL,
                                      activity_name varchar NULL,
                                      task_id int4 NULL,
                                      obyaz_priznak int4 NULL,
                                      webinar_vvod int4 NULL,
                                      CONSTRAINT activities_v3_pkey PRIMARY KEY (activity_id)
);


-- public.activities_v3 внешние включи

ALTER TABLE public.activities_v3 ADD CONSTRAINT activities_v3_tasks_v3_fk FOREIGN KEY (task_id) REFERENCES public.tasks_v3(task_id);