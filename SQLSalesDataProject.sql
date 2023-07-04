---exploring data
Select * from [dbo].[data]

--- analyzing unique value by using Distinct
SELECT distinct STATUS FROM [dbo].[data]
SELECT distinct year_id FROM [dbo].[data]
Select distinct productline FROM[dbo].[data]
select distinct Territory From [dbo].[data]
select distinct Dealsize FROM [dbo].[data]
select distinct territory FROM[dbo].[data]

--Analysis
-- firstly grouping sales by productline 
-- by using aggregate function 

-- syntax
-- select column name,aggregate function
--from table name 
--WHERE condition
--group by column name
--order by aggregate function
-- Productline , which product sales is in top
select productline,SUM(sales) revenue --aggregate function
FROM[dbo].[data]
GROUP BY PRODUCTLINE --column name
ORDER by revenue DESC --aggregate function
-- classic cars was the best productline 

--year id , which year max sale occurred
select year_id,SUM(sales) revenue
FROM[dbo].[data]
group by YEAR_ID
order by revenue DESC
-- 2004 was the best sale year and 2005 was the worst year

-- let's check the sales operated months in 2005
select distinct month_id
FROM[dbo].[data]
WHERE YEAR_ID = 2005

--- now analysis from which dealsize (medium, large and small) we got maximum profit

select dealsize, SUM(sales) revenue
from [dbo].[data]
group by DEALSIZE
order by revenue desc
-- from here we can see that medium dealsize gained more revenue , so company should focus on small dealsize
-- by doing some marketing , to gain more profits 

--what was the best month for sales in a specific year ? how much was earned that month ?

select month_id,SUM(sales) revenue, COUNT(ORDERNUMBER) frequency
FROM[dbo].[data]
where YEAR_ID = 2003 --will check for each year
GROUP by MONTH_ID
ORDER by revenue DESC -- from this Nov is the best month for 2003

select month_id,SUM(sales) revenue, COUNT(ORDERNUMBER) frequency
FROM[dbo].[data]
where YEAR_ID = 2004
GROUP by MONTH_ID
ORDER by revenue DESC -- from this Nov is the best month for 2004

select month_id,SUM(sales) revenue, COUNT(ORDERNUMBER) frequency
FROM[dbo].[data]
where YEAR_ID = 2005
GROUP by MONTH_ID
ORDER by revenue DESC -- from this May is the best month for 2005

-- november seems to be the best month for year 2003 and 2004 , so we will check which product is sold the most


select month_id, productline, SUM(sales) revenue, COUNT(ordernumber) frequency
FROM[dbo].[data]
where YEAR_ID = 2003 and MONTH_ID = 11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY revenue DESC -- classic cars was sold the most in year 2003

--2004
select month_id, productline, SUM(sales) revenue, COUNT(ordernumber) frequency
FROM[dbo].[data]
where YEAR_ID = 2004 and MONTH_ID = 11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY revenue DESC -- classic cars was sold the most in year 2004

-- RFM Analysis 
--recency(how long ago the last purchase was), frequency(how often they purchase) and monetary(how much they spent), 
--is one method of customer segmentation, a process of dividing customers into groups based on similar characteristics. 
--This method can help companies identify their customers who are most likely to respond the marketing campaign
-- check who is the best customer 

-- data points used in RFM analysis by using this dataset
--recency(how long ago their last purchase was) - last order date
--frequency(how often they purchase) - count of total orders
--monetary (how much they spent ) - total spend

-- advance level sql

DROP TABLE if EXISTS #RFM
;with rfm AS
(
select CUSTOMERNAME,
    SUM(SALES) MonetaryValue,
    avg(SALES) AvgMonetaryValue,
    COUNT(ORDERNUMBER) Frequency,
    MAX(ORDERDATE) LastOrderDate,
    (Select MAX(ORDERDATE)FROM[dbo].[data]) MaxOrderDate,
    DATEDIFF(DD,MAX(ORDERDATE),(Select MAX(ORDERDATE) FROM[dbo].[data])) recency
    --DATEDIFF() function returns the difference between two dates.
FROM[dbo].[data]
GROUP BY CUSTOMERNAME
),
-- now we need to convert the 92 records into 4 eaual group or buckets  , to do this we will use window function in sql
--in an aggregate function, a window function calculates on a set of rows. However, a window function does not cause rows to become grouped into a single output row.
--The following query uses the SUM() as a window function. It returns the sum salary of all employees along with the salary of each individual employee:
rfm_calc as
(
select r.*,
    NTILE(4) OVER (order by recency desc) rfm_recency,
    NTILE(4) OVER (order by frequency) rfm_frequency,
    NTILE(4) OVER (order by MonetaryValue) rfm_monetary
from rfm r
)
select c.*,rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
cast(rfm_recency as varchar)+ cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string
into #rfm
from rfm_calc c
--The SQL NTILE() is a window function that allows you to break the result set into a specified number of approximately equal groups, or buckets. It assigns each group a bucket number starting from one. For each row in a group, 
--the NTILE() function assigns a bucket number representing the group to which the row belongs.
--The CAST() function converts a value (of any type) into a specified datatype.

select CUSTOMERNAME,rfm_recency, rfm_frequency, rfm_monetary,
    case
        when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost customers' -- they will b lost customers
        when rfm_cell_string in (133,134,143,244,334,343,344,144) then 'slipping away, cannot lose' -- big spenders who haven't purchased lately
        when rfm_cell_string in (311,411,331) then 'new customers'
        when rfm_cell_string in (222,223,233,322) then 'potential churners'
        when rfm_cell_string in (323,333,321,422,332,432) then 'active'
        when rfm_cell_string in (433,434,443,444) then 'loyal'
    end rfm_segment
from #rfm

-- what product are most often sold ?
select distinct ordernumber ,STUFF(

    (SELECT ','+ productcode -- to get the productcode with the ordernumber 
    FROM[dbo].[data] p
    WHERE ordernumber IN
        (
            select ORDERNUMBER
            FROM (
                  select ORDERNUMBER,COUNT(*) rn
                    FROM[dbo].[data]
                    WHERE [STATUS] = 'SHIPPED'
                    GROUP BY ORDERNUMBER
                )m
                where rn = 3  -- by this we can check whose customer purchased 2 orders
        )
        AND p.ORDERNUMBER = s.ORDERNUMBER
        for xml PATH('')) -- all are appended with comma
        ,1,1,'') Productcodes
FROM[dbo].[data] s
order by 2 DESC





-- To check deep into one of the ordernumber and rn
--select * from [dbo].[data] where ORDERNUMBER = 10411