

select top 5 * 
from portofolio..CovidVaccinations
where continent is not null
order by 3,4


--select data that we are going to be using

select Location, date, total_cases, new_cases, total_deaths, population
from portofolio..CovidDeaths
order by 1,2

-- Looking at total cases vs total deaths
-- show likelihood of dying if you contract covid in your country
select location,
	date,
	total_cases,
	total_deaths,
	case when total_deaths is null then '0%'
	else concat((total_deaths/total_cases)*100,'%')
	end as death_percentage 
from portofolio..CovidDeaths
where location = 'Indonesia'
order by 1,2

--looking at total cases vs population
--show percentage of populations got covid

select location,
	date,
	population,
	total_cases,
	concat((total_cases/population)*100,'%')
from portofolio..CovidDeaths
where location = 'Indonesia'
order by 1,2

--looking at countries with highest infection rate compared to population

select location,
	population,
	max(total_cases) as highest_total_case,
	max((total_cases/population)*100) as highest_percentage
from portofolio..CovidDeaths
group by location, population
order by highest_percentage desc

--showing countries with highest death count per-population

select location, max(cast(total_deaths as int)) as totalDeathCount
from portofolio..CovidDeaths
where continent is not null
group by location
order by totalDeathCount desc

--showing continent with the highest death count per population

select continent, max(cast(total_deaths as int)) as totalDeathCount
from portofolio..CovidDeaths
where continent is not null
group by continent
order by totalDeathCount desc  

--global numbers per date

select 
	date,
	sum(new_cases) sum_NewCase,
	sum(cast(new_deaths as int)) sum_NewDeath,
	(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage
from portofolio..CovidDeaths
where continent is not null
group by date
order by 1,2

--overall global numbers

select 
	sum(new_cases) sum_NewCase,
	sum(cast(new_deaths as int)) sum_NewDeath,
	(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_percentage
from portofolio..CovidDeaths
where continent is not null
order by 1,2


--looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from portofolio..CovidDeaths dea
join portofolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
and new_vaccinations is not null
order by 1,2,3

select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over 
		(partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
		--(rollingPeopleVaccinated/population)*100
from portofolio..CovidDeaths dea
join portofolio..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3



--use CTE
with popsVac (continent, location, date, population, new_vaccinations, rollingPeopleVaccinated)
as
(select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over 
		(partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
	from portofolio..CovidDeaths dea
	join portofolio..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null)

select *, (rollingPeopleVaccinated/population)*100 as vaccinated_percent
from popsVac


--temp table


drop table if exists #percent_population_vaccinated
create table #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
rollingPeopleVaccinated numeric 
)

insert into #percent_population_vaccinated
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over 
		(partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
		--(rollingPeopleVaccinated/population)*100
	from portofolio..CovidDeaths dea
	join portofolio..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null

select *, (rollingPeopleVaccinated/population)*100 as vaccinated_percent
from #percent_population_vaccinated

--creating view to store data for later visualization

create view percent_population_vaccinated as
select dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int)) over 
		(partition by dea.location order by dea.location, dea.date) as rollingPeopleVaccinated
		--(rollingPeopleVaccinated/population)*100
	from portofolio..CovidDeaths dea
	join portofolio..CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null

select *
from percent_population_vaccinated