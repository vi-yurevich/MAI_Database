-- Иерархические запросы

CREATE TABLE file_system (
    file_id INTEGER NOT NULL,
    file_name VARCAHR2(1000 CHAR) NOT NULL,
    file_type CHAR(1 BYTE) NOT NULL,
    path VARCAHR2(4000),
    parent_id INTEGER
);

ALTER TABLE file_system ADD CONSTRAINT file_system_pk PRIMARY KEY ( file_id );

ALTER TABLE file_system
    ADD CONSTRAINT file_system_file_system_fk FOREIGN KEY ( parent_id )
    REFERENCES file_system ( file_id );

-- Идея:
select * from file_system where parent_id is null
union all
select * from file_system where parent_id in (select file_id from file_system where parent_id is null)
union all
select * from file_system where parent_id in (select file_id from file_system where parent_id in (select file_id from file_system where parent_id is null))
union all
select * from file_system where parent_id in (select file_id from file_system where parent_id in (select file_id from file_system where parent_id in (select * from file_system where parent_id is null)));
-- итд....


-- Синтаксис Oracle

select file_id, file_name, file_type, parent_id from file_system
connect by parent_id = prior file_id -- ключевое слово prior ставится перед атрибутом, который берётся из предыдущей выборки
start with parent_id is null; -- начальное условие
-- то есть при новом выборе мы берём такие parent_id, которые есть в множестве file_id из предыдущей итерации
-- "возьми вершины, у которых в качестве родителя указана какая-либо из вершин, которую получили на предыдущем шаге"


-- level - гулбина, колонка, которая вычислима по иерархии
-- это обход сверху вниз
select file_id, file_name, file_type, parent_id, level from file_system
where level < 3
connect by parent_id = prior file_id 
start with parent_id is null;


-- обход снизу вверх
select file_id, file_name, file_type, parent_id, level from file_system
connect by file_id = prior parent_id  -- мы 
start with file_id = 8;


-- SYS_CONNECT_BY_PATH() - ф-ция конкатенирует заданные в аргументах поля, образуя путь от корня до текущего узла
select 
    file_id, 
    file_name, 
    file_type, 
    parent_id, 
    level,
    SYS_CONNECT_BY_PATH(file_path, '/')
from file_system
connect by parent_id = prior file_id 
start with parent_id is null;


-- Бывают иерархии с циклами, в таком случае запрос выкинет исключение
-- Если нам всё таки нужен результат запроса, добавляем ключевое слово nocycle, 
-- в таком случае при обнаружении цикла произойдёт остановка выборки данных
-- Чтобы понять где обнаружен цикл добавляем псевдоколонку CONNECT_BY_ISCYCLE.
-- Значение в ней будет равно 1, в месте где был обнаружен цикл.
select 
    file_id, 
    file_name, 
    file_type, 
    parent_id, 
    level,
    SYS_CONNECT_BY_PATH(file_path, '/'),
    CONNECT_BY_ISCYCLE
from file_system
connect by nocycle parent_id = prior file_id 
start with parent_id is null;


-- Если в дереве несколько корней, то можно вывести CONNCECT_BY_ROOT()
-- Эта колонка выведет самый первый элемент в этой иерархии.
-- CONNECT_BY_ISLEAF - показявает является ли вершина листом 
select 
    CONNECT_BY_ISCYCLE,
    CONNCECT_BY_ROOT(file_id),
    CONNECT_BY_ISLEAF
from file_system
connect by nocycle parent_id = prior file_id 
start with parent_id is null;

-- Вывод в виде дерева
select 
    file_id,
    LPAD('   ', level) || file_name, 
    file_type, 
    parent_id, 
    level,
    SYS_CONNECT_BY_PATH(file_path, '/'),
    CONNECT_BY_ISCYCLE
from file_system
connect by nocycle parent_id = prior file_id 
start with parent_id is null;



-- Синтаксис ANSI для иерархических запросов

-- нужно указывать, какие колонки берём при рекурсивной выборке
-- подзапросы не поддерживаются
with r(file_id, file_name, file_type, parent_id) as (
    select * from file_system where parent_id is null
    union all
    select f.file_id, f.file_name, f.file_type, f.parent_id from file_system f inner join r on (f.parent_id = r.file_id)
)
select * from r;


-- Добавили уровень иерархии с помощью lvl и path, по сути по аналогии с рекурсией в обычном императивном ЯП
with r(file_id, file_name, file_type, parent_id, path) as (
    select file_id, file_name, file_type, parent_id, 1 lvl, '/' || file_name from file_system where parent_id is null -- "начальное значение рекурсии" это r
    union all
    select f.file_id, f.file_name, f.file_type, f.parent_id, r.lvl + 1, r.path || '/' || f.file_name 
    from file_system f inner join r on (f.parent_id = r.file_id) -- модификация начального значения 
)
select * from r;