-- Handling Null Values
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM customers
WHERE customer_id IS NULL
	OR customer_name IS NULL
    OR reg_date IS NULL;
    
SELECT COUNT(*) FROM restaurants
WHERE restaurant_id IS NULL
	OR restaurant_name IS NULL
    OR city IS NULL
    OR opening_hours IS NULL;
    
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM riders;
SELECT COUNT(*) FROM deliveries;

--  ----------------------------------------------------------------------------------
-- Business Analysis & Reports
-- ------------------------------------------------------------------------------------
-- Q.1
-- Write the query to find the top most frequently ordered dishes by customer called "Ravi Gupta" in the last one year
--  JOIN customer and orders
--  filter for last one year
-- filter for "Ravi Gupta"
--  GROUP by custoer,dishes and count
SELECT 
	customer_name,
    Dishes,
	Total_order
FROM
(
SELECT 
c.customer_id,
c.customer_name,
o.order_item as Dishes,
COUNT(*) as Total_order,
DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS Ranks
FROM customers as c
JOIN orders AS o
ON
c.customer_id = o.customer_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL 1 year
AND
c.customer_name = 'Ravi Gupta'
GROUP BY 1,2,3
ORDER BY 1,4 DESC
) as t1
WHERE Ranks <=5;

-- Q.2
-- Popular time slot
-- Identify the time slots during 	which the most orders are placed. Based on 2 intervals
-- Approach 1
SELECT 
	CASE
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
		 WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 24:00'
	END AS time_slot,
	COUNT(order_id) AS order_count
FROM orders
GROUP BY time_slot
ORDER BY order_count DESC;

-- Approach 2

SELECT
	FLOOR(EXTRACT(HOUR FROM order_time)/2)*2 AS start_time,
    FLOOR(EXTRACT(HOUR FROM order_time)/2)*2+2 AS end_time,
    COUNT(*) as total_orders
FROM orders
GROUP BY 1,2
ORDER BY 3 DESC;

-- Q-3 -Order Value Analysis
-- Find the average order value per customer who has placed more than 750 orders.
-- Return customer name, 	and aov (Average Order Value)
SELECT 
	c.customer_name,
    ROUND(AVG(o.total_amount),2) AS avo
FROM orders AS o
JOIN
	customers as c
	ON o.customer_id = c.customer_id
GROUP BY 1
HAVING COUNT(order_id) >750;
    
-- Q.4 - High- Value Customers
-- List the customers who have spent more than 1000K in total on food orders
-- return customer name and customer id

 SELECT
	o.customer_id,
	c.customer_name,
    SUM(o.total_amount) AS total_value
FROM orders AS o
JOIN
	customers as c
	ON o.customer_id = c.customer_id
GROUP BY 1,2
HAVING SUM(o.total_amount) >10000;

-- Q.5 - Order without delivery
-- Write a query to find the orders that were placed but not delivered 
-- return each restaurant name, city and number of not delivered orders

SELECT 
	r.restaurant_name,
    COUNT(o.order_id) AS Number_order_Pending
	FROM orders AS o
LEFT JOIN
	restaurants AS r
    ON r.restaurant_id = o.restaurant_id
LEFT JOIN
	deliveries AS d
    ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1
ORDER BY 2 DESC;

-- Q.6 - Restaurant Revenue Ranking
-- Rank restaurant by their total revenue from the last year, including their name
-- total revenue, and rank within their city

WITH ranking_table
AS
(
	SELECT 
		r.city AS City,
		r.restaurant_name AS Restaurant_name,
		SUM(o.total_amount) AS Revenue,
		RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS Ranks
	FROM orders AS o
	JOIN 
		restaurants AS r
		ON r.restaurant_id = o.restaurant_id
        WHERE o.order_date >= CURRENT_DATE - INTERVAL 1 year
		GROUP BY 1, 2
)
SELECT * FROM ranking_table
WHERE Ranks = 1;

