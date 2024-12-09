-- public.users_age_timezone_v2 определение

-- Drop table

-- DROP TABLE public.users_age_timezone_v2;

CREATE TABLE public.users_age_timezone_v2 (
                                              user_id int4 NULL,
                                              time_zone varchar(50) NULL,
                                              age int4 NULL
);
CREATE INDEX users_age_timezone_v2_user_id_idx ON public.users_age_timezone_v2 USING btree (user_id);