import gleam/pgo
import packages/generated/sql
import packages/store

pub fn with_database(f: fn(pgo.Connection) -> t) -> t {
  let config =
    pgo.Config(
      ..store.database_config_from_env(),
      database: "gleam_packages_test",
      pool_size: 1,
    )
  let db = pgo.connect(config)
  let assert Ok(_) = sql.migrate_schema(db, [], Ok)
  let t = f(db)
  let Nil = pgo.disconnect(db)
  t
}

pub fn truncate_tables(db: pgo.Connection) -> Nil {
  let sql =
    "
do $$
declare
  command varchar;
begin
  select 'truncate table ' || string_agg(oid::regclass::text, ', ') || ' cascade'
  into command
  from pg_class
  where relkind = 'r'  -- only tables
  and relnamespace = 'public'::regnamespace;

  execute command;
end
$$;
  "
  let assert Ok(_) = pgo.execute(sql, db, [], Ok)
  Nil
}
