#!/bin/bash

# Configuration
declare -r AUTHORIZATION_TOKEN="" # Github authorization access token
declare -r USER="" # Username
declare -r WORK_FOLDER="./tmp" # Backup target folder

# Constants
declare -r BACKUP_FOLDER="$WORK_FOLDER/current"
declare -r ARCHIVED_FOLDER="$WORK_FOLDER/archived"
declare -r END_RESPONSE="{\"error\":\"page is invalid\"}"

page=1
projects="[]"

echo "[Backup started]"

mkdir -p $WORK_FOLDER
mkdir -p $ARCHIVED_FOLDER
mkdir -p $BACKUP_FOLDER

while true; do
    repositories=$(curl --silent --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $AUTHORIZATION_TOKEN" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/user/repos?visibility=all&affiliation=owner&&per_page=100&page=$page")

    repository_count=$(echo "$repositories" | jq 'length')
    echo "Processing page $page ; repositories found: $repository_count"
    if [ "$repository_count" -eq 0 ]; then
        break
    fi

    for row in $(echo "$repositories" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${row}" | base64 -di | jq -r "${1}"
        }

        name=$(_jq '.name')
        updated_at=$(_jq '.updated_at')
        default_branch=$(_jq '.default_branch')
        full_name=$(_jq '.full_name')
        archived=$(_jq '.archived')
        git_url=$(_jq '.ssh_url')

        # Replace slashes and spaces in folder name
        folder_name=$(echo "$full_name" | sed 's|/|--|g; s| |-|g')
        echo "folder_name=$folder_name ; git_url=$git_url ; archived=$archived"

        if [ -f "$BACKUP_FOLDER/$folder_name.last-updated" ]; then
            last_updated=$(cat "$BACKUP_FOLDER/$folder_name.last-updated")
            if [ "$last_updated" == "$updated_at" ]; then
                echo "Skipping: $name (no changes since last backup)"
                continue
            fi
        fi

        if [ -d "$BACKUP_FOLDER/$folder_name" ]; then
            rm -rf "$ARCHIVED_FOLDER/$folder_name"
            mv "$BACKUP_FOLDER/$folder_name" "$ARCHIVED_FOLDER/$folder_name"
        fi

        rm -rf "$BACKUP_FOLDER/$folder_name"
        mkdir -p "$BACKUP_FOLDER/$folder_name"

        echo "Downloading: $name ($default_branch branch)"
        files=$(curl --silent --header "Accept: application/vnd.github+json" \
            --header  "Authorization: token $AUTHORIZATION_TOKEN" \
            --header "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/$USER/$name/git/trees/$default_branch?recursive=1" | jq -r '.tree[] | select(.type=="blob") | .path')

        for file in $files; do
            file_url="https://raw.githubusercontent.com/$USER/$name/$default_branch/$file"
            dest_path="$BACKUP_FOLDER/$folder_name/$file"
            mkdir -p "$(dirname "$dest_path")"
            curl -s -H "Authorization: token $AUTHORIZATION_TOKEN" "$file_url" -o "$dest_path"
            echo "Downloaded: $file"
        done

        echo "$updated_at" > "$BACKUP_FOLDER/$folder_name.last-updated"
        echo "✅ All files downloaded to: $BACKUP_FOLDER/$folder_name \n"
    done

    page=$((page+1))
done

echo "[Backup finished]"
