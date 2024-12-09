-- # Solving Business Problems :->>> 

--select distinct geolocation_state from geolocation

select geolocation_lng,count(*) from geolocation
group by geolocation_lng
having count(*) > 1

--#) Data type of all columns in the "customers" table.

SELECT *, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'customers' 
      AND TABLE_SCHEMA = 'dbo';

-- #)Get the time range between which the orders were placed.
SELECT 
    MIN(order_purchase_timestamp) AS EarliestOrderDate,
    MAX(order_purchase_timestamp) AS LatestOrderDate
FROM Orders;

--#) Count the cities & states of customers who ordered during the given period.

select * from customers
select * from orders

select count(distinct c.customer_city) as city_count, count(distinct c.customer_state) as state_count
from customers c
inner join orders o on c.customer_id = o.customer_id
where o.order_purchase_timestamp between '2016-09-04 21:15:19.0000000' and '2018-10-17 17:30:18.0000000'

-- #)Identify trends in the number of orders placed over the years.

select datepart(year,order_purchase_timestamp) as order_year, count(*) as number_of_orders
from orders
group by datepart(year,order_purchase_timestamp)

-- #) Detect any monthly seasonality in the number of orders.

select datepart(year,order_purchase_timestamp) as order_year, datepart(month,order_purchase_timestamp) as order_month, 
count(*) as number_of_orders
from orders
group by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp)
order by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp)

-- #) Determine the time of day when Brazilian customers mostly place orders (Dawn, Morning, Afternoon, or Night).

select * from customers

select case when DATEPART(hour,order_purchase_timestamp) >= 0 and DATEPART(hour,order_purchase_timestamp) < 6 then 'Dawn'
when DATEPART(hour,order_purchase_timestamp) >= 6 and DATEPART(hour,order_purchase_timestamp) < 12 then 'Morning'
when DATEPART(hour,order_purchase_timestamp) >=12 and DATEPART(hour,order_purchase_timestamp) < 18 then 'Afternoon'
else 'Night' end as Time_of_day,
count(*) as number_of_orders
from orders o
group by case when DATEPART(hour,order_purchase_timestamp) >= 0 and DATEPART(hour,order_purchase_timestamp) < 6 then 'Dawn'
when DATEPART(hour,order_purchase_timestamp) >= 6 and DATEPART(hour,order_purchase_timestamp) < 12 then 'Morning'
when DATEPART(hour,order_purchase_timestamp) >=12 and DATEPART(hour,order_purchase_timestamp) < 18 then 'Afternoon'
else 'Night' end

-- #) Month-on-month number of orders placed in each state.

select datepart(year,order_purchase_timestamp) as order_year, datepart(month,order_purchase_timestamp) as order_month, 
 c.customer_state, count(*) as total_orders
from orders o
inner join customers c on c.customer_city = c.customer_city
group by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp), c.customer_state
order by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp), c.customer_state

-- #) Distribution of customers across all states.

SELECT customer_state, COUNT(*) AS customer_count
FROM customers
GROUP BY customer_state
ORDER BY customer_count DESC;

-- #) Analyze money movement by looking at order prices, freight, and other factors.

select * from order_items

select order_id,sum(price) as total_revenue, sum(freight_value) as total_freight_cost,
sum(price+freight_value) as total_order_cost, sum(price-freight_value) as total_net_profit
from order_items 
group by order_id
order by total_net_profit desc

-- the above query is analysis(money movement) for each order_id of customer table
--likwewise we can also achieve the money movement over time,by region(state,city,etc)

-- #) Calculate the percentage increase in the cost of orders from 2017 to 2018 (Jan-Aug).

select * from orders
select * from order_items


