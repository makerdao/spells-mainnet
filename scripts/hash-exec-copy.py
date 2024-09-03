#! /usr/bin/env python3

import argparse
from datetime import datetime
import requests
import subprocess

INPUT_DATE_FORMAT="%Y-%m-%d"
REPO_URL = "/makerdao/community"

def get_executive_by_title (exec_title):
    base_git_api_url = f"https://api.github.com/repos{REPO_URL}/commits"

    api_response = requests.get(
        f"{base_git_api_url}?path=governance/votes/{exec_title}",
        params = {'per_page': '1'}
    )
    api_response.raise_for_status()
    commits = api_response.json()
    if not commits:
        raise ValueError(f"Executive copy not found: {exec_title}")

    commit_hash = commits[0].get("sha", "")

    # Get target exec copy content
    exec_copy_response = requests.get(
        f"https://raw.githubusercontent.com{REPO_URL}/{commit_hash}/governance/votes/{exec_title}"
    )
    exec_copy_response.raise_for_status()

    # Get target exec copy content
    executive_url = exec_copy_response.url

    # Remove trailing whitespace as command substitution in shell script removes it and we want to keep the output consistent
    # Example of shell script to create hash `cast keccak -- "$(wget 'PATH' -q -O - 2>/dev/null)"`
    if exec_copy_response.text[-1] == '\n':
        content = exec_copy_response.text[:-1]

    return content, executive_url, commit_hash

def get_content_hash (content):
    try:
        # Run the 'cast keccak' command with the content
        keccak_result = subprocess.run(
            ['cast', 'keccak', '--', content],  # Run the cast keccak command
            stdout = subprocess.PIPE,  # Capture the output
            stderr = subprocess.PIPE,  # Capture the errors
            text = True,  # Return output as text, not bytes
            check = True  # Raise an exception if the command fails
        )
        return keccak_result.stdout
    except FileNotFoundError:
        raise SystemExit("Error: The 'cast' command is not found. Ensure it's installed and in the PATH.")
    except subprocess.CalledProcessError as e:
        raise SystemExit(f"Command failed with error: {e.stderr}")

def main():
    # Parse positional arguments
    parser = argparse.ArgumentParser()
    parser.add_argument("date", help=f"Date to find executive copy for (format: {INPUT_DATE_FORMAT})")
    date_string = parser.parse_args().date.replace("date=", "")

    try:
        date = datetime.strptime(date_string, INPUT_DATE_FORMAT)
    except ValueError:
        raise SystemExit(f"Invalid date format. Please use {INPUT_DATE_FORMAT}.")

    # Find the executive doc for the given date
    POSSIBLE_EXEC_TITLES = [
        f"Executive%20vote%20-%20{date.strftime('%B %d, %Y')}.md",
        f"Executive%20Vote%20-%20{date.strftime('%B %d, %Y')}.md",
        f"Executive%20vote%20-%20{date.strftime('%B %-d, %Y')}.md",
        f"Executive%20Vote%20-%20{date.strftime('%B %-d, %Y')}.md"
    ]
    executive_content, executive_url, commit_hash = None, None, None
    for exec_title in POSSIBLE_EXEC_TITLES:
        try:
            executive_content, executive_url, commit_hash = get_executive_by_title(exec_title)
            break
        except ValueError as e:
            continue
        except requests.exceptions.RequestException as e:
            raise SystemExit(f"HTTP Request failed: {e}")

    # Check if executive content was found else exit
    if executive_content is None:
        raise SystemExit("Error: Executive Doc not found")

    # Hash target exec copy
    exec_hash = get_content_hash(executive_content)

    # Output target exec copy hash
    print(f"Community repo commit: {commit_hash}")
    print(f"Raw GitHub URL: {executive_url}")
    print(f"Exec copy hash: {exec_hash}")

# Execute the main function
main()
