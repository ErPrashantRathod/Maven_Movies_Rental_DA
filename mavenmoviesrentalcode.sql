-- DATA ANALYSIS PROJECT FOR RENTAL MOVIES BUSINESS
-- THE STEPS INVOLVED ARE EDA, UNDERSTANDING THR SCHEMA AND ANSWERING THE AD-HOC QUESTIONS
-- BUSINESS QUESTIONS LIKE EXPANDING MOVIES COLLECTION AND FETCHING EMAIL IDS FOR MARKETING ARE INCLUDED
-- HELPING COMPANY KEEP A TRACK OF INVENTORY AND HELP MANAGE IT.

USE mavenmovies;
-- EXPLORATORY DATA ANALYSIS --

-- UNDERSTANDING THE SCHEMA --


SELECT * FROM rental;
SELECT * FROM inventory;
SELECT * FROM customer;
SELECT * FROM film;

-- You need to provide customer firstname, lastname and email id to the marketing team --
SELECT first_name, last_name, email
FROM customer;

-- How many movies are with rental rate of $0.99? --
SELECT COUNT(*) AS cheapest_rentals
FROM film
WHERE rental_rate = 0.99;

-- We want to see rental rate and how many movies are in each rental category --
SELECT rental_rate, COUNT(*) AS total_numb_of_movies
FROM film
GROUP BY rental_rate;

-- Which rating is most prevalant in each store? --
SELECT rating, COUNT(*) AS rating_category_count
FROM film
GROUP BY rating
ORDER BY rating_category_count DESC;

-- Which rating is most prevalant in each store? --
SELECT inv.store_id, fl.rating, COUNT(*) AS total_films
FROM inventory AS inv LEFT JOIN
film AS fl 
ON inv.film_id = fl.film_id
GROUP BY inv.store_id, fl.rating;

-- List of films by Film Name, Category, Language --
SELECT F.title, C.name AS category_movies, LANG.name AS movie_language
FROM film AS F LEFT JOIN film_category AS FC
ON F.film_id = FC.film_id LEFT JOIN category AS C
ON FC.category_id = C.category_id LEFT JOIN language AS LANG
ON F.language_id = LANG.language_id;

-- How many times each movie has been rented out?
SELECT F.title, COUNT(*) AS popularity
FROM rental AS R LEFT JOIN inventory AS INV
ON R.inventory_id = INV.inventory_id LEFT JOIN film AS F
ON INV.film_id = F.film_id
GROUP BY F.title
ORDER BY popularity DESC;

-- REVENUE PER FILM (TOP 10 GROSSERS)
SELECT F.title, SUM(P.amount) AS revenue
FROM rental AS R LEFT JOIN payment AS P
ON R.rental_id = P.rental_id LEFT JOIN inventory AS INV 
ON R.inventory_id = INV.inventory_id LEFT JOIN film AS F 
ON INV.film_id = F.film_id
GROUP BY F.title
ORDER BY revenue DESC
LIMIT 10;

-- Most Spending Customer so that we can send him/her rewards or debate points
SELECT C.customer_id, SUM(P.amount) AS spending, C.first_name, C.last_name
FROM customer AS C LEFT JOIN payment AS P
ON C.customer_id = P.customer_id
GROUP BY C.customer_id
ORDER BY spending DESC
LIMIT 1;


-- Which Store has historically brought the most revenue?
SELECT S.store_id, SUM(P.amount) AS store_revenue
FROM payment AS P LEFT JOIN staff AS S
ON P.staff_id = S.staff_id
GROUP BY S.store_id;

-- How many rentals we have for each month
SELECT EXTRACT(YEAR FROM rental_date), EXTRACT(MONTH FROM rental_date) AS month_, COUNT(rental_id) AS number_
FROM rental
GROUP BY EXTRACT(YEAR FROM rental_date), EXTRACT(MONTH FROM rental_date);

