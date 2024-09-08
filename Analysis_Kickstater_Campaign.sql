/*
PROJECT DESCRIPTION:
A board game company requires assistance in setting up its first Kickstarter campaign. 
The objective of this analysis is to provide data-driven recommendations to a small board of game company 
on their Kickstarter campaigns by providing insights to help maximize funding for their campaign. 
The project answers the question, what is a realistic Kickstarter campaign goal the Kickstarter Company needs to raise.
*/

/*
mysql -u root -p kickstarter < ks-data.sql

ANALYSIS PLAN
-- Explore the schema tables
    List schema tables
    List table & row numbers
    List columns, data types & max length
    Looking at the table summary
    Check for duplicates row & column

-- Clean data 
    In campaign table: 
        Replace null with 0
        Rename [name] column to [campaign_name]
        Rename [launched] column to launch_date and change type to date
        Change data type of deadline column to date        
        Rename [goal] column to target_amount, roundup to 2 dp
        Rename [pledge] column to [pledged_amount], roundup to 2 dp
        Correct input error by changing "Succesa" = "successful"
        Calculated column [campaign_duration] = [deadline] – [launch_date]

-- Analysis:
    Conduct a Preliminary Data Analysis (Part 1)
    Visualize the Data (Part 2)
    Findings & Recommendations (Part 3)

-- Report:
    Writing the report  
    Report dissemination 
*/
-- select goal from campaign;

-- EXPLORING THE SCHEMA TABLES/ DATA  
-- List schema tables  
SHOW TABLES;


-- List table & row numbers 
SELECT TABLE_NAME, TABLE_ROWS 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = DATABASE();

-- list columns, data types & max length
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE();

-- explore campaign table 
-- Looking at the table summary 
DESCRIBE campaign;

-- Check for duplicate rows & columns 
SELECT id, name, sub_category_id, country_id, currency_id, launched, deadline, goal, pledged, backers, outcome, COUNT(*)
FROM campaign
GROUP BY id
HAVING COUNT(*) > 1;

-- CLEANING AND EXPORING CAMPAIGN TABLE
SELECT COUNT(*) FROM campaign;


-- check for nullable column
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'campaign' AND IS_NULLABLE = 'YES'; 

/*
-- check for actual null
SELECT *
FROM campaign
WHERE goal IS NULL;
*/


/*
-- delete row where name or goal is null
SET SQL_SAFE_UPDATES = 0;
DELETE FROM campaign
WHERE name IS NULL;

-- replace null with zero
SET SQL_SAFE_UPDATES = 0; -- to update without using key value
UPDATE campaign
SET goal = 0
WHERE goal IS NULL;
*/
-- No NULL values were found 

-- NOTE: 
-- ALTER TABLE commands are commented after run to avoid error when re-running the query.
/*
-- Rename [name] column to [campaign_name]
ALTER TABLE campaign
CHANGE name campaign_name text;

-- Rename [launched] column to launch_date
ALTER TABLE campaign
CHANGE launched launched_date date;

-- Change data type of deadline column to date
ALTER TABLE campaign
CHANGE deadline deadline date;

-- Rename [goal] column to target_amount, roundup to 2 dp
ALTER TABLE campaign
CHANGE COLUMN goal target_amount double(25, 2);

-- Rename [pledge] column to [pledged_amount], roundup to 2 dp
ALTER TABLE campaign
CHANGE pledged pledged_amount double(25, 2);

-- Correct input error
SET SQL_SAFE_UPDATES = 0;
UPDATE campaign
SET outcome = 'successful'
WHERE outcome = 'succesa';


-- Calculated column [campaign_duration] = [deadline] – [launch_date] 
ALTER TABLE campaign
ADD COLUMN campaign_duration INT AS (DATEDIFF(deadline, launched_date));
*/

-- ANALYSIS PHASE

-- PART 1: Preliminary Data Analysis
/*
(1). Are the goals for dollars raised significantly different between campaigns that are successful and unsuccessful?
To answer this question, we group the data into three groups: successful, unsuccessful and live campaigns.
But we exclude "live" campaign from the since the campaign is still active. 
Then, we use statistical t-test to determine if there is a 
significant difference in the goal amounts between the two groups.
*/
-- this group outcome column into 3 categories 
SELECT campaign_name,
  CASE 
    WHEN outcome = 'successful' THEN 'successful'
    WHEN outcome IN ('canceled', 'suspended', 'undefined', 'failed', '') THEN 'unsuccessful'
    WHEN outcome = 'live' THEN 'live'
  END AS `Outcome`,
  target_amount AS Goal,
  COUNT(*) AS `Count`
