git-submodule-sync:
    @git submodule update --init --recursive

git-sparse-checkout user repo subdir branch="main":
    @git clone --no-checkout https://github.com/{{ user }}/{{ repo }}.git && cd {{ repo }} 
    @git sparse-checkout init --cone
    @git sparse-checkout set {{ subdir }}
    @git checkout {{ branch }}

gh-folder-fetch repo path branch='main':
    uvx gh-folder-download --url {{ f'https://github.com/{{repo}}/tree/{{branch}}/{{path}}' }} --output tmp
    mv tmp/{{ path }} {{ file_stem(path) }}
    rm -r tmp
