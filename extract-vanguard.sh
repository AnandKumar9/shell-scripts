# !/bin/zsh
osascript -e 'tell application "Safari" to do JavaScript "document.documentElement.outerHTML" in front document' > /Users/anandkumar/Desktop/PortfolioHTML.txt

/Users/anandkumar/Documents/Projects/Python/InvestmentsTracker/.venv/bin/python3 /Users/anandkumar/Documents/Projects/Python/InvestmentsTracker/AnalyzerIndexFunds.py
/Users/anandkumar/Documents/Projects/Python/InvestmentsTracker/.venv/bin/python3 /Users/anandkumar/Documents/Projects/Python/InvestmentsTracker/AnalyzerETFsStocks.py

rm /Users/anandkumar/Desktop/PortfolioHTML.txt