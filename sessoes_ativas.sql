REM Autor            : Heraldo Araujo da Silva
REM Data atualizacao : 28/01/2019
REM Descricao        : Exibe apenas as sessoes que estao com status ativo

set linesize 200
set pagesize 45
col sid        format 99999
col serial     format 999999 
col USERNAME   format a11
col OSUSER     format a8
col STATUS     format a7
col MACHINE    format a19
col PROGRAM    format a21
col event      format a44
col comando    format a15
col wait_class format a15
select inst_id,
       sid,
       serial# as serial,
       username,
       (SELECT command_name  
        FROM gv$sqlcommand  
        WHERE command_type = command) comando,
       osuser,
       machine,
       program,
       event,
       wait_class,
       state
from gv$session
where username is not null
and status != 'INACTIVE'
order by comando;