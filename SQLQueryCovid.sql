----Total Cases/Deaths per continent and country 

SELECT [Continent]
	, [Location]
	, MAX([population]) AS Population
	, MAX([total_cases]) AS TotalCases
	, MAX(CONVERT(int,total_deaths))AS TotalDeaths
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent is not null
GROUP BY [continent], [location]
ORDER BY 1,2

---Total Covid per continent ---
SELECT [continent]
		,MAX([total_cases]) AS TotalCases
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] is not null
GROUP BY [continent]
ORDER BY 1

-- Looking at total cases vs Population 
-- in a certain location 

SELECT [Location]
		,[date]
		,[total_cases]
		,[total_deaths]
		,[population]
		,([Total_cases]/[population]) *100 as [cases_Percentage]
	
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [Location] LIKE '%KINGDOM%'
AND [continent] is NOT NULL

-- Highest infection rate compared to the population 
SELECT [Location]
		, [population]
		, MAX([total_cases]) AS highesInfectionCount
		, MAX(total_cases/population) *100 as cases_Percentage
		
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent is NOT NULL
GROUP BY [Location], [population]
ORDER BY cases_Percentage DESC

----Percentage of Death per cases and population by creating a temp table ---
DROP TABLE IF EXISTS PercentDeath
CREATE TABLE PercentDeath (
Continent nvarchar(255),
Location nvarchar(255),
Population numeric,
TotalCases numeric,
TotalDeaths numeric
)
INSERT INTO PercentDeath
SELECT [Continent]
	, [Location]
	, MAX([population]) AS Population
	, MAX([total_cases]) AS TotalCases
	, MAX(CONVERT(int,total_deaths))AS TotalDeaths
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] is not null
GROUP BY [continent], [location]
ORDER BY 1,2


SELECT [Continent]
		, [Location]
		, [TotalCases]
		, [TotalDeaths]
		, [TotalDeaths]/[TotalCases] AS PercentageOfDeath
FROM PercentDeath
ORDER BY 5 DESC

  ---what Percentage Caught covid--

SELECT [Location]
		,[Population]
		,[TotalCases]
		,[TotalCases]/[Population] AS CasePerPopulation
FROM PercentDeath
ORDER BY 4 DESC


--Percentage Vaccinated using a temp table--
DROP TABLE IF EXISTS PercentageVaccinated
CREATE TABLE PercentageVaccinated (
Continent nvarchar (255),
Location nvarchar (255),
Population numeric,
PeopleFullyVaccinated numeric )

INSERT INTO PercentageVaccinated

SELECT CD.[Continent]
		,CD.[Location] 
		,CD.[Population]
		,MAX(CAST(CV.[people_fully_vaccinated] as INT)) AS PeopleFullyVaccinated
FROM [PortfolioProject].[dbo].[CovidDeaths] CD
JOIN [PortfolioProject].[dbo].[CovidVaccinations] CV
	ON CD.[iso_code] = CV.[iso_code]
	AND CD.[date] = CV.[date]
WHERE CD.[continent] is not null
GROUP BY CD.[continent], CD.[Location], CD.[population]
ORDER BY 4 DESC

SELECT [Continent] 
		, [Location]
		, [Population]
		, [PeopleFullyVaccinated]
		, [PeopleFullyVaccinated]/[Population] *100 AS PercentageVaccinated
FROM [PercentageVaccinated]
ORDER BY 5 DESC

--continents with the highest death count per population
SELECT [continent]
		, MAX(CAST([total_deaths] AS int))AS DeathToll
		, MAX([population]) AS population
		, MAX(CAST([total_deaths] AS int))/MAX([population]) *100 AS DeathPerPopulation
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] is NOT NULL
GROUP BY [continent]
ORDER BY 4 DESC


--Rolling count of daily new deaths ---
SELECT [Continent]
		, [Location]
		, [date]
		, [new_cases]
		, SUM([new_cases]) OVER (PARTITION BY [Continent], [Location] ORDER BY [date]) AS Totalcases
FROM [PortfolioProject].[dbo].[CovidDeaths]

--Global number daily Newcases vs Deaths --
SELECT [date]
		, SUM([new_cases]) as NewCasesDaily
		, SUM(CAST([new_deaths] AS int)) as DeathTollDaily
		, SUM(CAST([New_deaths] as int)) / SUM([new_cases])*100 AS DeathPercentage
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE [continent] is not null
GROUP BY [date]
ORDER BY 1


--Continent with highest death count per population using a table ---
DROP TABLE IF EXISTS DeathByContinent
CREATE TABLE DeathByContinent(
Continent nvarchar(255),
location nvarchar(255),
population numeric,
TotalDeaths numeric)


INSERT INTO DeathByContinent

SELECT [Continent]
		, [location]
		, [population]
		,MAX(CAST(total_deaths as int)) OVER (PARTITION BY [continent],[location]) AS TotalDeaths
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE Continent is not null
ORDER BY 1

SELECT [Continent]
		, MAX([population]) AS Population
		, MAX(TotalDeaths) AS TotalDeaths
FROM DeathByContinent
Group by [continent]

----WITHOUHT A TABLE ----

SELECT [continent]
	   ,max(CAST(total_deaths as int)) AS TotalDeaths
FROM [PortfolioProject].[dbo].[CovidDeaths]
GROUP BY [Continent]

-- ORDER BY DeathToll DESC

SELECT [Location]
		,[population]
		,MAX(total_cases) AS total_cases
		,MAX(CAST(total_deaths AS int)) AS DeathToll
FROM [PortfolioProject].[dbo].[CovidDeaths]
WHERE continent is NOT NULL
GROUP BY [Location],[population]
ORDER BY 4 DESC


--- Creating Views for Visualisation ----

Create View PercentagePopulation as 
Select cd.continent, cd.location, cv.date ,cd.population, cv.new_vaccinations,
	SUM(CAST(cv.new_vaccinations as INT)) OVER (partition by cv.location ORDER BY cd.Location, cv.date) AS TotalVaccinationCount
	--(TotalVaccinationCount/population)*100 
FROM PortfolioProject.dbo.CovidDeaths cd
JOIN PortfolioProject.dbo.CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
WHERE cd.continent is not null
AND new_vaccinations is not null