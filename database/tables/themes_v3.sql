-- public.themes_v3 определение

-- Drop table

-- DROP TABLE public.themes_v3;

CREATE TABLE public.themes_v3 (
                                  theme_id int4 NOT NULL,
                                  theme_name varchar NULL,
                                  course_id int4 NULL,
                                  CONSTRAINT themes_v3_pkey PRIMARY KEY (theme_id)
);


-- public.themes_v3 внешние включи

ALTER TABLE public.themes_v3 ADD CONSTRAINT themes_v3_courses_v3_fk FOREIGN KEY (course_id) REFERENCES public.courses_v3(course_id);