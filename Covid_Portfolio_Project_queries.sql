/*

Queries for Covid Data Project
Author: William Melahouris
Data source: https://ourworldindata.org/covid-deaths
All Queries were written in Microsoft SQL Server Management Studio


*/

-- 1. 

-- Get the total cases, total deaths, and total death percentage

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths AS bigint)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2

-- 2.

-- We take several locations, as they contain data specified in other locations
-- i.e. European Union is part of Europe, any country is part of World, etc.

SELECT location, SUM(CAST(new_deaths AS bigint)) AS TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NULL
AND location NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'Lower middle income', 'Low income', 'High income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3. 

-- Show countries with the highest death count per population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- 4. 

-- Show countries with the highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidPortfolioProject.dbo.CovidDeaths$
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- 5.

-- Show each day of a given country's highest infection rate compared to population

SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM CovidPortfolioProject.dbo.CovidDeaths$
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC

-- 6. 

-- Now let's break things down by continent
-- Show the continents with the highest death count

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- 7.

-- Show Global numbers by date
-- We show total cases, total deaths, and the death percentage from a global perspective

SELECT date, SUM(new_cases) AS total_cases, 
  SUM(CAST(new_deaths AS int)) AS total_deaths, 
  SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- 8.

-- User an inner join to join the CovidDeaths and CovidVaccinations tables
-- They are joined based on matching location and date

SELECT *
FROM CovidPortfolioProject.dbo.CovidDeaths$ AS dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
ON dea.location = vac.location AND dea.date = vac.date

-- 9.

-- Now let's look at the Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths$ AS dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- 10. 

-- Create a CTE (common table expression)

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths$ AS dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentOfPopVaccinated
FROM PopvsVac

-- 11.

-- Create a Temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths$ AS dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

-- 12.

-- Creating Views to store data for later visualizations

DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.location, 
dea.date) AS RollingPeopleVaccinated
FROM CovidPortfolioProject.dbo.CovidDeaths$ AS dea
JOIN CovidPortfolioProject.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL


DROP VIEW IF EXISTS DeathsPerContinent

CREATE VIEW DeathsPerContinent AS
SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidPortfolioProject.dbo.CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent