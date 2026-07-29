--                                 ===========================================================================================
--                                 **************************** Data Loading and Database creation ****************************
--                                 ============================================================================================

create database if not exists coffee_sales;
use coffee_sales;
show variables like "secure_file_priv";

CREATE TABLE Coffee_Sales (
    transaction_id INT PRIMARY KEY,
    transaction_date DATE NOT NULL,
    transaction_time TIME NOT NULL,
    transaction_qty INT NOT NULL,
    store_id INT NOT NULL,
    store_location VARCHAR(50) NOT NULL,
    product_id INT NOT NULL,
    unit_price DECIMAL(8,2) NOT NULL,
    product_category VARCHAR(50) NOT NULL,
    product_type VARCHAR(100) NOT NULL,
    product_detail VARCHAR(100) NOT NULL,
    unit_cogs DECIMAL(8,2) NOT NULL,
    promotion_type VARCHAR(30),
    discount_amount DECIMAL(8,2) DEFAULT 0.00,
    order_channel VARCHAR(20) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    waiting_time INT NOT NULL COMMENT 'Waiting time in minutes',
    customer_rating DECIMAL(2,1),
    operating_expense DECIMAL(10,2) NOT NULL
);

load data infile "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Coffee_Sales.csv"
into table coffee_sales
fields terminated by ","
lines terminated by "\n"
ignore 1 rows ;

-- Understanding the dataset 
select * from coffee_sales limit 10000;
/*This dataset contains transaction-level sales data from three branches of the same coffee shop chain located in Lower Manhattan, Hell's Kitchen, and Astoria. It includes 
information such as transaction date and time, product details, quantity sold, selling price, COGS, discounts, operating expenses, payment methods, order channels, waiting time,
 customer ratings, and promotions.
 The objective of this project is to analyze sales performance, customer behavior, operational efficiency, and branch-wise performance using SQL.
 The analysis will begin with data exploration and quality checks, followed by KPI calculations, trend analysis, customer and product insights, promotion effectiveness, 
 and operational metrics such as waiting time and customer ratings. Finally, the cleaned and analyzed data will be visualized in Power BI to create an interactive dashboard
 that supports data-driven business decisions. */
desc coffee_sales;

select
count(distinct transaction_id) as Total_transactions,
count(distinct transaction_date) as Operating_days,
count(distinct Branch_name) as Total_Branches,
count(distinct product_category) as Total_product_categories,
count(distinct product_type) as Total_Product_Type,
count(distinct product_detail) as Total_menu_items,
count(distinct promotion_type) as Total_Promition_Type,
count(distinct order_channel) as Total_Order_channels,
count(distinct payment_method) as Total_payment_Methods 
from coffee_sales;

select distinct product_type from coffee_sales;

-- finding duplicate values 
 with duplicate_values as      -- used a CTE's for finding duplicates 
	(select *,row_number()     -- used row_number to assign a unique row number to each records 
    over(partition by   transaction_id,transaction_date,transaction_time,transaction_qty,
    Branch_id,Branch_name,product_id,unit_price,product_category,product_type,product_detail,
    unit_cogs,promotion_type,discount_amount,order_channel,payment_method,waiting_time,
    customer_rating ,operating_expense order by transaction_id)as row_num from coffee_sales)
	select * from duplicate_values where row_num>1; 

-- Null Checks
select * from coffee_sales;
select 
sum(case when transaction_date is null then 1 else 0 end) as null_transaction_date,
sum(case when transaction_time is null then 1 else 0 end) as null_transaction_time,
sum(case when transaction_qty is null then 1 else 0 end) as null_transaction_qty,
sum(case when branch_id is null then 1 else 0 end) as null_branch_id,
sum(case when branch_name is null then 1 else 0 end) as null_branch_name,
sum(case when product_id is null then 1 else 0 end) as null_product_id,
sum(case when unit_price is null then 1 else 0 end) as null_unit_price,
sum(case when product_category is null then 1 else 0 end) as null_product_category,
sum(case when product_type is null then 1 else 0 end) as null_product_type,
sum(case when product_detail is null then 1 else 0 end) as null_product_detail,
sum(case when unit_cogs is null then 1 else 0 end) as null_unit_cogs,
sum(case when promotion_type is null then 1 else 0 end) as null_promotion_type,
sum(case when discount_amount is null then 1 else 0 end) as null_discount_amount,
sum(case when order_channel is null then 1 else 0 end) as null_order_channel,
sum(case when payment_method is null then 1 else 0 end) as null_payment_method,
sum(case when waiting_time is null then 1 else 0 end) as null_waiting_time,
sum(case when customer_rating is null then 1 else 0 end) as null_customer_rating,
sum(case when operating_expense is null then 1 else 0 end) as null_operating_expense
from coffee_sales;