-- Reward users who have rented at least 30 times (with details of customers)
SELECT customer_id, first_name, last_name, email
FROM customer
WHERE customer_id IN(SELECT customer_id
FROM (SELECT customer_id, COUNT(rental_id) AS number_of_trans
FROM rental
GROUP BY customer_id
HAVING number_of_trans > 30) AS C);

SELECT C.*
FROM (SELECT customer_id,COUNT(rental_id) AS number_of_trans
FROM rental
GROUP BY customer_id
HAVING number_of_trans > 30) AS LC INNER JOIN customer AS C
ON LC.customer_id = C.customer_id;

-- Could you pull all payments from our first 100 customers (based on customer ID)
SELECT *
FROM payment
WHERE customer_id BETWEEN 1 AND 100;

-- Now I’d love to see just payments over $5 for those same customers, since January 1, 2006
SELECT *
FROM payment
WHERE (customer_id BETWEEN 1 AND 100) AND amount > 5 AND payment_date > '2006-01-01';

-- Now, could you please write a query to pull all payments from those specific customers, along
-- with payments over $5, from any customer?
SELECT *
FROM payment
WHERE amount > 5 AND customer_id IN (SELECT customer_id
		FROM payment
		WHERE (customer_id BETWEEN 1 AND 100) AND amount > 5 AND payment_date > '2006-01-01');
        
        
 -- We need to understand the special features in our films. Could you pull a list of films which
-- include a Behind the Scenes special feature?
SELECT title, special_features
FROM film
WHERE special_features LIKE "%Behind the scenes%";   
        
-- unique movie ratings and number of movies
SELECT rating, COUNT(film_id) AS total_films
FROM film
GROUP BY rating
ORDER BY total_films;  
        
-- Could you please pull a count of titles sliced by rental duration?
SELECT rental_duration, COUNT(title)
FROM film   
GROUP BY rental_duration;   
        
-- RATING, COUNT_MOVIES,LENGTH OF MOVIES AND COMPARE WITH RENTAL DURATION
SELECT RATING,
	COUNT(FILM_ID)  AS COUNT_OF_FILMS,
    MIN(LENGTH) AS SHORTEST_FILM,
    MAX(LENGTH) AS LONGEST_FILM,
    AVG(LENGTH) AS AVERAGE_FILM_LENGTH,
    AVG(RENTAL_DURATION) AS AVERAGE_RENTAL_DURATION
FROM FILM
GROUP BY RATING
ORDER BY AVERAGE_FILM_LENGTH;
        
 -- I’m wondering if we charge more for a rental when the replacement cost is higher.
-- Can you help me pull a count of films, along with the average, min, and max rental rate,
-- grouped by replacement cost?
SELECT REPLACEMENT_COST,
	COUNT(FILM_ID) AS NUMBER_OF_FILMS,
    MIN(RENTAL_RATE) AS CHEAPEST_RENTAL,
    MAX(RENTAL_RATE) AS EXPENSIVE_RENTAL,
    AVG(RENTAL_RATE) AS AVERAGE_RENTAL
FROM FILM
GROUP BY REPLACEMENT_COST
ORDER BY REPLACEMENT_COST;       
        
-- “I’d like to talk to customers that have not rented much from us to understand if there is something
-- we could be doing better. Could you pull a list of customer_ids with less than 15 rentals all-time?”
SELECT CUSTOMER_ID,COUNT(*) AS TOTAL_RENTALS
FROM RENTAL
GROUP BY CUSTOMER_ID
HAVING TOTAL_RENTALS < 15;

-- “I’d like to see if our longest films also tend to be our most expensive rentals.
-- Could you pull me a list of all film titles along with their lengths and rental rates, and sort them
-- from longest to shortest?”

SELECT TITLE,LENGTH,RENTAL_RATE
FROM FILM
ORDER BY LENGTH DESC
LIMIT 20;        
       
-- CATEGORIZE MOVIES AS PER LENGTH

SELECT TITLE,LENGTH,
	CASE
		WHEN LENGTH < 60 THEN 'UNDER 1 HR'
        WHEN LENGTH BETWEEN 60 AND 90 THEN '1 TO 1.5 HRS'
        WHEN LENGTH > 90 THEN 'OVER 1.5 HRS'
        ELSE 'ERROR'
	END AS LENGTH_BUCKET
