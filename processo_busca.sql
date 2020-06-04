REM Autor            : Heraldo Araujo da Silva
REM Data atualizacao : 04/06/2020
REM Descricao        : Exibe informações de um processo 
REM Nota 1           : Passando como parametro o PID do sistema operacional
REM Exemplo          : SQL>processo_busca.sql 99999

set linesize 300
set pagesize 45
set verify   off;

col sid       format 99999
col SERIAL#   format 99999 
col USERNAME  format a10
col OSUSER    format a10
col STATUS    format a9
col event     format a30
col OS_PID    format 999999
col tracefile format a75
col instancia format a9
col program   format a27
col event     format a40
col terminal  format a20

prompt 
prompt R e l a c a o   p r o c e s s o   S . O   e   p r o c e s s o   n o   b a n c o   d e   d a d o s
prompt  
SELECT (select instance_name from gv$instance i where i.inst_id = s.inst_id) as instancia,
       s.sid sid,
       s.serial#,
       --lpad(p.spid,7)  as os_pid,
       s.USERNAME,
       s.osuser,
       status,
       s.event,
       p.PGA_ALLOC_MEM as pga_alocada,
       p.PGA_USED_MEM  as pga_usada,
       p.LATCHWAIT,
       p.LATCHSPIN,
       p.PROGRAM,
       p.TERMINAL,
       p.PNAME,
	   p.TRACEFILE
FROM gv$process p , gv$session  s
WHERE p.addr = s.paddr
and p.spid = '&1';

set verify   on;
