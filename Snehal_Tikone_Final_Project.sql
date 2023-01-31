#Loading the database

USE ACME;

CREATE TABLE IF NOT EXISTS dim_memberdetails(
	member_id INT NOT NULL,
    member_first_name VARCHAR(15),
    member_last_name VARCHAR(15),
    member_birth_date VARCHAR(20),
    member_age INT,
	member_gender VARCHAR(1),
    PRIMARY KEY (member_id)
    );

CREATE TABLE IF NOT EXISTS dim_drugform(
drug_form_code VARCHAR(4) NOT NULL,
drug_form_desc VARCHAR(100),
PRIMARY KEY (drug_form_code)
);

CREATE TABLE IF NOT EXISTS dim_drug_bg_code(
drug_brand_generic_code INT NOT NULL,
drug_brand_generic_desc VARCHAR(100),
PRIMARY KEY (drug_brand_generic_code)
);

CREATE TABLE IF NOT EXISTS dim_drugdetails(
drug_ndc VARCHAR(100) NOT NULL,
drug_name VARCHAR(100),
drug_form_code VARCHAR(4),
drug_brand_generic_code INT,
PRIMARY KEY (drug_ndc),
FOREIGN KEY (drug_form_code) REFERENCES dim_drugform(drug_form_code) 
ON DELETE RESTRICT ON UPDATE RESTRICT,
FOREIGN KEY (drug_brand_generic_code) REFERENCES dim_drug_bg_code(drug_brand_generic_code)
ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE IF NOT EXISTS fact_insurance_info(
member_id INT NOT NULL,
fill_date VARCHAR(20),
copay DECIMAL(13,4),
insurance_paid DECIMAL(13,4),
drug_ndc VARCHAR(100) NOT NULL,
FOREIGN KEY (member_id) REFERENCES dim_memberdetails (member_id)
ON UPDATE CASCADE ON DELETE RESTRICT,
FOREIGN KEY (drug_ndc) REFERENCES dim_drugdetails (drug_ndc)
ON DELETE RESTRICT
);

commit;


#DROP TABLE COMMANDS--------------------------------------
DROP TABLE fact_insurance_info;
DROP TABLE dim_drugdetails;
DROP TABLE dim_drug_bg_code;
DROP TABLE dim_drugform;
DROP TABLE dim_memberdetails;



#SELECT QUERIES-------------------------------------------
SELECT * FROM dim_drug_bg_code;
SELECT * FROM dim_drugdetails;
SELECT * FROM dim_drugform;
SELECT * FROM dim_memberdetails;
SELECT * FROM fact_insurance_info;


#SQL query that identifies the number of prescriptions grouped by drug name----------
SELECT count(*) as 'NUMBER OF PRESCRIPTIONS' ,dd.drug_name FROM dim_drugdetails dd 
INNER JOIN fact_insurance_info fii
ON dd.drug_ndc = fii.drug_ndc 
GROUP BY dd.drug_name;


#-	Write a SQL query that counts total prescriptions, counts unique (i.e. distinct)
# members, sums copay $$, and sums insurance paid $$, for members grouped as either ‘age 65+’ or ’ < 65’.
# Use case statement logic to develop this query similar to lecture 3. Paste your output in the space below here; 
#your code should be included in your .sql file.
#	Also answer these questions: How many unique members are over 65 years of age? 
#	How many prescriptions did they fill?


SELECT count(*) as NUMBER_OF_PRESCRIPTIONS,
fii.member_id,
sum(fii.copay),
sum(fii.insurance_paid),
md.member_age,
CASE
    WHEN md.member_age >= 65 THEN "age 65+"
    WHEN md.member_age < 65 THEN "< 65"
END AS AGE_GROUP
FROM dim_drugdetails dd 
INNER JOIN fact_insurance_info fii ON dd.drug_ndc = fii.drug_ndc 
INNER JOIN dim_memberdetails md ON md.member_id=fii.member_id
GROUP BY fii.member_id;

WITH GROUPED_MEMBERS AS (
SELECT count(*) as NUMBER_OF_PRESCRIPTIONS,
fii.member_id,sum(fii.copay),
sum(fii.insurance_paid),
md.member_age,
CASE
    WHEN md.member_age >= 65 THEN "age 65+"
    WHEN md.member_age < 65 THEN "< 65"
END AS AGE_GROUP
FROM dim_drugdetails dd 
INNER JOIN fact_insurance_info fii ON dd.drug_ndc = fii.drug_ndc 
INNER JOIN dim_memberdetails md ON md.member_id=fii.member_id
GROUP BY fii.member_id)
 
SELECT count(member_id) AS AGE_ABOVE_65,NUMBER_OF_PRESCRIPTIONS from GROUPED_MEMBERS where AGE_GROUP = 'age 65+' GROUP BY member_id ;


#Write a SQL query that identifies the amount paid by the insurance for 
#the most recent prescription fill date. Use the format that we learned with SQL Window functions. 
#Your output should be a table with member_id, member_first_name, member_last_name, drug_name, fill_date (most recent), 
#and most recent insurance paid. Paste your output in the space below here; your code should be included in your .sql file.
#Also answer these questions: For member ID 10003, what was the drug name listed on their most recent fill date?
#How much did their insurance pay for that medication?

WITH MR_DATA AS(
SELECT md.member_id,
md.member_first_name,
md.member_last_name,
dd.drug_name,
RANK() OVER (PARTITION BY md.member_id ORDER BY 
str_to_date(fii.fill_date,'%m/%d/%Y') DESC) AS MR_Date,fii.fill_date,
fii.insurance_paid
FROM dim_memberdetails md 
INNER JOIN fact_insurance_info fii ON md.member_id = fii.member_id
INNER JOIN dim_drugdetails dd ON fii.drug_ndc = dd.drug_ndc)

SELECT member_id,
member_first_name,
member_last_name,
drug_name,
fill_date,
insurance_paid
FROM MR_DATA WHERE MR_Date=1;

