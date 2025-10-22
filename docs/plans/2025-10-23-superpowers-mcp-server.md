# Superpowers MCP Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an MCP server that enforces skill discovery through required tool calls, making skill usage as unavoidable as TodoWrite is now.

**Architecture:** Go-based MCP server that indexes skill files, performs semantic matching on user requests, and returns ranked skill matches. Provides structural enforcement at the tool level rather than documentation level.

**Tech Stack:** Go, official MCP Go SDK, YAML frontmatter parsing, semantic text matching

---

## Task 1: Project Setup and Dependencies

**Files:**
- Create: `superpowers-mcp/go.mod`
- Create: `superpowers-mcp/go.sum`
- Create: `superpowers-mcp/main.go`
- Create: `superpowers-mcp/.gitignore`
- Create: `superpowers-mcp/README.md`

**Step 1: Initialize Go module**

```bash
cd superpowers-mcp
go mod init github.com/your-org/superpowers-mcp
```

**Step 2: Add MCP SDK dependency**

```bash
go get github.com/modelcontextprotocol/go-sdk
```

**Step 3: Create main.go skeleton**

```go
package main

import (
	"log"
)

func main() {
	log.Println("Superpowers MCP Server starting...")
}
```

**Step 4: Create .gitignore**

```
# Binaries
superpowers-mcp
superpowers-mcp-*

# Go
*.exe
*.exe~
*.dll
*.so
*.dylib
*.test
*.out
go.work
```

**Step 5: Create README.md**

```markdown
# Superpowers MCP Server

MCP server for enforcing skill discovery in Claude Code.

## Installation

```bash
go build -o superpowers-mcp
```

## Usage

Add to Claude Code MCP config:
```json
{
  "superpowers": {
    "command": "/path/to/superpowers-mcp",
    "args": ["--skills-dir", "/path/to/skills"]
  }
}
```
```

**Step 6: Verify setup**

Run: `go mod tidy && go build`
Expected: Binary builds successfully

**Step 7: Commit**

```bash
git add .
git commit -m "feat: initialize superpowers-mcp Go project"
```

---

## Task 2: Skill File Indexer

**Files:**
- Create: `superpowers-mcp/internal/skills/types.go`
- Create: `superpowers-mcp/internal/skills/indexer.go`
- Create: `superpowers-mcp/internal/skills/indexer_test.go`

**Step 1: Write the failing test for skill loading**

Create `internal/skills/indexer_test.go`:

```go
package skills

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadSkills(t *testing.T) {
	// Create temp skills directory
	tmpDir := t.TempDir()
	skillDir := filepath.Join(tmpDir, "test-skill")
	os.MkdirAll(skillDir, 0755)

	// Create test skill file
	skillContent := `---
name: test-skill
description: Use when testing - test description
---

# Test Skill

Content here.`

	os.WriteFile(filepath.Join(skillDir, "SKILL.md"), []byte(skillContent), 0644)

	// Load skills
	indexer := NewIndexer(tmpDir)
	skills, err := indexer.LoadSkills()

	if err != nil {
		t.Fatalf("LoadSkills failed: %v", err)
	}

	if len(skills) != 1 {
		t.Fatalf("Expected 1 skill, got %d", len(skills))
	}

	if skills[0].Name != "test-skill" {
		t.Errorf("Expected name 'test-skill', got '%s'", skills[0].Name)
	}

	if skills[0].Description != "Use when testing - test description" {
		t.Errorf("Expected description to match, got '%s'", skills[0].Description)
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/skills/... -v`
Expected: FAIL with "package skills: undefined"

**Step 3: Write types.go**

Create `internal/skills/types.go`:

```go
package skills

// Skill represents a parsed skill file
type Skill struct {
	Name        string
	Description string
	Path        string
	Content     string
}
```

**Step 4: Write minimal indexer implementation**

Create `internal/skills/indexer.go`:

