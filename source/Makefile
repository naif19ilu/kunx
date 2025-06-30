objs = p.o
exec = p

p: p.asm
	as	-o p.o p.asm
	ld	-o p p.o

clean:
	rm	-rf $(objs) $(exec)

