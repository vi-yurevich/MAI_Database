-- сильно упрощённый вариант запроса №11

-- все менеджеры
select manager_id, manager_first_name, manager_last_name from manager;


-- все январские заказы
select * from sales_order where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY');


-- пары (номер заказа, сумма по товару)
select sales_order_id, product_qty * product_price amount from sales_order_line;


-- менеджер, его заказы с суммой по каждому товару, проданному в январе
select manager_id, so.sales_order_id, product_qty * product_price amount
from sales_order so inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY');


-- менеджер и сумма всех его январских заказов
select manager_first_name, manager_last_name, sum(product_qty * product_price) amount
from sales_order so
         inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
         inner join manager m on m.manager_id = so.manager_id
where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
group by so.manager_id, manager_first_name, manager_last_name
order by amount desc;


-- максимальная сумма заказов за январь у одного менеджера
select max(sum(product_qty * product_price)) amount
from sales_order so
         inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
group by so.manager_id;


-- менеджер, продавший товаров на максимальную сумму в январе
select so.manager_id, manager_first_name, manager_last_name, sum(product_qty * product_price) amount
from sales_order so
         inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
         inner join manager m on m.manager_id = so.manager_id
where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
group by so.manager_id, manager_first_name, manager_last_name
having sum(product_qty * product_price) = (
    select max(sum(product_qty * product_price)) amount
    from sales_order so
             inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
    where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
    group by so.manager_id
);


-- хотим избавиться от двойного полного прохода sales_order_id
-- тут всё равно будет два полных прохода, но только уже не по всем данным, а по агрегированным
create view v_manager_sales as (
    select manager_first_name, manager_last_name, sum(product_qty * product_price) amount
    from sales_order so
            inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
            inner join manager m on m.manager_id = so.manager_id
    where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
    group by so.manager_id, manager_first_name, manager_last_name
);

-- используем, созданный view
select * from v_manager_sales where amount = (select max(amount) from v_manager_sales);


-- используем временное представление, которое используется в нашем запросе
-- это называется Common Table Expressions (CTE)
-- является альтернативой вложенным запросам
with tmp_manager_sales as (
    select manager_first_name, manager_last_name, sum(product_qty * product_price) amount
    from sales_order so
             inner join sales_order_line sol on so.sales_order_id = sol.sales_order_id
             inner join manager m on m.manager_id = so.manager_id
    where order_date between to_date('01-01-2016', 'DD-MM-YYYY') and to_date('31-01-2016', 'DD-MM-YYYY')
    group by so.manager_id, manager_first_name, manager_last_name
)
select * from tmp_manager_sales where amount = (select max(amount) from tmp_manager_sales);
