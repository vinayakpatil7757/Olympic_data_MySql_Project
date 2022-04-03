CREATE DATABASE olympic_data; 
USE olympic_data;
CREATE TABLE olympic_history
(
    ID INT,
    Name Varchar(255),
    Sex Varchar(255),
    Age Varchar(255),
    Height Varchar(255),
    Weight Varchar(255),
    Team Varchar(255),
    Noc Varchar(255),
    Games Varchar(255),
    Year  INT,
    Season Varchar(255),
    City Varchar(255),
    Sport Varchar(255),
    Event Varchar(255),
    Medal Varchar(255)
);

/*Selecting all data from olympic_history table*/
SELECT *
FROM olympic_history;

/*Check Secure path from where we can load data from files */
/* SHOW VARIABLES LIKE "secure_file_priv"; */ 

/* Loading data from secure file path*/
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/athlete_events.csv'
INTO TABLE olympic_history
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(ID, Name, Sex, Age, Height, Weight, Team, NOC, Games, Year, Season, City, Sport, Event, Medal);

SELECT *
FROM olympic_history;

/* ***************************************************************************************** */
/*Duplicate records*/

CREATE TABLE new_table LIKE olympic_history;  /*Creating table having same structure of olympic_history's Columns */

INSERT INTO new_table                          /*Inserting rows into new_table*/ 
SELECT DISTINCT * FROM olympic_history         /*Selecting unique rows*/
GROUP BY Name ,Sex, Age, Height, Weight,Team,Noc, Games, Year,Season, City, Sport, Event, Medal;

SELECT *
FROM new_table;       

DROP TABLE olympic_history; 
 
ALTER TABLE new_table RENAME TO olympic_history;
 
/* ************************************************************************************************************************************* */
/*Total rows in table*/

SELECT COUNT(*) AS Total_rows
FROM olympic_history;

/* ************************************************************************************************************************************* */
/* Recent & Old Olympic data */

SELECT MAX(Year) AS Recent_yr, MIN(Year) AS Start_yr
FROM olympic_history;

/* ********************************************************************************************************************************** */
/* Total Olympic Games */

WITH tab1 AS
	(SELECT DISTINCT (Season), Year
	FROM olympic_history
	ORDER BY Year)
SELECT COUNT(*) AS Total_Olympic_Games
FROM  tab1;

/* ************************************************************************************************************************************* */
/* Total Summer Olympics & Total Winter Olympics & List of all Olympic games */

SELECT 
       (SELECT COUNT(DISTINCT Games)
	FROM olympic_history
	WHERE Season='Summer')  AS Total_Summer_Olympics, 

	(SELECT COUNT(DISTINCT Games) 
	FROM olympic_history
	WHERE Season='Winter') AS Total_Winter_Olympics,

	 (SELECT COUNT(DISTINCT Games)
	  FROM olympic_history) AS Total_Olympic_games;
     
/* ********************************************************************************************************************************** */
/*Maximum  Participation count*/

SELECT DISTINCT(Name), Noc,COUNT(Name) AS Participation_count
FROM olympic_history
GROUP BY Name
ORDER BY Participation_count DESC;

/* *********************************************************************************************************************************** */
/*Total Participation of countries in each Olympic Games */

SELECT DISTINCT(Games),COUNT(DISTINCT(Noc)) AS Total_countries_participation
FROM olympic_history
GROUP BY Games
ORDER BY Games;

/* ************************************************************************************************************************************** */
/* Maximum & minimum Participation of Countries in the Olympics*/

WITH tab AS 
	(SELECT DISTINCT(Games),COUNT(DISTINCT(NOC)) AS Num_of_countries
	FROM olympic_history
	GROUP BY Games
	ORDER BY Num_of_countries DESC)
SELECT *
FROM tab
WHERE Num_of_countries IN ((SELECT MIN(Num_of_countries) AS minimum_country FROM tab), (SELECT MAX(Num_of_countries) FROM tab));

/* ************************************************************************************************************************************ */
/*Country participated in all Olympic games */

