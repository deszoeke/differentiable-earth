#!/bin/bash
# Compile the project's Julia packages on a compute node, then run the package tests as a check.
# Run helpers/instantiate_login.sh on a login node first (downloads). From the repository:
#     sbatch helpers/precompile_job.sh                 # x86_64 CPU nodes (also used by the A100 nodes)
#     sbatch -p ceoas-arm helpers/precompile_job.sh    # aarch64 GH200 nodes (separate depot)
# Output: precompile-<jobid>.out in the repository. Expect "Test Summary: ... 20 pass" at the end.
#SBATCH --job-name=precompile
#SBATCH --partition=ceoas
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=2:00:00
#SBATCH --output=precompile-%j.out

set -euo pipefail
if [[ -z ${SLURM_JOB_ID:-} ]]; then
    echo "run as a Slurm job, from the repository directory: sbatch helpers/precompile_job.sh" >&2
    exit 1
fi
repo=$SLURM_SUBMIT_DIR
source "$repo/helpers/arch_env.sh"
export JULIA_NUM_PRECOMPILE_TASKS=${SLURM_CPUS_PER_TASK:-8}
echo "host $(hostname), arch $(uname -m), $(julia +1.11 --version)"

for env in "$repo" "$repo/plots"; do
    echo "== precompiling $env"
    julia +1.11 --project="$env" -e 'using Pkg; Pkg.precompile()'
done

echo "== package tests"
cd "$repo"
julia +1.11 --project=. DifferentiableEarth/test/runtests.jl
