-- public.pages_v3 определение

-- Drop table

-- DROP TABLE public.pages_v3;

CREATE TABLE public.pages_v3 (
                                 page_id int4 NOT NULL,
                                 page_type varchar(50) NULL,
                                 task_id int4 NULL,
                                 activity_id int4 NULL,
                                 CONSTRAINT pages_v3_pkey PRIMARY KEY (page_id)
);


-- public.pages_v3 внешние включи

ALTER TABLE public.pages_v3 ADD CONSTRAINT pages_v3_activities_v3_fk FOREIGN KEY (activity_id) REFERENCES public.activities_v3(activity_id);
ALTER TABLE public.pages_v3 ADD CONSTRAINT pages_v3_tasks_v3_fk FOREIGN KEY (task_id) REFERENCES public.tasks_v3(task_id);