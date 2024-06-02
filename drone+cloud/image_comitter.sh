# Commit files in the directory passed as argument, probably with work-tree and git-dir
git_commit() {
    local repo_dir="$1"
    local commit_dir="$2"
    echo "Committing files in $commit_dir"
    git --git-dir="$repo_dir.git" --work-tree="$commit_dir" add .
    git --git-dir="$repo_dir.git" --work-tree="$commit_dir" commit --author="'drone <drone@wildlife.emli>'" -m "auto: Commit annotated metadata"
    git --git-dir="$repo_dir.git" --work-tree="$commit_dir" push
}

usage() {
    echo "Usage: $0 <waiting_dir> <output_dir> <classify_script> <repo_dir> [iterations_before_commit]"
}

validate_input(){
    if [ $# -lt 4 ] || [ $# -gt 5 ]; then
        echo "Error: Invalid number of arguments"
        usage
        exit 1
    fi
}

main() {
    validate_input "$@"
    local waiting_dir="$1"
    local output_dir="$2"
    local classify_script="$3"
    local repo_dir="$4"
    local iterations_before_commit="${5:-1}"

    mkdir -p "$output_dir"
    mkdir -p "$waiting_dir"


    local counter=0
    while true; do
        sleep 5
        waiting_files=$(find "$waiting_dir" -mindepth 2 -maxdepth 2 -name '*.json')
        echo "Found $(echo "$waiting_files" | wc -l) files in $waiting_dir"

        # For each file in waiting_dir
        for file in $waiting_files; do
            local target_dir=$(dirname "$file")
            target_dir=$(basename "$target_dir")
            target_dir="$output_dir/$target_dir"
            echo "Processing $file"
            echo "Target dir: $target_dir"

            image_file="${file%.*}.jpg"
            classify_script "$image_file"
            mkdir -p "$target_dir"
            cp "$file" "$target_dir"
            rm "$image_file"
            rm "$file"
            git_commit "$repo_dir" "$output_dir"
        done

        ((counter++))
        #if [ $((counter % iterations_before_commit)) -eq 0 ]; then
        #    git_commit "$repo_dir" "$output_dir"
        #    counter=0
        #fi


    done
}


main "$@"