///|
fn record_yaml_coverage(
  plan_env : Map[String, String],
  field : String,
  outcome? : Bool? = None,
  job? : Bool = false,
) -> Unit {
  guard @env.get_env_var("ACTRUN_COVERAGE_DIR") is Some(directory) else {
    return
  }
  let key = if job { "ACTRUN_COVERAGE_JOB" } else { "ACTRUN_COVERAGE_STEP" }
  guard plan_env.get(key) is Some(source) && source.length() > 0 else { return }
  let record : Json = {
    "source": source,
    "field": field,
    "outcome": match outcome {
      Some(value) => Json::boolean(value)
      None => Json::null()
    },
  }
  let serialized = record.stringify()
  let safe_name = @crypto.bytes_to_hex_string(
    @crypto.sha256(@utf8.encode(serialized)),
  )
  @xfs.write_string_to_file(directory + "/" + safe_name + ".json", serialized) catch {
    _ => ()
  }
}
