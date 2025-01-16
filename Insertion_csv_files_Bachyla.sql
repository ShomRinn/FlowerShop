CREATE OR REPLACE FUNCTION load_data_from_csv(
    customer_file_path TEXT,
    order_file_path TEXT,
    order_detail_file_path TEXT,
    supplier_file_path TEXT,
    rental_file_path TEXT,
    rental_detail_file_path TEXT,
    product_file_path TEXT,
    category_file_path TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Load data into main tables
    EXECUTE format('COPY Customer (first_name, last_name, email, phone_number, birth_date, address, postal_code) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', customer_file_path);
    EXECUTE format('COPY Supplier (supplier_name, contact_phone, contact_email, address, city, country) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', supplier_file_path);
    EXECUTE format('COPY Category (category_name) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', category_file_path);
	EXECUTE format('COPY Product (product_name, category_id, supplier_id, price, available_quantity, description) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', product_file_path);
	EXECUTE format('COPY Orders (customer_id, order_date) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', order_file_path);
    EXECUTE format('COPY Orders_detail (order_id, product_id, quantity) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', order_detail_file_path);
    EXECUTE format('COPY Rental (customer_id, rental_date, return_date) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', rental_file_path);
    EXECUTE format('COPY Rental_detail (rental_id, product_id, quantity) FROM %L DELIMITER '','' CSV HEADER ENCODING ''LATIN1''', rental_detail_file_path);
    

    -- Data validation and cleanup
    -- Remove invalid email addresses from Customer and Supplier
    DELETE FROM Customer WHERE email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
    DELETE FROM Supplier WHERE contact_email !~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$';
    
    -- Remove items with invalid product costs or quantities
    DELETE FROM Product WHERE price <= 0;
    DELETE FROM Product WHERE available_quantity < 0;
    DELETE FROM Rental_detail WHERE quantity <= 0;
    DELETE FROM Orders_detail WHERE quantity <= 0;
    
    -- Remove invalid dates
    DELETE FROM Rental WHERE rental_date < '2011-01-01' OR return_date < '2011-01-01';
    DELETE FROM Orders WHERE order_date < '2011-01-01';
    DELETE FROM Customer WHERE birth_date < '1945-01-01';
	
    -- Assuming validate_rental_dates is a valid function
    DELETE FROM Rental WHERE NOT validate_rental_dates(rental_date, return_date);

    -- Insert calculated data
    UPDATE Rental_detail rd
    SET days_rented = calculate_rental_days(r.rental_date, r.return_date)
    FROM Rental r
    WHERE rd.rental_id = r.rental_id;
    
    UPDATE Orders_detail
    SET price = p.price * od.quantity
    FROM Orders_detail od
    JOIN Product p ON od.product_id = p.product_id;
    
	UPDATE Rental_detail
    SET price = p.price * rd.quantity * rd.days_rented
    FROM Rental_detail rd
    JOIN Product p ON rd.product_id = p.product_id;
    
    UPDATE Orders o
    SET total_price = sub.total_price
    FROM (
        SELECT order_id, SUM(price) AS total_price
        FROM Orders_detail
        GROUP BY order_id
    ) sub
    WHERE o.order_id = sub.order_id;
END;
$$ LANGUAGE plpgsql;



-- Call the function with appropriate file paths
SELECT load_data_from_csv('D:/csv/customer.csv', 'D:/csv/order.csv', 'D:/csv/order_detail.csv', 'D:/csv/suppliers.csv', 'D:/csv/rental.csv', 'D:/csv/rental_detail.csv', 'D:/csv/product.csv', 'D:/csv/category.csv');

-- Queries to view data
SELECT * FROM Supplier;
SELECT * FROM Customer;
SELECT * FROM Rental;
SELECT * FROM Rental_detail;
SELECT * FROM Orders;
SELECT * FROM Orders_detail;
SELECT * FROM Category;
SELECT * FROM Product;
