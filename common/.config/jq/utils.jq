# Reusable primitives
def schema: path(..) | map(tostring) | join("/");
def in_paths($prefixes):
  map(select(
    .file.path as $p | $prefixes | any(. as $pre | $p | startswith($pre))
  ));

def top(f; n):
  group_by(f)
  | map({key: (.[0]|f), count: length, files: (map(.file.path)|unique|length)})
  | sort_by(-.count) | .[0:n];
