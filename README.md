# Course Work Data Pipeline

## 1. Business Description

**Flower Shop** is a small shop in London where you can buy indoor plants, trees, seeds, gardening tools, soil, and fertilizers. A gardening equipment rental service is also available. The business works with many suppliers from different countries.

## 2. Model Descriptions

### ER-Schema for OLTP

![ER-Schema for OLTP](ER-schema%20Bachyla.png)

**Script:** `Creation_and_functions_OLTP_Bachyla.sql`

#### Tables and Relationships

1. **Customer**  
   - **Fields**:
     - `customer_id (PK)`: A unique identifier for each customer.  
     - `first_name (Not Null)`: The first name of the customer.  
     - `last_name (Not Null)`: The last name of the customer.  
     - `email (Not Null)`: The email address of the customer.  
     - `phone_number (Not Null)`: The phone number of the customer.  
     - `birth_date (Not Null)`: The birth date of the customer.  
     - `address (Not Null)`: The physical address of the customer.  
     - `postal_code`: The postal code of the customer’s address.

   - **Relationships**:
     - Referenced by the **Orders** and **Rental** tables via `customer_id` (one-to-many relationship).

2. **Supplier**  
   - **Fields**:
     - `supplier_id (PK)`: A unique identifier for each supplier.  
     - `supplier_name (Not Null)`: The name of the supplier.  
     - `contact_phone (Not Null, Unique)`: The supplier’s contact phone.  
     - `contact_email (Not Null, Unique)`: The supplier’s contact email.  
     - `address (Not Null)`: The supplier’s address.  
     - `city (Not Null)`: The city where the supplier is located.  
     - `country (Not Null)`: The country where the supplier is located.

   - **Relationships**:
     - Referenced by the **Product** table via `supplier_id` (one-to-many relationship).

3. **Category**  
   - **Fields**:
     - `category_id (PK)`: A unique identifier for each product category.  
     - `category_name (Not Null, Unique)`: The category name.

   - **Relationships**:
     - Referenced by the **Product** table via `category_id` (one-to-many relationship).

4. **Product**  
   - **Fields**:
     - `product_id (PK)`: A unique identifier for each product.  
     - `product_name (Not Null, Unique)`: The name of the product.  
     - `category_id (FK)`: References `category_id` in **Category**.  
     - `supplier_id (FK)`: References `supplier_id` in **Supplier**.  
     - `price (Not Null)`: The price of the product.  
     - `available_quantity (Not Null)`: The available stock quantity.  
     - `description`: Product description.

   - **Relationships**:
     - Many-to-one with **Supplier** and **Category**.  
     - Referenced by **Orders_detail** and **Rental_detail** (one-to-many relationship).

5. **Orders**  
   - **Fields**:
     - `order_id (PK)`: A unique identifier for each order.  
     - `customer_id (FK)`: References `customer_id` in **Customer**.  
     - `order_date (Not Null)`: The date the order was placed.  
     - `total_price`: The total price of the order.

   - **Relationships**:
     - Many-to-one with **Customer**.  
     - Referenced by **Orders_detail** (one-to-many relationship).

6. **Orders_detail**  
   - **Fields**:
     - `order_detail_id (PK)`: A unique identifier for each order detail.  
     - `order_id (FK)`: References `order_id` in **Orders**.  
     - `product_id (FK)`: References `product_id` in **Product**.  
     - `price (Decimal)`: The price of the product in the order.  
     - `quantity (Not Null)`: The quantity of the product in the order.

   - **Relationships**:
     - Many-to-one with **Orders** and **Product**.

7. **Rental**  
   - **Fields**:
     - `rental_id (PK)`: A unique identifier for each rental.  
     - `customer_id (FK)`: References `customer_id` in **Customer**.  
     - `rental_date (Not Null)`: The date the rental started.  
     - `return_date (Not Null)`: The date the rental ended.  
     - `total_price (Decimal)`: The total price of the rental.

   - **Relationships**:
     - Many-to-one with **Customer**.  
     - Referenced by **Rental_detail** (one-to-many relationship).

8. **Rental_detail**  
   - **Fields**:
     - `rental_detail_id (PK)`: A unique identifier for each rental detail.  
     - `rental_id (FK)`: References `rental_id` in **Rental**.  
     - `product_id (FK)`: References `product_id` in **Product**.  
     - `price (Decimal)`: The price of the product in the rental.  
     - `quantity (Not Null)`: The quantity of the product in the rental.  
     - `days_rented`: The number of days the product was rented.

   - **Relationships**:
     - Many-to-one with **Rental** and **Product**.

#### Summary of Relationships

- One-to-Many:
  - Customer → Orders  
  - Customer → Rental  
  - Supplier → Product  
  - Category → Product  
  - Orders → Orders_detail  
  - Product → Orders_detail  
  - Rental → Rental_detail  
  - Product → Rental_detail  

This schema enables the business to manage and track products, orders, rentals, suppliers, and customers effectively.

### Functions

1. **validate_rental_dates**  
   - **Purpose**: Ensures that `rental_date` is earlier than `return_date` for each rental.

2. **calculate_rental_days**  
   - **Purpose**: Calculates the number of days between `rental_date` and `return_date` (useful for determining rental duration).

---

## 3. Prepare Script to Load CSV Data into the OLTP Database

**Script:** `Insertion_csv_files_Bachyla.sql`

