#
# Default make builds both original darknet, and its CPP equivalent darknet-cpp
# make darknet - only darknet (original code), OPENCV=0
# make darknet-cpp - only the CPP version, OPENCV=1
# make darknet-cpp-shared - build the shared-lib version (without darknet.c calling wrapper), OPENCV=1
# 
# CPP version supports OpenCV3. Tested on Ubuntu 16.04
#
# OPENCV=1 (C++ && CV3, or C && CV2 only - check with pkg-config --modversion opencv)
# When building CV3 and C version, will get errors like
# ./obj/image.o: In function `cvPointFrom32f':
# /usr/local/include/opencv2/core/types_c.h:929: undefined reference to `cvRound'
#
# 

GPU=1
CUDNN=1
OPENCV=1
DEBUG=0

#ARCH= -gencode arch=compute_20,code=[sm_20,sm_21] \
      -gencode arch=compute_30,code=sm_30 \
      -gencode arch=compute_35,code=sm_35 \
      -gencode arch=compute_50,code=[sm_50,compute_50] \
      -gencode arch=compute_52,code=[sm_52,compute_52]

# This is what I use, uncomment if you know your arch and want to specify
ARCH=  -gencode arch=compute_52,code=compute_52

# C Definitions

VPATH=./src/
EXEC=darknet
OBJDIR=./obj/
CC=gcc

# C++ Definitions
EXEC_CPP=darknet-cpp
SHARED_CPP=darknet-cpp-shared
OBJDIR_CPP=./obj-cpp/
OBJDIR_CPP_SHARED=./obj-cpp-shared/
#CC_CPP=g++
CC_CPP=/usr/bin/c++
#CFLAGS_CPP=-Wno-write-strings -mavx -std=c++0x -I/usr/local/cuda-8.0/include -I/usr/local/zed/include -I/usr/include/eigen3 -I/home/mmvc/niu/zed-opencv/include -isystem /usr/local/include -isystem /usr/local/include/opencv -Wno-format-extra-args  
CFLAGS_CPP= -I/usr/local/cuda-8.0/include -I/usr/local/zed/include -I/usr/include/eigen3 -I/home/mmvc/niu/zed-opencv/include -isystem /usr/local/include -isystem /usr/local/include/opencv  -mavx -Wno-format-extra-args -std=c++0x 
#CFLAGS_CPP+= -L/usr/local/cuda-8.0/lib64  -L/usr/local/zed/lib -rdynamic /usr/local/zed/lib/libsl_zed.so /usr/local/zed/lib/libsl_depthcore.so /usr/local/zed/lib/libsl_calibration.so /usr/local/zed/lib/libsl_tracking.so /usr/local/zed/lib/libsl_disparityFusion.so /usr/local/zed/lib/libsl_svorw.so /usr/local/zed/lib/libcudpp.so /usr/local/zed/lib/libcudpp_hash.so /usr/local/lib/libopencv_cudabgsegm.so.3.2.0 /usr/local/lib/libopencv_cudaobjdetect.so.3.2.0 /usr/local/lib/libopencv_cudastereo.so.3.2.0 /usr/local/lib/libopencv_ml.so.3.2.0 /usr/local/lib/libopencv_shape.so.3.2.0 /usr/local/lib/libopencv_stitching.so.3.2.0 /usr/local/lib/libopencv_superres.so.3.2.0 /usr/local/lib/libopencv_videostab.so.3.2.0 -lcuda /usr/local/cuda-8.0/lib64/libcudart.so /usr/local/cuda-8.0/lib64/libnppc.so /usr/local/cuda-8.0/lib64/libnppi.so /usr/local/cuda-8.0/lib64/libnpps.so /usr/local/lib/libopencv_cudafeatures2d.so.3.2.0 /usr/local/lib/libopencv_cudacodec.so.3.2.0 /usr/local/lib/libopencv_cudaoptflow.so.3.2.0 /usr/local/lib/libopencv_cudalegacy.so.3.2.0 /usr/local/lib/libopencv_calib3d.so.3.2.0 /usr/local/lib/libopencv_cudawarping.so.3.2.0 /usr/local/lib/libopencv_features2d.so.3.2.0 /usr/local/lib/libopencv_flann.so.3.2.0 /usr/local/lib/libopencv_highgui.so.3.2.0 /usr/local/lib/libopencv_objdetect.so.3.2.0 /usr/local/lib/libopencv_photo.so.3.2.0 /usr/local/lib/libopencv_cudaimgproc.so.3.2.0 /usr/local/lib/libopencv_cudafilters.so.3.2.0 /usr/local/lib/libopencv_cudaarithm.so.3.2.0 /usr/local/lib/libopencv_video.so.3.2.0 /usr/local/lib/libopencv_videoio.so.3.2.0 /usr/local/lib/libopencv_imgcodecs.so.3.2.0 /usr/local/lib/libopencv_imgproc.so.3.2.0 /usr/local/lib/libopencv_core.so.3.2.0 /usr/local/lib/libopencv_cudev.so.3.2.0 -Wl,-rpath,/usr/local/cuda-8.0/lib64:/usr/local/zed/lib:/usr/local/lib

NVCC=nvcc

OPTS=-Ofast
LDFLAGS= -lm -pthread 
COMMON= 
CFLAGS=-Wall -Wfatal-errors 


ifeq ($(DEBUG), 1) 
OPTS=-O0 -g
endif

CFLAGS+=$(OPTS)

ifeq ($(OPENCV), 1) 
COMMON+= -DOPENCV
CFLAGS+= -DOPENCV
LDFLAGS+= `pkg-config --libs opencv` 
COMMON+= `pkg-config --cflags opencv` 
endif

