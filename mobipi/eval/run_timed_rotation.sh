#!/bin/bash
# Rotates the vanilla-policy eval over the test scenes until a wall-clock budget
# runs out, then writes results.csv (round, scene, success_rate, seconds).
# Each round exports a fresh MOBIPI_ENV_SEED so rounds sample new episodes; a run
# still in flight at the deadline is killed and not recorded.
#
# Usage: ./run_timed_rotation.sh [budget_seconds=7200] [out_dir=logs/rotation_<date>]
set -u

BUDGET_S=${1:-7200}
OUT_DIR=${2:-logs/rotation_$(date +%Y%m%d_%H%M%S)}
ENV_NAME=CloseDrawer
SCENES=(1 4 7 8 9)
EPISODES_PER_RUN=15

cd "$(dirname "$0")"
mkdir -p "$OUT_DIR"
OUT_DIR=$(realpath "$OUT_DIR")
export MUJOCO_GL=egl
echo "round,scene,success_rate,seconds" > "$OUT_DIR/results.csv"

deadline=$(( $(date +%s) + BUDGET_S ))
round=0
while true; do
  export MOBIPI_ENV_SEED=$round
  for scene in "${SCENES[@]}"; do
    remaining=$(( deadline - $(date +%s) ))
    [ "$remaining" -le 0 ] && break 2
    start=$(date +%s)
    log="$OUT_DIR/round${round}_scene${scene}.log"
    timeout "$remaining" python eval_baseline.py --env_name "$ENV_NAME" \
      --layout_id "$scene" --style_id "$scene" --seed 1 \
      --baseline_name vanilla_policy --num_episodes "$EPISODES_PER_RUN" \
      --log_root_dir "$OUT_DIR/round$round" > "$log" 2>&1 || continue
    rate=$(grep -a "Episodes end with success rate" "$log" | tail -1 | awk '{print $NF}')
    echo "$round,$scene,$rate,$(( $(date +%s) - start ))" >> "$OUT_DIR/results.csv"
  done
  round=$(( round + 1 ))
done
echo "done: $OUT_DIR/results.csv"
