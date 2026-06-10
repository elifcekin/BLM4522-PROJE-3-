-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 1: Veritabanı Tablo Yapısı
-- Veritabanı: WideWorldImporters
-- ============================================================

USE WideWorldImporters;
GO

-- Şema, tablo adı ve satır sayısı bilgilerini listele
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS SatirSayisi
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
ORDER BY p.rows DESC;
