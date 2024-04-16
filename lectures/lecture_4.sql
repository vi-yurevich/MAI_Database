-- №1 Каждый месяц компания выдает премию в размере 5% от суммы продаж менеджеру,
-- который за предыдущие 3 месяца продал товаров на самую большую сумму.
-- Выведите месяц, manager_id, manager_first_name, manager_last_name,
-- премию за период с января по декабрь 2014 года

-- представление всех сджойненых таблиц
select *
from V_FACT_SALE;


-- Округляем до месяца и считаем сумму продаж за месяц
select trunc(SALE_DATE, 'mm'),
       manager_id,
       manager_first_name,
       manager_last_name,
       sum(sale_amount) sale_amount
from v_fact_sale
group by trunc(SALE_DATE, 'mm'),
         manager_id,
         manager_first_name,
         manager_last_name;


-- альтернативный вариант: пронумеровать месяца 2014, плюс три месяца предыдущего года
select SALE_DATE,
       floor(months_between(sale_date, to_date('01.01.2014', 'DD.MM.YYYY'))) month_no
from v_fact_sale
where floor(months_between(sale_date, to_date('01.01.2014', 'DD.MM.YYYY'))) between -2 and 12
order by month_no;


-- сколько продали за 3 предыдущих месяца
with step1 as (select trunc(SALE_DATE, 'mm') sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sum(sale_amount)       sale_amount
               from v_fact_sale
               group by trunc(SALE_DATE, 'mm'),
                        manager_id,
                        manager_first_name,
                        manager_last_name)
select sale_month,
       manager_id,
       manager_first_name,
       manager_last_name,
       sale_amount,
       sum(sale_amount) over (
            partition by manager_id
            order by sale_month
            range between interval '3' MONTH preceding and interval '1' month preceding
		    ) prev_sale_amount
from step1;


-- ранжируем по продажам за 3 месяца
with step1 as (select trunc(SALE_DATE, 'mm') sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sum(sale_amount)       sale_amount
               from v_fact_sale
               group by trunc(SALE_DATE, 'mm'),
                        manager_id,
                        manager_first_name,
                        manager_last_name),
     step2 as (select sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sale_amount,
                      sum(sale_amount) over (
                            partition by manager_id
                            order by sale_month
                            range between interval '3' MONTH preceding and interval '1' month preceding
		                    ) prev_sale_amount
               from step1)
select sale_month,
       manager_id,
       manager_first_name,
       manager_last_name,
       sale_amount,
       prev_sale_amount,
       rank() over (partition by sale_month order by prev_sale_amount desc NULLS LAST) rank
from step2
where sale_month between to_date('01.01.2014', 'DD.MM.YYYY') and to_date('31.12.2014', 'DD.MM.YYYY');

-- берём людей с рангом = 1 и вычисляем их бонус
with step1 as (select trunc(SALE_DATE, 'mm') sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sum(sale_amount)       sale_amount
               from v_fact_sale
               group by trunc(SALE_DATE, 'mm'),
                        manager_id,
                        manager_first_name,
                        manager_last_name),
     step2 as (select sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sale_amount,
                      sum(sale_amount) over (
        partition by manager_id
        order by sale_month
        range between interval '3' MONTH preceding and interval '1' month preceding
		) PREV_SALE_AMOUNT
               from step1),
     step3 as (select sale_month,
                      manager_id,
                      manager_first_name,
                      manager_last_name,
                      sale_amount,
                      prev_sale_amount,
                      rank() over (partition by sale_month order by prev_sale_amount desc NULLS LAST) rank
               from step2
               where sale_month between to_date('01.01.2014', 'DD.MM.YYYY') and to_date('31.12.2014', 'DD.MM.YYYY'))
select sale_month, manager_id, manager_first_name, manager_last_name, sale_amount * 0.05 BONUS, prev_sale_amount
from step3
where rank = 1;
-- Результат:
-- 01-JAN-14	362	Eugene	  Miller	66632.37	212209.55	3331.6185
-- 01-FEB-14	969	Gregory	  Cox	    160052.9	140929.22	8002.645
-- 01-MAR-14	813	Nancy	  Carter	58653.62	140901.5	2932.681
-- 01-APR-14	214	Lawrence  Gordon	78917.59	171632.29	3945.8795
-- 01-MAY-14	158	Kenneth	  Lynch	    42898.11	138905.34	2144.9055
-- 01-JUN-14	1	Walter	  Ford	    73768.98	171148.43	3688.449
-- 01-JUL-14	366	Michael	  Evans	    58563.19	163647.85	2928.1595
-- 01-AUG-14	1	Walter	  Ford	    45122.93	193947.72	2256.1465
-- 01-SEP-14	66	Jesse	  Graham	63875.24	235568.49	3193.762
-- 01-OCT-14	643	Theresa	  Stone	    94536.9	    127531.92	4726.845
-- 01-NOV-14	65	Michael	  White	    93472.31	111483.96	4673.6155
-- 01-DEC-14	926	Eric	  Ellis	    28086.04	101856.28	1404.302

