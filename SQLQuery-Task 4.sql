USE SalesTargetDB;
GO

DROP TABLE IF EXISTS dbo.SalesTarget;
DROP TABLE IF EXISTS dbo.OrderDetails;
DROP TABLE IF EXISTS dbo.ListOrders;
GO

CREATE TABLE dbo.ListOrders (
    OrderID VARCHAR(15) PRIMARY KEY,
    OrderDate DATE NOT NULL,
    CustomerID INT,
    CustomerName VARCHAR(30),
    State VARCHAR(30),
    City VARCHAR(30)
);
GO

CREATE TABLE dbo.OrderDetails (
    OrderID VARCHAR(15) NOT NULL,
    Amount INT,
    Profit INT NOT NULL,
    Quantity INT,
    Category VARCHAR(20) UNIQUE NOT NULL,
    [Sub-Category] VARCHAR(20),
    PRIMARY KEY (OrderID, Category),
    FOREIGN KEY (OrderID) REFERENCES dbo.ListOrders(OrderID)
);
GO

CREATE TABLE dbo.SalesTarget (
    MonthOrderDate DATE,
    Category VARCHAR(20),
    Target INT,
    PRIMARY KEY (Category),
    FOREIGN KEY (Category) REFERENCES dbo.OrderDetails(Category)
);
GO

USE SalesTargetDB;
GO

-- Check row count
SELECT COUNT(*) AS TotalRows FROM dbo.SalesTarget;
GO

-- View all data
SELECT * FROM dbo.SalesTarget;
GO

-- Check for duplicates
SELECT Category, COUNT(*) 
FROM dbo.SalesTarget
GROUP BY Category 
HAVING COUNT(*) > 1;
GO

-- LEFT JOIN: Keep all sales records even if product details missing
SELECT o.OrderID, o.OrderDate, o.CustomerName, d.Amount, d.Category, d.Sub_Category
FROM dbo.ListOrders o
LEFT JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID;
GO

-- RIGHT JOIN: Customers who haven’t purchased
SELECT o.OrderID, o.CustomerName, d.Amount
FROM dbo.ListOrders o
RIGHT JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID;
GO

-- FULL OUTER JOIN: Inspect unmatched rows
SELECT o.OrderID, o.CustomerName, d.Amount
FROM dbo.ListOrders o
FULL OUTER JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID;
GO

-- Handle missing values
UPDATE dbo.OrderDetails
SET Profit = COALESCE(Profit, 0);

-- Ensure proper date formatting
SELECT OrderID, FORMAT(OrderDate, 'yyyy-MM-dd') AS CleanDate
FROM dbo.ListOrders;
GO

-- Remove anomalies (negative sales if invalid)
DELETE FROM dbo.OrderDetails WHERE Amount < 0;
GO

--- Compute total sales and average quantity by category and state
SELECT Category, State,
       SUM(Amount) AS TotalSales,
       AVG(Quantity) AS AvgQuantity
FROM dbo.ListOrders o
JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID
GROUP BY Category, State
ORDER BY TotalSales DESC;
GO

SELECT FORMAT(o.OrderDate, 'yyyy-MM') AS Month,
       SUM(d.Amount) AS MonthlySales
FROM dbo.ListOrders o
JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID
GROUP BY FORMAT(o.OrderDate, 'yyyy-MM') 
ORDER BY Month;
GO

-- Compare actual vs target
SELECT s."MonthOrderDate", s.Category,
       SUM(d.Amount) AS ActualSales,
       s.Target,
       (SUM(d.Amount) - s.Target) AS Variance
FROM dbo.SalesTarget s
LEFT JOIN dbo.ListOrders o ON FORMAT(o.OrderDate, 'yyyy-MM') = s."MonthOrderDate"
LEFT JOIN dbo.OrderDetails d ON o.OrderID = d.OrderID AND d.Category = s.Category
GROUP BY s."MonthOrderDate", s.Category, s.Target;
GO