-- public.activity_history_viewed_v2 определение

-- Drop table

-- DROP TABLE public.activity_history_viewed_v2;

CREATE TABLE public.activity_history_viewed_v2 (
                                                   user_id int4 NULL,
                                                   created_at timestamp NULL,
                                                   page_type varchar(50) NULL,
                                                   page_id int4 NULL,
                                                   "module" int4 NULL,
                                                   attestation int4 NULL,
                                                   activity_type varchar(50) NULL
);
CREATE INDEX activity_history_viewed_v2_page_id_idx ON public.activity_history_viewed_v2 USING btree (page_id);
CREATE INDEX activity_history_viewed_v2_page_type_idx ON public.activity_history_viewed_v2 USING btree (page_type);
CREATE INDEX activity_history_viewed_v2_user_id_idx ON public.activity_history_viewed_v2 USING btree (user_id);
CREATE INDEX activity_history_viewed_v2_user_id_idx2 ON public.activity_history_viewed_v2 USING btree (user_id, page_id);