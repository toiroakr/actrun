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
  let filename = source +
    "-" +
    field +
    "-" +
    (match outcome {
      Some(value) => value.to_string()
      None => "seen"
    })
  let parts : Array[String] = filename
    .iter()
    .map(fn(c) {
      if (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '-' ||
        c == '_' ||
        c == '.' {
        c.to_string()
      } else {
        "_"
      }
    })
    .collect()
  let safe_name = parts.join("")
  @xfs.write_string_to_file(
    directory + "/" + safe_name + ".json",
    record.stringify(),
  ) catch {
    _ => ()
  }
}
