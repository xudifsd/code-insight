#ifndef GENERATOR_H
#define GENERATOR_H
#include "cJSON.h"

extern cJSON * interpret_invocation(struct invocation *);
extern cJSON * interpret_definition(struct definition *);
extern cJSON * interpret_file(struct file *);
extern char * generate(struct file *);
#endif /*GENERATOR_H*/
