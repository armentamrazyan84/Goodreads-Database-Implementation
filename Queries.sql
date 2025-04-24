-- 1.users who joined in the last 6 months and have rated more than 3 books. (most active readers)

SELECT u.username, u.email, u.join_date
FROM Users u
WHERE u.join_date >= CURDATE() - INTERVAL 6 Month
  AND (
    SELECT COUNT(*)
    FROM Ratings r
    WHERE r.user_id = u.user_id
  ) > 3;

-- 2.books with average rating higher than the average rating of books in the same genre(s).

SELECT b.title, AVG(r.rating) AS avg_rating
FROM Books b
JOIN Ratings r ON b.book_id = r.book_id
GROUP BY b.book_id
HAVING AVG(r.rating) > ALL (
    SELECT AVG(r2.rating)
    FROM Ratings r2
    JOIN BookGenres bg ON bg.book_id = r2.book_id
    WHERE bg.genre_id IN (
        SELECT bg2.genre_id
        FROM BookGenres bg2
        WHERE bg2.book_id = b.book_id
    )
    GROUP BY bg.genre_id
);

-- 3.books with at least 5 ratings and average rating above 3.

SELECT b.title, COUNT(r.rating) AS rating_count, AVG(r.rating) AS avg_rating
FROM Books b
JOIN Ratings r ON b.book_id = r.book_id
GROUP BY b.book_id
HAVING COUNT(r.rating) >= 5 AND AVG(r.rating) > 3;

-- 4.the most active reviewer’s top-rated book