# Place the IPP .a file from OpenCV here for easy linking
LDFLAGS += -L./3rdparty

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda-8.0/lib64 -L/usr/local/zed/lib -rdynamic /usr/local/zed/lib/libsl_zed.so /usr/local/zed/lib/libsl_depthcore.so /usr/local/zed/lib/libsl_calibration.so /usr/local/zed/lib/libsl_tracking.so /usr/local/zed/lib/libsl_disparityFusion.so /usr/local/zed/lib/libsl_svorw.so /usr/local/zed/lib/libcudpp.so /usr/local/zed/lib/libcudpp_hash.so /usr/local/lib/libopencv_cudabgsegm.so.3.2.0 /usr/local/lib/libopencv_cudaobjdetect.so.3.2.0 /usr/local/lib/libopencv_cudastereo.so.3.2.0 /usr/local/lib/libopencv_ml.so.3.2.0 /usr/local/lib/libopencv_shape.so.3.2.0 /usr/local/lib/libopencv_stitching.so.3.2.0 /usr/local/lib/libopencv_superres.so.3.2.0 /usr/local/lib/libopencv_videostab.so.3.2.0 -lcuda /usr/local/cuda-8.0/lib64/libcudart.so /usr/local/cuda-8.0/lib64/libnppc.so /usr/local/cuda-8.0/lib64/libnppi.so /usr/local/cuda-8.0/lib64/libnpps.so /usr/local/lib/libopencv_cudafeatures2d.so.3.2.0 /usr/local/lib/libopencv_cudacodec.so.3.2.0 /usr/local/lib/libopencv_cudaoptflow.so.3.2.0 /usr/local/lib/libopencv_cudalegacy.so.3.2.0 /usr/local/lib/libopencv_calib3d.so.3.2.0 /usr/local/lib/libopencv_cudawarping.so.3.2.0 /usr/local/lib/libopencv_features2d.so.3.2.0 /usr/local/lib/libopencv_flann.so.3.2.0 /usr/local/lib/libopencv_highgui.so.3.2.0 /usr/local/lib/libopencv_objdetect.so.3.2.0 /usr/local/lib/libopencv_photo.so.3.2.0 /usr/local/lib/libopencv_cudaimgproc.so.3.2.0 /usr/local/lib/libopencv_cudafilters.so.3.2.0 /usr/local/lib/libopencv_cudaarithm.so.3.2.0 /usr/local/lib/libopencv_video.so.3.2.0 /usr/local/lib/libopencv_videoio.so.3.2.0 /usr/local/lib/libopencv_imgcodecs.so.3.2.0 /usr/local/lib/libopencv_imgproc.so.3.2.0 /usr/local/lib/libopencv_core.so.3.2.0 /usr/local/lib/libopencv_cudev.so.3.2.0 -Wl,-rpath,/usr/local/cuda-8.0/lib64:/usr/local/zed/lib:/usr/local/lib -lcuda -lcudart -lcublas -lcurand 
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ-SHARED=gemm.o utils.o cuda.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o matrix.o network.o connected_layer.o cost_layer.o parser.o option_list.o detection_layer.o captcha.o route_layer.o writing.o box.o nightmare.o normalization_layer.o avgpool_layer.o coco.o dice.o yolo.o detector.o layer.o compare.o classifier.o local_layer.o swag.o shortcut_layer.o activation_layer.o rnn_layer.o gru_layer.o rnn.o rnn_vid.o crnn_layer.o demo.o tag.o cifar.o go.o batchnorm_layer.o art.o region_layer.o reorg_layer.o super.o voxel.o tree.o

ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ-GPU=convolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o network_kernels.o avgpool_layer_kernels.o
OBJ-SHARED+=$(OBJ-GPU)
endif

OBJ=$(OBJ-SHARED) darknet.o
OBJS = $(addprefix $(OBJDIR), $(OBJ))
DEPS = $(wildcard src/*.h) Makefile

OBJS_CPP = $(addprefix $(OBJDIR_CPP), $(OBJ))
OBJS_CPP_SHARED = $(addprefix $(OBJDIR_CPP_SHARED), $(OBJ-SHARED))

all: backup obj obj-cpp results $(EXEC) $(EXEC_CPP)

$(EXEC): obj clean $(OBJS)
	$(CC) $(COMMON) $(CFLAGS) $(OBJS) -o $@ $(LDFLAGS)

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(EXEC_CPP): obj-cpp clean-cpp $(OBJS_CPP)
	$(CC_CPP) $(COMMON) $(CFLAGS) $(OBJS_CPP) -o $@ $(LDFLAGS)
$(SHARED_CPP): obj-shared-cpp clean-cpp $(OBJS_CPP_SHARED)
	$(CC_CPP) $(COMMON) $(CFLAGS) $(OBJS_CPP_SHARED) -o lib$@.so $(LDFLAGS) -shared	

$(OBJDIR_CPP)%.o: %.c $(DEPS)
	$(CC_CPP) $(COMMON) $(CFLAGS_CPP) $(CFLAGS) -c $< -o $@
$(OBJDIR_CPP_SHARED)%.o: %.c $(DEPS)
	$(CC_CPP) $(COMMON) $(CFLAGS_CPP) $(CFLAGS) -fPIC -c $< -o $@

$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

$(OBJDIR_CPP)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@
$(OBJDIR_CPP_SHARED)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS) -fPIC" -c $< -o $@

	
obj:
	mkdir -p obj
obj-cpp:
	mkdir -p obj-cpp
obj-shared-cpp:
	mkdir -p obj-cpp-shared

backup:
	mkdir -p backup

results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(EXEC)
clean-cpp:
	rm -rf $(OBJS_CPP) $(OBJS_CPP_SHARED) $(EXEC_CPP) $(SHARED_CPP)

