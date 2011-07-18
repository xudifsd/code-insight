#include "entry.h"
#include "hash.h"
#include "string.h"
#include <stdio.h>
#include <malloc.h>

struct file * file_entry_init(char *filename){
	struct file * rtn = (struct file *)malloc(sizeof(struct file));
	rtn->filename = string_init(filename);
	rtn->type_table = init_hash_table();
	rtn->definition_list = NULL;
	rtn->next = NULL;
	return rtn;
}

struct function_definition * definition_entry_init(int lineno, char *filename, char *return_value, char *function_name, char *args_list){
	struct function_definition *rtn = (struct function_definition *) malloc(sizeof(struct function_definition));
	rtn->lineno = lineno;
	rtn->file_name = string_init(filename);
	rtn->return_value = string_init(return_value);
	rtn->function_name = string_init(function_name);
	rtn->args_list = string_init(args_list);
	rtn->next = NULL;
	rtn->invocation_list = NULL;
	return rtn;
}

struct invoked_function * invocation_entry_init(int lineno, char *function_name, char *pars_list){
	struct invoked_function *rtn = (struct invoked_function *)malloc(sizeof(struct invoked_function));
	rtn->lineno = lineno;
	rtn->function_name = string_init(function_name);
	rtn->pars_list = string_init(pars_list);
	rtn->next = NULL;
	return rtn;
}

int add_invoked_function(struct function_definition *definition, struct invoked_function *invocation){
	/*FIXME should add error check*/
	struct invoked_function *p = definition->invocation_list;
	if (p == NULL){
		definition->invocation_list = invocation;
	} else{
		for (; p->next != NULL; p = p->next);
			/*skip to the last of list*/
		p->next = invocation;
	}
	return 1;
}

int add_function_definition(struct file * file_entry, struct function_definition *definition_entry){
	/*FIXME should add error check*/
	struct function_definition *p = file_entry->definition_list;
	if (p == NULL){
		file_entry->definition_list = definition_entry;
	} else {
		for (; p->next != NULL; p = p->next);
			/*skip to the last of list*/
		p->next = definition_entry;
	}
	return 1;
}

struct file * add_file(struct file *head, struct file *tail){
	struct file *p = head;
	if (p == NULL)
		return tail;
	for (; p->next != NULL; p = p->next);
		/*find tail*/
	p->next = tail;
	return head;
}
