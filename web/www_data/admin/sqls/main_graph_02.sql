SELECT
    date_part('week', created_at) AS year_week,
    COUNT(activivty_id) FILTER (WHERE is_attestation = 0) AS view_act
FROM
    dataset_h_v3
WHERE
    course_id = :course_id and
    created_at BETWEEN :start_date AND :finish_date
GROUP BY
    date_part('year', created_at),
    date_part('week', created_at)
ORDER BY
    date_part('year', created_at);


-- SELECT
--     CONCAT(date_part('year', created_at), '-',  LPAD(date_part('week', created_at)::text, 2, '0')) AS year_week,
--     COUNT(activivty_id) FILTER (WHERE is_attestation = 0) AS view_act
-- FROM
--     dataset_h_v3
-- WHERE
--     created_at BETWEEN ''.$dt1.' 00:00:00.000' AND ''.$dt2.' 00:00:00.000'
-- GROUP BY
--     year_week,
--     date_part('week', created_at)
-- ORDER BY year_week;