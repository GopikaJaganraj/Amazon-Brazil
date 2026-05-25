/*
===========
ANALYSIS 1
===========
1.1 To simplify its financial reports, Amazon India needs to standardize payment values. 
Round the average payment values to integer (no decimal) for each payment type and display t
he results sorted in ascending order.
Output: payment_type, rounded_avg_payment 
*/
SELECT 
payment_type,
ROUND(AVG(payment_value)) AS rounded_avg_payment
FROM amazon_brazil."Payments"
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;

/*
1.2 To refine its payment strategy, Amazon India wants to know the distribution of 
orders by payment type. Calculate the percentage of total orders for each payment type, 
rounded to one decimal place, and display them in descending order
Output: payment_type, percentage_orders 
*/
SELECT payment_type,
ROUND(COUNT(order_id)*100.0/(SELECT COUNT(*) FROM amazon_brazil."Payments"),1) AS percentage_orders
FROM amazon_brazil."Payments"
GROUP BY payment_type
ORDER BY percentage_orders DESC;

/*
1.3 Amazon India seeks to create targeted promotions for products within specific price ranges.
Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their 
name. Display these products, sorted by price in descending order.
Output: product_id, price 
*/
select p.product_id,o.price
from amazon_brazil."Product" as p
join amazon_brazil."Order Items" as o
on p.product_id=o.product_id
where o.price between 100 and 500
and lower(p.product_category_name)like( '%smart%' )
group by p.product_id,o.price
order by o.price desc;

/*
1.4 To identify seasonal sales patterns, Amazon India needs to focus on the most 
successful months. Determine the top 3 months with the highest total sales value, r
ounded to the nearest integer.
Output: month, total_sales
*/
SELECT 
EXTRACT(MONTH FROM TO_TIMESTAMP(order_purchase_timestamp,
'DD/MM/YY HH24:MI:SS')) AS month,ROUND(SUM(payment_value)) AS total_sales
FROM amazon_brazil."orders" o
JOIN amazon_brazil."Payments" p
ON o.order_id = p.order_id
GROUP BY month
ORDER BY total_sales DESC
LIMIT 3;

/*
1.5 Amazon India is interested in product categories with significant price variations. 
Find categories where the difference between the maximum and minimum product prices is 
greater than 500 BRL.
Output: product_category_name, price_difference 
*/
SELECT p.product_category_name,
MAX(oi.price) - MIN(oi.price)
AS price_difference
FROM amazon_brazil."Product" p
JOIN amazon_brazil."Order Items" oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING MAX(oi.price) - MIN(oi.price) > 500
ORDER BY price_difference;

/*
1.6 To enhance the customer experience, Amazon India wants to find which payment types 
have the most consistent transaction amounts. Identify the payment types with the least 
variance in transaction amounts, sorting by the smallest standard deviation first.
Output: payment_type, std_deviation 
*/
SELECT payment_type,STDDEV(payment_value) AS std_deviation
FROM amazon_brazil."Payments"
GROUP BY payment_type
ORDER BY std_deviation ASC;

/*
1.7 Amazon India wants to identify products that may have incomplete name in order to fix
it from their end. Retrieve the list of products where the product category name is missing 
or contains only a single character.
Output: product_id, product_category_name  
*/
SELECT product_id,product_category_name
FROM amazon_brazil."Product"
WHERE product_category_name IS NULL
OR LENGTH(product_category_name) = 1;

/* 
===========
ANALYSIS 2
===========
2.1 Amazon India wants to understand which payment types are most popular across different 
order value segments (e.g., low, medium, high). Segment order values into three ranges: 
orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. Calculate the count 
of each payment type within these ranges and display the results in descending order of count
Output: order_value_segment, payment_type, count 
*/
SELECT 
CASE
WHEN payment_value < 200 THEN 'Low Value Orders'
WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium Value Orders'
ELSE 'High Value Orders'
END AS order_value_segment,payment_type,
COUNT(payment_type) AS count
FROM amazon_brazil."Payments"
GROUP BY order_value_segment, payment_type
ORDER BY count DESC;

