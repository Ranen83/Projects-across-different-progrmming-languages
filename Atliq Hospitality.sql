#total order lines = COUNT(total_order_id) = 33549
SELECT COUNT(order_id) AS total_order_lines FROM fact_order_lines;

#line fill rate = total orders shipped in full quanitity/total orders lines (not orders diff exist) = if i use 'if' command then I would get 
#inidviudal result not in proper format (LFR - order lines are as per orders nothing missing)
SELECT COUNT(order_id)/33549 AS LFR FROM fact_order_lines 
WHERE in_full='1';

#D - how such drastic change exists in VFR & LFR

#Volume Fill Rate (orders as per ordered qty full (herein we're considering all orders irrespective of in_full or 0n_time)
SELECT SUM(delivery_qty)/SUM(order_qty) AS VFR FROM fact_order_lines;

#ORDER means  wholesome not considering particulars witin an order
SELECT COUNT(order_id) AS total_orders FROM fact_orders_aggregate;

#On time delivery% of orders what does differntiating b/w orders and order lines denote 59.03%
SELECT COUNT(order_id)/31729 AS OTD FROM fact_orders_aggregate
WHERE on_time='1';

#In full qunatity order % 52.78%
SELECT COUNT(order_id)/31729 AS IFQO FROM fact_orders_aggregate
WHERE in_full='1';

#OTIF % 29.02 pct
SELECT COUNT(order_id)/31729 FROM fact_orders_aggregate
WHERE otif='1';

#these targets are the benchmark to match OTIF, IF,OTD 
#On_time_target_pct avg 86%
SELECT AVG(ontime_target_pct) AS average_OTT FROM dim_targets_orders;

#in_full_target_pct 76%
SELECT AVG(infull_target_pct) AS average_IFT FROM dim_targets_orders;

#avg OTIF 65%
SELECT AVG(otif_target_pct) AS average_OTIF FROM dim_targets_orders;

SELECT @@sql_mode;
SET @@sql_mode = SYS.LIST_DROP(@@sql_mode, 'ONLY_FULL_GROUP_BY');
SELECT @@sql_mode; 

#finding out LFR% for per customer
SELECT *,
(delivery_qty*100)/order_qty AS VoFR_pct FROM fact_order_lines 
GROUP BY customer_id;


# from below calculations I think even if LIFR is in 'in full' in data but difference exist in pct_value due  
WITH X as
(SELECT customer_id,
SUM(CASE WHEN In_Full = '1' THEN 1 ELSE 0 END)*100/ count(*) AS LiFR_pct,
SUM(delivery_qty) AS delivery_qty,
SUM(order_qty) AS order_qty
FROM fact_order_lines
GROUP BY customer_id)
SELECT customer_id,LiFR_pct,
SUM(delivery_qty)*100 /SUM(order_qty) AS VoFR_pct
FROM x
GROUP BY customer_id;

SELECT COUNT(order_id) AS total_orders FROM fact_orders_aggregate;

#on time pct, infull, otif for each customer
WITH X as
(SELECT customer_id,
COUNT(*) AS total_orders, 
SUM(CASE WHEN on_time = '1' THEN 1 ELSE 0 END)  AS ontime_ct,
SUM(CASE WHEN in_full = '1' THEN 1 ELSE 0 END) AS infull_ct,
SUM(CASE WHEN otif= '1' THEN 1 ELSE 0 END) AS otif_ct
FROM fact_orders_aggregate
GROUP BY customer_id
),
Y as
(SELECT customer_id,
total_orders,
ontime_ct,
infull_ct,
otif_ct,
(ontime_ct*100)/total_orders AS ontime_pct,
(infull_ct*100)/total_orders AS infull_pct,
(otif_ct*100)/total_orders AS otif_pct
FROM X
GROUP BY customer_id,total_orders,ontime_ct,infull_ct,otif_ct
)
SELECT * FROM Y
LIMIT 0,1000000;

#can otif_pct be such low than otif_pct
SELECT lv.customer_id,c.city,lv.LiFR_pct,lv.VoFR_pct,ot.ontime_pct,t.ontime_target_pct,ot.infull_pct,t.infull_target_pct,ot.otif_pct,t.otif_target_pct
FROM lifr_vofr_pct lv
JOIN ot_if_otif_pct ot ON lv.customer_id=ot.customer_id
JOIN dim_targets_orders t ON lv.customer_id=t.customer_id
JOIN dim_customers c ON lv.customer_id=c.customer_id

WITH X as
(SELECT p.product_id,p.product_name,p.category,
SUM(CASE WHEN In_Full = '1' THEN 1 ELSE 0 END)*100/ count(*) AS LiFR_pct,
SUM(delivery_qty) AS delivery_qty,
SUM(order_qty) AS order_qty
FROM fact_order_lines
GROUP BY product_id)
SELECT customer_id,LiFR_pct,
SUM(delivery_qty)*100 /SUM(order_qty) AS VoFR_pct
FROM x
GROUP BY customer_id;


WITH X as
(SELECT fl.product_id,p.product_name,
SUM(CASE WHEN In_Full = '1' THEN 1 ELSE 0 END)*100/ count(*) AS LiFR_pct,
SUM(delivery_qty) AS delivery_qty,
SUM(order_qty) AS order_qty
FROM fact_order_lines fl
JOIN dim_products p ON p.product_id=fl.product_id
GROUP BY product_id
)
SELECT product_id,product_name, LiFR_pct,
SUM(delivery_qty)*100 /SUM(order_qty) AS VoFR_pct
FROM x
GROUP BY product_id;