SELECT *
FROM Portfolio_Covid_Project.dbo.CovidDeaths_update
ORDER BY 3,4

ALTER TABLE Portfolio_Covid_Project.dbo.CovidDeaths_update
ALTER COLUMN population FLOAT

--SELECT *
--FROM Portfolio_Covid_Project..CovidVaccinations_update
--ORDER BY 3,4

---Selecting the data to be used
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Covid_Project.dbo.CovidDeaths_update
ORDER BY 1,2


---Total cases vs population
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS InfectedPopulation
FROM Portfolio_Covid_Project..CovidDeaths_update
---WHERE Location like '%Nigeria%'
ORDER BY 3,4

----Total Cases vs Deaths per country
SELECT date, location, SUM(CONVERT(FLOAT, total_cases)) AS TotalCases, SUM(CONVERT(FLOAT, total_deaths)) AS TotalDeaths, 
	(SUM(CONVERT(FLOAT, total_deaths))/SUM(NULLIF(CONVERT(FLOAT, total_cases), 0)))*100 AS DeathPercentage
FROM Portfolio_Covid_Project..CovidDeaths_update
WHERE location = 'CHINA'
GROUP BY date, location
ORDER BY 2,3


---Countries with highest infection rates compared to population
SELECT Location, population, MAX(total_cases) AS MaxInfectionCount, MAX(total_cases/population)*100 AS InfectedPopulation
FROM Portfolio_Covid_Project..CovidDeaths_update
GROUP BY population, location
ORDER BY InfectedPopulation DESC

---Countries with highest death count per population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio_Covid_Project..CovidDeaths_update
---WHERE continent != location
GROUP BY location
ORDER BY TotalDeathCount DESC


---Continents with highest death count per population
SELECT continent, MAX(total_deaths) AS TotalDeathCountContinent
FROM Portfolio_Covid_Project..CovidDeaths_update
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCountContinent DESC

---Global numbers
SELECT date, SUM(CAST(new_cases AS INT)) AS TotalCases, SUM(CONVERT(INT, new_deaths)) as TotalDeaths, 
(new_deaths/CAST(NULLIF(new_cases, 0)AS INT))*100 AS DeathPercentage
FROM Portfolio_Covid_Project..CovidDeaths_update
GROUP BY date, new_cases, new_deaths
ORDER BY 1,2 

---Commulative cases and deaths over time
SELECT date, location, SUM(SUM(CONVERT(FLOAT,new_cases))) OVER (ORDER BY date) AS CumulativeCases,
	SUM(SUM(CONVERT(FLOAT,new_deaths))) OVER (ORDER BY date) AS CumulativeDeaths
FROM Portfolio_Covid_Project..CovidDeaths_update
WHERE continent = 'Europe'
GROUP BY date, location
ORDER BY date;



---Looking at Total population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, NULLIF(vac.new_vaccinations,0) AS NewVaccinations
FROM Portfolio_Covid_Project..CovidDeaths_update AS dea
JOIN Portfolio_Covid_Project..CovidVaccinations_update AS vac
On dea.location = vac.location and dea.date = vac.date
WHERE dea.location LIKE '%Nigeria%' AND dea.date LIKE '%2021%'



SELECT dea.continent, dea.location, dea.date, 
       NULLIF(vac.new_vaccinations, 0) AS NewVaccinations, 
       SUM(CONVERT(FLOAT, NULLIF(vac.new_vaccinations, 0))) 
       OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPplVac
FROM Portfolio_Covid_Project..CovidDeaths_update AS dea
JOIN Portfolio_Covid_Project..CovidVaccinations_update AS vac
ON dea.location = vac.location AND dea.date = vac.date
---WHERE dea.location LIKE '%Nigeria%' AND dea.date LIKE '%2021%'
ORDER BY 1,2


---Use a CTE
WITH PopVSvac(Continent, Location, Date, Population, NewVaccinations, RollingPplVac) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population,
        NULLIF(vac.new_vaccinations, 0) AS NewVaccinations, 
        SUM(CONVERT(FLOAT, NULLIF(vac.new_vaccinations, 0))) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPplVac
FROM Portfolio_Covid_Project..CovidDeaths_update AS dea
JOIN Portfolio_Covid_Project..CovidVaccinations_update AS vac
ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.location LIKE '%Nigeria%' AND dea.date LIKE '%2021%'
--ORDER BY 1, 2
)
SELECT *, (RollingPplVac / Population) * 100 AS VaccinationPercentage
FROM PopVSvac;


---Create Temptable
DROP TABLE IF EXISTS #PercentagePopulationVaccinated;
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingPplVac numeric,
VaccinationPercentage numeric
);

WITH PopVSvac(Continent, Location, Date, Population, NewVaccinations, RollingPplVac) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population,
        NULLIF(vac.new_vaccinations, 0) AS NewVaccinations, 
        SUM(CONVERT(FLOAT, NULLIF(vac.new_vaccinations, 0))) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPplVac
FROM Portfolio_Covid_Project..CovidDeaths_update AS dea
JOIN Portfolio_Covid_Project..CovidVaccinations_update AS vac
ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.location LIKE '%Nigeria%' AND dea.date LIKE '%2021%'
--ORDER BY 1, 2
)
INSERT INTO #PercentagePopulationVaccinated
SELECT Continent, Location, Date, Population, NewVaccinations, RollingPplVac, 
       (RollingPplVac / Population) * 100 AS VaccinationPercentage
FROM PopVSvac;



---Creating view to store data for later visualization
DROP VIEW  IF EXISTS ViewPercentagePopulationVaccinated
CREATE VIEW ViewPercentagePopulationVaccinated AS
WITH PopVSvac(Continent, Location, Date, Population, NewVaccinations, RollingPplVac) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population,
        NULLIF(vac.new_vaccinations, 0) AS NewVaccinations, 
        SUM(CONVERT(FLOAT, NULLIF(vac.new_vaccinations, 0))) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPplVac
FROM Portfolio_Covid_Project..CovidDeaths_update AS dea
JOIN Portfolio_Covid_Project..CovidVaccinations_update AS vac
ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.location LIKE '%Nigeria%' AND dea.date LIKE '%2021%'
--ORDER BY 1, 2
)
SELECT *, (RollingPplVac / Population) * 100 AS VaccinationPercentage
FROM PopVSvac;
