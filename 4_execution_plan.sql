-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 4: Execution Plan Analizi ve Sorgu İyileştirme
-- Veritabanı: WideWorldImporters
-- NOT: Ctrl+M ile Actual Execution Plan aktif edilmelidir
-- ============================================================

USE WideWorldImporters;
GO

-- -----------------------------------------------------------
-- 4.1 KÖTÜ SORGU: Subquery kullanımı
-- Execution Plan'da Nested Loops ve Key Lookup yoğun görülür
-- Sorgu maliyeti batch'in %100'ü olarak hesaplanır
-- -----------------------------------------------------------
SELECT *
FROM Sales.Orders
WHERE CustomerID IN (
    SELECT CustomerID FROM Sales.Customers
    WHERE DeliveryCityID = 19586
);
GO

-- -----------------------------------------------------------
-- 4.2 İYİ SORGU: INNER JOIN ile optimize edilmiş versiyon
-- SELECT * yerine yalnızca gerekli kolonlar seçilmiştir
-- Subquery kaldırılmış, JOIN kullanılmıştır
-- Execution Plan'da daha az Nested Loop görülür
-- -----------------------------------------------------------
SELECT 
    o.OrderID,
    o.OrderDate,
    o.CustomerPurchaseOrderNumber,
    c.CustomerName,
    c.DeliveryCityID
FROM Sales.Orders o
INNER JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE c.DeliveryCityID = 19586;
GO
