create database restaurant;
-- CREATING DATA SET

CREATE TABLE sales (customer_id VARCHAR(1),order_date DATE,product_id INTEGER);

INSERT INTO sales
  (customer_id, order_date, product_id)
  
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant ?
select s.customer_id,sum(m.price) 
from sales as s join menu as m
on m.product_id = s.product_id
group by s.customer_id;


-- 2. How many days has each customer visited the restaurant ?
select customer_id,count(distinct(order_date)) as visiteddays from sales 
group by customer_id;


-- 3. What was the first item from the menu purchased by each customer ?
select s.customer_id,m.product_name,first_value(s.order_date) over(partition by s.customer_id order by s.order_date) as first_ord_date
from sales as s join menu as m
on s.product_id = m.product_id
group by s.customer_id ;

-- Customer A’s first order was sushi.
-- Customer B’s first order was curry.
-- Customer C’s first order was ramen


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select s.product_id,m.product_name,
count(s.product_id) as frequency
from sales as s join menu as m 
on s.product_id=m.product_id group by m.product_name order by count(s.product_id) desc limit 1;

with t as (
select s.customer_id,s.product_id,m.product_name,
count(s.product_id) as frequency
from sales as s join menu as m 
on s.product_id=m.product_id where s.product_id=3 group by s.customer_id,m.product_id)
select customer_id,product_id,product_name,sum(frequency) as total from t group by customer_id order by sum(frequency) desc ;


-- 5. Which item was the most popular for each customer?
with t as 
(select s.customer_id,s.product_id,m.product_name,count(s.product_id) as cnt,
dense_rank() over(partition by customer_id order by count(s.product_id) desc) as rnk
from sales as s join menu as m 
on s.product_id=m.product_id 
group by s.customer_id,s.product_id)
select * from t where rnk =1;


-- 6. Which item was purchased first by the customer after they became a member?

with t as (
select m.customer_id,m.join_date,s.order_date,me.product_name,
rank() over(partition by m.customer_id order by s.order_date ) as rnk
from members as m join sales as s 
on m.customer_id=s.customer_id
join menu as me 
on s.product_id=me.product_id where s.order_date > m.join_date)
select * from t where rnk=1;

-- 7. Which item was purchased just before the customer became a member?
with t as (
select m.customer_id,m.join_date,s.order_date,me.product_name,
rank() over(partition by m.customer_id order by s.order_date desc) as rnk
from members as m join sales as s 
on m.customer_id=s.customer_id
join menu as me 
on s.product_id=me.product_id where s.order_date < m.join_date)
select * from t where rnk=1;

-- 8. What is the total items and amount spent for each member before they became a member?

with t as (
select m.customer_id,me.price,
count(s.product_id)  as quantity , me.price * count(s.product_id) as total
from members as m join sales as s 
on m.customer_id=s.customer_id
join menu as me 
on s.product_id=me.product_id where s.order_date < m.join_date group by s.customer_id,s.product_id order by s.customer_id )
select customer_id,sum(quantity) as total_items,sum(total) as Grandtotal from t group by customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id,
sum(case s.product_id
when s.product_id=1 then m.price * 20
else m.price * 10
end) as points
from sales as s join menu as m 
on s.product_id = m.product_id group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


with t as (
select s.customer_id,s.order_date,m.join_date,
adddate(m.join_date,interval 6 day) as first_week,
last_day(m.join_date) as last_date,s.product_id,me.price
from sales as s left join members as m
on m.customer_id=s.customer_id
left join menu as me on
s.product_id = me.product_id)
select customer_id,
sum(case
when order_date between join_date and first_week then price*20
when (order_date not between join_date and first_week) and product_id=1 then price *20
else price *10
end)as points 
from t where order_date < '21-01-31' group by customer_id;


-- 11. Join All The Things, Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

-- joined all the records
with t as (
select s.customer_id,s.product_id,me.product_name,s.order_date,
case
when s.order_date >= m.join_date then 'Y'
else 'N'
end as Membership
from sales as s left join members as m
on m.customer_id=s.customer_id
left join menu as me on
s.product_id = me.product_id)
select * from t;


-- ranked all the records
with t as (
select s.customer_id,s.product_id,me.product_name,s.order_date,
case
when s.order_date >= m.join_date then 'Y'
else 'N'
end as Membership
from sales as s left join members as m
on m.customer_id=s.customer_id
left join menu as me on
s.product_id = me.product_id)
select *,
case 
when membership ='N' then null
else rank() over( partition by customer_id,membership order by order_date)
end as ranking
from t;
