-- Monitor slow queries (queries taking > 1 second)
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    max_time,
    stddev_time,
    rows
FROM pg_stat_statements 
WHERE mean_time > 1000  -- queries taking more than 1 second on average
ORDER BY mean_time DESC
LIMIT 20;