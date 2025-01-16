-- Installing the required extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Creating an external server that connects to ‘oltp’
CREATE SERVER oltp_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', dbname '01', port '5432');

-- Creating a custom display for the current user
CREATE USER MAPPING FOR CURRENT_USER
    SERVER oltp_server
    OPTIONS (user 'postgres', password '159357');

-- Importing a schema from an external server
IMPORT FOREIGN SCHEMA public
FROM SERVER oltp_server
INTO public;

DROP FUNCTION IF EXISTS transferring_data CASCADE;

CREATE OR REPLACE FUNCTION transferring_data()
RETURNS void AS $$
BEGIN
    -- Transferring data to DimCustomer
    INSERT INTO DimCustomer (first_name, last_name, email, phone_number, birth_date, address, postal_code)
    SELECT c.first_name, c.last_name, c.email, c.phone_number, c.birth_date, c.address, c.postal_code
    FROM public.customer c
    LEFT JOIN DimCustomer dc ON c.email = dc.email
    WHERE dc.customer_id IS NULL;

    -- Transferring data to DimSupplier
    INSERT INTO DimSupplier (supplier_name, contact_phone, contact_email, address, city, country)
    SELECT s.supplier_name, s.contact_phone, s.contact_email, s.address, s.city, s.country
    FROM public.supplier s
    LEFT JOIN DimSupplier ds ON s.contact_email = ds.contact_email
    WHERE ds.supplier_id IS NULL;

    -- Transferring data to DimCategory
    INSERT INTO DimCategory (category_name)
    SELECT c.category_name
    FROM public.category c
    LEFT JOIN DimCategory dc ON c.category_name = dc.category_name
    WHERE dc.category_id IS NULL;

    -- Transferring data to DimProduct
    INSERT INTO DimProduct (product_name, category_id, supplier_id, price, available_quantity, description, start_date, end_date, current_flag)
    SELECT p.product_name, dc.category_id, ds.supplier_id, p.price, p.available_quantity, p.description, NOW(), '9999-12-31', TRUE
    FROM public.product p
    JOIN public.category c ON p.category_id = c.category_id
    JOIN DimCategory dc ON c.category_name = dc.category_name
    JOIN public.supplier s ON p.supplier_id = s.supplier_id
    JOIN DimSupplier ds ON s.contact_email = ds.contact_email
    LEFT JOIN DimProduct dp ON p.product_name = dp.product_name AND dc.category_id = dp.category_id AND ds.supplier_id = dp.supplier_id
    WHERE dp.product_id IS NULL;

    -- Transferring data to DimDate
    INSERT INTO DimDate (date, day, month, quarter, year)
    SELECT DISTINCT o.order_date, EXTRACT(DAY FROM o.order_date), EXTRACT(MONTH FROM o.order_date), EXTRACT(QUARTER FROM o.order_date), EXTRACT(YEAR FROM o.order_date)
    FROM public.orders o
    LEFT JOIN DimDate dd ON o.order_date = dd.date
    WHERE dd.date IS NULL;
	
	INSERT INTO DimDate (date, day, month, quarter, year)
    SELECT DISTINCT r.rental_date, EXTRACT(DAY FROM r.rental_date), EXTRACT(MONTH FROM r.rental_date), EXTRACT(QUARTER FROM r.rental_date), EXTRACT(YEAR FROM r.rental_date)
    FROM public.rental r
    LEFT JOIN DimDate dd ON r.rental_date = dd.date
    WHERE dd.date IS NULL;

    -- Transferring data to FactSales
    INSERT INTO FactSales (customer_id, product_id, date_id, quantity, total_price)
    SELECT c.customer_id, p.product_id, d.date_id, od.quantity, (od.quantity * p.price) AS total_price
    FROM public.orders o
	JOIN public.orders_detail od ON o.order_id = od.order_id
    JOIN public.customer c ON o.customer_id = c.customer_id
    JOIN public.product p ON od.product_id = p.product_id
    JOIN DimCustomer dc ON c.email = dc.email
    JOIN DimProduct dp ON p.product_name = dp.product_name
    JOIN DimDate d ON o.order_date = d.date
    LEFT JOIN FactSales fs ON c.customer_id = fs.customer_id AND p.product_id = fs.product_id AND d.date_id = fs.date_id
    WHERE fs.sales_id IS NULL;

    -- Transferring data to FactRental
    INSERT INTO FactRental (customer_id, product_id, rental_date_id, quantity, days_rented, total_price)
    SELECT c.customer_id, p.product_id, d.date_id, rd.quantity, rd.days_rented, (rd.quantity * p.price * rd.days_rented) AS total_price
    FROM public.rental r
	JOIN public.rental_detail rd ON r.rental_id = rd.rental_id
    JOIN public.customer c ON r.customer_id = c.customer_id
    JOIN public.product p ON rd.product_id = p.product_id
    JOIN DimCustomer dc ON c.email = dc.email
    JOIN DimProduct dp ON p.product_name = dp.product_name
    JOIN DimDate d ON r.rental_date = d.date
    LEFT JOIN FactRental fr ON c.customer_id = fr.customer_id AND p.product_id = fr.product_id AND d.date_id = fr.rental_date_id
    WHERE fr.rental_id IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT transferring_data();

SELECT * FROM DimCustomer;
SELECT * FROM DimSupplier;
SELECT * FROM DimCategory;
SELECT * FROM DimProduct;
SELECT * FROM DimDate;
SELECT * FROM FactSales;
SELECT * FROM FactRental;
