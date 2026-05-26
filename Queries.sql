-- Index on movie title for faster search
CREATE INDEX Mov_Often ON Film_Det(Title);

-- Index on Mov_id in Rating for faster JOIN with Film_Det
CREATE INDEX Rat_Often ON Rating(Mov_id);

-- Index on User_id in Watch_His for faster user history lookup
CREATE INDEX Watch_Often ON Watch_His(User_id);

-- DATABASE SUMMARY

SELECT 'Genre' as TableName, COUNT(*) AS Records FROM Genre UNION ALL
SELECT 'Users',COUNT(*) FROM Users UNION ALL
SELECT 'Film_Det',COUNT(*) FROM Film_Det  UNION ALL
SELECT 'Film_Lang',COUNT(*)FROM Film_Lang UNION ALL
SELECT 'Watch_His', COUNT(*) FROM Watch_His UNION ALL
SELECT 'Rating',COUNT(*)FROM Rating;


-- QUERY 1: Show all movies with their genre name (INNER JOIN)
SELECT F.Title, G.Gen_Name
FROM Film_Det F
INNER JOIN Genre G ON F.Gen_Id = G.Gen_Id;

-- QUERY 2: Show all movies even if genre is missing (LEFT JOIN)
SELECT F.Title, G.Gen_Name
FROM Film_Det F
LEFT JOIN Genre G ON F.Gen_Id = G.Gen_Id;

-- QUERY 3: Show movies with their genre and languages
SELECT F.Title, G.Gen_Name, L.Film_Lang
FROM Film_Det F
JOIN Genre G ON F.Gen_Id = G.Gen_Id
JOIN Film_Lang L ON F.Mov_id = L.Mov_id;

-- QUERY 4: Count total movies available in each genre
SELECT G.Gen_Name, COUNT(F.Title) AS Total_Movies
FROM Film_Det F
JOIN Genre G ON F.Gen_Id = G.Gen_Id
GROUP BY G.Gen_Name;

-- QUERY 5: Show average rating and total ratings per movie
SELECT F.Title, AVG(R.Score)AS Avg_Rate,COUNT(R.Rat_id) AS Total_Ratings
FROM Film_Det F
JOIN Rating R ON F.Mov_id = R.Mov_id
GROUP BY F.Title
ORDER BY Avg_Rate desc;

-- QUERY 6: Show only movies with average rating above 4.5
SELECT F.Title, ROUND(AVG(R.Score),2) AS Avg_Score
FROM Film_Det F
JOIN Rating R ON F.Mov_id = R.Mov_id
GROUP BY F.Title
HAVING AVG(R.Score) > 4.5
ORDER BY Avg_Score DESC;

-- QUERY 7: Show top 10 most watched movies with their avg rating
SELECT F.Title,COUNT(W.Watch_id) AS Total_Views,ROUND(AVG(R.Score),2)AS Avg_Rating
FROM Film_Det F
LEFT JOIN Watch_His W ON F.Mov_id = W.Mov_id
LEFT JOIN Rating    R ON F.Mov_id = R.Mov_id
GROUP BY F.Title
ORDER BY Total_Views DESC
LIMIT 10;

-- QUERY 8: Find movies rated above the overall average score where average score= 3.05356
SELECT F.Title, R.Score
FROM Film_Det F
JOIN Rating R ON F.Mov_id = R.Mov_id
WHERE R.Score > (SELECT AVG(Score) FROM Rating);

-- QUERY 9: Find users who watched more than 2 movies
WITH Watch_than_Two AS (
    SELECT User_id, COUNT(Mov_id) AS Total_Watched
    FROM Watch_His
    GROUP BY User_id
)
SELECT U.UserName, W.Total_Watched
FROM Users U
JOIN Watch_than_Two W ON W.User_id = U.User_id
WHERE W.Total_Watched > 2;

-- QUERY 10: Rank all movies by their average rating globally
SELECT F.Title,AVG(R.Score) AS Avg_Score,DENSE_RANK() OVER (ORDER BY AVG(R.Score) DESC) AS Rank_Film
FROM Film_Det F
JOIN Rating R ON F.Mov_id = R.Mov_id
GROUP BY F.Title
ORDER BY Rank_Film
LIMIT 10;

