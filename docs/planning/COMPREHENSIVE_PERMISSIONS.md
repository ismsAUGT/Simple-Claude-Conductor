# Comprehensive Permissions for Uninterrupted Execution

This document enumerates all operations Claude typically needs during plan execution, organized by category.

## Permission Categories

### 1. Read Operations (Always Safe)

These never modify anything and should always be allowed:

```json
"Read",
"Glob",
"Grep",
"WebSearch",
"WebFetch"
```

### 2. Task/Agent Operations

For spawning subagents:

```json
"Task"
```

### 3. Write Operations (New Files)

Creating new files in project directories:

```json
"Write(docs/**)",
"Write(src/**)",
"Write(output/**)",
"Write(tests/**)",
"Write(lib/**)",
"Write(scripts/**)",
"Write(config/**)",
"Write(public/**)",
"Write(static/**)",
"Write(templates/**)",
"Write(components/**)",
"Write(pages/**)",
"Write(api/**)",
"Write(utils/**)",
"Write(helpers/**)",
"Write(models/**)",
"Write(views/**)",
"Write(controllers/**)",
"Write(services/**)",
"Write(middleware/**)",
"Write(hooks/**)",
"Write(assets/**)",
"Write(styles/**)",
"Write(css/**)",
"Write(js/**)",

"Write(STATUS.md)",
"Write(Questions_For_You.md)",
"Write(README.md)",
"Write(CHANGELOG.md)",
"Write(LICENSE)",
"Write(.gitignore)",
"Write(.env.example)",

"Write(*.md)",
"Write(*.txt)",
"Write(*.json)",
"Write(*.yaml)",
"Write(*.yml)",
"Write(*.toml)",
"Write(*.ini)",
"Write(*.cfg)",
"Write(*.conf)",

"Write(*.py)",
"Write(*.js)",
"Write(*.ts)",
"Write(*.tsx)",
"Write(*.jsx)",
"Write(*.html)",
"Write(*.css)",
"Write(*.scss)",
"Write(*.less)",
"Write(*.vue)",
"Write(*.svelte)",

"Write(*.java)",
"Write(*.kt)",
"Write(*.scala)",
"Write(*.go)",
"Write(*.rs)",
"Write(*.rb)",
"Write(*.php)",
"Write(*.cs)",
"Write(*.cpp)",
"Write(*.c)",
"Write(*.h)",
"Write(*.hpp)",
"Write(*.swift)",
"Write(*.m)",

"Write(*.sql)",
"Write(*.graphql)",
"Write(*.proto)",

"Write(*.sh)",
"Write(*.bat)",
"Write(*.ps1)",
"Write(*.cmd)",

"Write(Dockerfile)",
"Write(docker-compose.yml)",
"Write(Makefile)",
"Write(CMakeLists.txt)",
"Write(requirements.txt)",
"Write(package.json)",
"Write(package-lock.json)",
"Write(tsconfig.json)",
"Write(pyproject.toml)",
"Write(setup.py)",
"Write(Cargo.toml)",
"Write(go.mod)",
"Write(pom.xml)",
"Write(build.gradle)"
```

### 4. Edit Operations (Modify Existing)

Editing files in project directories:

