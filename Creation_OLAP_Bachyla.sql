-- Create the Customer dimension table
CREATE TABLE DimCustomer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(60) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    birth_date DATE NOT NULL,
    address VARCHAR(255) NOT NULL,
    postal_code VARCHAR(15) 
);

-- Create the Supplier dimension table
CREATE TABLE DimSupplier (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    contact_phone VARCHAR(20) NOT NULL UNIQUE,
    contact_email VARCHAR(60) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(80) NOT NULL,
    country VARCHAR(60) NOT NULL
);

-- Create the Category dimension table
CREATE TABLE DimCategory (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(60) NOT NULL UNIQUE
);

-- Create the Product dimension table
CREATE TABLE DimProduct (
    product_id SERIAL PRIMARY KEY,
    product_name TEXT NOT NULL UNIQUE,
    category_id INT,
    supplier_id INT,
    price DECIMAL(10, 2) NOT NULL,
    available_quantity INT NOT NULL,
    description TEXT,
    CONSTRAINT fk_category_id FOREIGN KEY (category_id) REFERENCES DimCategory(category_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_supplier_id FOREIGN KEY (supplier_id) REFERENCES DimSupplier(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Create indexes for foreign keys in the DimProduct table
CREATE INDEX idx_dim_product_category_id ON DimProduct(category_id);
CREATE INDEX idx_dim_product_supplier_id ON DimProduct(supplier_id);

-- Create the Date dimension table
CREATE TABLE DimDate (
    date_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day INT,
    month INT,
    quarter INT,
    year INT
);

-- Create the Sales fact table
CREATE TABLE FactSales (
    sales_id SERIAL PRIMARY KEY,
    customer_id INT,
    product_id INT,
    date_id INT,
    quantity INT NOT NULL,
    total_price DECIMAL(10, 2),
    CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES DimCustomer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES DimProduct(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_date_id FOREIGN KEY (date_id) REFERENCES DimDate(date_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create indexes for foreign keys in the FactSales table
CREATE INDEX idx_fact_sales_customer_id ON FactSales(customer_id);
CREATE INDEX idx_fact_sales_product_id ON FactSales(product_id);
CREATE INDEX idx_fact_sales_date_id ON FactSales(date_id);

-- Create the Rental fact table
CREATE TABLE FactRental (
    rental_id SERIAL PRIMARY KEY,
    customer_id INT,
    product_id INT,
    rental_date_id INT,
    quantity INT NOT NULL,
    days_rented INT,
    total_price DECIMAL(10, 2),
    CONSTRAINT fk_customer_id FOREIGN KEY (customer_id) REFERENCES DimCustomer(customer_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES DimProduct(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rental_date_id FOREIGN KEY (rental_date_id) REFERENCES DimDate(date_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Create indexes for foreign keys in the FactRental table
CREATE INDEX idx_fact_rental_customer_id ON FactRental(customer_id);
CREATE INDEX idx_fact_rental_product_id ON FactRental(product_id);
CREATE INDEX idx_fact_rental_rental_date_id ON FactRental(rental_date_id);