SELECT DISTINCT(NOC), COUNT(DISTINCT(Games)) AS participation_number
FROM olympic_history 
GROUP BY NOC
HAVING participation_number= (WITH tab1 AS
					(SELECT DISTINCT (Season), Year
					FROM olympic_history
					ORDER BY Year)
			      SELECT COUNT(*) AS Total_Olympic_Games
			      FROM  tab1)
ORDER BY participation_number;

/* ************************************************************************************************************************************* */
/* Olympic Sports in every Summer Olympic */

WITH tab1 AS 
	(SELECT DISTINCT(Sport), COUNT(DISTINCT(Games)) AS Sport_count, 
	                                                               (SELECT COUNT(DISTINCT(Year)) 
                                                                        FROM olympic_history
			                                                WHERE Season='Summer') AS Total_Summer_Olympics
	 FROM olympic_history
	 WHERE Season='Summer'
         GROUP BY Sport
         ORDER BY Sport_count DESC)
SELECT *
FROM tab1
WHERE Sport_count=Total_Summer_Olympics;

/* ************************************************************************************************************************************** */
/* Olympic Sports in every Winter Olympic */

WITH tab1 AS 
	(SELECT DISTINCT(Sport), COUNT(DISTINCT(Games)) AS Sport_count, 
	                                                              (SELECT COUNT(DISTINCT(Year)) 
                                                                        FROM olympic_history
			                                                WHERE Season='Winter') AS Total_Summer_Olympics
	 FROM olympic_history
	 WHERE Season='Winter'
         GROUP BY Sport
         ORDER BY Sport_count DESC)
SELECT *
FROM tab1
WHERE Sport_count=Total_Summer_Olympics;

/* ************************************************************************************************************************************** */
/*Spors played only once in Olympics */

SELECT DISTINCT(Sport), COUNT(DISTINCT(Games)) as game_count, Games
FROM olympic_history
GROUP BY Sport
HAVING game_count=1
ORDER BY Sport;

/* ************************************************************************************************************************************** */
/* Total sports played in each Olympic Games*/

SELECT Games, COUNT(DISTINCT(Sport)) AS num_of_sports
FROM olympic_history
GROUP BY Games
ORDER BY num_of_sports DESC; 

/* ************************************************************************************************************************************** */
/* Oldest athletes to win a gold medal*/

WITH tab AS
	(SELECT *
	FROM olympic_history
	WHERE Medal='Gold')
SELECT *
FROM tab
WHERE Age IN (SELECT MAX(CAST(AGE AS UNSIGNED)) FROM tab) ;

/* ************************************************************************************************************************************** */
/* Male-Female Ratio*/

WITH tab AS
	(SELECT COUNT(Name) AS Male_count 
	FROM olympic_history
	WHERE Sex ='M')
SELECT *, 
	(WITH tab2 AS
	        (SELECT COUNT(Name)  
	         FROM olympic_history
	         WHERE Sex ='F') 
	 SELECT *
	 FROM tab2) AS Female_count ,
	          (SELECT Male_count/Female_count )AS Male_Female_Ratio
FROM tab;

/* ************************************************************************************************************************************** */
/* Athletes who have won the most Gold medals*/

SELECT Name, Team, COUNT(Medal) AS Gold_count
FROM olympic_history
WHERE Medal='Gold'
GROUP BY Name
ORDER BY Gold_count DESC;

/* ************************************************************************************************************************************** */
/* Athletes who have won the most medals (gold/silver/bronze)*/

SELECT Name, team, COUNT(Medal) AS Total_medals
FROM olympic_history
WHERE Medal IN( 'Gold','Silver','Bronze')
GROUP BY Name
ORDER BY Total_medals DESC;

/* ************************************************************************************************************************************** */
/*Countries with total medals*/

SELECT Noc,Team, COUNT(Medal) AS Total_medals
FROM olympic_history
WHERE Medal IN ('Gold', 'Silver', 'Bronze')
GROUP BY Noc
ORDER BY Total_medals DESC;

/* ************************************************************************************************************************************** */
/* Total Gold, Silver and Bronze medals won by each country.*/

SELECT Noc,  COALESCE(SUM(Gold), 0) as 'Gold',
	     COALESCE(SUM(Silver), 0) as 'Silver',
	     COALESCE(SUM(Bronze), 0) as 'Bronze'
