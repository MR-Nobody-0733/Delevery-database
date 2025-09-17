/*
Name: Yash Chaudhari
Date: 06 April, 2024
*/

-- Creating Customer Table
CREATE TABLE Customer (
    customer_id INT NOT NULL,
    first_name NVARCHAR(15) NOT NULL,
    last_name NVARCHAR(15)NOT NULL,
	street_address NVARCHAR(30)NOT NULL,
	city  NVARCHAR(20)NOT NULL,
	postal_code NVARCHAR(7)NOT NULL,
    phone NVARCHAR(15) NOT NULL,
    email NVARCHAR(30),
    CONSTRAINT PK_Customer 
		PRIMARY KEY (customer_id)
);

-- Creating Driver Table
CREATE TABLE Driver (
	driver_id INT NOT NULL,
	full_name NVARCHAR(30)NOT NULL,
	license_number NVARCHAR(15)NOT NULL,
	phone NVARCHAR(15)NOT NULL,
	CONSTRAINT PK_Driver 
		PRIMARY KEY (driver_id)
);

-- Creating the Truck table
CREATE TABLE Truck (
	truck_id INT NOT NULL,
	truck_capacity NVARCHAR(6)NOT NULL,
	license_plate NVARCHAR(8)NOT NULL,
	current_status NVARCHAR(20)NOT NULL,
	CONSTRAINT PK_Truck 
		PRIMARY KEY (truck_id)
);

-- Creating the Warehouse table
CREATE TABLE Warehouse (
    warehouse_id INT NOT NULL,
    location NVARCHAR(50)NOT NULL,
    capacity NVARCHAR(10)NOT NULL,
    truck_id INT NOT NULL,
	CONSTRAINT PK_Warehouse 
		PRIMARY KEY (warehouse_id),
    CONSTRAINT FK_Warehousen_Truck 
		FOREIGN KEY (truck_id) REFERENCES Truck(truck_id)
);

-- Creating the Delivery table
CREATE TABLE Delivery (
    delivery_id INT NOT NULL ,
    delivery_address NVARCHAR(30) NOT NULL,
	delivery_city NVARCHAR(20) NOT NULL,
    delivery_postal_code NVARCHAR(7) NOT NULL,
    delivery_date DATE NOT NULL,
    cost DECIMAL(10,2) NOT NULL,
    delivery_weight DECIMAL(5,2) NOT NULL,
    delivery_package NVARCHAR(3) NOT NULL,
    status NVARCHAR(18),   
    customer_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    truck_id INT NOT NULL,
    driver_id INT NOT NULL,
	CONSTRAINT PK_Delivery 
		PRIMARY KEY (delivery_id),
    CONSTRAINT FK_Delivery_Customer 
		FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    CONSTRAINT FK_Delivery_Warehouse 
		FOREIGN KEY (warehouse_id) REFERENCES Warehouse(warehouse_id),
    CONSTRAINT FK_Delivery_Truck 
		FOREIGN KEY (truck_id) REFERENCES Truck(truck_id),
    CONSTRAINT FK_Delivery_Driver 
		FOREIGN KEY (driver_id) REFERENCES Driver(driver_id),

--Adding the Check 
	CONSTRAINT CHK_Cost
		CHECK (Cost >= 0),
);

--Adding 2 indexes 

--Q1 index
CREATE NONCLUSTERED INDEX INDEX_Delivery_Customer_Date
ON Delivery (customer_id, delivery_date);

--Q2 index
CREATE NONCLUSTERED INDEX INDEX_Driver_License
ON Driver(license_number);

--Adding trigger
CREATE OR ALTER TRIGGER TRG_Delivery
ON Delivery
AFTER INSERT,UPDATE
AS
BEGIN
	DECLARE @MaxWeightKg DECIMAL(5,2) = 500.00;
	SET NOCOUNT ON;

	IF EXISTS(
	SELECT 1 FROM INSERTED	
	WHERE delivery_weight > @MaxWeightkg
	)
	BEGIN
		RAISERROR('Weight limit exceeded 500kg', 16,1);
		ROLLBACK TRANSACTION;
	END;
END;

--Adding function 
CREATE OR ALTER FUNCTION ufn_IsAVALABLETRUCKS(
      @truck_id INT
)
RETURNS NVARCHAR(3) -- YES OR NO
AS
BEGIN
	DECLARE @status NVARCHAR(20);
	DECLARE @result NVARCHAR(3) = 'NO';

	 -- Get the truck's current status
	  SELECT @status = current_status
	  FROM Truck
	  WHERE truck_id = @truck_id;


	   -- Check availability
    IF @status = 'Available'
        SET @result = 'Yes';
	ELSE
		SET @result = 'NO'

	RETURN @result;
END;

--Adding Stored Procedure.
CREATE OR ALTER PROCEDURE usp_GetDeliveryCustomer
	@Delivery_ID INT
AS
BEGIN
--  check if delevery exist
	IF NOT EXISTS(
		SELECT 1 FROM Delivery 
		WHERE delivery_id = @Delivery_ID)
		BEGIN
			RAISERROR('Delivery ID does not exist', 16, 1);
			RETURN;
		END;	

-- Get delivery details
	SELECT
		c.customer_id,
		c.first_name + c.last_name AS customer_name,
		c.phone,
		d.delivery_address,
		d.delivery_city
	FROM Delivery d
	JOIN Customer c ON d.customer_id = c.customer_id
	WHERE d.delivery_id = @Delivery_ID;

	PRINT('Retrieved information for Delivery '+ CAST(@Delivery_ID AS VARCHAR));
END;


--Testing indexes 
SELECT delivery_id, delivery_date, cost
FROM Delivery
WHERE customer_id = 73 AND delivery_date = '2025-01-16';

SELECT driver_id, full_name
FROM Driver
WHERE license_number = '85259';

-- Testing TRIGGER AND CHECK constrain
INSERT INTO Delivery (delivery_id, delivery_address, delivery_city, delivery_postal_code,
                      delivery_date, cost, delivery_weight, delivery_package, status,
                      customer_id, warehouse_id, truck_id, driver_id)
VALUES (555, '789 Heavy St', 'Winnipeg', 'R3C3C3', '2025-04-14', 199.99, 600.00, '2', 'Cancelled',
        1, 1, 1, 1);

		INSERT INTO Delivery (delivery_id, delivery_address, delivery_city, delivery_postal_code,
                      delivery_date, cost, delivery_weight, delivery_package, status,
                      customer_id, warehouse_id, truck_id, driver_id)
VALUES (600, '789 Heavy St', 'Winnipeg', 'R3C3C3', '2025-04-14', -10, 600.00, '2', 'Cancelled',
        1, 1, 1, 1);

--Testing function
SELECT dbo.ufn_IsAVALABLETRUCKS(1) 
AS TruckAvailable;

SELECT dbo.ufn_IsAVALABLETRUCKS(2) 
AS TruckAvailable;

-- Testing Stored Procedure.
EXEC usp_GetDeliveryCustomer @Delivery_ID = 1;









