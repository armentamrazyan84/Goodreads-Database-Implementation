-- 1. Set the current date as a join date when a user is added.

DELIMITER $$
CREATE TRIGGER set_user_join_date
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
    IF NEW.join_date IS NULL THEN
        SET NEW.join_date = CURDATE();
    END IF;
END $$
DELIMITER ;

SELECT *
FROM Users;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (101, 'Anna', 'Smith', 'anna@example.com', 'annasmith', 'pass123345123', 100);

INSERT INTO Users (user_id, first_name, last_name, email, username, password, join_date, current_points)
VALUES (102, 'John', 'Doe', 'john@example.com', 'johnnyd', 'securepass', '2022-01-01', 200);

-- 2. Raise error if user tries to buy a gift they don't have enough points to.

DELIMITER $$
CREATE TRIGGER prevent_giveaway_if_insufficient_points
BEFORE INSERT ON GiveawayWins
FOR EACH ROW
BEGIN
    DECLARE user_points INT;
    DECLARE gift_cost INT;

    SELECT current_points INTO user_points
    FROM Users
    WHERE user_id = NEW.user_id;

    SELECT cost_in_points INTO gift_cost
    FROM Giveaways
    WHERE giveaway_id = NEW.giveaway_id;

    IF user_points < gift_cost THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient points to win this giveaway.';
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (103, 'Alice', 'LowPoints', 'alice@example.com', 'alicelp', 'pass234123', 20);

INSERT INTO Giveaways (giveaway_id, name, description, cost_in_points)
VALUES (201, 'Free Book', 'Win a signed book!', 50);

INSERT INTO GiveawayWins (user_id, giveaway_id, win_date)
VALUES (103, 201, CURDATE());

INSERT INTO GiveawayWins (user_id, giveaway_id, win_date)
VALUES (1, 201, CURDATE());

-- 3. Updating the user's points after purchase

DELIMITER $$
CREATE TRIGGER deduct_points_on_giveaway
AFTER INSERT ON GiveawayWins
FOR EACH ROW
BEGIN
    DECLARE cost INT;
    SELECT cost_in_points INTO cost
    FROM Giveaways
    WHERE giveaway_id = NEW.giveaway_id;

    UPDATE Users
    SET current_points = current_points - cost
    WHERE user_id = NEW.user_id;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (104, 'Andrea', 'Salute', 'andreaand@example.com', 'andreasalute', 'password123', 100);

SELECT * 
FROM Users;

INSERT INTO Giveaways (giveaway_id, name, description, cost_in_points)
VALUES (202, 'Exclusive Book', 'A rare signed book giveaway', 30);

INSERT INTO GiveawayWins (user_id, giveaway_id, win_date)
VALUES (104, 202, CURDATE());

-- 4. Updating the last_update date when progress is changed 

DELIMITER $$
CREATE TRIGGER update_bookshelf_timestamp
BEFORE UPDATE ON BookshelfBooks
FOR EACH ROW
BEGIN
    IF NEW.progress <> OLD.progress THEN
        SET NEW.last_updated = NOW();
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (105, 'Anna', 'Sherly', 'aaaan@example.com', 'greengables', 'password', 110);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (401, 'random', 'Jrandom.', 1);  

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (501, 105, 'random');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (501, 401, 'reading', 10, NOW());

SELECT * 
FROM BookshelfBooks 
WHERE shelf_id = 501 AND book_id = 401;

UPDATE BookshelfBooks
SET progress = 26
WHERE shelf_id = 501 AND book_id = 401;

-- 5. Preventing duplicate friendship entries.

DELIMITER $$
CREATE TRIGGER prevent_duplicate_friendships
BEFORE INSERT ON Friendships
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM Friendships
        WHERE user_id1 = NEW.user_id2 AND user_id2 = NEW.user_id1
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Friendship already exists in reverse order.';
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES 
(106, 'Alice', 'Smith', 'alices@example.com', 'alice', 'pas12344s', 40),
(107, 'Bob', 'Jones', 'bob@example.com', 'bobby', 'pas456543s', 110);

INSERT INTO Friendships (user_id1, user_id2, friendship_date)
VALUES (106, 107, NOW());

INSERT INTO Friendships (user_id1, user_id2, friendship_date)
VALUES (107, 106, NOW());

-- 6. Check that group participants don't exceed the maximum

DELIMITER $$
CREATE TRIGGER check_group_participants
BEFORE INSERT ON GroupDiscussion
FOR EACH ROW
BEGIN
    DECLARE total INT;
    SET total = 
        (NEW.participant_1 IS NOT NULL) +
        (NEW.participant_2 IS NOT NULL) +
        (NEW.participant_3 IS NOT NULL) +
        (NEW.participant_4 IS NOT NULL) +
        (NEW.participant_5 IS NOT NULL) +
        (NEW.participant_6 IS NOT NULL) +
        (NEW.participant_7 IS NOT NULL);

    IF total > NEW.max_people THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Too many participants for the group.';
    END IF;
