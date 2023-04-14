-- Insert or update a hex_user record.
-- If the username is already in use, update the email and hex_url.
insert into hex_user
  (username, email, hex_url)
values
  ($1, $2, $3)
on conflict (username) do update
set
  email = $2
, hex_url = $3
returning
  id
