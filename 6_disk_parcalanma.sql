-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 6: Disk Alanı ve Parçalanma Yönetimi
-- Veritabanı: WideWorldImporters
-- ============================================================

USE WideWorldImporters;
GO

-- -----------------------------------------------------------
-- 6.1 Tablo boyut analizi
-- Toplam alan, kullanılan alan ve boş alan KB cinsinden
-- -----------------------------------------------------------
SELECT 
    t.name AS TableName,
    p.rows AS SatirSayisi,
    SUM(a.total_pages) * 8 AS ToplamAlanKB,
    SUM(a.used_pages) * 8 AS KullanilanAlanKB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS BosAlanKB
FROM sys.tables t
JOIN sys.indexes i ON t.object_id = i.object_id
JOIN sys.partitions p ON i.object_id = p.object_id
    AND i.index_id = p.index_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name, p.rows
ORDER BY ToplamAlanKB DESC;
GO

-- -----------------------------------------------------------
-- 6.2 İndeks parçalanma analizi
-- avg_fragmentation_in_percent > 5 olan indeksler listelenir
-- %10-30 arası: REORGANIZE önerilir
-- %30 üzeri  : REBUILD önerilir
-- -----------------------------------------------------------
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ROUND(ips.avg_fragmentation_in_percent, 2) AS FragmentationPct,
    ips.page_count
FROM sys.dm_db_index_physical_stats(
    DB_ID('WideWorldImporters'), NULL, NULL, NULL, 'SAMPLED') ips
JOIN sys.indexes i
    ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 5
  AND ips.page_count > 100
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- -----------------------------------------------------------
-- 6.3 İndeks bakımı
-- OrderLines: %99 parçalanma → REORGANIZE
-- Orders    : %99 parçalanma → REBUILD
-- -----------------------------------------------------------
ALTER INDEX ALL ON Sales.OrderLines REORGANIZE;
GO

ALTER INDEX ALL ON Sales.Orders REBUILD;
GO
