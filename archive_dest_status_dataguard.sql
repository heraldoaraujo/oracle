REM Autor     : Heraldo Araújo da Silva
REM Data      : 04/06/2020
REM Descricao : Exibe informações sobre a sicronizacao do destino dos arqchive log
REM           : Util para fazer troubleshoot de uma ambiente em dataguard

set line       200
set pagesize   100
set feed       off
col dest_name  format a20
col error      format a20
col inst_id    format 9999999
col dest_id    format 9999999
col gap_status format a15
col instancia  format a10

prompt 
prompt S t a t u s   d o   d e s t i n o   d o s   a r c h i v e   l o g s
prompt 
select (select instance_name from gv$instance i where i.inst_id = a.inst_id) as instancia, 
       dest_id, 
	   dest_name, 
	   DATABASE_MODE, 
	   status, 
	   type, 
	   database_mode,
	   error,
	   gap_status,
	   SYNCHRONIZATION_STATUS,
	   recovery_mode
from gv$archive_dest_status a
where database_mode <> 'UNKNOWN'
order by gap_status,status desc;