-- Drop foreign key constraints on product_id in FactSales and FactRental
ALTER TABLE FactSales DROP CONSTRAINT IF EXISTS fk_product_id;
ALTER TABLE FactRental DROP CONSTRAINT IF EXISTS fk_product_id;

-- Remove the existing primary key constraint from DimProduct if it exists
ALTER TABLE DimProduct DROP CONSTRAINT IF EXISTS DimProduct_pkey CASCADE;

-- Add a unique constraint to product_id in DimProduct
ALTER TABLE DimProduct ADD CONSTRAINT DimProduct_product_id_ukey UNIQUE (product_id);

-- Add new columns for SCD Type 2
ALTER TABLE DimProduct
ADD COLUMN IF NOT EXISTS productHistory_ID SERIAL PRIMARY KEY,
ADD COLUMN IF NOT EXISTS start_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS end_date TIMESTAMP,
ADD COLUMN IF NOT EXISTS current_flag BOOLEAN DEFAULT TRUE;

-- Initialize the new columns for existing records
UPDATE DimProduct
SET start_date = NOW(),
    end_date = '9999-12-31',
    current_flag = TRUE
WHERE start_date IS NULL OR end_date IS NULL OR current_flag IS NULL;

-- Drop the old update trigger function if it exists
DROP FUNCTION IF EXISTS DimProduct_update_trigger() CASCADE;

-- Create the new update trigger function
CREATE OR REPLACE FUNCTION DimProduct_update_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if any relevant field is being updated
    IF (OLD.product_name <> NEW.product_name OR
        OLD.category_id <> NEW.category_id OR
        OLD.supplier_id <> NEW.supplier_id OR
        OLD.price <> NEW.price OR
        OLD.available_quantity <> NEW.available_quantity OR
        OLD.description <> NEW.description) AND OLD.current_flag AND NEW.current_flag THEN
        
        -- Set the end_date of the old record
        UPDATE DimProduct
        SET end_date = CURRENT_TIMESTAMP,
            current_flag = FALSE
        WHERE productHistory_ID = OLD.productHistory_ID;

        -- Insert a new record with updated values
        INSERT INTO DimProduct (
            product_id, product_name, category_id, supplier_id, price, available_quantity, description, start_date, end_date, current_flag
        )
        VALUES (
            OLD.product_id, NEW.product_name, NEW.category_id, NEW.supplier_id, NEW.price, NEW.available_quantity, NEW.description, CURRENT_TIMESTAMP, '9999-12-31', TRUE
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the old trigger if it exists
DROP TRIGGER IF EXISTS DimProduct_update ON DimProduct CASCADE;

-- Create the new trigger
CREATE TRIGGER DimProduct_update
AFTER UPDATE ON DimProduct
FOR EACH ROW
EXECUTE FUNCTION DimProduct_update_trigger();

-- Recreate foreign key constraints with the new primary key
ALTER TABLE FactSales
ADD CONSTRAINT FactSales_product_id_fkey
FOREIGN KEY (product_id) REFERENCES DimProduct(product_id);

ALTER TABLE FactRental
ADD CONSTRAINT FactRental_product_id_fkey
FOREIGN KEY (product_id) REFERENCES DimProduct(product_id);

-- Example update to DimProduct to trigger the SCD Type 2 logic
UPDATE DimProduct
SET
    product_name = 'New Product Name',
    category_id = (SELECT category_id FROM DimCategory WHERE category_name = 'seeds'),
    supplier_id = (SELECT supplier_id FROM DimSupplier WHERE supplier_name = 'Garden Treasures'),
    price = 4.99,
    available_quantity = 100,
    description = 'Updated description'
WHERE
    product_id = (SELECT product_id FROM DimProduct WHERE product_name = 'Basil Seeds')
    AND current_flag = TRUE;
