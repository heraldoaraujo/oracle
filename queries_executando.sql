REM Autor            : Heraldo Silva
REM Data atualizacao : 04/06/2020
REM Descricao        : exibe as queries que estao sendo executada 

set linesize 250
set pagesize 45

col username format a11
col sql_text format a72
col event    format a31
col sid      format 9999
col serial   format 99999
col pid_SO   format a7
col username format a17
col osuser   format a10
col sql_text format a80

prompt
prompt Q u e r i e s   e m   e x e c u c a o 
prompt
select (select instance_name from gv$instance i where i.inst_id = s.inst_id) as instancia,
       s.sid, 
       s.serial# serial,
       p.spid pid_SO,
       s.username,
       s.osuser,
       s.event,
       to_char(s.sql_exec_start,'dd/mm/yy hh24:mi:ss') inicio_execucao,
       sql.sql_id,
       sql.sql_text
from gv$session s, gv$process p, gv$sql sql
where p.addr = s.paddr 
and s.sql_id = sql.sql_id
order by username;
