
set -euo pipefail


pluginRepos=("hiasr/vim-zellij-navigator" "laperlej/zellij-sessionizer" "karimould/zellij-forgot" "fresh2dev/zellij-autolock" )

for i in ${!pluginRepos[@]};
do
  repo=${pluginRepos[$i]}
  echo "Updating $repo"
  release_name=$(gh release view -R "$repo" --json name --jq '.name')
  wasm_file=$(gh release view -R "$repo" --json assets --jq '.assets[] | select(.name | contains("wasm")).name')

  if [ -z "$wasm_file" ]; then
    echo "No wasm file found for $repo"
    exit 1
  fi
  echo "Downloading $wasm_file"
  gh release download  -R "$repo" --pattern *.wasm
done

