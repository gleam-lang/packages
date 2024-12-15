pub type BagTable(k, v)

@external(erlang, "ethos_ffi", "bag_new")
pub fn new() -> BagTable(k, v)

@external(erlang, "ethos_ffi", "bag_get")
pub fn get(table: BagTable(k, v), key: k) -> Result(List(v), Nil)

@external(erlang, "ethos_ffi", "bag_insert")
pub fn insert(table: BagTable(k, v), key: k, value: v) -> Result(Nil, Nil)

@external(erlang, "ethos_ffi", "bag_delete")
pub fn delete(table: BagTable(k, v), key: k, value: v) -> Result(Nil, Nil)

@external(erlang, "ethos_ffi", "bag_delete_key")
pub fn delete_key(table: BagTable(k, v), key: k) -> Result(Nil, Nil)

@external(erlang, "ethos_ffi", "bag_delete_value")
pub fn delete_value(table: BagTable(k, v), value: v) -> Result(Nil, Nil)

@external(erlang, "ethos_ffi", "drop")
pub fn drop(table: BagTable(k, v)) -> Nil
