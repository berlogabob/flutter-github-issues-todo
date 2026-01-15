GitDoIt — Flutter GitHub Issues TODO App
GitDoIt is a mobile app built with Flutter for managing GitHub Issues as a simple TODO list. Create, edit, and close issues directly from your phone. Just Do It with GitHub!
GitHub stars
Flutter version
License: MIT
Features

View open/closed GitHub Issues
Create new issues (title, body, labels, assignees, milestone)
Edit and change status (open ↔ closed)
Pull-to-refresh and filters by status
Secure storage for Personal Access Token (fine-grained PAT)
Planned: Kanban board by labels, calendar sync, notifications

Who It's For

Developers using GitHub Issues as their main TODO system
Users needing a minimalist mobile client without bloat (e.g., if Super Productivity feels overwhelming)
Flutter developers looking for a GitHub API integration example

Quick Start

Clone the repositoryBashgit clone https://github.com/berlogabob/flutter-github-issues-todo.git
cd flutter-github-issues-todo
Install dependenciesBashflutter pub get
Run the appBashflutter run
In the app, enter a fine-grained Personal Access Token (with issues: read & write permissions)
→ https://github.com/settings/tokens → Fine-grained tokens

Technologies

Flutter 3.16+
Dart 3.2+
Packages: http, flutter_secure_storage, provider, json_serializable, intl
GitHub REST API v3

Project Structure
textlib/
├── models/         # Issue, Label, Milestone models
├── services/       # GitHubService for all API requests
├── screens/        # AuthScreen, HomeScreen, CreateIssueScreen...
├── providers/      # State management with Provider
└── main.dart
How to Contribute

⭐ Star the repository — it helps with visibility
🐛 Found a bug? Create an issue
💡 Feature ideas (kanban, calendar sync)? Welcome in discussions
Pull Requests with improvements are super!

License
MIT License — fork and use in your own projects.
Just Do It! 🚀
@berlogabob · Lisbon, PT · 2026
