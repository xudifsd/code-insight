#include <stdio.h>
#include <stdlib.h>
#include "cJSON.h"
#include "entry.h"

/**
 * usage of cJSON please read cJSON-README.
 * this file is used to translate struct in c into JSON in js,
 * so that we can using the data we collected from source code
 * to display in html
 * */

cJSON * interpret_invocation(struct invocation *invocation, char *definition_name){
	/*definition_name is the name of function which invoke invocation*/
	cJSON * rtn = cJSON_CreateObject();
	cJSON_AddNumberToObject(rtn, "lineno", invocation->lineno);
	cJSON_AddStringToObject(rtn, "function_name", invocation->function_name->buffer);
	cJSON_AddStringToObject(rtn, "definition_name", definition_name);
	cJSON_AddStringToObject(rtn, "pars_list", invocation->pars_list->buffer);
	return rtn;
}

cJSON * interpret_definition(struct definition *definition){
	cJSON *rtn = cJSON_CreateObject();
	cJSON_AddNumberToObject(rtn, "lineno", definition->lineno);
	cJSON_AddStringToObject(rtn, "file_name", definition->file_name->buffer);
	cJSON_AddStringToObject(rtn, "return_value", definition->return_value->buffer);
	cJSON_AddStringToObject(rtn, "function_name", definition->function_name->buffer);
	cJSON_AddStringToObject(rtn, "args_list", definition->args_list->buffer);
	cJSON *invocation_list = cJSON_CreateArray();
	cJSON_AddItemToObject(rtn, "invocation_list", invocation_list);
	struct invocation *p = definition->invocation_list;
	if (p == NULL){
		return rtn;
	} else {
		while (p != NULL){
			cJSON_AddItemToArray(invocation_list, interpret_invocation(p, definition->function_name->buffer));
			p = p->next;
		}
		return rtn;
	}
}

cJSON * interpret_file(struct file * file){
	cJSON *rtn = cJSON_CreateObject();
	cJSON_AddStringToObject(rtn, "file_name", file->filename->buffer);
	/*should save type_table?*/
	cJSON * definition_list = cJSON_CreateArray();
	cJSON_AddItemToObject(rtn, "definition_list", definition_list);
	struct definition *p = file->definition_list;
	if (p == NULL){
		return rtn;
	} else {
		while (p != NULL){
			cJSON_AddItemToArray(definition_list, interpret_definition(p));
			p = p->next;
		}
		return rtn;
	}
}

char * interpret(struct file *start){
	cJSON *rtn = cJSON_CreateArray();
	struct file *p = start;
	while(p != NULL){
		cJSON_AddItemToArray(rtn, interpret_file(p));
		p = p->next;
	}
	return cJSON_Print(rtn);
}
