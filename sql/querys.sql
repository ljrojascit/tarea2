


-- PARTE 1:
-- 1. co-stars
SELECT DISTINCT n1.name, n2.name 
FROM names AS n1
LEFT JOIN acted AS a1
ON n1.id = a1.name_id
LEFT JOIN acted AS a2
ON a1.title_id = a2.title_id
LEFT JOIN names AS n2
ON a2.name_id = n2.id
WHERE a1.name_id != a2.name_id;
















-- 2. recursiva co-stars indirectos de 'Kevin Bacon'
WITH RECURSIVE co_star(name1, name2) AS (
	SELECT DISTINCT n1.name, n2.name 
    FROM names AS n1
	LEFT JOIN acted AS a1
	ON n1.id = a1.name_id
	LEFT JOIN acted AS a2
	ON a1.title_id = a2.title_id
	LEFT JOIN names AS n2
	ON a2.name_id = n2.id
	WHERE a1.name_id != a2.name_id 
), 
indirect_co_star_bacon(name2) AS (
	SELECT name2 FROM co_star
	WHERE name1 = 'Kevin Bacon'
	UNION
	SELECT c2.name2
	FROM indirect_co_star_bacon AS c1
	LEFT JOIN co_star AS c2
	ON c1.name2 = c2.name1
) SELECT DISTINCT * FROM indirect_co_star_bacon;




-- 3. Lyudmila Saveleva
WITH RECURSIVE co_star(name1, name2) AS (
	SELECT DISTINCT n1.name, n2.name 
    FROM names AS n1
	LEFT JOIN acted AS a1
	ON n1.id = a1.name_id
	LEFT JOIN acted AS a2
	ON a1.title_id = a2.title_id
	LEFT JOIN names AS n2
	ON a2.name_id = n2.id
	WHERE a1.name_id != a2.name_id 
), 
indirect_co_star_saveleva(name2) AS (
	SELECT name2 FROM co_star
	WHERE name1 = 'Lyudmila Saveleva'
	UNION
	SELECT c2.name2
	FROM indirect_co_star_saveleva AS c1
	LEFT JOIN co_star AS c2
	ON c1.name2 = c2.name1
) SELECT DISTINCT * FROM indirect_co_star_saveleva;







-- 4.1
WITH RECURSIVE co_star(name1, name2) AS (
	SELECT DISTINCT n1.name, n2.name 
    FROM names AS n1
	LEFT JOIN acted AS a1
	ON n1.id = a1.name_id
	LEFT JOIN acted AS a2
	ON a1.title_id = a2.title_id
	LEFT JOIN names AS n2
	ON a2.name_id = n2.id
	WHERE a1.name_id != a2.name_id 
), 
indirect_co_star(name1, name2) AS (
	SELECT * 
    FROM co_star
    WHERE name1 = 'Kevin Bacon'
	UNION
	SELECT c1.name1, c2.name2
	FROM indirect_co_star AS c1
	LEFT JOIN co_star AS c2
	ON c1.name2 = c2.name1
) SELECT * FROM indirect_co_star;

-- 4.2
WITH RECURSIVE co_star(name1, name2) AS (
	SELECT DISTINCT n1.name, n2.name 
    FROM names AS n1
	LEFT JOIN acted AS a1
	ON n1.id = a1.name_id
	LEFT JOIN acted AS a2
	ON a1.title_id = a2.title_id
	LEFT JOIN names AS n2
	ON a2.name_id = n2.id
	WHERE a1.name_id != a2.name_id 
), 
indirect_co_star(name1, name2) AS (
	SELECT * 
    FROM co_star
	UNION
	SELECT c1.name1, c2.name2
	FROM indirect_co_star AS c1
	LEFT JOIN co_star AS c2
	ON c1.name2 = c2.name1
) SELECT * FROM indirect_co_star WHERE name1 = 'Kevin Bacon';





-- PARTE 2:
-- 1. Nombres de actores que han hecho 'Batman'
-- dos consultas: con y sin JOIN
-- EXPLAIN ANALYSE

-- join
explain analyze
select distinct n.name 
from acted as a
left join names as n 
on n.id = a.name_id
where role = 'Batman';
-- sin join
explain analyze
select distinct n.name 
from acted as a, names as n 
where n.id = a.name_id and role = 'Batman';


-- 2. EXPLAIN ANALYSE, tiempo ejecucion
-- ejecutar varias veces para tener un estimacion (tiempo de planificaicon cambia)
explain analyze
select distinct n.name 
from acted as a
left join names as n 
on n.id = a.name_id
where role = 'Batman';

-- usar btree indice en atributo role de la tabla acted
create index indice_btree on acted (role);

explain analyze
select distinct n.name 
from acted as a
left join names as n 
on n.id = a.name_id
where role = 'Batman';

drop index indice_btree;

-- 3. btree, hash, sin indice, analizar resultados (ATRIBUTOS PELICULAS 2022)
-- sin indices
explain analyse
select *
from titles
where release_year = 2022;
-- btree en release_year
create index indice_btree on titles (release_year);
explain analyse
select *
from titles
where release_year = 2022;
drop index indice_btree;
-- indice hash
create index indice_hash on titles using HASH (release_year);
explain analyse
select *
from titles
where release_year = 2022;
drop index indice_hash;

-- 4. ATRIBUTOS PELICULAS 2018 - 2020, btree, hash, sin indice
-- query base
explain analyze
select *
from titles
where release_year >= 2018
and release_year <= 2020;
-- indice btree
create index indice_btree on titles (release_year);
explain analyse
select *
from titles
where release_year >= 2018
and release_year <= 2020;
drop index indice_btree;
-- indice hash
create index indice_hash on titles using HASH (release_year);
explain analyse
select *
from titles
where release_year >= 2018
and release_year <= 2020;
drop index indice_hash;
