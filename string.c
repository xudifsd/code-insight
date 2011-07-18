#include <malloc.h>
#include <string.h>
#include "string.h"

String * string_init(char *string){
	String * rtn = (String *)malloc(sizeof(String));
	rtn->buffer = (char *)malloc(STRING_INIT_SIZE);
	//we always init String.buffer to '0' so that we can treat String.buffer as a string at any particular times
	memset(rtn->buffer, 0, STRING_INIT_SIZE);
	rtn->used = 0;
	rtn->size = STRING_INIT_SIZE;
	string_append(rtn, string);
	return rtn;
}

static String * string_increase(String *target){
	target->buffer = (char *)realloc(target->buffer, target->size + STRING_INCREMENT);
	//we always init String.buffer to '0' so that we can treat String.buffer as a string at any particular times
	memset(target->buffer + target->used, 0, STRING_INCREMENT);
	target->size += STRING_INCREMENT;
	return target;
}

String * string_add(String *target, char character){	//fundamental function to add something to String->buffer
	if (target->size == target->used + 1){	//save '\0'
		string_increase(target);
		string_add(target, character);
	} else {
		target->buffer[target->used++] = character;
	}
}

String * string_append(String *target, char *src){
	if (src == NULL)
		return target;
	int i;
	for (i = 0; src[i] != '\0'; i++){
		string_add(target, src[i]);
	}
}

String * string_replace(String *target, char *src){
	memset(target->buffer, 0, target->size);
	target->used = 0;
	string_append(target, src);
}

void string_free(String *target){
	free(target->buffer);
	free(target);
}
