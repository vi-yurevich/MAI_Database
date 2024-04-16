-- №2 Компания хочет оптимизировать количество офисов, проанализировав относительные объемы продаж по офисам
-- в течение периода с 2013-2014 гг.
-- Выведите год, office_id, city_name, country, относительный объем продаж за текущий год
-- Офисы, которые демонстрируют наименьший относительной объем в течение двух лет скорее всего будут закрыты.
WITH step1 AS (SELECT TRUNC(sale_date, 'year') AS year_,
                      office_id,
                      office_name,
                      city_id,
                      city_name,
                      country,
                      SUM(sale_amount) OVER (
                        PARTITION BY office_id,
                                     office_name,
                                     city_id,
                                     city_name,
                                     TRUNC(sale_date, 'year')
                                     ) AS office_sales_amount, SUM(sale_amount) OVER (
                                        PARTITION BY TRUNC(sale_date, 'year')) AS year_sale_amount
               FROM V_FACT_SALE
               WHERE sale_date BETWEEN TO_DATE('2013-01-01', 'YYYY-MM-DD') AND TO_DATE('2014-12-31', 'YYYY-MM-DD'))
SELECT DISTINCT year_,
                office_id,
                city_name,
                country,
                (office_sales_amount / year_sale_amount) AS relative_sales_volume
FROM step1
ORDER BY relative_sales_volume;



-- №3 Для планирования закупок, компанию оценивает динамику роста продаж по товарам.
-- Динамика оценивается как отношение объема продаж в текущем месяце к предыдущему.
-- Выведите товары, которые демонстрировали наиболее высокие темпы роста продаж в течение первого полугодия 2014 года.
WITH step1 AS (SELECT TRUNC(sale_date, 'mm') AS sale_month,
                      product_id,
                      product_name,
                      sum(sale_qty) AS qty
               FROM V_FACT_SALE
               WHERE sale_date BETWEEN TO_DATE('2013-12-01', 'YYYY-MM-DD') AND TO_DATE('2014-06-30', 'YYYY-MM-DD')
               GROUP BY TRUNC(sale_date, 'mm'), product_id, product_name),
     step2 AS (SELECT sale_month,
                      product_id,
                      product_name,
                      qty,
                      SUM(QTY) OVER (PARTITION BY product_id, product_name
                       ORDER BY sale_month
                       RANGE BETWEEN INTERVAL '1' MONTH PRECEDING AND INTERVAL '1' MONTH PRECEDING
                 ) prev_month_qty
               FROM step1)
SELECT sale_month,
       product_id,
       product_name,
       qty / prev_month_qty AS dynamic
FROM step2
WHERE sale_month >= TO_DATE('2014-01-01', 'YYYY-MM-DD')
  AND qty / prev_month_qty IS NOT NULL
ORDER BY dynamic DESC;

-- №4 Напишите запрос, который выводит отчет о прибыли компании за 2014 год: помесячно и поквартально.
-- Отчет включает сумму прибыли за период и накопительную сумму прибыли с начала года по текущий период.
WITH step1 AS (
    SELECT TRUNC(sale_date, 'mm') AS mnth,
       SUM(sale_amount) AS sale_amount_mnth
    FROM V_FACT_SALE
    WHERE sale_date BETWEEN TO_DATE('2014-01-01', 'YYYY-MM-DD') AND TO_DATE('2014-12-31', 'YYYY-MM-DD')
    GROUP BY TRUNC(sale_date, 'mm')
)
SELECT mnth,
       TRUNC(mnth, 'Q') AS   quartet,
       sale_amount_mnth,
       SUM(sale_amount_mnth) OVER (ORDER BY mnth) sale_amount_mnth_cum,
       SUM(sale_amount_mnth) OVER (PARTITION BY TRUNC(mnth, 'Q')) sales_amount_quarter,
       SUM(sale_amount_mnth) OVER (ORDER BY TRUNC(mnth, 'Q') RANGE UNBOUNDED PRECEDING) AS sales_amount_quarter_cum
FROM step1;

-- №5 Найдите вклад в общую прибыль за 2014 год 10% наиболее дорогих товаров и 10% наиболее дешевых товаров.
-- Выведите product_id, product_name, total_sale_amount, percent
with step1 as (
    SELECT
        product_id,
        product_name,
        SUM(sale_amount) total_sales_amount
    FROM
        V_FACT_SALE
    WHERE sale_date BETWEEN TO_DATE('2014-01-01', 'YYYY-MM-DD') AND TO_DATE('2014-12-31', 'YYYY-MM-DD')
    GROUP BY product_id, product_name
),
     step2 AS (
         SELECT
             product_id,
             product_name,
             total_sales_amount,
             CUME_DIST(total_sales_amount) OVER(ORDER BY total_sales_amount) percent
         FROM
             step1
     )
