#ifndef PARSE_H
#define PARSE_H

#include "hash.h"
#include "string.h"

struct file {
	String *filename;
	struct hash_table *type_table;	/*save all typedef variable type*/
	struct definition *definition_list;
	struct file *next;
};

struct definition {
	int lineno;
	String *file_name;	/*should be specify, because it's maybe in included file*/
	String *return_value;	/*some language do not have to specify return type, so return_value->buffer can be empty string*/
	String *function_name;
	String *args_list;
	struct definition *next;
	struct invocation *invocation_list;
};

struct invocation {
	int lineno;
	String *function_name;
	String *pars_list;
	struct invocation *next;
};

extern struct file * file_entry_init(char *);
extern struct definition * definition_entry_init(int, char *, char *, char *, char *);
extern struct invocation * invocation_entry_init(int, char *, char *);
extern int add_invocation(struct definition *, struct invocation *);
extern int add_definition(struct file *, struct definition *);
#endif /*PARSE_H*/
