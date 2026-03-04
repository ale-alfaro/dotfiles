acli_query_tickets() {
    query=$(
        cat <<-EOF
    project = "BEDR"
    AND assignee = 5efe36132a72950bbfb58925
    AND status NOT IN (Done, Closed, Deprecated, Canceled)
    ORDER BY created DESC
EOF
    )
    acli jira workitem search --jql "$query" --fields "key,summary" --csv | column --table --separator=,
}
