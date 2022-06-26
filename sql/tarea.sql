-- PARTE 2:
------------------------------------------------------------------------------------------------------------------------
-- Pregunta 1:
------------------------------------------------------------------------------------------------------------------------
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
-- es posible que mi motor este cambiando algo (lo corri en mi pc a traves de postgresql de docker)

------------------------------------------------------------------------------------------------------------------------
-- Pregunta 2: Analizar Execution Time
------------------------------------------------------------------------------------------------------------------------
-- Execution Time por defecto
EXPLAIN ANALYZE
SELECT DISTINCT names.name
FROM names
JOIN acted on names.id = acted.name_id
WHERE acted.role = 'Batman';
-- Execution Time varia entre 3 a 6ms

-- agregar btree acted.role
CREATE INDEX indice_btree ON acted (role);

-- correr nuevamente
EXPLAIN ANALYZE
SELECT DISTINCT names.name
FROM names
JOIN acted on names.id = acted.name_id
WHERE acted.role = 'Batman';
-- Execution Time varia entre 0.1 y 0.2ms
-- el btree mejora significativamente el rendimiento

-- el btree nos ayuda aca ya que en vez de una busqueda secuencial se utiliza un "Bitmap Heap Scan"
-- es interesante tener en cuenta que el sorteo ocurre igualmente, probablemente la tabla ya estaba sorteada
-- esto significa que el lugar donde mejora el rendimiento es en la busqueda de la palabra "Batman" y no en el JOIN
-- o su ausencia

-- eliminar btree
DROP INDEX indice_btree;

------------------------------------------------------------------------------------------------------------------------
-- Pregunta 3:
------------------------------------------------------------------------------------------------------------------------
-- sin indice
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year = 2022;
-- Execution Time entre 0.7 y 1.1ms

-- btree en release_year
CREATE INDEX indice_btree ON titles (release_year);
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year = 2022;
DROP INDEX indice_btree;
-- Execution Time entre 0.04 y 0.05ms

-- indice hash
CREATE INDEX indice_hash ON titles USING HASH (release_year);
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year = 2022;
DROP INDEX indice_hash;
-- Execution Time entre 0.05 y 0.06ms

-- ambos tipos de indice ayudan
-- btree es ligeramente mas rapido
-- el plan de hash es mas complicado que el de btree

------------------------------------------------------------------------------------------------------------------------
-- Pregunta 4:
------------------------------------------------------------------------------------------------------------------------
-- sin indice
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year >= 2018
AND release_year <= 2020;
-- ET entre 0.8 y 1.3ms

-- btree
CREATE INDEX indice_btree ON titles (release_year);
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year >= 2018
AND release_year <= 2020;
DROP INDEX indice_btree;
-- 0.2 - 0.3ms

-- hash
CREATE INDEX indice_hash ON titles USING HASH (release_year);
EXPLAIN ANALYZE
SELECT *
FROM titles
WHERE release_year >= 2018
AND release_year <= 2020;
DROP INDEX indice_hash;
-- 0.8 - 1.1ms

-- aca solo nos ayuda el btree
-- esto se debe a que estamos buscando por mayor o igual, y el motor no sabe de antemano los maximos y minimos desde
-- donde hacer el hash, asi que tiene que hacer una busqueda secuencial.