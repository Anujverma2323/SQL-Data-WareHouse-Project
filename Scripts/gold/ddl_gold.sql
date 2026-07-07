/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================

Script Purpose:
    This script creates views for the Gold layer in the data warehouse.
    The Gold layer represents the final dimension and fact tables (Star Schema).

    Each view performs transformations and combines data from the Silver layer
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

===============================================================================
*/

CREATE VIEW gold.dim_customers AS 

SELECT 
     ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
ci.cst_id AS Customer_id,
ci.cst_key AS Customer_number,
ci.cst_firstname AS First_name,
ci.cst_lastname AS Last_name,
la.cntry AS country,
ci.cst_material_status AS marital_Status,

CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the master for gender integration
     ELSE COALESCE(ca.gen, 'n/a')
END AS new_gen,
ci.cst_create_date AS create_date,
ca.bdate AS Birthdate


FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_az12 ca
ON        ci.cst_key = ca.cid
LEFT JOIN Silver.erp_loc_a101 la
ON        ci.cst_key = la.cid

CREATE VIEW gold.dim_products AS 
SELECT 
 ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
pc.cat AS category,
pc.subcat AS subcategory,
pc.maintenance ,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS Start_date
FROM Silver.crm_prd_info pn
LEFT JOIN Silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL -- Filter out all historical data


USE DataWarehouse;
GO
CREATE VIEW gold.fact_sales AS
SELECT 
sd.sls_ord_num AS order_number ,
pr.product_key,
cu.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM Silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id