-- Q.7 - Most Popular Dish By city
-- Identify the most popular dish in each city based on the number of orders.

SELECT *
FROM (
SELECT 
	r.city,
	o.order_item AS Popluar_Dish,
    COUNT(o.order_id) As Number_Order,
    RANK() OVER(PARTITION BY r.city ORDER BY COUNT(o.order_id) DESC) AS Ranks
FROM orders AS o
JOIN restaurants AS r
	ON r.restaurant_id = o.restaurant_id
GROUP BY 1,2
) AS t1
WHERE Ranks = 1;

-- Q.8 - 
-- Find the customers who have't order in 2025 but did in 2024.
-- Find the customer who have order in 2024
-- Find the customer who have't order in 2025 and compare 1 and 2

SELECT 
	DISTINCT customer_id FROM orders
    WHERE EXTRACT(YEAR FROM order_date) = 2024
    AND
    customer_id NOT IN
					(SELECT DISTINCT customer_id FROM orders
					WHERE EXTRACT(YEAR FROM order_date) = 2025);
-- Q.9 - Cacellation Rate Comparision:
-- Calculate and compare the order cancellation rate for each restaurant between the 
-- current year and previous year.

WITH can_ratio_24 AS (
SELECT 
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
FROM orders AS o
		LEFT JOIN deliveries AS d
			ON o.order_id = d.order_id
		WHERE EXTRACT(YEAR FROM order_date) = 2024
		GROUP BY o.restaurant_id
),
can_ratio_25 AS( 
		SELECT
		o.restaurant_id,
		COUNT(o.order_id) as total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) not_delivered
FROM orders AS o
		LEFT JOIN deliveries AS d
			ON o.order_id = d.order_id
		WHERE EXTRACT(YEAR FROM order_date) = 2025
		GROUP BY o.restaurant_id
),
last_year_data AS (
	SELECT
		restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered / total_orders) * 100, 2) AS cancel_ratio
FROM can_ratio_24
),
current_year_data AS (
	SELECT
		restaurant_id,
        total_orders,
        not_delivered,
        ROUND((not_delivered / total_orders) * 100, 2) AS cancel_ratio
FROM can_ratio_25
)
SELECT
	c.restaurant_id,
    c.cancel_ratio AS current_year_ratio,
    l.cancel_ratio AS last_year_ratio
FROM current_year_data AS c
LEFT JOIN last_year_data AS l
ON c.restaurant_id = l.restaurant_id;

-- Q.10 - Rider average delivery Time:
-- Determine each rider's delivery time

SELECT 
    o.order_id,
    o.order_time,
    d.delivery_time,
    rider_id,
    -- Absolute time difference in seconds
    TIMESTAMPDIFF(SECOND, 
        LEAST(o.order_time, d.delivery_time),
        GREATEST(o.order_time, d.delivery_time)
    ) AS time_differ_seconds,
    -- Format as HH:MM:SS
    SEC_TO_TIME(
        TIMESTAMPDIFF(SECOND, 
            LEAST(o.order_time, d.delivery_time),
            GREATEST(o.order_time, d.delivery_time)
        )
    ) AS delivery_duration

FROM orders AS o
JOIN deliveries AS d ON d.order_id = o.order_id
WHERE d.delivery_status = 'Delivered';
-- Q.11- Monthly Restaurant Growth Ratio:
-- Calculate each restaurant's growth ratio based on the total number of delivered since its joining
WITH growth_ration
AS (
SELECT
	o.restaurant_id,
    DATE_FORMAT(o.order_date, '%m-%y') AS months,
    COUNT(o.order_id) AS cr_month_order,
    LAG(COUNT(o.order_id),1) OVER(PARTITION BY o.restaurant_id ORDER BY  DATE_FORMAT(o.order_date, '%m-%y'))
    AS prev_month_order
FROM orders AS O
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
GROUP BY 1,2
ORDER BY 1,2
)
SELECT
	restaurant_id,
    months,
    prev_month_order
	cr_month_order,
    ROUND((cr_month_order-prev_month_order)/prev_month_order * 100,2) AS groth_ratio
