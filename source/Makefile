objs = p.o makewords.o
exec = p makewords

p: p.asm
	as	-o p.o p.asm
	ld	-o p p.o

makewords: makewords.asm
	as	-o makewords.o makewords.asm
	ld	-o makewords makewords.o

clean:
	rm	-rf $(objs) $(exec)

