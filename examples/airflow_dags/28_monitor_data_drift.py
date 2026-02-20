"""
DAG 28: Monitor Data Drift
Detecta mudanças nas distribuições de dados (drift)

Funcionalidades:
- Captura estatísticas de colunas numéricas críticas
- Compara com baseline (7 dias atrás)
- Calcula drift percentage
- Alerta se drift > 20% (WARNING) ou > 50% (CRITICAL)

Métricas monitoradas:
- orders: price, freight_value
- reviews: review_score (distribuição)
- order_items: item_total_value

Schedule: @daily (7h AM)
Autor: Hyego
"""

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.hooks.postgres import PostgresHook
from datetime import datetime, timedelta
import logging
import pandas as pd

default_args = {
    'owner': 'hyego',
    'depends_on_past': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Colunas a monitorar (tabela.coluna)
COLUMNS_TO_MONITOR = {
    'olist_silver.orders': ['price', 'freight_value'],
    'olist_silver.order_reviews': ['review_score'],
    'olist_silver.order_items': ['item_total_value', 'freight_value'],
}

def capture_statistics():
    """Captura estatísticas atuais de todas as colunas monitoradas"""
    logger = logging.getLogger(__name__)
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    all_stats = []
    
    for table_full, columns in COLUMNS_TO_MONITOR.items():
        schema, table = table_full.split('.')
        
        for column in columns:
            logger.info(f"📊 Capturando estatísticas: {table}.{column}")
            
            query = f"""
            SELECT 
                '{table}' as table_name,
                '{column}' as column_name,
                COUNT(*) as row_count,
                MIN({column}) as min_value,
                MAX({column}) as max_value,
                AVG({column}) as mean_value,
                PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY {column}) as p25,
                PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY {column}) as p50,
                PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY {column}) as p75,
                PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY {column}) as p95,
                STDDEV({column}) as stddev_value
            FROM {schema}.{table}
            WHERE {column} IS NOT NULL;
            """
            
            try:
                df = pg_hook.get_pandas_df(query)
                if not df.empty:
                    row = df.iloc[0]
                    
                    # Adicionar métricas individuais
                    metrics = [
                        {'metric_name': 'min', 'metric_value': row['min_value']},
                        {'metric_name': 'max', 'metric_value': row['max_value']},
                        {'metric_name': 'mean', 'metric_value': row['mean_value']},
                        {'metric_name': 'p25', 'metric_value': row['p25']},
                        {'metric_name': 'p50', 'metric_value': row['p50']},
                        {'metric_name': 'p75', 'metric_value': row['p75']},
                        {'metric_name': 'p95', 'metric_value': row['p95']},
                        {'metric_name': 'stddev', 'metric_value': row['stddev_value']},
                    ]
                    
                    for metric in metrics:
                        all_stats.append({
                            'table_name': table,
                            'column_name': column,
                            'metric_name': metric['metric_name'],
                            'metric_value': float(metric['metric_value']) if pd.notna(metric['metric_value']) else None,
                            'row_count': int(row['row_count'])
                        })
                
            except Exception as e:
                logger.error(f"❌ Erro ao capturar {table}.{column}: {e}")
    
    logger.info(f"✅ Capturadas {len(all_stats)} estatísticas")
    return pd.DataFrame(all_stats)

def get_baseline_statistics():
    """Busca estatísticas do baseline (7 dias atrás)"""
    logger = logging.getLogger(__name__)
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    query = """
    SELECT 
        table_name,
        column_name,
        metric_name,
        metric_value,
        row_count,
        captured_at
    FROM olist_monitoring.data_statistics
    WHERE captured_at >= CURRENT_DATE - INTERVAL '8 days'
    AND captured_at <= CURRENT_DATE - INTERVAL '6 days'
    ORDER BY captured_at DESC
    LIMIT 1000;
    """
    
    try:
        df = pg_hook.get_pandas_df(query)
        if df.empty:
            logger.info("ℹ️ Nenhum baseline encontrado (primeira execução)")
            return None
        
        # Pegar apenas o mais recente de cada métrica
        df = df.sort_values('captured_at', ascending=False).drop_duplicates(
            subset=['table_name', 'column_name', 'metric_name'],
            keep='first'
        )
        
        logger.info(f"✅ Recuperadas {len(df)} estatísticas do baseline")
        return df
        
    except Exception as e:
        logger.error(f"❌ Erro ao buscar baseline: {e}")
        return None

def detect_drift(current_df, baseline_df):
    """Compara estatísticas atuais vs baseline e detecta drift"""
    logger = logging.getLogger(__name__)
    
    if baseline_df is None or baseline_df.empty:
        logger.info("ℹ️ Primeira execução - criando baseline")
        return [], {'warning': 0, 'critical': 0, 'ok': len(current_df)}
    
    # Merge current com baseline
    merged = current_df.merge(
        baseline_df[['table_name', 'column_name', 'metric_name', 'metric_value']],
        on=['table_name', 'column_name', 'metric_name'],
        how='left',
        suffixes=('_current', '_baseline')
    )
    
    drifts = []
    stats = {'warning': 0, 'critical': 0, 'ok': 0}
    
    for _, row in merged.iterrows():
        if pd.isna(row['metric_value_baseline']) or row['metric_value_baseline'] == 0:
            continue
        
        current_val = row['metric_value_current']
        baseline_val = row['metric_value_baseline']
        
        # Calcular drift %
        drift_pct = ((current_val - baseline_val) / baseline_val) * 100
        drift_abs = abs(drift_pct)
        
        # Classificar severidade
        if drift_abs > 50:
            severity = 'CRITICAL'
            stats['critical'] += 1
        elif drift_abs > 20:
            severity = 'WARNING'
            stats['warning'] += 1
        else:
            severity = 'OK'
            stats['ok'] += 1
        
        drifts.append({
            'table_name': row['table_name'],
            'column_name': row['column_name'],
            'metric_name': row['metric_name'],
            'current_value': current_val,
            'baseline_value': baseline_val,
            'drift_pct': drift_pct,
            'severity': severity
        })
    
    logger.info(f"📊 Drift Detection: OK={stats['ok']}, WARNING={stats['warning']}, CRITICAL={stats['critical']}")
    
    return drifts, stats

def save_statistics(stats_df):
    """Salva estatísticas na tabela data_statistics"""
    logger = logging.getLogger(__name__)
    pg_hook = PostgresHook(postgres_conn_id='postgres_default')
    
    if stats_df.empty:
        logger.info("ℹ️ Nenhuma estatística para salvar")
        return
    
    engine = pg_hook.get_sqlalchemy_engine()
    stats_df.to_sql(
        'data_statistics',
        engine,
        schema='olist_monitoring',
        if_exists='append',
        index=False
    )
    
    logger.info(f"✅ {len(stats_df)} estatísticas inseridas")

def generate_alerts(drifts, stats):
    """Gera alertas para drifts detectados"""
    logger = logging.getLogger(__name__)
    
    if stats['warning'] > 0 or stats['critical'] > 0:
        logger.warning("=" * 60)
        logger.warning("⚠️ DATA DRIFT DETECTED!")
        logger.warning(f"   WARNING: {stats['warning']} métricas com drift > 20%")
        logger.warning(f"   CRITICAL: {stats['critical']} métricas com drift > 50%")
        logger.warning("=" * 60)
        
        # Listar top drifts críticos
        critical_drifts = [d for d in drifts if d['severity'] == 'CRITICAL']
        if critical_drifts:
            logger.warning("🚨 Top CRITICAL drifts:")
            for drift in critical_drifts[:5]:  # Top 5
                logger.warning(
                    f"   - {drift['table_name']}.{drift['column_name']}.{drift['metric_name']}: "
                    f"{drift['baseline_value']:.2f} → {drift['current_value']:.2f} "
                    f"({drift['drift_pct']:+.1f}%)"
                )
    else:
        logger.info("✅ Nenhum drift significativo detectado (sistema estável)")

def run_data_drift_monitoring(**context):
    """Task principal: monitora drift de dados"""
    logger = logging.getLogger(__name__)
    logger.info("🔍 Iniciando Data Drift Monitoring...")
    
    # 1. Capturar estatísticas atuais
    current_stats = capture_statistics()
    
    # 2. Buscar baseline (7d atrás)
    baseline_stats = get_baseline_statistics()
    
    # 3. Detectar drift
    drifts, stats = detect_drift(current_stats, baseline_stats)
    
    # 4. Salvar estatísticas atuais
    save_statistics(current_stats)
    
    # 5. Gerar alertas
    generate_alerts(drifts, stats)
    
    logger.info("✅ Data Drift Monitoring concluído!")
    return {'drifts': len(drifts), **stats}

with DAG(
    'monitor_data_drift',
    default_args=default_args,
    description='[MONITORING] Data Drift Detection',
    schedule_interval='0 7 * * *',  # 7h AM diário
    start_date=datetime(2025, 2, 4),
    catchup=False,
    tags=['fase-2', 'monitoring', 'drift'],
) as dag:
    
    task_monitor = PythonOperator(
        task_id='run_data_drift_monitoring',
        python_callable=run_data_drift_monitoring,
    )
