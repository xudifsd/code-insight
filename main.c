#include "hash.h"

int main(int argc, char *argv[]){
	int i;
	for (i = 1; i < argc; i++){
		scan_c(argv[i]);	/*only handle C language right now*/
	}
}
