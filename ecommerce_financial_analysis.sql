USE Ecomerce_Analyzes;

select c.country, count(o.status) as order_Completed
from customers c
join orders o
on c.customer_id = o.customer_id
where o.status not in ('Cancelled','Returned')
group by c.country
order by order_Completed DESC;

SELECT 
    p.category,
    SUM(o.quantity) AS total_items_sold,
    SUM(o.quantity * p.retail_price) AS total_realized_revenue
FROM orders o
INNER JOIN products p 
    ON o.product_id = p.product_id
WHERE o.status IN ('Completed', 'Shipped')
GROUP BY p.category
ORDER BY total_items_sold DESC;

SELECT 
    p.category,
    SUM(o.quantity) AS total_items_returned_or_cancelled,
    SUM(o.quantity * p.retail_price) AS potential_revenue_lost
FROM orders o
INNER JOIN products p 
    ON o.product_id = p.product_id
WHERE o.status IN ('Cancelled', 'Returned')
GROUP BY p.category
ORDER BY total_items_returned_or_cancelled DESC;


SELECT 
    p.category,
    -- 1. Calculate the total investment (Cost of Goods Sold)
    SUM(o.quantity * p.unit_cost) AS total_investment_cost,
    
    -- 2. Calculate the total money brought in (Gross Revenue)
    SUM(o.quantity * p.retail_price) AS total_revenue,
    
    -- 3. Calculate the actual Net Profit
    SUM(o.quantity * (p.retail_price - p.unit_cost)) AS net_profit,
    
    -- 4. Calculate the ROI Percentage
    ROUND(
        (SUM(o.quantity * (p.retail_price - p.unit_cost)) / SUM(o.quantity * p.unit_cost)) * 100, 
    2) AS roi_percentage
FROM orders o
INNER JOIN products p 
    ON o.product_id = p.product_id
WHERE o.status IN ('Completed', 'Shipped')
GROUP BY p.category
ORDER BY roi_percentage DESC;
