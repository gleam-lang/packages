create table packages (
  name varchar(100) primary key,
  updated_at timestamp not null default current_timestamp,
  imported_at timestamp not null default current_timestamp,
  links jsonb not null default '{}'::jsonb,
  licenses varchar(255)[] not null default '[]',
  description not null text default 'My Description' 
);

create table previous_hex_api_scan (
  id boolean primary key default true,
  scanned_at timestamp not null,

  -- We use a constraint to enforce that the id is always the value `true` so
  -- now this table can only hold one row.
  constraint previous_hex_api_scan_singleton check (id)
)
