
OBJS = cJSON.o c-scanner.o entry.o generator.o interpreter.o hash.o main.o string.o to-dot.o
LIBS = cJSON.h hash.h entry.h generator.h interpreter.h string.h to-dot.h
PROS = code-insight

PREFIX = ~/bin

CFLAGES = -g

$(PROS) : $(LIBS) $(OBJS)
	gcc $(CFLAGES) -o $(PROS) $(OBJS) -lm

cJSON.o : $(LIBS) cJSON.c
	gcc $(CFLAGES) -c cJSON.c

c-scanner.o : $(LIBS) c-scanner.c
	gcc $(CFLAGES) -c c-scanner.c

c-scanner.c: $(LIBS) c-scanner.l
	flex -o c-scanner.c c-scanner.l

to-dot.o: $(LIBS)
	gcc $(CFLAGES) -c to-dot.c

entry.o : $(LIBS) entry.c
	gcc $(CFLAGES) -c entry.c

generator.o : $(LIBS) generator.c
	gcc $(CFLAGES) -c generator.c

interpreter.o : $(LIBS) interpreter.c
	gcc $(CFLAGES) -c interpreter.c

hash.o : $(LIBS) hash.c
	gcc $(CFLAGES) -c hash.c

main.o : $(LIBS) main.c
	gcc $(CFLAGES) -c main.c

string.o : $(LIBS) string.c
	gcc $(CFLAGES) -c string.c

install :
	cp $(PROS) $(PREFIX)
	-mkdir /etc/code-insight
	cp template.html /etc/code-insight

uninstall :
	rm $(PREFIX)/$(PROS)
	rm -rf /etc/code-insight

clean:
	-rm $(PROS) $(OBJS) c-scanner.c
