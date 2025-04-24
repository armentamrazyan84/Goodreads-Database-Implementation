-- 1. Displays each user's total number of review, ratings and points

CREATE VIEW UserInfo AS
SELECT u.user_id, u.username, u.current_points, count(DISTINCT r.review_id) AS total_reviews, count(DISTINCT rtn.book_id) AS total_ratings
FROM Users u LEFT JOIN Reviews r ON u.user_id = r.user_id LEFT JOIN Ratings rtn ON u.user_id = rtn.user_id 
GROUP BY u.user_id;

SELECT * FROM UserInfo;

-- 2. Tracks how many books each user has in each status (currently reading, finished, want to read)

CREATE VIEW ReadingStatus AS
SELECT u.user_id, u.username, bsb.status, COUNT(*) as BookCount
FROM Users u JOIN Bookshelves bs ON u.user_id = bs.user_id JOIN BookshelfBooks bsb ON bs.shelf_id = bsb.shelf_id
GROUP BY u.user_id, bsb.status;

SELECT * FROM ReadingStatus;

-- 3. Shows user-added quotes with book title and author name

CREATE VIEW QuotesandAuthors AS
SELECT u.username, q.quote_text, b.title, CONCAT(a.first_name, ' ', a.last_name) as author_name
FROM Quotes q JOIN Books b ON q.book_id = b.book_id JOIN Authors a ON b.author_id = a.author_id JOIN Users u ON q.user_id = u.user_id;

SELECT * FROM QuotesandAuthors;

-- 4. Shows public user information hiding user's password, email and their points

CREATE VIEW PublicUserInfo AS
SELECT user_id,first_name, last_name, username, join_date
FROM users;

SELECT * FROM PublicUserInfo;

-- 5. Shows users who are the most active in group discussions based on the number of discussions they participate in  

CREATE VIEW UserDiscussion AS
SELECT pi.user_id, pi.username, pi.first_name, pi.last_name, COUNT(gd.group_id) as total_discussions
FROM PublicUserInfo pi LEFT JOIN GroupDiscussion gd ON pi.user_id IN (gd.participant_1, gd.participant_2, gd.participant_3, gd.participant_4, gd.participant_5, gd.participant_6, gd.participant_7)
GROUP BY pi.user_id
ORDER BY total_discussions DESC;

SELECT * FROM UserDiscussion;

-- 6. Shows Books users' friends gave 5 star ratings (for friend based recommendation)

CREATE VIEW FriendRecommendations AS
SELECT f.user_id1 AS viewer_user_id, f.user_id2 AS friend_user_id, u.username AS friend_username, r.book_id, b.title, r.rating, r.rating_date
FROM Friendships f JOIN Ratings r ON f.user_id2 = r.user_id AND r.rating = 5 JOIN Books b ON r.book_id = b.book_id JOIN Users u ON u.user_id = f.user_id2; 

SELECT * FROM FriendRecommendations;

-- 7. Displays the most popular books based on reviews and ratings

CREATE VIEW PopularBooks AS
SELECT b.book_id, b.title, ROUND(AVG(rt.rating), 2) AS avg_rating, SUM(DISTINCT r.review_id) AS total_reviews
FROM Books b LEFT JOIN reviews r ON b.book_id = r.book_id LEFT JOIN ratings rt ON b.book_id = rt.book_id
GROUP BY b.book_id, b.title
HAVING COUNT(r.review_id) > 0
ORDER BY avg_rating DESC, total_reviews DESC;

SELECT * FROM PopularBooks;

-- 8. Creates a nested view (using View_PopularBooks) filtering highly popular books with average ratings more than 4.5 and review count more than 20

CREATE VIEW MostPopularBooks AS
SELECT *
FROM PopularBooks 
WHERE avg_rating >= 4.5 AND total_reviews >= 20;

SELECT * FROM MostPopularBooks;

-- 9. Measures how similiar two friends are based on shared bookshelf books and similiar ratings

CREATE VIEW FriendshipSimiliarity AS
SELECT f.user_id1, f.user_id2,  COUNT(DISTINCT bsb1.book_id) AS shared_books,
    ROUND(avg(ABS(r1.rating - r2.rating)), 2) AS avg_rating_difference
FROM Friendships f JOIN ratings r1 ON f.user_id1 = r1.user_id JOIN ratings r2 ON f.user_id2 = r2.user_id AND r1.book_id = r2.book_id
JOIN BookshelfBooks bsb1 ON r1.book_id = bsb1.book_id JOIN BookshelfBooks bsb2 ON r2.book_id = bsb2.book_id AND bsb1.shelf_id = bsb2.shelf_id 
WHERE ABS(r1.rating - r2.rating) IS NOT NULL
GROUP BY f.user_id1, f.user_id2;

SELECT * FROM FriendshipSimiliarity;


-- 10. Displays Books that have won the most awards

CREATE VIEW MostAwardsBooks AS 
SELECT b.book_id, b.title, COUNT(ba.award_id) AS total_awards 
FROM BookAwards ba JOIN Books b ON ba.book_id = b.book_id 
GROUP BY b.book_id, b.title
ORDER BY total_awards DESC;

SELECT * FROM MostAwardsBooks;