**Function:** `load_data_from_csv`  
- **Purpose**: Automates loading data from multiple CSV files into the OLTP PostgreSQL database.  
- **Parameters**:
  - `customer_file_path (TEXT)`
  - `order_file_path (TEXT)`
  - `order_detail_file_path (TEXT)`
  - `supplier_file_path (TEXT)`
  - `rental_file_path (TEXT)`
  - `rental_detail_file_path (TEXT)`
  - `product_file_path (TEXT)`
  - `category_file_path (TEXT)`

**Function Logic**:

1. **Load Data into Main Tables**  
   Uses `COPY` to load CSV data into each table, expecting comma-delimited CSV with a header row (LATIN1 encoding).

2. **Data Validation and Cleanup**  
   - Email validation (removing invalid emails).  
   - Product validation (removing products with non-positive prices or negative quantities).  
   - Quantity validation (removing non-positive quantities in **Orders_detail** and **Rental_detail**).  
   - Date validation (removing invalid date entries).  
   - Rental date validation (removing rentals that fail `validate_rental_dates`).

3. **Insert Calculated Data**  
   - Calculate `days_rented` using `calculate_rental_days`.  
   - Calculate `price` fields for **Orders_detail** and **Rental_detail**.  
   - Calculate total order price (`total_price`) in **Orders**.

4. **Execution**  
   - Run the function with the CSV file paths as parameters.  
   - Verify the data in each table after execution.

---

## 4. Design Schemas & Create Needed Tables, Indexes

### ER-Schema for OLAP

![ER-Schema for OLAP](ER-schema%20for%20OLAP%20Bachyla.png)

**Script:** `Creation_OLAP_Bachyla.sql`

---

## 5. Prepare Script to Load Data from the OLTP Database to the OLAP Database

**Script:** `Load_data_to_OLAP_Bachyla.sql`  

This script uses PostgreSQL Foreign Data Wrapper (FDW) to connect the OLTP database (`01`) with the OLAP database (`DWH`). Below is an outline:

1. **Install Required Extension**
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgres_fdw;
   ```
2. **Create Foreign Server**
   ```sql
   CREATE SERVER oltp_server
       FOREIGN DATA WRAPPER postgres_fdw
       OPTIONS (host 'localhost', dbname '01', port '5432');
   ```
3. **Create User Mapping**
   ```sql
   CREATE USER MAPPING FOR CURRENT_USER
       SERVER oltp_server
       OPTIONS (user 'postgres', password '159357');
   ```
4. **Import Schema from Foreign Server**
   ```sql
   IMPORT FOREIGN SCHEMA public
   FROM SERVER oltp_server
   INTO public;
   ```
5. **Create Data Transfer Function**
   ```sql
   DROP FUNCTION IF EXISTS transferring_data CASCADE;

   CREATE OR REPLACE FUNCTION transferring_data()
   RETURNS void AS $$
   BEGIN
       -- Data transfer logic here
   END;
   $$
   LANGUAGE plpgsql;
   ```
6. **Data Transfer Operations**  
   - **DimCustomer**: Insert new customers from OLTP avoiding duplicates.  
   - **DimSupplier**: Insert new suppliers from OLTP avoiding duplicates.  
   - **DimCategory**: Insert new categories from OLTP avoiding duplicates.  
   - **DimProduct**: Insert new products (with current_flag, start/end dates) from OLTP avoiding duplicates.  
   - **DimDate**: Insert unique order and rental dates.  
   - **FactSales**: Insert new sales transactions.  
   - **FactRental**: Insert new rental transactions.

7. **Execute the Data Transfer Function**
   ```sql
   SELECT transferring_data();
   ```
8. **Queries to View Data**
   ```sql
   SELECT * FROM DimCustomer;
   SELECT * FROM DimSupplier;
   SELECT * FROM DimCategory;
   SELECT * FROM DimProduct;
   SELECT * FROM DimDate;
   SELECT * FROM FactSales;
   SELECT * FROM FactRental;
   ```

**Summary**  
This script creates a connection to the OLTP database via FDW, imports the schema, and defines a function (`transferring_data`) to insert new records into the dimensional and fact tables of the OLAP database. It helps maintain data integrity and avoids duplicates.

---

## 6. How to Run the Project

1. In PostgreSQL, create two databases: **01** and **DWH**.  
2. Clone the Git repository containing all necessary scripts (initialization, data loading, and datasets).  
3. In the **01** database, run `Creation_and_functions_OLTP_Bachyla.sql` to initialize tables and functions.  
4. Run `Insertion_csv_files_Bachyla.sql` (adjusting file paths to your CSVs). This should create 8 tables according to the OLTP schema.  
5. In the **DWH** database, run `Creation_OLAP_Bachyla.sql` to create tables based on the OLAP schema.  
6. Run `SDC2_changes_Bachyla.sql`.  
7. Update the credentials at the top of `Load_data_to_OLAP_Bachyla.sql` (e.g., host, dbname, port, user, and password). Example:
   ```sql
   CREATE SERVER oltp_server
   FOREIGN DATA WRAPPER postgres_fdw
   OPTIONS (host 'localhost', dbname 'DWH', port '5432');

   CREATE USER MAPPING FOR CURRENT_USER
   SERVER oltp
   OPTIONS (user 'postgres', password 'put_your_password_here');
   ```
8. Run `Load_data_to_OLAP_Bachyla.sql`.  
9. Open the Power BI project (if desired) to visualize or analyze the loaded data.

---

**Thank you for using our FlowerShop Data Pipeline!**  
Feel free to open issues or contribute to this repository. If you have any questions or suggestions, please reach out.
