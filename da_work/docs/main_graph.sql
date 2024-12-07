--Первый. График по статусам. Левый верхний
--:course_id=49
--:start_date='2023-12-01'
--:finish_date='2023-12-28'
select
    case
        when status = 0 then 'Спящие'
        when status = 1 then 'Засыпающие'
        when status = 2 then 'Активные'
        end as status
     , count(distinct user_id) filter (where k_day = :start_date) first_period
  , count(distinct user_id) filter (where k_day = :finish_date) second_period
from public.glu_dt_v3
where course_id = :course_id
group by 1

--Второй. Автор - ИНГА, я лишь чуть оптимизировала, упростив и убрав concat и прочее. График Среднее время на платформе. Правый верхний
SELECT 
       date_part('week', created_at) AS week,
       COUNT(activivty_id) FILTER (WHERE is_attestation = 0) AS "Просмотренные активности"
FROM 
       dataset_h_v3
WHERE 
       course_id = 77 and
       created_at BETWEEN :start_date AND :finish_date
GROUP BY 
       date_part('year', created_at),
       date_part('week', created_at)
ORDER BY 
       date_part('year', created_at);


--Четвертый. График перехода между статусами. Правый нижний
--:course_id=49
--:start_date='2023-12-01'
--:finish_date='2023-12-28'
select k_day
     , count(distinct user_id) filter (where status = 2) activ--"Активные"
   , count(distinct user_id) filter (where status = 1) zasyp--"Засыпающие"
   , count(distinct user_id) filter (where status = 0) sleept--"Спящие"
from public.glu_dt_v3
where k_day between :start_date and :finish_date and course_id=:course_id
group by 1