```json
"Edit(docs/**)",
"Edit(src/**)",
"Edit(output/**)",
"Edit(tests/**)",
"Edit(lib/**)",
"Edit(scripts/**)",
"Edit(config/**)",
"Edit(public/**)",
"Edit(static/**)",
"Edit(templates/**)",
"Edit(components/**)",
"Edit(pages/**)",
"Edit(api/**)",
"Edit(utils/**)",
"Edit(helpers/**)",
"Edit(models/**)",
"Edit(views/**)",
"Edit(controllers/**)",
"Edit(services/**)",
"Edit(middleware/**)",
"Edit(hooks/**)",
"Edit(assets/**)",
"Edit(styles/**)",
"Edit(css/**)",
"Edit(js/**)",

"Edit(STATUS.md)",
"Edit(Questions_For_You.md)",
"Edit(README.md)",
"Edit(CHANGELOG.md)",
"Edit(.gitignore)",
"Edit(.env.example)",

"Edit(*.md)",
"Edit(*.txt)",
"Edit(*.json)",
"Edit(*.yaml)",
"Edit(*.yml)",
"Edit(*.toml)",
"Edit(*.py)",
"Edit(*.js)",
"Edit(*.ts)",
"Edit(*.tsx)",
"Edit(*.jsx)",
"Edit(*.html)",
"Edit(*.css)",
"Edit(*.scss)",
"Edit(*.vue)",
"Edit(*.svelte)",
"Edit(*.java)",
"Edit(*.go)",
"Edit(*.rs)",
"Edit(*.rb)",
"Edit(*.php)",
"Edit(*.cs)",
"Edit(*.cpp)",
"Edit(*.c)",
"Edit(*.h)",
"Edit(*.sh)",
"Edit(*.bat)",
"Edit(*.sql)",

"Edit(Dockerfile)",
"Edit(docker-compose.yml)",
"Edit(Makefile)",
"Edit(requirements.txt)",
"Edit(package.json)",
"Edit(tsconfig.json)",
"Edit(pyproject.toml)"
```

### 5. Bash Operations

#### Directory & File Viewing
```json
"Bash(ls *)",
"Bash(ls)",
"Bash(dir *)",
"Bash(dir)",
"Bash(pwd)",
"Bash(cd *)",
"Bash(tree *)",
"Bash(cat *)",
"Bash(type *)",
"Bash(head *)",
"Bash(tail *)",
"Bash(less *)",
"Bash(more *)",
"Bash(wc *)",
"Bash(file *)",
"Bash(stat *)",
"Bash(find *)",
"Bash(which *)",
"Bash(where *)",
"Bash(echo *)",
"Bash(printf *)"
```

#### Directory Management
```json
"Bash(mkdir *)",
"Bash(mkdir -p *)",
"Bash(cp *)",
"Bash(copy *)",
"Bash(mv *)",
"Bash(move *)",
"Bash(touch *)"
```

#### Python
```json
"Bash(python *)",
"Bash(python3 *)",
"Bash(py *)",
"Bash(pip install *)",
"Bash(pip3 install *)",
"Bash(pip freeze*)",
"Bash(pip list*)",
"Bash(pytest*)",
"Bash(python -m pytest*)",
"Bash(python -m pip*)",
"Bash(python -m venv*)",
"Bash(mypy *)",
"Bash(pyright *)",
"Bash(ruff *)",
"Bash(flake8 *)",
"Bash(black *)",
"Bash(isort *)",
"Bash(pylint *)",
"Bash(bandit *)",
"Bash(poetry *)",
"Bash(pdm *)",
"Bash(uv *)"
```

#### Node.js / JavaScript
```json
"Bash(node *)",
"Bash(npm *)",
"Bash(npm install*)",
"Bash(npm run*)",
"Bash(npm test*)",
"Bash(npm start*)",
"Bash(npm build*)",
"Bash(npm ci*)",
"Bash(npx *)",
"Bash(yarn *)",
"Bash(pnpm *)",
"Bash(bun *)",
"Bash(tsc *)",
"Bash(eslint *)",
"Bash(prettier *)",
"Bash(jest *)",
"Bash(vitest *)",
"Bash(vite *)",
"Bash(webpack *)",
"Bash(esbuild *)",
"Bash(rollup *)"
```

#### Go
```json
"Bash(go *)",
"Bash(go build*)",
"Bash(go run*)",
"Bash(go test*)",
"Bash(go mod*)",
"Bash(go get*)",
"Bash(go fmt*)",
"Bash(go vet*)",
"Bash(golangci-lint *)"
```

#### Rust
```json
"Bash(cargo *)",
"Bash(cargo build*)",
"Bash(cargo run*)",
"Bash(cargo test*)",
"Bash(cargo check*)",
"Bash(cargo clippy*)",
"Bash(cargo fmt*)",
"Bash(rustc *)",
"Bash(rustfmt *)"
```

#### Java / JVM
```json
"Bash(java *)",
"Bash(javac *)",
"Bash(mvn *)",
"Bash(gradle *)",
"Bash(./gradlew *)"
```

