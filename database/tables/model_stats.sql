-- public.model_stats определение

-- Drop table

-- DROP TABLE public.model_stats;

CREATE TABLE public.model_stats (
                                    id serial4 NOT NULL,
                                    data_create timestamp NULL,
                                    metrika varchar(30) NULL,
                                    model_info varchar(200) NULL,
                                    id_user int4 NULL,
                                    value float4 NULL,
                                    day_num int4 NULL,
                                    time_sql float4 NULL,
                                    time_model float4 NULL,
                                    CONSTRAINT model_stats_pkey PRIMARY KEY (id)
);
CREATE INDEX model_stats_id_user_date_idx ON public.model_stats USING btree (id_user, data_create);
CREATE INDEX model_stats_id_user_idx ON public.model_stats USING btree (id_user, day_num);