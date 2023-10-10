--Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent is not null 
ORDER BY 1,2

-- Looking at the total cases vs. the total deaths
-- Shows likelihood of death by COVID in your country
SELECT Location, date, total_cases, total_deaths, (cast(total_deaths as float))/(cast(total_cases as float))*100 AS death_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent is not null 
Order by 1,2


-- Looking at the total cases vs. the population
-- shows which percentage of the population contracted COVID
SELECT Location, date, population, total_cases, (cast(total_cases as float))/population *100 AS population_infection_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent is not null 
Order by 1,2


--Looking at which countries that have the highest infection rate per population
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((cast(total_cases as float))/population) *100 AS max_population_infection_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent is not null 
GROUP BY location, Population
Order by max_population_infection_percentage DESC


-- Looking at which countries have the highest death rate per population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent is not null 
-- and Location like '%states%'
GROUP BY location
Order by total_death_count DESC

-- Breaking things down by continent
SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent is not null 
GROUP BY continent
Order by total_death_count DESC
--North America may not be including numbers from Canada


-- Showing continents with the highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent is null 
GROUP BY location
Order by total_death_count DESC



-- Global numbers
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_cases)/NULLIF(SUM(new_deaths),0)*100 as death_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent is not null 
GROUP BY date --this requires aggregate functions
ORDER BY 1,2

SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_cases)/NULLIF(SUM(new_deaths),0)*100 as death_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent is not null 
ORDER BY 1,2

--Join query to view data in both tables
SELECT * 
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at total population vs. vaccinations with CTE
WITH population_vaccination(continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations
	--Partition by - rolling sum - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, (rolling_total_vaccinations/population)*100 as population_vaccination_percentage
FROM population_vaccination

-- Looking at total population vs. vaccinations with temp table
DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_total_vaccinations numeric
)

INSERT INTO #percent_population_vaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations
	--Partition by - rolling sum - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_total_vaccinations/population)*100 as population_vaccination_percentage
FROM #percent_population_vaccinated


-- Creating View to store data for later visualizations
CREATE VIEW percent_population_vaccinated as
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_total_vaccinations 
	--Partition by - rolling sum - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT * FROM percent_population_vaccinated