package cli

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/etapsc/bridge/internal/config"
	"github.com/etapsc/bridge/internal/customize"
	"github.com/spf13/cobra"
)

func customizeCmd() *cobra.Command {
	var personality, target string
	var addSpecs, removeSpecs []string
	var list bool

	cmd := &cobra.Command{
		Use:   "customize",
		Short: "Modify personality or domain specializations",
		Long:  "Change project personality pack or add/remove domain specialization skills in an existing BRIDGE project.",
		RunE: func(cmd *cobra.Command, args []string) error {
			absTarget, err := filepath.Abs(target)
			if err != nil {
				return err
			}

			cfg, err := config.Load(absTarget)
			if err != nil {
				return fmt.Errorf("failed to load config: %w", err)
			}

			if list {
				fmt.Printf("Pack:            %s\n", cfg.Pack)
				fmt.Printf("Personality:     %s\n", cfg.Personality)
				if len(cfg.Specializations) > 0 {
					fmt.Printf("Specializations: %s\n", strings.Join(cfg.Specializations, ", "))
				} else {
					fmt.Printf("Specializations: (none)\n")
				}
				installed, _ := customize.ListInstalled(absTarget)
				if len(installed) > 0 {
					fmt.Printf("Installed specs: %s\n", strings.Join(installed, ", "))
				}
				return nil
			}

			changed := false

			// Apply personality
			if personality != "" {
				if !isValidPersonality(personality) {
					return fmt.Errorf("invalid personality %q: must be one of %v", personality, config.Personalities())
				}

				profilesDir, err := resolveDataDir("profiles")
				if err != nil {
					return fmt.Errorf("cannot find personality profiles: %w", err)
				}
				profile, err := customize.LoadProfile(profilesDir, personality)
				if err != nil {
					return err
				}

				patched, err := customize.ApplyPersonality(absTarget, profile)
				if err != nil {
					return err
				}

				cfg.Personality = personality
				changed = true

				if len(patched) > 0 {
					fmt.Printf("Personality set to %q — patched %d files:\n", personality, len(patched))
					for _, f := range patched {
						fmt.Printf("  * %s\n", f)
					}
				} else {
					fmt.Printf("Personality set to %q (no agent files found to patch)\n", personality)
				}
			}

			// Add specializations
			if len(addSpecs) > 0 {
				specsDir, err := resolveDataDir("specializations")
				if err != nil {
					return fmt.Errorf("cannot find specializations: %w", err)
				}
				for _, spec := range addSpecs {
					if err := customize.AddSpecialization(absTarget, specsDir, spec); err != nil {
						return fmt.Errorf("failed to add spec %q: %w", spec, err)
					}
					fmt.Printf("  + Added specialization: %s\n", spec)
					if !containsSpec(cfg.Specializations, spec) {
						cfg.Specializations = append(cfg.Specializations, spec)
					}
				}
				changed = true
			}

			// Remove specializations
			if len(removeSpecs) > 0 {
				for _, spec := range removeSpecs {
					if err := customize.RemoveSpecialization(absTarget, spec); err != nil {
						return fmt.Errorf("failed to remove spec %q: %w", spec, err)
					}
					fmt.Printf("  - Removed specialization: %s\n", spec)
					cfg.Specializations = removeSpec(cfg.Specializations, spec)
				}
				changed = true
			}

			if !changed {
				return fmt.Errorf("no action specified — use --personality, --add-spec, --remove-spec, or --list")
			}

			if err := cfg.Save(absTarget); err != nil {
				return fmt.Errorf("failed to save config: %w", err)
			}
			fmt.Println("\n.bridge.json updated.")

			return nil
		},
	}

	cmd.Flags().StringVar(&personality, "personality", "", "Set personality: strict, balanced, mentoring")
	cmd.Flags().StringSliceVar(&addSpecs, "add-spec", nil, "Add specializations: frontend, backend, api, data, infra, mobile, security")
	cmd.Flags().StringSliceVar(&removeSpecs, "remove-spec", nil, "Remove specializations")
	cmd.Flags().BoolVar(&list, "list", false, "List current personality and active specializations")
	cmd.Flags().StringVarP(&target, "target", "t", ".", "Target project directory")

	return cmd
}

func containsSpec(specs []string, spec string) bool {
	for _, s := range specs {
		if s == spec {
			return true
		}
	}
	return false
}

func removeSpec(specs []string, spec string) []string {
	var result []string
	for _, s := range specs {
		if s != spec {
			result = append(result, s)
		}
	}
	return result
}
