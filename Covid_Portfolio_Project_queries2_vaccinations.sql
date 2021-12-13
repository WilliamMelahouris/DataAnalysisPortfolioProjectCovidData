/*

Queries for Covid Data Project
Mostly contains queries on Covid Vaccinations
Author: William Melahouris
Data source: https://ourworldindata.org/covid-deaths
All Queries were written in Microsoft SQL Server Management Studio

*/


-- 0.

-- Here is the data we will primarily be working with

SELECT *
FROM CovidPortfolioProject.dbo.CovidVaccinations$
ORDER BY continent, location, date


-- 1.

-- Get all the distinct locations in the world by continent
-- Locations without a continent are excluded (i.e. location = 'World", location = 'European Union', etc.)
-- This lets us know what exact parts of the world the data covers

SELECT DISTINCT continent, location
FROM CovidPortfolioProject.dbo.CovidVaccinations$
WHERE continent IS NOT NULL
ORDER BY continent


-- 2.

-- Figure out how many locations (countries) are in a given continent within the Covid Vaccinations data

SELECT DISTINCT continent, COUNT(DISTINCT location)
FROM CovidPortfolioProject.dbo.CovidVaccinations$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY continent


-- 3.

-- Get the total # of vaccinations for each country in each continent

SELECT continent, location, MAX(CAST(total_vaccinations AS bigint)) AS total_vacs_for_country
FROM CovidPortfolioProject.dbo.CovidVaccinations$
WHERE continent IS NOT NULL AND total_vaccinations IS NOT NULL
GROUP BY continent, location
ORDER BY continent, location


-- 4.

-- Show the top 10 countries with the highest # of vaccinations

SELECT TOP 10 location, MAX(CAST(total_vaccinations AS bigint)) AS total_vacs_for_country
FROM CovidPortfolioProject.dbo.CovidVaccinations$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_vacs_for_country DESC


-- 5.

-- Get the percentage of each country's population fully vaccinated against Covid
--
-- First create a temp table called VaccinationsTempTable that contains total
-- population which is stored in the CovidDeaths table. We use an Inner Join
-- to join together the CovidVaccinations and CovidDeaths table.

DROP TABLE IF EXISTS VaccinationsTempTable
CREATE TABLE VaccinationsTempTable
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population numeric,
Total_Vaccinations numeric,
People_Vaccinated numeric,
People_Fully_Vaccinated numeric,
Total_Boosters numeric,
New_Vaccinations numeric
)
INSERT INTO VaccinationsTempTable
SELECT 
    vac.continent,
	vac.location,
	vac.date,
	dea.population, 
	vac.total_vaccinations, 
	vac.people_vaccinated, 
	vac.people_fully_vaccinated, 
	vac.total_boosters,
	vac.new_vaccinations
FROM 
	CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
JOIN 
	CovidPortfolioProject.dbo.CovidDeaths$ AS dea
ON 
	vac.continent = dea.continent 
	AND vac.location = dea.location 
	AND vac.date = dea.date
ORDER BY continent, location, date

-- Now get the percentage of each country's population fully vaccinated against Covid
-- NOTE: Gibraltar has a fully vaccinated percentage over 100%
--		 I checked visualizations online and they match that
--	     To fix this, I use a CASE statement to force it to be 100%
SELECT 
	Location AS Country,
	CASE
		WHEN MAX(CAST(ROUND((People_Fully_Vaccinated/Population)*100,2) AS float)) > 100 THEN 100
		ELSE MAX(CAST(ROUND((People_Fully_Vaccinated/Population)*100,2) AS float))
	END AS Percent_Fully_Vaxed
FROM VaccinationsTempTable 
WHERE People_Fully_Vaccinated IS NOT NULL AND Population IS NOT NULL
GROUP BY Location
ORDER BY Percent_Fully_Vaxed DESC


-- 6.

-- Get the total # of boosters for each country
-- Some countries don't have any data on # of people boosted
-- We will exclude those


SELECT Location, MAX(Total_Boosters) AS Num_Boosted
FROM VaccinationsTempTable
WHERE Total_Boosters IS NOT NULL
GROUP BY Location
ORDER BY Num_Boosted DESC


-- 7.

-- Get the percentage of each country's population with vaccine boosters

SELECT Location, Population, MAX(CAST(ROUND(Total_Boosters/Population * 100,2) AS float)) AS Percent_Boosted
FROM VaccinationsTempTable
WHERE Total_Boosters IS NOT NULL AND Population IS NOT NULL
GROUP BY Location, Population
ORDER BY Percent_Boosted DESC


-- 8.

-- Determine the number of vaccinations for each month and year
-- in a given location ordered from largest to smallest
-- We create a temp table here called TempTableX which is used
-- in #9 as well.

DROP TABLE IF EXISTS TempTableX
CREATE TABLE TempTableX
(
	Location varchar(255),
	Month_Year nvarchar(255),
	Total_Vaccs_For_Month bigint
)
INSERT INTO TempTableX
SELECT
	Location,
	CONCAT(DATENAME(MONTH, Date),' ',YEAR(Date)) AS Month_Year,
	SUM(New_Vaccinations) AS Total_Vaccinations_For_Month
FROM 
	VaccinationsTempTable
WHERE New_Vaccinations IS NOT NULL
GROUP BY 
	Location, CONCAT(DATENAME(MONTH, Date),' ',YEAR(Date))

SELECT *
FROM TempTableX
ORDER BY Location, Total_Vaccs_For_Month DESC



-- 9.

-- Determine which month and year of a given country 
-- had the largest number of vaccinations.

SELECT
	tablex.Location, 
	tablex.Month_Year AS Month_Year_With_Highest_Vaccinated, 
	tablemax.Num_Vaccinated
FROM 
	TempTableX AS tablex
JOIN
(
SELECT
	Location,
	MAX(Total_Vaccs_For_Month) AS Num_Vaccinated
FROM 
	TempTableX	
GROUP BY
	Location
) AS tablemax
ON tablex.Location = tablemax.Location
AND tablex.Total_Vaccs_For_Month = tablemax.Num_Vaccinated
ORDER BY Location


-- 10.

-- Global numbers
-- Get total number vaccinated, total number fully vaccinated, 
-- and percentage that is fully vaccinated

SELECT
	SUM(total_vaccinated_in_country) AS Num_Vaccinated,
	SUM(num_fully_vaccinated_in_country) AS Num_Fully_Vaccinated,
	ROUND(SUM(CAST(num_fully_vaccinated_in_country AS float))/SUM(CAST(total_vaccinated_in_country AS float))*100,2) AS Percent_Fully_Vaccinated
FROM
	(
	 SELECT 
		Location, 
		MAX(CAST(people_fully_vaccinated AS bigint)) AS num_fully_vaccinated_in_country,
		MAX(CAST(total_vaccinations AS bigint)) AS total_vaccinated_in_country
	 FROM CovidPortfolioProject.dbo.CovidVaccinations$
	 WHERE continent IS NOT NULL
	 GROUP BY Location
	) AS tabley