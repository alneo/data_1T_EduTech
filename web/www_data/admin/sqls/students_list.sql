--- Студенты по курсу за дату
SELECT
    us.user_id,
    us.tg_bot,
    cv."name" as kurs,
    ms.metrika,
    ms.model_info,
    ms.value,
    ms.day_num
FROM
    users_v2 us,
    courses_v2 cv,
    model_stats ms,
    table_glu_dt_v3 tgdv
where
    us.course_id = cv.course_id and
    ms.id_user = us.user_id and
    us.course_id IN (:courses_id) and
    ms.data_create = :filter_date and(
        ms.metrika='m2_success' and
        ms.value between :success_ot and :success_do
    ) and
        tgdv.user_id = us.user_id and
        tgdv.k_day = :filter_date and
        tgdv.status in (:statuss)
limit 100;