SELECT CONCAT("'", b.title, "'",  " by " ,a.first_name," ", a.last_name)
FROM Books b
JOIN Ratings r ON b.book_id = r.book_id 
JOIN Authors a on b.author_id = a.author_id
WHERE r.user_id = (
    SELECT user_id
    FROM Reviews
    GROUP BY user_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
ORDER BY r.rating DESC
LIMIT 1;

-- 5.books that belong to multiple genres including both 'Fantasy' and 'Adventure'.

SELECT b.title
FROM Books b
WHERE b.book_id IN (
    SELECT book_id
    FROM BookGenres bg
    WHERE bg.genre_id IN (
        SELECT genre_id FROM Genres WHERE name IN ('Fantasy', 'Adventure')
    )
    GROUP BY book_id
    HAVING COUNT(DISTINCT genre_id) = 2
);

-- 6.Books that are the highest-rated in a given user's rating history

SELECT DISTINCT b.title, r.user_id, r.rating
FROM Ratings r
JOIN Books b ON r.book_id = b.book_id
WHERE r.rating >= ALL (
    SELECT r2.rating
    FROM Ratings r2
    WHERE r2.user_id = r.user_id
);

-- 7.Authors who don’t have any books reviewed

SELECT CONCAT(a.first_name, " ", a.last_name)
FROM Authors a
WHERE NOT EXISTS (
    SELECT *
    FROM Books b
    JOIN Reviews r ON r.book_id = b.book_id
    WHERE b.author_id = a.author_id
);

-- 8.Find top 5 users with the highest total review word count

WITH ReviewWordCount AS (
    SELECT user_id, SUM(CHAR_LENGTH(review_text)) AS total_words
    FROM Reviews
    GROUP BY user_id
)
SELECT u.username, rw.total_words
FROM ReviewWordCount rw
JOIN Users u ON u.user_id = rw.user_id
ORDER BY rw.total_words DESC
LIMIT 5;

-- 9.Show users with how many books they've added to bookshelves

SELECT u.username,
       (SELECT COUNT(DISTINCT bb.book_id) 
        FROM BookshelfBooks bb
        JOIN Bookshelves bs ON bb.shelf_id = bs.shelf_id
        WHERE bs.user_id = u.user_id) AS total_bookshelved
FROM Users u;

-- 10.We give 100 bonus points to users who have won a challenge and written more than 3 reviews

UPDATE Users u
SET current_points = current_points + 100
WHERE u.user_id IN (
    SELECT cp.user_id
    FROM ChallengeParticipation cp
    WHERE cp.state = 'Won'
)
AND (
    SELECT COUNT(*) FROM Reviews r WHERE r.user_id = u.user_id
) > 3;


-- 11.We assign “New”, “Intermediate”, “Advanced” labels to users based on how many books they’ve reviewed

SELECT u.username,
       COUNT(r.review_id) AS review_count,
       CASE 
           WHEN COUNT(r.review_id) < 2 THEN 'New'
           WHEN COUNT(r.review_id) BETWEEN 2 AND 5 THEN 'Intermediate'
           ELSE 'Advanced'
       END AS reviewer_level
FROM Users u
LEFT JOIN Reviews r ON u.user_id = r.user_id
GROUP BY u.user_id;

-- 12.Authors whose books have an average rating above 3, and none of their books have ever received a rating below 3

SELECT a.first_name, a.last_name
FROM Authors a
WHERE a.author_id IN (
    SELECT b.author_id
    FROM Books b
    JOIN Ratings r ON b.book_id = r.book_id
    GROUP BY b.author_id
    HAVING AVG(r.rating) > 3
       AND MIN(r.rating) >= 3
);

-- 13.We rank users based on total review length, number of reviews, and average comment count on their reviews

SELECT u.username,
       COUNT(DISTINCT r.review_id) AS total_reviews,
       SUM(CHAR_LENGTH(r.review_text)) AS total_word_count,
       AVG(comment_count) AS avg_comments_per_review
FROM Users u
JOIN Reviews r ON u.user_id = r.user_id
LEFT JOIN (
    SELECT review_id, COUNT(*) AS comment_count
    FROM Comments
    GROUP BY review_id
) rc ON rc.review_id = r.review_id
GROUP BY u.user_id
ORDER BY total_word_count DESC, avg_comments_per_review DESC;

-- 14.We find books that users have added to bookshelves but where status is never ‘finished’

SELECT DISTINCT b.title
FROM Books b
JOIN BookshelfBooks bb ON b.book_id = bb.book_id
WHERE b.book_id NOT IN (
    SELECT book_id
    FROM BookshelfBooks
    WHERE status = 'finished'
);

-- 15.Books that have won at least one award but have never received a review

SELECT b.title
FROM Books b
JOIN BookAwards ba ON ba.book_id = b.book_id
LEFT JOIN Reviews r ON r.book_id = b.book_id
WHERE r.review_id IS NULL;

-- 16.We calculate each user’s challenge success rate: percentage of challenges marked as ‘Won’

SELECT u.username,
       COUNT(cp.challenge_id) AS total_challenges,
       SUM(CASE WHEN cp.state = 'Won' THEN 1 ELSE 0 END) AS won_challenges,
       ROUND(100 * SUM(CASE WHEN cp.state = 'Won' THEN 1 ELSE 0 END) / COUNT(cp.challenge_id), 2) AS win_rate_percent
FROM Users u
JOIN ChallengeParticipation cp ON cp.user_id = u.user_id
GROUP BY u.user_id
HAVING total_challenges >= 1;

-- 17. We identify series where different books in the same series were published by different publishers

SELECT s.name AS series_name, COUNT(DISTINCT e.publisher_id) AS unique_publishers
FROM Series s
JOIN Books b ON s.series_id = b.series_id
JOIN Editions e ON e.book_id = b.book_id
GROUP BY s.series_id
HAVING unique_publishers > 1;

-- 18.We find the top 5 most quoted books where the average rating is below 3.5

SELECT b.title, COUNT(q.quote_id) AS total_quotes, AVG(r.rating) AS avg_rating
FROM Books b
JOIN Quotes q ON q.book_id = b.book_id
LEFT JOIN Ratings r ON r.book_id = b.book_id
GROUP BY b.book_id
HAVING AVG(r.rating) < 3.5
ORDER BY total_quotes DESC
LIMIT 5;

-- 19.We suggest new friends to a user by showing people who share at least one mutual friends

SELECT f2.user_id2 AS suggested_friend, COUNT(*) AS mutual_count
FROM Friendships f1
JOIN Friendships f2 ON f1.user_id2 = f2.user_id1
WHERE f1.user_id1 = 1
  AND f2.user_id2 NOT IN (
      SELECT user_id2 FROM Friendships WHERE user_id1 = 1
  )
  AND f2.user_id2 != 1
GROUP BY f2.user_id2
HAVING mutual_count >= 1;


-- 20. User retention Analysis
-- We identify users who joined more than a year ago and have not rated, reviewed, or shelved a    book in the last 6 months.

SELECT u.username
FROM Users u
WHERE u.join_date < CURDATE() - INTERVAL 1 YEAR
  AND u.user_id NOT IN (
    SELECT user_id FROM Ratings WHERE rating_date >= CURDATE() - INTERVAL 6 MONTH
    UNION
    SELECT user_id FROM Reviews WHERE review_date >= CURDATE() - INTERVAL 6 MONTH
    UNION
    SELECT bs.user_id
    FROM Bookshelves bs
    JOIN BookshelfBooks bb ON bs.shelf_id = bb.shelf_id
    WHERE bb.last_updated >= CURDATE() - INTERVAL 6 MONTH
);

-- 21. Find users who have spent the most points on giveaways

SELECT u.username, SUM(g.cost_in_points) AS total_spent
FROM GiveawayWins gw
JOIN Giveaways g ON gw.giveaway_id = g.giveaway_id
JOIN Users u ON gw.user_id = u.user_id
GROUP BY u.user_id
ORDER BY total_spent DESC;

-- 22. Which giveaway has the most winners

SELECT g.name, COUNT(*) AS total_winners
FROM GiveawayWins gw
JOIN Giveaways g ON gw.giveaway_id = g.giveaway_id
GROUP BY gw.giveaway_id
ORDER BY total_winners DESC;

-- 23. Find the books that has been quoted but not reviewed

SELECT b.title, COUNT(q.quote_id) AS quote_count
FROM Books b
JOIN Quotes q ON b.book_id = q.book_id
WHERE b.book_id NOT IN (
    SELECT book_id FROM Reviews
)
GROUP BY b.book_id, b.title
ORDER BY quote_count DESC;


-- 24. Books that have never been recommanded, quoted or reviewed

SELECT DISTINCT b.title
FROM Books b
JOIN BookshelfBooks bb ON b.book_id = bb.book_id
WHERE bb.status = 'finished'
  AND b.book_id NOT IN (
      SELECT book_id FROM BookRecommendations
      UNION
      SELECT book_id FROM Quotes
      UNION
      SELECT book_id FROM Reviews
  );

-- 25. Find the users who have never written a review but rated at least 3 books

SELECT u.username
FROM Users u
WHERE u.user_id IN (
    SELECT user_id
    FROM Ratings
    GROUP BY user_id
    HAVING COUNT(*) >= 3
)
AND u.user_id NOT IN (
    SELECT user_id FROM Reviews
);

-- 26. Find who has red the most books relative to the time since they have joined

SELECT u.username,
       u.join_date,
       COUNT(DISTINCT bb.book_id) AS books_finished,
       DATEDIFF(CURDATE(), u.join_date) AS days_active,
       ROUND(COUNT(DISTINCT bb.book_id) / GREATEST(DATEDIFF(CURDATE(), u.join_date), 1), 2) AS books_per_day
FROM Users u
JOIN Bookshelves bs ON u.user_id = bs.user_id
JOIN BookshelfBooks bb ON bs.shelf_id = bb.shelf_id
WHERE bb.status = 'finished'
GROUP BY u.user_id, u.username, u.join_date
ORDER BY books_per_day DESC;


-- 27. Displays the most diverse readers (based on genres)

WITH UserDiversity AS
	(SELECT r.user_id, bg.genre_id 
    FROM Ratings r 
    JOIN Books b on r.book_id = b.book_id 
    JOIN BookGenres bg on b.book_id = bg.book_id
    GROUP BY r.user_id, bg.genre_id)
    
SELECT u.username, count(DISTINCT ud.genre_id) distinct_genres
FROM Users u 
JOIN UserDiversity ud on u.user_id = ud.user_id
GROUP BY u.user_id
ORDER BY distinct_genres DESC;

-- 28 Books with high standard deviation of ratings (people either love them or hate them)

SELECT b.title, AVG(r.rating) average_rating, MAX(r.rating) highest_rating, MIN(r.rating)  lowest_rating, MAX(r.rating) - MIN(r.rating) rating_range
FROM Ratings r
JOIN Books b on r.book_id = b.book_id
GROUP BY b.book_id 
HAVING rating_range >= 3
ORDER BY rating_range desc;


-- 29. Users whose average rating is at least 1 point below the average rating

WITH AvgRating AS (
	SELECT AVG(rating) overall_average FROM Ratings)
    
SELECT u.username, AVG(r.rating) user_average
FROM Users u JOIN Ratings r on u.user_id = r.user_id
GROUP BY u.user_id, u.username
HAVING AVG(r.rating) < (SELECT overall_average FROM AvgRating) - 1;

-- 30. Genres that attract new users

SELECT bg.genre_id, COUNT(*) first_genre_count
FROM (SELECT r.user_id, r.book_id 
	 FROM Ratings r
     WHERE r.rating_date = (SELECT MIN(r2.rating_date) FROM Ratings r2 WHERE r2.user_id = r.user_id)
 ) AS first_books JOIN BookGenres bg on first_books.book_id = bg.book_id
GROUP BY bg.genre_id
ORDER BY first_genre_count DESC;