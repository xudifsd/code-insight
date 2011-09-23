#include <stdio.h>
#include "entry.h"

static void definition_to_dot(FILE *stream, const struct definition *definition, const char *filename){
	struct invocation *invocation = definition->invocation_list;
	while (invocation != NULL){
		fprintf(stream, "\t\"%s:%s\"->\"%s:%s\"\n", filename, definition->function_name->buffer, filename, invocation->function_name->buffer);
		invocation = invocation->next;
	}
}

static void file_to_dot(FILE *stream, const struct file *file){
	struct definition *definition = file->definition_list;
	while (definition != NULL){
		definition_to_dot(stream, definition, file->filename->buffer);
		definition = definition->next;
	}
}

void to_dot(FILE *stream, const struct file *head){
	struct file *filep = head;
	fprintf(stream, "digraph G{");
	while (filep != NULL){
		file_to_dot(stream, filep);
		filep = filep->next;
	}
	fprintf(stream, "}");
}
