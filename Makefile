# PREDICODE Flags
#PROFILING=-dprofiling
#following is for progress-aware execution
#PROFILING=
#following is for vanilla
PROFILING=noprofile
GPU=0
CUDNN=0
OPENCV=0
OPENMP=0
DEBUG=0

ARCH= -gencode arch=compute_30,code=sm_30 \
      -gencode arch=compute_35,code=sm_35 \
      -gencode arch=compute_50,code=[sm_50,compute_50] \
      -gencode arch=compute_52,code=[sm_52,compute_52]
#      -gencode arch=compute_20,code=[sm_20,sm_21] \ This one is deprecated?

# This is what I use, uncomment if you know your arch and want to specify
# ARCH= -gencode arch=compute_52,code=compute_52

VPATH=./src/:./examples
SLIB=libdarknet.so
ALIB=libdarknet.a
EXEC=darknet
OBJDIR=./obj/

LLVM_BIN=/localdisk/soham/build/bin
PREDICODE_LIB_SRC=$(LLVM_BIN)/../lib.c
PREDICODE_HEADER=$(LLVM_BIN)/../lib.h
PREDICODE_LIB_LL=$(LLVM_BIN)/../lib.ll


OPT=$(LLVM_BIN)/opt
#CC=$(LLVM_BIN)/clang
CC=gcc
NVCC=nvcc 
AR=ar
ARFLAGS=rcs
OPTS=-Ofast
LDFLAGS= -lm -pthread -lrt
COMMON= -Iinclude/ -Isrc/
CFLAGS=-Wall -Wno-unused-result -Wno-unknown-pragmas -Wfatal-errors -fPIC

ifeq ($(OPENMP), 1) 
CFLAGS+= -fopenmp
LDFLAGS+= -lomp
endif

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

ifeq ($(GPU), 1) 
COMMON+= -DGPU -I/usr/local/cuda/include/
CFLAGS+= -DGPU
LDFLAGS+= -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand
endif

ifeq ($(CUDNN), 1) 
COMMON+= -DCUDNN 
CFLAGS+= -DCUDNN
LDFLAGS+= -lcudnn
endif

OBJ=gemm.o utils.o cuda.o deconvolutional_layer.o convolutional_layer.o list.o image.o activations.o im2col.o col2im.o blas.o crop_layer.o dropout_layer.o maxpool_layer.o softmax_layer.o data.o network.o matrix.o connected_layer.o cost_layer.o parser.o option_list.o detection_layer.o route_layer.o upsample_layer.o box.o normalization_layer.o avgpool_layer.o layer.o local_layer.o shortcut_layer.o logistic_layer.o activation_layer.o rnn_layer.o gru_layer.o crnn_layer.o demo.o batchnorm_layer.o region_layer.o reorg_layer.o tree.o  lstm_layer.o l2norm_layer.o yolo_layer.o
PASTIME=/home/common_shared/PAStime/pastime/lib.o
PREDICODE_OBJ=classifier.o
EXECOBJA=captcha.o lsd.o super.o art.o tag.o cifar.o go.o rnn.o segmenter.o regressor.o classifier.o coco.o yolo.o detector.o nightmare.o darknet.o
ifeq ($(GPU), 1) 
LDFLAGS+= -lstdc++ 
OBJ+=convolutional_kernels.o deconvolutional_kernels.o activation_kernels.o im2col_kernels.o col2im_kernels.o blas_kernels.o crop_layer_kernels.o dropout_layer_kernels.o maxpool_layer_kernels.o avgpool_layer_kernels.o
endif

#------------------------------------LITMUS Stuff
LIBLITMUS=/home/common_shared/litmus/liblitmus
COMMON+= -I${LIBLITMUS}/include -I${LIBLITMUS}/arch/x86/include
LDFLAGS+= -L${LIBLITMUS} -llitmus

#------------------------------------PAStime Stuff
PASTIME=/home/common_shared/PAStime/pastime
COMMON+= -I${PASTIME}/
LDFLAGS+= -L${PASTIME} -lpastime

#------------------------------------PMU Tools Stuff
JEVENTS=/home/common_shared/PAStime/PMU/pmu-tools/jevents
#COMMON+= -I${JEVENTS}
#LDFLAGS+= -L${JEVENTS} -ljevents
LDFLAGS+= -ljevents

EXECOBJ = $(addprefix $(OBJDIR), $(EXECOBJA))
OBJS = $(addprefix $(OBJDIR), $(OBJ))
PREDICODE_OBJS=$(addprefix $(OBJDIR), $(PREDICODE_OBJ))
DEPS = $(wildcard src/*.h) Makefile include/darknet.h

all: obj backup results $(SLIB) $(ALIB) $(EXEC)
#all: obj  results $(SLIB) $(ALIB) $(EXEC)


$(EXEC): $(EXECOBJ) $(ALIB) #$(PASTIME) #$(PREDICODE_LIB_LL)
	$(CC) $(COMMON) $(CFLAGS) $^ $(LDFLAGS) -o $@ $(ALIB)

$(ALIB): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^

$(SLIB): $(OBJS)
	$(CC) $(CFLAGS) -shared $(LDFLAGS) $^ -o $@

$(OBJDIR)%.o: %.c $(DEPS)
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@
ifneq ($(PROFILING),noprofile)
	@$(if $(findstring $@, $(PREDICODE_OBJS)), \
	$(CC) $(COMMON) -O0 $(CFLAGS) -O0 -S -emit-llvm -include $(PREDICODE_HEADER) $< -o $<.temp; \
	$(OPT) -load $(LLVM_BIN)/../lib/LLVMProfilingPass.so $(PROFILING) -profilingpass --profiling_functions=folder_walk_classify -S -o $<.temp2 < $<.temp; \
	$(CC) $(COMMON) $(CFLAGS) -S -emit-llvm -x ir $<.temp2 -o $<.temp3; \
	$(CC) $(COMMON) $(CFLAGS) -c -x ir $<.temp3 -o $@; \
	echo "$@ is instrumented")
endif

$(PASTIME)%.o: %.c
	$(CC) $(COMMON) $(CFLAGS) -c $< -o $@

$(OBJDIR)%.o: %.cu $(DEPS)
	$(NVCC) $(ARCH) $(COMMON) --compiler-options "$(CFLAGS)" -c $< -o $@

#$(PREDICODE_OBJS): %.c $(DEPS)
#	$(CC) $(COMMON) -O0 $(CFLAGS) -O0 -S -emit-llvm -include $(PREDICODE_HEADER) $< -o $@.temp
#	$(OPT) -load $(LLVM_BIN)/../lib/LLVMProfilingPass.so -profilingpass -dprofiling --profiling_functions=forward_network -S -o $@.temp2 < $@.temp
#	$(CC) $(COMMON) $(CFLAGS) -S -emit-llvm -x ir $@.temp2 -o $@

$(PREDICODE_LIB_LL): $(PREDICODE_LIB_SRC)
	$(CC) -S -emit-llvm $< -o $@ -Ofast -finline-hint-functions -finline-functions

obj:
	mkdir -p obj
backup:
	mkdir -p backup
results:
	mkdir -p results

.PHONY: clean

clean:
	rm -rf $(OBJS) $(SLIB) $(ALIB) $(EXEC) $(EXECOBJ) $(OBJDIR)/*

