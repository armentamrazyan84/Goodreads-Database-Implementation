CREATE SCHEMA IF NOT EXISTS `GoodReads`;

USE GoodReads;

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    username VARCHAR(30) NOT NULL UNIQUE,
    password VARCHAR(100) NOT NULL,
    join_date DATE,
    current_points INT NOT NULL
);

CREATE TABLE Authors (
    author_id INT PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    bio TEXT,
    birth_date DATE NOT NULL,
    death_date DATE DEFAULT NULL,
    nationality VARCHAR(30)
);

CREATE TABLE Genres (
    genre_id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL
);

CREATE TABLE Series (
    series_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE Publishers (
    publisher_id INT PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    country VARCHAR(30) NOT NULL,
    city VARCHAR(30),
    street_number VARCHAR(30),
    building_number VARCHAR(10),
    founded_year INT 
);
CREATE TABLE Books (
    book_id INT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    series_id INT DEFAULT NULL,
    author_id INT NOT NULL,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id),
    FOREIGN KEY (series_id) REFERENCES Series(series_id)
);

CREATE TABLE Awards (
    award_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    year_started INT
);

CREATE TABLE Characters (
    character_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL,
    description TEXT,
    series_id INT DEFAULT NULL,
    book_id INT DEFAULT NULL,
    FOREIGN KEY (series_id) REFERENCES Series(series_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

CREATE TABLE Editions (
    edition_id INT PRIMARY KEY,
    book_id INT NOT NULL,
    publisher_id INT NOT NULL,
    publication_date TIMESTAMP,
    page_count INT,
    format VARCHAR(100),
    language VARCHAR(100),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id)
);

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    review_text TEXT NOT NULL,
    review_date TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

CREATE TABLE Comments (
    comment_id INT PRIMARY KEY,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMP,
    user_id INT NOT NULL,
    review_id INT NOT NULL,
    parent_comment_id INT DEFAULT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (review_id) REFERENCES Reviews(review_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_comment_id) REFERENCES Comments(comment_id)
);

CREATE TABLE Quotes (
    quote_id INT PRIMARY KEY,
    quote_text TEXT NOT NULL,
    quote_date TIMESTAMP,
    book_id INT NOT NULL,
    user_id INT NOT NULL,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Bookshelves (
    shelf_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    shelf_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Challenges (
    challenge_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    goal INT NOT NULL, -- Clarifying goal is the number of books to be read
    duration INT NOT NULL, -- Clarifying duration is in days
    points INT NOT NULL
);

CREATE TABLE GroupDiscussion (
    group_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    max_people INT CHECK (max_people <= 7) DEFAULT 7,
    participant_1 INT NOT NULL,
    participant_2 INT,
    participant_3 INT,
    participant_4 INT,
    participant_5 INT,
    participant_6 INT,
    participant_7 INT,
    FOREIGN KEY (participant_1) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_2) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_3) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_4) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_5) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_6) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (participant_7) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Giveaways (
    giveaway_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    cost_in_points INT NOT NULL
);

CREATE TABLE BookshelfBooks (
    shelf_id INT NOT NULL,
    book_id INT NOT NULL,
    status VARCHAR(50) CHECK (status IN ('finished', 'reading', 'want to read')) NOT NULL,
    progress INT CHECK (progress BETWEEN 0 AND 100),
    last_updated TIMESTAMP,
    PRIMARY KEY (shelf_id, book_id),
    FOREIGN KEY (shelf_id) REFERENCES Bookshelves(shelf_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

CREATE TABLE BookGenres (
    book_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (book_id, genre_id),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES Genres(genre_id)
);

CREATE TABLE BookAwards (
    book_id INT NOT NULL,
    award_id INT NOT NULL,
    year_won INT NOT NULL,
    PRIMARY KEY (book_id, award_id, year_won),
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (award_id) REFERENCES Awards(award_id)
);

CREATE TABLE Friendships (
    user_id1 INT NOT NULL,
    user_id2 INT NOT NULL,
    friendship_date TIMESTAMP NOT NULL,
    PRIMARY KEY (user_id1, user_id2, friendship_date),
    FOREIGN KEY (user_id1) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id2) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Ratings (
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    rating INT NOT NULL,
    rating_date TIMESTAMP,
    PRIMARY KEY (user_id, book_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

CREATE TABLE ChallengeParticipation (
    user_id INT NOT NULL,
    challenge_id INT NOT NULL,
    date_joined TIMESTAMP NOT NULL,
    state VARCHAR(20) CHECK (state IN ('Won', 'In Progress', 'Failed')) NOT NULL,
    PRIMARY KEY (user_id, challenge_id, date_joined),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (challenge_id) REFERENCES Challenges(challenge_id) 
);

CREATE TABLE GiveawayWins (
    user_id INT NOT NULL,
    giveaway_id INT NOT NULL,
    win_date DATE NOT NULL,
    PRIMARY KEY (user_id, giveaway_id, win_date),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (giveaway_id) REFERENCES Giveaways(giveaway_id)
);

CREATE TABLE BookRecommendations (
    user_id INT NOT NULL,
    book_id INT NOT NULL,
    reason TEXT NOT NULL,
    PRIMARY KEY (user_id, book_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE
);

