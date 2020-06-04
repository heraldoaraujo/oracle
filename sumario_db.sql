REM Autor            : Heraldo Araujo da Silva
REM Data atualizacao : 04/06/2020
REM Descricao        : Exibe informacoes conveniente para ter um conhecimento geral de uma base de dados.
REM nota 1           : Alterar o caminho do spool na linha 14

set linesize 200
set pagesize 45
column timecol   new_value data ;
column instancia new_value char;
select name||'_' instancia, to_char(sysdate,'yyyymmdd_hh24miss') timecol
from v$database ;

--altear o caminho do spool na linha abaixo
spool C:\diretorio\sumario_&&char&&data ;
set serveroutput on size 1000000;
set timing off;

declare

type umcursor is ref cursor;
abre_cursor   umcursor;
consulta_dinamica varchar2(1000);

p                   number;
--variaveis instancia
id_instancia        varchar2(100);
nome_instancia      varchar2(60);
nome_servidor       varchar2(200);
status_instancia    varchar2(100);
inicio_instancia    varchar2(70);

--variaveis banco de dados
id_do_banco         varchar2(40) default 0;
nome_do_banco       varchar2(50) default 0;
log_arquivado       varchar2(50);
modo_aberto         varchar2(50);
plataforma          varchar2(60);
flashback_modo      varchar2(60);
protecao_modo       varchar2(60);
protecao_level      varchar2(60);
papel_banco         varchar2(60);
data_atual          varchar2(20);

--variaveis tamanho banco de dados
tamanho_controlfile varchar2(25);
tamanho_redolog     varchar2(25);
tamanho_archivelog  varchar2(25);
tamanho_temp        varchar2(25);
tamanho_datafile    varchar2(25);
tamanho_total       varchar2(25);

--variavies versao
versao              varchar2(200);
v_versao            number(10);

v_container         varchar2(3);
container_nome      varchar2(10);
tablespace_name     varchar2(40);
tamanho_atual       varchar2(15);
tamanho_max         varchar2(15);
file_name           varchar2(500);
container_ativo     varchar2(3);
querie_dinamica     varchar2(4000);
contador_controle   number default 1;
largura_relatorio   number default 140;-- pode alterar o parametro dessa variavel para redimensionar a largura do relatorio
largura_formulario  number default 30; -- pode alterar o parametro dessa variavel para redimensionar a distancia do formulario 
largura_container   number default 20;

cursor arquivo_controle is 
       select inst_id, name from gv$controlfile;

cursor arquivo_dados is 
       select tablespace_name,
       file_name,
       case when bytes is null then '               '
       else to_char(bytes,'99g999g999g999') 
       end tamanho_atual ,
       case when maxbytes is null then '               '
       else to_char(maxbytes,'99g999g999g999') end tamanho_max
       from dba_data_files 
       order by tablespace_name,file_name;

cursor registro_refazer is 
       select lf.inst_id, l.group#, bytes, archived, l.status, type, lf.member
       from gv$log l, gv$logfile lf
       where l.group# = lf.group#
       order by lf.inst_id, l.group#, lf.member;

cursor paremetros is 
       select n_instancia, parametro, valor from (
       select to_char(inst_id) n_instancia,name parametro,display_value  valor
       from gv$parameter 
       where name in ('cpu_count','db_block_size','db_domain','db_name','log_buffer','memory_max_target','memory_target',
       'processes','sga_target','sga_max_size','sessions','db_writer_processes','audit_file_dest','db_create_file_dest')
       or (name like '%log_archive_dest%' and name not like '%log_archive_dest_state%' and value is not null)
       union
       select 'parametro banco' n_instancia, parameter parametro,value valor 
       from nls_database_parameters
       where parameter not in ('NLS_TIMESTAMP_FORMAT','NLS_TIMESTAMP_TZ_FORMAT','NLS_TIME_FORMAT','NLS_TIME_TZ_FORMAT','NLS_NCHAR_CONV_EXCP','OPEN_CURSORS'))
       order by 2,1;

cursor remendos is
       select to_char(action_time,'dd/mm/yyyy hh24:mi:ss') dt_aplicado, version, id, comments
       from dba_registry_history
       order by action_time asc;

cursor c_banco is select dbid, name, log_mode, open_mode, platform_name, flashback_on, protection_mode, protection_level, database_role 
       from gv$database;
       
cursor c_instancia is 
       select inst_id, instance_name, host_name, startup_time, status 
       from gv$instance 
       order by inst_id asc;
  
cursor c_versao is 
       select inst_id, banner
       from gv$version 
       where banner like '%Oracle Database%'
       order by inst_id;

procedure trata_titulo (e_titulo in varchar2) is
titulo              varchar2(2000);
begin
  titulo := '+'||(rpad(e_titulo,largura_relatorio,'-'))||'+';
  dbms_output.put_line('|'||(rpad(' ',largura_relatorio,' '))||'|');
  dbms_output.put_line(titulo);
end trata_titulo;

