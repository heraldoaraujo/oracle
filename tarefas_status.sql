REM Autor     : Heraldo Silva
REM Data      : 04/06/2020
REM Descricao : lista todas as taferas agendadas

set line     250
set pagesize 100
set feed     off

col owner    format a8
col job_name format a30
col duracao  format a30
col enabled  format a7

prompt 
prompt T a r e f a s   a g e n d a d a s
prompt
select owner,
       job_name, 
       job_type,
       replace(substr(job_action,1,50),chr(10),' ') programa, 
       enabled, 
       state, 
       failure_count, 
       to_char(last_start_date,'dd/mm/yyyy hh24:mi:ss') ultima_execucao, 
       to_char(next_run_date,'dd/mm/yyyy hh24:mi:ss') proxima_execucao, 
       last_run_duration duracao
from dba_scheduler_jobs
order by enabled asc, next_run_date desc;
