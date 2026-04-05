#!/bin/zsh

# 1. Run this shell script, locates the last transaction file and extracts the latest date from it, opens capitalone.com
# 2. [MANUAL] After manually dowloading latest cvs, hit enter. Locates the new file
# 3. Duplicates new file, removes duplicate transactions from original new file
# 4. [MANUAL] Enter transactions from checking account and other banks, edit the csv
# 5. Opens the Python script for formatting  in Pycharm. 
# 6. [MANUAL] Run the Pycharm project manually
# 7. [MANUAL] Review and correct as needed before putting in google sheets

EXPENSES_FOLDER="/Users/anandkumar/Library/CloudStorage/GoogleDrive-write2anand.kumar@gmail.com/My Drive/Synced/Monetary/Expenses/US/US Expenses"
DOWNLOADS_FOLDER="/Users/anandkumar/Downloads"

# ------------------------ STEP 1: Extract the latest date from existing transactions file ------------------------ #

# Count CSV files
csv_count_run1=$(find "$EXPENSES_FOLDER" -maxdepth 1 -type f -name "*.csv" | wc -l)

if (( csv_count_run1 != 1 )); then
  echo "❌ CSV file count is not exactly 1 in $EXPENSES_FOLDER"
  exit 1
fi

# Exactly one CSV file → capture its name
older_csv_file=$(find "$EXPENSES_FOLDER" -maxdepth 1 -type f -name "*.csv")

# Grab the line immediately after the first empty line
line_after_empty=$(awk 'found_empty {print; exit} /^$/ {found_empty=1}' "$older_csv_file" | tr -d '\r')

if [[ -z $line_after_empty ]]; then
  echo "❌ '$older_csv_file' has no non-empty line after the first empty line" >&2
  exit 1
fi

# Extract first comma-separated entry
first_transaction_date=${line_after_empty%%,*}

echo "✅ Existing CSV file: $older_csv_file"
echo "✅ First transaction date: $first_transaction_date"

capitalone_url="https://myaccounts.capitalone.com/Card/KA+MCVSi2a3iUX6dBNYUwLOnS1hVGnxAMeMqeqfM6ZI=/DownloadTransactions"
open -a "Safari" "$capitalone_url"

echo "Press Enter once you have downloaded new csv file!"
read _

# ------------------------ STEP 2: Locate the new transactions file ------------------------ #

# Locate the new transactions file in Downloads folder and move it to Expense folder
csv_count_downloads=$(find "$DOWNLOADS_FOLDER" -maxdepth 1 -type f -name "*_transaction_download.csv" | wc -l)

if (( csv_count_downloads != 1 )); then
  echo "❌ CSV transactions file count is not exactly 1 in $DOWNLOADS_FOLDER"
  exit 1
fi

downloads_csv_file=$(find "$DOWNLOADS_FOLDER" -maxdepth 1 -type f -name "*.csv")
mv "$downloads_csv_file" $EXPENSES_FOLDER

# Count CSV files afresh
csv_count_run2=$(find "$EXPENSES_FOLDER" -maxdepth 1 -type f -name "*.csv" | wc -l)

if (( csv_count_run2 != 2 )); then
  echo "❌ CSV file count is not 2, please check if you have moved the new csv from Downloads folder to here"
  exit 1
fi

# Save the CSV files locations in an array
csv_files_run2=()
while IFS= read -r -d '' file; do
  csv_files_run2+=("$file")
done < <(find "$EXPENSES_FOLDER" -maxdepth 1 -type f -name "*.csv" -print0)

# Find the name of the new CSV file
for f in "${csv_files_run2[@]}"; do
  if [[ "$f" != "$older_csv_file" ]]; then
    new_csv_file="$f"
    break
  fi
done

echo "✅ New CSV file: $new_csv_file"

# ------------------------ STEP 3: Remove duplicative transactions from new file ------------------------ #

backup_copy="${new_csv_file%.csv}_backup.csv"
cp "$new_csv_file" "$backup_copy"

{
  # write header line
  echo "Transaction Date,Posted Date,Card No.,Description,Category,Debit,Credit"
  # Filter out lines that are already in csv_file_run1
  grep -vxF -f "$older_csv_file" "$backup_copy"
} > "$new_csv_file"

# ------------------------ STEP 4: Open PyCharm ------------------------ #

open -a "PyCharm CE" "/Users/anandkumar/Documents/Projects/Python/ExpenseTracker"

echo "✅ Done now. Make sure to enter Checking account and BOA card transactions first."