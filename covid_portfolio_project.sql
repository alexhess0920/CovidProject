-- Confirming data imported correctly by selecting all columns and rows


Select *
From PorfolioProject..CovidDeaths
order by 3,4


-- Select Data that we are going to be using


Select Location, date, total_cases, new_cases, total_deaths, population
From PorfolioProject..CovidDeaths
order by 1,2


-- Looking at Total Cases versus Total Deaths. This code will create a new temporary column displaying mortality rate
-- Shows likelihood of dying if you contract COVID-19, ordered by country and date, filtered for keyword match containing the word 'states' in any format (I just wanted United States).


Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PorfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID-19.


Select Location, date, population, total_cases, (total_cases/population)*100 as ContractionRate
From PorfolioProject..CovidDeaths
Where location like '%states%'
order by 1,2


-- Looking at Countries with Highest infection Rate compared to population


Select Location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases/population))*100 as ContractionRate
From PorfolioProject..CovidDeaths
Group by Location, Population
order by 4 desc


-- Showing Countries with the Highest Death Count per Population. 
-- Must cast total_deaths as an integer because data type is not correct.
-- If you run this code without the WHERE statement, we find that there is unneccesary data in here pertaining to entire continents. 
-- Adding the where clause allows us to filter that out so we can review the countries by themselves.


Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PorfolioProject..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count


Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PorfolioProject..CovidDeaths
Where continent is NOT null
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS TOTAL


Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PorfolioProject..CovidDeaths
Where continent is not null
order by 1,2


-- GLOBAL NUMBERS BROKEN DOWN BY DAY


Select  date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From PorfolioProject..CovidDeaths
Where continent is not null
Group By date
order by 1, 2


--Joining the two tables together for analysis


Select *
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date 


-- Looking at Total Population vs Vaccinations


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2, 3




--CONVERT achieves the same goal as CAST in this useage. 
--This query creates a rollings tabulation of new vaccines per day, grouped by location and date (country)


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2, 3


--Looking at the percentage of the population of countries that is vaccinated. (METHOD ONE: CTE)


With PopulationVacRate (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 AS VaxRate
From PopulationVacRate

--TEMP TABLE method

--**DROP Table if exists #PercentPopulationVaccinated**
--Runing this code ^ before the query will eliminate temp table if already created, that way we can edit column data types
--or any other changes we may need to make. Running a second Create Table command will result in an error
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as VaccinationRate
From #PercentPopulationVaccinated
Order by 2,3


-- Creating View to store data for later visualizations

USE PorfolioProject
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From PorfolioProject..CovidDeaths dea
Join PorfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null 


