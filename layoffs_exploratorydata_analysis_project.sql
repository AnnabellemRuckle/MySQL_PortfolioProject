-- PROJECT: LAYOFFS DATA - EXPLORATORY DATA ANALYSIS 
-- PURPOSE: explore trends and insights from cleaned layoff data

SELECT * 
FROM layoffs_staging2;

-- 1. BASIC METRICS AND EXTREMES

-- finding the maximum number of layoffs and the highest percentage laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;


-- showing companies with 100% layoffs 
-- ordered by how much funding they had raised
SELECT * 
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;


-- total layoffs per company 
SELECT company, SUM(total_laid_off) AS total_laid_off_sum
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC;


-- 2. TIME RANGE AND TRENDS OVER TIME 

-- identifying the earliest and latest dates in the dataset
SELECT MIN(`date`) AS start_date, MAX(`date`) AS end_date
FROM layoffs_staging2;


-- total layoffs by year
SELECT YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;


-- 3. COMPANY SPECIFIC PERCENTAGE ANALYSIS

-- total layoff percentages per company 
SELECT company, SUM(percentage_laid_off) AS total_percentage
FROM layoffs_staging2
GROUP BY company 
ORDER BY 2 DESC;


-- 4. MONTHLY TRENDS AND ROLLING TOTALS

-- showing total layoffs by month
SELECT SUBSTRING(`date`, 1, 7) AS `month`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;


-- calculated rolling total layoffs across months
WITH Rolling_Total AS (
    SELECT SUBSTRING(`date`, 1, 7) AS `month`,
           SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `month`
    ORDER BY 1 ASC
)
SELECT `month`,
       total_off,
       SUM(total_off) OVER (ORDER BY `month`) AS rolling_total
FROM Rolling_Total;


-- 5. YEARLY COMPANY RANKINGS

-- calculated total layoffs by company and year
SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;


-- ranking companies each year by total layoffs and showing the top 5 per year
WITH Company_Year (company, years, total_laid_off) AS (
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
SELECT * 
FROM Company_Year_Rank
WHERE Ranking <= 5;
