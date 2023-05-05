Question 1
Query 1 
Business meaning :   Total income per month(13 months ) and comparing  with pervious month and then calculating the amount of change in income and the percent and getting the rank of each month , we may need to know what is the most months that gives us so much income than others
Select
    to_char(to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ) AS Month , 
    sum( QUANTITY * PRICE)  as  Total_Income ,
    lag( sum( QUANTITY * PRICE) ) over(ORDER BY TO_DATE(to_char(to_date( INVOICEDATE,'MM/DD/YYYY        HH24:MI'),'MON YYYY' ),'MON YYYY') ASC) as Prev_Total_Income, 
     (sum( QUANTITY * PRICE) -lag( sum( QUANTITY * PRICE) ) over(ORDER BY TO_DATE(to_char(to_date(    INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ),'MON YYYY') ASC)) AS Total_Change,
  round((sum( QUANTITY * PRICE) -lag( sum( QUANTITY * PRICE) ) over(ORDER BY   TO_DATE(to_char(to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ),'MON YYYY') ASC))/
lag( sum( QUANTITY * PRICE) ) over(ORDER BY TO_DATE(to_char(to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ),'MON YYYY') ASC),4) *100  AS percent_CHANGE ,
RANK() OVER(ORDER BY sum( QUANTITY * PRICE) deSC)  AS MONTH_RANK
FROM tableretail
group by to_char(to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ) 
ORDER BY TO_DATE(to_char(to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI'),'MON YYYY' ),'MON YYYY') ASC ;

 



Query 2-

Bussines meaning :  Studying the most hours in the day in terms of the total income and number of invoices  in each hour , then ranking  hours depending on first total income and second on number of invoices   then categorizing the hours  depending on both  invoices_Rank  and Income_Rank to differentiate among the value for each hour  so we may need to increase  customer service agents in these hours  

WITH HOUR_DETAILS1 AS (
select invoice ,  to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI') as date1,sum( QUANTITY * PRICE)  as  Total_Income1 
  from tableretail 
group by invoice ,  to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI')
ORDER BY invoice  ) 
, HOUR_DETAILS2 as (
  select to_char(date1,'HH AM' ) AS HOUR ,sum(Total_Income1 )  as  Total_Income ,count(1) number_of_invoices  ,
  NTILE(3) OVER (ORDER BY count(1)  desc ) AS invoices_Rank ,  NTILE(3) OVER (ORDER BY sum(Total_Income1 )  desc ) AS Income_Rank 
  FROM HOUR_DETAILS1
  group  by to_char(date1,'HH AM' )
      )
   SELECT HOUR , Total_Income ,Income_Rank,  number_of_invoices ,invoices_Rank,   CASE 
             WHEN (Income_Rank ,invoices_Rank) in ((1,1))  THEN 'Platinum Hour'
             WHEN (Income_Rank ,invoices_Rank) in ((1,2),(2,1))  THEN 'Diamond Hour'
            WHEN (Income_Rank ,invoices_Rank) in ((2,2))  THEN 'Gold Hour'
            WHEN (Income_Rank ,invoices_Rank) in ((2,3),(3,2))  THEN 'Silver Hour'
            WHEN (Income_Rank ,invoices_Rank) in ((3,3))  THEN 'Bronze Hour'
    END AS Hour_Category 
  from HOUR_DETAILS2 
    order by  Hour ;


 
Query 3 –

Business meaning : grouping customers into two groups and getting the income and number of custmoers and invoices per group ,The first group contain the most 20% customers in terms of their income and the second group contain the rest of customers (last 80% of customers) , then studying each group to know how much each group participates in the total sales .


with customer_total as (
SELECT customer_id,count(1) as number_of_invoices ,SUM(QUANTITY*PRICE) AS Sales,  
          PERCENT_RANK() OVER (ORDER BY SUM(QUANTITY*PRICE) DESC) AS SalesRank 
      FROM TABLERETAIL
    GROUP BY customer_id ),
    
    category_total as 
    (    select customer_id, Sales  , number_of_invoices,  CASE 
          WHEN SalesRank <= .2  THEN 'Fisrt 20% Group'
          when  SalesRank > .2 then  'Last 80% Group'
    END AS Customer_Category 
    from customer_total )
       
    select Customer_Category,  sum(sales) as total_sales ,count(customer_id) as number_of_customers ,sum(number_of_invoices ) as number_of_invoices,  round(sum(sales)/ sum(sum(sales)) over() ,2 ) as Ratio_to_Total_Sales
    from category_total group by Customer_Category;


 
    






Query4
Business meaning : analyzing the data for each stock code by calculating the total sales , total quantity and number of invoices for each   the totalsales and nmber of invoices for each stockcode  then ranking them in these terms then finding the correlation between the total sales and both number of invoices and total quantity  for each stock code 

SELECT stockcode,
SUM(QUANTITY*PRICE) AS total_Sales,
 RANK() OVER (ORDER BY SUM(QUANTITY*PRICE) DESC) AS Sales_Rank,
 COUNT(1) AS number_of_invoices, 
 RANK() OVER (ORDER BY COUNT(1) DESC) AS invoices_rank,
  round( CORR(COUNT(1), SUM(QUANTITY*PRICE)) OVER (),2) AS invoices_correlation_to_Sales,
sum(quantity) as total_quantity , 
  RANK() OVER (ORDER BY sum(quantity)  DESC) AS Quantity_Rank,
     round(  CORR(sum(quantity), SUM(QUANTITY*PRICE)) OVER (),2)  AS quantity_correlation_to_Sales
FROM TABLERETAIL
GROUP BY stockcode 
ORDER BY total_Sales DESC 
;

 

It sounds like there is a good relationship between the total quantity and total sales , there is also a moderate relationship between total sales and number of invoices.
Query 5
Business meaning : here we study the relation between the customer and the sales and stockcode by calculating the total sales and total number of orders and then getting the most valuable stockcode for each customer(in terms of the income from this stockcode) and getting the number of orders that have this stock.
WITH customer_SALES AS (
  SELECT 
    Customer_ID, SUM(Quantity * Price) AS total_sales,
    COUNT(DISTINCT Invoice) AS total_orders
    FROM tableRetail
  GROUP BY Customer_ID
  order by total_sales desc
   ), CUSTOMER_CODES AS (
 SELECT 
    Customer_ID, 
    STOCKCODE, COUNT(1)  as number_of_orders_for_code,
    SUM(QUANTITY * PRICE ) AS MONEY_PAID_FOR_CODE,
    RANK() OVER (PARTITION BY Customer_ID ORDER BY SUM(QUANTITY * PRICE) DESC) AS RANK1
FROM tableRetail
GROUP BY Customer_ID, STOCKCODE
)
SELECT   S.Customer_ID, S.total_sales,S.total_orders as total_number_of_orders,
 C.STOCKCODE as Most_income_code,  C.MONEY_PAID_FOR_CODE,   c.number_of_orders_for_code
  FROM customer_SALES S
JOIN CUSTOMER_CODES C
ON S.Customer_ID=C.Customer_ID
WHERE C.RANK1=1
order by S.total_sales desc;

 

Q2

 with CUSTOMER_details as (
SELECT CUSTOMER_ID ,
round( max(max( to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI')) ) over() -max( to_date( INVOICEDATE,'MM/DD/YYYY HH24:MI')) ) as recency
,COUNT(distinct(invoice)) AS frequency , sum(quantity*price) as Monetary
        from tableretail
group by CUSTOMER_ID
),
CUSTOMER_ID_SCORE AS (
select CUSTOMER_ID,recency,frequency,Monetary ,  NTILE(5) OVER (ORDER BY recency desc  ) AS recency_score, 
NTILE(5) OVER (ORDER BY (frequency +Monetary)/2   ) AS F_M_score
from CUSTOMER_details
) 
SELECT CUSTOMER_ID ,recency,frequency,Monetary,recency_score, F_M_score, CASE 
          WHEN  recency_score >= 4 AND  F_M_score > 4  THEN 'CHAMPIONS'
          WHEN  ( recency_score , F_M_score)  IN  ((5, 2), (4, 2), (3, 3), (4, 3))  THEN 'Potential Loyalists'
          WHEN  ( recency_score , F_M_score)  IN  ((5, 3), (4, 4), (3, 5), (3,4))  THEN 'Loyal Customers'
          WHEN  ( recency_score , F_M_score)  IN  ((5,1)) THEN 'Recent Customers'
         WHEN  ( recency_score , F_M_score)  IN  ((4, 1), (3,1))  THEN 'Promising'
         WHEN  ( recency_score , F_M_score)  IN  ((3,2), (2,3), (2,2))  THEN 'Customers Needing Attention'
         WHEN  ( recency_score , F_M_score)  IN  ((2,5), (2,4), (1,3))  THEN 'At Risk'
          WHEN  ( recency_score , F_M_score)  IN  ((1,5), (1,4))  THEN  'Cant Lose them'
         WHEN  ( recency_score , F_M_score)  IN  ((1,2))  THEN  'Hibernating'
         WHEN  ( recency_score , F_M_score)  IN  ((1,1))  THEN  'Lost'
        
    END AS Hour_Category 
    FROM CUSTOMER_ID_SCORE
    ORDER BY MONETARY DESC ;
 



Q3
1
SELECT DISTINCT(cust_id), 
       -- Select distinct customer IDs and calculate the maximum consecutive days between transactions for each customer
       (MAX(to_date(INVOICEDATE, 'YYYY-MM-DD')) OVER (PARTITION BY cust_id) 
          - MIN(to_date(INVOICEDATE, 'YYYY-MM-DD')) OVER (PARTITION BY cust_id)) AS MAX_CONSECUTIVE_DAYS
FROM Transactions;
  ;
 












2-
WITH CUST_DETAILS AS( 
SELECT CUST_ID , to_date( INVOICEDATE,'YYYY-MM-DD') INVOICEDATE ,
 SUM(PRICE) OVER (PARTITION BY CUST_ID ORDER BY to_date( INVOICEDATE,'YYYY-MM-DD')   ROWS BETWEEN UNBOUNDED preceding  AND CURRENT ROW ) AS TOTAL_TO_DAY
,  to_date( INVOICEDATE,'YYYY-MM-DD')-min( to_date( INVOICEDATE,'YYYY-MM-DD')) over(partition by CUST_ID ) as days_between ,
count(1) OVER (PARTITION BY CUST_ID ORDER BY to_date( INVOICEDATE,'YYYY-MM-DD')   ROWS BETWEEN UNBOUNDED preceding  AND CURRENT ROW ) AS count_TO_DAY
FROM TRANSACTIONS 
order by CUST_ID  
) ,cust4 as (
select  cust_id, min(count_TO_DAY) number_of_invoices, min(days_between) as days_to_reach_250
 from CUST_DETAILS
where TOTAL_TO_DAY >=250
 group by cust_id
  )  select round(avg(number_of_invoices)) as average_invoices ,round(avg(days_to_reach_250)) as average_days from cust4;

 

