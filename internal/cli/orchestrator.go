package cli

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/etapsc/bridge/internal/pack"
	"github.com/spf13/cobra"
)

func orchestratorCmd() *cobra.Command {
	var orchType, platform, target, name, repo, version string

	cmd := &cobra.Command{
		Use:   "orchestrator",
		Short: "Install controller or multi-repo orchestrator",
		Long:  "Install BRIDGE Controller (portfolio management) or Multi-Repo (cross-repo coding) orchestrator packs.",
		RunE: func(cmd *cobra.Command, args []string) error {
			if orchType == "" {
				return fmt.Errorf("--type is required (controller, multi-repo, both)")
			}

			absTarget, err := filepath.Abs(target)
			if err != nil {
				return err
			}

			switch orchType {
			case "controller":
				return installController(absTarget, name, repo, version)
			case "multi-repo":
				return installMultiRepo(absTarget, name, platform, repo, version)
			case "both":
				if err := installController(absTarget, name, repo, version); err != nil {
					return err
				}
				return installMultiRepo(absTarget, name, platform, repo, version)
			default:
				return fmt.Errorf("invalid type %q: must be controller, multi-repo, or both", orchType)
			}
		},
	}

	cmd.Flags().StringVar(&orchType, "type", "", "Orchestrator type: controller, multi-repo, both")
	cmd.Flags().StringVar(&platform, "platform", "claude-code", "Platform for multi-repo: claude-code, codex")
	cmd.Flags().StringVarP(&target, "target", "t", ".", "Target directory")
	cmd.Flags().StringVarP(&name, "name", "n", "My Projects", "Portfolio/workspace name")
	cmd.Flags().StringVarP(&repo, "repo", "r", "etapsc/bridge", "GitHub repo for remote download")
	cmd.Flags().StringVarP(&version, "version", "v", "latest", "Release tag for remote download")

	return cmd
}

func installController(targetDir, name, repo, version string) error {
	fmt.Println("Installing BRIDGE Controller...")
	fmt.Printf("  Target: %s\n", targetDir)

	execDir := executableDir()
	src := pack.Resolve(execDir, "controller", repo, version)

	if err := os.MkdirAll(targetDir, 0755); err != nil {
		return err
	}

	if err := pack.Extract(src, targetDir); err != nil {
		return fmt.Errorf("failed to extract controller pack: %w", err)
	}

	if err := pack.ReplacePlaceholders(targetDir, name); err != nil {
		return fmt.Errorf("failed to replace placeholders: %w", err)
	}

	fmt.Println("  Controller installed.")
	fmt.Printf("\n  Next: cd %s && claude && /bridge-status\n\n", targetDir)
	return nil
}

func installMultiRepo(targetDir, name, platform, repo, version string) error {
	if platform != "claude-code" && platform != "codex" {
		return fmt.Errorf("invalid platform %q: must be claude-code or codex", platform)
	}

	orchDir := filepath.Join(targetDir, "bridge-orchestrator")
	fmt.Printf("Installing BRIDGE Multi-Repo (%s)...\n", platform)
	fmt.Printf("  Target: %s\n", orchDir)

	if err := os.MkdirAll(orchDir, 0755); err != nil {
		return err
	}

	execDir := executableDir()

	// Try pre-merged archive first, then merge manually
	archiveName := fmt.Sprintf("multi-repo-%s", platform)
	src := pack.Resolve(execDir, archiveName, repo, version)

	if src.Mode == SourceModeRemote(src) {
		// Fallback: merge base pack + overlay
		basePack := platform
		if platform == "claude-code" {
			basePack = "claude-code"
		} else {
			basePack = "codex"
		}
		baseSrc := pack.Resolve(execDir, basePack, repo, version)
		if err := pack.Extract(baseSrc, orchDir); err != nil {
			return fmt.Errorf("failed to extract base pack: %w", err)
		}
		// Overlay multi-repo specific files
		multiSrc := pack.Resolve(execDir, "multi-repo", repo, version)
		if multiSrc.Mode == pack.SourceFolder {
			overlayDir := filepath.Join(multiSrc.Path, platform)
			if _, err := os.Stat(overlayDir); err == nil {
				pack.Extract(pack.Source{Mode: pack.SourceFolder, Path: overlayDir}, orchDir)
			}
		}
	} else {
		if err := pack.Extract(src, orchDir); err != nil {
			return fmt.Errorf("failed to extract multi-repo pack: %w", err)
		}
	}

	if err := pack.ReplacePlaceholders(orchDir, name); err != nil {
		return fmt.Errorf("failed to replace placeholders: %w", err)
	}

	fmt.Println("  Multi-repo installed.")
	if platform == "claude-code" {
		fmt.Printf("\n  Next: cd %s && claude && /bridge-repo-status\n\n", orchDir)
	} else {
		fmt.Printf("\n  Next: cd %s && codex && $bridge-repo-status\n\n", orchDir)
	}
	return nil
}

// SourceModeRemote checks if source resolved to remote (no local found).
func SourceModeRemote(src pack.Source) pack.SourceMode {
	return pack.SourceRemote
}
