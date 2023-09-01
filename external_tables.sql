select t.name as local_name, t.remote_object_name, t.type_desc, s.database_name as external_db, s.pushdown
from sys.external_tables t
join sys.external_data_sources s on s.data_source_id = t.data_source_id


