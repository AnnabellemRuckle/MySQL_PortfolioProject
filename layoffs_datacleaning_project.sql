-- PROJECT: LAYOFFS DATA - DATA CLEANING 
-- PURPOSE: clean and standardize layoff data for analysis

-- looking at all records from the layoffs table
SELECT * 
FROM layoffs; 

-- 1. REMOVING DUPLICATES

-- creating staging table to avoid modifying original data
CREATE TABLE layoffs_staging 
LIKE layoffs;

-- copying all records from original table into the staging table
INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;


-- assigning a row number to each record to identify duplicates
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`
       ) AS row_num
FROM layoffs_staging;


-- identifying duplicate records 
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, industry, total_laid_off, `date`, stage,
                            country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
) duplicates
WHERE row_num > 1;


-- checking specific company's for duplicates 
SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';


-- attempting to delete duplicates using a CTE 
WITH DELETE_CTE AS (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY company, industry, total_laid_off, `date`, stage,
                                country, funds_raised_millions
               ) AS row_num
        FROM layoffs_staging
    ) duplicates
    WHERE row_num > 1
)
DELETE 
FROM DELETE_CTE;


-- creating a second staging table with a column for duplicates 
CREATE TABLE `layoffs_staging2` (
  `company` TEXT,
  `location` TEXT,
  `industry` TEXT,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` TEXT,
  `date` TEXT,
  `stage` TEXT,
  `country` TEXT,
  `funds_raised_millions` INT DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


-- inserting data into the new table with row numbers assigned
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, `date`, stage,
                        country, funds_raised_millions
       ) AS row_num
FROM layoffs_staging;


-- deleting duplicate rows 
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;


SELECT * 
FROM layoffs_staging2;


-- 2. STANDARDIZE THE DATA

-- triming extra spaces in company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);


-- reviewing all distinct industries 
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;


-- finding inconsistent labels 
SELECT * 
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- setting all to Crypto for consistency 
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


-- checking for inconsistent country formatting
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1; 

-- fixing country values 
UPDATE layoff_staging2  
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- converting date column from text to proper date type
SELECT `date`
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. HANDLE NULL OR BLANK VALUES

-- checking rows with both total_laid_off and percentage_laid_off missing
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- replacing empty strings in industry with null for consistency
UPDATE layoffs_staging2 
SET industry = NULL
WHERE industry = '';


-- verifies which rows still have null or blank industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';


-- checking a specific company
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';


-- matching null industry rows to others with same company but known industry
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1 
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;


-- updating missing industries based on matching companies
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- 4. REMOVE IRRELEVANT ROWS OR COLUMNS

-- identifying rows with no layoff data 
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- deleting rows entirely
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


SELECT * 
FROM layoffs_staging2; 

-- droping the helper column 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

