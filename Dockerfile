# Start from the pristine PyTorch 2.1 & CUDA 12.1 Development image
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-devel

# Prevent interactive prompts during apt installations
ENV DEBIAN_FRONTEND=noninteractive

# FIX 1: Added libopengl0 to solve the missing libOpenGL.so.0 error
RUN apt-get update && apt-get install -y \
    git wget unzip curl ninja-build \
    libglib2.0-0 libsm6 libxrender-dev libxext6 \
    libgl1-mesa-glx libegl1 libgles2 libglvnd0 \
    libosmesa6 libopengl0 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/glvnd/egl_vendor.d && \
    echo '{\n\
    "file_format_version" : "1.0.0",\n\
    "ICD" : {\n\
        "library_path" : "libEGL_nvidia.so.0"\n\
    }\n\
}' > /usr/share/glvnd/egl_vendor.d/10_nvidia.json

ENV PYOPENGL_PLATFORM=egl

# RUN conda install -y -c conda-forge ffmpeg=4.2.2

RUN wget https://johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.2.2-amd64-static.tar.xz && \
    tar -xf ffmpeg-4.2.2-amd64-static.tar.xz && \
    cp ffmpeg-4.2.2-amd64-static/ffmpeg /opt/conda/bin/ && \
    cp ffmpeg-4.2.2-amd64-static/ffprobe /opt/conda/bin/ && \
    rm -rf ffmpeg-4.2.2-*
# Fix the two major Python packaging issues
RUN pip install --upgrade pip && \
    pip install "setuptools<70.0.0" "numpy<2.0.0" wheel

# Set the default working directory
WORKDIR /workspace/phantom

# Copy your local repository into the container's workspace
COPY . /workspace/phantom/

RUN pip install -e submodules/sam2[notebooks]
RUN pip install -e submodules/phantom-hamer[all] --no-build-isolation
RUN pip install -e submodules/phantom-hamer/third-party/ViTPose

# Install mmcv
RUN pip install torch==2.1.0 torchvision==0.16.0 --index-url https://download.pytorch.org/whl/cu121
RUN pip install mmcv==1.3.9
RUN pip install mmcv-full -f https://download.openmmlab.com/mmcv/dist/cu121/torch2.1.0/index.html
RUN pip install numpy==1.26.4

RUN pip install -e submodules/phantom-robosuite
RUN pip install -e submodules/phantom-robomimic

# Install global dependencies
RUN pip install joblib mediapy open3d pandas transformers==4.42.4 PyOpenGL==3.1.4 Rtree \
    protobuf==3.20.0 hydra-core==1.3.2 omegaconf==2.3.0 gdown \
    git+https://github.com/epic-kitchens/epic-kitchens-100-hand-object-bboxes.git

RUN pip install -e submodules/phantom-E2FGVI

RUN pip install -e .