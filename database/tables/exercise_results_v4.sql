-- public.exercise_results_v4 определение

-- Drop table

-- DROP TABLE public.exercise_results_v4;

CREATE TABLE public.exercise_results_v4 (
                                            "module" int4 NULL,
                                            activity_id int4 NULL,
                                            user_id int4 NULL,
                                            created_at timestamp NULL,
                                            "result" varchar(50) NULL,
                                            success int4 NULL
);