--  < Exloratory data analysis >

SELECT * FROM walmart_clean;

SELECT COUNT(*) FROM walmart_clean;


-- checking for null values containing rows

SELECT COUNT(*) - COUNT(branch) FROM walmart_clean;
SELECT COUNT(*) - COUNT(city) FROM walmart_clean;
SELECT COUNT(*) - COUNT(category) FROM walmart_clean;
SELECT COUNT(*) - COUNT(unit_price) FROM walmart_clean;
SELECT COUNT(*) - COUNT(quantity) FROM walmart_clean;
SELECT COUNT(*) - COUNT(date) FROM walmart_clean;

SELECT category , COUNT(*) FROM walmart_clean
GROUP BY category; 

SELECT MAX(quantity) FROM walmart_clean;
SELECT MIN(quantity) FROM walmart_clean;

SELECT payment_method , COUNT(*) FROM walmart_clean
GROUP BY payment_method;

SELECT COUNT(DISTINCT(branch)) FROM walmart_clean;


-- < BUSINESS PROBLEMS >

/*
Q.1 What are the different payment methods, and how many transactions and
items were sold with each method? */

SELECT
	payment_method,
	COUNT(*) AS no_of_trnsaction,
	SUM(quantity) AS sum_of_quantity 
	FROM walmart_clean
GROUP BY payment_method;

/*
Q.2 Identify the highest-rated category in each branch, displaying the branch, category and average rating 
*/

SELECT * FROM 
(
SELECT 
	branch ,
	category,
	AVG(rating) AS average_rating,
	RANK() OVER(PARTITION BY branch ORDER BY AVG(rating)  DESC) as ranking
	FROM walmart_clean
GROUP BY 1,2
)
WHERE ranking = 1


-- Q.3 Identify the busiest day for each branch based on the number of transactions

ALTER TABLE walmart_clean
ALTER COLUMN date 
SET DATA TYPE DATE
USING TO_DATE(date , 'DD-MM-YY' );


SELECT * FROM
(
SELECT 
	branch ,
	TO_CHAR(date , 'day') ,
	COUNT(*),
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ranking
	FROM walmart_clean
	GROUP BY 1,2
)
WHERE ranking = 1


--Q.4 Calculate the total quantity of items sold per payment method. List payment_method and total_quantity.

SELECT 
	payment_method , 
	SUM(quantity) AS total_quantity
FROM walmart_clean
GROUP BY payment_method

--Q.5 Determine the average, minimum, and maximum rating of category for each city. 
-- List the city, average_rating, min_rating, and max_rating.

SELECT 
	city ,
	category,
	AVG(rating),
	MIN(rating),
	MAX(rating)
FROM walmart_clean
GROUP BY 1,2
ORDER BY 1

/*
Q.6 Calculate the total profit for each category by considering total_profit as
(unit_price * quantity * profit_margin). 
List category and total_profit, ordered from highest to lowest profit.
*/

SELECT 
category,
SUM(unit_price * quantity * profit_margin) AS total_profit
FROM walmart_clean
GROUP BY 1
ORDER BY total_profit DESC

/*
Q.7 Determine the most common payment method for each Branch. 
Display Branch and the preferred_payment_method.
*/

WITH cte 
AS
(
SELECT
	branch ,
	payment_method,
	COUNT(*),
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ranking
	FROM walmart_clean
	GROUP BY 1,2
)
SELECT * FROM cte
WHERE ranking = 1

/*
Q.8 Categorize sales into 3 group MORNING, AFTERNOON, EVENING 
Find out each of the shift and number of invoices
*/

-- changed time varchar to time data-type
ALTER TABLE walmart_clean
ALTER COLUMN time
SET DATA TYPE TIME
USING time::TIME;


SELECT
CASE 
    WHEN EXTRACT(HOUR FROM time) < 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM time) BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
END AS shift,
  COUNT(*) AS total_invoices
FROM walmart_clean
GROUP BY shift;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)

WITH last_year
AS
(
	SELECT 
		branch ,
		SUM(total_price) AS revenue 
	FROM walmart_clean
	WHERE TO_char(date , 'YYYY') = '2022'
	GROUP BY branch
),

current_year
AS
(
	SELECT 
		branch ,
		SUM(total_price) AS revenue 
	FROM walmart_clean
	WHERE TO_char(date , 'YYYY') = '2023'
	GROUP BY branch
)

SELECT ly.branch , 
(ly.revenue - cy.revenue)/ly.revenue * 100  AS ratio
FROM 
current_year AS cy JOIN last_year AS ly ON
cy.branch = ly.branch
ORDER BY ratio
LIMIT 5


