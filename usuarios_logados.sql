REM Autor            : Heraldo Araujo da Silva
REM Data atualizacao : 04/06/2020
REM Descricao        : Exibe os usuários logados e de forma agrupada a quantidade de threads. 

set line 200
col username  format a17
col osuser    format a10
col machine   format a25
col program   format a40
col instancia format a9

prompt
prompt U s u a r i o s   L o g a d o s
prompt
select (select instance_name from gv$instance i where i.inst_id = s.inst_id) as instancia,
       count(*) total_threads ,
       USERNAME,
       osuser,
       machine,
       program,
       to_char(min(logon_time),'dd/mm/yyyy hh24:mi:ss') logado_desde
from gv$session s
where username is not null
group by inst_id,USERNAME,osuser,machine,program
order by username, inst_id, program, count(*), logado_desde;
