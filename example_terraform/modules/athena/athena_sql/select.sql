SELECT
 count(*) AS count,
 httpsourceid,
 httprequest.clientip,
 t.rulegroupid, 
 t.nonTerminatingMatchingRules
FROM "waf_logs" 
CROSS JOIN UNNEST(rulegrouplist) AS t(t) 
WHERE action <> 'BLOCK' AND cardinality(t.nonTerminatingMatchingRules) > 0 
GROUP BY t.nonTerminatingMatchingRules, action, httpsourceid, httprequest.clientip, t.rulegroupid 
ORDER BY "count" DESC 
Limit 50