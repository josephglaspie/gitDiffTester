#!/usr/bin/env bash
branch=""

function diff() {
    git_status
    difflists
    set_buildkite
}

function git_status() {

    if [[ "${BUILDKITE_BRANCH}" == "main" ]]; then 
        branch=HEAD~1
        git_output=$(git --no-pager diff --name-status $branch)
    else
        branch=main
        git_output=$(git --no-pager diff --name-status $branch)
    fi

    echo "${git_output}"
}

function difflists() {

    # lists to store diffs
    declare -g ADDED_FILES
    declare -g DELETED_FILES
    declare -g MODIFIED_FILES


    git_output=$(git_status)
    OLDIFS=$IFS; IFS=$'\n'; for line in $git_output;
    do
        #chop status
        file=$(echo "${line}" | awk '{ print $2 }')
        # only process yaml or yml files in workspaces/
        if [[ ("${file}" != *.yaml* && "${file}" != *.yml*) || ("${file}" != workspaces/** )]]
        then
            continue
        fi

        case "${line::1}" in
            # added
            A)
                echo "added new file: ${file}"
                ADDED_FILES+="${file},"
                ;;
            # deleted
            D)
                echo "deleted old file: ${file}"
                DELETED_FILES+="${file},";;
            # modified
            M)
                echo "modified existing file ${file}"
                MODIFIED_FILES+="${file},"
                ;;
            # renamed
            R)
                # get renamed files
                all_renamed_files=$(git --no-pager diff --name-status $branch | grep '^R')
                # Create a variable to hold each line
                while IFS= read -r line; do
                    old_filename=$(echo "$line" | awk '{print $2}')
                    new_filename=$(echo "$line" | awk '{print $3}')
                
                    diffs=$(git diff $branch -- $old_filename $new_filename)
                
                if [[ ! $diffs ]]; then
                    echo "No updates to $new_filename"
                else
                    MODIFIED_FILES+="${new_filename},"
                fi
                
                done <<< "$all_renamed_files"
                # TODO: check tfc-managment to see what happens to "disreguarded file names". Also if [[ "${BUILDKITE_BRANCH}" == "main"
                # check if renamed files had any updates to them, if yes add to MODIFIED_FILES else disreguard them
            # default
            *)
                echo "not recognized...skipping"
                ;;
        esac
    done





    IFS=$OLDIFS

    export ADDED_FILES=$(echo ${ADDED_FILES} | sed 's/,*$//g')
    export DELETED_FILES=$(echo ${DELETED_FILES} | sed 's/,*$//g')
    export MODIFIED_FILES=$(echo ${MODIFIED_FILES} | sed 's/,*$//g')

    echo "ADDED_FILES: ${ADDED_FILES}"
    echo "DELETED_FILES: ${DELETED_FILES}"
    echo "MODIFIED_FILES: ${MODIFIED_FILES}"

}

function buildkite_cmd() {
    declare buildkite_cmd

    if ! buildkite_cmd="$(which buildkite-agent)"; then
        return 1
    fi

    echo "${buildkite_cmd}"
    return 0
}


function set_buildkite() {
    declare buildkite


    if ! buildkite="$(buildkite_cmd)"; then
        return 1
    fi

    if [ "$BUILDKITE" = true ] ; then
        echo "setting buildkite vars"
        if [ -n "${ADDED_FILES}" ] ; then
            "${buildkite}" meta-data set "tfc_added_files" "$ADDED_FILES"
            "${buildkite}" meta-data get "tfc_added_files"
        fi

        if [ -n "${DELETED_FILES}" ] ; then
            "${buildkite}" meta-data set "tfc_deleted_files" "$DELETED_FILES"
            echo "tfc_deleted_files set to: $DELETED_FILES"
            "${buildkite}" meta-data get "tfc_deleted_files"
        fi

        if [ -n "${MODIFIED_FILES}" ] ; then
            "${buildkite}" meta-data set "tfc_modified_files" "$MODIFIED_FILES"
            "${buildkite}" meta-data get "tfc_modified_files"
        fi
    fi
}