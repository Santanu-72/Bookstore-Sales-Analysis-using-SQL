--Creating all the required tables

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title VARCHAR(255),
    author VARCHAR(255),
    genre VARCHAR(100),
    published_year INT,
    price DECIMAL(10,2),
    stock INT
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20),
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    book_id INT,
    order_date DATE,
    quantity INT,
    total_amount DECIMAL(10,2),

    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);

--Importing books, customers, orders Dataset from files

copy books
from 'D:\Sql Book Store Analysis Project\Datasets\Books.csv'
DELIMITER  ','
csv header;

copy customers
from 'D:\Sql Book Store Analysis Project\Datasets\Customers.csv'
DELIMITER  ','
csv header;

copy orders
from 'D:\Sql Book Store Analysis Project\Datasets\Orders.csv'
DELIMITER  ','
csv header;

--checking the datasets

select * from books;
select * from customers;
select * from orders;

-- Retrieve all books in the "Fiction" genre
SELECT * FROM books
where genre = 'Fiction';

-- Find books published after the year 1950
SELECT * FROM books
WHERE published_year < 1950;

-- List all customers from the Canada
SELECT * FROM customers
WHERE country  = 'Canada';

-- Show orders placed in November 2023
SELECT * FROM orders
WHERE order_date >= '2023-11-01'
  AND order_date < '2023-12-01';

-- Retrieve the total stock of books available
SELECT count(book_id) AS  Total_stock FROM books;

-- Find the details of the most expensive book
SELECT * FROM books
WHERE price = 
	(SELECT max(price) FROM books);

-- Show all customers who ordered more than 1 quantity of a book
SELECT o.customer_id, o.quantity, c.name
FROM orders o
INNER JOIN customers c 
ON o.customer_id = c.customer_id
WHERE o.quantity > 1
ORDER BY o.quantity desc;

-- Retrieve all orders where the total amount exceeds $20
SELECT * FROM orders
WHERE total_amount > 20;

-- List all genres available in the Books table
SELECT genre FROM books
group BY genre;

-- Find the book with the lowest stock
SELECT * FROM books
ORDER BY stock ASC 
LIMIT 1;

-- Calculate the total revenue generated from all orders
SELECT sum(total_amount ) FROM orders;

--Advance Queries

-- Retrieve the total number of books sold for each genre
SELECT b.genre, sum(o.quantity) AS total_books_sold
FROM books b 
INNER JOIN orders o 
ON b.book_id = o.book_id
GROUP BY b.genre 
ORDER BY total_books_sold desc;

-- Find the average price of books in the "Fantasy" genre
SELECT genre, avg(price) AS average_price FROM books 
GROUP BY genre
HAVING genre = 'Fantasy';

-- List customers who have placed at least 2 orders
SELECT c.name, count(o.customer_id) AS count_of_orders 
FROM customers AS c 
INNER JOIN orders AS o
ON c.customer_id = o.customer_id 
GROUP BY o.customer_id, c.name 
HAVING count(o.customer_id ) >= 2
ORDER BY count_of_orders desc;

-- Find the most frequently ordered book
SELECT book_id, count_of_books
FROM (
    SELECT 
        book_id,
        COUNT(book_id) AS count_of_books,
        MAX(COUNT(book_id)) OVER() AS max_count
    FROM orders
    GROUP BY book_id
) t
WHERE count_of_books = max_count;

-- Show the top 3 most expensive books of 'Fantasy' Genre 
SELECT *
FROM (
    SELECT 
        title,
        genre,
        price,
        RANK() OVER(PARTITION BY genre ORDER BY price DESC) AS rnk
    FROM books
    WHERE genre = 'Fantasy'
) t
WHERE rnk <= 3;

-- Retrieve the total quantity of books sold by each author
SELECT 
	b.author,
	sum(o.quantity) AS books_sold
FROM books AS b
INNER JOIN orders AS o
ON b.book_id = o.book_id
GROUP BY b.author
ORDER BY books_sold desc;

-- List the cities where customers who spent over $30 are located
SELECT
	c2.name,
	c.city,
	o.total_amount
FROM customers AS c
INNER JOIN orders AS o
ON c.customer_id = o.customer_id
INNER JOIN customers AS c2
ON c2.customer_id = c.customer_id
WHERE o.total_amount >= 30
ORDER BY o.total_amount desc;

-- Find the customer who spent the most on orders

WITH customer_spending AS(
	SELECT
		c.name,
		sum(o.total_amount) AS total_spending
	FROM customers AS c
	INNER JOIN orders AS o
	ON c.customer_id = o.customer_id 
	GROUP BY o.customer_id, c.name
)
SELECT * FROM customer_spending AS cs
WHERE 
	cs.total_spending = (SELECT max(total_spending) FROM customer_spending ) ;

-- Calculate the stock remaining after fulfilling all order
SELECT 
	b.title,
	b.stock - coalesce(sum(o.quantity),0) AS available_stock
FROM books AS b
left JOIN orders AS o
ON b.book_id = o.book_id
GROUP BY b.book_id, b.title, b.stock 
ORDER BY available_stock desc;

--Calculate the total revenue generated for each month and identify the growth trend over time.
SELECT 
    TO_CHAR(DATE_TRUNC('month', order_date), 'Mon YYYY') AS month,
    SUM(total_amount) AS revenue,
    COALESCE(
    	LAG(SUM(total_amount)) OVER(ORDER BY DATE_TRUNC('month', order_date)), 0) AS Growth_Per_Month
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date);

--Identify the top 3 customers who spent the most money on orders.
WITH customer_spending AS(
	SELECT
		c.name,
		sum(o.total_amount) AS total_spending,
		dense_rank() over(ORDER BY sum(o.total_amount) desc) AS rnk
	FROM customers AS c
	INNER JOIN orders AS o
	ON c.customer_id = o.customer_id 
	GROUP BY c.name, c.customer_id 
)
SELECT * FROM customer_spending
WHERE rnk <= 3;