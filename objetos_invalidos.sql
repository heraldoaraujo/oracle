REM Autor     : Heraldo Silva
REM Data      : 04/06/2020
REM Descricao : Exibe o total de objetos invalidos de cada esquema

set line       200
set pagesize   100
set feed       off

prompt 
prompt U s u a r i o s   c o m   o b j e t o s   i n v a l i d o s
prompt 
select owner, object_type, count(*) as total
from dba_objects
where status = 'INVALID'
group by owner, object_type
order by 3;
