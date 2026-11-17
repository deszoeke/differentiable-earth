#!/bin/bash
# Download the project's Julia packages on a LOGIN node (which has internet), without compiling
# (the head node's limits kill big compiles). Then compile on a compute node:
#     sbatch helpers/precompile_job.sh
#
# From the repository directory, once per architecture (x86_64 login node; repeat in an aarch64
# shell for the GH200 nodes):
#     helpers/instantiate_login.sh
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
source "$repo/helpers/arch_env.sh"

juliaup add 1.11 2>/dev/null || true          # no-op if already installed
(cd "$repo" && juliaup override set 1.11)     # plain `julia` = 1.11 inside the repo only

export JULIA_PKG_PRECOMPILE_AUTO=0            # download only; compile later in a Slurm job
for env in "$repo" "$repo/plots"; do
    echo "== instantiating $env"
    julia +1.11 --project="$env" -e 'using Pkg; Pkg.instantiate()'
done
echo "done. Now compile on a compute node:  sbatch helpers/precompile_job.sh"
