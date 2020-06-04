REM Autor            : Heraldo Silva
REM Data atualizacao : 04/06/2020
REM Descricao        : Exibe as sessoes do banco e os eventos de espera
REM Nota 1           : Funciona em instanca stand-alone e RAC.
REM Nota 2           : Não exibe sessoes internas do oracle.

set line 300
set pagesize 45
col username     format a22
col osuser       format a10
col machine      format a20
col inst_id      format 999999
col sid          format 9999
col serial       format 9999999
col program      format a46
col logado_desde format a19
col schemaname   format a21
col service_name format a12
col event        format a40

SELECT inst_id,
       SID, 
       SERIAL# SERIAL, 
       nvl(USERNAME,'oracle') username, 
       OSUSER,
       STATUS, 
       to_char(LOGON_TIME,'dd/mm/yyyy hh24:mi:ss') logado_desde,
       MACHINE, 
       PROGRAM, 
       STATE  ,
       event
FROM GV$SESSION 
where username is not null
order by status desc, state, event, username, osuser, machine;