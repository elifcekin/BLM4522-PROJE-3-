-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 2: DMV ile Veritabanı İzleme
-- Veritabanı: WideWorldImporters
-- ============================================================

USE WideWorldImporters;
GO

-- -----------------------------------------------------------
-- 2.1 En çok kaynak tüketen TOP 10 sorgu
-- -----------------------------------------------------------
SELECT TOP 10
    qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time_ms,
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset
          END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY avg_elapsed_time_ms DESC;
GO

-- -----------------------------------------------------------
-- 2.2 Sistem bekleme istatistikleri
-- Gereksiz sistem bekleme türleri filtrelenerek listelendi
-- -----------------------------------------------------------
SELECT TOP 15
    wait_type,
    waiting_tasks_count,
    wait_time_ms,
    max_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (
    'SLEEP_TASK', 'BROKER_TO_FLUSH', 'BROKER_TASK_STOP',
    'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
    'WAITFOR', 'LAZYWRITER_SLEEP', 'SQLTRACE_BUFFER_FLUSH'
)
ORDER BY wait_time_ms DESC;
GO

-- -----------------------------------------------------------
-- 2.3 Aktif kullanıcı bağlantılarını izle
-- -----------------------------------------------------------
SELECT 
    session_id,
    status,
    login_name,
    host_name,
    cpu_time,
    memory_usage,
    total_elapsed_time
FROM sys.dm_exec_sessions
WHERE is_user_process = 1;
GO