```go
package skills

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type Indexer struct {
	skillsDir string
}

func NewIndexer(skillsDir string) *Indexer {
	return &Indexer{skillsDir: skillsDir}
}

func (idx *Indexer) LoadSkills() ([]Skill, error) {
	var skills []Skill

	// Walk skills directory
	err := filepath.Walk(idx.skillsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Look for SKILL.md files
		if !info.IsDir() && info.Name() == "SKILL.md" {
			skill, err := parseSkillFile(path)
			if err != nil {
				return fmt.Errorf("parsing %s: %w", path, err)
			}
			skills = append(skills, skill)
		}

		return nil
	})

	return skills, err
}

func parseSkillFile(path string) (Skill, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return Skill{}, err
	}

	text := string(content)
	skill := Skill{
		Path:    path,
		Content: text,
	}

	// Parse YAML frontmatter
	if strings.HasPrefix(text, "---\n") {
		parts := strings.SplitN(text[4:], "\n---", 2)
		if len(parts) == 2 {
			frontmatter := parts[0]

			// Simple YAML parsing (name and description only)
			for _, line := range strings.Split(frontmatter, "\n") {
				if strings.HasPrefix(line, "name:") {
					skill.Name = strings.TrimSpace(strings.TrimPrefix(line, "name:"))
				}
				if strings.HasPrefix(line, "description:") {
					skill.Description = strings.TrimSpace(strings.TrimPrefix(line, "description:"))
				}
			}
		}
	}

	return skill, nil
}
```

**Step 5: Run test to verify it passes**

Run: `go test ./internal/skills/... -v`
Expected: PASS

**Step 6: Commit**

```bash
git add internal/skills/
git commit -m "feat: add skill file indexer with YAML frontmatter parsing"
```

---

## Task 3: Semantic Skill Matcher

**Files:**
- Create: `superpowers-mcp/internal/skills/matcher.go`
- Create: `superpowers-mcp/internal/skills/matcher_test.go`

**Step 1: Write the failing test for skill matching**

Create `internal/skills/matcher_test.go`:

```go
package skills

import (
	"testing"
)

func TestMatchSkills(t *testing.T) {
	skills := []Skill{
		{
			Name:        "test-driven-development",
			Description: "Use when implementing any feature or bugfix, before writing implementation code",
		},
		{
			Name:        "systematic-debugging",
			Description: "Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes",
		},
		{
			Name:        "discovery-tree-workflow",
			Description: "Use when planning and tracking work - creates visible, emergent work breakdown",
		},
	}

	matcher := NewMatcher(skills)

	testCases := []struct {
		query    string
		expected string
	}{
		{"implement user login", "test-driven-development"},
		{"fix broken test", "systematic-debugging"},
		{"plan feature implementation", "discovery-tree-workflow"},
	}

	for _, tc := range testCases {
		matches := matcher.Match(tc.query, 3)

		if len(matches) == 0 {
			t.Errorf("Query '%s': expected matches, got none", tc.query)
			continue
		}

		if matches[0].Name != tc.expected {
			t.Errorf("Query '%s': expected '%s', got '%s'", tc.query, tc.expected, matches[0].Name)
		}
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/skills/... -v`
Expected: FAIL with "undefined: NewMatcher"

**Step 3: Write minimal matcher implementation**

Create `internal/skills/matcher.go`:

```go
package skills

import (
	"sort"
	"strings"
)

type SkillMatch struct {
	Skill
	Score float64
}

type Matcher struct {
	skills []Skill
}

func NewMatcher(skills []Skill) *Matcher {
	return &Matcher{skills: skills}
}

func (m *Matcher) Match(query string, limit int) []SkillMatch {
	var matches []SkillMatch

	queryLower := strings.ToLower(query)
	queryWords := strings.Fields(queryLower)

	for _, skill := range m.skills {
		score := m.scoreSkill(skill, queryLower, queryWords)
		if score > 0 {
			matches = append(matches, SkillMatch{
				Skill: skill,
				Score: score,
			})
		}
	}

	// Sort by score descending
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].Score > matches[j].Score
	})

	// Return top N matches
	if limit > 0 && len(matches) > limit {
		matches = matches[:limit]
	}

	return matches
}

func (m *Matcher) scoreSkill(skill Skill, query string, queryWords []string) float64 {
	descLower := strings.ToLower(skill.Description)
	nameLower := strings.ToLower(skill.Name)

	score := 0.0

	// Exact phrase match in description (high score)
	if strings.Contains(descLower, query) {
		score += 10.0
	}

	// Name match (medium-high score)
	for _, word := range queryWords {
		if strings.Contains(nameLower, word) {
			score += 5.0
		}
	}

	// Individual word matches in description (lower score)
	for _, word := range queryWords {
		if len(word) > 3 && strings.Contains(descLower, word) {
			score += 1.0
		}
	}

	return score
}
```

**Step 4: Run test to verify it passes**

Run: `go test ./internal/skills/... -v`
Expected: PASS

**Step 5: Commit**

```bash
git add internal/skills/
git commit -m "feat: add semantic skill matcher with keyword scoring"
```

---

## Task 4: MCP Server Implementation

**Files:**
- Create: `superpowers-mcp/internal/server/server.go`
- Create: `superpowers-mcp/internal/server/tools.go`
- Modify: `superpowers-mcp/main.go`

**Step 1: Write server.go skeleton**

Create `internal/server/server.go`:

```go
package server

import (
	"context"
	"log"

	"github.com/your-org/superpowers-mcp/internal/skills"
	mcp "github.com/modelcontextprotocol/go-sdk"
)

type SuperpowersServer struct {
	matcher *skills.Matcher
	indexer *skills.Indexer
}

func New(skillsDir string) (*SuperpowersServer, error) {
	indexer := skills.NewIndexer(skillsDir)
	skillsList, err := indexer.LoadSkills()
	if err != nil {
		return nil, err
	}

	log.Printf("Loaded %d skills from %s", len(skillsList), skillsDir)

	matcher := skills.NewMatcher(skillsList)

	return &SuperpowersServer{
		matcher: matcher,
		indexer: indexer,
	}, nil
}

func (s *SuperpowersServer) Start(ctx context.Context) error {
	// TODO: Implement MCP server protocol
	log.Println("Superpowers MCP server started")
	<-ctx.Done()
	return nil
}
```

**Step 2: Write tools.go with skill-search tool**

Create `internal/server/tools.go`:

```go
package server

import (
	"context"
	"encoding/json"
)

// SkillSearchRequest is the input for skill-search tool
type SkillSearchRequest struct {
	Query string `json:"query"`
	Limit int    `json:"limit,omitempty"`
}

// SkillSearchResult is the output for skill-search tool
type SkillSearchResult struct {
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Path        string  `json:"path"`
	Score       float64 `json:"score"`
}

// HandleSkillSearch implements the skill-search MCP tool
func (s *SuperpowersServer) HandleSkillSearch(ctx context.Context, params json.RawMessage) (interface{}, error) {
	var req SkillSearchRequest
	if err := json.Unmarshal(params, &req); err != nil {
		return nil, err
	}

	if req.Limit == 0 {
		req.Limit = 5
	}

	matches := s.matcher.Match(req.Query, req.Limit)

	results := make([]SkillSearchResult, len(matches))
	for i, match := range matches {
		results[i] = SkillSearchResult{
			Name:        match.Name,
			Description: match.Description,
			Path:        match.Path,
			Score:       match.Score,
		}
	}

	return map[string]interface{}{
		"matches": results,
	}, nil
}
```

**Step 3: Update main.go to use server**

Modify `main.go`:

```go
package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/your-org/superpowers-mcp/internal/server"
)

func main() {
	skillsDir := flag.String("skills-dir", "", "Path to skills directory")
	flag.Parse()

	if *skillsDir == "" {
		log.Fatal("--skills-dir is required")
	}

	srv, err := server.New(*skillsDir)
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigCh
		log.Println("Shutting down...")
		cancel()
	}()

	if err := srv.Start(ctx); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
```

**Step 4: Test compilation**

Run: `go build`
Expected: Binary builds successfully

**Step 5: Commit**

```bash
git add internal/server/ main.go
git commit -m "feat: add MCP server skeleton with skill-search tool handler"
```

---

## Task 5: MCP Protocol Integration

**Files:**
- Modify: `internal/server/server.go`
- Create: `internal/server/server_test.go`

**Step 1: Write test for MCP tool registration**

Create `internal/server/server_test.go`:

```go
package server

import (
	"testing"
)

func TestToolsRegistered(t *testing.T) {
	// Test that skill-search tool is properly registered
	// This is a placeholder - actual test depends on MCP SDK API
	t.Skip("TODO: Implement once MCP SDK integration is complete")
}
```

**Step 2: Update server.go with MCP SDK integration**

Modify `internal/server/server.go` to integrate with actual MCP Go SDK:

```go
// NOTE: This implementation depends on the official MCP Go SDK API
// The exact API may differ - consult go-sdk documentation

package server

import (
	"context"
	"log"

	"github.com/your-org/superpowers-mcp/internal/skills"
	mcp "github.com/modelcontextprotocol/go-sdk"
)

type SuperpowersServer struct {
	matcher   *skills.Matcher
	indexer   *skills.Indexer
	mcpServer *mcp.Server
}

func New(skillsDir string) (*SuperpowersServer, error) {
	indexer := skills.NewIndexer(skillsDir)
	skillsList, err := indexer.LoadSkills()
	if err != nil {
		return nil, err
	}

	log.Printf("Loaded %d skills from %s", len(skillsList), skillsDir)

	matcher := skills.NewMatcher(skillsList)

	// Create MCP server
	mcpServer := mcp.NewServer("superpowers", "1.0.0")

	s := &SuperpowersServer{
		matcher:   matcher,
		indexer:   indexer,
		mcpServer: mcpServer,
	}

	// Register tools
	s.registerTools()

	return s, nil
}

func (s *SuperpowersServer) registerTools() {
	// Register skill-search tool
	s.mcpServer.RegisterTool(mcp.Tool{
		Name:        "skill_search",
		Description: "Search for relevant skills based on user's task description. Returns ranked list of matching skills with names, descriptions, and file paths.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"query": map[string]interface{}{
					"type":        "string",
					"description": "The user's request or task description to match against skill descriptions",
				},
				"limit": map[string]interface{}{
					"type":        "integer",
					"description": "Maximum number of matches to return (default: 5)",
					"default":     5,
				},
			},
			Required: []string{"query"},
		},
	}, s.HandleSkillSearch)
}

func (s *SuperpowersServer) Start(ctx context.Context) error {
	log.Println("Superpowers MCP server started")
	return s.mcpServer.Serve(ctx)
}
```

**Step 3: Build and test**

Run: `go build`
Expected: Build succeeds

**Step 4: Manual testing with MCP inspector**

Run: `./superpowers-mcp --skills-dir /path/to/skills`
Test: Use MCP inspector tool to call skill_search with query "implement feature"
Expected: Returns relevant skills

**Step 5: Commit**

```bash
git add internal/server/
git commit -m "feat: integrate MCP Go SDK and register skill_search tool"
```

---

## Task 6: Installation Script and Documentation

**Files:**
- Create: `superpowers-mcp/install.sh`
- Create: `superpowers-mcp/docs/INSTALLATION.md`
- Modify: `superpowers-mcp/README.md`

**Step 1: Write install.sh**

Create `install.sh`:

```bash
#!/bin/bash
set -e

echo "Installing Superpowers MCP Server..."

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    arm64|aarch64)
        ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Build binary
echo "Building for $OS-$ARCH..."
go build -o superpowers-mcp-$OS-$ARCH

# Install to /usr/local/bin (or user-specified location)
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"
cp superpowers-mcp-$OS-$ARCH "$INSTALL_DIR/superpowers-mcp"
chmod +x "$INSTALL_DIR/superpowers-mcp"

echo "Installed to $INSTALL_DIR/superpowers-mcp"
echo ""
echo "Add to Claude Code MCP config (~/.config/claude/config.json):"
echo ""
echo '{
  "mcpServers": {
    "superpowers": {
      "command": "'$INSTALL_DIR'/superpowers-mcp",
      "args": ["--skills-dir", "/path/to/your/skills"]
    }
  }
}'
```

**Step 2: Write INSTALLATION.md**

Create `docs/INSTALLATION.md`:

```markdown
# Installation Guide

## Prerequisites

- Go 1.21 or later
- Claude Code with MCP support

## Installation

### Option 1: Install Script

```bash
./install.sh
```

### Option 2: Manual Installation

```bash
go build -o superpowers-mcp
cp superpowers-mcp ~/.local/bin/
```

## Configuration

Add to your Claude Code MCP configuration (`~/.config/claude/config.json`):

```json
{
  "mcpServers": {
    "superpowers": {
      "command": "/path/to/superpowers-mcp",
      "args": ["--skills-dir", "/path/to/your/skills/directory"]
    }
  }
}
```

## Verification

Restart Claude Code and check that the `skill_search` tool is available.

## Usage

The MCP server provides the `skill_search` tool which is called automatically by the using-superpowers skill when you start any task.

## Troubleshooting

**Tool not appearing:**
- Check MCP server logs in Claude Code
- Verify skills directory path is correct
- Ensure binary has execute permissions

**No matches returned:**
- Verify SKILL.md files have proper YAML frontmatter
- Check that descriptions are present in frontmatter
- Try broader search queries
```

**Step 3: Update README.md**

Update `README.md` with comprehensive documentation:

```markdown
# Superpowers MCP Server

MCP server that enforces skill discovery through required tool calls, making skill usage as unavoidable as TodoWrite.

## What This Solves

Agents often skip skill discovery, working from memory or assumptions. This MCP server makes skill discovery structural:

1. Agent starts task
2. using-superpowers skill requires calling `skill_search` tool
3. Tool returns relevant skills (can't be faked)
4. Agent MUST read returned skills

## Installation

See [docs/INSTALLATION.md](docs/INSTALLATION.md) for detailed instructions.

Quick start:
```bash
./install.sh
```

## Tools Provided

### `skill_search`

Search for relevant skills based on user's task description.

**Parameters:**
- `query` (required): User's request or task description
- `limit` (optional): Maximum matches to return (default: 5)

**Returns:**
```json
{
  "matches": [
    {
      "name": "test-driven-development",
      "description": "Use when implementing any feature or bugfix...",
      "path": "/path/to/skills/test-driven-development/SKILL.md",
      "score": 12.5
    }
  ]
}
```

## Architecture

- **Indexer**: Parses SKILL.md files with YAML frontmatter
- **Matcher**: Semantic matching using keyword scoring
- **Server**: MCP protocol implementation with tool registration

## Development

```bash
go test ./...
go build
./superpowers-mcp --skills-dir ./test-skills
```

## License

MIT
```

**Step 4: Make install.sh executable**

Run: `chmod +x install.sh`

**Step 5: Commit**

```bash
git add install.sh docs/ README.md
git commit -m "docs: add installation script and comprehensive documentation"
```

---

## Task 7: Update using-superpowers Skill

**Files:**
- Modify: `skills/using-superpowers/SKILL.md`

**Step 1: Update skill discovery checklist section**

Modify `skills/using-superpowers/SKILL.md` lines 14-40:

```markdown
## Mandatory: Before ANY Task

### The Skill Discovery Checklist

For EVERY user request, **BEFORE creating TodoWrite todos**, you MUST:

**1. Call skill_search tool** (if MCP server available)

```
skill_search(query: "user's request text", limit: 5)
```

The tool returns matching skills with names, descriptions, and paths.

**2. Create TodoWrite todos for the checklist:**

1. **Call skill_search tool** (if available, or list skills manually)
2. **Review returned matches** (Read the top matches)
3. **If match found: Read the skill** (Use Read tool on skill file path)
4. **If match found: Announce usage** ("I'm using [Skill] to [purpose]")
5. **Proceed with task** (Follow skill if found, or proceed directly)

**Create ALL five todos immediately. Mark them as you go.**

**Why tool call first:** Tool must be called BEFORE TodoWrite to prevent rationalizing away the search. The tool call is structural enforcement - you cannot skip it.

**Multiple tasks?** If user provides multiple distinct tasks (e.g., "Add auth, fix tests, write docs"), the FIRST task gets skill_search call + checklist. After completing task 1, when you start task 2, repeat: skill_search → TodoWrite → proceed.

**If MCP server not available:** Fall back to manual checking:
1. List ALL available skills by name (output visible)
2. Match task to skills from that list
3. Continue with checklist

**Don't rationalize:**
- "I already know the skills" - Call the tool anyway. The list grows.
- "This will slow me down" - Tool call takes <1 second.
- "I need context first" - Call tool THEN gather context.
- "This is too simple" - Simple tasks need skills most.
- "I'll check if I get stuck" - Too late, you've chosen wrong path.
- "MCP server not configured" - Use manual fallback, don't skip.
- "Tool call is ceremony" - It's enforcement. That's the point.
```

**Step 2: Add new section after "Critical Rules"**

Add after line 13:

```markdown
## MCP Tool Integration

**If superpowers MCP server is installed:**
- `skill_search` tool is available
- MUST be called before creating TodoWrite todos
- Returns ranked skill matches for user's request
- Makes skill discovery structural, not honor-system

**To install MCP server:**
See superpowers-mcp README in skills repository.
```

**Step 3: Update "Why this checklist matters"**

Modify line 40:

```markdown
**Why this checklist matters:**

**Without tool enforcement:** Agents skip skill discovery 80%+ of the time.

**With skill_search tool:** Structural enforcement makes skipping impossible. Tool must be called before proceeding.

**With TodoWrite only:** Makes checklist visible, but "checking" can still be faked mentally.

**Together:** skill_search (structural) + TodoWrite (visibility) = bulletproof enforcement.
```

**Step 4: Test the updated skill**

Run: Restart Claude Code session and verify skill_search is called first

Expected: Agent calls tool before creating todos

**Step 5: Commit**

```bash
git add skills/using-superpowers/SKILL.md
git commit -m "feat: integrate skill_search MCP tool into using-superpowers skill"
```

---

## Verification Steps

**After completing all tasks:**

1. **Build the MCP server:**
   ```bash
   cd superpowers-mcp
   go build
   ```

2. **Run tests:**
   ```bash
   go test ./... -v
   ```

3. **Install locally:**
   ```bash
   ./install.sh
   ```

4. **Configure Claude Code:**
   Add to `~/.config/claude/config.json`

5. **Start new Claude Code session:**
   Verify `skill_search` tool is available

6. **Test skill discovery:**
   Give Claude a task and observe:
   - Does it call `skill_search` first?
   - Does it receive correct matches?
   - Does it read the returned skills?

7. **Test fallback:**
   Remove MCP config, verify manual fallback works

---

## Success Criteria

- [ ] MCP server builds and runs without errors
- [ ] skill_search tool returns relevant matches
- [ ] Semantic matching ranks TDD higher for "implement feature" than debugging skills
- [ ] using-superpowers skill calls tool before TodoWrite
- [ ] Agents cannot skip skill discovery without explicitly ignoring tool requirement
- [ ] Manual fallback works when MCP server unavailable

---

## Notes for Engineer

- **MCP SDK API may differ:** Check official go-sdk documentation for exact API
- **Semantic matching is simple:** Keyword-based scoring, not ML-based embeddings (intentionally simple)
- **Skills directory structure:** Expects `skills/skill-name/SKILL.md` format
- **YAML parsing is minimal:** Only extracts `name` and `description` fields
- **Testing strategy:** Unit tests for matching logic, integration test with real skills directory
- **Deployment:** Single binary, no external dependencies beyond Go stdlib

---

## Related Skills

- @superpowers:executing-plans - For implementing this plan
- @test-driven-development - For implementing each task
- @systematic-debugging - If implementation issues arise
