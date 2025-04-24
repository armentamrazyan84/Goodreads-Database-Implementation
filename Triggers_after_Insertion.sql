-- 9. User's are not allowed to quote a book if they haven't red it yet.

DELIMITER $$
CREATE TRIGGER validate_quote_from_read_book
BEFORE INSERT ON Quotes
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM BookshelfBooks bb
        JOIN Bookshelves bs ON bb.shelf_id = bs.shelf_id
        WHERE bs.user_id = NEW.user_id AND bb.book_id = NEW.book_id AND bb.status = 'finished'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You can only quote books you have finished reading.';
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (114, 'John', 'pettigrew', 'john@test.com', 'theRat', 'securepass', 370);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (403, 'Quote-worthy Book', 'A book full of wisdom.', 1); 

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (503, 114, 'Test Shelf');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (503, 403, 'reading', 45, NOW());

INSERT INTO Quotes (quote_id, quote_text, quote_date, book_id, user_id)
VALUES (801, 'This is a great line!', NOW(), 403, 114);

UPDATE BookshelfBooks
SET status = 'finished', progress = 100
WHERE shelf_id = 503 AND book_id = 403;

INSERT INTO Quotes (quote_id, quote_text, quote_date, book_id, user_id)
VALUES (801, 'This is a great line!', NOW(), 403, 114);

-- 12. Preventing recommantion of a book by a user who hasn't read it

DELIMITER $$
CREATE TRIGGER prevent_unfinished_book_recommendation
BEFORE INSERT ON BookRecommendations
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM BookshelfBooks bb
        JOIN Bookshelves bs ON bb.shelf_id = bs.shelf_id
        WHERE bs.user_id = NEW.user_id
          AND bb.book_id = NEW.book_id
          AND bb.status = 'finished'
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You must finish a book before recommending it.';
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (117, 'Simon', 'Black', 'simon@example.com', 'blacksimon', 'pass123123', 120);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (406, 'Unfinished Masterpiece', 'A book you must finish.', 1); 

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (506, 117, 'Test Shelf');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (506, 406, 'reading', 30, NOW());

INSERT INTO BookRecommendations (user_id, book_id, reason)
VALUES (117, 406, 'Everyone should read this!');

UPDATE BookshelfBooks
SET status = 'finished', progress = 100
WHERE shelf_id = 506 AND book_id = 406;

INSERT INTO BookRecommendations (user_id, book_id, reason)
VALUES (117, 406, 'A stunning read!');


-- since the triggers are created once and are used always, after checking them once, making sure they work
-- we should clean up all the test cases, to make sure our database is consist of only accurate and relevant data. 

SET SQL_SAFE_UPDATES = 0;

DELETE FROM BookRecommendations
WHERE user_id IN (117, 999)
   OR book_id IN (406, 999);

DELETE FROM Quotes
WHERE user_id IN (114, 115)
   OR book_id IN (403, 404);

DELETE FROM GiveawayWins
WHERE user_id IN (103, 104, 1)
   OR giveaway_id IN (201, 202);

DELETE FROM Friendships
WHERE user_id1 IN (106, 107)
   OR user_id2 IN (106, 107);

DELETE FROM BookshelfBooks
WHERE shelf_id IN (501, 502, 503, 504, 505, 999)
   OR book_id IN (401, 402, 403, 404, 405, 406, 999);

DELETE FROM Bookshelves
WHERE shelf_id IN (501, 502, 503, 504, 505, 999);

DELETE FROM GroupDiscussion
WHERE group_id = 601;

DELETE FROM Giveaways
WHERE giveaway_id IN (201, 202);

DELETE FROM Books
WHERE book_id IN (401, 402, 403, 404, 405, 406, 999);

DELETE FROM Users
WHERE user_id BETWEEN 101 AND 117 
   OR user_id = 999;

SET SQL_SAFE_UPDATES = 1;
