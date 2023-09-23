// TODO: remove and use Wisp
@external(erlang, "packages_ffi", "priv_directory")
pub fn priv_directory(application: String) -> Result(String, Nil)
