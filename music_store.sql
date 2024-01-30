USE music_store;

 -- Which city has the best customers? And returns one city that has the highest sum of invoice totals  

SELECT billing_city, SUM(total) AS Invoice_Total
FROM invoice
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- The best Cutomer: Who Spent the most money

SELECT customer.customer_id, 
	first_name, 
    last_name,
    CEIL(SUM(total)) AS total_spending
FROM customer
INNER JOIN invoice 
	ON customer.customer_id = invoice.customer_id
GROUP BY customer.customer_id, first_name, last_name
ORDER BY total_spending DESC
LIMIT 1;



-- Email, first name, last name & genre of all Rock Music listeners.

SELECT DISTINCT email, first_name, last_name
FROM customer
INNER JOIN invoice 
	ON customer.customer_id = invoice.customer_id
INNER JOIN invoice_line 
	ON invoice.invoice_id = invoice_line.invoice_id
WHERE track_id IN (
	SELECT track_id
	FROM track
	JOIN genre
		ON track.genre_id = genre.genre_id
	WHERE genre.name LIKE 'Rock'
)
ORDER BY email;

 -- Artists who have written the most rock music in our dataset. returns the Artist name and total track count of the top 10 rock bands. 

SELECT artist.artist_id, artist.name, COUNT(artist.artist_id) as number_of_songs
FROM track
INNER JOIN album2
	ON track.album_id = album2.album_id
INNER JOIN artist
	ON album2.artist_id = artist.artist_id
INNER JOIN genre
	ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC
LIMIT 10;


-- Return all the track names that have a song length longer than the average song length. 

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;


-- how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent 
WITH best_selling_artist AS (
	SELECT artist.artist_id as artist_id,
		artist.name as artist_name, 
		SUM(invoice_line.unit_price*invoice_line.quantity) as total_sales
	FROM invoice_line
	INNER JOIN track
		ON invoice_line.track_id = track.track_id
	INNER JOIN album2
		ON track.album_id = album2.album_id
	INNER JOIN artist
		ON album2.artist_id = artist.artist_id
	GROUP BY 1, 2
	ORDER BY 3 DESC
	LIMIT 1
)

SELECT customer.customer_id,
	customer.first_name,
    customer.last_name,
    best_selling_artist.artist_name,
	ROUND(SUM(invoice_line.unit_price*invoice_line.quantity), 2) as amount_spent
FROM invoice
JOIN customer
	ON invoice.customer_id = customer.customer_id 
JOIN invoice_line
	ON invoice.invoice_id = invoice_line.invoice_id
JOIN track  
	ON invoice_line.track_id = track.track_id 
JOIN album2 
	ON track.album_id = album2.album_id 
JOIN best_selling_artist 
	ON album2.artist_id = best_selling_artist.artist_id 
GROUP BY 1,2,3,4
ORDER BY 5 DESC;


/* We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. */

WITH popular_genre As (
	SELECT customer.country,
		genre.name as genre_name,
		genre.genre_id,
		COUNT(invoice_line.quantity) as purchase,
		DENSE_RANK() OVER(
			PARTITION BY customer.country
			ORDER BY COUNT(invoice_line.quantity) DESC
		) AS rk
	FROM invoice_line
	JOIN invoice
		ON invoice_line.invoice_id = invoice.invoice_id
	JOIN customer
		ON invoice.customer_id = customer.customer_id
	JOIN track  
		ON invoice_line.track_id = track.track_id 
	JOIN genre
		ON track.genre_id = genre.genre_id
	GROUP BY 1, 2, 3
	ORDER BY 1 ASC ) 
SELECT *
FROM popular_genre
WHERE rk = 1;


--  customer that has spent the most on music for each country
WITH customer_rank AS (
	SELECT customer.country as country,
		customer.first_name as first_name,
		customer.last_name as last_name,
		ROUND(SUM(invoice.total), 2) AS total_spending,
		DENSE_RANK () OVER(
			PARTITION BY customer.country
			ORDER BY SUM(invoice.total) DESC
		) as rk
	FROM customer
	JOIN invoice
		ON customer.customer_id = invoice.customer_id
	GROUP BY 1, 2, 3
	ORDER BY 1)

SELECT country,
	first_name,
    last_name,
    total_spending
FROM customer_rank
WHERE rk = 1;