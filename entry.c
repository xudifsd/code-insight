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

struct definition * definition_entry_init(int lineno, char *filename, char *return_value, char *function_name, char *args_list){
	struct definition *rtn = (struct definition *) malloc(sizeof(struct definition));
	rtn->lineno = lineno;
	rtn->file_name = string_init(filename);
	rtn->return_value = string_init(return_value);
	rtn->function_name = string_init(function_name);
	rtn->args_list = string_init(args_list);
	rtn->next = NULL;
	rtn->invocation_list = NULL;
	return rtn;
}

struct invocation * invocation_entry_init(int lineno, char *function_name, char *pars_list){
	struct invocation *rtn = (struct invocation *)malloc(sizeof(struct invocation));
	rtn->lineno = lineno;
	rtn->function_name = string_init(function_name);
	rtn->pars_list = string_init(pars_list);
	rtn->next = NULL;
	return rtn;
}

int add_invocation(struct definition *definition, struct invocation *invocation){
	/*FIXME should add error check*/
	struct invocation *p = definition->invocation_list;
	if (p == NULL){
		definition->invocation_list = invocation;
	} else{
		for (; p->next != NULL; p = p->next);
			/*skip to the last of list*/
		p->next = invocation;
	}
	return 1;
}

int add_definition(struct file * file_entry, struct definition *definition_entry){
	/*FIXME should add error check*/
	struct definition *p = file_entry->definition_list;
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
