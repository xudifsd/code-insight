#ifndef PARSE_H
#define PARSE_H

#include "string.h"

struct file {
	String *filename;
	struct function_definition *definition_list;
	struct file *next;
};

struct function_definition {
	int lineno;
	String *file_name;	/*should be specify, because it's maybe in included file*/
	String *return_value;	/*some language do not have to specify return type, so return_value->buffer can be empty string*/
	String *function_name;
	String *args_list;
	struct function_definition *next;
	struct invoked_function *invocation_list;
};

struct invoked_function {
	int lineno;
	String *function_name;
	String *pars_list;
	struct invoked_function *next;
};

extern struct file * file_entry_init(char *);
extern struct function_definition * definition_entry_init(int, char *, char *, char *, char *);
extern struct invoked_function * invocation_entry_init(int, char *, char *);
extern int add_invoked_function(struct function_definition *, struct invoked_function *);
#endif /*PARSE_H*/
