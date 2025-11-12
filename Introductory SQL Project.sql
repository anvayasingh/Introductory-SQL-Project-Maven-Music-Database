CREATE DATABASE maven_music;
USE maven_music;

-- Creating Tables
-- Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    email VARCHAR(150),
    member_since DATE,
    subscription_plan VARCHAR(50),
    subscription_rate DECIMAL(5,2),
    discount_flag VARCHAR(10),
    cancellation_date DATE
);

-- Audio Files Table
CREATE TABLE audio_files (
    audio_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(100),
    genre VARCHAR(50),
    popularity INT
);

-- Session Login Table
CREATE TABLE session_login_time (
    session_id INT PRIMARY KEY,
    session_log_in_time DATETIME
);

-- Listening History Table
CREATE TABLE listening_history (
    customer_id INT,
    session_id INT,
    audio_order INT,
    audio_id VARCHAR(20),
    audio_type VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (session_id) REFERENCES session_login_time(session_id),
    FOREIGN KEY (audio_id) REFERENCES audio_files(audio_id)
);

-- Data Cleaning and Validation
UPDATE customers
SET email = TRIM(REPLACE(email, 'Email:', ''));

UPDATE customers
SET subscription_plan = 'Basic (Ads)'
WHERE subscription_plan IS NULL OR subscription_plan = '';

UPDATE customers
SET discount_flag = 'No'
WHERE discount_flag IS NULL OR discount_flag = '';

-- creating a new numeric column for easier joins
ALTER TABLE audio_files ADD COLUMN audio_id_num INT;
UPDATE audio_files
SET audio_id_num = CAST(SUBSTRING_INDEX(ID, '-', -1) AS UNSIGNED);

-- Listening history table to have numeric audio_id values 
UPDATE listening_history
SET audio_id = REPLACE(audio_id, 'Song-', '');

-- Convert “Member Since” and “Cancellation Date” to proper date format
UPDATE customers
SET member_since = STR_TO_DATE(member_since, '%m/%d/%y'),
    cancellation_date = STR_TO_DATE(cancellation_date, '%m/%d/%y');
    
-- Checking Datatypes
DESCRIBE customers;
DESCRIBE listening_history;
DESCRIBE audio_files;
DESCRIBE session_login_time;

-- Checking for missing or Invalid Data
-- Finding customers without a plan
SELECT * FROM customers WHERE subscription_plan IS NULL OR subscription_plan = '';

-- Finding audio IDs missing in audio_files
SELECT DISTINCT lh.audio_id
FROM listening_history lh
LEFT JOIN audio_files af ON lh.audio_id = af.audio_id_num
WHERE af.audio_id_num IS NULL;    

-- Checking date ranges
SELECT MIN(member_since), MAX(member_since) FROM customers;
SELECT MIN(session_log_in_time), MAX(session_log_in_time) FROM session_login_time;

-- listing all customers and their subscription plans.
SELECT customer_id, customer_name, subscription_plan
FROM customers
ORDER BY customer_id;

-- 1) Finding all songs of a specific genre
SELECT * 
FROM audio_files
WHERE genre = 'Pop Music';

-- 2) Showing the total number of tracks available
SELECT COUNT(*) AS total_tracks
FROM audio_files;

-- 3) Displaying all customers who joined after March 15, 2023
SELECT customer_name, member_since
FROM customers
WHERE member_since > '2023-03-15';

-- 4) Retrieving customers with active subscriptions (not cancelled)
SELECT customer_name, subscription_plan
FROM customers
WHERE cancellation_date IS NULL;


-- 5) Getting top 10 songs by popularity
SELECT name, genre, popularity
FROM audio_files
ORDER BY popularity ASC
LIMIT 10;

-- 6) Total listening sessions per customer
SELECT customer_id, COUNT(DISTINCT session_id) AS total_sessions
FROM listening_history
GROUP BY customer_id
ORDER BY total_sessions DESC;

-- 7) Total songs played by each customer
SELECT customer_id, COUNT(audio_id) AS total_songs_played
FROM listening_history
GROUP BY customer_id
ORDER BY total_songs_played DESC;

-- 8) Top 5 most-played songs overall
SELECT af.name AS song_name, af.genre, COUNT(*) AS times_played
FROM listening_history lh
JOIN audio_files af ON lh.audio_id = af.audio_id_num
GROUP BY af.name, af.genre
ORDER BY times_played DESC
LIMIT 5;

-- 9) Top 5 customers by total songs played
SELECT c.customer_name, COUNT(lh.audio_id) AS total_plays
FROM customers c
JOIN listening_history lh ON c.customer_id = lh.customer_id
GROUP BY c.customer_name
ORDER BY total_plays DESC
LIMIT 5;

-- 10) Customers who listened to the most genres
SELECT c.customer_name, COUNT(DISTINCT af.genre) AS unique_genres
FROM listening_history lh
JOIN audio_files af ON lh.audio_id = af.audio_id_num
JOIN customers c ON lh.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY unique_genres DESC
LIMIT 5;

-- 11) Finding customers who cancelled within 30 days of joining
SELECT customer_name, member_since, cancellation_date,
       DATEDIFF(cancellation_date, member_since) AS days_active
FROM customers
WHERE cancellation_date IS NOT NULL
  AND DATEDIFF(cancellation_date, member_since) <= 30;
  
-- 12) Average sessions per customer
SELECT ROUND(COUNT(DISTINCT session_id) / COUNT(DISTINCT customer_id), 2) AS avg_sessions_per_user
FROM listening_history;

-- 13) Distinct number of tracks each customer has played
SELECT c.customer_name, COUNT(DISTINCT lh.audio_id) AS unique_tracks_played
FROM listening_history lh
JOIN customers c 
    ON lh.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY unique_tracks_played DESC;

-- 14) Most popular genre among premium users
SELECT af.genre, COUNT(*) AS total_plays
FROM listening_history lh
JOIN customers c ON lh.customer_id = c.customer_id
JOIN audio_files af ON lh.audio_id = af.audio_id_num
WHERE c.subscription_plan LIKE '%Premium%'
GROUP BY af.genre
ORDER BY total_plays DESC
LIMIT 1;
  