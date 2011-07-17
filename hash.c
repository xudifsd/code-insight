#include "hash.h"
#include "string.h"
#include <malloc.h>
#include <string.h>

/**
 * hash.c used to save all typedefed variable type,
 * we do this because we want to find function
 * definition which returns typedefed type instead
 * of builtin type. For example we want to pick up
 * those code:
 *
 * typedef struct foo {
 * 		int foo1;
 * 		char bar1;
 * } bar;
 * bar function_name (int foo1, char bar1){
 * 		.....
 * 	}
 * */

struct hash_table * init_hash_table(){
	int i;
	struct hash_table *p;
	struct hash_table * rtn = (struct hash_table *)malloc((sizeof(struct hash_table)) * (26*2+1));
	/*name's range is [a-zA-Z_]*/
	for (i = 0, p = rtn; i < 26; i++, p++){
		p->name = 'A' + i;
		p->head = NULL;
	}
	p->name = '_';
	p->head = NULL;
	p++;
	for ( i = 0; i < 26; i++, p++){
		p->name = 'a' + i;
		p->head = NULL;
	}
	return rtn;
}

int insert_into_hash_table(struct hash_table *hash_table, char *type_name){
	/**
	 * we do not check whether it's already exist in hash_table,
	 * return 1 if insert successfully, 0 if not.
	 * */
	int target = *type_name;
	int pos;

	struct hash_entry * new_entry = (struct hash_entry *)malloc(sizeof(struct hash_entry));	//create new entry firstly
	new_entry->type_name = string_init(type_name);
	new_entry->next = NULL;

	if ((target - 'A' <= 25) && (target - 'A' >= 0)){
		pos = target - 'A';
	} else if (target == '_'){
		pos = 26;
	} else if ((target - 'a' <= 25) && (target - 'a' >= 0)){
		pos = 27 + target - 'a';
	} else {
		//fprintf(stderr, "hash.c debug : wrong type_name, it's not [a-zA-Z_]\n");
		return 0;
	}
	struct hash_entry *list_head = (hash_table + pos)->head;
	struct hash_entry *p = list_head;
	if (p == NULL){
		(hash_table + pos)->head = new_entry;
		return 1;
	}
	for (p = list_head ; p->next != NULL; p = p->next);	//if there already have, then list them
		/*Nothing here*/
	p->next = new_entry;
	return 1;
}

int is_defined_type(struct hash_table *hash_table, char *type_name){
	/**
	 * This function should treat type_name more generous,
	 * which means other can invoke this function with type's
	 * pointer format, for example, there are a typedefed
	 * type whose name is 'foo', if other invoke this function
	 * with 'foo *' even with 'foo **', this function also
	 * return 1.
	 * */
	char *universal_type_name = strdup(type_name);
	int i;
	for (i = 0; universal_type_name[i] != '\0'; i++){
		if ( universal_type_name[i] == ' ' ||
				universal_type_name[i] == '\t' ||
				universal_type_name[i] == '\n'){
			universal_type_name[i] = '\0';
			break;
		}
	}
	int target = *universal_type_name;
	int pos;

	if ((target - 'A' <= 25) && (target - 'A' >= 0)){
		pos = target - 'A';
	} else if (target == '_'){
		pos = 26;
	} else if ((target - 'a' <= 25) && (target - 'a' >= 0)){
		pos = 27 + target - 'a';
	} else {
		//fprintf(stderr, "hash.c debug : wrong type_name, it's not [a-zA-Z_]\n");
		free(universal_type_name);
		return 0;
	}
	struct hash_entry *list_head = (hash_table + pos)->head;
	struct hash_entry *p = list_head;
	if (p == NULL){
		free(universal_type_name);
		return 0;
	}
	for (p = list_head ; p != NULL; p = p->next){
		if (!strcmp(p->type_name->buffer, universal_type_name)){
			free(universal_type_name);
			return 1;
		}
	}
	free(universal_type_name);
	return 0;
}
