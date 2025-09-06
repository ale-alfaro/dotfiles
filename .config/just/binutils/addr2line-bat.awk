{
    file_line = $NF
    if (match(file_line, /:[0-9]+$/)) {
        line = substr(file_line, RSTART + 1)
        file = substr(file_line, 1, RSTART - 1)
        start = line - 10
        if (start < 1)
            start = 1
        end = line + 10
        system("bat --line-range " start ":" end " --highlight-line " line " " file)
    }
}
