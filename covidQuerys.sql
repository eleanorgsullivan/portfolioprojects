--select the data that we will be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolioProjectCovid..covidDeaths
ORDER BY 1,2

--total cases vs total deaths, likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS deathPercentage
FROM portfolioProjectCovid..covidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--total cases vs population, shows what percentage has gotten covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infectionPercentage
FROM portfolioProjectCovid..covidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

--countries w/ highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highestInfectionCount, MAX((total_cases/population)*100) AS percentPopulationInfected
FROM portfolioProjectCovid..covidDeaths
GROUP BY population, location
ORDER BY percentPopulationInfected DESC

--countries w/ the highest death count per population
SELECT location, MAX(CAST(total_deaths AS INT)) AS totalDeathCount
FROM portfolioProjectCovid..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totalDeathCount DESC

--continents w/ highest death count
SELECT continent, MAX(CAST(total_deaths AS INT)) AS totalDeathCount
FROM portfolioProjectCovid..covidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totalDeathCount DESC

--global numbers
SELECT  SUM(new_cases) AS totalCases, SUM(CAST (new_deaths AS int)) AS totalDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases) * 100 AS deathPercentage
FROM portfolioProjectCovid..covidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2

--joinging covidDeaths and covidVaccinations
SELECT *
FROM portfolioProjectCovid..covidDeaths death
JOIN portfolioProjectCovid..covidVaccinations vax
	ON death.location = vax.location
	AND death.date = vax.date

--total population vs vaccinations
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rollingPeopleVax
FROM portfolioProjectCovid..covidDeaths death
JOIN portfolioProjectCovid..covidVaccinations vax
	ON death.location = vax.location
	AND death.date = vax.date
WHERE death.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform Calculation on Partition By in previous query
WITH popvsvax(continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
AS(
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rollingPeopleVax
FROM portfolioProjectCovid..covidDeaths death
JOIN portfolioProjectCovid..covidVaccinations vax
	ON death.location = vax.location
	AND death.date = vax.date
WHERE death.continent IS NOT NULL)

SELECT *, (rollingPeopleVaccinated/population)*100
FROM popvsvax

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #percentPopVax
CREATE TABLE #percentPopVax
(contenint nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)
INSERT INTO #percentPopVax
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rollingPeopleVax
FROM portfolioProjectCovid..covidDeaths death
JOIN portfolioProjectCovid..covidVaccinations vax
	ON death.location = vax.location
	AND death.date = vax.date
WHERE death.continent IS NOT NULL

SELECT *, (rollingPeopleVaccinated/population)*100
FROM #percentPopVax

--creating view to store data for later visualizations
CREATE VIEW percentPopVax AS
SELECT death.continent, death.location, death.date, death.population, vax.new_vaccinations, 
SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS rollingPeopleVax
FROM portfolioProjectCovid..covidDeaths death
JOIN portfolioProjectCovid..covidVaccinations vax
	ON death.location = vax.location
	AND death.date = vax.date
WHERE death.continent IS NOT NULL