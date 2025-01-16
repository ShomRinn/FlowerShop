-- Create the Customer table
CREATE TABLE Customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(60) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    birth_date DATE,
    address VARCHAR(255) NOT NULL,
    postal_code VARCHAR(15)
);

-- Create the Supplier table
CREATE TABLE Supplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    contact_phone VARCHAR(20) UNIQUE NOT NULL,
    contact_email VARCHAR(60) UNIQUE NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(80) NOT NULL,
    country VARCHAR(60) NOT NULL
);

-- Create the Category table
CREATE TABLE Category (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(60) UNIQUE NOT NULL
);

-- Create the Product table
CREATE TABLE Product (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT UNIQUE NOT NULL,
    category_id INT REFERENCES Category(category_id),
    supplier_id INT REFERENCES Supplier(supplier_id),
    price DECIMAL(10,2) NOT NULL,
    available_quantity INT,
    description TEXT
);

-- Create the Order table
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customer(customer_id),
    order_date DATE NOT NULL,
    total_price DECIMAL(10,2)
);

-- Create the Order_detail table
CREATE TABLE Orders_detail (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES Orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES Product(product_id),
    price DECIMAL(10,2),
    quantity INT NOT NULL
);

-- Create the Rental table
CREATE TABLE Rental (
    rental_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customer(customer_id),
    rental_date DATE NOT NULL,
    return_date DATE NOT NULL,
    total_price DECIMAL(10,2)
);

-- Create the Rental_detail table
CREATE TABLE Rental_detail (
    rental_detail_id SERIAL PRIMARY KEY,
    rental_id INT REFERENCES Rental(rental_id) ON DELETE CASCADE,
    product_id INT REFERENCES Product(product_id),
    price DECIMAL(10,2),
    quantity INT NOT NULL,
    days_rented INT
);

-- Function to check if rental_date is earlier than return_date
CREATE OR REPLACE FUNCTION validate_rental_dates(rental_date DATE, return_date DATE) RETURNS BOOLEAN AS $$
BEGIN
    IF rental_date < return_date THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate the number of rental days
CREATE OR REPLACE FUNCTION calculate_rental_days(rental_date DATE, return_date DATE) RETURNS INT AS $$
BEGIN
    RETURN return_date - rental_date;
END;
$$ LANGUAGE plpgsql;

