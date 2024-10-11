SET sql_mode = 'ALLOW_INVALID_DATES';
SET sql_mode = ''; 		#disables sql strict mode to show '0000-00-00' as a valid null date

select *
from hr;

-- id had weird chars so we change it
alter table hr
change column ï»¿id emp_id varchar(20) null;

describe hr;

select birthdate
from hr;

-- cleaning birthdate formatting
update hr
set birthdate = case
	when birthdate like '%/%' then date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y/%m/%d')
    when birthdate like '%-%' then date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y/%m/%d')
    else null
end;

alter table hr
modify column birthdate date;

-- cleaning hire_date formatting
update hr
set hire_date = case
	when hire_date like '%/%' then date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y/%m/%d')
    when hire_date like '%-%' then date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y/%m/%d')
    else null
end;

alter table hr
modify column hire_date date;

-- cleaning termdate data
update hr
set termdate = IF(termdate IS NOT NULL AND termdate != '', date(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC')), '0000-00-00')
where true;

SET sql_mode = 'ALLOW_INVALID_DATES';

alter table hr
modify column termdate date;

-- add age column
alter table hr
add column age int;

update hr
set age = timestampdiff(YEAR, birthdate, curdate());

-- check for anomalies in age
select min(age) as youngest, max(age) as oldest
from hr;

select count(age)
from hr
where age < 18;

select birthdate 
from hr
where birthdate >= '2060-01-01';

-- correct the wrong birthdates (eg. 2060 -> 1960)
update hr
set birthdate = date_sub(birthdate, interval 100 YEAR)
where birthdate >= '2060-01-01';

-- QUESTIONS

-- 1. What is the gender breakdown of employees in the company?
SET sql_mode = ''; 		#disables sql strict mode to show '0000-00-00' as a valid null date

select gender, count(gender) as count
from hr
where termdate = '0000-00-00'
group by gender;

-- 2. What are the race/ethnicity breakdown of the employees
select race, count(race) as count
from hr
where termdate = '0000-00-00'
group by race
order by race desc;

-- 3. What is the age distribution of the employees
select case 
	when age between 18 and 24 then '18-24'
	when age between 25 and 34 then '25-34'
	when age between 35 and 44 then '35-44'
	when age between 45 and 54 then '45-54'
	when age between 55 and 64 then '55-64'
	else '65+'
end as age_group, count(*) as count, gender
from hr
where termdate = '0000-00-00'
group by age_group, gender
order by age_group, gender;

-- 4. How many employees work at hq vs remote
select location, count(location) as count
from hr
where termdate = '0000-00-00'
group by location;

-- 5. What is the average length of employement for employees who have been terminated
select round(avg(datediff(termdate, hire_date))/365,2) avg_len_empolyement_in_years
from hr
where termdate <= curdate() and termdate <> '0000-00-00';

-- 6. How does the gender distribution vary across departments and job titles?
select gender, department, count(*) as count
from hr
where termdate = '0000-00-00'
group by gender, department
order by gender, department;

select gender, jobtitle, count(*) as count
from hr
where termdate = '0000-00-00'
group by gender, jobtitle
order by gender, jobtitle;

-- 7. What is the distribution of job titles across the company?
select jobtitle, count(*) as count
from hr
where termdate = '0000-00-00'
group by jobtitle
order by jobtitle;

-- 8. Which department has the highest turnover rate?
with cte as
(
select department, count(*) as total_emp
from hr
group by department
),
cte2 as
(
select department, count(*) as terminated_emp
from hr 
where termdate <> '0000-00-00' and curdate() > termdate
group by department
)
select a.department, a.total_emp, b.terminated_emp, b.terminated_emp/a.total_emp as terminated_emp_ratio
from cte as a
join cte2 as b
on a.department = b.department;

-- 9. What is the distribution of employees across locations by city and state?
select location_city, count(*) as count
from hr
where termdate = '0000-00-00'
group by location_city
order by location_city desc; 

select location_state, count(*) as count
from hr
where termdate = '0000-00-00'
group by location_state
order by location_state desc; 

-- 10. How has the company's employee count changed over time based on hire and term dates? (Find the number of hires, terminations and % change per year)
with cte as
(
select year(hire_date) as year, count(*) as total_hired
from hr
group by year
),
cte2 as
(
select year(hire_date) as year, count(*) as terminated_emp
from hr 
where termdate <> '0000-00-00' and curdate() > termdate
group by year
)
select a.year, a.total_hired, b.terminated_emp, (a.total_hired - b.terminated_emp) as net_change, round((a.total_hired - b.terminated_emp)/a.total_hired,2) as net_change_percentage
from cte as a
join cte2 as b
on a.year = b.year
order by year;

-- 11. What is the tenure distribution for each department? (How long do employees work in each department before they leave or are made to leave?)
select department, round(avg(datediff(curdate(), termdate))/365,2) as avg_tenure
from hr
where termdate <> '0000-00-00' and curdate() >= termdate
group by department
order by avg_tenure desc;



