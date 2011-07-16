#ifndef STRING_H
#define STRING_H
#include <stdio.h>

#define STRING_INIT_SIZE 50
#define STRING_INCREMENT 10

#define TERMINATED 1
#define UNTERMINATED 0

typedef struct sString {
	size_t used;
	size_t size;
	char *buffer;
} String;

extern String * string_init(char *);
extern String * string_add(String *, char);
extern String * string_append(String *, char *);
extern String * string_replace(String *, char *);
extern void string_free(String *target);
#endif /*STRING_H*/
