#!/usr/bin/env nu

# Install superpowers skills to Claude Code
# This script creates symlinks for skills and commands while preserving existing installations

def main [] {
    let skills_source = $env.HOME | path join "superpowers-skills" "skills"
    let commands_source = $env.HOME | path join "superpowers-skills" "commands"
    let claude_skills = $env.HOME | path join ".claude" "skills"
    let claude_commands = $env.HOME | path join ".claude" "commands"

    # Ensure source directory exists
    if not ($skills_source | path exists) {
        print $"Error: Skills source directory not found: ($skills_source)"
        exit 1
    }

    # Create target directories if they don't exist
    mkdir $claude_skills
    mkdir $claude_commands

    print "Installing superpowers skills..."
    print ""

    # Install skill directories
    print "Linking skill directories:"
    let skill_dirs = ls $skills_source
        | where type == dir
        | get name

    for skill_dir in $skill_dirs {
        let skill_name = $skill_dir | path basename
        let target = $claude_skills | path join $skill_name

        # Check if target already exists
        if ($target | path exists) {
            # Check if it's a symlink pointing to our source
            if ($target | path type) == "symlink" {
                let link_target = (readlink $target | str trim)
                if $link_target == $skill_dir {
                    print $"  ✓ ($skill_name) - already linked"
                    continue
                } else {
                    print $"  ↻ ($skill_name) - relinking from ($link_target) to ($skill_dir)"
                    rm $target
                }
            } else {
                print $"  ⚠ ($skill_name) - exists but is not a symlink, skipping"
                continue
            }
        }

        # Create the symlink
        try {
            ln -s $skill_dir $target
            print $"  + ($skill_name) - linked"
        } catch {
            print $"  ✗ ($skill_name) - failed to create symlink"
        }
    }

    print ""

    # Install command files from commands directory
    if ($commands_source | path exists) {
        print "Linking command files:"
        let command_files = ls $commands_source
            | where type == file
            | where name =~ '\.md$'
            | get name

        for command_file in $command_files {
            let command_basename = $command_file | path basename
            let command_name = $command_basename | str replace '.md' ''

            # Create both prefixed and unprefixed versions
            let versions = [
                {name: $command_name, filename: $command_basename},
                {name: $"superpowers:($command_name)", filename: $"superpowers:($command_name).md"}
            ]

            for version in $versions {
                let target = $claude_commands | path join $version.filename

                # Check if target already exists
                if ($target | path exists) {
                    # Check if it's a symlink pointing to our source
                    if ($target | path type) == "symlink" {
                        let link_target = (readlink $target | str trim)
                        if $link_target == $command_file {
                            print $"  ✓ ($version.name) - already linked"
                            continue
                        } else {
                            print $"  ↻ ($version.name) - relinking from ($link_target) to ($command_file)"
                            rm $target
                        }
                    } else {
                        print $"  ⚠ ($version.name) - exists but is not a symlink, skipping"
                        continue
                    }
                }

                # Create the symlink
                try {
                    ln -s $command_file $target
                    print $"  + ($version.name) - linked"
                } catch {
                    print $"  ✗ ($version.name) - failed to create symlink"
                }
            }
        }
    }

    print ""
    print "Installation complete!"
    print ""
    print "Next steps:"
    print "  1. Restart Claude Code to load the new skills and commands"
    print "  2. Try /superpowers:brainstorm to start using skills"
}
