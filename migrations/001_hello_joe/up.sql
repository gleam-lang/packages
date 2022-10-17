CREATE TABLE packages (
    name varchar(100) PRIMARY KEY,
    updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    imported_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    links jsonb NOT NULL DEFAULT '{}' ::jsonb,
    licenses varchar(255)[] NOT NULL DEFAULT ARRAY[] ::varchar(255)[],
    description text NOT NULL DEFAULT 'My Description'
);

CREATE TABLE previous_hex_api_scan (
    id boolean PRIMARY KEY DEFAULT TRUE,
    scanned_at timestamp NOT NULL,
    -- We use a constraint to enforce that the id is always the value `true` so
    -- now this table can only hold one row.
    CONSTRAINT previous_hex_api_scan_singleton CHECK (id)
);