END $$
DELIMITER ;

-- same trigger for update

DELIMITER $$
CREATE TRIGGER check_group_participants_update
BEFORE UPDATE ON GroupDiscussion
FOR EACH ROW
BEGIN
    DECLARE total INT;
    SET total = 
        (NEW.participant_1 IS NOT NULL) +
        (NEW.participant_2 IS NOT NULL) +
        (NEW.participant_3 IS NOT NULL) +
        (NEW.participant_4 IS NOT NULL) +
        (NEW.participant_5 IS NOT NULL) +
        (NEW.participant_6 IS NOT NULL) +
        (NEW.participant_7 IS NOT NULL);

    IF total > NEW.max_people THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Too many participants for the group.';
    END IF;
END $$
DELIMITER ;


-- testing 

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES 
(108, 'Sam', 'Percival', 'sam@example.com', 'SamPercival', 'pass2334567', 560),
(109, 'Samuel', 'Wulfric', 'samuel2@example.com', 'SamuelWulfric', 'pas2332456s', 140),
(110, 'Samo', 'Brian', 'samo3@example.com', 'SamoBrian', 'pa23456456ss', 230);

INSERT INTO GroupDiscussion (group_id, name, description, max_people, participant_1, participant_2)
VALUES (601, 'Study Group', 'Testing participant limit', 2, 108, 109);

UPDATE GroupDiscussion
SET participant_3 = 110
WHERE group_id = 601;

-- 7. Preventing having the same book in the same shelf 

DELIMITER $$
CREATE TRIGGER prevent_duplicate_book_in_shelf
BEFORE INSERT ON BookshelfBooks
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM BookshelfBooks
        WHERE shelf_id = NEW.shelf_id AND book_id = NEW.book_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This book is already on this shelf.';
    END IF;
END $$
DELIMITER ;

-- testing 

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (111, 'Aragog', 'Spider', 'aragog@example.com', 'scaryfriend', 'pas222333s', 130);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (402, 'Shelf Trigger Book', 'Trigger test', 1);  

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (502, 111, 'My Shelf');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (502, 402, 'reading', 20, NOW());

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (502, 402, 'want to read', 0, NOW());

-- 8. Ensuring that passwords are at least 8 characters

DELIMITER $$
CREATE TRIGGER enforce_password_length
BEFORE INSERT ON Users
FOR EACH ROW
BEGIN
    IF CHAR_LENGTH(NEW.password) < 8 OR CHAR_LENGTH(NEW.password) > 100 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password must be between 8 and 100 characters.';
    END IF;
END $$
DELIMITER ;

-- testing

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (112, 'Emma', 'Clark', 'emmark@example.com', 'Emmaclark', 'StrongPass1', 120);
INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (113, 'Max', 'Swift', 'swiftmax@example.com', 'MaxSwift', '123', 250);


-- 10. Preventing deleting a book if it has been quoted or reviewed.

DELIMITER $$
CREATE TRIGGER prevent_deleting_referenced_books
BEFORE DELETE ON Books
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM Quotes WHERE book_id = OLD.book_id
        UNION
        SELECT 1 FROM Reviews WHERE book_id = OLD.book_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete a book that has quotes or reviews.';
    END IF;
END $$
DELIMITER ;

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (115, 'Alex', 'Sandra', 'asandra@example.com', 'lonelywolf', 'password', 120);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (404, 'Test Book', 'For trigger testing.', 1);

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (504, 115, 'Test Shelf');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (504, 404, 'finished', 100, NOW());

INSERT INTO Quotes (quote_id, quote_text, quote_date, book_id, user_id)
VALUES (802, 'Testing quote.', NOW(), 404, 115);

DELETE FROM Books WHERE book_id = 404;

DELETE FROM Quotes WHERE quote_id = 802;

DELETE FROM Books WHERE book_id = 404;

-- 11. Set status reading when the progress is between 1 and 99

DELIMITER $$
CREATE TRIGGER auto_set_reading_status
BEFORE INSERT ON BookshelfBooks
FOR EACH ROW
BEGIN
    IF NEW.progress > 0 AND NEW.progress < 100 AND NEW.status != 'reading' THEN
        SET NEW.status = 'reading';
    END IF;
END $$
DELIMITER ;

INSERT INTO Users (user_id, first_name, last_name, email, username, password, current_points)
VALUES (116, 'Will', 'Aniston', 'willwill@example.com', 'aniston', 'securepass', 140);

INSERT INTO Books (book_id, title, description, author_id)
VALUES (405, 'Trigger Book', 'For status test.', 1);

INSERT INTO Bookshelves (shelf_id, user_id, shelf_name)
VALUES (505, 116, 'Auto Shelf');

INSERT INTO BookshelfBooks (shelf_id, book_id, status, progress, last_updated)
VALUES (505, 405, 'want to read', 45, NOW());

SELECT * FROM BookshelfBooks
WHERE shelf_id = 505 AND book_id = 405;