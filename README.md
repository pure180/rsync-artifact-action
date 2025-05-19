# Artifacts RSync GitHub Action

A lightweight composite-run action that **pushes** or **pulls** one or more folders between your workflow checkout and a persistent artifact directory on same server that hosts your self-hosted GitHub runner.:

```
$HOME/.artifacts/<target>/<folder>/
```

Typical use-case: keep build outputs or caches on a self-hosted runner to speed up subsequent jobs or deployments.

---

## Requirements

| Requirement                                                   | Why it matters                                                      |
| ------------------------------------------------------------- | ------------------------------------------------------------------- |
| **Linux self-hosted runner**                                  | The action relies on GNU core-utils, `bash`, and local disk access. |
| **`rsync`** (≥ 3.1)                                           | Fast, incremental folder sync.                                      |
| **`getopt`** (from `util-linux`)                              | Used by the shell script for strict flag parsing.                   |
| **Write access to `$HOME/.artifacts`** (or a custom base path) | Where the action stores the pushed folders.                         |

> **IMPORTANT**
>
> This action is intend to run on self hosted runners to avoid github artifact storage restrictions
>
> **Note** It will **not** work on GitHub-hosted runners or Windows/macOS without modifications.


---

## Inputs

| Input name | Required | Description                                                                                                                                                                            | Default           |
| ---------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------- |
| `mode`     | **yes**  | `push` to upload, `pull` to download                                                                                                                                                   | —                 |
| `target`   | **yes**  | Sub-directory under the base path that groups the artifacts (e.g. `my-repo`)                                                                                                           | —                 |
| `source`   | **yes**  | Comma-separated list of folders. <br>• For **push**: relative or absolute paths in the workspace. <br>• For **pull**: plain folder names (the action restores them into `./<folder>`). | —                 |
| `base`     | no       | Root artifact directory on the runner                                                                                                                                                  | `$HOME/.artifacts` |
| `delete`   | no       | `true` → add `--delete` to `rsync` (removes files in the destination that no longer exist in the source). Only meaningful for **push**.                                                | `false`           |

---

## Usage Examples

### 1 · Push build artifacts

```yaml
# .github/workflows/push-artifacts.yml
name: Push artifacts

jobs:
  push:
    runs-on: self-hosted    # must be the server that holds $HOME/.artifacts
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/artifacts-sync
        with:
          mode: push
          target: my-app
          source: build,node_modules
          delete: "true"    # keep remote copy pristine
```

### 2 · Pull artifacts in a follow-up job

```yaml
# .github/workflows/pull-artifacts.yml
name: Restore artifacts

jobs:
  pull:
    runs-on: self-hosted
    steps:
      - uses: actions/checkout@v4

      - uses: ./.github/actions/artifacts-sync
        with:
          mode: pull
          target: my-app
          source: build,node_modules
          # base: "/custom/path"   # uncomment if you changed the base dir
```

The action prints a compact `rsync` summary (files count, transferred bytes, speed-up) for each folder and exits with a non-zero status if any required argument is missing or the sync fails.

---

Happy syncing!

---

MIT License - 2025 Daniel Pfisterer <https://github.com/pure180>