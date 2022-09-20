use sakila;

-- Instructions

-- 1. How many copies of the film Hunchback Impossible exist in the inventory system?

select * from inventory;
select * from film;

-- step 1: subquery of the film's name
select film_id, title from film where title = "Hunchback Impossible";

-- step 2: final query
select count(film_id) as total_copies from inventory
where film_id in (
	select film_id from (
		select film_id, title 
        from film
        where title = "Hunchback Impossible"
    )sub1
);


-- 2. List all films whose length is longer than the average of all the films.

select * from film;

-- step 1: get the avg of all the films
select avg(length) as average_length from film;

-- step 2: final query
select * 
from film
where length > (
	select avg(length) as average_length from film
);


-- 3. Use subqueries to display all actors who appear in the film Alone Trip.

select * from actor;
select * from film_actor;
select * from film;

-- step 1: Get the film
select film_id, title from film where title = "Alone Trip";


-- step 2: Get the actor that we are interested in
select actor_id
from film_actor
where film_id = (
	select film_id from film where title = "Alone Trip"
);

-- step 3: final query
select actor_id, first_name, last_name
from actor
where actor_id in (
	select actor_id from (
		select actor_id
		from film_actor
		where film_id = (
			select film_id from film where title = "Alone Trip"
		)
	)sub1
);


-- 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.

select * from film;
select * from category;
select * from film_category;

-- step 1: Get the family rated movies
select category_id from category where name = "family";

-- step 2: Get the movies rated with the category
select film_id
from film_category
where category_id = (
	select category_id from category where name = "family"
);

-- step 3: final query
select *
from film
where film_id in (
	select film_id
	from film_category
	where category_id = (
	select category_id from category where name = "family"
	)
);

-- 5. Get name and email from customers from Canada using subqueries. Do the same with joins. 
-- Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.

select * from customer; -- address_id
select * from address; -- city_id
select * from city; -- country_id
select * from country; -- country

-- step 1: Get the Canada country_id
select country_id from country where country = "Canada";

-- step 2: Get the city
select city_id from city
where country_id = (
	select country_id from country where country = "Canada"
);

-- step 3: Get the address
select address_id from address
where city_id in (
	select city_id from city
	where country_id = (
		select country_id from country where country = "Canada"
)
);

-- step 4: final query
select first_name, last_name, email
from customer
where address_id in (
	select address_id from address
	where city_id in (
		select city_id from city
		where country_id = (
			select country_id from country where country = "Canada"
		)
	)
);


# Now with JOINS

select first_name, last_name, email
from customer
join address using(address_id)
join city using (city_id)
join country using(country_id)
where country = "Canada";

### CONCLUSION:
### It's MUUUUCH MORE easier to do that with JOINS, so don't waist time in the future


-- 6. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films.
-- First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.

select * from film_actor;
select * from film;

-- step 1: Finding the most prolific actor
select actor_id, count(film_id) as number_films from film_actor group by actor_id order by count(film_id) desc limit 1;

-- step 2: Find the movies (film_id), not yet the final query
select film_id
from film_actor
where actor_id in (
	select actor_id, count(film_id) as number_films 
    from film_actor 
    group by actor_id 
    order by count(film_id) desc 
    limit 1
); -- This doesn't work, so I'll make the same but with a rank

-- new step 1: Ranking the actors by number of films played
select actor_id, count(film_id) as number_films, rank() over(order by count(film_id) desc) as ranking from film_actor group by actor_id;

-- new step 2: Getting the most prolific one
select actor_id from (
	select actor_id, count(film_id) as number_films, rank() over(order by count(film_id) desc) as ranking from film_actor group by actor_id
)sub1
where ranking = 1;

-- new step 3: Getting the list with the movies
select film_id
from film_actor
where actor_id in (
	select actor_id from (
		select actor_id, count(film_id) as number_films, rank() over(order by count(film_id) desc) as ranking 
        from film_actor 
        group by actor_id
	)sub1
	where ranking = 1
);


-- step 4: final query
select title
from film
where film_id in (
	select film_id
	from film_actor
	where actor_id in (
		select actor_id from (
			select actor_id, count(film_id) as number_films, rank() over(order by count(film_id) desc) as ranking 
			from film_actor 
			group by actor_id
		)sub1
		where ranking = 1
	)
);


-- 7. Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments

select * from payment;
select * from film;
select * from rental;
select * from inventory;

-- step 1: Get the sum of payments per customer_id
select customer_id, sum(amount) as total_payments, rank() over(order by sum(amount) desc) as customer_ranking from payment group by customer_id;

-- step 2: Getting the most profitable customer
select customer_id from (
	select customer_id, sum(amount) as total_payments, rank() over(order by sum(amount) desc) as customer_ranking 
    from payment 
    group by customer_id
)sub1
where customer_ranking = 1;

-- step 3: Get the copies of films what rented our best customer
select inventory_id
from rental
where customer_id in (
	select customer_id from (
		select customer_id, sum(amount) as total_payments, rank() over(order by sum(amount) desc) as customer_ranking 
		from payment 
		group by customer_id
	)sub1
	where customer_ranking = 1
);

-- step 4: Films per film_id
select film_id
from inventory
where inventory_id in (
	select inventory_id
	from rental
	where customer_id in (
		select customer_id from (
			select customer_id, sum(amount) as total_payments, rank() over(order by sum(amount) desc) as customer_ranking 
			from payment 
			group by customer_id
		)sub1
		where customer_ranking = 1
	)
);

-- step 5: Final query
select film_id, title
from film
where film_id in (
	select film_id
	from inventory
	where inventory_id in (
		select inventory_id
		from rental
		where customer_id in (
			select customer_id from (
				select customer_id, sum(amount) as total_payments, rank() over(order by sum(amount) desc) as customer_ranking 
				from payment 
				group by customer_id
			)sub1
			where customer_ranking = 1
		)
	)
);



-- 8. Get the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client.

select * from payment;

-- step 1:
select customer_id, sum(amount) as total_amount_spent from payment group by customer_id; -- This is the total amount spent by each customer

-- step 2: Getting the average of the total amount of payments
select avg(total_amount_spent) as average_payments from (
	select customer_id, sum(amount) as total_amount_spent 
    from payment 
    group by customer_id
)sub1;

-- step 3: Final query
select customer_id, sum(amount) as total_amount_spent 
from payment 
group by customer_id
having total_amount_spent > (
	select avg(total_amount_spent) as average_payments from (
		select customer_id, sum(amount) as total_amount_spent 
		from payment 
		group by customer_id
	)sub1
)
order by total_amount_spent desc;


