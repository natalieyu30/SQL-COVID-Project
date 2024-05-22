select * 
from Porfolio.dbo.CovidDeath
WHERE location ='High Income'

select *
from Porfolio.dbo.CovidVaccination

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Porfolio.dbo.CovidDeath
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying
SELECT location, date, total_cases, total_deaths, (total_deaths/CAST(total_cases AS float))*100 as DeathPercentage
FROM Porfolio.dbo.CovidDeath
WHERE location like '%canada%'
ORDER BY 1,2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (CAST(total_cases AS float)/population)*100 as PercentPopulationInfected
FROM Porfolio.dbo.CovidDeath
WHERE location like '%canada'
ORDER BY 1,2

-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(CAST(total_cases AS int)) as HightestInfectionCount, (MAX(CAST(total_cases AS int)/population))*100 as PercentPopulationInfected
FROM Porfolio.dbo.CovidDeath
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, population, MAX(CAST(total_deaths AS int)) as HightestDeathCount, (MAX(CAST(total_deaths AS int)/population))*100 as PercentPopulationDeath
FROM Porfolio.dbo.CovidDeath
WHERE continent IS NOT NULL 
GROUP BY location, population
ORDER BY 3 DESC

-- Let's break things down by Continent
SELECT continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Porfolio.dbo.CovidDeath
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Showing continents with the hightest death count per Population
SELECT location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
FROM Porfolio.dbo.CovidDeath
WHERE continent IS NULL AND (location NOT LIKE '%income%' AND location NOT LIKE '%union' AND location NOT LIKE 'world')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Creating View to store data for later visualizations
CREATE VIEW vwGlobalDeathCount 
AS
(
	SELECT location, MAX(CAST(total_deaths AS int)) as TotalDeathCount
	FROM Porfolio.dbo.CovidDeath
	WHERE continent IS NULL AND (location NOT LIKE '%income%' AND location NOT LIKE '%union' AND location NOT LIKE 'world')
	GROUP BY location
	--ORDER BY TotalDeathCount DESC
)

SELECT * 
FROM vwGlobalDeathCount


-- Global numbers
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeath, (SUM(new_deaths)/NULLIF(SUM(new_cases),0))*100 AS DeathPercentage
FROM Porfolio.dbo.CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Looking at Total Population vs Vaccinations
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (Partition by d.location Order by d.location, d.date ROWS UNBOUNDED PRECEDING) AS RollingPeopelVaccinated,

FROM Porfolio.dbo.CovidDeath d
JOIN Porfolio.dbo.CovidVaccination v
	ON d.location = v.location
	AND d.date = v.date
WHERE D.continent IS NOT NULL
ORDER BY 1,2,3


-- Use CTE
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopelVaccinated)
AS 
(
	SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
	SUM(CAST(v.new_vaccinations AS float)) OVER (Partition by d.location Order by d.location, d.date ROWS UNBOUNDED PRECEDING) AS RollingPeopelVaccinated
	FROM Porfolio.dbo.CovidDeath d
	JOIN Porfolio.dbo.CovidVaccination v
		ON d.location = v.location
		AND d.date = v.date
	WHERE D.continent IS NOT NULL
	--ORDER BY 1,2,3
)
SELECT *, (RollingPeopelVaccinated/Population)*100 
FROM PopvsVac