FROM          
     (SELECT Noc, CASE WHEN tab2.Medal='Gold' THEN  tab2.Total END AS 'Gold',
		  CASE WHEN tab2.Medal='Silver' THEN  tab2.Total END AS 'Silver',
		  CASE WHEN tab2.Medal='Bronze' THEN  tab2.Total END AS 'Bronze'
     FROM (WITH tab1 AS 
		  (SELECT *,COUNT(*)
		  FROM olympic_history
		  GROUP BY Games, Noc, Medal,Event)
	   SELECT * , COUNT(Medal) AS Total 
	   FROM tab1
	   GROUP BY Games,Noc,Medal,Event
	   ORDER BY Noc) AS tab2) AS tab3
 GROUP BY Noc
 ORDER BY Gold DESC;
 
 /* ************************************************************************************************************************************** */
/*Total gold, silver and bronze medals won by each country corresponding to each olympic games.*/

SELECT Games,Noc, COALESCE(SUM(Gold),0) AS 'Gold',
	          COALESCE(SUM(Silver),0) AS 'Silver',
	          COALESCE(SUM(Bronze),0) AS 'Bronze'
FROM 
    (SELECT Games, Noc,
			  CASE WHEN tab2.Medal='Gold' THEN tab2.Total END AS 'Gold',
			  CASE WHEN tab2.Medal='Silver' THEN tab2.Total END AS 'Silver',
			  CASE WHEN tab2.Medal='Bronze' THEN tab2.Total END AS 'Bronze'
     FROM
	  (WITH tab1 AS 
		 (SELECT Games,Noc, Medal
		  FROM olympic_history
		  WHERE Medal in ('Gold','Silver','Bronze'))
	   SELECT * , COUNT(Medal) AS Total
	   FROM tab1
	   WHERE Medal='Gold' or Medal='Silver' or Medal='Bronze' 
	   GROUP BY Games,Noc,Medal
	   ORDER BY Games) AS tab2) AS tab3
GROUP BY Games, Noc;  
 
 /* ************************************************************************************************************************************** */
/*Country won the most gold, most silver and most bronze medals in each olympic games.*/

SELECT tab3.Games,
       COALESCE(MAX(Total_Gold),0) AS 'Total_Gold',
       COALESCE(MAX(Total_Silver),0) AS 'Total_Silver',
       COALESCE(MAX(Total_Bronze),0) AS 'Total_Bronze'
FROM	
    (SELECT tab2.Games, 
		   CASE WHEN tab2.Medal ='Gold' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Gold',
		   CASE WHEN tab2.Medal ='Silver' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Silver',
		   CASE	WHEN tab2.Medal ='Bronze' THEN CONCAT(tab2.Noc,'-', tab2.Total_medals) END AS 'Total_Bronze'
     FROM
	 (WITH tab1 AS
		 (SELECT Games, Medal,Noc,COUNT(Medal) AS num_counts 
		  FROM olympic_history
		  WHERE Medal <> 'NA'
		  GROUP BY Games, Medal,Noc
		  ORDER BY Games,Medal, num_counts DESC)
	  SELECT Games,Medal,Noc, MAX(num_counts) AS Total_medals
	  FROM tab1
	  GROUP BY Games,Medal) AS tab2) AS tab3
GROUP BY Games ;         

/* ************************************************************************************************************************************** */
/*Maximum medals won by country in every Olympic game*/

WITH tab0 AS
	   (SELECT Games, Noc, COUNT(Medal) AS total_medals
	    FROM olympic_history
	    WHERE Medal <> 'NA'
	    GROUP BY Games,Noc
	    ORDER BY Games,total_medals DESC)
SELECT Games, Noc, MAX(total_medals) AS max_medals
FROM tab0
GROUP BY Games;

/* ************************************************************************************************************************************** */
/*Sport/event, India has won highest medals.*/

WITH India AS
	   (SELECT Sport, COUNT(Medal) AS Medals
	    FROM olympic_history
	    WHERE Noc='IND' AND Medal <> 'NA' 
	    GROUP BY Sport)
SELECT Sport, MAX(Medals)
FROM India
HAVING MAX(Medals);

/* ************************************************************************************************************************************** */
/*Break down all olympic games where India won medal for Hockey and how many medals in each olympic games*/

