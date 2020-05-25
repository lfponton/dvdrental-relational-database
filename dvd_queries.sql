/*
Udacity Project: Investigate a Relational Database
DVD Rentals
The questions in this document correspond to the questions in the presentation.

Question 1: I want to understand what movies customers are watching the most
classified by categories, so I can prioritize my investments in the future.
I am specially interested in investing in movies in the 4th percentile, so I
would first like to have an overview of the distribution of the categories in
percentiles based to the amount of times movies in these categories have
been rented.
The question I want to answer with data is: What percentiles do the
different film categories fall into based on the amount of times movies in
these categories have been rented? */

WITH category_count AS (SELECT name,
                               COUNT(*) AS rental_counts
                        FROM category AS c
                        JOIN film_category AS fc
                        ON c.category_id = fc.category_id
                        JOIN film AS f
                        ON fc.film_id = f.film_id
                        JOIN inventory AS i
                        ON f.film_id = i.film_id
                        JOIN rental AS r
                        ON i.inventory_id = r.inventory_id
                        GROUP BY 1)

SELECT name,
       NTILE(4) OVER (ORDER BY rental_counts) AS percentile,
       rental_counts
FROM category_count
ORDER BY 3 DESC;

/*
Question 2:
In order to know in what countries to focus more, I would like to know what
countries rent most films. How are the number of rentals distributed worldwide?
*/

WITH country_rentals AS (SELECT co.country
                         FROM category AS ca
                         JOIN film_category AS fc
                         ON ca.category_id = fc.category_id
                         JOIN film AS f
                         ON fc.film_id = f.film_id
                         JOIN inventory AS i
                         ON f.film_id = i.film_id
                         JOIN rental AS r
                         ON i.inventory_id = r.inventory_id
                         JOIN customer AS cu
                         ON r.customer_id = cu.customer_id
                         JOIN address AS ad
                         ON cu.address_id = ad.address_id
                         JOIN city AS ci
                         ON ad.city_id = ci.city_id
                         JOIN country AS co
                         ON ci.country_id = co.country_id)

SELECT country,
       COUNT(*) AS rentals_count
FROM country_rentals
GROUP BY 1
ORDER BY 2 DESC;

/*
Question 3:
Now I want to know what categories are most popular (have a higher number of
rentals) per country. I will focus on countries with more than 500 rentals.
What are the most popular categories in countries with more than 500 rentals?
*/

WITH country_categories AS (SELECT ca.name, co.country
                            FROM category AS ca
                            JOIN film_category AS fc
                            ON ca.category_id = fc.category_id
                            JOIN film AS f
                            ON fc.film_id = f.film_id
                            JOIN inventory AS i
                            ON f.film_id = i.film_id
                            JOIN rental AS r
                            ON i.inventory_id = r.inventory_id
                            JOIN customer AS cu
                            ON r.customer_id = cu.customer_id
                            JOIN address AS ad
                            ON cu.address_id = ad.address_id
                            JOIN city AS ci
                            ON ad.city_id = ci.city_id
                            JOIN country AS co
                            ON ci.country_id = co.country_id),

     plus_500 AS (SELECT country,
                         COUNT(*)
                  FROM country_categories
                  GROUP BY 1
                  HAVING COUNT(*) > 500)

SELECT name, country,
       COUNT(*) AS rentals_count
FROM country_categories
WHERE country IN (SELECT country FROM plus_500)
GROUP BY 1, 2
ORDER BY 1 ASC, 3 DESC;

/* Question 4: Finally, I would like to know what percentage of the total revenue from
rentals theses countries represent out of the total, and the total sales
amount for each of them. I would like this query to be more customizable in
terms of choosing the countries */

WITH total_sales AS (SELECT SUM(amount)
                     FROM payment),

     country_payments AS (SELECT country, p.amount
                          FROM category AS ca
                          JOIN film_category AS fc
                          ON ca.category_id = fc.category_id
                          JOIN film AS f
                          ON fc.film_id = f.film_id
                          JOIN inventory AS i
                          ON f.film_id = i.film_id
                          JOIN rental AS r
                          ON i.inventory_id = r.inventory_id
                          JOIN payment AS p
                          ON r.rental_id = p.rental_id
                          JOIN customer AS cu
                          ON p.customer_id = cu.customer_id
                          JOIN address AS ad
                          ON cu.address_id = ad.address_id
                          JOIN city AS ci
                          ON ad.city_id = ci.city_id
                          JOIN country AS co
                          ON ci.country_id = co.country_id
                          WHERE co.country = 'India' OR
                          co.country = 'China' OR
                          co.country = 'United States' OR
                          co.country = 'Mexico' OR
                          co.country = 'Russian Federation' OR
                          co.country = 'Brazil' OR
                          co.country = 'Japan' OR
                          co.country = 'Philippines')

SELECT country,
       ROUND(SUM(amount)*100/(SELECT * FROM total_sales), 2) AS pct_total_sales,
       SUM(amount) AS sales
FROM country_payments
GROUP BY 1
ORDER BY 2 DESC;
