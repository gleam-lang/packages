create table packages (
  name varchar(100) primary key,
  imported_at timestamp not null default current_timestamp
);

create table previous_hex_api_scan (
  id boolean primary key default true,
  scanned_at timestamp not null,

  -- We use a constraint to enforce that the id is always the value `true` so
  -- now this table can only hold one row.
  constraint previous_hex_api_scan_singleton check (id)
)
