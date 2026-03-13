package cli

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

func packCmd() *cobra.Command {
	var sourceDir string

	cmd := &cobra.Command{
		Use:   "pack",
		Short: "Build release tar.gz archives (maintainer tool)",
		Long:  "Rebuild all distributable pack archives from source folders. Equivalent to the legacy package.sh script.",
		RunE: func(cmd *cobra.Command, args []string) error {
			absDir, err := filepath.Abs(sourceDir)
			if err != nil {
				return err
			}

			// Simple packs
			simplePacks := []string{
				"bridge-full", "bridge-standalone", "bridge-claude-code",
				"bridge-codex", "bridge-opencode", "bridge-controller",
			}

			for _, p := range simplePacks {
				packDir := filepath.Join(absDir, p)
				if _, err := os.Stat(packDir); os.IsNotExist(err) {
					fmt.Printf("  Skipping %s (folder not found)\n", p)
					continue
				}
				archivePath := filepath.Join(absDir, p+".tar.gz")
				if err := createTarGz(packDir, archivePath); err != nil {
					return fmt.Errorf("failed to pack %s: %w", p, err)
				}
				fmt.Printf("  %s.tar.gz\n", p)
			}

			// Multi-repo: merge base + overlay
			multiRepoDir := filepath.Join(absDir, "bridge-multi-repo")
			if _, err := os.Stat(multiRepoDir); err == nil {
				for _, platform := range []string{"claude-code", "codex"} {
					overlayDir := filepath.Join(multiRepoDir, platform)
					if _, err := os.Stat(overlayDir); os.IsNotExist(err) {
						continue
					}

					var basePack string
					if platform == "claude-code" {
						basePack = "bridge-claude-code"
					} else {
						basePack = "bridge-codex"
					}

					baseDir := filepath.Join(absDir, basePack)
					if _, err := os.Stat(baseDir); os.IsNotExist(err) {
						fmt.Printf("  Skipping multi-repo-%s (base pack %s not found)\n", platform, basePack)
						continue
					}

					// Merge into temp dir
					tmpDir, err := os.MkdirTemp("", "bridge-merge-*")
					if err != nil {
						return err
					}

					// Copy base
					filepath.Walk(baseDir, func(path string, info os.FileInfo, err error) error {
						if err != nil {
							return err
						}
						rel, _ := filepath.Rel(baseDir, path)
						dest := filepath.Join(tmpDir, rel)
						if info.IsDir() {
							return os.MkdirAll(dest, 0755)
						}
						return copyFileForPack(path, dest, info.Mode())
					})

					// Copy overlay (overwrites base files)
					filepath.Walk(overlayDir, func(path string, info os.FileInfo, err error) error {
						if err != nil {
							return err
						}
						rel, _ := filepath.Rel(overlayDir, path)
						dest := filepath.Join(tmpDir, rel)
						if info.IsDir() {
							return os.MkdirAll(dest, 0755)
						}
						return copyFileForPack(path, dest, info.Mode())
					})

					archiveName := fmt.Sprintf("bridge-multi-repo-%s", platform)
					archivePath := filepath.Join(absDir, archiveName+".tar.gz")
					if err := createTarGz(tmpDir, archivePath); err != nil {
						os.RemoveAll(tmpDir)
						return fmt.Errorf("failed to pack %s: %w", archiveName, err)
					}
					os.RemoveAll(tmpDir)
					fmt.Printf("  %s.tar.gz\n", archiveName)
				}
			}

			// Dual-agent
			dualDir := filepath.Join(absDir, "bridge-dual-agent")
			if _, err := os.Stat(dualDir); err == nil {
				archivePath := filepath.Join(absDir, "bridge-dual-agent.tar.gz")
				if err := createTarGz(dualDir, archivePath); err != nil {
					return fmt.Errorf("failed to pack bridge-dual-agent: %w", err)
				}
				fmt.Printf("  bridge-dual-agent.tar.gz\n")
			}

			fmt.Println("\nDone. Archives ready for GitHub Release or local setup.")
			return nil
		},
	}

	cmd.Flags().StringVarP(&sourceDir, "dir", "d", ".", "Directory containing bridge-* source folders")

	return cmd
}

func createTarGz(srcDir, destPath string) error {
	f, err := os.Create(destPath)
	if err != nil {
		return err
	}
	defer f.Close()

	gw := gzip.NewWriter(f)
	defer gw.Close()

	tw := tar.NewWriter(gw)
	defer tw.Close()

	return filepath.Walk(srcDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		rel, err := filepath.Rel(srcDir, path)
		if err != nil {
			return err
		}
		if rel == "." {
			return nil
		}

		header, err := tar.FileInfoHeader(info, "")
		if err != nil {
			return err
		}
		header.Name = rel

		if err := tw.WriteHeader(header); err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		file, err := os.Open(path)
		if err != nil {
			return err
		}
		defer file.Close()

		_, err = io.Copy(tw, file)
		return err
	})
}

func copyFileForPack(src, dest string, mode os.FileMode) error {
	if err := os.MkdirAll(filepath.Dir(dest), 0755); err != nil {
		return err
	}
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.OpenFile(dest, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, mode)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}
