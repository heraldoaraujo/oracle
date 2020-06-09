REM Autor            : Heraldo Silva
REM Data atualizacao : 09/06/2020
REM Descricao        : Gera o DDL de um programa PLSQL e joga a saida em um spool.
REM Nota 1           : Deve passar como parametro o <dono>.<objeto>
REM Exemplo          : SQL> @gera_program.sql "dono.objeto";

prompt G e r a   P r o g r a m a   P L / S Q L 

set timing   off;
set head     off;
set feedback off;
set verify   off;

spool        ddl_programa.sql;

select nvl(text,'PROGRAMA NAO ENCONTRADO')
from dba_source 
where owner||'.'||name = upper('&1')
ORDER BY type asc, line ASC;

spool        off;

set verify   on;
set timing   on;
set head     on;
set feedback on;
