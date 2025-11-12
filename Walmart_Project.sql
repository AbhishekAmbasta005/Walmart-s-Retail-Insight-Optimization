-- A WALMART PROJECT BY ABHISHEK AMBASTA -- 

-- Project Title: Sales Performance Analysis of Walmart Stores Using Advanced MySQL Techniques. 

-- Business Problem:
-- Walmart wants to optimize its sales strategies by analyzing historical transaction data across branches,
-- customer types, payment methods, and product lines. To achieve this, advanced MySQL queries will be
-- employed to answer challenging business questions related to sales performance, customer segmentation, and product trends.

CREATE DATABASE WALMART_PROJECT;
USE WALMART_PROJECT;
SELECT * FROM WALMARTSALES_DATA;

-- TASK 1: Identifying the Top Branch by Sales Growth Rate (6 Marks).
-- Walmart wants to identify which branch has exhibited the highest sales growth over time. Analyze the total sales
-- for each branch and compare the growth rate across months to find the top performer.

-- From the below Query we can calculate Monthly sales Per Branch :

SELECT Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%y'), '%Y-%m') AS SalesMonth,
Sum(Total) AS MonthlySales
From Walmartsales_data
Group By Branch,SalesMonth;

-- From the below Query we can calculate the Monthly Growth Rate Calculation :

SELECT Branch, SalesMonth, MonthlySales,
LAG(MonthlySales) OVER 
(PARTITION BY Branch ORDER BY SalesMonth) AS PrevMonthSales,
ROUND(IFNULL(
(MonthlySales- LAG(MonthlySales) OVER (PARTITION BY Branch ORDER BY SalesMonth)) /
LAG(MonthlySales) OVER (PARTITION BY Branch ORDER BY SalesMonth) * 100,0),2)
AS GrowthRate
FROM 
(SELECT Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%y'), '%Y-%m') AS SalesMonth,
Sum(Total) AS MonthlySales
From Walmartsales_data
Group By Branch,SalesMonth
)
AS MonthlyData;

-- From the below Query we can calculate the Average Growth Rate per Branch : 

SELECT Branch, ROUND(AVG(GrowthRate), 2) AS AvgGrowthRate
FROM (SELECT Branch,SalesMonth,ROUND(IFNULL(
(MonthlySales - LAG(MonthlySales) OVER (PARTITION BY Branch ORDER BY SalesMonth)) / 
LAG(MonthlySales) OVER (PARTITION BY Branch ORDER BY SalesMonth) * 100, 0), 2) AS GrowthRate,
    
          -- Needed to filter out first month-- 

LAG(MonthlySales) OVER (PARTITION BY Branch ORDER BY SalesMonth) AS PrevMonthSales
FROM (SELECT Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%y'), '%Y-%m') AS SalesMonth,
SUM(Total) AS MonthlySales
FROM Walmartsales_data GROUP BY Branch, SalesMonth) AS MonthlyData) AS GrowthResults
WHERE PrevMonthSales IS NOT NULL
GROUP BY Branch
ORDER BY AvgGrowthRate DESC;


-- Task 2: Finding the Most Profitable Product Line for Each Branch (6 Marks)
-- Walmart needs to determine which product line contributes the highest profit to each branch.The profit margin
-- should be calculated based on the difference between the gross income and cost of goods sold.

-- Answer: the question say Profit margin = gross income − cogs, but lets take example of Invoice ID: '750-67-8428'
-- Profit margin = 26.1415 - 522.83 = -496.6885 
--  This gives us a negative value, which logically makes no financial sense

-- If we're calculating profit margin, the standard formula is: Profit Margin (%)=(Gross Income / COGS )×100
-- So we already have a column named as gross margin percentage that are same for all
-- so we have a column as gross income that is already calculated, we can use that for calculating this.

SELECT Branch, `Product line`, Total_Profit
FROM (SELECT Branch, `Product line`, SUM(`gross income`) AS Total_Profit,
RANK() OVER (
PARTITION BY Branch ORDER BY SUM(`gross income`) DESC) AS Profit_Rank
FROM Walmartsales_Data
GROUP BY Branch, `Product line`)
AS Ranked_Profit
Where Profit_Rank=1;

-- TASK 3: Task 3: Analyzing Customer Segmentation Based on Spending (6 Marks)
-- Walmart wants to segment customers based on their average spending behavior. Classify customers into three
-- tiers: High, Medium, and Low spenders based on their total purchase amounts.

select * from walmartsales_data;

SELECT `Customer ID`, ROUND(TotalSpending, 2) AS TotalSpending,
  CASE WHEN SpendingTier = 1 THEN 'Low'
       WHEN SpendingTier = 2 THEN 'Medium'
       WHEN SpendingTier = 3 THEN 'High'
  END AS SpendingCategory
