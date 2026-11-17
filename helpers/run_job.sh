#!/bin/bash
# Run a driver from its run directory on a compute node. The run directory holds its own copy of
# the driver (whose Settings block is the run's configuration); output and the log go there too.
#     mkdir -p run/<name> && cp drivers/<driver>.jl run/<name>/        # then edit its Settings
#     sbatch helpers/run_job.sh run/<name>                              # runs the one .jl file there
#     sbatch -p ceoas-arm helpers/run_job.sh run/<name>                 # GH200 (aarch64) nodes
# After a precompile job:  sbatch --dependency=afterok:<jobid> helpers/run_job.sh run/<name>
# Hardware/time options on the sbatch line override the defaults below.
#SBATCH --job-name=de-run
#SBATCH --partition=ceoas
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=4:00:00
#SBATCH --output=slurm-%j.out

set -euo pipefail
usage="usage: sbatch helpers/run_job.sh <run directory>   (holding exactly one driver .jl file)"
[[ -n ${SLURM_JOB_ID:-} ]] || { echo "submit with sbatch; $usage" >&2; exit 1; }
(( $# == 1 )) || { echo "$usage" >&2; exit 1; }
repo=$SLURM_SUBMIT_DIR
cd "$1"
drivers=(*.jl)
(( ${#drivers[@]} == 1 )) && [[ -f ${drivers[0]} ]] || { echo "need exactly one .jl in $PWD; $usage" >&2; exit 1; }
source "$repo/helpers/arch_env.sh"

log=$PWD/slurm-$SLURM_JOB_ID.out
echo "job $SLURM_JOB_ID on $(hostname) ($(uname -m)), run directory $PWD; log: $log"
exec > "$log" 2>&1
echo "job $SLURM_JOB_ID on $(hostname) ($(uname -m)), $(julia +1.11 --version), driver ${drivers[0]}"
echo "start: $(date -Is)"
trap 'echo "end: $(date -Is), exit status $?"' EXIT
julia +1.11 --project="$repo" -t "${SLURM_CPUS_PER_TASK:-1}" "${drivers[0]}"
