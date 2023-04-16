insert into most_recent_hex_timestamp
  (id, timestamp)
values
  (true, to_timestamp($1))
on conflict (id) do update
set
  timestamp = to_timestamp($1);