/*
2.2 Amazon India wants to analyse the price range and average price for each product 
category. Calculate the minimum, maximum, and average price for each category, and list 
them in descending order by the average price.
Output: product_category_name, min_price, max_price, avg_price 
*/
SELECT p.product_category_name,
MIN(oi.price) AS min_price,
MAX(oi.price) AS max_price,
ROUND(AVG(oi.price), 2) AS avg_price
FROM amazon_brazil."Product" p
JOIN amazon_brazil."Order Items" oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY avg_price DESC;

/*
2.3 Amazon India wants to identify the customers who have placed multiple orders over time.
Find all customers with more than one order, and display their customer unique IDs along 
with the total number of orders they have placed.
Output: customer_unique_id, total_orders
*/
SELECT c.customer_unique_id,
COUNT(o.order_id) AS total_orders
FROM amazon_brazil."Customers" c
JOIN amazon_brazil."orders" o
ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
HAVING COUNT(o.order_id) > 1
ORDER BY total_orders DESC;

/*
2.4 Amazon India wants to categorize customers into different types ('New–order qty.=1';
'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history. 
Use a temporary table to define these categories and join it with the customers table to 
update and display the customer types.
Output: customer_id, customer_type 
*/
CREATE TEMP TABLE customer_order_counts AS
SELECT customer_id,
COUNT(order_id) AS total_orders
FROM amazon_brazil."orders"
GROUP BY customer_id;
SELECT customer_id,
CASE
WHEN total_orders = 1 THEN 'New'
WHEN total_orders BETWEEN 2 AND 4 THEN 'Returning'
ELSE 'Loyal'
END AS customer_type
FROM customer_order_counts;

/*
2.5 Amazon India wants to know which product categories generate the most revenue. 
Use joins between the tables to calculate the total revenue for each product category. 
Display the top 5 categories.
Output: product_category_name, total_revenue
*/
SELECT p.product_category_name,ROUND(SUM(oi.price), 2) AS total_revenue
FROM amazon_brazil."Product" p
JOIN amazon_brazil."Order Items" oi
ON p.product_id = oi.product_id
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 5;

