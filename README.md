# Later Time Capsule Map
### Project Structure
- `data/`: contains app-level state management (e.g. `ChangeNotifier`, providers)
- `views/pages/`: each file = 1 screen, responsible for layout and routing
- `widgets/`: shared UI components across screens

### Code Conventions
- `snake_case` for file names and folders: `map_page.dart`
- `PascalCase` for class names: `MapPage`
- `camelCase` for variables and functions: `userPosition`, `loadData()`
- Use `const` constructors where possible
- Avoid deeply nested widgets — extract into smaller widgets
- Keep business logic outside of widgets (e.g., in notifiers or services)

### Repo Conventions
- Branch name starts with `feature` if it contains new feature (including adding/removing new packages, assets etc.) `feature/some-feature-to-do`
- `bugfix` if it contains bugfixes that are supposed to be reviewd `bugfix/bug-to-fix`
- `hotfix` if it contains fix for major bug that needs to be merged asap `hotfix/important-bug-to-fix`
- Branch should be responsible only for the thing it describes (usually the equivalent of one task)
- Commit name should be short and concise
- Anything else that needs to be mentioned should be in commit description
