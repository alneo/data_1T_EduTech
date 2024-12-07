--переменные:
--:date - дата среза
--:user_id - user_id

with
week_later as(
select status pre_status
from public.table_glu_dt_v3
where (k_day = :date::date - interval '1 week') and user_id = :user_id
)

select k_day, user_id, status
  , case 
    when (select pre_status from week_later) < status then 'UP'
    when (select pre_status from week_later) = status then 'NO_CHANGE'
    when (select pre_status from week_later) > status then 'DOWN'
  end  
from public.table_glu_dt_v3
where k_day = :date::date and user_id = :user_id
