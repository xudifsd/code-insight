
OBJS = parser.o string.o
LIBS = string.h
PROS = code-insight

main : $(LIBS) $(OBJS)
	gcc -g -o $(PROS) $(OBJS)

parser.o : $(LIBS) parser.c
	gcc -g -c parser.c

parser.c: parser.l
	flex -o parser.c parser.l

string.o : $(LIBS) string.c
	gcc -g -c string.c

clean:
	-rm $(PROS) $(OBJS) parser.c
