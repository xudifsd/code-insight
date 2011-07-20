#include "entry.h"
#include "hash.h"
#include "interpreter.h"
#include "generator.h"

int main(int argc, char *argv[]){
	int i;
	struct file *head = NULL;
	for (i = 1; i < argc; i++){
		head = add_file(head, scan_c(argv[i]));	/*only handle C language right now*/
	}
	FILE * template = fopen("template.html", "r");
	FILE * out = fopen("code-insight.html", "w");
	fprintf(out, read_template(template), interpret(head));
}
