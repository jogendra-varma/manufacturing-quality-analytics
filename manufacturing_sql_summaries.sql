-- =====================================================
-- Manufacturing Quality Analytics — SQL Summary Queries
-- Run against: manufacturing_defects table, Azure SQL DB
-- =====================================================

-- 1. Overall defect rate (baseline KPI for dashboard)
SELECT
    COUNT(*) AS total_records,
    SUM(DefectStatus) AS total_defects,
    CAST(SUM(DefectStatus) AS FLOAT) / COUNT(*) AS defect_rate
FROM manufacturing_defects;

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;
-- 2. Defect rate by maintenance-hour bin (matches your what-if calculator)
SELECT
    CASE
        WHEN MaintenanceHours < 2 THEN '0-2'
        WHEN MaintenanceHours < 4 THEN '2-4'
        WHEN MaintenanceHours < 6 THEN '4-6'
        WHEN MaintenanceHours < 8 THEN '6-8'
        WHEN MaintenanceHours < 10 THEN '8-10'
        WHEN MaintenanceHours < 12 THEN '10-12'
        WHEN MaintenanceHours < 14 THEN '12-14'
        WHEN MaintenanceHours < 16 THEN '14-16'
        WHEN MaintenanceHours < 18 THEN '16-18'
        WHEN MaintenanceHours < 20 THEN '18-20'
        WHEN MaintenanceHours < 22 THEN '20-22'
        ELSE '22-24'
    END AS maintenance_bin,
    COUNT(*) AS n,
    CAST(SUM(DefectStatus) AS FLOAT) / COUNT(*) AS defect_rate
FROM manufacturing_defects
GROUP BY
    CASE
        WHEN MaintenanceHours < 2 THEN '0-2'
        WHEN MaintenanceHours < 4 THEN '2-4'
        WHEN MaintenanceHours < 6 THEN '4-6'
        WHEN MaintenanceHours < 8 THEN '6-8'
        WHEN MaintenanceHours < 10 THEN '8-10'
        WHEN MaintenanceHours < 12 THEN '10-12'
        WHEN MaintenanceHours < 14 THEN '12-14'
        WHEN MaintenanceHours < 16 THEN '14-16'
        WHEN MaintenanceHours < 18 THEN '16-18'
        WHEN MaintenanceHours < 20 THEN '18-20'
        WHEN MaintenanceHours < 22 THEN '20-22'
        ELSE '22-24'
    END
ORDER BY maintenance_bin;


-- 3. Low vs High maintenance comparison (your A/B test groups, verified in SQL)
SELECT
    CASE WHEN MaintenanceHours <= 12 THEN 'Low Maintenance (<=12h)' ELSE 'High Maintenance (>12h)' END AS process_group,
    COUNT(*) AS n,
    SUM(DefectStatus) AS defects,
    CAST(SUM(DefectStatus) AS FLOAT) / COUNT(*) AS defect_rate
FROM manufacturing_defects
GROUP BY CASE WHEN MaintenanceHours <= 12 THEN 'Low Maintenance (<=12h)' ELSE 'High Maintenance (>12h)' END;


-- 4. Quality Score vs Defect Status — check if quality score is a leading indicator
SELECT
    DefectStatus,
    AVG(QualityScore) AS avg_quality_score,
    MIN(QualityScore) AS min_quality_score,
    MAX(QualityScore) AS max_quality_score
FROM manufacturing_defects
GROUP BY DefectStatus;


-- 5. Production volume bands vs defect rate — second dashboard dimension
SELECT
    CASE
        WHEN ProductionVolume < 300 THEN 'Low (<300)'
        WHEN ProductionVolume < 600 THEN 'Medium (300-600)'
        WHEN ProductionVolume < 900 THEN 'High (600-900)'
        ELSE 'Very High (900+)'
    END AS volume_band,
    COUNT(*) AS n,
    CAST(SUM(DefectStatus) AS FLOAT) / COUNT(*) AS defect_rate
FROM manufacturing_defects
GROUP BY
    CASE
        WHEN ProductionVolume < 300 THEN 'Low (<300)'
        WHEN ProductionVolume < 600 THEN 'Medium (300-600)'
        WHEN ProductionVolume < 900 THEN 'High (600-900)'
        ELSE 'Very High (900+)'
    END
ORDER BY volume_band;


-- 6. Supplier quality vs defect rate — supply-chain angle
SELECT
    ROUND(SupplierQuality, 0) AS supplier_quality_rounded,
    COUNT(*) AS n,
    CAST(SUM(DefectStatus) AS FLOAT) / COUNT(*) AS defect_rate
FROM manufacturing_defects
GROUP BY ROUND(SupplierQuality, 0)
ORDER BY supplier_quality_rounded;
