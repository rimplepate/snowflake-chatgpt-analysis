-- Create a new warehouse (you can skip if you already have one)
CREATE OR REPLACE WAREHOUSE my_wh
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE;

-- Create a database
CREATE OR REPLACE DATABASE chatgpt_db;

-- Create a schema
CREATE OR REPLACE SCHEMA chatgpt_schema;

-- Use them
USE WAREHOUSE my_wh;
USE DATABASE chatgpt_db;
USE SCHEMA chatgpt_schema;

CREATE OR REPLACE TABLE chatgpt_data (
    Category STRING,
    Subcategory STRING,
    Item STRING,
    Date STRING,
    Value STRING,
    Notes STRING
);

CREATE OR REPLACE STAGE chatgpt_stage;

SELECT * FROM chatgpt_data LIMIT 10;

-- Create a cleaned numeric column
CREATE OR REPLACE TABLE chatgpt_data_cleaned AS
SELECT
    Category,
    Subcategory,
    Item,
    TRY_TO_DATE(Date, 'DD-Mon-YY') AS Date_converted,
    Value,
    TRY_TO_DOUBLE(REGEXP_SUBSTR(REPLACE(REPLACE(REPLACE(Value, '$', ''), ',', ''), '%', ''), '[-+]?\\d*\\.?\\d+')) AS Value_numeric,
    COALESCE(Notes, 'No notes') AS Notes
FROM chatgpt_data;

SELECT
    Category,
    COUNT(Value_numeric) AS count_values,
    SUM(Value_numeric) AS sum_values,
    AVG(Value_numeric) AS avg_value
FROM chatgpt_data_cleaned
GROUP BY Category
ORDER BY sum_values DESC;

SELECT
    Subcategory,
    COUNT(Value_numeric) AS count_values,
    SUM(Value_numeric) AS sum_values,
    AVG(Value_numeric) AS avg_value
FROM chatgpt_data_cleaned
GROUP BY Subcategory
ORDER BY avg_value DESC;

SELECT
    Date_converted,
    Category,
    AVG(Value_numeric) AS avg_value
FROM chatgpt_data_cleaned
WHERE Date_converted IS NOT NULL
GROUP BY Date_converted, Category
ORDER BY Date_converted;

SELECT
    SUM(CASE WHEN Value IS NULL THEN 1 ELSE 0 END) AS missing_value,
    SUM(CASE WHEN Notes = 'No notes' THEN 1 ELSE 0 END) AS missing_notes
FROM chatgpt_data_cleaned;

