/*
COVID Vaccine Death Data
Exploration in SQL
*/

/*SELECT DATA THAT WE ARE GOING TO BE USING*/
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent IS NOT NULL 
ORDER BY 1,2




/*LOOKING AT TOTAL CASES VS. TOTAL DEATHS - INDICATES LIKELIHOOD OF DEATH BY COVID IN YOUR COUNTRY*/
SELECT Location, date, total_cases, total_deaths, (cast(total_deaths AS float))/(cast(total_cases AS float))*100 AS death_percentage --changing data types as needed to get percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%' -- shows death percentage in the United States
WHERE continent IS NOT NULL
ORDER BY 1,2




/*LOOKING AT TOTAL CASES VS. THE POPULATION - SHOWS WHICH PERCENTAGE OF THE POPULATION CONTRACTED COVID*/
SELECT Location, date, population, total_cases, (cast(total_cases AS float))/population *100 AS population_infection_percentage --changing data types as needed to get percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%' -- shows death percentage in the United States
WHERE continent IS NOT NULL 
ORDER BY 1,2



/*LOOKING AT WHICH COUNTRIES HAVE THE HIGHEST INFECTION RATE PER POPULATION*/
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((cast(total_cases AS float))/population) *100 AS max_population_infection_percentage--changing data types as needed, shows highest infeciton count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%' --shows infection rate in the United States
WHERE continent IS NOT NULL
GROUP BY location, Population --this is required for aggregate functions
ORDER BY max_population_infection_percentage DESC



/*LOOKING AT WHICH COUNTRIES HAVE THE HIGHEST DEATH RATE PER POPULATION*/
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count --changing data types as needed
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent IS NOT NULL
-- and Location like '%states%'
GROUP BY location --this is required for aggregate functions
ORDER BY total_death_count DESC





/*BREAKING THINGS DOWN BY CONTINENT*/
SELECT continent, MAX(cast(total_deaths AS int)) AS total_death_count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent IS NOT NULL
GROUP BY continent --this is required for aggregate functions
ORDER BY total_death_count DESC
--North America may not be including numbers from Canada





/*SHOWING CONTINENTS WITH THE HIGHEST DEATH COUNT PER POPULATION*/
SELECT location, MAX(cast(total_deaths AS int)) AS total_death_count
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
WHERE continent IS NULL --keep it null to include all continents
GROUP BY location --this is required for aggregate functions
ORDER BY total_death_count DESC






/*GLOBAL NUMBERS*/
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_cases)/NULLIF(SUM(new_deaths),0)*100 AS death_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
GROUP BY date --this is required for aggregate functions
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_cases)/NULLIF(SUM(new_deaths),0)*100 AS death_percentage
FROM [PortfolioProject].[dbo].[COVIDDeaths$]
--WHERE Location like '%states%'
WHERE continent IS NOT NULL
ORDER BY 1,2





/*JOIN QUERY TO VIEW DATA IN BOTH DEATHS & VACCINATIONS TABLES*/
SELECT * 
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	AND dea.date = vac.date






/*LOOKING AT TOTAL POPULATION VS. VACCINATIONS WITH CTE*/
WITH population_vaccination(continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER 
	(
		PARTITION BY dea.location
		ORDER BY 
			dea.location, 
			dea.date
	) 
	AS rolling_total_vaccinations
	--Partition by - rolling sum to show daily increase in vaccinations in each location - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_total_vaccinations/population)*100 AS population_vaccination_percentage
FROM population_vaccination







/*LOOKING AT TOTAL POPULATION VS. VACCINATIONS WITH TEMP TABLE*/
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
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER
	(
		PARTITION BY dea.location
		ORDER BY 
			dea.location, 
			dea.date
	)
	AS rolling_total_vaccinations
	--Partition by - rolling sum to show daily increase in vaccinations in each location - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_total_vaccinations/population)*100 AS population_vaccination_percentage
FROM #percent_population_vaccinated







/*CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS*/
CREATE VIEW percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CAST(vac.new_vaccinations AS FLOAT)) OVER
	(
		PARTITION BY dea.location
		ORDER BY 
			dea.location, 
			dea.date
	) 
	AS rolling_total_vaccinations 
	--Partition by - rolling sum to show daily increase in vaccinations in each location - when query gets to a new location it should start over
FROM [PortfolioProject].[dbo].[COVIDDeaths$] dea
JOIN [PortfolioProject].[dbo].[COVIDVaccinations$] vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM percent_population_vaccinated
