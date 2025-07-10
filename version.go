package main

import (
	"fmt"
	"runtime"
)

var (
	// Version information
	Version   = "1.0.0"
	BuildDate = "unknown"
	GitCommit = "unknown"
	GitBranch = "unknown"
)

// GetVersionInfo returns version information
func GetVersionInfo() string {
	return fmt.Sprintf(`🎭 Chaos Monkey v%s
Build Date: %s
Git Commit: %s
Git Branch: %s
Go Version: %s
OS/Arch: %s/%s
`, Version, BuildDate, GitCommit, GitBranch, runtime.Version(), runtime.GOOS, runtime.GOARCH)
}

// PrintVersion prints version information
func PrintVersion() {
	fmt.Println(GetVersionInfo())
} 