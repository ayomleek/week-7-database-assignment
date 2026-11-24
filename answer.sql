-- =====================================================================
-- DATABASE NORMALIZATION ASSIGNMENT
-- Submission file: answer.sql
-- Tested on: MySQL workbench
-- By Ayom Leek
-- =====================================================================

DROP DATABASE IF EXISTS normalization_assignment;
CREATE DATABASE normalization_assignment;
USE normalization_assignment;


-- =====================================================================
-- QUESTION 1: ACHIEVING FIRST NORMAL FORM (1NF)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Problem:
-- The Products column in ProductDetail stores multiple values in a
-- single cell (e.g. "Laptop, Mouse"). This violates 1NF, which requires
-- every column to hold atomic (single) values.
--
-- Solution:
-- Create a new table where each row holds exactly ONE product for an
-- order. Because OrderID now repeats across rows, the primary key is
-- the composite (OrderID, Product).
-- ---------------------------------------------------------------------

-- Original (unnormalized) table, shown for reference
CREATE TABLE ProductDetail (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Products     VARCHAR(255) NOT NULL
);

INSERT INTO ProductDetail (OrderID, CustomerName, Products) VALUES
(101, 'John Doe',    'Laptop, Mouse'),
(102, 'Jane Smith',  'Tablet, Keyboard, Mouse'),
(103, 'Emily Clark', 'Phone');

-- New table in 1NF: one product per row
CREATE TABLE ProductDetail_1NF (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Product      VARCHAR(100) NOT NULL,
    PRIMARY KEY (OrderID, Product)
);

-- Insert the normalized records (one row per product)
INSERT INTO ProductDetail_1NF (OrderID, CustomerName, Product) VALUES
(101, 'John Doe',    'Laptop'),
(101, 'John Doe',    'Mouse'),
(102, 'Jane Smith',  'Tablet'),
(102, 'Jane Smith',  'Keyboard'),
(102, 'Jane Smith',  'Mouse'),
(103, 'Emily Clark', 'Phone');

-- Verify the result
SELECT * FROM ProductDetail_1NF ORDER BY OrderID, Product;

-- =====================================================================
-- QUESTION 2: ACHIEVING SECOND NORMAL FORM (2NF)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Problem (partial dependency):
-- OrderDetails has the composite primary key (OrderID, Product).
--   OrderID -> CustomerName              (depends on PART of the key)
--   (OrderID, Product) -> Quantity       (depends on the WHOLE key)
-- CustomerName depends only on OrderID, so it is a partial dependency
-- that violates 2NF. It also causes redundancy: "John Doe" is stored
-- twice for order 101, and "Jane Smith" three times for order 102.
--
-- Solution:
-- Decompose OrderDetails into two tables:
--   1. Orders     (OrderID PK, CustomerName)       - order-level data
--   2. OrderItems (OrderID, Product, Quantity)     - item-level data
--      with composite PK (OrderID, Product) and FK OrderID -> Orders.
-- ---------------------------------------------------------------------

-- Original table (already in 1NF), shown for reference
CREATE TABLE OrderDetails (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    Product      VARCHAR(100) NOT NULL,
    Quantity     INT          NOT NULL,
    PRIMARY KEY (OrderID, Product)
);

INSERT INTO OrderDetails (OrderID, CustomerName, Product, Quantity) VALUES
(101, 'John Doe',    'Laptop',   2),
(101, 'John Doe',    'Mouse',    1),
(102, 'Jane Smith',  'Tablet',   3),
(102, 'Jane Smith',  'Keyboard', 1),
(102, 'Jane Smith',  'Mouse',    2),
(103, 'Emily Clark', 'Phone',    1);

-- Step 1: Orders table - each order and its customer stored exactly once
CREATE TABLE Orders (
    OrderID      INT          NOT NULL,
    CustomerName VARCHAR(100) NOT NULL,
    PRIMARY KEY (OrderID)
);

-- Step 2: OrderItems table - products and quantities per order
CREATE TABLE OrderItems (
    OrderID  INT          NOT NULL,
    Product  VARCHAR(100) NOT NULL,
    Quantity INT          NOT NULL,
    PRIMARY KEY (OrderID, Product),
    CONSTRAINT fk_orderitems_orders
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Step 3: Insert the normalized records
-- Orders first (parent table), using DISTINCT to remove the redundancy
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Then OrderItems (child table)
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;

-- Step 4: Verify the result
SELECT * FROM Orders     ORDER BY OrderID;
SELECT * FROM OrderItems ORDER BY OrderID, Product;

-- Verify no information was lost: rejoining reproduces the original data
SELECT o.OrderID, o.CustomerName, oi.Product, oi.Quantity
FROM Orders o
JOIN OrderItems oi ON o.OrderID = oi.OrderID
ORDER BY o.OrderID, oi.Product;