/* Add a new revenue column to store total sales for each transaction */
alter table coffee_sales
add column Revenue decimal(8,2)
after transaction_qty;

/* Calculate revenue = Unit Price × Transaction Quantity */
update coffee_sales 
set revenue=round(unit_price*transaction_qty,2) ;

/* Add a new column to store Total Cost of Goods Sold (COGS) */
alter table coffee_sales
add column total_cogs1 decimal(8,2)
after unit_cogs;

select * from coffee_sales limit 100;

update coffee_sales
set total_cogs=round(unit_cogs*transaction_qty,2);
/* Calculate Total Cost of Goods Sold (COGS) for each transaction. */

/* Add a new profit column to store the profit earned  from each Transaction */
alter table coffee_sales 
add column Profit decimal(8,2)
after total_cogs;

/* 
Calculate profit for each transaction.
Formula:Profit = (Sales Revenue) - (Total COGS + Operating Expense+discount_amount)
*/
update coffee_sales
set profit=round(
(revenue)-(total_cogs+operating_Expense+discount_amount),2);

--  calculate total profit 
select sum(profit) as Sum_of_profit from coffee_sales;

-- Executive Dashboard KPIs:
select 
count(*) as Total_Orders,
sum(transaction_qty) as Total_items_sold,
round(sum(Revenue),2) as Total_Revenue,
round(sum(profit),2) as Total_Profit,
concat(round((sum(profit) / sum(revenue)) * 100, 2),"%") as profit_margin,
round(avg(waiting_time),2) as Avg_Waiting_time,
round(avg(customer_rating),2) as Avg_customer_Rating
from coffee_sales;
/* Summarizes the coffee chain's overall performance using core business metrics
 such as orders, revenue, profit, customer ratings, and average waiting time. */

alter table coffee_sales
change store_id Branch_Id int;

alter table coffee_sales
change store_location Branch_name varchar(20);

select * from coffee_sales;

-- Dates Covered 
select min(transaction_date) as Start_date , max(transaction_date) as End_date  , 
datediff(max(transaction_date) ,min(transaction_date)) as Total_days_Covered from coffee_sales;
/* Insight: The dataset covers a 180-day period from January 1, 2023, to June 30, 2023, providing six months of transactional data 
suitable for analyzing sales trends, seasonal patterns, and branch performance. */

-- maximum, minimum & Average Price of products 
select min(unit_price) as minimum_price , max(unit_price) as maximum_Price ,
round(avg(unit_price),2) as Average_Price  from coffee_sales;
/* Insight: The average selling price is $3.38, with products ranging from $0.80 to $45.00. */

-- Minimum and Maximum and Average Ratings 
select min(customer_rating) as Min_Rating,
max(customer_rating) as Max_rating,
round(avg(customer_rating),2) as Average_Ratings 
from coffee_sales;
/* Insight: The average customer rating of 4.69 reflects a positive customer experience, 
while the narrow rating range (3.8–5.0) suggests consistently high service quality across all branches. */

select * from coffee_sales;

select 
case 
when customer_rating <4.0 then "Need_Improvement(<4.0)"
when customer_rating between 4.0 and 4.4 then "Good(4.0-4.4)"
when customer_rating between 4.5 and 4.7 then "Very Good(4.5-4.7)"
else "Excellent (4.8-5.0)"
end as Rating_Category,
count(*) as Total_orders
from coffee_sales  
group by Rating_Category
order by total_orders desc;
/* Insight: The majority of orders received ratings between 4.5 and 5.0, indicating consistently 
high customer satisfaction across all branches, while less than 1% of orders were rated below 4.0. */

-- Date-wise analysis
select transaction_date,count(transaction_id) as "Total_orders" 
from coffee_sales 
group by transaction_date order by transaction_date;
/* with noticeable fluctuations on certain days, indicating changing
  customer demand and potential peak business periods*/

create view daily_order as
select transaction_date,count(transaction_id) as Total_orders
from coffee_sales
group by transaction_date;
 -- Top 5
select *
from daily_order 
order by total_orders desc
limit 5; 
-- Bottom 5
select *
from daily_order 
group by transaction_date 
order by total_orders asc
limit 5;

