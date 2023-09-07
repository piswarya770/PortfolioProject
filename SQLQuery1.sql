select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--Select data that we are going to be using
Select Location,date, total_cases, new_cases,total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
--order by 1,2
-- Total cases vs total deaths
Select TOP (10) Location,date, total_cases,total_deaths 
--,total_deaths/total_cases as DeathPercent1
,CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) *100 as DeathPercent
from PortfolioProject..CovidDeaths

-- shows likelihood of dying if you contract covid in your country
Select Location,date, total_cases,total_deaths 
--,total_deaths/total_cases as DeathPercent1
,CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) *100 as DeathPercent
from PortfolioProject..CovidDeaths
where location like '%state%'
and continent is not null

-- looking total cases  vs population
select Location, date, population, total_cases, (total_cases/population) * 100 as Totalcasespercent
from PortfolioProject..CovidDeaths
--where Totalcasespercent = (select MAX(Totalcasespercent) 
--from PortfolioProject..CovidDeaths)

WITH CTE AS (
    SELECT
        Location,
        date,
        population,
        total_cases,
        (total_cases/population) * 100 as Totalcasespercent
    FROM PortfolioProject..CovidDeaths
)

SELECT
    Location,
    date,
    population,
    total_cases,
    Totalcasespercent
FROM CTE
WHERE Totalcasespercent = (SELECT MAX(Totalcasespercent) FROM CTE);

--looking at countries with highest infection rate compared to population
select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)) * 100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
group by Location, population
order by PercentPopulationInfected desc

--Showing countries with highest death count per population
select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by Location
order by TotalDeathCount desc

--lets break things down by continent
-- Showing the continents with highest death count per population
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

--Global numbers
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as Deathpercent
from PortfolioProject..CovidDeaths
where continent is not null

-- looking at the total population vs vaccination
select death.continent, death.location, death.date, death.population, vacci.new_vaccinations
, sum(cast(vacci.new_vaccinations as float)) over (partition by death.location order by death.location,death.date) as CumulativePeopleVaccinated
from PortfolioProject..CovidDeaths death
join PortfolioProject..CovidVaccinations vacci
on death.location = vacci.location
and death.date = vacci.date
where death.continent is not null
order by 2,3

-- Use CTE
with PopVSVac( continent, location, date,population, new_vaccinations,cumulativePeopleVaccinated)
as
(select death.continent, death.location, death.date, death.population, vacci.new_vaccinations
, sum(cast(vacci.new_vaccinations as float)) over (partition by death.location order by death.location,death.date) as CumulativePeopleVaccinated
from PortfolioProject..CovidDeaths death
join PortfolioProject..CovidVaccinations vacci
on death.location = vacci.location
and death.date = vacci.date
where death.continent is not null
--order by 2,3
)
select * ,(CumulativePeopleVaccinated/population)*100
from PopVSVac

-- use Temp table
Drop Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulativePeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select death.continent, death.location, death.date, death.population, vacci.new_vaccinations
, sum(cast(vacci.new_vaccinations as float)) over (partition by death.location order by death.location,death.date) as CumulativePeopleVaccinated
from PortfolioProject..CovidDeaths death
join PortfolioProject..CovidVaccinations vacci
on death.location = vacci.location
and death.date = vacci.date
--where death.continent is not null

select * ,(CumulativePeopleVaccinated/population)*100 
from #PercentPopulationVaccinated

-- creating view to store data for later visualization
create view PercentPopulationVaccinated as

select 
death.continent, death.location, death.date, death.population, vacci.new_vaccinations, 
sum(cast(vacci.new_vaccinations as float)) over (partition by death.location order by death.location,death.date) as CumulativePeopleVaccinated
from 
PortfolioProject..CovidDeaths death
join 
PortfolioProject..CovidVaccinations vacci
on 
death.location = vacci.location
and 
death.date = vacci.date
where death.continent is not null;
--order by 2,3
-- Now you can select from the view

select * 
from PercentPopulationVaccinated;