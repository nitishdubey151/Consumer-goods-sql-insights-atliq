
-- 1. Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.

select market
from dim_customer
where customer= 'Atliq Exclusive' AND region= 'APAC'
order by market;

-- 2. What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields-unique_products_2020, unique_products_2021, percentage_chg

with cte1 as (
select count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year=2020),

cte2 as (
select count(distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year=2021)

select *, ROUND((unique_products_2021-unique_products_2020)/unique_products_2020*100,2) as percentage_chg
from cte1,cte2;

-- 3. Provide a report with all the unique product counts for each segment andsort them in descending order of product counts.
-- The final output contains- 2 fields, segment, product_count

select segment, count(distinct product) as product_count
from dim_product
group by segment
order by product_count desc;

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
-- The final output contains these fields- segment, product_count_2020, product_count_2021, difference

with cte1 as (
select p.segment, count(distinct p.product) as product_count_2020
from dim_product p
join fact_sales_monthly s
on p.product_code=s.product_code
where fiscal_year= 2020
group by segment
order by product_count_2020),

cte2 as (
select p.segment, count(distinct p.product) as product_count_2021
from dim_product p
join fact_sales_monthly s
on p.product_code=s.product_code
where fiscal_year= 2021
group by segment
order by product_count_2021)

select cte1.segment, cte1.product_count_2020, cte2.product_count_2021, 
(product_count_2021- product_count_2020) as difference
from cte1
join cte2
on cte1.segment= cte2.segment
order by cte1.segment;

-- 5. Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields- product_code, product, manufacturing_cost

select p.product_code, p.product, m.manufacturing_cost
from dim_product p
join fact_manufacturing_cost m
on p.product_code= m.product_code
where manufacturing_cost
IN (
select max(manufacturing_cost) from fact_manufacturing_cost
UNION
select min(manufacturing_cost) from fact_manufacturing_cost
)
ORDER BY manufacturing_cost DESC;

-- 6. Generate a report which contains the top 5 customers who received anaverage high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields- customer_code, customer, average_discount_percentage

with cte1 as (
select customer_code, avg(pre_invoice_discount_pct) as a
from fact_pre_invoice_deductions
where fiscal_year= 2021
group by customer_code),

cte2 as(
select customer, customer_code
from dim_customer
where market= "India")

select cte1.customer_code, cte2.customer, round(cte1.a,2) as average_discount_percentage
from cte1
join cte2
on cte1.customer_code=cte2.customer_code
order by average_discount_percentage desc
limit 5;

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns- Month, Year, Gross sales Amount

select monthname(s.date) as month, s.fiscal_year, 
	   round(sum(p.gross_price*s.sold_quantity),2) as gross_sales_amount
from fact_sales_monthly s
join fact_gross_price p
on s.product_code= p.product_code
join dim_customer c
on c.customer_code= s.customer_code
where customer= 'atliq exclusive'
GROUP BY  Month, s.fiscal_year 
ORDER BY s.fiscal_year;

-- 8. In which quarter of 2020, got the maximum total_sold_quantity? 
-- The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity

with cte1 as (
select *,
	case
	   when month(date) in (9,10,11) then "Q1"
       when month(date) in (12,1,2) then "Q2"
       when month(date) in (3,4,5) then "Q3"
       else "Q4"
end as quarter
from fact_sales_monthly
where fiscal_year=2020)

select quarter, sum(sold_quantity) as total_sold_quantity
from cte1
group by quarter
order by total_sold_quantity desc;

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
-- The final output contains these fields- channel, gross_sales_mln, percentage

with cte1 as (
select c.channel, round(sum(g.gross_price*s.sold_quantity/1000000),2) as gross_sales_mln
from fact_sales_monthly s
join fact_gross_price g
on s.product_code=g.product_code
join dim_customer c
on c.customer_code= s.customer_code
where s.fiscal_year=2021
group by channel)

select channel, gross_sales_mln, round(gross_sales_mln*100/sum(gross_sales_mln) over(),2) as percentage
from cte1
order by percentage desc;

-- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
-- The final output contains these- fields, division, product_code, product, total_sold_quantity, rank_order

with cte1 as(
select p.division, p.product_code, p.product, sum(sold_quantity) as total_sold_quantity,
rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
from dim_product p
join fact_sales_monthly s
on p.product_code=s.product_code
where fiscal_year=2021
group by p.product_code, p.division, p.product
)

select *
from cte1
where rank_order in(1,2,3);