procedure trata_dado (e_dado in varchar2) is
dado                varchar2(2000);
begin
  dado := '|'||(rpad(e_dado,largura_relatorio,' '))||'|';
  dbms_output.put_line(dado);
end trata_dado;

procedure fecha_relatorio is
begin
  dbms_output.put_line('|'||(rpad(' ',largura_relatorio,' '))||'|'); 
  dbms_output.put_line('+'||(rpad('-',largura_relatorio,'-'))||'+'); 
end fecha_relatorio;

begin
  select to_number(substr(version,1,2)) into v_versao from v$instance; 
  data_atual := to_char(sysdate,'dd/mm/yyyy hh24:mi:ss');
  --banco de dados
  
  p := 0; 
  for c in c_banco loop
      if p > 0 then
         id_do_banco    := id_do_banco||', '||c.dbid;
         nome_do_banco  := nome_do_banco||', '||c.name;
         log_arquivado  := log_arquivado||', '||c.log_mode;
         modo_aberto    := modo_aberto||', '||c.open_mode;
         plataforma     := plataforma||', '||c.platform_name;
         flashback_modo := flashback_modo||', '||c.flashback_on;
         protecao_modo  := protecao_modo||', '||c.protection_mode;
         protecao_level := protecao_level||', '||c.protection_level;
         papel_banco    := papel_banco||', '||c.database_role;
      else
         id_do_banco    := c.dbid;
         nome_do_banco  := c.name;
         log_arquivado  := c.log_mode;
         modo_aberto    := c.open_mode;
         plataforma     := c.platform_name;
         flashback_modo := c.flashback_on;
         protecao_modo  := c.protection_mode;
         protecao_level := c.protection_level;
         papel_banco    := c.database_role;
      end if;
      p := p + 1;
  end loop;
  
  --instancia
  p := 0;
  for c in c_instancia loop
      if p > 0 then
         id_instancia     := id_instancia||', '||c.inst_id;
         nome_instancia   := nome_instancia||', '||c.instance_name;
         nome_servidor    := nome_servidor||', '||c.host_name;
         inicio_instancia := inicio_instancia||', '||c.startup_time;
         status_instancia := status_instancia||', '||c.status;
      else
         id_instancia     := c.inst_id;
         nome_instancia   := c.instance_name;
         nome_servidor    := c.host_name;
         inicio_instancia := c.startup_time;
         status_instancia := c.status;
      end if;
      p := p + 1;
  end loop;
  
  --versao
  p := 0;
  for c in c_versao loop
      if p > 0 then
         versao := versao||', '||c.banner;
      else
         versao := c.banner;
      end if;
      p := p + 1;
  end loop;
  
  if v_versao >= 12 then 
       execute immediate 'select cdb  from v$database' into container_ativo; 
       if container_ativo = 'YES' then
          v_container := 'cdb';
       else 
	      v_container := 'dba';
       end if;
  else 
     v_container := 'dba';
  end if;
  
  select to_char(sum(block_size*file_size_blks),'999g999g999g999g999')  
  into tamanho_controlfile 
  from gV$CONTROLFILE;
  
  select to_char(sum(bytes*members),'999g999g999g999g999') 
  into tamanho_redolog 
  from gv$log;
  
  select case when sum(blocks*block_size) is null then to_char(0,'999g999g999g999g999') 
              else to_char(sum(blocks*block_size),'999g999g999g999g999') 
         end into tamanho_archivelog 
  from gv$archived_log 
  where deleted <> 'YES';
         
  querie_dinamica :=       
  'select to_char(sum(bytes),''999g999g999g999g999'')  from '||v_container||'_temp_files';
  execute immediate querie_dinamica into tamanho_temp;
  
  querie_dinamica :=
  'select to_char(sum(bytes),''999g999g999g999g999'') from '||v_container||'_data_files';
  execute immediate querie_dinamica into tamanho_datafile;
  
  querie_dinamica :=
  'select to_char(sum(espaco_utilizado),''999g999g999g999g999'')  from (
  select ''controlfile'' as arquivo,sum(block_size*file_size_blks) as espaco_utilizado from gV$CONTROLFILE
  union
  select ''redolog'' as arquivo,sum(bytes*members) as espaco_utilizado from gv$log
  union
  select ''archive_log'' as arquivo,sum(blocks*block_size) as espaco_utilizado from gv$archived_log where deleted <> ''YES''
  union
  select ''temporary'' as arquivo,sum(bytes) as espaco_utilizado from '||v_container||'_temp_files
  union
  select ''datafile'' as arquivo,sum(bytes) as espaco_utilizado from '||v_container||'_data_files)';
  
  execute immediate querie_dinamica into tamanho_total;
  
  dbms_output.put_line('+'||(rpad('S u m a r i o   d o   b a n c o   d e   d a d o s '||nome_do_banco,largura_relatorio,'-'))||'+');
  --trata_titulo('S u m a r i o   d o   b a n c o   d e   d a d o s '||nome_do_banco);
  
  trata_dado('relatorio gerado em '||data_atual);
  
  trata_titulo('--GERAL');
  trata_dado('Id do banco         :'||id_do_banco);
  trata_dado('Nome do banco       :'||nome_do_banco);
  trata_dado('Papel do banco      :'||papel_banco);
  trata_dado('Modo de protecao    :'||protecao_modo);
  trata_dado('Level de protecao   :'||protecao_level);
  trata_dado('Log archivado       :'||log_arquivado);
  trata_dado('Estado do banco     :'||modo_aberto);
  trata_dado('Nome da instancia   :'||nome_instancia);
  trata_dado('Status da instancia :'||status_instancia);
  trata_dado('Nome do servidor    :'||nome_servidor);
  trata_dado('Plataforma          :'||plataforma);
  trata_dado('Modo flashback      :'||flashback_modo);
  if container_ativo = 'YES' then
     trata_dado('Container           :'||'YES');
  end if;
  
  trata_titulo('--VERSAO');
  trata_dado('Versao :'||versao);
  
  trata_titulo('--TAMANHO DO BANCO DE DADOS');
  trata_dado('controlfile :'||tamanho_controlfile||' bytes');
  trata_dado('redolog     :'||tamanho_redolog||' bytes');
  trata_dado('archivelog  :'||tamanho_archivelog||' bytes');
  trata_dado('temporario  :'||tamanho_temp||' bytes');
  trata_dado('datafile    :'||tamanho_datafile||' bytes');
  trata_dado('TOTAL       :'||tamanho_total||' bytes');
  
  
  trata_titulo('--ARQUIVO DE CONTROLE');
  for ac in arquivo_controle loop
      trata_dado(contador_controle||' :'||ac.name);
      contador_controle := contador_controle + 1;
  end loop;
  
  trata_titulo('--ARQUIVOS DE REDO LOG');
  for arg in registro_refazer loop
    trata_dado(arg.inst_id||' : grupo '||arg.group#||' :'||arg.member);
  end loop;
  
  if v_container = 'cdb' then 
     trata_titulo('--ARQUIVO DE DADOS');
     trata_dado(rpad('Container',largura_formulario-largura_container,' ')||'|'||rpad('Tablespace',largura_formulario,' ')||'|'||'Tamanho        |Tamanho maximo |Nome do arquivo'); 
     
     consulta_dinamica := 'select v.name nome ,
                           tablespace_name,
                           file_name,
                           case when bytes is null then ''               ''
                                else to_char(bytes,''99,999,999,999'') 
                           end tamanho_atual ,
                           case when maxbytes is null then ''               ''
                           else to_char(maxbytes,''99,999,999,999'') 
                           end tamanho_max
                           from cdb_data_files df inner join v$containers v on v.con_id = df.con_id 
                           order by df.con_id,tablespace_name,file_name';
     
     open abre_cursor for consulta_dinamica;
     loop 
     fetch abre_cursor into container_nome,tablespace_name,file_name,tamanho_atual,tamanho_max;
           trata_dado(rpad(container_nome,largura_formulario-largura_container,' ')||':'||rpad(tablespace_name,largura_formulario,' ')||':'||tamanho_atual||':'||tamanho_max||': '||file_name);
           exit when abre_cursor%NOTFOUND;      
     end loop;
     close abre_cursor;
  else 
     trata_titulo('--ARQUIVO DE DADOS');
     trata_dado(rpad('Tablespace',largura_formulario,' ')||'Tamanho Total   |Tamanho Maximo |Nome do Arquivo'); 
     for ad in arquivo_dados loop
         trata_dado(rpad(ad.tablespace_name,largura_formulario,' ')||':'||ad.tamanho_atual||':'||ad.tamanho_max||': '||ad.file_name);
     end loop;
  end if;
  
  trata_titulo('--PRINCIPAIS PARAMETROS');
  trata_dado(rpad('instancia',largura_formulario,' ')||'|'||rpad('Parametro',largura_formulario,' ')||'|'||'Valor');
  for p in paremetros loop
      trata_dado(rpad(p.n_instancia,largura_formulario,' ')||':'||rpad(p.parametro,largura_formulario,' ')||':'||p.valor);
  end loop;
  
  trata_titulo('--PATCHS APLICADOS');
  trata_dado(rpad('Data',largura_formulario-largura_container,' ')||'                    |'||
             rpad('Versao',largura_formulario,' ')||'|'||'Id                            |Comentario'); 
  for p in remendos loop
      trata_dado(rpad(p.dt_aplicado,largura_formulario,' ')||':'||
                 rpad(nvl(p.version,' '),largura_formulario,' ')||':'||
                 rpad(p.id,largura_formulario,' ')||':'||
                 rpad(p.comments,largura_formulario,' '));
  end loop;
       
  fecha_relatorio;

exception when others then
       dbms_output.put_line(sqlerrm);
       --dbms_output.put_line(flashback_modo||' - '||id_instancia||' - '||status_instancia||' - '||nome_instancia||' - '||nome_servidor);
       dbms_output.put_line(container_nome||' - '||tablespace_name||' - '||tamanho_atual||' - '||tamanho_max||' - '||file_name);
end;
/
spool off;
set timing on;