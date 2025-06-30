objs = p.o makewords.o lowercase.o
exec = p makewords lowercase

all: $(exec)

p: p.asm
	as	-o p.o p.asm
	ld	-o p p.o

makewords: makewords.asm
	as	-o makewords.o makewords.asm
	ld	-o makewords makewords.o

lowercase: lowercase.asm
	as	-o lowercase.o lowercase.asm
	ld	-o lowercase lowercase.o

clean:
	rm	-rf $(objs) $(exec)

