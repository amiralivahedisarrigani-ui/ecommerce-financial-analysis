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

--Factoring in unit costs, retail prices, item quantities, and checkout discounts, what is the true net profit and gross margin percentage for each product category month-over-month?

WITH MonthlyMetrics AS (
    SELECT 
        p.category,
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,

        -- Revenue after discount
        SUM(
            o.quantity * p.retail_price 
            * (1 - COALESCE(od.discount_rate, 0))
        ) AS total_revenue,

        -- Product cost
        SUM(
            o.quantity * p.unit_cost
        ) AS total_cost

    FROM orders o

    INNER JOIN order_details od
        ON o.order_id = od.order_id
        AND o.product_id = od.product_id

    INNER JOIN products p
        ON o.product_id = p.product_id

    WHERE o.status IN ('Completed', 'Shipped')

    GROUP BY 
        p.category,
        DATE_FORMAT(o.order_date, '%Y-%m')
),

ProfitMetrics AS (
    SELECT
        category,
        order_month,
        total_revenue,
        total_cost,

        -- Gross profit after discounts
        total_revenue - total_cost AS gross_profit

    FROM MonthlyMetrics
)

SELECT
    category,
    order_month,

    ROUND(total_revenue, 2) AS total_revenue,

    ROUND(gross_profit, 2) AS net_profit,

    -- Gross margin %
    ROUND(
        (gross_profit / NULLIF(total_revenue, 0)) * 100,
        2
    ) AS gross_margin_percentage,

    -- Previous month's profit
    ROUND(
        LAG(gross_profit) OVER (
            PARTITION BY category
            ORDER BY order_month
        ),
        2
    ) AS previous_month_profit,

    -- Month-over-month profit growth %
    ROUND(
        (
            gross_profit
            - LAG(gross_profit) OVER (
                PARTITION BY category
                ORDER BY order_month
            )
        )
        / NULLIF(
            LAG(gross_profit) OVER (
                PARTITION BY category
                ORDER BY order_month
            ),
            0
        ) * 100,
        2
    ) AS mom_profit_growth_percentage

FROM ProfitMetrics

ORDER BY 
    category,
    order_month;