-- Month-wise analysis
select date_format(transaction_date,"%Y-%m") as Order_month,
count(transaction_id) as "Total_orders"
from coffee_sales 
group by Order_month
order by Order_month asc;
/* monthly order volume showed an upward trend from March onwards.
 February had fewer orders due to having only 28 days.*/
 
 -- Quarter-wise analysis
select concat("Q",quarter(transaction_date)) as `Quarter`,
count(*) as Total_orders ,
round(sum(unit_price * transaction_qty),2) as Total_Revenue
from  coffee_sales 
group by  `Quarter`
order by `Quarter`;
/* Insight: Q2 outperformed Q1 with 72.27% more orders and significantly higher revenue, 
indicating stronger customer demand in the second quarter. */

select concat(round((442154.72-256657.61)/256657.61*100,2),'%') as Percentage_Increase;  
/* Growth Rate(%) = ((Current Quarter - Previous Quarter) / Previous Quarter) × 100 */

-- Gross_Profit_Margin
select round(((sum(Revenue) - sum(total_cogs))
	/sum(Revenue))*100,2)as gross_profit_margin from coffee_sales;

select * from coffee_sales;

-- Branch Performance
select
    branch_name,
    count(*) as total_orders,
    sum(transaction_qty) as total_items_sold,
    round(sum(revenue), 2) as total_revenue,
    round(sum(profit), 2) as total_profit,
    concat(round(sum(profit)/sum(Revenue)*100,2),"%") as Profit_Margin
from coffee_sales
group by branch_name
order by total_profit desc;

-- Product Category Analysis
select product_category,
count(*) as Total_Orders,
sum(Revenue) as Revenue,
sum(profit) as Profit
from coffee_sales
group by product_category
order by profit desc;

/* Insight:Coffee is the most profitable product category, while Flavours recorded
a loss of $4,768.85, indicating that its pricing or costs may need improvement.
*/

select waiting_time ,
round(avg(customer_rating),1) as Customer_rating
from coffee_sales
group by waiting_time 
order by Customer_rating;
/* Insight:Waiting Time does effect the customer rating  products with wating time of 3 and 5 have 
a average rating of 4.9 and product with waiting time of 12 and 11 have customer ratings of 3.8 and 3.9 */

select * from coffee_sales;

-- **************************** Advanced SQL (Window Functions) ****************************

-- Product_Type Profit ranking
 with Product_Profit as
(select Product_type,
sum(revenue) as Total_Revenue,
sum(profit) as Total_Profit
from coffee_sales
group by Product_type)
select * ,
dense_rank() over(order by Total_profit desc) as Profit_Rank   
from Product_Profit;
/* Insight:Barista Espresso and Brewed Chai Tea are the most profitable product types,
while Regular Syrup recorded the highest loss of $3,554.79. */

-- Promotion Performance Ranking
with promotion as(
select 
Promotion_type,
count(*) as Total_Orders,
sum(Profit) as Total_Profit,
sum(Revenue) as Total_Revenue
from coffee_sales
group by promotion_type)
select * ,
dense_rank() over(order by Total_Revenue desc) as Revenue_Rank
from promotion;
/* Insight:Breakfast Combo is the most profitable promotion, while Bundle Offer generated
the lowest profit and may need improvement.
*/

-- Order Channel Performance
with Channel as
(select
order_channel,
count(*) as Total_Orders,
sum(revenue) as Total_Revenue,
sum(profit) as Total_Profit
from coffee_sales
group by order_channel
)select *,
rank() over(order by Total_Profit desc) as Profit_Rank
from Channel;

/* Insight:The order channel with the highest profit performed better overall,
while the lower-ranked channel may need more promotions to increase sales.*/

-- Payment Method Performance Ranking
with Payment as
(select
payment_method,
count(*) as Total_Orders,
sum(revenue) as Total_Revenue,
sum(profit) as Total_Profit
from coffee_sales
group by payment_method
)select *,
dense_rank() over(order by Total_Revenue desc) as Revenue_Rank
from Payment;
/* Insight:Customers mostly preferred Credit Card payments, whereas Apple Pay was
the least used payment method.*/

-- Revenue contribution by month
with Monthly_Sales as
(select
date_format(transaction_date,"%M") as Order_Month,
sum(revenue) as Total_Revenue
from coffee_sales
group by Order_Month
)select
Order_Month,
Total_Revenue,
concat(round((Total_Revenue/sum(Total_Revenue) over())*100,2),"%") as Revenue_Percentage
from Monthly_Sales
order by Total_Revenue desc;
/* Insight:
Revenue increased steadily over the six-month period, with June generating
the highest revenue contribution and February the lowest because it had
only 28 days.
*/