#### Ruby
```json
"Bash(ruby *)",
"Bash(gem *)",
"Bash(bundle *)",
"Bash(rails *)",
"Bash(rake *)",
"Bash(rspec *)"
```

#### Git (Safe Operations)
```json
"Bash(git status*)",
"Bash(git diff*)",
"Bash(git log*)",
"Bash(git show*)",
"Bash(git branch*)",
"Bash(git add *)",
"Bash(git add .)",
"Bash(git commit*)",
"Bash(git stash*)",
"Bash(git checkout -b *)",
"Bash(git switch *)",
"Bash(git fetch*)",
"Bash(git pull*)",
"Bash(git remote*)",
"Bash(git config --get*)",
"Bash(git rev-parse*)",
"Bash(git ls-files*)",
"Bash(git blame*)"
```

#### Docker (Read-Only / Safe)
```json
"Bash(docker ps*)",
"Bash(docker images*)",
"Bash(docker logs*)",
"Bash(docker build*)",
"Bash(docker run*)",
"Bash(docker-compose up*)",
"Bash(docker-compose down*)",
"Bash(docker-compose build*)",
"Bash(docker-compose logs*)"
```

#### Curl / HTTP
```json
"Bash(curl *)",
"Bash(wget *)",
"Bash(http *)"
```

#### Environment
```json
"Bash(env)",
"Bash(printenv *)",
"Bash(set)",
"Bash(export *)"
```

#### Windows-Specific
```json
"Bash(cmd /c *)",
"Bash(powershell *)",
"Bash(Start-Process *)",
"Bash(Get-Content *)",
"Bash(Set-Content *)",
"Bash(Test-Path *)"
```

### 6. Explicit Deny List

Operations that should NEVER be allowed:

```json
"Bash(rm -rf /)",
"Bash(rm -rf ~)",
"Bash(rm -rf /*)",
"Bash(rm -rf $HOME)",
"Bash(del /s /q C:\\*)",
"Bash(del /s /q %USERPROFILE%*)",
"Bash(format *)",
"Bash(mkfs *)",
"Bash(dd if=*)",

"Bash(git push --force origin main)",
"Bash(git push --force origin master)",
"Bash(git push -f origin main)",
"Bash(git push -f origin master)",
"Bash(git reset --hard origin/main)",
"Bash(git reset --hard origin/master)",
"Bash(git clean -fdx)",

"Bash(sudo *)",
"Bash(su *)",
"Bash(chmod 777 *)",
"Bash(chown *)",

"Bash(curl * | bash)",
"Bash(wget * | bash)",
"Bash(curl * | sh)",

"Write(C:\\Windows\\*)",
"Write(C:\\Program Files\\*)",
"Write(C:\\Program Files (x86)\\*)",
"Write(/etc/*)",
"Write(/usr/*)",
"Write(/bin/*)",
"Write(/sbin/*)",
"Write(/boot/*)",

"Edit(C:\\Windows\\*)",
"Edit(/etc/*)",
"Edit(/usr/*)"
```

---

## Consolidated settings.local.json

