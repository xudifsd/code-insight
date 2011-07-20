
OBJS = cJSON.o c-scanner.o entry.o generator.o hash.o main.o string.o
LIBS = cJSON.h hash.h entry.h generator.h string.h
PROS = code-insight

CFLAGES = -g

$(PROS) : $(LIBS) $(OBJS)
	gcc $(CFLAGES) -o $(PROS) $(OBJS) -lm

cJSON.o : $(LIBS) cJSON.c
	gcc $(CFLAGES) -c cJSON.c

c-scanner.o : $(LIBS) c-scanner.c
	gcc $(CFLAGES) -c c-scanner.c

c-scanner.c: $(LIBS) c-scanner.l
	flex -o c-scanner.c c-scanner.l

entry.o : $(LIBS) entry.c
	gcc $(CFLAGES) -c entry.c

generator.o : $(LIBS) generator.c
	gcc $(CFLAGES) -c generator.c

hash.o : $(LIBS) hash.c
	gcc $(CFLAGES) -c hash.c

main.o : $(LIBS) main.c
	gcc $(CFLAGES) -c main.c

string.o : $(LIBS) string.c
	gcc $(CFLAGES) -c string.c

clean:
	-rm $(PROS) $(OBJS) c-scanner.c