FROM campaign
WHERE outcome NOT IN ('live') 
GROUP BY campaign_name, `Outcome`, target_amount;

-- This calculate the the average of successful and unsucessful
SELECT
  CASE 
    WHEN outcome = 'successful' THEN 'successful'
    WHEN outcome IN ('canceled', 'suspended', 'undefined', 'failed', 'success') THEN 'unsuccessful'
    WHEN outcome = 'live' THEN 'live'
  END AS `Outcome Group`,
  AVG(target_amount) AS `Average target amount`,
  COUNT(*) AS `Count`
FROM campaign
WHERE outcome NOT IN ('live')
GROUP BY `Outcome Group`;


/*
(2a). What are the top/bottom 3 categories with the most backers? 
(2b). What are the top/bottom 3 subcategories by backers?
To answer this question, we can group the data by categories and subcategories and calculate the sum of the 
number of backers for each group. Then, sort the groups in descending order and select the top/bottom 3 groups.
*/
-- (2a) Top/bottom 3 categories with the most backers:
SELECT category.name AS `Top 3 Category`, SUM(campaign.backers) AS `No of Backer`, AVG(campaign.backers) AS `Avg backers`
FROM category
JOIN sub_category ON category.id = sub_category.category_id
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  category.name
ORDER BY `Avg backers` DESC
LIMIT 3;

SELECT category.name AS `Bottom 3 Category`, SUM(campaign.backers) AS `No of Backer`, AVG(campaign.backers) AS `Avg backers`
FROM category
JOIN sub_category ON category.id = sub_category.category_id
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  category.name
ORDER BY `Avg backers` ASC
LIMIT 3;

-- (2b) Top/Bottom 3 Sub categories with the most backers:
SELECT sub_category.name AS `Top 3 subcategory`, SUM(campaign.backers) AS `No of Backer`, AVG(campaign.backers) AS `Avg backers`
FROM sub_category
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  sub_category.name
ORDER BY `Avg backers` DESC
LIMIT 3;

SELECT sub_category.name AS `Bottom 3 subcategory`, SUM(campaign.backers) AS `No of Backer`, AVG(campaign.backers) AS `Avg backers`
FROM sub_category
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  sub_category.name
ORDER BY `Avg backers` ASC
LIMIT 3;

/*
select t1.name, SUM(t2.backers) AS total_backers
from category t1 cross join
campaign t2
GROUP BY name
ORDER BY total_backers DESC
LIMIT 3;
*/

/*
(3a). What are the top/bottom 3 categories that have raised the most money? 
(3b). What are the top/bottom 3 subcategories that have raised the most money?
To answer this question, we can group the data by categories and subcategories and 
calculate the sum of the pledged amount for each group. 
You can then sort the groups in descending order and select the top/bottom 3 groups.
*/
-- 3a.  Top/bottom 3 categories that have raised the most money:
SELECT category.name AS `Top 3 goals with most money`, SUM(campaign.pledged_amount) AS `Amount raised`, AVG(campaign.pledged_amount) AS `Avg Amount`
FROM category
JOIN sub_category ON category.id = sub_category.category_id
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  category.name
ORDER BY `Amount raised` DESC
LIMIT 3;

SELECT category.name AS `Bottom 3 goals with most money`, SUM(campaign.pledged_amount) AS `Amount raised`, AVG(campaign.pledged_amount) AS `Avg Amount`
FROM category
JOIN sub_category ON category.id = sub_category.category_id
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  category.name
ORDER BY `Amount raised` ASC
LIMIT 3;

-- 3b. Top/bottom 3 subcategories that have raised the most money:
SELECT sub_category.name AS `Top 3 sub_goals with most money`, SUM(campaign.pledged_amount) AS `Amount raised`, AVG(campaign.pledged_amount) AS `Avg Amount`
FROM sub_category
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  sub_category.name
ORDER BY `Amount raised` DESC
LIMIT 3;

SELECT sub_category.name AS `Bottom 3 sub_goals with most money`, SUM(campaign.pledged_amount) AS `Amount raised`, AVG(campaign.pledged_amount) AS `Avg Amount`
FROM sub_category
JOIN campaign ON sub_category.id = campaign.sub_category_id
GROUP BY  sub_category.name
ORDER BY `Amount raised` ASC
LIMIT 3;