/*
===========
ANALYSIS 3
===========
3.1 The marketing team wants to compare the total sales between different seasons. 
Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) 
based on order purchase dates, and display the results. Spring is in the months of March, 
April and May. Summer is from June to August and Autumn is between September and November 
and rest months are Winter. 
Output: season, total_sales
*/
SELECT season,ROUND(SUM(oi.price)) AS total_sales
FROM amazon_brazil."Order Items" oi
JOIN (SELECT o.order_id,
CASE
WHEN EXTRACT(MONTH FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS'))IN(3,4,5)
THEN 'Spring'
WHEN EXTRACT(MONTH FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS'))IN(6,7,8)
THEN 'Summer'
WHEN EXTRACT(MONTH FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS'))IN(9,10,11)
THEN 'Autumn'
ELSE 'Winter'
END AS season
FROM amazon_brazil."orders" o)sales ON sales.order_id = oi.order_id
GROUP BY season;

/*
3.2 The inventory team is interested in identifying products that have sales volumes 
above the overall average. Write a query that uses a subquery to filter products with a 
total quantity sold above the average quantity.
Output: product_id, total_quantity_sold
*/
SELECT product_id,
COUNT(order_id) AS total_quantity_sold
FROM amazon_brazil."Order Items"
GROUP BY product_id
HAVING COUNT(order_id) > ( SELECT AVG(total_quantity)
FROM(
SELECT COUNT(order_id) AS total_quantity
FROM amazon_brazil."Order Items"
GROUP BY product_id) AS avg_sales)
ORDER BY total_quantity_sold DESC;

/*
3.3 To understand seasonal sales patterns, the finance team is analysing the monthly 
revenue trends over the past year (year 2018). Run a query to calculate total revenue g
enerated each month and identify periods of peak and low sales. Export the data to Excel 
and create a graph to visually represent revenue changes across the months. 
Output: month, total_revenue
*/
SELECT EXTRACT(MONTH FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS')) AS month,
ROUND(SUM(oi.price)) AS revenue
FROM amazon_brazil."orders" o
JOIN amazon_brazil."Order Items" oi
ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS'))=2018
GROUP BY month
ORDER BY revenue DESC;

/*
3.4 A loyalty program is being designed  for Amazon India. Create a segmentation based on 
purchase frequency: ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, 
and ‘Loyal’ for more than 5 orders. Use a CTE to classify customers and their count and 
generate a chart in Excel to show the proportion of each segment.
Output: customer_type, count
*/
WITH order_total AS (SELECT DISTINCT(customer_id),
COUNT(order_id) AS total_orders 
FROM amazon_brazil."orders"
GROUP BY customer_id )
SELECT
CASE WHEN total_orders BETWEEN 1 AND 2 THEN 'Occassional'
WHEN total_orders BETWEEN 3 AND 5 THEN 'Regular'
ELSE 'Loyal'
END AS customer_type,
COUNT(DISTINCT(customer_id)) AS COUNT
FROM order_total
GROUP BY customer_type
ORDER BY COUNT;

/*
3.5 Amazon wants to identify high-value customers to target for an exclusive rewards 
program. You are required to rank customers based on their average order value 
(avg_order_value) to find the top 20 customers.
Output: customer_id, avg_order_value, and customer_rank
*/
SELECT o.customer_id,
AVG(oi.price) AS avg_order_value,
RANK() OVER(ORDER BY AVG(oi.price) DESC) AS customer_rank
FROM amazon_brazil."orders" o
JOIN amazon_brazil."Order Items" oi
ON o.order_id=oi.order_id
GROUP BY o.customer_id
ORDER BY avg_order_value DESC LIMIT 20;

/*
3.6 Amazon wants to analyze sales growth trends for its key products over their lifecycle.
Calculate monthly cumulative sales for each product from the date of its first sale. 
Use a recursive CTE to compute the cumulative sales (total_sales) for each product month by
month.
Output: product_id, sale_month, and total_sales 
*/
WITH sales AS(
SELECT product_id,
EXTRACT(MONTH FROM TO_TIMESTAMP(
o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS')) AS sale_month,
SUM(oi.price) AS monthly_sales
FROM amazon_brazil."orders" o
JOIN amazon_brazil."Order Items" oi
ON o.order_id = oi.order_id
GROUP BY product_id, sale_month)
SELECT
product_id,sale_month,
round(SUM(monthly_sales)OVER(PARTITION BY product_id ORDER BY sale_month)) AS total_sales
FROM sales
ORDER BY product_id,sale_month;

/*
3.7 To understand how different payment methods affect monthly sales growth, Amazon wants 
to compute the total sales for each payment method and calculate the month-over-month growth
rate for the past year (year 2018). Write query to first calculate total monthly sales for 
each payment method, then compute the percentage change from the previous month.
Output: payment_type, sale_month, monthly_total, monthly_change.
*/
WITH total AS(SELECT p.payment_type,
EXTRACT(MONTH FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS')) AS sale_month,
ROUND(SUM(oi.price)) AS monthly_total
FROM amazon_brazil."Payments" p
JOIN amazon_brazil."orders" o
ON p.order_id = o.order_id
JOIN amazon_brazil."Order Items" oi
ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM 
TO_TIMESTAMP(o.order_purchase_timestamp,'DD/MM/YY HH24:MI:SS'))=2018
GROUP BY p.payment_type, sale_month)
SELECT payment_type,sale_month,monthly_total,
ROUND((monthly_total -LAG(monthly_total)
OVER(PARTITION BY payment_type
ORDER BY sale_month))/LAG(monthly_total)
OVER(PARTITION BY payment_type
ORDER BY sale_month)*100.0,2) AS monthly_change
FROM total
ORDER BY payment_type, sale_month;