SELECT Games, Team,Sport, COUNT(Medal) AS Medals
FROM olympic_history
WHERE Noc='IND' AND Medal <> 'NA' AND Sport='Hockey'
GROUP BY Games
ORDER BY Medals DESC;

/* ************************************************************************************************************************************** */
/*Which countries have never won gold medal but have won silver/bronze medals?*/

SELECT tab4.Noc , tab4.Total_Silver, tab4.Total_Bronze
FROM
    (SELECT tab3.Noc, 
			COALESCE(MAX(Gold),0) AS 'Total_Gold',
			COALESCE(MAX(Silver),0) AS 'Total_Silver',
			COALESCE(MAX(Bronze),0) AS 'Total_Bronze'
     FROM        
	 (SELECT tab2.Noc, 
		        CASE WHEN tab2.Medal='Gold' THEN tab2.total_medals END AS 'Gold',
		        CASE WHEN tab2.Medal='Silver' THEN tab2.total_medals END AS 'Silver',
		        CASE WHEN tab2.Medal='Bronze' THEN tab2.total_medals END AS 'Bronze'
	  FROM      
		(WITH tab1 AS
			(SELECT Noc,Medal,COUNT(Medal) AS total_medals
       			 FROM olympic_history
        		 WHERE Medal<> 'NA'
			 GROUP BY Noc,Medal
		         ORDER BY Noc)
		   SELECT *
		   FROM tab1
		   GROUP BY Noc,Medal
		   ORDER BY Noc) AS tab2
	    GROUP BY Noc,Medal
	    ORDER BY Noc) AS tab3
	GROUP BY Noc 
	ORDER BY Total_Gold, Total_Silver,Total_Bronze) AS tab4
WHERE Total_Gold =0
ORDER BY Total_Silver DESC;

/* ************************************************************************************************************************************** */
/*Gold Won By India as team*/

SELECT *
FROM olympic_history
WHERE Noc='IND' AND Medal='Gold'
GROUP BY Games, Event
ORDER BY Games;

/* ************************************************************************************************************************************** */
/*Medals won by India In each Olympic games & with sport event*/

SELECT Games, Event,Medal
FROM olympic_history
WHERE Noc='IND' AND Medal <> 'NA'
GROUP BY Games,Event
ORDER BY Games;

/* ************************************************************************************************************************************** */
/*Total Medals given in each event*/

SELECT tab2.Event, COALESCE(MAX(Gold),0) AS 'Total_Gold',
		   COALESCE(MAX(Silver),0) AS 'Total_Silver',
                   COALESCE(MAX(Bronze),0) AS 'Total_Bronze'
FROM
    (WITH tab1 AS
	    (SELECT Event,Medal ,COUNT(Medal) AS max_medals
	     FROM olympic_history
	     WHERE Medal <> 'NA'
	     GROUP BY Event, Medal
	     ORDER BY max_medals DESC)
     SELECT Event, CASE WHEN Medal='Gold'THEN max_medals END AS 'Gold',
		   CASE WHEN Medal='Silver'THEN max_medals END AS 'Silver',
		   CASE WHEN Medal='Bronze'THEN max_medals END AS 'Bronze'
     FROM tab1) AS tab2
GROUP BY Event; 

/* ************************************************************************************************************************************** */
/* Hosting City Count */ 

WITH tab1 AS
	 (SELECT (Games),(City)
          FROM olympic_history
	  GROUP BY Games,City
	  ORDER BY Games)
SELECT City, COUNT(City) AS total_hosted
FROM tab1
GROUP BY City
ORDER BY total_hosted DESC;

/* ************************************************************************************************************************************** */
/*Success Ratio*/

 SELECT 
	 (WITH tab1 AS                       
		  (SELECT COUNT(*) 
		  FROM olympic_history
		   WHERE Medal='NA') 
	 SELECT *
	 FROM tab1) No_medals , 
         
	(WITH tab2 AS                       
		  (SELECT COUNT(*) 
		  FROM olympic_history
		   WHERE Medal <>'NA') 
	 SELECT *
	 FROM tab2) Medals,
         
	(SELECT Medals/No_medals) AS Success_ratio;
        
