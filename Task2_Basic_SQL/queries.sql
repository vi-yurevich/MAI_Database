-- №1 Выбрать все заказы (SALES_ORDER)
select sales_order_id, order_date, manager_id from sales_order;


-- №2 Выбрать все заказы, введенные после 1 января 2016 года
select sales_order_id, order_date, manager_id from sales_order
where order_date > to_date('2016-01-01', 'YYYY-MM-DD');


-- №3 Выбрать все заказы, введенные после 1 января 2016 года и до 15 июля 2016 года
select sales_order_id, order_date, manager_id from sales_order
where order_date > to_date('2016-01-01', 'YYYY-MM-DD')
    and order_date < to_date('2016-07-15', 'YYYY-MM-DD');


-- №4 Найти менеджеров с именем 'Henry'
select manager_id, manager_first_name, manager_last_name, office_id from manager
where 'henry' = lower(manager_first_name);


-- №5 Выбрать все заказы менеджеров с именем Henry
select sales_order_id, order_date, manager_id from sales_order
where manager_id in (
	select manager_id from manager
	where 'henry' = lower(manager_first_name));


-- №6 Выбрать все уникальные страны из таблицы CITY
select distinct country from city;


-- №7 Выбрать все уникальные комбинации страны и региона из таблицы CITY
select distinct country, region from city;


-- №8 Выбрать все страны из таблицы CITY с количеством городов в них.
select country, count(*) from city
group by country;


-- №9 Выбрать количество товаров (QTY), проданное с 1 по 30 января 2016 года.
select sum(product_qty) as product_qty_january
from sales_order_line
where sales_order_id in (
	select sales_order_id
	from sales_order
	where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
	and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'));


-- №10 Выбрать все уникальные названия городов, регионов и стран в одной колонке
select city_name as name from city
union
select region from city
union
select country from city;


-- №11 Выбрать имена и фамилии менеджеров, которые продали товаров на наибольшую сумму за январь 2016
select manager_first_name, manager_last_name from manager
where manager_id = (select T3.manager_id
                    from (select T1.manager_id,
                                 sum(T2.total_order_cost) as total_order_cost
                          from (select manager_id, sales_order_id
                                from sales_order
                                where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                  and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
                                   inner join ((select sales_order_id,
                                                       sum(product_qty * product_price) as total_order_cost
                                                from sales_order_line
                                                where sales_order_id in (select sales_order_id
                                                                         from sales_order
                                                                         where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                                           and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                                                group by sales_order_id) T2)
                                              on T1.sales_order_id = T2.sales_order_id
                          group by T1.manager_id) T3
                    where T3.total_order_cost = (select max(total_order_cost)
                                                 from (select T1.manager_id,
                                                              sum(T2.total_order_cost) as total_order_cost
                                                       from (select manager_id, sales_order_id
                                                             from sales_order
                                                             where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                               and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
                                                                inner join ((select sales_order_id,
                                                                                    sum(product_qty * product_price) as total_order_cost
                                                                             from sales_order_line
                                                                             where sales_order_id in
                                                                                   (select sales_order_id
                                                                                    from sales_order
                                                                                    where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                                                      and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                                                                             group by sales_order_id) T2)
                                                                           on T1.sales_order_id = T2.sales_order_id
                                                       group by T1.manager_id)));



-- Далее перечислены подзапросы запроса №11, от внутреннего к внешним

-- Номера заказов, сделанные в январе 2016
select sales_order_id as january_sales_order_id
from sales_order
where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
  and order_date <= to_date('2016-01-31', 'YYYY-MM-DD');


-- Пары (номер менеджера, номера его январских заказов)
select manager_id, sales_order_id as january_sales_order_id
from sales_order
where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
  and order_date <= to_date('2016-01-31', 'YYYY-MM-DD');


-- Пары (номер январского заказа, суммарная стоимость заказа)
select sales_order_id, sum(product_qty * product_price) as total_order_cost
from sales_order_line
where sales_order_id in (select sales_order_id as january_sales_order_id
                         from sales_order
                         where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                           and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
group by sales_order_id;


-- Пары (номер менеджера, суммарная стоимость одного из январских заказов)
select T1.manager_id,
       T2.total_order_cost
from (select manager_id, sales_order_id
      from sales_order
      where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
        and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
         inner join ((select sales_order_id,
                             sum(product_qty * product_price) as total_order_cost
                      from sales_order_line
                      where sales_order_id in (select sales_order_id
                                               from sales_order
                                               where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                 and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                      group by sales_order_id) T2)
                    on T1.sales_order_id = T2.sales_order_id;


-- Пары (номер менеджера, суммарная стоимость всех его январских заказов)
select T1.manager_id,
       sum(T2.total_order_cost) as total_order_cost
from (select manager_id, sales_order_id
      from sales_order
      where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
        and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
         inner join ((select sales_order_id,
                             sum(product_qty * product_price) as total_order_cost
                      from sales_order_line
                      where sales_order_id in (select sales_order_id
                                               from sales_order
                                               where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                 and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                      group by sales_order_id) T2)
                    on T1.sales_order_id = T2.sales_order_id
group by T1.manager_id;


-- Максимальная выручка за январь у одного менеджера
select max(total_order_cost)
from (select T1.manager_id,
             sum(T2.total_order_cost) as total_order_cost
      from (select manager_id, sales_order_id
            from sales_order
            where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
              and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
               inner join ((select sales_order_id,
                                   sum(product_qty * product_price) as total_order_cost
                            from sales_order_line
                            where sales_order_id in (select sales_order_id
                                                     from sales_order
                                                     where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                       and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                            group by sales_order_id) T2)
                          on T1.sales_order_id = T2.sales_order_id
      group by T1.manager_id);


-- Номера менеджеров, у которых выручка максимальна
select T3.manager_id
from (select T1.manager_id,
             sum(T2.total_order_cost) as total_order_cost
      from (select manager_id, sales_order_id
            from sales_order
            where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
              and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
               inner join ((select sales_order_id,
                                   sum(product_qty * product_price) as total_order_cost
                            from sales_order_line
                            where sales_order_id in (select sales_order_id
                                                     from sales_order
                                                     where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                       and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                            group by sales_order_id) T2)
                          on T1.sales_order_id = T2.sales_order_id
      group by T1.manager_id) T3
where T3.total_order_cost = (select max(total_order_cost)
                             from (select T1.manager_id,
                                          sum(T2.total_order_cost) as total_order_cost
                                   from (select manager_id, sales_order_id
                                         from sales_order
                                         where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                           and order_date <= to_date('2016-01-31', 'YYYY-MM-DD')) T1
                                            inner join ((select sales_order_id,
                                                                sum(product_qty * product_price) as total_order_cost
                                                         from sales_order_line
                                                         where sales_order_id in (select sales_order_id
                                                                                  from sales_order
                                                                                  where order_date >= to_date('2016-01-01', 'YYYY-MM-DD')
                                                                                    and order_date <= to_date('2016-01-31', 'YYYY-MM-DD'))
                                                         group by sales_order_id) T2)
                                                       on T1.sales_order_id = T2.sales_order_id
                                   group by T1.manager_id));