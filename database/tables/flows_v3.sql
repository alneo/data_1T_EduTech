-- public.flows_v3 определение

-- Drop table

-- DROP TABLE public.flows_v3;

CREATE TABLE public.flows_v3 (
                                 flow_num float4 NOT NULL,
                                 CONSTRAINT flows_v3_pkey PRIMARY KEY (flow_num)
);