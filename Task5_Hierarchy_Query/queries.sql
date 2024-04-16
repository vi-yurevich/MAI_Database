create table FILE_SYSTEM(
  ID        INTEGER,        -- Идентификатор файла или папки
  NAME      VARCHAR2(1000), -- имя файла/папки
  PARENT_ID INTEGER,        -- Ссылка на родительскую папку
  TYPE      VARCHAR2(100),  -- тип 'DIR' или 'FILE'
  FILE_SIZE INTEGER         -- собственный размер файла
);

alter table FILE_SYSTEM add primary key(ID);
alter table FILE_SYSTEM add foreign key(PARENT_ID) references FILE_SYSTEM(ID);



-- №1 Вывести все директории в виде:
-- ID, Название, Путь до корня

with r(id, name, parent_id, file_size, type, path) as (
    select id, name, parent_id, file_size, type, '/' || name from file_system where parent_id is null
    union all
    select f.id, f.name, f.parent_id, f.file_size, f.type, r.path || '/' || f.name
    from file_system f inner join r on (f.parent_id = r.id)
)
select * from r;


-- №2 Для каждой директории посчитать объем занимаемого места на диске (с учетом всех вложенных папок)
-- ID, Название, Путь до корня, total_size

with r1(id, name, parent_id, file_size, path) as (
    select id, name, parent_id, file_size, '/' || name from file_system where parent_id is null
    union all
    select f.id, f.name, f.parent_id, f.file_size, r1.path || '/' || f.name
    from file_system f inner join r1 on (f.parent_id = r1.id)
),
r2(id, name, parent_id, file_size, type, size_) as (
    select id, name, parent_id, file_size, type, 0 + file_size from file_system where type = 'FILE'
    union all
    select f.id, f.name, f.parent_id, f.file_size, f.type, r2.size_ + f.file_size
    from file_system f inner join r2 on (f.id = r2.parent_id)
),
step3 as (
    select id, name, sum(size_) total_size 
    from r2
    group by id, name
) 
select s3.id, s3.name, s3.total_size, r1.path
from step3 s3 inner join r1 on (s3.id = r1.id);


-- №3 Добавить в запрос: сколько процентов директория занимает места относительно всех среди своих соседей (siblings)
-- ID, Название, Путь до корня, total_size, ratio

with r1(id, name, parent_id, type, path) as (
    select id, name, parent_id, type, '/' || name from file_system where parent_id is null
    union all
    select f.id, f.name, f.parent_id, f.type, r1.path || '/' || f.name
    from file_system f inner join r1 on (f.parent_id = r1.id)
),
r2(id, parent_id, file_size, type, size_) as (
    select id, parent_id, file_size, type, 1 + file_size from file_system where type = 'FILE'
    union all
    select f.id, f.parent_id, f.file_size, f.type, r2.size_ + f.file_size
    from file_system f inner join r2 on (f.id = r2.parent_id)
),
step3 as (
    select id, sum(size_) total_size 
    from r2
    group by id
), 
step4 as (
    select s3.id, r1.parent_id, r1.name, s3.total_size, r1.path, r1.type
    from step3 s3 inner join r1 on (s3.id = r1.id)
),
step5 as (
    select id, parent_id, name, path, type, total_size, sum(total_size) over (partition by parent_id) parent_size
    from step4
)
select id, name, path, total_size, round(total_size / parent_size * 100, 2) ratio 
from step5;


-- №4 Проанализировать план выполнения последнего запроса и предложить вариант оптимизации.

explain plan for 
with r1(id, name, parent_id, type, path) as (
    select id, name, parent_id, type, '/' || name from file_system where parent_id is null
    union all
    select f.id, f.name, f.parent_id, f.type, r1.path || '/' || f.name
    from file_system f inner join r1 on (f.parent_id = r1.id)
),
r2(id, parent_id, file_size, type, size_) as (
    select id, parent_id, file_size, type, 1 + file_size from file_system where type = 'FILE'
    union all
    select f.id, f.parent_id, f.file_size, f.type, r2.size_ + f.file_size
    from file_system f inner join r2 on (f.id = r2.parent_id)
),
step3 as (
    select id, sum(size_) total_size 
    from r2
    group by id
), 
step4 as (
    select s3.id, r1.parent_id, r1.name, s3.total_size, r1.path, r1.type
    from step3 s3 inner join r1 on (s3.id = r1.id)
),
step5 as (
    select id, parent_id, name, path, type, total_size, sum(total_size) over (partition by parent_id) parent_size
    from step4
)
select id, name, path, total_size, round(total_size / parent_size * 100, 2) ratio 
from step5;

select * from table(dbms_xplan.display('plan_table', null, 'all'));