--SELECT total_cases, total_deaths
--FROM CovidDeaths
--WHERE ISNUMERIC(total_cases) = 0 OR ISNUMERIC(total_deaths) = 0;

--ALTER TABLE CovidDeaths
--ALTER COLUMN total_cases FLOAT;

--ALTER TABLE CovidDeaths
--ALTER COLUMN total_deaths FLOAT;

--EXEC sp_help 'CovidDeaths';

SELECT*
FROM PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--SELECT*
--FROM PortfolioProject..CovidVaccinations
--order by 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
order by 3,4

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
FROM PortfolioProject..CovidDeaths
Where location like '%poland%'
order by 1, 2

-- Shows what % of population got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as Percent_Population_Infected
FROM PortfolioProject..CovidDeaths
Where location like '%poland%'
order by 1, 2

-- Looking at Countries with Highest Infection Rates compared to Population
SELECT location, population, MAX(total_cases) as Highes_Infection_Count, MAX((total_cases/population))*100 as Percent_Population_Infected
FROM PortfolioProject..CovidDeaths
--Where location like '%poland%'
Group by location, population
order by Percent_Population_Infected desc


-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
--Where location like '%poland%'
Where continent is not null
Group by location
order by Total_Death_Count desc

-- Break Down by Continents
SELECT continent, MAX(total_deaths) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by Total_Death_Count desc


-- Shownig continents with the highest death count per population
SELECT continent, MAX(total_deaths) as Total_Death_Count
FROM PortfolioProject..CovidDeaths
Where continent is not null
Group by continent
order by Total_Death_Count desc


-- Global Numbers

Select SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Rotal_Deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From PortfolioProject..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Looking at Total Population vs Vaccinations

SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) 
       OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_People_Vaccinated
--, (Rolling_People_Vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date;


-- USE CTE

With PopvsVac (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
as
(
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) 
       OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
Select*, (Rolling_People_Vaccinated/population)*100
From PopvsVac


-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
       dea.location, 
       dea.date, 
       dea.population, 
       vac.new_vaccinations,
       SUM(CONVERT(BIGINT, ISNULL(vac.new_vaccinations, 0))) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL 
-- ORDER BY dea.location, dea.date;

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;


-- Creating View to Store Data for Later Visualisation

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

