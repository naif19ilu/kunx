objs = p.o makewords.o lowercase.o sort.o unique.o
exec = p makewords lowercase sort unique

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

sort: sort.asm
	as	-o sort.o sort.asm
	ld	-o sort sort.o

unique: unique.asm
	as	-o unique.o unique.asm
	ld	-o unique unique.o

clean:
	rm	-rf $(objs) $(exec)

