-- public.exercise_results_v3 определение

-- Drop table

-- DROP TABLE public.exercise_results_v3;

CREATE TABLE public.exercise_results_v3 (
                                            user_id int4 NULL,
                                            page_id int4 NULL,
                                            created_at timestamp NULL,
                                            "result" varchar(50) NULL,
                                            success int4 NULL,
                                            exercise_results_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                            CONSTRAINT exercise_results_v3_pkey PRIMARY KEY (exercise_results_id)
);


-- public.exercise_results_v3 внешние включи

ALTER TABLE public.exercise_results_v3 ADD CONSTRAINT exercise_results_v3_pages_v3_fk FOREIGN KEY (page_id) REFERENCES public.pages_v3(page_id);
ALTER TABLE public.exercise_results_v3 ADD CONSTRAINT exercise_results_v3_users_v3_fk FOREIGN KEY (user_id) REFERENCES public.users_v3(user_id);