SELECT
    product_id,
    product_name,
    total_sales_amount,
    percent
FROM
    step2
WHERE percent <= 0.10 OR percent >= 0.90;


-- №6 Компания хочет премировать трех наиболее продуктивных (по объему продаж, конечно) менеджеров в каждой стране в 2014 году.
-- Выведите country, <список manager_last_name manager_first_name, разделенный запятыми> которым будет выплачена премия
with step1 as (
    SELECT
        country,
        manager_id,
        manager_first_name,
        manager_last_name,
        SUM(sale_amount) volume_of_sales
    FROM
        V_FACT_SALE
    WHERE sale_date BETWEEN TO_DATE('2014-01-01', 'YYYY-MM-DD') AND TO_DATE('2014-12-31', 'YYYY-MM-DD')
    GROUP BY country, manager_id, manager_first_name, manager_last_name
),
     step2 AS (
         SELECT
             country,
             manager_id,
             manager_first_name,
             manager_last_name,
             ROW_NUMBER() OVER (PARTITION BY country ORDER BY volume_of_sales DESC) index_in_partition
         FROM
             step1
     )
SELECT
    country,
    LISTAGG(manager_last_name || ' ' || manager_first_name, ', ') WITHIN GROUP (ORDER BY manager_id) top_3_managers_list
FROM
    step2
WHERE index_in_partition <= 3
GROUP BY COUNTRY;


-- №7 Выведите самый дешевый и самый дорогой товар, проданный за каждый месяц в течение 2014 года.
-- cheapest_product_id, cheapest_product_name, expensive_product_id, expensive_product_name, month, cheapest_price, expensive_price
WITH step1 AS (SELECT TRUNC(sale_date, 'mm') AS sale_month,
                      product_id,
                      product_name,
                      sale_price,
                      MAX(sale_price)  OVER (PARTITION BY TRUNC(sale_date, 'mm')) AS max_price,
                      MIN(sale_price) OVER (PARTITION BY TRUNC(sale_date, 'mm')) AS min_price
               FROM V_FACT_SALE
               WHERE TRUNC(sale_date, 'mm') BETWEEN TO_DATE('2014-01-01', 'YYYY-MM-DD')
                         AND TO_DATE('2014-12-31', 'YYYY-MM-DD')),
     step2 AS (SELECT sale_month,
                      product_id   cheapest_product_id,
                      product_name cheapest_product_name,
                      sale_price   cheapest_price
               FROM step1
               WHERE sale_price = min_price),
     step3 AS (SELECT sale_month,
                      product_id   expensive_product_id,
                      product_name expensive_product_name,
                      sale_price   expensive_price
               FROM step1
               WHERE sale_price = max_price)
SELECT cheapest_product_id,
       cheapest_product_name,
       expensive_product_id,
       expensive_product_name,
       step2.sale_month,
       cheapest_price,
       expensive_price
FROM step2
         INNER JOIN step3 ON step2.sale_month = step3.sale_month;


-- №8 Менеджер получает оклад в 30 000 + 5% от суммы своих продаж в месяц. Средняя наценка стоимости товара - 10%
-- Посчитайте прибыль предприятия за 2014 год по месяцам (сумма продаж - (исходная стоимость товаров + зарплата))
-- month, sales_amount, salary_amount, profit_amount

WITH step1 AS (SELECT TRUNC(sale_date, 'mm')          AS mnth,
                      SUM(sale_amount)                AS manager_month_sale,
                      SUM(sale_amount) * 0.05 + 30000 AS manager_month_salary
               FROM v_fact_sale
               WHERE sale_date BETWEEN TO_DATE('2014-01-01', 'YYYY-MM-DD') AND TO_DATE('2014-12-31', 'YYYY-MM-DD')
               GROUP BY TRUNC(sale_date, 'mm'),
                        manager_id),
     step2 AS (SELECT mnth,
                      SUM(manager_month_sale) OVER (PARTITION BY mnth)    AS month_sale,
                      SUM(manager_month_salary) OVER (PARTITION BY mnth)  AS month_salary,
                      ROW_NUMBER() OVER (PARTITION BY mnth ORDER BY mnth) AS ind
               FROM step1)
SELECT mnth,
       month_sale - (month_sale * 0.9 + month_salary) AS month_income
FROM step2
WHERE ind = 1;