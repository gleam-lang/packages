insert into most_recent_hex_timestamp
  (id, unix_timestamp)
values
  (true, $1)
on conflict (id) do update
set
  unix_timestamp = $1;
