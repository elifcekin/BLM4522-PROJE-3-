-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 3: İndeks Yönetimi
-- Veritabanı: WideWorldImporters
-- ============================================================

USE WideWorldImporters;
GO

-- -----------------------------------------------------------
-- 3.1 Mevcut indeksleri listele
-- -----------------------------------------------------------
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique,
    i.is_primary_key
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY t.name, i.name;
GO

-- -----------------------------------------------------------
-- 3.2 Eksik indeksleri tespit et (DMV ile)
-- improvement_measure değeri yüksek olanlar önceliklidir
-- -----------------------------------------------------------
SELECT TOP 10
    migs.avg_total_user_cost * migs.avg_user_impact *
    (migs.user_seeks + migs.user_scans) AS improvement_measure,
    mid.statement AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_group_stats migs
JOIN sys.dm_db_missing_index_groups mig
    ON migs.group_handle = mig.index_group_handle
JOIN sys.dm_db_missing_index_details mid
    ON mig.index_handle = mid.index_handle
ORDER BY improvement_measure DESC;
GO

-- -----------------------------------------------------------
-- 3.3 İndeks öncesi ölçüm
-- UnitPrice = 87.00 AND Quantity = 6 koşuluyla test sorgusu
-- Messages sekmesinde logical reads değerini not al
-- -----------------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    ol.OrderID,
    ol.StockItemID,
    ol.Quantity,
    ol.UnitPrice,
    ol.TaxRate
FROM Sales.OrderLines ol
WHERE ol.UnitPrice = 87.00
  AND ol.Quantity = 6;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- -----------------------------------------------------------
-- 3.4 Nonclustered indeks oluştur
-- -----------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_OrderLines_UnitPrice_Quantity
ON Sales.OrderLines (UnitPrice, Quantity)
INCLUDE (OrderID, StockItemID, TaxRate);
GO

-- -----------------------------------------------------------
-- 3.5 İndeks sonrası ölçüm (aynı sorgu tekrar çalıştırılır)
-- Logical reads 673'ten 4'e düşmesi beklenmektedir
-- -----------------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    ol.OrderID,
    ol.StockItemID,
    ol.Quantity,
    ol.UnitPrice,
    ol.TaxRate
FROM Sales.OrderLines ol
WHERE ol.UnitPrice = 87.00
  AND ol.Quantity = 6;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

-- -----------------------------------------------------------
-- 3.6 Kullanılmamış indeksleri tespit et
-- user_seeks ve user_scans = 0 olan indeksler listelenir
-- FK_ ve sistem indeksleri silinmemelidir
-- -----------------------------------------------------------
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    COALESCE(ius.user_seeks, 0) AS user_seeks,
    COALESCE(ius.user_scans, 0) AS user_scans,
    COALESCE(ius.user_updates, 0) AS user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id = ius.object_id
    AND i.index_id = ius.index_id
    AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
    AND i.is_primary_key = 0
    AND i.is_unique = 0
    AND COALESCE(ius.user_seeks, 0) = 0
    AND COALESCE(ius.user_scans, 0) = 0
ORDER BY COALESCE(ius.user_updates, 0) DESC;
GO
