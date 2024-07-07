create database if not exists walmartsales;

use walmartsales;

create table if not exists sales_w(
invoiceID varchar (30) not null primary key,
branch varchar(5) not null,
city varchar (25) not null,
customer_type varchar(30) not null,
gender varchar (10) not null,
product_line varchar (100) not null,
unit_price decimal (10, 2) not null,
quantity int not null,
VAT float (6, 4) not null,
total decimal(12, 2) not null,
date datetime not null,
time time not null,
payment varchar (30) not null,
COGS decimal (12, 2) not null,
gross_margin_percentage float (10, 5) not null,
gross_income float(10,5) not null,
rating decimal (2,1) not null
);

-- -----------------------------------------------------------------------------------------------------------
-- ----------------------------------------------Feature Engineering------------------------------------------

-- time of day
select 
	time,
	(case
		when `time` between "00:00:00" and "11:59:59" then "Morning"
		when `time` between "12:00:00" and "16:00:00" then "Afternoon"
		else "Evening"
        end) time_of_day
from sales;


alter table sales
add column time_of_day varchar(20) not null;

update sales
set time_of_day = (
case
		when `time` between "00:00:00" and "11:59:59" then "Morning"
		when `time` between "12:00:00" and "16:00:00" then "Afternoon"
		else "Evening"
end
);

-- day_name

select date , dayname(date) 
from sales;

alter table sales
add column day_name varchar(20) not null;

update sales
set day_name = (select dayname(date) );

-- month_name

alter table sales
add column month_name varchar(10) ;

update sales
set month_name = (select monthname(date));

select * from sales;

-- -----------------------------------------------------------------------------------------------------------
-- ---------------------------------------------Generic-------------------------------------------------------

-- How many unique cities does the data have?
select distinct(city)
from sales;

-- In which city is each branch?
select distinct(branch), city
from sales
group by branch, city;

-- -----------------------------------------------------------------------------------------------------------
-- ---------------------------------------------PRODUCT-------------------------------------------------------

-- Before that lets change the column names.
alter table sales
change `Invoice ID` invoice_id varchar(15),
change `Customer type` customer_type varchar(15),
change `Product line` Product_line varchar(100),
change `Unit price` Unit_price decimal(10, 4),
change `Tax 5%` VAT decimal(10, 4),
change `gross margin percentage` gross_margin_percentage float(10, 4),
change `gross income` gross_income float(10, 4),
change `total` total_revenue float(10, 5);

-- How many unique product lines does the data have?	
select distinct(product_line)
from sales;

-- What is the most common payment method?
select payment, count(payment) No_of_occurances
from sales
group by payment
order by No_of_occurances desc
limit 1;

-- What is the most selling product line?
select product_line, count(product_line) cnt from sales
group by product_line
order by cnt desc
limit 1;

-- What is the total revenue by month?
select month_name, sum(total_revenue) total_revenue
from sales
group by month_name
order by total_revenue desc;

-- What month had the largest COGS?
select month_name, sum(cogs) total_cogs
from sales
group by month_name
order by total_cogs desc
limit 1;

-- What product line had the largest revenue?
select product_line products, sum(total_revenue) revenue
from sales
group by products
order by revenue desc
limit 1;

-- What is the city with the largest revenue?
select city, sum(total_revenue) revenue
from sales
group by city
order by revenue desc
limit 1;

-- What product line had the largest VAT?
select product_line, avg(vat) largest_vat
from sales
group by product_line
order by largest_vat desc
limit 1;

-- Fetch each product line and add a column to those product line showing "Good", "Bad". Good if its greater than average sales.
select product_line, average_sales,
(case when total_revenue > average_sales then 'Good'
else 'Bad'
end) as Good_Bad
from (
select product_line, total_revenue, avg(total_revenue) average_sales
from sales
group by product_line, total_revenue) cte
order by average_sales desc;

-- Which branch sold more products than average product sold?
select branch, sum(quantity) quantity
from sales
group by branch
having sum(quantity) > (select avg(quantity) from sales);

-- What is the most common product line by gender?
select gender, product_line, count, ranking
from (select gender,
product_line,
count(product_line) as count,
row_number() over (partition by gender order by count(product_line) desc) as ranking 
from sales
group by gender, product_line) cte
where ranking = 1
order by count desc;

-- What is the average rating of each product line?
select product_line, round(avg(rating),2) as average_rating
from sales
group by product_line
order by average_rating desc;

-- -----------------------------------------------------------------------------------------------------------
-- ---------------------------------------------SALES---------------------------------------------------------

-- Number of sales made in each time of the day per weekday
select day_name, time_of_day, round(count(*), 2) sales
from sales
group by day_name, time_of_day
order by day_name, time_of_day; 

-- Which of the customer types brings the most revenue?
select customer_type, round(sum(total_revenue),2) revenue
from sales
group by customer_type
order by revenue desc;

-- Which city has the largest tax percent/ VAT (Value Added Tax)?
select city, round(max(vat),2) highest_VAT_perc
from sales
group by city
order by highest_VAT_perc desc
limit 3;

-- OR consider the average instead of max VAT--

select city, round(avg(vat),2) highest_VAT_perc
from sales
group by city
order by highest_VAT_perc desc
limit 3;

-- Which customer type pays the most in VAT?
-- on an average
select customer_type, round(avg(vat),2) vat
from sales
group by customer_type
order by vat desc;

-- -----------------------------------------------------------------------------------------------------------
-- ---------------------------------------------CUSTOMER------------------------------------------------------

-- How many unique customer types does the data have?
select distinct(customer_type)
from sales;

-- How many unique payment methods does the data have?
select distinct(payment)
from sales;

-- What is the most common customer type?
select customer_type, count(*) count
from sales
group by customer_type
order by count desc;

-- Which customer type buys the most?
select customer_type, sum(quantity) qty_buy
from sales
group by customer_type
order by qty_buy desc;

-- OR --
select customer_type, count(*) qty_buy
from sales
group by customer_type
order by qty_buy desc;

-- What is the gender of most of the customers?
select gender , count(*) count
from sales
group by gender
order by count desc;

-- What is the gender distribution per branch?
select branch, gender, count(*) count
from sales
group by branch, gender
order by branch, count desc;

-- Which time of the day do customers give most ratings?
SELECT TIME_OF_DAY, round(avg(rating),2) highest_rating
from sales
group by TIME_OF_DAY
order by highest_rating desc;

-- Which time of the day do customers give most ratings per branch?
SELECT branch, TIME_OF_DAY, round(avg(rating),2) highest_rating
from sales
group by branch, TIME_OF_DAY
order by branch, highest_rating desc;

-- Which day fo the week has the best avg ratings?
select day_name, round(avg(rating),2) avg_rating
from sales
group by day_name
order by avg_rating desc;

-- Which day of the week has the best average ratings per branch?
select branch, day_name, avg_rating
from
(select branch, day_name, round(avg(rating),2) avg_rating,
row_number() OVER (partition by branch order by round(avg(rating),2) desc) as ranking
from sales
group by branch, day_name
order by branch, avg_rating desc) cte
where ranking = 1;

select * from sales