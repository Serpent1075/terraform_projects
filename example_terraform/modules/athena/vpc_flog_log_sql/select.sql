SELECT
  date_format(from_unixtime(cast(start AS bigint)), '%Y-%m-%d') as A,
  srcaddr AS source_ip,
  dstaddr AS destination_ip,
  dstport,
  protocol,
  count (dstport) as count
FROM
  "bcl_vpc_flowlog_db"."vpc_flow_logs"
WHERE
  action = 'ACCEPT'
  AND srcaddr = '21.101.51.147'
  AND dstport BETWEEN 0 AND 1023
  AND date_format(from_unixtime(cast(start AS bigint)), '%Y-%m-%d') BETWEEN '2023-12-20' AND '2024-01-08'
GROUP BY
  date_format(from_unixtime(cast(start AS bigint)), '%Y-%m-%d'),
  srcaddr,
  dstaddr,
  dstport,
  protocol