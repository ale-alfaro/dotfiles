submodule-sync:
    @git submodule update --init --recursive

sparse-checkout user repo subdir branch="main":
    @git clone --no-checkout https://github.com/{{ user }}/{{ repo }}.git && cd {{ repo }} 
    @git sparse-checkout init --cone
    @git sparse-checkout set {{ subdir }}
    @git checkout {{ branch }}