FROM (SELECT `Customer ID`,SUM(`Total`) AS TotalSpending,
NTILE(3) OVER (ORDER BY SUM(`Total`)) AS SpendingTier
FROM Walmartsales_data
GROUP BY `Customer ID`
) AS Segmented
ORDER BY TotalSpending DESC;


-- Task 4: Detecting Anomalies in Sales Transactions (6 Marks)
-- Walmart suspects that some transactions have unusually high or low sales compared to the average for the
-- product line. Identify these anomalies.

SELECT `Product line`, AVG(`Total`) AS AvgTotal
FROM WalmartSales_data
GROUP BY `Product line`;

-- We will then do the self join operation to compare each transaction's Total to its product line’s average.
-- Also We define anomalies as: Transactions with Total > 150% of average or Total < 50% of average.

SELECT w.`Invoice ID`,w.`Product line`,w.`Total`,avg_tbl.AvgTotal,
CASE
WHEN w.`Total` > avg_tbl.AvgTotal * 1.5 THEN 'High Anomaly'
WHEN w.`Total` < avg_tbl.AvgTotal * 0.5 THEN 'Low Anomaly'
END AS AnomalyType
FROM `Walmartsales_data` w
JOIN (
SELECT `Product line`, AVG(`Total`) AS AvgTotal
FROM WalmartSales_data
GROUP BY `Product line`)
AS avg_tbl
ON w.`Product line` = avg_tbl.`Product line`
WHERE avg_tbl.AvgTotal * 1.5 OR
avg_tbl.AvgTotal * 0.5;

-- Task 5: Most Popular Payment Method by City (6 Marks)
-- Walmart needs to determine the most popular payment method in each city to tailor marketing strategies.

-- Answer : First we will try to count the payment method per city.

SELECT City,Payment, COUNT(*) AS Tansaction_count
FROM Walmartsales_data
GROUP BY City, Payment;

-- Now we will use RANK to find the most-used payment method per city:

SELECT *
FROM (SELECT City,Payment,COUNT(*) AS TransactionCount,
RANK() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS PaymentRank
FROM Walmartsales_data
GROUP BY City, Payment) AS ranked_payments
WHERE PaymentRank = 1
ORDER BY TransactionCount DESC;

-- Task 6: Monthly Sales Distribution by Gender (6 Marks)
-- Walmart wants to understand the sales distribution between male and female customers on a monthly basis.

Select * FROM walmartsales_data;

Select * 
From (Select DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%y'), '%Y-%m') AS SalesMonth, Sum(`Total`) As Total_Sales ,Gender
FROM Walmartsales_Data
GROUP BY SalesMonth, Gender) AS sales_distribution
ORDER BY SalesMonth, Gender;

-- Task 7: Best Product Line by Customer Type (6 Marks)
-- Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal).

SELECT * 
FROM (SELECT `Customer type`, `Product line`, SUM(`Total`) AS Total_Sales,
RANK() OVER (PARTITION BY `Customer type` ORDER BY SUM(`Total`) DESC) AS Top_Product
From Walmartsales_data
GROUP BY `Customer type`, `Product line`) AS Best_Product_Line
WHERE Top_Product = 1
ORDER BY `Customer type`;

-- TASK 8: Identifying Repeat Customers (6 Marks)
-- Walmart needs to identify customers who made repeat purchases within a specific time frame (e.g., within 30 days).

SELECT DISTINCT `Customer ID`
FROM (
SELECT `Customer ID`,STR_TO_DATE(Date, '%d-%m-%Y') AS PurchaseDate,
LAG(STR_TO_DATE(Date, '%d-%m-%Y')) OVER (PARTITION BY `Customer ID` ORDER BY STR_TO_DATE(Date, '%d-%m-%Y')) AS Previous_PurchaseDate
FROM walmartsales_data) AS Customer_dates
WHERE DATEDIFF(PurchaseDate, Previous_PurchaseDate) <=30
AND Previous_PurchaseDate IS NOT NULL;

-- Task 9: Finding Top 5 Customers by Sales Volume (6 Marks)
-- Walmart wants to reward its top 5 customers who have generated the most sales Revenue.

SELECT `Customer ID`,ROUND(SUM(`Total`), 2) AS TotalSpending
FROM Walmartsales_data
GROUP BY `Customer ID`
ORDER BY TotalSpending DESC
LIMIT 5;

-- Task 10: Analyzing Sales Trends by Day of the Week (6 Marks)
-- Walmart wants to analyze the sales patterns to determine which day of the week brings the highest sales.

SELECT DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS DayOfWeek,ROUND(SUM(Total), 2) AS TotalSales
FROM Walmartsales_data
GROUP BY DayOfWeek
ORDER BY TotalSales DESC;