-- проверка: кто продал больше всех за янв, фев, март (то есть кандидад на бонус в апреле)
select manager_id, manager_first_name, manager_last_name, sum(sale_amount)
from v_fact_sale
where sale_date between to_date('01.01.2014', 'DD.MM.YYYY') and to_date('31.03.2014', 'DD.MM.YYYY')
group by manager_id, manager_first_name, manager_last_name
order by sum(sale_amount) desc;
-- Результат: 191    Clarence	Woods	298960.83

-- видно, что человек, продавший больше всех в три предыдущих месяца, но, ничего не продавший в текущем месяцу, выведен
-- не будет. Если такой результат не соответствует требованиям заказчика, то решается это введением доп. строк:
with ALL_MONTHS as (select ADD_MONTHS(TO_DATE('1.10.2013', 'DD.MM.YYYY'), level - 1) MONTH
                    from dual
connect by level <= 15
    )
         , ALL_MANAGERS as (
select MANAGER_ID, MANAGER_FIRST_NAME, MANAGER_LAST_NAME
from MANAGER
    ), ALL_MANAGER_MONTHS as (
select *
from ALL_MONTHS cross join ALL_MANAGERS
    ), step1 as (
select
    MONTH SALE_MONTH, MM.MANAGER_ID, MM.MANAGER_FIRST_NAME, MM.MANAGER_LAST_NAME, SUM (SALE_AMOUNT) SALE_AMOUNT
from ALL_MANAGER_MONTHS MM left outer join V_FACT_SALE S
on (MM.MANAGER_ID = S.MANAGER_ID and MM.MONTH = trunc(S.SALE_DATE, 'mm'))
group by MONTH, MM.MANAGER_ID, MM.MANAGER_FIRST_NAME, MM.MANAGER_LAST_NAME
    ),
    step2 as (
select
    SALE_MONTH, MANAGER_ID, MANAGER_FIRST_NAME, MANAGER_LAST_NAME, SALE_AMOUNT, SUM (SALE_AMOUNT) over (
    partition by MANAGER_ID
    order by SALE_MONTH
    range between interval '3' MONTH preceding and interval '1' MONTH preceding
    ) PREV_SALE_AMOUNT
from step1
    ), step3 as (
select
    SALE_MONTH, MANAGER_ID, MANAGER_FIRST_NAME, MANAGER_LAST_NAME, SALE_AMOUNT, PREV_SALE_AMOUNT, RANK() over (partition by sale_month order by PREV_SALE_AMOUNT desc NULLS LAST) RANK
from step2
where SALE_MONTH between TO_DATE('01.01.2014'
    , 'DD.MM.YYYY')
  and TO_DATE('31.12.2014'
    , 'DD.MM.YYYY')
    )
select SALE_MONTH,
       MANAGER_ID,
       MANAGER_FIRST_NAME,
       MANAGER_LAST_NAME,
       SALE_AMOUNT,
       PREV_SALE_AMOUNT,
       SALE_AMOUNT * 0.05 BONUS
from step3
where RANK = 1;
-- Результат:
-- 01-JAN-14	362	Eugene	Miller	        66632.37	212209.55	3331.6185
-- 01-FEB-14	362	Eugene	Miller	        278841.92
-- 01-MAR-14	969	Gregory	Cox		        300982.12
-- 01-APR-14	191	Clarence	Woods		298960.83
-- 01-MAY-14	191	Clarence	Woods		298960.83
-- 01-JUN-14	191	Clarence	Woods		298960.83
-- 01-JUL-14	1	Walter	Ford		    244917.41
-- 01-AUG-14	366	Michael	Evans		    222211.04
-- 01-SEP-14	66	Jesse	Graham	        63875.24	235568.49	3193.762
-- 01-OCT-14	958	Sharon	Jackson		    203215.56
-- 01-NOV-14	244	Jeffrey	Fox		        179323.58
-- 01-DEC-14	65	Michael	White		    204956.27