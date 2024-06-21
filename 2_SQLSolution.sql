--1 What are the top 5 brands by receipts scanned for most recent month?
WITH recent_month_receipts AS (
SELECT r.receipt_id, ri.barcode
FROM Receipts r
JOIN ReceiptItems ri ON r.receipt_id = ri.receipt_id
WHERE r.purchase_date >= DATEADD(MONTH, -1, GETDATE())
)
SELECT b.name AS brand_name, COUNT(DISTINCT rm.receipt_id) AS receipt_count
FROM recent_month_receipts rm
JOIN Brands b ON rm.barcode = b.barcode
GROUP BY b.name
ORDER BY receipt_count DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;


--2 How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?
WITH current_month AS (
SELECT r.receipt_id, ri.barcode
FROM Receipts r
JOIN ReceiptItems ri ON r.receipt_id = ri.receipt_id
WHERE r.purchase_date >= DATEADD(MONTH, -1, GETDATE())
),

current_month_ranking AS (
SELECT b.name AS brand_name, COUNT(DISTINCT cm.receipt_id) AS receipt_count, 
RANK() OVER (ORDER BY COUNT(DISTINCT cm.receipt_id) DESC) AS rank
FROM current_month cm
JOIN Brands b ON cm.barcode = b.barcode
GROUP BY b.name
ORDER BY receipt_count DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)

, previous_month AS (
SELECT r.receipt_id, ri.barcode
FROM Receipts r
JOIN ReceiptItems ri ON r.receipt_id = ri.receipt_id
WHERE r.purchase_date >= DATEADD(MONTH, -2, GETDATE()) AND r.purchase_date < DATEADD(MONTH, -1, GETDATE())
),

previous_month_ranking AS (
SELECT b.name AS brand_name, COUNT(DISTINCT pm.receipt_id) AS receipt_count, 
RANK() OVER (ORDER BY COUNT(DISTINCT pm.receipt_id) DESC) AS rank
FROM previous_month pm
JOIN Brands b ON pm.barcode = b.barcode
GROUP BY b.name
ORDER BY receipt_count DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY
)

SELECT 
cmr.brand_name AS current_brand, cmr.receipt_count AS current_count,
cmr.rank AS current_rank, pmr.brand_name AS previous_brand,
pmr.receipt_count AS previous_count, pmr.rank AS previous_rank
FROM current_month_ranking cmr
FULL OUTER JOIN previous_month_ranking pmr ON cmr.brand_name = pmr.brand_name
ORDER BY cmr.rank, pmr.rank;


--3 When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
WITH spend_comparison AS (
SELECT rewards_receipt_status, AVG(total_spent) AS avg_spend
FROM Receipts
WHERE rewards_receipt_status IN ('Accepted', 'Rejected')
GROUP BY rewards_receipt_status
)

SELECT rewards_receipt_status, avg_spend
FROM spend_comparison
ORDER BY avg_spend DESC;


--4 When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?
WITH items_comparison AS (
    SELECT rewards_receipt_status, SUM(purchased_item_count) AS total_items
    FROM Receipts
    WHERE  rewards_receipt_status IN ('Accepted', 'Rejected')
    GROUP BY rewards_receipt_status
)
SELECT rewards_receipt_status, total_items
FROM items_comparison
ORDER BY total_items DESC;


--5 Which brand has the most spend among users who were created within the past 6 months?
WITH recent_users AS (
    SELECT 
        user_id
    FROM 
        Users
    WHERE 
        created_date >= DATEADD(MONTH, -6, GETDATE())
)

, user_receipts AS (
    SELECT 
        ru.user_id,
        r.receipt_id
    FROM 
        recent_users ru
    JOIN 
        Receipts r ON ru.user_id = r.user_id
)

, receipt_items AS (
    SELECT 
        ur.user_id,
        ri.receipt_id,
        ri.barcode,
        ri.final_price
    FROM 
        user_receipts ur
    JOIN 
        ReceiptItems ri ON ur.receipt_id = ri.receipt_id
)

, brand_spend AS (
    SELECT 
        ri.barcode,
        SUM(CAST(ri.final_price AS FLOAT)) AS total_spend
    FROM 
        receipt_items ri
    GROUP BY 
        ri.barcode
)

SELECT 
    b.name AS brand_name,
    bs.total_spend
FROM 
    brand_spend bs

JOIN 
    Brands b ON b.barcode = bs.barcode
ORDER BY 
    bs.total_spend DESC
OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY;


--6 Which brand has the most transactions among users who were created within the past 6 months?
WITH recent_users AS (
    SELECT 
        user_id
    FROM 
        Users
    WHERE 
        created_date >= DATEADD(MONTH, -6, GETDATE())
)

, user_receipts AS (
    SELECT 
        ru.user_id,
        r.receipt_id
    FROM 
        recent_users ru
    JOIN 
        Receipts r ON ru.user_id = r.user_id
)

, receipt_items AS (
    SELECT 
        ur.user_id,
        ri.receipt_id,
        ri.barcode
    FROM 
        user_receipts ur
    JOIN 
        ReceiptItems ri ON ur.receipt_id = ri.receipt_id
)

, brand_transactions AS (
    SELECT 
        ri.barcode,
        COUNT(ri.receipt_id) AS total_transactions
    FROM 
        receipt_items ri
    GROUP BY 
        ri.barcode
)

SELECT b.name AS brand_name, bt.total_transactions
FROM brand_transactions bt
JOIN Brands b ON p.barcode = b.barcode
ORDER BY bt.total_transactions DESC
OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY;