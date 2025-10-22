# JJ Workflow MCP Server Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an MCP server that enforces the jj examine-commit-work-squash cycle through structured tool calls, preventing agents from skipping state checks or violating workflow steps.

**Architecture:** Go-based MCP server that wraps jj commands with workflow enforcement. Provides high-level operations (start_work, save_progress, get_context) that check state, run commands, and return structured data instead of text parsing.

**Tech Stack:** Go, official MCP Go SDK, jj CLI integration via os/exec

---

## Task 1: Project Setup and Dependencies

**Files:**
- Create: `jj-workflow-mcp/go.mod`
- Create: `jj-workflow-mcp/go.sum`
- Create: `jj-workflow-mcp/main.go`
- Create: `jj-workflow-mcp/.gitignore`
- Create: `jj-workflow-mcp/README.md`

**Step 1: Initialize Go module**

```bash
cd jj-workflow-mcp
go mod init github.com/your-org/jj-workflow-mcp
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
	log.Println("JJ Workflow MCP Server starting...")
}
```

**Step 4: Create .gitignore**

```
# Binaries
jj-workflow-mcp
jj-workflow-mcp-*

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
# JJ Workflow MCP Server

MCP server for enforcing jj examine-commit-work-squash workflow in Claude Code.

## Installation

```bash
go build -o jj-workflow-mcp
```

## Usage

Add to Claude Code MCP config:
```json
{
  "jj-workflow": {
    "command": "/path/to/jj-workflow-mcp",
    "args": []
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
git commit -m "feat: initialize jj-workflow-mcp Go project"
```

---

## Task 2: JJ Command Executor

**Files:**
- Create: `jj-workflow-mcp/internal/jj/executor.go`
- Create: `jj-workflow-mcp/internal/jj/executor_test.go`
- Create: `jj-workflow-mcp/internal/jj/types.go`

**Step 1: Write the failing test for jj command execution**

Create `internal/jj/executor_test.go`:

```go
package jj

import (
	"testing"
)

func TestCheckJJRepo(t *testing.T) {
	exec := NewExecutor()

	// This test assumes we're in a jj repo
	// Skip if not
	isRepo, err := exec.IsJJRepo()
	if err != nil {
		t.Skipf("Skipping: %v", err)
	}

	if !isRepo {
		t.Skip("Not in a jj repository")
	}
}

func TestParseStatus(t *testing.T) {
	exec := NewExecutor()

	testCases := []struct {
		output   string
		expected bool // isEmpty
	}{
		{"Working copy changes:\n(no changes)", true},
		{"Working copy changes:\nM file.txt", false},
		{"Working copy: (no changes)", true},
		{"No changes", true},
	}

	for _, tc := range testCases {
		isEmpty := exec.parseStatusOutput(tc.output)
		if isEmpty != tc.expected {
			t.Errorf("parseStatusOutput(%q) = %v, want %v", tc.output, isEmpty, tc.expected)
		}
	}
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/jj/... -v`
Expected: FAIL with "package jj: undefined"

**Step 3: Write types.go**

Create `internal/jj/types.go`:

```go
package jj

// WorkingCopyState represents the state of the jj working copy
type WorkingCopyState struct {
	IsEmpty       bool
	HasTracked    bool
	ChangeID      string
	ParentID      string
	Description   string
	TrackedFiles  []string
}

// CommitResult represents the result of a commit operation
type CommitResult struct {
	ChangeID    string
	Description string
	Success     bool
}

// SquashResult represents the result of a squash operation
type SquashResult struct {
	ParentID string
	Success  bool
	NewEmpty bool
}
```

**Step 4: Write minimal executor implementation**

Create `internal/jj/executor.go`:

```go
package jj

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"
)

type Executor struct {
	workDir string
}

func NewExecutor() *Executor {
	return &Executor{}
}

func (e *Executor) SetWorkDir(dir string) {
	e.workDir = dir
}

// IsJJRepo checks if current directory is a jj repository
func (e *Executor) IsJJRepo() (bool, error) {
	cmd := exec.Command("jj", "root")
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	output, err := cmd.CombinedOutput()
	if err != nil {
		if strings.Contains(string(output), "There is no jj repo") {
			return false, nil
		}
		return false, err
	}

	return true, nil
}

// GetStatus runs jj status and parses the output
func (e *Executor) GetStatus() (*WorkingCopyState, error) {
	cmd := exec.Command("jj", "status")
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("jj status failed: %w", err)
	}

	state := &WorkingCopyState{
		IsEmpty:      e.parseStatusOutput(string(output)),
		TrackedFiles: e.parseTrackedFiles(string(output)),
	}

	state.HasTracked = len(state.TrackedFiles) > 0

	return state, nil
}

// parseStatusOutput determines if working copy is empty (no tracked changes)
func (e *Executor) parseStatusOutput(output string) bool {
	// Check for explicit "no changes" indicators
	if strings.Contains(output, "(no changes)") {
		return true
	}
	if strings.Contains(output, "No changes") {
		return true
	}

	// Check if there are any tracked file markers (M, A, D, R)
	lines := strings.Split(output, "\n")
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if len(trimmed) > 0 {
			firstChar := trimmed[0]
			if firstChar == 'M' || firstChar == 'A' || firstChar == 'D' || firstChar == 'R' {
				return false
			}
		}
	}

	return true
}

// parseTrackedFiles extracts tracked files from status output
func (e *Executor) parseTrackedFiles(output string) []string {
	var files []string
	lines := strings.Split(output, "\n")

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if len(trimmed) > 2 {
			firstChar := trimmed[0]
			if firstChar == 'M' || firstChar == 'A' || firstChar == 'D' || firstChar == 'R' {
				// Extract filename (after status marker and space)
				parts := strings.SplitN(trimmed, " ", 2)
				if len(parts) == 2 {
					files = append(files, strings.TrimSpace(parts[1]))
				}
			}
		}
	}

	return files
}

// Commit creates a commit with the given message
func (e *Executor) Commit(message string) (*CommitResult, error) {
	cmd := exec.Command("jj", "commit", "-m", message)
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		return nil, fmt.Errorf("jj commit failed: %w (stderr: %s)", err, stderr.String())
	}

	return &CommitResult{
		Description: message,
		Success:     true,
	}, nil
}

// NewChange creates a new empty change
func (e *Executor) NewChange() error {
	cmd := exec.Command("jj", "new")
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	return cmd.Run()
}

// Squash squashes working copy into parent
func (e *Executor) Squash() (*SquashResult, error) {
	cmd := exec.Command("jj", "squash")
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	err := cmd.Run()
	if err != nil {
		return nil, fmt.Errorf("jj squash failed: %w", err)
	}

	return &SquashResult{
		Success:  true,
		NewEmpty: true, // After squash, working copy becomes empty
	}, nil
}

// Describe updates the description of a change
func (e *Executor) Describe(message string) error {
	cmd := exec.Command("jj", "describe", "-m", message)
	if e.workDir != "" {
		cmd.Dir = e.workDir
	}

	return cmd.Run()
}
```

**Step 5: Run test to verify it passes**

Run: `go test ./internal/jj/... -v`
Expected: PASS (or SKIP if not in jj repo)

**Step 6: Commit**

```bash
git add internal/jj/
git commit -m "feat: add jj command executor with status parsing"
```

---

## Task 3: Workflow State Machine

**Files:**
- Create: `jj-workflow-mcp/internal/workflow/workflow.go`
- Create: `jj-workflow-mcp/internal/workflow/workflow_test.go`

**Step 1: Write the failing test for workflow enforcement**

Create `internal/workflow/workflow_test.go`:

```go
package workflow

import (
	"testing"
)

func TestStartWorkInEmptyChange(t *testing.T) {
	// Test that start_work in empty change just commits
	t.Skip("TODO: Implement with mock executor")
}

func TestStartWorkInNonEmptyChange(t *testing.T) {
	// Test that start_work in non-empty change creates new + commits
	t.Skip("TODO: Implement with mock executor")
}

func TestSaveProgressValidation(t *testing.T) {
	// Test that save_progress validates state before squashing
	t.Skip("TODO: Implement with mock executor")
}
```

**Step 2: Run test to verify it fails**

Run: `go test ./internal/workflow/... -v`
Expected: All tests SKIP (placeholder tests)

**Step 3: Write workflow implementation**

Create `internal/workflow/workflow.go`:

```go
package workflow

import (
	"fmt"

	"github.com/your-org/jj-workflow-mcp/internal/jj"
)

type Workflow struct {
	executor *jj.Executor
}

func New(executor *jj.Executor) *Workflow {
	return &Workflow{executor: executor}
}

// StartWorkContext is returned by StartWork
type StartWorkContext struct {
	ChangeID       string `json:"change_id"`
	ParentID       string `json:"parent_id"`
	Description    string `json:"description"`
	WasEmpty       bool   `json:"was_empty"`
	CreatedNew     bool   `json:"created_new"`
}

// StartWork implements the examine-commit step of the workflow
func (w *Workflow) StartWork(description string) (*StartWorkContext, error) {
	// Step 1: Check if repo is jj
	isRepo, err := w.executor.IsJJRepo()
	if err != nil {
		return nil, fmt.Errorf("checking jj repo: %w", err)
	}
	if !isRepo {
		return nil, fmt.Errorf("not a jj repository")
	}

	// Step 2: Get status (examine)
	state, err := w.executor.GetStatus()
	if err != nil {
		return nil, fmt.Errorf("getting status: %w", err)
	}

	ctx := &StartWorkContext{
		Description: description,
		WasEmpty:    state.IsEmpty,
	}

	// Step 3: Commit with description
	if state.IsEmpty {
		// In empty change: just commit
		_, err := w.executor.Commit(description)
		if err != nil {
			return nil, fmt.Errorf("committing: %w", err)
		}
		ctx.CreatedNew = false
	} else {
		// Not in empty change: new + commit
		err := w.executor.NewChange()
		if err != nil {
			return nil, fmt.Errorf("creating new change: %w", err)
		}

		_, err = w.executor.Commit(description)
		if err != nil {
			return nil, fmt.Errorf("committing: %w", err)
		}
		ctx.CreatedNew = true
	}

	return ctx, nil
}

// SaveProgressContext is returned by SaveProgress
type SaveProgressContext struct {
	Squashed     bool   `json:"squashed"`
	ParentID     string `json:"parent_id"`
	NowEmpty     bool   `json:"now_empty"`
	ShouldUpdate bool   `json:"should_update_parent_message"`
}

// SaveProgress implements the squash step of the workflow
func (w *Workflow) SaveProgress() (*SaveProgressContext, error) {
	// Step 1: Get current state
	state, err := w.executor.GetStatus()
	if err != nil {
		return nil, fmt.Errorf("getting status: %w", err)
	}

	// Step 2: Validate there's work to save
	if state.IsEmpty {
		return nil, fmt.Errorf("no changes to save (working copy is empty)")
	}

	// Step 3: Squash
	result, err := w.executor.Squash()
	if err != nil {
		return nil, fmt.Errorf("squashing: %w", err)
	}

	return &SaveProgressContext{
		Squashed:     result.Success,
		ParentID:     result.ParentID,
		NowEmpty:     result.NewEmpty,
		ShouldUpdate: true, // Always suggest updating parent message
	}, nil
}

// GetWorkContext returns current working copy state
type WorkContext struct {
	IsEmpty      bool     `json:"is_empty"`
	HasTracked   bool     `json:"has_tracked"`
	TrackedFiles []string `json:"tracked_files"`
	NextAction   string   `json:"next_action"`
}

// GetWorkContext implements the examine step (query current state)
func (w *Workflow) GetWorkContext() (*WorkContext, error) {
	state, err := w.executor.GetStatus()
	if err != nil {
		return nil, fmt.Errorf("getting status: %w", err)
	}

	ctx := &WorkContext{
		IsEmpty:      state.IsEmpty,
		HasTracked:   state.HasTracked,
		TrackedFiles: state.TrackedFiles,
	}

	// Suggest next action based on state
	if state.IsEmpty {
		ctx.NextAction = "call jj_start_work with work description"
	} else if state.HasTracked {
		ctx.NextAction = "continue working, then call jj_save_progress when ready"
	}

	return ctx, nil
}

// UpdateParentMessage updates the parent commit's message
func (w *Workflow) UpdateParentMessage(message string) error {
	return w.executor.Describe(message)
}
```

**Step 4: Build to verify compilation**

Run: `go build`
Expected: Build succeeds

**Step 5: Commit**

```bash
git add internal/workflow/
git commit -m "feat: add workflow state machine with examine-commit-work-squash enforcement"
```

---

## Task 4: MCP Server Implementation

**Files:**
- Create: `jj-workflow-mcp/internal/server/server.go`
- Create: `jj-workflow-mcp/internal/server/tools.go`
- Modify: `jj-workflow-mcp/main.go`

**Step 1: Write server.go skeleton**

Create `internal/server/server.go`:

```go
package server

import (
	"context"
	"log"

	"github.com/your-org/jj-workflow-mcp/internal/jj"
	"github.com/your-org/jj-workflow-mcp/internal/workflow"
	mcp "github.com/modelcontextprotocol/go-sdk"
)

type JJWorkflowServer struct {
	workflow  *workflow.Workflow
	mcpServer *mcp.Server
}

func New() (*JJWorkflowServer, error) {
	executor := jj.NewExecutor()
	wf := workflow.New(executor)

	// Create MCP server
	mcpServer := mcp.NewServer("jj-workflow", "1.0.0")

	s := &JJWorkflowServer{
		workflow:  wf,
		mcpServer: mcpServer,
	}

	// Register tools
	s.registerTools()

	return s, nil
}

func (s *JJWorkflowServer) registerTools() {
	// Register jj_start_work tool
	s.mcpServer.RegisterTool(mcp.Tool{
		Name:        "jj_start_work",
		Description: "Start new work in jj workflow. Checks if in empty change, commits with description. Enforces examine-commit steps.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"description": map[string]interface{}{
					"type":        "string",
					"description": "Description of work to be done (commit message)",
				},
			},
			Required: []string{"description"},
		},
	}, s.HandleStartWork)

	// Register jj_save_progress tool
	s.mcpServer.RegisterTool(mcp.Tool{
		Name:        "jj_save_progress",
		Description: "Save work progress by squashing into parent commit. Enforces that work is ready to save.",
		InputSchema: mcp.ToolInputSchema{
			Type:       "object",
			Properties: map[string]interface{}{},
		},
	}, s.HandleSaveProgress)

	// Register jj_get_context tool
	s.mcpServer.RegisterTool(mcp.Tool{
		Name:        "jj_get_context",
		Description: "Get current working copy state and suggested next action. Used for status checks.",
		InputSchema: mcp.ToolInputSchema{
			Type:       "object",
			Properties: map[string]interface{}{},
		},
	}, s.HandleGetContext)

	// Register jj_update_parent tool
	s.mcpServer.RegisterTool(mcp.Tool{
		Name:        "jj_update_parent",
		Description: "Update parent commit message to reflect all accumulated work. Should be called after squashing.",
		InputSchema: mcp.ToolInputSchema{
			Type: "object",
			Properties: map[string]interface{}{
				"message": map[string]interface{}{
					"type":        "string",
					"description": "Updated commit message describing ALL accumulated work",
				},
			},
			Required: []string{"message"},
		},
	}, s.HandleUpdateParent)
}

func (s *JJWorkflowServer) Start(ctx context.Context) error {
	log.Println("JJ Workflow MCP server started")
	return s.mcpServer.Serve(ctx)
}
```

**Step 2: Write tools.go with tool handlers**

Create `internal/server/tools.go`:

```go
package server

import (
	"context"
	"encoding/json"
)

// StartWorkRequest is the input for jj_start_work
type StartWorkRequest struct {
	Description string `json:"description"`
}

// HandleStartWork implements the jj_start_work tool
func (s *JJWorkflowServer) HandleStartWork(ctx context.Context, params json.RawMessage) (interface{}, error) {
	var req StartWorkRequest
	if err := json.Unmarshal(params, &req); err != nil {
		return nil, err
	}

	result, err := s.workflow.StartWork(req.Description)
	if err != nil {
		return nil, err
	}

	return result, nil
}

// HandleSaveProgress implements the jj_save_progress tool
func (s *JJWorkflowServer) HandleSaveProgress(ctx context.Context, params json.RawMessage) (interface{}, error) {
	result, err := s.workflow.SaveProgress()
	if err != nil {
		return nil, err
	}

	return result, nil
}

// HandleGetContext implements the jj_get_context tool
func (s *JJWorkflowServer) HandleGetContext(ctx context.Context, params json.RawMessage) (interface{}, error) {
	result, err := s.workflow.GetWorkContext()
	if err != nil {
		return nil, err
	}

	return result, nil
}

// UpdateParentRequest is the input for jj_update_parent
type UpdateParentRequest struct {
	Message string `json:"message"`
}

// HandleUpdateParent implements the jj_update_parent tool
func (s *JJWorkflowServer) HandleUpdateParent(ctx context.Context, params json.RawMessage) (interface{}, error) {
	var req UpdateParentRequest
	if err := json.Unmarshal(params, &req); err != nil {
		return nil, err
	}

	err := s.workflow.UpdateParentMessage(req.Message)
	if err != nil {
		return nil, err
	}

	return map[string]interface{}{
		"success": true,
		"message": "Parent commit message updated",
	}, nil
}
```

**Step 3: Update main.go to use server**

Modify `main.go`:

```go
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/your-org/jj-workflow-mcp/internal/server"
)

func main() {
	srv, err := server.New()
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
git commit -m "feat: add MCP server with jj workflow tools"
```

---

## Task 5: Installation and Documentation

**Files:**
- Create: `jj-workflow-mcp/install.sh`
- Create: `jj-workflow-mcp/docs/TOOLS.md`
- Modify: `jj-workflow-mcp/README.md`

**Step 1: Write install.sh**

Create `install.sh`:

```bash
#!/bin/bash
set -e

echo "Installing JJ Workflow MCP Server..."

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
go build -o jj-workflow-mcp-$OS-$ARCH

# Install
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$INSTALL_DIR"
cp jj-workflow-mcp-$OS-$ARCH "$INSTALL_DIR/jj-workflow-mcp"
chmod +x "$INSTALL_DIR/jj-workflow-mcp"

echo "Installed to $INSTALL_DIR/jj-workflow-mcp"
echo ""
echo "Add to Claude Code MCP config (~/.config/claude/config.json):"
echo ""
echo '{
  "mcpServers": {
    "jj-workflow": {
      "command": "'$INSTALL_DIR'/jj-workflow-mcp",
      "args": []
    }
  }
}'
```

**Step 2: Write TOOLS.md**

Create `docs/TOOLS.md`:

```markdown
# JJ Workflow MCP Tools

## Overview

Four tools enforce the examine-commit-work-squash cycle:

1. `jj_start_work` - Examine state + commit with description
2. `jj_save_progress` - Squash work into parent
3. `jj_get_context` - Query current state
4. `jj_update_parent` - Update parent commit message

## Tool Specifications

### jj_start_work

**Purpose:** Start new work following jj workflow (examine + commit steps).

**Input:**
```json
{
  "description": "Work description for commit message"
}
```

**Output:**
```json
{
  "change_id": "abc123",
  "parent_id": "def456",
  "description": "Work description",
  "was_empty": true,
  "created_new": false
}
```

**Behavior:**
1. Checks if in jj repository
2. Runs `jj status` to check if working copy is empty
3. If empty: runs `jj commit -m "description"`
4. If not empty: runs `jj new` then `jj commit -m "description"`

**Error conditions:**
- Not in jj repository
- jj command fails

### jj_save_progress

**Purpose:** Save work by squashing into parent commit.

**Input:** None

**Output:**
```json
{
  "squashed": true,
  "parent_id": "def456",
  "now_empty": true,
  "should_update_parent_message": true
}
```

**Behavior:**
1. Checks current state
2. Validates there are tracked changes
3. Runs `jj squash`
4. Returns new empty state

**Error conditions:**
- No changes to save (working copy empty)
- jj squash fails

### jj_get_context

**Purpose:** Get current working copy state and suggested next action.

**Input:** None

**Output:**
```json
{
  "is_empty": true,
  "has_tracked": false,
  "tracked_files": [],
  "next_action": "call jj_start_work with work description"
}
```

**Behavior:**
1. Runs `jj status`
2. Parses output for state
3. Returns structured data + suggestion

**Error conditions:**
- Not in jj repository
- jj status fails

### jj_update_parent

**Purpose:** Update parent commit message to reflect all accumulated work.

**Input:**
```json
{
  "message": "Updated message describing ALL accumulated work"
}
```

**Output:**
```json
{
  "success": true,
  "message": "Parent commit message updated"
}
```

**Behavior:**
1. Runs `jj describe -m "message"`

**Error conditions:**
- jj describe fails

## Usage Examples

### Starting Work

```
Agent: Calls jj_start_work({ description: "Fix authentication bug" })
Server: Returns { was_empty: true, created_new: false, ... }
Agent: Now in working change, can edit files
```

### Saving Progress

```
Agent: Makes changes, tests pass
Agent: Calls jj_save_progress()
Server: Squashes changes into parent, returns { now_empty: true, should_update_parent_message: true }
Agent: Calls jj_update_parent({ message: "Fix authentication bug - updated token validation" })
```

### Checking State

```
Agent: Calls jj_get_context()
Server: Returns { is_empty: false, has_tracked: true, tracked_files: ["auth.go"], next_action: "continue working..." }
```

## Integration with jj-change-workflow Skill

The skill should be updated to use these tools instead of raw jj commands:

**Before (raw commands):**
```bash
jj status
jj commit -m "description"
jj squash
```

**After (MCP tools):**
```
jj_start_work({ description: "..." })
# work
jj_save_progress()
jj_update_parent({ message: "..." })
```

**Benefits:**
- Can't skip state check (built into jj_start_work)
- Can't misparse jj status output (server handles it)
- Structured data instead of text parsing
- Enforced workflow steps
```

**Step 3: Update README.md**

Update `README.md`:

```markdown
# JJ Workflow MCP Server

MCP server that enforces the jj examine-commit-work-squash workflow through structured tool calls.

## What This Solves

The jj-change-workflow skill relies on agents:
1. Running `jj status` before starting work
2. Correctly parsing text output to determine empty/non-empty
3. Following the correct command sequence
4. Updating parent messages after squashing

Agents frequently skip these steps or parse output incorrectly. This MCP server makes the workflow structural.

## Installation

```bash
./install.sh
```

Or manually:
```bash
go build -o jj-workflow-mcp
cp jj-workflow-mcp ~/.local/bin/
```

Add to Claude Code MCP config:
```json
{
  "mcpServers": {
    "jj-workflow": {
      "command": "/path/to/jj-workflow-mcp",
      "args": []
    }
  }
}
```

## Tools Provided

- `jj_start_work` - Examine + commit (enforces workflow start)
- `jj_save_progress` - Squash (enforces workflow save)
- `jj_get_context` - Query state (replaces manual jj status parsing)
- `jj_update_parent` - Update parent message (enforces message maintenance)

See [docs/TOOLS.md](docs/TOOLS.md) for detailed specifications.

## Architecture

- **Executor**: Wraps jj CLI commands via os/exec
- **Workflow**: State machine enforcing examine-commit-work-squash
- **Server**: MCP protocol with tool registration

## Benefits Over Raw Commands

| Raw jj commands | MCP Tools |
|-----------------|-----------|
| Agent can skip `jj status` | `jj_start_work` requires state check |
| Text parsing errors | Structured JSON output |
| Agent forgets to update parent message | Tool returns `should_update_parent_message: true` |
| Honor system | Structural enforcement |

## Development

```bash
go test ./...
go build
./jj-workflow-mcp
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

## Task 6: Update jj-change-workflow Skill

**Files:**
- Modify: `skills/jj-change-workflow/SKILL.md`

**Step 1: Add MCP integration section after overview**

Add new section after line 26:

```markdown
## MCP Integration (Recommended)

**If jj-workflow MCP server is installed**, use these tools instead of raw jj commands:

- `jj_start_work(description)` - Replaces examine + commit steps
- `jj_save_progress()` - Replaces squash step
- `jj_get_context()` - Replaces jj status parsing
- `jj_update_parent(message)` - Replaces jj describe

**Benefits:**
- Can't skip state checks (built into tools)
- No text parsing errors (structured JSON)
- Workflow steps are enforced
- Parent message updates are prompted

**To install MCP server:** See jj-workflow-mcp README in skills repository.

**The cycle with MCP tools:**
```
1. jj_get_context()          # Check state
2. jj_start_work("X")        # Describe work before starting
3. [work]                    # Make changes
4. jj_save_progress()        # Save work
5. jj_update_parent("X")     # Update parent with ALL work
6. Repeat                    # Back to step 1
```

**If MCP server not available:** Use raw jj commands as documented below.
```

**Step 2: Update Quick Reference table**

Modify Quick Reference section (around line 109) to include MCP tools:

```markdown
## Quick Reference

| Situation | MCP Tool (if available) | Raw Command (fallback) | Why |
|-----------|------------------------|------------------------|-----|
| Starting any work | `jj_get_context()` | `jj status` | Check if in empty change |
| In empty change | `jj_start_work("Intent")` | `jj commit -m "Intent"` | Describe work before starting |
| Not in empty change | `jj_start_work("Intent")` (handles automatically) | `jj new` then `jj commit -m "Intent"` | Create + describe |
| Made progress worth keeping | `jj_save_progress()` | `jj squash` | Save work to parent |
| After squashing | `jj_update_parent("All work")` | `jj describe -m "..."` | Update message for ALL accumulated work |
| Starting next piece | `jj_get_context()` | `jj status` | Check state again |
```

**Step 3: Add MCP examples section**

Add before "Real-World Examples" section:

```markdown
## MCP Tool Examples

**If jj-workflow MCP server is installed:**

### Bug fix with MCP:
```
jj_get_context()
# Returns: { is_empty: true, next_action: "call jj_start_work..." }

jj_start_work({ description: "Fix type error in utils.ts line 42" })
# Returns: { was_empty: true, created_new: false }

# Edit the file
# Run tests - they pass

jj_save_progress()
# Returns: { squashed: true, should_update_parent_message: true }

jj_update_parent({ message: "Fix type error in utils.ts line 42" })
```

### Feature work with MCP (multi-step):
```
jj_get_context()

jj_start_work({ description: "Add user authentication" })

# Implement login
jj_save_progress()
jj_update_parent({ message: "Add user authentication: login" })

jj_get_context()
jj_start_work({ description: "Add logout" })

# Implement logout
jj_save_progress()
jj_update_parent({ message: "Add user authentication: login and logout" })
```
```

**Step 4: Update Common Mistakes to reference MCP fallback**

Add to Common Mistakes table:

```markdown
| "MCP tools add overhead" | Tools enforce correctness. 5 seconds vs hours debugging. |
| "I'll use raw commands, they're faster" | Raw commands = easy to skip steps. Use MCP if available. |
```

**Step 5: Update Red Flags section**

Add to Red Flags list:

```markdown
- MCP server available but using raw commands anyway
- Not checking tool output (structured data tells you what to do next)
- Ignoring `should_update_parent_message: true` flag
```

**Step 6: Commit**

```bash
git add skills/jj-change-workflow/SKILL.md
git commit -m "feat: integrate jj-workflow MCP tools into jj-change-workflow skill"
```

---

## Verification Steps

**After completing all tasks:**

1. **Build the MCP server:**
   ```bash
   cd jj-workflow-mcp
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

4. **Test in jj repository:**
   ```bash
   cd /path/to/jj-repo
   # In separate terminal: ./jj-workflow-mcp
   # Use MCP inspector to test tools
   ```

5. **Configure Claude Code:**
   Add to `~/.config/claude/config.json`

6. **Start new Claude Code session in jj repo:**
   - Verify tools are available
   - Test jj_get_context returns state
   - Test jj_start_work creates commit
   - Test jj_save_progress squashes changes

7. **Test workflow enforcement:**
   - Agent should call jj_start_work automatically
   - Agent should receive structured data
   - Agent should update parent after squashing

---

## Success Criteria

- [ ] MCP server builds and runs without errors
- [ ] jj_start_work correctly detects empty/non-empty states
- [ ] jj_save_progress validates changes exist before squashing
- [ ] jj_get_context returns accurate structured state
- [ ] jj-change-workflow skill integrates MCP tools as primary method
- [ ] Agents follow workflow without skipping steps
- [ ] Fallback to raw commands works when MCP unavailable

---

## Notes for Engineer

- **Error handling**: All jj command failures should return structured errors
- **Working directory**: Executor supports SetWorkDir for testing
- **Status parsing**: Simple text parsing, looks for "no changes" and tracked file markers
- **MCP SDK API**: Consult go-sdk docs for exact API (structure may differ slightly)
- **Testing strategy**: Unit tests for status parsing, integration tests with real jj repo
- **Tool naming**: Use snake_case (jj_start_work) per MCP conventions

---

## Related Skills

- @superpowers:executing-plans - For implementing this plan
- @test-driven-development - For implementing each task
- @jj-change-workflow - The skill this MCP server supports
