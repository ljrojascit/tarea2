---------------------------------------------------------------------
-- PARTE 1:
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
-- PARTE 2:
---------------------------------------------------------------------
-- 1.
-- todos los actores que han hecho rol de batman con JOIN
EXPLAIN ANALYZE
SELECT DISTINCT names.name
FROM names
JOIN acted on names.id = acted.name_id
WHERE acted.role = 'Batman';

-- Unique  (cost=1140.21..1140.22 rows=2 width=14) (actual time=4.217..4.224 rows=13 loops=1)
--  ->  Sort  (cost=1140.21..1140.21 rows=2 width=14) (actual time=4.217..4.219 rows=23 loops=1)
--        Sort Key: names.name
--        Sort Method: quicksort  Memory: 26kB
--        ->  Nested Loop  (cost=0.29..1140.20 rows=2 width=14) (actual time=0.378..4.200 rows=23 loops=1)
--              ->  Seq Scan on acted  (cost=0.00..1123.59 rows=2 width=4) (actual time=0.368..4.137 rows=23 loops=1)
--                    Filter: ((role)::text = 'Batman'::text)
--                    Rows Removed by Filter: 60024
--              ->  Index Scan using names_pkey on names  (cost=0.29..8.30 rows=1 width=18) (actual time=0.002..0.002 rows=1 loops=23)
--                    Index Cond: (id = acted.name_id)
-- Planning Time: 0.174 ms
-- Execution Time: 4.247 ms


-- todos los actores que han hecho rol de batman sin JOIN
EXPLAIN ANALYZE
SELECT DISTINCT names.name
FROM names, acted
WHERE names.id = acted.name_id
AND acted.role = 'Batman';

-- Unique  (cost=1140.21..1140.22 rows=2 width=14) (actual time=4.543..4.549 rows=13 loops=1)
--   ->  Sort  (cost=1140.21..1140.21 rows=2 width=14) (actual time=4.542..4.544 rows=23 loops=1)
--         Sort Key: names.name
--         Sort Method: quicksort  Memory: 26kB
--         ->  Nested Loop  (cost=0.29..1140.20 rows=2 width=14) (actual time=0.395..4.525 rows=23 loops=1)
--               ->  Seq Scan on acted  (cost=0.00..1123.59 rows=2 width=4) (actual time=0.380..4.443 rows=23 loops=1)
--                     Filter: ((role)::text = 'Batman'::text)
--                     Rows Removed by Filter: 60024
--               ->  Index Scan using names_pkey on names  (cost=0.29..8.30 rows=1 width=18) (actual time=0.003..0.003 rows=1 loops=23)
--                     Index Cond: (id = acted.name_id)
-- Planning Time: 0.188 ms
-- Execution Time: 4.572 ms



-- las dos consultas generan el mismo plan y tienen casi el mismo tiempo de ejecucion
-- el plan consiste en:
-- - sortear names por name (utilizando quicksort)
-- - hacer join por loop anidado
-- - buscar secuencialmente el nombre "Batman"
-- - buscar en acted la fila donde name_id sea names.id (no especifica como lo hace)
