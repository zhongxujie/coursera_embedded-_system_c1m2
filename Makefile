#******************************************************************************
# Copyright (C) 2017 by Alex Fosdick - University of Colorado
#
# Redistribution, modification or use of this software in source or binary
# forms is permitted as long as the files maintain this copyright. Users are 
# permitted to modify this and use it to learn about the field of embedded
# software. Alex Fosdick and the University of Colorado are not liable for any
# misuse of this material. 
#
#*****************************************************************************

#------------------------------------------------------------------------------ 
# Description:
# Use: make [TARGET] [PLATFORM-OVERRIDES]
# 
# Build Targets:
#      <FILE>.o - object file
#      <FILE>.i - preprocessed file
#      <FILE>.asm - assembly file
#      complie-all - complie all object files (do not link)
#      build - compile all object file and link to final executable
#      clean - remove all compiled file
# 
# Platform Overrides:
#      Target Platform: HOST, MSP432
#------------------------------------------------------------------------------
include sources.mk

# Platform overrrides
ifeq ($(PLATFORM), HOST)
	# Compile Flags and Defines
	CC = gcc
	LD = ld
	LDFLAGS = -Wl,-Map=$(TARGET).map 
	CFLAGS = -Werror -g -O0 -std=c99 
	CPPFLAGS = $(INCLUDES) -DHOST

	#other GNU tools
	SIZE = size
	OBJDUMP = objdump
endif
ifeq ($(PLATFORM), MSP432)
	#Architecture Specific Flags
	LINKER_FILE = -T msp432p401r.lds
	CPU = cortex-m4 
	ARCH = armv7e-m
	SPECS = nosys.specs
	FLOAT-ABI = hard
	FPU = fpv4-sp-d16
	# source files
	SOURCES := main.c \
			   memory.c \
			   interrupts_msp432p401r_gcc.c \
			   startup_msp432p401r_gcc.c \
			   system_msp432p401r.c
	# Compile Flags and Defines	    
	CC = arm-none-eabi-gcc
	LD = arm-none-eabi-ld
	LDFLAGS = -Wl,-Map=$(TARGET).map $(LINKER_FILE)
	CFLAGS = -Werror -g -O0 -std=c99 -mthumb \
			 -mcpu=$(CPU) -march=$(ARCH) --specs=$(SPECS) -mfpu=$(FPU) -mfloat-abi=$(FLOAT-ABI) 
	CPPFLAGS = $(INCLUDES) -DMSP432
	
	# other GNU tools
	SIZE = arm-none-eabi-size
	OBJDUMP = arm-none-eabi-objdump
endif

# Generate the preprocessed output of all c-program implementation files (use the –E flag).
PRES = $(SOURCES:.c=.i)
%.i : %.c
	$(CC) -E $< $(CPPFLAGS) -o $@

# Generate assembly output of c-program implementation files 
# and the final output executable (Use the –S flag and the objdump utility)
ASMS = $(SOURCES:.c=.asm)
%.asm : %.c
	$(CC) -S $< $(CPPFLAGS) $(CFLAGS) -o $@

# Generate the object file for all c-source files (but do not link) 
# by specifying the object file you want to compile.
OBJS = $(SOURCES:.c=.o)
%.o : %.c
	$(CC) -c $< $(CPPFLAGS) $(CFLAGS) -o $@

# Generate the dependency file for all c-source files
DEPS = $(SOURCES:.c=.d)
%.d : %.c
	$(CC) -E -M $< $(CPPFLAGS) -o $@

.PHONY: compile-all
compile-all: $(OBJS)

.PHONY: build
build: c1m2.out

c1m2.out: $(OBJS)
	$(CC) $(OBJS) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@
	$(SIZE) $@

.PHONY: clean
clean:
	rm -f *.i *.asm *.o *.d c1m2.out *.map


