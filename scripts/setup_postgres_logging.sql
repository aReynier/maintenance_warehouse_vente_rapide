-- Configuration de la journalisation via ALTER SYSTEM
-- Collecteur
ALTER SYSTEM SET logging_collector = 'on';
ALTER SYSTEM SET log_directory = 'log';
ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';

-- Contenu des logs
ALTER SYSTEM SET log_line_prefix = '%m [%p] %q%u@%d/%a (tx:%x)';
ALTER SYSTEM SET log_statement = 'ddl';
ALTER SYSTEM SET log_min_duration_statement = '250';
ALTER SYSTEM SET log_min_messages = 'warning';
ALTER SYSTEM SET log_min_error_statement = 'error';
ALTER SYSTEM SET log_lock_waits = 'on';
ALTER SYSTEM SET log_temp_files = 0;
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_rotation_age = '1d';
ALTER SYSTEM SET log_rotation_size = '10MB';

SELECT pg_reload_conf();