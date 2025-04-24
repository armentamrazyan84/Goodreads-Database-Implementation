-- 1. Get name of a person by his/her ID

DELIMITER //
CREATE FUNCTION GetUserFullName(uid INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE full_name VARCHAR(100);
    SELECT CONCAT(first_name, ' ', last_name) INTO full_name
    FROM Users WHERE user_id = uid;
    RETURN full_name;
END;
//
DELIMITER ;

Select GetUserFullName(2) as second_person;

-- 2. Get book's average rating by its ID

DELIMITER //
CREATE FUNCTION GetBookAvgRating(bid INT)
RETURNS DECIMAL(3,2)
DETERMINISTIC
BEGIN
    DECLARE avg_rating DECIMAL(3,2);
    SELECT AVG(rating) INTO avg_rating FROM Ratings WHERE book_id = bid;
    RETURN avg_rating;
END;
//
DELIMITER ;

SELECT GetBookAvgRating(3);

-- 3. Did the user finish the book?

DELIMITER //
CREATE FUNCTION HasFinishedBook(uid INT, bid INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE is_finished BOOLEAN;
    SELECT COUNT(*) > 0 INTO is_finished
    FROM BookshelfBooks bb
    JOIN Bookshelves bs ON bb.shelf_id = bs.shelf_id
    WHERE bs.user_id = uid AND bb.book_id = bid AND bb.status = 'finished';
    RETURN is_finished;
END;
//
DELIMITER ;

SELECT HasFinishedBook(1,31) as Did_You_Finish;

-- 4. Get book count by author

DELIMITER //
CREATE FUNCTION GetBookCountByAuthor(aid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE bcount INT;
    SELECT COUNT(*) INTO bcount FROM Books WHERE author_id = aid;
    RETURN bcount;
END;
//
DELIMITER ;

SELECT GetBookCountByAuthor(2) as count_of_books;

-- 5. Count books in a user's shelf

DELIMITER //
CREATE FUNCTION GetBooksInShelf(sid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE bcount INT;
    SELECT COUNT(*) INTO bcount FROM BookshelfBooks WHERE shelf_id = sid;
    RETURN bcount;
END;
//
DELIMITER ;

SELECT GetBooksInShelf(19) as Number_of_Books;


-- 6. User's current points

DELIMITER //
CREATE FUNCTION GetCurrentPoints(uid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE points INT;
    SELECT current_points INTO points
    FROM Users
    WHERE user_id = uid;
    RETURN points;
END;
//
DELIMITER ;

SELECT GetCurrentPoints(1) AS points_earned;

-- 7. Get most recent review

DELIMITER //
CREATE FUNCTION GetLastReviewInfo(bid INT)
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    DECLARE r_info VARCHAR(100);
    DECLARE rid INT;
    DECLARE rdate DATETIME;

    SELECT MAX(review_date)
    INTO rdate
    FROM Reviews
    WHERE book_id = bid;

    SELECT review_id
    INTO rid
    FROM Reviews
    WHERE book_id = bid AND review_date = rdate
    LIMIT 1;

    SET r_info = CONCAT('ID: ', rid, ', Date: ', rdate);
    RETURN r_info;
END;
//
DELIMITER ;

SELECT GetLastReviewInfo(1) AS last_review_date;

-- 8. Get number of friends a user has

DELIMITER //
CREATE FUNCTION GetFriendCount(uid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE fcount INT;
    SELECT COUNT(*) INTO fcount FROM Friendships
    WHERE user_id1 = uid OR user_id2 = uid;
    RETURN fcount;
END;
//
DELIMITER ;

SELECT GetFriendCount(1) As count_of_friends;

-- 9. Get giveaway win count for a specific user

DELIMITER //
CREATE FUNCTION GetGiveawayWins(uid INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE gcount INT;
    SELECT COUNT(*) INTO gcount FROM GiveawayWins WHERE user_id = uid;
    RETURN gcount;
END;
//
DELIMITER ;

SELECT GetGiveawayWins(11) as giveaway_win_count;

-- 10. Check if a user is in a group

DELIMITER //
CREATE FUNCTION IsUserInGroup(gid INT, uid INT)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE exists_flag BOOLEAN;
    SELECT EXISTS (
        SELECT 1 FROM GroupDiscussion
        WHERE group_id = gid AND (
            participant_1 = uid OR participant_2 = uid OR participant_3 = uid OR 
            participant_4 = uid OR participant_5 = uid OR participant_6 = uid OR 
            participant_7 = uid
        )
    ) INTO exists_flag;
    RETURN exists_flag;
END;
//
DELIMITER ;

SELECT IsUserInGroup(1,1) as is_in_group;
SELECT IsUserInGroup(1,4) as is_in_group;

-- 11. The number of times a book was added to shelves

DELIMITER //
CREATE FUNCTION GetShelfAdditionsForBook(p_book_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE shelf_count INT;
    SELECT COUNT(*) INTO shelf_count
    FROM BookshelfBooks
    WHERE book_id = p_book_id;
    
    RETURN shelf_count;
END //
DELIMITER ;

SELECT GetShelfAdditionsForBook(1) as number_of_times_read;

-- 12. Count of comments written by a user

DELIMITER //
CREATE FUNCTION GetUserCommentCount(p_user_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE total_comments INT;
    SELECT COUNT(*) INTO total_comments
    FROM Comments
    WHERE user_id = p_user_id;
    
    RETURN total_comments;
END //
DELIMITER ;

SELECT GetUserCommentCount(14);