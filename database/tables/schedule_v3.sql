-- public.schedule_v3 определение

-- Drop table

-- DROP TABLE public.schedule_v3;

CREATE TABLE public.schedule_v3 (
                                    flow_num int4 NOT NULL,
                                    page_id int4 NOT NULL,
                                    visibility varchar(50) NULL,
                                    date_shown timestamp NULL,
                                    deadline timestamp NULL,
                                    schedule_id int4 GENERATED ALWAYS AS IDENTITY( INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START 1 CACHE 1 NO CYCLE) NOT NULL,
                                    CONSTRAINT schedule_v3_pk PRIMARY KEY (schedule_id),
                                    CONSTRAINT schedule_v3_unique UNIQUE (flow_num, page_id)
);


-- public.schedule_v3 внешние включи

ALTER TABLE public.schedule_v3 ADD CONSTRAINT schedule_v3_flows_v3_fk FOREIGN KEY (flow_num) REFERENCES public.flows_v3(flow_num);
ALTER TABLE public.schedule_v3 ADD CONSTRAINT schedule_v3_pages_v3_fk FOREIGN KEY (page_id) REFERENCES public.pages_v3(page_id);