-- public.users_logs_v2 определение

-- Drop table

-- DROP TABLE public.users_logs_v2;

CREATE TABLE public.users_logs_v2 (
                                      user_id int4 NULL,
                                      created_at timestamp NULL,
                                      "event" varchar(50) NULL,
                                      "comment" varchar(256) NULL
);
CREATE INDEX users_logs_v2_comment_idx ON public.users_logs_v2 USING btree (comment);
CREATE INDEX users_logs_v2_user_id_idx ON public.users_logs_v2 USING btree (user_id);