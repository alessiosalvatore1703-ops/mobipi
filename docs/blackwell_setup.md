# Setup for NVIDIA Blackwell GPUs (RTX 50xx, sm_120)

`install.sh` pins `torch==2.2.0+cu121`, which has no sm_120 kernels. Use this recipe instead.
Verified on an RTX 5080 Laptop, driver 580, vanilla-policy eval (CloseDrawer).

```bash
conda create -n mobipi-bw -c conda-forge python=3.10
conda activate mobipi-bw
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128
conda install -c nvidia/label/cuda-12.8.1 cuda-nvcc cuda-cudart-dev cuda-libraries-dev

# gsplat JIT-compiles CUDA on first use and needs nvcc plus the conda include/lib dirs.
T=$CONDA_PREFIX/targets/x86_64-linux
conda env config vars set CUDA_HOME=$CONDA_PREFIX TORCH_CUDA_ARCH_LIST=12.0 CPATH=$T/include LIBRARY_PATH=$T/lib
conda deactivate && conda activate mobipi-bw

pip install nerfstudio==1.1.5 robosuite==1.5.0
# Submodule numpy pins conflict with each other, so install them without deps.
pip install --no-deps -e external/robocasa -e external/diffusion_policy -e external/mimicgen \
    -e external/robomimic -e external/lelan/train -e .
pip install numpy==1.23.5 mujoco==3.2.6 diffusers==0.11.1 transformers==4.36.0 \
    huggingface-hub==0.25.0 peft==0.10.0 timm==1.0.12 tianshou==0.4.10 --no-deps
pip install imageio-ffmpeg tensorboardX scikit-optimize cma sentencepiece prettytable \
    efficientnet-pytorch warmup-scheduler openai-clip lmdb vit-pytorch positional-encodings \
    scikit-video einops hydra-core zarr
```

Then follow the README (macros, `download_kitchen_assets.py`, `download_pi.py`) and run evals
with `MUJOCO_GL=egl`. pip prints dependency-conflict warnings from the submodules' old pins;
they are metadata only.

`MOBIPI_ENV_SEED` (default 0) changes the env seed so repeated evals sample new episodes;
`mobipi/eval/run_timed_rotation.sh [budget_s] [out_dir]` rotates scenes 1,4,7,8,9 for a
wall-clock budget and writes `results.csv`.