FROM growth_ration;

-- Q.12-Customer Segmentation:
-- Customer Segmentation: Segment customer into 'Gold' or 'Silver' groups based on their total spending
-- Compare to the average order value (AOV) . If the customer's total spending exceeds the AOV,
-- label them as a 'Gold'; otherwise, label them as a 'Silver'. Write a sql query to determine the segments.
-- total number of order and total revenue.
-- Customer total spend
-- AOV . Gold and Silver. Each category and total order and total revenue

SELECT ROUND(AVG(total_amount),2) FROM orders; -- 824.05
SELECT customer_id, SUM(total_amount) AS total_spend FROM orders GROUP BY 1;
SELECT 
	customer_category,
    SUM(total_orders) AS total_orders,
    SUM(total_spend) AS total_revenue
FROM
(
SELECT 
	customer_id,
    SUM(total_amount) AS total_spend,
    COUNT(order_id) AS total_orders,
    CASE 
    WHEN  SUM(total_amount) > (SELECT AVG(total_amount) FROM orders) THEN 'Gold' 
    ELSE 'Silver'
    END AS customer_category
FROM orders
GROUP BY 1
) as t1 GROUP BY 1;

-- Q-13- Rider monthly earnings:
-- Calculate rider's total monthly earnings, assuming they earn 8% of order amount.

SELECT 
	d.rider_id,
    DATE_FORMAT(o.order_date,'%m-%y') AS months,
    SUM(total_amount) AS total_revenue,
    SUM(total_amount) * 0.08 AS rider_earning
FROM orders as o
JOIN deliveries as d
ON o.order_id = d.order_id
GROUP BY 1,2
ORDER BY 1,2;

-- Q-14- Rider Rating Analysis:
-- Find the number of 5-Star,4-star,3-star rating each rider has.
-- riders receive this rating based on delivery time.
-- If orders are received less than 15 minute of order received time the rider get 5 star rating
-- If they deliver 15 and 20 minutes they get 4 star rating
-- If they deliver after 20 minutes they get 3 star rating
SELECT 
	rider_id,
    stars,
    COUNT(*) AS total_starts
FROM
(
		SELECT 
		rider_id,
		delivery_took_time,
			CASE 
				WHEN delivery_took_time < 15 THEN '5 Star' 
				WHEN delivery_took_time BETWEEN 15 AND 20 THEN '4 Star'
			ELSE '3 Star'
			END AS stars
		 FROM
		(
		SELECT 
			o.order_id,
			d.rider_id,
			o.order_time,
			d.delivery_time,
			TIMESTAMPDIFF(MINUTE, o.order_time, d.delivery_time) + 
			CASE WHEN d.delivery_time < o.order_time THEN 1440 ELSE 0 END AS delivery_took_time
		FROM orders as o
		JOIN deliveries as d
		ON o.order_id = d.order_id
		WHERE delivery_status = 'Delivered'
		) as t1
) as t2
GROUP BY 1,2
ORDER BY 1,3;

-- Q-15- Order frequency by day:
-- Analyze order frequency per day of the week and identify the peak day for each restaurant
SELECT *
FROM 
(
	SELECT 
		r.restaurant_name,
		DATE_FORMAT(order_date,'%W') AS order_day,
		COUNT(o.order_id) AS total_order,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY  COUNT(o.order_id)DESC) AS Ranks
	 FROM orders AS o
	JOIN restaurants as r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1,2
	ORDER BY 1,3 DESC
) AS t1
WHERE Ranks = 1;

-- Q-16- Customer Life time value (CLV):
-- Calculate the total revenue generated by each customer over the orders

-- Q-17- Monthly Sales Trends:
-- Identify Sales Trends by comparing each month's total sales to the previous month.

-- Q-18- :
-- 

