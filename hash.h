#include "string.h"

#ifndef HASH_H
#define HASH_H

struct hash_entry{
	String *type_name;
	struct hash_entry *next;	//for collision save
};

struct hash_table {
	/*use for hash_table array*/
	char name;	//Only save first character in name, namely [a-zA-Z_]
	struct hash_entry *head;
};

extern struct hash_table * init_hash_table();
extern int insert_into_hash_table(struct hash_table *, char *);
extern int is_defined_type(struct hash_table *, char *);
#endif //HASH_H