with order_costs as (
select datepart(year,order_purchase_timestamp) as order_year, datepart(month,order_purchase_timestamp) as order_month, 
sum(i.price + i.freight_value )as total_order_cost
from orders o
inner join order_items i on o.order_id = i.order_id
where datepart(month,order_purchase_timestamp) between 1 and 8
group by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp) ) ,
cte as (
select 
sum(case when order_year = 2017 then total_order_cost else 0 end) as total_cost_2017,
sum(case when order_year = 2018 then total_order_cost else 0 end) as total_cost_2018
from order_costs )
select total_cost_2017,total_cost_2018
,round(((total_cost_2018 - total_cost_2017) / total_cost_2017 * 100),2) as percentage_increase
from cte

-- #) Calculate the total & average value of order prices and freight for each state.

select c.customer_state, sum(o.price) as total_order_price, avg(o.price) as avg_order_price,
sum(o.freight_value) as total_freight_value, avg(o.freight_value) as avg_freight_value
from order_items o
inner join orders o2 on o.order_id = o2.order_id
inner join customers c on c.customer_id = o2.customer_id
group by c.customer_state
order by c.customer_state

-- #) Calculate the delivery time and the difference between estimated and actual delivery dates

select * from orders

select order_id, DATEDIFF(day,order_purchase_timestamp,order_delivered_customer_date) as delivery_time,
DATEDIFF(day, order_delivered_customer_date, order_estimated_delivery_date) as diff
from orders
where order_delivered_customer_date is not null

select order_id, DATEADD(day,datediff(day,order_purchase_timestamp,order_delivered_customer_date),cast('1900-01-01' as datetime)) as delivery_time
from orders
where order_delivered_customer_date is not null

--convert varchar into 108 

-- #) Identify the top 5 states with the highest & lowest average freight values.

select * from customers	
select * from order_items


select * from (
select top 5 c.customer_state, avg(o.freight_value) as avg_freight_value
from order_items o
inner join orders o2 on o.order_id = o2.order_id
inner join customers c on c.customer_id = o2.customer_id
group by c.customer_state 
order by avg_freight_value desc
union 
select top 5 c.customer_state, avg(o.freight_value) as avg_freight_value
from order_items o
inner join orders o2 on o.order_id = o2.order_id
inner join customers c on c.customer_id = o2.customer_id
group by c.customer_state 
order by avg_freight_value asc ) combined_result
order by avg_freight_value desc


-- #) Identify the top 5 states with the highest & lowest average delivery times.


select  top 5 c.customer_state, avg(DATEDIFF(day,o.order_purchase_timestamp,o.order_delivered_customer_date)) as delivery_time
from orders o
inner join customers c on c.customer_id = o.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by delivery_time desc

select  top 5 c.customer_state, avg(DATEDIFF(day,o.order_purchase_timestamp,o.order_delivered_customer_date)) as delivery_time
from orders o
inner join customers c on c.customer_id = o.customer_id
where o.order_delivered_customer_date is not null
group by c.customer_state
order by delivery_time asc

-- #) Identify the top 5 states where delivery is faster than the estimated date.
--This condition ensures that we are only considering orders where the actual delivery date is earlier than the estimated delivery date.

select * from customers		
select * from orders

select  top 5 c.customer_state, count(o.order_id) as faster_delivery_count
from orders o
inner join customers c on c.customer_id = o.customer_id
where o.order_delivered_customer_date < o.order_estimated_delivery_date and
o.order_delivered_customer_date is not null and o.order_estimated_delivery_date is not null
group by c.customer_state
order by faster_delivery_count desc

-- #) Month-on-month number of orders placed using different payment types.

select datepart(year,order_purchase_timestamp) as order_year, datepart(month,order_purchase_timestamp) as order_month, 
p.payment_type, count(*) as total_orders
from orders o
inner join payments p on o.order_id = p.order_id
group by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp), p.payment_type
order by datepart(year,order_purchase_timestamp), datepart(month,order_purchase_timestamp), p.payment_type

select * from payments
select * from orders

-- #) Number of orders based on payment installments.

select payment_installments, count(order_id) as order_count
from payments
group by payment_installments
order by order_count desc

-------------------------=====================----------------------=====================--------------------

