-- public.exercise_results_v2 определение

-- Drop table

-- DROP TABLE public.exercise_results_v2;

CREATE TABLE public.exercise_results_v2 (
                                            "module" int4 NULL,
                                            activity_id int4 NULL,
                                            user_id int4 NULL,
                                            created_at timestamp NULL,
                                            "result" varchar(50) NULL,
                                            success int4 NULL
);
CREATE INDEX exercise_results_v2_activity_id_idx ON public.exercise_results_v2 USING btree (activity_id);
CREATE INDEX exercise_results_v2_activity_id_idx2 ON public.exercise_results_v2 USING btree (activity_id, user_id);
CREATE INDEX exercise_results_v2_success0_idx ON public.exercise_results_v2 USING btree (success);
CREATE INDEX exercise_results_v2_success_idx ON public.exercise_results_v2 USING btree (success, activity_id);
CREATE INDEX exercise_results_v2_user_id_idx ON public.exercise_results_v2 USING btree (user_id);