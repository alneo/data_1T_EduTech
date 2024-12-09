-- public."20241024_dataset_timeseries_with_metrics_v_gavrilova" определение

-- Drop table

-- DROP TABLE public."20241024_dataset_timeseries_with_metrics_v_gavrilova";

CREATE TABLE public."20241024_dataset_timeseries_with_metrics_v_gavrilova" (
                                                                               id int4 NULL,
                                                                               user_id int4 NULL,
                                                                               payment int4 NULL,
                                                                               time_zone int4 NULL,
                                                                               age int4 NULL,
                                                                               unti_id int4 NULL,
                                                                               course_id int4 NULL,
                                                                               flow_num float4 NULL,
                                                                               tg_bot int4 NULL,
                                                                               m2_progress float4 NULL,
                                                                               m2_attestation float4 NULL,
                                                                               "module" float4 NULL,
                                                                               m2_delay float4 NULL,
                                                                               sum_auth float4 NULL,
                                                                               sum_schedule_activities float4 NULL,
                                                                               sum_required_activity float4 NULL,
                                                                               sum_attestation_activity float4 NULL,
                                                                               view_delay_first float4 NULL,
                                                                               view_delay_sum float4 NULL,
                                                                               sum_activity_viewed float4 NULL,
                                                                               sum_required_activity_viewed float4 NULL,
                                                                               sum_attestation_activity_viewed float4 NULL,
                                                                               w_view_hours float4 NULL,
                                                                               sum_exercise float4 NULL,
                                                                               sum_required_exercises float4 NULL,
                                                                               sum_attestation_exercises float4 NULL,
                                                                               exercise_delay_first float4 NULL,
                                                                               exercise_delay_sum float4 NULL,
                                                                               result_delay_mean float4 NULL,
                                                                               result_delay_sum float4 NULL,
                                                                               sum_exercise_attempts_mean float4 NULL,
                                                                               mean_required_result float4 NULL,
                                                                               mean_non_req_result float4 NULL,
                                                                               mean_attestation_result float4 NULL,
                                                                               sum_result float4 NULL,
                                                                               conn float4 NULL,
                                                                               online_rate float4 NULL,
                                                                               mean_result float4 NULL,
                                                                               progress float4 NULL,
                                                                               cur_date varchar(50) NULL
);