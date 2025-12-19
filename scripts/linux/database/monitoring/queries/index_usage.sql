-- Monitor index usage efficiency
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_tup_read = 0 THEN 0
        ELSE (idx_tup_fetch::float / idx_tup_read::float * 100)::numeric(5,2)
    END as efficiency_percent
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY efficiency_percent DESC;