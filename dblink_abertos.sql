REM Autor     : Heraldo Silva
REM Data      : 04/06/2020
REM Descricao : Exibe os db_links que estão abertos ou em execucao 

set line       200
set pagesize   100
set feed       off

col DB_LINK      format a30
col logged_on    format a20
col open_cursors format 999999999999

prompt 
prompt D B   L i n k s   e m   e x e c u c a o
prompt 
select db_link,
       logged_on,
	   open_cursors,
	   case when in_transaction = 'YES' THEN 'Transacao no momento. E necessario confirmar ou reverter a transacao'
	        else in_transaction end em_transacao,
	   update_sent
from v$dblink
order by db_link;