Here's the complete, production-ready permissions file:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "WebSearch",
      "WebFetch",
      "Task",

      "Write(docs/**)",
      "Write(src/**)",
      "Write(output/**)",
      "Write(tests/**)",
      "Write(lib/**)",
      "Write(scripts/**)",
      "Write(config/**)",
      "Write(public/**)",
      "Write(components/**)",
      "Write(pages/**)",
      "Write(api/**)",
      "Write(utils/**)",
      "Write(services/**)",
      "Write(styles/**)",

      "Write(STATUS.md)",
      "Write(Questions_For_You.md)",
      "Write(README.md)",
      "Write(*.md)",
      "Write(*.json)",
      "Write(*.yaml)",
      "Write(*.yml)",
      "Write(*.py)",
      "Write(*.js)",
      "Write(*.ts)",
      "Write(*.tsx)",
      "Write(*.jsx)",
      "Write(*.html)",
      "Write(*.css)",
      "Write(*.go)",
      "Write(*.rs)",
      "Write(*.java)",
      "Write(*.sh)",
      "Write(*.bat)",
      "Write(*.sql)",
      "Write(Dockerfile)",
      "Write(docker-compose.yml)",
      "Write(Makefile)",
      "Write(requirements.txt)",
      "Write(package.json)",

      "Edit(docs/**)",
      "Edit(src/**)",
      "Edit(output/**)",
      "Edit(tests/**)",
      "Edit(lib/**)",
      "Edit(scripts/**)",
      "Edit(config/**)",
      "Edit(public/**)",
      "Edit(components/**)",
      "Edit(STATUS.md)",
      "Edit(Questions_For_You.md)",
      "Edit(*.md)",
      "Edit(*.json)",
      "Edit(*.yaml)",
      "Edit(*.py)",
      "Edit(*.js)",
      "Edit(*.ts)",
      "Edit(*.html)",
      "Edit(*.css)",

      "Bash(ls *)",
      "Bash(dir *)",
      "Bash(pwd)",
      "Bash(cat *)",
      "Bash(type *)",
      "Bash(head *)",
      "Bash(tail *)",
      "Bash(echo *)",
      "Bash(mkdir *)",
      "Bash(cp *)",
      "Bash(copy *)",
      "Bash(mv *)",
      "Bash(move *)",

      "Bash(python *)",
      "Bash(python3 *)",
      "Bash(py *)",
      "Bash(pip *)",
      "Bash(pytest *)",
      "Bash(mypy *)",
      "Bash(ruff *)",
      "Bash(black *)",

      "Bash(node *)",
      "Bash(npm *)",
      "Bash(npx *)",
      "Bash(yarn *)",
      "Bash(pnpm *)",
      "Bash(tsc *)",
      "Bash(eslint *)",
      "Bash(jest *)",
      "Bash(vitest *)",

      "Bash(go *)",
      "Bash(cargo *)",
      "Bash(java *)",
      "Bash(mvn *)",
      "Bash(gradle *)",

      "Bash(git status*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(git add *)",
      "Bash(git commit*)",
      "Bash(git branch*)",
      "Bash(git checkout*)",
      "Bash(git fetch*)",
      "Bash(git pull*)",
      "Bash(git stash*)",

      "Bash(docker ps*)",
      "Bash(docker build*)",
      "Bash(docker run*)",
      "Bash(docker-compose *)",

      "Bash(curl *)",
      "Bash(wget *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(del /s /q *)",
      "Bash(format *)",
      "Bash(sudo *)",
      "Bash(git push --force*)",
      "Bash(git push -f *)",
      "Bash(git reset --hard*)",
      "Bash(git clean -fdx*)",
      "Bash(chmod 777*)",
      "Bash(curl * | bash)",
      "Bash(curl * | sh)",
      "Write(C:\\Windows\\*)",
      "Write(C:\\Program Files*)",
      "Edit(C:\\Windows\\*)"
    ]
  }
}
```

---

## UI Permission Interruption Handling

When Claude is interrupted for a permission not in the allow list:

### Detection

The UI polls `STATUS.md`. If no update for >60 seconds during execution, likely permission prompt.

### User Notification

```
┌─────────────────────────────────────────────────────────────────┐
│  ⚠️ ATTENTION NEEDED                                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Claude may be waiting for permission in the terminal.          │
│                                                                  │
│  Please check the terminal window and:                          │
│    • Press 'y' then Enter to allow the action                   │
│    • Or press 'n' then Enter to deny it                         │
│                                                                  │
│  The operation that needs permission will be shown in the       │
│  terminal. If you allow it, we'll add it to the auto-approve    │
│  list for next time.                                            │
│                                                                  │
│  [Open Terminal Window]                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Learning from Interruptions

When user approves a new permission:
1. Log it to `conductor-permissions-log.json`
2. Periodically review and add common ones to default allow list
3. Over time, interruptions become rare

---

## Testing Strategy

To validate comprehensive permissions:

1. **Run a typical project** end-to-end
2. **Log every tool call** Claude makes (via hook)
3. **Check if any were not pre-approved**
4. **Add missing patterns** to allow list
5. **Repeat** with different project types

This creates a feedback loop where permissions improve over time.
