SELECT
  DATE_FORMAT(from_iso8601_timestamp(time) AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d %H:%i:00') AS request_hour_kst,
  COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com/path/%' THEN 1 ELSE NULL END) AS smartall_int_request_count,
  COUNT(CASE WHEN request_url LIKE '%gw-bookclub.wjthinkbig.com%' THEN 1 ELSE NULL END) AS bookclub_int_request_count,
  COUNT(CASE WHEN request_url LIKE '%gw-thinkbigstudy.wjthinkbig.com%' THEN 1 ELSE NULL END) AS thinkbigstudy_int_request_count,
  COUNT(CASE WHEN request_url LIKE '%gw.wjthinkbig.com%' THEN 1 ELSE NULL END) AS wjthinkbig_int_request_count,
  COUNT(CASE WHEN request_url LIKE '%gw-ecommerce.wjthinkbig.com%' THEN 1 ELSE NULL END) AS ecommerce_int_request_count,
  COUNT(CASE WHEN request_url LIKE '%gw-collect.wjthinkbig.com%' THEN 1 ELSE NULL END) AS collect_int_request_count
FROM gw_2020_api
WHERE
  day='2023/11/19' 
  
GROUP BY
  DATE_FORMAT(from_iso8601_timestamp(time) AT TIME ZONE 'Asia/Seoul', '%Y-%m-%d %H:%i:00')
ORDER BY
  request_hour_kst


SELECT 
    DATE_TRUNC('hour', from_iso8601_timestamp(time) AT TIME ZONE 'Asia/Seoul') + INTERVAL '30' MINUTE * (FLOOR(EXTRACT(MINUTE FROM from_iso8601_timestamp(time)) / 30)) AS request_half_hour_kst,
    COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NF11%TD%' THEN 1 ELSE NULL END) AS banner_NF11_request_count,
    COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY11%TD%' THEN 1 ELSE NULL END) AS banner_NY11_request_count,
    COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY04%TD%' THEN 1 ELSE NULL END) AS banner_NY04_request_count,
    COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY05%TD%' THEN 1 ELSE NULL END) AS banner_NY05_request_count,
    COUNT(CASE WHEN request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY06%TD%' THEN 1 ELSE NULL END) AS banner_NY06_request_count

FROM "albaccesslog"."prd_security_alb_blk_ext_5_partitioned" 

WHERE
  (request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NF11%TD%' OR
  request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY11%TD%' OR
  request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY04%TD%' OR
  request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY05%TD%' OR
  request_url LIKE '%gw-smartall.wjthinkbig.com%smartall%v1.0%banner%NY06%TD%' 
  ) AND  
  (day='2023/07/23' OR day='2023/07/24')
  
GROUP BY
DATE_TRUNC('hour', from_iso8601_timestamp(time) AT TIME ZONE 'Asia/Seoul') + INTERVAL '1' MINUTE * (FLOOR(EXTRACT(MINUTE FROM from_iso8601_timestamp(time))))
ORDER BY
request_half_hour_kst

  