FROM FILM;

-- CATEGORIZING MOVIES TO RECOMMEND VARIOUS AGE GROUPS AND DEMOGRAPHIC

SELECT DISTINCT TITLE,
	CASE
		WHEN RENTAL_DURATION <= 4 THEN 'RENTAL TOO SHORT'
        WHEN RENTAL_RATE >= 3.99 THEN 'TOO EXPENSIVE'
        WHEN RATING IN ('NC-17','R') THEN 'TOO ADULT'
        WHEN LENGTH NOT BETWEEN 60 AND 90 THEN 'TOO SHORT OR TOO LONG'
        WHEN DESCRIPTION LIKE '%Shark%' THEN 'NO_NO_HAS_SHARKS'
        ELSE 'GREAT_RECOMMENDATION_FOR_CHILDREN'
	END AS FIT_FOR_RECOMMENDATTION
FROM FILM;

-- “I’d like to know which store each customer goes to, and whether or
-- not they are active. Could you pull a list of first and last names of all customers, and
-- label them as either ‘store 1 active’, ‘store 1 inactive’, ‘store 2 active’, or ‘store 2 inactive’?”
SELECT CUSTOMER_ID,FIRST_NAME,LAST_NAME,
	CASE
		WHEN STORE_ID = 1 AND ACTIVE = 1 THEN 'store 1 active'
        WHEN STORE_ID = 1 AND ACTIVE = 0 THEN 'store 1 inactive'
        WHEN STORE_ID = 2 AND ACTIVE = 1 THEN 'store 2 active'
        WHEN STORE_ID = 2 AND ACTIVE = 0 THEN 'store 2 inactive'
        ELSE 'ERROR'
	END AS STORE_AND_STATUS
FROM CUSTOMER;

-- “Can you pull for me a list of each film we have in inventory?
-- I would like to see the film’s title, description, and the store_id value
-- associated with each item, and its inventory_id. Thanks!”
SELECT DISTINCT INVENTORY.INVENTORY_ID,INVENTORY.STORE_ID,FILM.TITLE,FILM.DESCRIPTION 
FROM FILM INNER JOIN INVENTORY
 ON FILM.FILM_ID = INVENTORY.FILM_ID;

-- Actor first_name, last_name and number of movies
SELECT * FROM FILM_ACTOR;
SELECT * FROM ACTOR;

SELECT ACTOR.ACTOR_ID,ACTOR.FIRST_NAME,ACTOR.LAST_NAME,COUNT(FILM_ACTOR.FILM_ID) AS NUMBER_OF_FILMS
FROM ACTOR LEFT JOIN FILM_ACTOR
ON ACTOR.ACTOR_ID = FILM_ACTOR.ACTOR_ID
GROUP BY ACTOR.ACTOR_ID
ORDER BY  NUMBER_OF_FILMS DESC;

-- “One of our investors is interested in the films we carry and how many actors are listed for each
-- film title. Can you pull a list of all titles, and figure out how many actors are
-- associated with each title?”
SELECT F.TITLE,COUNT(FA.ACTOR_ID) AS NUMBER_OF_ACTORS
FROM FILM  AS F LEFT JOIN FILM_ACTOR AS FA
ON F.FILM_ID = FA.FILM_ID
GROUP BY F.TITLE
ORDER BY  NUMBER_OF_ACTORS DESC;

-- “We will be hosting a meeting with all of our staff and advisors soon. Could you pull one list of all staff
-- and advisor names, and include a column noting whether they are a staff member or advisor? Thanks!”

SELECT * FROM STAFF;
SELECT * FROM ADVISOR;

(SELECT FIRST_NAME,LAST_NAME,'ADVISORS' AS DESIGNATION
FROM ADVISOR
UNION
SELECT FIRST_NAME,LAST_NAME,'STAFF MEMBER' AS DESIGNATION
FROM STAFF);



