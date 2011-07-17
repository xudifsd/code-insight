
OBJS = hash.o parser.o string.o
LIBS = hash.h string.h
PROS = code-insight

CFLAGES = -g

$(PROS) : $(LIBS) $(OBJS)
	gcc $(CFLAGES) -o $(PROS) $(OBJS)

parser.o : $(LIBS) parser.c
	gcc $(CFLAGES) -c parser.c

parser.c: parser.l
	flex -o parser.c parser.l

string.o : $(LIBS) string.c
	gcc $(CFLAGES) -c string.c

hash.o : $(LIBS) hash.c
	gcc $(CFLAGES) -c hash.c

clean:
	-rm $(PROS) $(OBJS) parser.c
