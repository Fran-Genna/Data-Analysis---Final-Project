CREATE TABLE fashion_data (
    user_uuid TEXT,
    category TEXT,
    designer_id TEXT,
    level TEXT,
    country TEXT,
    purchase_date DATE,
    purchase_year INTEGER,
    purchase_trimester TEXT,
    purchase_month INTEGER,
    platform TEXT,
    item_id TEXT,
    stars INTEGER,
    subscription_date DATE,
    subscription_year INTEGER,
    subscription_trimester TEXT,
    subscription_month INTEGER
);


SELECT *
FROM fashion_data;



-- CATEGORY: how many sells per category for each month?
SELECT
    purchase_year,
    purchase_trimester,
    purchase_month,
    category,
    COUNT(*) AS category_sells
FROM
    fashion_data
GROUP BY
    purchase_year,
    purchase_trimester,
    purchase_month,
    category
ORDER BY
    purchase_year,
    purchase_trimester,
    purchase_month,
    category;




-- SUBSCRIPTIONS
SELECT
    subscription_year,
    subscription_trimester,
    subscription_month,
    COUNT(*) AS monthly_subscriptions
FROM
    fashion_data
GROUP BY
    subscription_year,
    subscription_trimester,
    subscription_month
ORDER BY
    subscription_year,
    subscription_trimester,
    subscription_month;




-- Top Designer / Item per category
-- Common Table Expression to calculate total sales per item, designer, category, and year
WITH top_selling_items AS (
    SELECT
        category,
        purchase_year,
        designer_id,
        item_id,
        level,
        COUNT(*) AS total_sales,

        -- Ranking all items by sales, within category + year + level
        ROW_NUMBER() OVER (
            PARTITION BY category, purchase_year
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM fashion_data
    GROUP BY category, purchase_year, designer_id, item_id, level
)

-- Select top-selling item per category and year
SELECT
    category,
    purchase_year,
    designer_id,
    item_id,
    level
FROM top_selling_items
WHERE rn = 1
ORDER BY category, purchase_year;
	




--Clustering
-- Calculate user-level metrics: total sales and average stars (rounded to 1 decimal)
WITH user_metrics AS (
    SELECT 
        user_uuid,
        COUNT(*) AS total_sales,  -- Total number of sales per user
        ROUND(AVG(stars)::numeric, 1) AS avg_stars  -- Average rating (stars) per user, rounded to 1 decimal place
    FROM fashion_data
    GROUP BY user_uuid
),

-- Calculate median values for total_sales and avg_stars across all users
stats AS (
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_sales) AS median_sales,  -- Median of total sales
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY avg_stars) AS median_stars    -- Median of average stars
    FROM user_metrics
)
-- Assign each user to a cluster based on their total_sales and avg_stars relative to the medians
SELECT 
    um.user_uuid,
    um.total_sales,
    um.avg_stars,
    CASE 
        WHEN um.total_sales < s.median_sales AND um.avg_stars < s.median_stars THEN 'Jims'           -- Low sales, low rating
        WHEN um.total_sales < s.median_sales AND um.avg_stars >= s.median_stars THEN 'Mirandas'      -- Low sales, high rating
        WHEN um.total_sales >= s.median_sales AND um.avg_stars < s.median_stars THEN 'The Wolfs'     -- High sales, low rating
        WHEN um.total_sales >= s.median_sales AND um.avg_stars >= s.median_stars THEN 'The Champions'-- High sales, high rating
    END AS cluster_name
FROM user_metrics um
CROSS JOIN stats s;  -- Combine metrics with median stats for comparison














