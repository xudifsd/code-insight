#ifndef INTERPRETER_H
#define INTERPRETER_H
#include "cJSON.h"

extern cJSON * interpret_invocation(struct invocation *);
extern cJSON * interpret_definition(struct definition *);
extern cJSON * interpret_file(struct file *);
extern char * interpret(struct file *);
#endif /*INTERPRETER_H*/
