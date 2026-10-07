-- 02_dim_local_votacao.sql
-- dimensao geografica: union das stagings 2018 e 2022 para deduplicar locais de votacao
-- nk composta: concat_ws('_', cd_municipio, nr_zona, nr_local_votacao)
-- flags: fl_grande_abc (7 municipios) e fl_rmsp (39 municipios da rmsp, incluindo o abc)

use innovationlab_appliedbi;
go

if object_id('dbo.fato_votacao', 'u') is not null
    drop table dbo.fato_votacao;

if object_id('dbo.dim_local_votacao', 'u') is not null
    drop table dbo.dim_local_votacao;
go

create table dbo.dim_local_votacao (
    sk_local_votacao int identity(1,1) not null,
    nk_local_votacao varchar(50) not null,
    cd_municipio int not null,
    nm_municipio varchar(100) not null,
    nr_zona varchar(10) not null,
    nr_local_votacao varchar(10) not null,
    nm_local_votacao varchar(200) not null,
    sg_uf varchar(2) not null constraint df_dim_local_votacao_sg_uf default 'SP',
    fl_grande_abc bit not null constraint df_dim_local_votacao_abc default 0,
    fl_rmsp bit not null constraint df_dim_local_votacao_rmsp default 0,
    constraint pk_dim_local_votacao primary key (sk_local_votacao),
    constraint uq_dim_local_votacao_nk unique (nk_local_votacao)
);
go

with locais_unificados as (
    select
        2022 as nr_ano,
        cd_municipio,
        upper(nm_municipio) as nm_municipio,
        nr_zona,
        nr_local_votacao,
        upper(nm_local_votacao) as nm_local_votacao,
        coalesce(sg_uf, 'SP') as sg_uf
    from dbo.staging_votacaosecao_2022_sp
    group by cd_municipio, nm_municipio, nr_zona, nr_local_votacao, nm_local_votacao, sg_uf
    union
    select
        2018 as nr_ano,
        cd_municipio,
        upper(nm_municipio) as nm_municipio,
        nr_zona,
        nr_local_votacao,
        upper(nm_local_votacao) as nm_local_votacao,
        coalesce(sg_uf, 'SP') as sg_uf
    from dbo.staging_votacaosecao_2018_sp
    group by cd_municipio, nm_municipio, nr_zona, nr_local_votacao, nm_local_votacao, sg_uf
),
locais_ranqueados as (
    -- se o nome do local mudou entre 2018 e 2022, prevalece o nome mais recente
    select
        concat_ws('_', cd_municipio, nr_zona, nr_local_votacao) as nk_local_votacao,
        cd_municipio,
        nm_municipio,
        nr_zona,
        nr_local_votacao,
        nm_local_votacao,
        sg_uf,
        row_number() over (
            partition by cd_municipio, nr_zona, nr_local_votacao
            order by nr_ano desc, nm_local_votacao
        ) as rn
    from locais_unificados
)
insert into dbo.dim_local_votacao (
    nk_local_votacao,
    cd_municipio,
    nm_municipio,
    nr_zona,
    nr_local_votacao,
    nm_local_votacao,
    sg_uf,
    fl_grande_abc,
    fl_rmsp
)
select
    nk_local_votacao,
    cast(cd_municipio as int),
    left(nm_municipio, 100),
    left(nr_zona, 10),
    left(nr_local_votacao, 10),
    left(coalesce(nm_local_votacao, 'LOCAL NÃO INFORMADO'), 200),
    left(sg_uf, 2),
    case
        when nm_municipio in (
            'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL',
            'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA'
        ) then 1 else 0
    end as fl_grande_abc,
    case
        when nm_municipio in (
            'SÃO PAULO', 'SANTO ANDRÉ', 'SÃO BERNARDO DO CAMPO', 'SÃO CAETANO DO SUL',
            'DIADEMA', 'MAUÁ', 'RIBEIRÃO PIRES', 'RIO GRANDE DA SERRA', 'GUARULHOS',
            'OSASCO', 'BARUERI', 'CARAPICUÍBA', 'COTIA', 'EMBU DAS ARTES', 'EMBU-GUAÇU',
            'FERRAZ DE VASCONCELOS', 'FRANCISCO MORATO', 'FRANCO DA ROCHA',
            'ITAPECERICA DA SERRA', 'ITAPEVI', 'ITAQUAQUECETUBA', 'JANDIRA', 'JUQUITIBA',
            'MOGI DAS CRUZES', 'POÁ', 'SALESÓPOLIS', 'SANTA ISABEL', 'SANTANA DE PARNAÍBA',
            'SUZANO', 'TABOÃO DA SERRA', 'VARGEM GRANDE PAULISTA', 'ARUJÁ', 'BIRITIBA MIRIM',
            'CAIEIRAS', 'CAJAMAR', 'GUARAREMA', 'PIRAPORA DO BOM JESUS', 'SÃO LOURENÇO DA SERRA'
        ) then 1 else 0
    end as fl_rmsp
from locais_ranqueados
where rn = 1;
go