/*
(4a). What was the amount the most successful board game company raised? 
(4b). How many backers did they have?
To answer this question, we filter the data to only include successful 
campaigns in the board game category, and select the campaign with the highest pledged amount. 
We can then retrieve the pledged amount and number of backers for that campaign.
*/
SELECT campaign_name AS "Most successful board game", pledged_amount AS "Amount", backers AS "No of backers"
FROM campaign
WHERE campaign_name LIKE '%board%' AND outcome = 'successful'
ORDER BY pledged_amount DESC
LIMIT 1;


/*
(5). Rank the top three countries with the most successful campaigns in terms of dollars and 
in terms of the number of campaigns backed:
To answer this question, you can group the data by country and calculate the sum of the pledged amount and 
number of backers for each group. You can then sort the groups in descending order based on the pledged amount 
and number of backers, and select the top 3 groups.
*/
/*
SELECT
  country.name AS Country,
  SUM(campaign.pledged_amount) AS `Total Pledged Amount`,
  SUM(campaign.backers) AS `Total Number of Backers`,
  RANK() OVER (ORDER BY SUM(campaign.pledged_amount) DESC) AS `Rank by Pledged Amount`,
  RANK() OVER (ORDER BY SUM(campaign.backers) DESC) AS `Rank by Number of Backers`
FROM
  campaign
JOIN
  country ON country.id = campaign.country_id
WHERE
  outcome = 'successful'
GROUP BY
  country.name
ORDER BY
  `Rank by Pledged Amount` ASC, `Rank by Number of Backers` ASC
LIMIT 3;
*/

-- (5a). Rank the top three countries with the most successful campaigns in terms of dollars
SELECT
  country.name AS Country,
  SUM(campaign.pledged_amount) AS `Total Pledged Amount`,
  RANK() OVER (ORDER BY SUM(campaign.pledged_amount) DESC) AS `Rank by Pledged Amount`
FROM campaign
JOIN country ON country.id = campaign.country_id
WHERE outcome = 'successful'
GROUP BY country.name
ORDER BY `Rank by Pledged Amount` ASC
LIMIT 3;

-- (5b). Rank the top three countries with the most successful campaigns in terms of dollars
SELECT
  country.name AS Country,
  SUM(campaign.backers) AS `Total Number of Backers`,
  RANK() OVER (ORDER BY SUM(campaign.backers) DESC) AS `Rank by Number of Backers`
FROM campaign
JOIN country ON country.id = campaign.country_id
WHERE outcome = 'successful'
GROUP BY country.name
ORDER BY `Rank by Number of Backers` ASC
LIMIT 3;


/*
(6). Do longer or shorter campaigns tend to raise more money?
To answer this question, you can calculate the length of each campaign by subtracting the launch date from the deadline.
We then calculate the average pledged amount and the average duration.
And finally create a scatter plot and a correlation coefficient to explore and visualized the relationship 
between campaign duration and pledged amount using MS Excel.
*/
SELECT 
  category.name AS category_name,
  AVG(campaign.pledged_amount) AS avg_pledged_amount,
  AVG(campaign.campaign_duration) AS avg_campaign_duration
FROM 
  category
JOIN 
  sub_category ON category.id = sub_category.category_id
JOIN 
  campaign ON sub_category.id = campaign.sub_category_id
GROUP BY 
  category_name
ORDER BY 
    avg_campaign_duration ASC;
    

-- TO ANSWER REPORT QUESTIONS 

-- what is a realistic Kickstarter campaign goal (in dollars) should the company aim to raise?
SELECT AVG(target_amount) AS `Realistic Goal in dollars`
FROM campaign
WHERE outcome = 'successful';

-- How many backers will be needed to meet this goal? 
SELECT SUM(target_amount) / AVG(backers) FROM campaign WHERE outcome = 'successful';

-- How many backers can the company realistically expect, based on trends in their category?
SELECT AVG(campaign.backers) AS avg_backers
FROM campaign
JOIN sub_category ON campaign.sub_category_id = sub_category.id
JOIN category ON sub_category.category_id = category.id
WHERE category.name = category.name
AND sub_category.name = sub_category.name
AND campaign.outcome = 'successful';

-- campaign goals in dollars, Number of backers, and duration of campaigns
SELECT 
  category.name AS `Campaign category`,
  AVG(campaign.target_amount) AS `AVG Goal`,
  AVG(campaign.campaign_duration) AS `AVG Duration`
FROM 
  category
JOIN 
  sub_category ON category.id = sub_category.category_id
JOIN 
  campaign ON sub_category.id = campaign.sub_category_id
GROUP BY 
  `Campaign category`
ORDER BY 
    `AVG Goal` ASC;
