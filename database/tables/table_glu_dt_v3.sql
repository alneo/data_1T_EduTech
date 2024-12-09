-- public.table_glu_dt_v3 определение

-- Drop table

-- DROP TABLE public.table_glu_dt_v3;

CREATE TABLE public.table_glu_dt_v3 (
                                        k_day date NULL,
                                        user_id int4 NULL,
                                        course_id int4 NULL,
                                        required_activities_delay int8 NULL,
                                        success_required_done int8 NULL,
                                        success_optional_done int8 NULL,
                                        mean_result_required int4 NULL,
                                        cur_date_speed numeric NULL,
                                        avg_speed numeric NULL,
                                        cur_date_progress int4 NULL,
                                        current_progress int8 NULL,
                                        status int4 NULL,
                                        m2_progress int4 NULL,
                                        m2_success int4 NULL
);
CREATE INDEX table_glu_dt_v3_course_id_idx ON public.table_glu_dt_v3 USING btree (course_id);
CREATE INDEX table_glu_dt_v3_k_day_idx ON public.table_glu_dt_v3 USING btree (k_day, user_id);