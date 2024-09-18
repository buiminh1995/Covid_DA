select * from new..CovidDeaths1 order by 3,4

select * from new..CovidVaccinations1 order by 3,4

-- Select Data that we are going to use

select location, NewDateColumn, total_cases, new_cases, total_deaths, population from new..CovidDeaths1 order by 1,2

-- Looking at total cases vs total deaths

select * from new..CovidDeaths1
where location like 'United States' order by NewDateColumn

-- Shows likelihood of dying if you contract covid in the US

select location, NewDateColumn, total_cases, total_deaths, 
CASE 
	WHEN total_cases = 0 THEN NULL  -- Or any other value you want to return
    ELSE (total_deaths / total_cases)*100
END as DeathPercentage
from new..CovidDeaths1
where location like 'United States'
order by 1,2

-- Looking at Total Cases vs Population
-- Show percentage of population got Covid
select location,NewDateColumn, total_cases, population, 
CASE 
	WHEN population = 0 THEN NULL  -- Or any other value you want to return
    ELSE (total_cases / population)*100
END as CasePercentage
from new..CovidDeaths1
where location like 'United States'
order by 1,2

-- Looking at countries with highest infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount
from new..CovidDeaths1
Group by location, population
order by HighestInfectionCount desc

select location, population, max(total_cases) as HighestInfectionCount,
CASE 
	WHEN population = 0 THEN NULL  -- Or any other value you want to return
    ELSE max((total_cases / population))*100
END as HighestInfectionRate
from new..CovidDeaths1
Group by location, population
order by HighestInfectionRate desc

--Showing continents with the highest death count per population
select continent, max(total_deaths) as HighestDeathCount
from new..CovidDeaths1
where continent is not null and continent <> ''
Group by continent
order by HighestDeathCount desc

--Global Numbers
select date, sum(cast(new_cases as int)) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths
from new..CovidDeaths1 
group by date
order by date

select NewDateColumn, sum(cast(new_cases as int)) as Total_Cases, sum(cast(new_deaths as int)) as Total_Deaths
from new..CovidDeaths1 
group by NewDateColumn
order by NewDateColumn

select sum(cast(new_cases as int)) as a, sum(cast(new_deaths as int)) as b from new..CovidDeaths1

select sum(new_deaths) from new..CovidDeaths1

Select SUM(cast(new_cases as bigint)) as Total_Cases, SUM(new_deaths) as Total_Deaths,
CASE
	WHEN SUM(cast(new_cases as bigint)) = 0 then NULL
	ELSE sum(new_deaths)/sum(cast(new_cases as decimal(12,1)))*100 
END as DeathPercentage
from new..CovidDeaths1
where continent is not null or continent <> ''
order by 1,2

---- Covid Vaccinations

select * from new..CovidVaccinations1

---- Looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
order by 1,2,3

---- 

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.date) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
order by 1,2,3


--If do below (only partition by location), all locations will have the same sum value

'''
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
order by 1,2,3
'''

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
order by 1,2,3

----

select dea.continent, dea.location, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
order by 1,2

-----Want to use RollingPeopleVaccinated to divide it by population
-----Use CTE

with PopvsVac as
(select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
---order by 1,2,3
)

select *, (RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinated_over_Population
from PopvsVac

select *, (RollingPeopleVaccinated/cast(population as decimal(12,1)))*100 as RollingPeopleVaccinated_over_Population
from PopvsVac

--Temp table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations bigint,
RollingPeopleVaccinated bigint
)
--select * from #PercentPopulationVaccinated order by Location, Date

Insert into #PercentPopulationVaccinated (Continent, Location, Date, Population,New_vaccinations,RollingPeopleVaccinated)
select dea.continent, 
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''

--below query RollingPeopleVaccinated/population returns decimal because we set Population as numeric above
select *, (RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated order by Location, Date

-- Creating view to store data for later visualization

Create View PercentPopulationVaccinated as
select dea.continent, 
dea.location,
dea.date,
dea.population,
vac.new_vaccinations,
sum(convert(bigint,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from new..CovidVaccinations1 vac join new..CovidDeaths1 dea
on vac.location = dea.location and dea.date = vac.date
where dea.continent is not null and dea.continent <> ''
--order by 2,3



---- Helpful queries

SELECT * FROM information_schema.columns where TABLE_NAME='CovidDeaths1'
SELECT * FROM information_schema.columns where TABLE_NAME='CovidVaccinations1'

USE new;

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME  = 'dbo.CovidDeaths1'

------

SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS;

------

ALTER TABLE dbo.CovidVaccinations1 ADD NewDateColumn DATE;

UPDATE dbo.CovidVaccinations1 SET NewDateColumn = CAST(date AS DATE);

------

UPDATE dbo.CovidDeaths1 SET new_cases = NULL WHERE new_cases = ''

------

use new
SELECT COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS where TABLE_NAME='dbo.CovidDeaths1'
go

------

SELECT CAST(total_cases AS INT)
FROM new..CovidDeaths1;

------

ALTER TABLE new..CovidDeaths1
ALTER COLUMN population BIGINT;

------

ALTER TABLE new..CovidDeaths1
ALTER COLUMN date DATE;

ALTER TABLE new..CovidVaccinations1
ALTER COLUMN date DATE;

------

DECLARE @Num1 INT;
DECLARE @Num2 INT;

SET @Num1=0;
SET @Num2=0;

SELECT @Num1/NULLIF(@Num2,0) AS Division;

------

DECLARE @Num3 INT;

SET @Num3 = NULL

SELECT cast(@Num3 as int) as hello

---------

SELECT CAST('' AS decimal(10,0));
