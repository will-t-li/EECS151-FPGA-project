.section    .start
.global     _start

_start:

# Follow a convention
# x1 = result register 1
# x2 = result register 2
# x10 = argument 1 register
# x11 = argument 2 register
# x20 = flag register

# Test ADD
li x10, 100		      # Load argument 1 (rs1)
li x11, 200		      # Load argument 2 (rs2)
add x1, x10, x11	  # Execute the instruction being tested
li x20, 1		        # Set the flag register to stop execution and inspect the result register
			              # Now we check that x1 contains 300

# Test BEQ
li x2, 100		      # Set an initial value of x2
beq x0, x0, branch1	# This branch should succeed and jump to branch1
li x2, 123		      # This shouldn't execute, but if it does x2 becomes an undesirable value
branch1: li x1, 500	# x1 now contains 500
li x20, 2		        # Set the flag register
			              # Now we check that x1 contains 500 and x2 contains 100

# Test Everything

li x3, 100
# addi x0, x0, 0 # required
sw	x3, 0(x1)

lui	x2, 0xaa0
addi x2, x2, 170
sw	x2, 0(x1)
lw	x14, 0(x1)
li x20, 3		        # Set the flag register

# Test CSR
li x19, 1
csrrw x0, 0x51E, x19

# Test DATA
li x15, 2
sw	x15,0(x1)
lw	x15,0(x1)
addi x15,x15,1
sw	x15,0(x1)
lw	x15,0(x1)
li x20, 4	



Done: j Done

