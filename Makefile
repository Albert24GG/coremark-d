# Compiler definitions
LDC = ldc2
GDC = gdc
CC = gcc

# Output binaries
LDC_BIN = coremark_ldc
GDC_BIN = coremark_gdc

# Compiler flags (customize as needed)
GDCFLAGS = -O3 -frelease
LDCFLAGS = -O3 -release
CFLAGS = -O3

# Source files
D_SOURCES = core_state.d core_list_join.d core_main.d core_matrix.d core_util.d coremark.d
POSIX_SOURCES = posix/core_portme_posix_overrides.d posix/core_portme_h.d posix/core_portme.d
C_SOURCES = posix/callgrind_instr.c

# Object files
C_OBJECTS = $(C_SOURCES:.c=.o)

# Default target
all: $(LDC_BIN) $(GDC_BIN)

# Rule for compiling C files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# LDC compilation rule
$(LDC_BIN): $(C_OBJECTS) $(D_SOURCES) $(POSIX_SOURCES)
	$(LDC) $(LDCFLAGS) -of=$@ $(D_SOURCES) $(POSIX_SOURCES) $(C_OBJECTS)

# GDC compilation rule
$(GDC_BIN): $(C_OBJECTS) $(D_SOURCES) $(POSIX_SOURCES)
	$(GDC) $(GDCFLAGS) -o $@ $(D_SOURCES) $(POSIX_SOURCES) $(C_OBJECTS)

# Clean rule
clean:
	rm -f $(LDC_BIN) $(LDC_BIN).o $(GDC_BIN) $(GDC_BIN).o $(C_OBJECTS)

.PHONY: all clean