-- QUERY 11: Rank movies within each genre separately
SELECT F.Title,G.Gen_Name,AVG(R.Score) AS Avg_Score,
DENSE_RANK() OVER (PARTITION BY G.Gen_Name ORDER BY AVG(R.Score) DESC) AS Rank_Movie
FROM Film_Det F
JOIN Rating R ON F.Mov_id = R.Mov_id
JOIN Genre  G ON F.Gen_Id = G.Gen_Id
GROUP BY F.Title, G.Gen_Name;

-- QUERY 12: Genre popularity report with ranking
SELECT G.Gen_Name,COUNT(W.Watch_id) AS Total_Views,AVG(R.Score)AS Avg_Rating,
DENSE_RANK() OVER (ORDER BY COUNT(W.Watch_id) DESC) AS Genre_Rank
FROM Genre G
LEFT JOIN Film_Det  F ON G.Gen_Id = F.Gen_Id
LEFT JOIN Watch_His W ON F.Mov_id = W.Mov_id
LEFT JOIN Rating    R ON F.Mov_id = R.Mov_id
GROUP BY G.Gen_Name
ORDER BY Genre_Rank;

-- QUERY 13: Top 10 most active users with their rating behavior
SELECT U.UserName,U.Country,COUNT(W.Watch_id) AS Movies_Watched,AVG(R.Score)AS Avg_Score_Given,
DENSE_RANK() OVER (ORDER BY COUNT(W.Watch_id) DESC) AS User_Rank
FROM Users U
LEFT JOIN Watch_His W ON U.User_id = W.User_id
LEFT JOIN Rating    R ON U.User_id = R.User_id
GROUP BY U.UserName, U.Country
ORDER BY User_Rank
LIMIT 10;

-- PROCEDURE 1: Get movie statistics (avg rating + total ratings)
DELIMITER $$
CREATE PROCEDURE Movie_Det()
BEGIN
SELECT F.Title,AVG(R.Score)AS Avg_Rate,COUNT(R.Rat_id) AS Total_Ratings
FROM Film_Det F JOIN Rating R ON F.Mov_id = R.Mov_id
GROUP BY F.Title;
END $$
DELIMITER ;

CALL Movie_Det();

-- Get all movies filtered by genre name
DELIMITER $$
CREATE PROCEDURE Get_Genre(IN Genre_Name VARCHAR(50))
BEGIN
SELECT F.Title, G.Gen_Name
FROM Film_Det F JOIN Genre G ON F.Gen_Id = G.Gen_Id
WHERE G.Gen_Name = Genre_Name;
END $$
DELIMITER ;

CALL Get_Genre('Horror');
CALL Get_Genre('Action');
CALL Get_Genre('Drama');

-- Add Last_Active column to Users table
ALTER TABLE Users
ADD COLUMN Last_Active DATETIME;

-- Create trigger → fires after every watch record inserted
DELIMITER $$
CREATE TRIGGER Update_Last_Active
AFTER INSERT ON Watch_His
FOR EACH ROW
BEGIN
UPDATE Users
SET Last_Active = NOW()
WHERE User_id = NEW.User_id;
END $$
DELIMITER ;

-- Fill existing users Last_Active from old watch history
UPDATE Users U
JOIN Watch_His W ON U.User_id = W.User_id
SET U.Last_Active = W.Watched_on;

-- Test trigger → insert watch record and check Last_Active
INSERT INTO Watch_His (User_id, Mov_id, Watched_on, Watch_percent)
VALUES (100, 211, NOW(), 100);

-- Verify Last_Active updated automatically
SELECT User_id, UserName, Last_Active
FROM Users
WHERE User_id = 100;

-- Verify trigger worked
-- Shows username, movie watched, watch% and last active time
SELECT U.UserName, U.Last_Active, F.Title, W.Watch_percent, W.Watched_on
FROM Users U
JOIN Watch_His W ON U.User_id = W.User_id
JOIN Film_Det F ON W.Mov_id = F.Mov_id
WHERE U.User_id = 100;

-- Retrieves each movie watched by a user once, showing their latest watch percentage and most recent watch date
SELECT U.UserName, F.Title,MAX(W.Watch_percent) AS Watch_percent,MAX(W.Watched_on) AS Last_Watched
FROM Users U
JOIN Watch_His W ON U.User_id = W.User_id
JOIN Film_Det F ON W.Mov_id = F.Mov_id
WHERE U.User_id = 100
GROUP BY U.UserName, F.Title;