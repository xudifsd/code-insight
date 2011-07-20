#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include "generator.h"

char * read_template(FILE *stream){
	char *rtn = (char *)malloc(sizeof(char) * TEMPLATE_BUF_SIZE);
	char c;
	int i = 0;
	memset(rtn, 0, sizeof(char) * TEMPLATE_BUF_SIZE);
	while( (c = fgetc(stream)) != EOF){
		rtn[i] = c;
		i++;
	}
	return rtn;
}
