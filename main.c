#include "entry.h"
#include "hash.h"

int main(int argc, char *argv[]){
	int i;
	struct file *head = NULL;
	for (i = 1; i < argc; i++){
		head = add_file(head, scan_c(argv[i]));	/*only handle C language right now*/
	}
}
