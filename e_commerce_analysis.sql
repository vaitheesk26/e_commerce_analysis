create schema portfolio;
use portfolio;


-- Importing data from excel (.csv) through import wizard

select * from e_commerce_data;
describe e_commerce_data;

-- Checking whether is there any null-Values

select count(*) as Null_Values 
from e_commerce_data
where sales Is null;

-- Modify data type (text to date) for Order_date and Ship_Date

alter table e_commerce_data
modify Order_Date date;

alter table e_commerce_data
modify Ship_Date date;

-- Adding new column No_of_Days_to_Ship

alter table e_commerce_data
add No_of_Days_to_Deliver int;

update e_commerce_data
set No_of_Days_to_Deliver = datediff(Ship_Date,Order_Date);



-- ------------------------------------------------------- Business -------------------------------------------------------------------
-- --------------------------------------------------------- Sales --------------------------------------------------------------------

-- 1.Key Performance Indicator's (KPI): What are the aggregated figures for the total sales revenue, total profit, total number of orders and the profit margin percentage?

select  concat('$' ,  format(sum(sales),0)) as Total_Sales,  
        concat('$' ,  format(sum(profit),0)) as Total_Profit,
        format(count(distinct(order_ID)),0) as Total_Orders, 
        concat(round((sum(profit)/sum(sales))*100,2),'%') as Profit_Percentage
from e_commerce_data;

-- 2. Shipping Cost: What is the standard shipping cost per item?

select ship_mode, 
       round(sum(shipping_cost)/sum(quantity),2) as Average_Shipping_Cost_Per_Product, 
       format(sum(sales),2) as Ship_Mode_Sales, 
       count(distinct(order_id)) as Product_Counts
from e_commerce_data
group by ship_mode
order by Average_Shipping_Cost_Per_Product asc ;

-- 3. Product Sub-Category Sales: Which sub-categories are experiencing strong profit, and which ones are lagging behind?
-- Top-Seller based on Profit:

select sub_category,round(sum(sales),2) as Total_Sales,
       round(sum(profit),2) as Total_Profit, 
       sum(quantity) as Units_Sold
from e_commerce_data
group by sub_category
order by Total_Profit desc
Limit 2;

-- Underperforming 

select sub_category,
       round(sum(sales),2) as Total_Sales,
       round(sum(profit),2) as Total_Profit, 
       sum(quantity) as Units_Sold
from e_commerce_data
group by sub_category
order by Total_Profit asc
Limit 3;

-- 4.Sales based on Year: Which year recorded the highest total sales along with their profits?

with  yearly_total_sales as (
select year(order_date) as Sales_Year, 
            round(sum(sales),2) as Total_Sales, 
            round(sum(profit),2) as Total_Profit
from e_commerce_data
group by sales_year
)
select Sales_Year,
       Total_Sales,
       Total_Profit
from yearly_total_sales
order by Total_Sales desc;

-- 5. Sales Trend based on quarterly sales: What is the quarterly sales for each year?

create view Quarterly_sales as
select temp.Order_Year , 
       round(temp.Q1,2) as Quarterly_1,
       round(temp.Q2,2) as Quarterly_2,
       round(temp.Q3,2) as Quarterly_3,
       round(temp.Q4,2) as Quarterly_4
from (select year(e_commerce_data.order_date) as Order_Year,
sum(case
    when Quarter(e_commerce_data.order_date) = 1 then e_commerce_data.sales
    else 0
    end) as Q1,
sum(case
    when Quarter(e_commerce_data.order_date) = 2 then e_commerce_data.sales
    else 0
    end) as Q2,
sum(case
    when Quarter(e_commerce_data.order_date) = 3  then e_commerce_data.sales
    else 0
    end) as Q3,
sum(case
    when Quarter(e_commerce_data.order_date) = 4 then e_commerce_data.sales
    else 0
    end) as Q4
from portfolio.e_commerce_data
group by year(e_commerce_data.order_date)) as temp;

select * 
from Quarterly_sales
order by order_year asc;

-- 6. Monthly Sales: Which months typically see the highest sales every year, and which month consistently experiences the lowest sales annually?

with  monthly_sales as (
      select year(order_date) as Sales_year, 
             monthname(order_date) as Sales_Month, 
             round(sum(sales),2) as Total_Sales, 
             round(sum(profit),2) as Total_Profit
      from e_commerce_data
      group by sales_year,sales_month
)
select sales_year,
       Sales_Month,
       Total_Sales,
       Total_Profit
from monthly_sales
order by sales_year, Total_Sales desc;

-- 7. Delivery Frequency: How many days does it take for products to be delivered?

alter table e_commerce_data
add No_of_Days_to_Deliver int;

update e_commerce_data
set No_of_Days_to_Deliver = datediff(Ship_Date,Order_Date);

select No_of_Days_to_Deliver, 
       count(distinct(order_ID)) as Products
from e_commerce_data
group by No_of_Days_to_Deliver
order by Products desc;
-- ------------------------------------------------------------ Market ----------------------------------------------------------------
-- 1.Market Presence: In how many markets, regions and countries does Cartify operate ?

Select count(distinct(Market)) as Market,
       count(distinct(Region)) as Region, 
       count(distinct(Country)) as Country
from e_commerce_data;

-- 2. Sales and Profit in each market:  What are the total sales and profit in each market?

select Market, 
       round(sum(sales),2) as Sales,  
       round(sum(profit),2) as Profit, 
       count(distinct(country)) as Country
from e_commerce_data
group by Market
order by round(sum(sales)) desc;

-- 3. Growth Rate: Which region has the highest growth rate percentage from 2019–2022?

create view growth_rate_region as 
select temp.Region, 
       (temp.sales_2022 - temp.sales_2019) / temp.sales_2019 AS Growth_Rate,
       temp.Sales,
       temp.Profit,
       temp.Customers
from ( select e_commerce_data.region as Region,
              count(distinct(e_commerce_data.customer_id)) as Customers, 
              round(sum(e_commerce_data.sales),2) as sales, 
              round(sum(e_commerce_data.profit),2) as profit,
sum(case 
    when year (e_commerce_data.order_date)= 2019 then e_commerce_data.sales
    else 0
    end) as sales_2019,
sum(case 
    when year (e_commerce_data.order_date)= 2022 then e_commerce_data.sales
    else 0
    end) AS sales_2022
from portfolio.e_commerce_data
group by e_commerce_data.region) temp;

select Region, 
       concat(round(growth_Rate * 100,2), "%") as Growth_Rate_Percentage, 
       Sales, 
       Profit, 
       Customers
from growth_rate_region
order by cast(Growth_rate_percentage as decimal(10,2)) desc;

-- 4.Segment: What are the total sales and total profit within each customer segment for overall market?

select Segment,  
       round(sum(sales),2) as Sales, 
       round(sum(Profit),2) as Profit,
       rank() over(order by sum(sales) desc) as Ranking
from e_commerce_data
group by segment
order by Sales desc;







