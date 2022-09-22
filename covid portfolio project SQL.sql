select * 
from portfolio_project..CovidDeaths
order by 3,4

--select * 
--from portfolio_project..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be starting with
select location,date,total_cases,new_cases,total_deaths,population
from portfolio_project..CovidDeaths
order by 1,2 desc

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from portfolio_project..CovidDeaths
where location like '%states%'
order by 1,2 

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
select location,date,total_cases,population,(total_cases/population)*100 as PopulationPercentage
from portfolio_project..CovidDeaths
where location like '%states%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population
select location,population,MAX(total_cases) as HighestInfectionCount,MAX((total_cases/population))*100 as PopulationInfectedPercentage
from portfolio_project..CovidDeaths
--where location like '%states%'
Group by location,population
order by PopulationInfectedPercentage desc


-- Countries with Highest Death Count per Population
select location,MAX(cast(total_deaths as int)) as HighestDeathCount
from portfolio_project..CovidDeaths
--where location like '%states%'
where continent is not null
Group by location
order by HighestDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
select location,MAX(cast(total_deaths as int)) as HighestDeathCount
from portfolio_project..CovidDeaths
--where location like '%states%'
where continent is null
Group by location
order by HighestDeathCount desc

--GLOBAL NUMBERS
select date, sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from portfolio_project..CovidDeaths
where continent is not null
group by date
order by 1,2

--looking total population vs total vaccinations
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null
order by 1,2,3


--use CTE

with popvsVac(continent,location,date,population,new_vaccinations,rollingPeopleVaccinated)
as
(select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over(partition by dea.location order by dea.location,dea.date) as rollingPeopleVaccinated
from portfolio_project..CovidDeaths dea
join portfolio_project..CovidVaccinations vac
on dea.location=vac.location
and dea.date=vac.date 
where dea.continent is not null
)
select *,(RollingPeopleVaccinated/population)*100
from popvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From portfolio_project..CovidDeaths dea
Join portfolio_project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 




