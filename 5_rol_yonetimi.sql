-- ============================================================
-- BLM4522 Proje 1: Veritabanı Performans Optimizasyonu
-- Bölüm 5: Rol ve Erişim Yönetimi
-- Veritabanı: WideWorldImporters
-- ============================================================

USE WideWorldImporters;
GO

-- -----------------------------------------------------------
-- 5.1 Login ve kullanıcı oluştur
-- -----------------------------------------------------------
CREATE LOGIN WWI_ReadOnly WITH PASSWORD = 'Guclu@Sifre2024!';
GO

CREATE USER WWI_ReadOnly FOR LOGIN WWI_ReadOnly;
GO

-- db_datareader rolüne ekle (yalnızca SELECT yetkisi)
EXEC sp_addrolemember 'db_datareader', 'WWI_ReadOnly';
GO

-- -----------------------------------------------------------
-- 5.2 Özel rol oluştur ve yetki ver
-- Sales ve Purchasing şemalarına SELECT yetkisi tanınır
-- -----------------------------------------------------------
CREATE ROLE SalesAnalystRole;
GO

GRANT SELECT ON SCHEMA::Sales TO SalesAnalystRole;
GRANT SELECT ON SCHEMA::Purchasing TO SalesAnalystRole;
GO

ALTER ROLE SalesAnalystRole ADD MEMBER WWI_ReadOnly;
GO

-- -----------------------------------------------------------
-- 5.3 Rol doğrulama
-- WWI_ReadOnly kullanıcısının hangi rollerde olduğunu göster
-- -----------------------------------------------------------
SELECT 
    dp.name AS UserName,
    dp2.name AS RoleName
FROM sys.database_role_members drm
JOIN sys.database_principals dp
    ON drm.member_principal_id = dp.principal_id
JOIN sys.database_principals dp2
    ON drm.role_principal_id = dp2.principal_id
WHERE dp.name = 'WWI_ReadOnly';
GO

-- -----------------------------------------------------------
-- 5.4 Tüm kullanıcı ve rolleri listele
-- -----------------------------------------------------------
SELECT 
    name AS UserName,
    type_desc AS UserType,
    create_date
FROM sys.database_principals
WHERE type IN ('S', 'U', 'R')
  AND name NOT LIKE '##%'
  AND name != 'guest'
ORDER BY type_desc;
GO

-- -----------------------------------------------------------
-- 5.5 Şema yetki doğrulaması
-- -----------------------------------------------------------
SELECT 
    dp.name AS UserOrRole,
    o.name AS SchemaName,
    p.permission_name,
    p.state_desc
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
JOIN sys.schemas o ON p.major_id = o.schema_id
WHERE dp.name IN ('WWI_ReadOnly', 'SalesAnalystRole');
GO

-- -----------------------------------------------------------
-- 5.6 Yetki testi: INSERT işlemi reddedilmeli
-- Beklenen hata: "The INSERT permission was denied"
-- -----------------------------------------------------------
EXECUTE AS USER = 'WWI_ReadOnly';
GO

INSERT INTO Sales.Customers (CustomerName) VALUES ('Test');
GO

REVERT;
GO
