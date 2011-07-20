%option noyywrap yylineno nodefault

%x IFILE
%x LOOKING_RETURN_TYPE
%x LOOKING_FUNCTION_NAME
%x LOOKING_FUNCTION_ARGS
%x LOOKING_FUNCTION_BODY
%x LOOKING_ARGS_LIST
%x LOOKING_INVOCATION_END

%x LOOKING_VAR_TYPE
%x LOOKING_IDENTIFIER
%x LOOKING_STRUCT_BODY_START
%x LOOKING_STRUCT_BODY_END
%x LOOKING_TYPEDEF_END

WS (([ \t\n]+)|{COMMENT})
IDENTIFIER ([a-zA-Z_][a-zA-Z0-9_]*)

INT_TYPE ((signed{WS}|unsigned{WS})?(int|long({WS}(int|long))?|short({WS}int)?|char))
FLOAT_TYPE (float|(long{WS})?double)
STRUCT_TYPE (struct{WS}{IDENTIFIER})
POINTER (({WS}[*]{1,})?)

VAR_TYPE ((void|{INT_TYPE}|{FLOAT_TYPE}|{STRUCT_TYPE}){POINTER})
RETURN_TYPE ((const{WS})?{VAR_TYPE})
PARS_LIST "("([^)]|\n)*")"

COMMENT (("/*"([^*]|[*]+[^/*]|\n)*"*/")|("//".*\n))
%{
/**
 * TODO
 * add some builtin variable type support like size_t.
 * sometimes function name matches '\n', use some function to trim yytext.
 * couldn't parse nested function invocation like foo(bar()). Is this necessary? just to show user some function invoke foo(bar()) and bar()?
 * sholud match string constant? maybe there would be a string contains function definition.
 */
#include <string.h>
#include "entry.h"
#include "hash.h"
#include "string.h"

/*track include file*/
struct file_stack {
	struct file_stack *prev;
	char *filename;
	int lineno;
	YY_BUFFER_STATE bs;
	FILE *f;
} *curbs = NULL;

int function_definition = 0;
int function_invocation = 0;
int comment = 0;
int typedefed = 0;

String *function_return_type = NULL;
String *function_name = NULL;	/*this will be used to temporarily store definition function name, which can be used to finish whole function definition*/
String *function_args_list = NULL;

struct file * init_file = NULL;
struct definition *cur_function = NULL;	/*in which function's body*/
struct hash_table *type_table = NULL;

String *invocation_function_name = NULL;
String *function_pars_list = NULL;

String *type = NULL;	/*this hold "typedef foo bar"'s foo*/
String *def = NULL;	/*this hold "typedef foo bar"'s bar*/

int read_new_file(char *);
int pop_file();

char *curfilename;	/*this saved included file's name*/

%}

%%

"#"[ \t]*"define".*\n	{ /*we don't like #define*/ }
"#"[ \t]*"include"[ \t]*[\"]	{ BEGIN IFILE; }

<IFILE>[^ \t\n\"]+	{
	{
		int c;
		while (( c = input()) && c != '\n');	/*eat rest word, we don't check the finish quote, it's not our business, it's compiler's duty*/
	}
	if (!read_new_file(yytext)){
		fprintf(stderr, "can't read from %s\n", yytext);
		//yyterminate();
	}
	BEGIN(INITIAL);
}
<IFILE>.|\n	{
	unput(*yytext);
	fprintf(stderr, "%s:%3d bad include expression!\n", curbs->filename, yylineno);
	BEGIN(INITIAL);
}



{COMMENT}	{ comment++; }

(auto|break|case|continue|default|do|else|enum|for|goto|if|register|return|sizeof|switch|volatile|while)	{ /*skip some key word*/ }






(static{WS}|extern{WS})?(inline{WS})?{RETURN_TYPE}	{
	BEGIN(LOOKING_FUNCTION_NAME);
	string_replace(function_return_type, yytext);
}

(static{WS}|extern{WS})(inline)?	{
	/*FIEMX this should be saved*/
	BEGIN(LOOKING_RETURN_TYPE);/*only match typedefed type*/
	string_replace(function_return_type, yytext);
}

(inline)	{
	/*FIEMX this should be saved*/
	BEGIN(LOOKING_RETURN_TYPE);/*only match typedefed type*/
	string_replace(function_return_type, yytext);
}

<LOOKING_RETURN_TYPE>{WS}	{ string_append(function_return_type, yytext); }
<LOOKING_RETURN_TYPE>{IDENTIFIER}{POINTER} {
	if (is_defined_type(type_table, yytext)){
		BEGIN(LOOKING_FUNCTION_NAME);
		string_append(function_return_type, yytext);
	}
}
<LOOKING_RETURN_TYPE>.	{ unput(*yytext);BEGIN(INITIAL);}

<LOOKING_FUNCTION_NAME>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_NAME>{IDENTIFIER}	{
	BEGIN(LOOKING_FUNCTION_ARGS);
	string_replace(function_name, yytext);
}
<LOOKING_FUNCTION_NAME>. {
	unput(*yytext);
	BEGIN(INITIAL);
}

<LOOKING_FUNCTION_ARGS>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_ARGS>{PARS_LIST}	{
	BEGIN(LOOKING_FUNCTION_BODY);
	string_replace(function_args_list, yytext);
}
<LOOKING_FUNCTION_ARGS>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}

<LOOKING_FUNCTION_BODY>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_BODY>"{"	{
	/* find "{" is to exclude some function declare, and only in function body there will be function invocation*/
	cur_function = definition_entry_init(yylineno, curfilename, function_return_type->buffer, function_name->buffer, function_args_list->buffer);
	add_definition(init_file, cur_function);
	printf("%s:%3d definition which is '%s %s %s'\n", curbs->filename, yylineno, function_return_type->buffer, cur_function->function_name->buffer, function_args_list->buffer);
	function_definition++;
	BEGIN(INITIAL);
}
<LOOKING_FUNCTION_BODY>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}




"typedef"	{
	BEGIN(LOOKING_VAR_TYPE);
}

<LOOKING_VAR_TYPE>{WS}	{ /*skip white space*/ }
<LOOKING_VAR_TYPE>(void|{INT_TYPE}|{FLOAT_TYPE}){POINTER}	{
	BEGIN(LOOKING_IDENTIFIER);
	string_replace(type, yytext);
}
<LOOKING_VAR_TYPE>{STRUCT_TYPE}	{
	BEGIN(LOOKING_STRUCT_BODY_START);
	string_replace(type, yytext);
}
<LOOKING_VAR_TYPE>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}

<LOOKING_STRUCT_BODY_START>{WS}	{ /*skip white space*/}
<LOOKING_STRUCT_BODY_START>"{"	{
	/*this handle "typedef struct foo{int name;} bar;"*/
	BEGIN(LOOKING_STRUCT_BODY_END);
}
<LOOKING_STRUCT_BODY_START>{IDENTIFIER}	{
	/*this handle "typedef struct foo bar;"*/
	string_replace(def, yytext);
	BEGIN(LOOKING_TYPEDEF_END);
}
<LOOKING_STRUCT_BODY_START>.	{ BEGIN(INITIAL); }

<LOOKING_STRUCT_BODY_END>"}"	{ BEGIN(LOOKING_IDENTIFIER); }
<LOOKING_STRUCT_BODY_END>{WS}|.	{ /*do nothing*/}

<LOOKING_IDENTIFIER>{WS}	{ /*skip white space*/ }
<LOOKING_IDENTIFIER>{IDENTIFIER}	{
	BEGIN(LOOKING_TYPEDEF_END);
	string_replace(def, yytext);
}
<LOOKING_IDENTIFIER>.	{ BEGIN(INITIAL); }

<LOOKING_TYPEDEF_END>{WS}	{ /*skip white space*/ }
<LOOKING_TYPEDEF_END>";"	{
	printf("%s:%3d find whole typedef definition which is 'typedef %s %s'\n", curbs->filename, yylineno, type->buffer, def->buffer);
	insert_into_hash_table(type_table, def->buffer);
	typedefed++;
	BEGIN(INITIAL);
}
<LOOKING_TYPEDEF_END>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}








{IDENTIFIER}	{
	if (is_defined_type(type_table, yytext)){
		string_replace(function_return_type, yytext);
		BEGIN(LOOKING_FUNCTION_NAME);	/*this maybe typedefed return type*/
	} else{
		string_replace(invocation_function_name, yytext);
		BEGIN(LOOKING_ARGS_LIST);	/*this maybe function name*/
	}
}
{IDENTIFIER}{POINTER}	{
	/*this maybe typedefed pointer which is return type*/
	if (is_defined_type(type_table, yytext)){
		BEGIN(LOOKING_FUNCTION_NAME);
		string_replace(function_return_type, yytext);
	}
}

<LOOKING_ARGS_LIST>{WS}	{/*skip white space*/}
<LOOKING_ARGS_LIST>"("	{
	/*those code is to avoid nested parentheses*/
	int nested = 1;
	char temp = 0;
	string_replace(function_pars_list, "(");
	for (; (temp = input()) && temp != EOF ; string_add(function_pars_list, temp)){
		if (temp == '('){
			nested++;
		} else if ( temp == ')'){
			nested--;
		}
		if (nested == 0){
			string_add(function_pars_list, temp);
			break;
		}
	}
	if (temp == EOF){
		fprintf(stderr, "fatal error in source code, unfinished\n");
		exit(1);
	}
	BEGIN(LOOKING_INVOCATION_END);
}
<LOOKING_ARGS_LIST>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}

<LOOKING_INVOCATION_END>{WS}	{/*skip white space*/}
<LOOKING_INVOCATION_END>[^{]	{
	BEGIN(INITIAL);
	function_invocation++;
	if (cur_function == NULL){
		/*
		 * this means invoke function out of function definition,
		 * maybe this because our regex is not mature,solve this later.
		 * */
		printf("%s:%3d out of function definition invoke '%s %s'\n", curbs->filename, yylineno,  invocation_function_name->buffer, function_pars_list->buffer);
	} else{
		add_invocation(cur_function, invocation_entry_init(yylineno, invocation_function_name->buffer, function_pars_list->buffer));
		printf("%s:%3d in function '%s' which invoke '%s %s'\n", curbs->filename, yylineno, cur_function->function_name->buffer,  invocation_function_name->buffer, function_pars_list->buffer);
	}
}
<LOOKING_INVOCATION_END>.	{
	unput(*yytext);
	BEGIN(INITIAL);
}




<<EOF>>	{ if(!pop_file()) yyterminate(); }

.|\n {/**
		* maybe this will be a bug, imagine this
		* "+int foo();" '.' will match '+' and
		* other pattern will think rest is a
		* function invocation*/
}

%%

int read_new_file(char *name){
	FILE *f = fopen(name, "r");
	if (!f){
		perror(name);
		return 0;
	}

	struct file_stack *bs = (struct file_stack *)malloc(sizeof(struct file_stack));
	if (curbs)
		curbs->lineno = yylineno;
	bs->prev = curbs;

	bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
	bs->f = f;
	bs->filename = name;
	yy_switch_to_buffer(bs->bs);
	curbs = bs;
	yylineno = 1;
	curfilename = name;
	return 1;
}

int pop_file(){
	struct file_stack *bs = curbs;
	struct file_stack *prevbs;

	if (curbs == NULL)	return 0;

	fclose(bs->f);
	yy_delete_buffer(bs->bs);
	prevbs = bs->prev;
	free(bs);

	if (!prevbs) return 0;

	yy_switch_to_buffer(prevbs->bs);
	curbs = prevbs;
	yylineno = curbs->lineno;
	curfilename = curbs->filename;
	return 1;
}

void init(){
	/**
	 * Because flex do not execute 1st area's code when it's being invoked
	 * again, so we take flex's responsibility to init them everytimes.*/
	if (curbs != NULL){
		curbs = NULL;

		function_definition = 0;
		function_invocation = 0;
		comment = 0;
		typedefed = 0;

		string_replace(function_return_type, "");
		string_replace(function_name, "");
		string_replace(function_args_list, "");

		init_file = NULL;
		cur_function = NULL;
		type_table = NULL;

		string_replace(invocation_function_name, "");
		string_replace(function_pars_list, "");

		string_replace(type, "");
		string_replace(def, "");

		curfilename = NULL;
	} else {
		function_return_type = string_init("");
		function_name = string_init("");
		function_args_list = string_init("");

		invocation_function_name = string_init("");
		function_pars_list = string_init("");

		type = string_init("");
		def = string_init("");
	}

}
struct file *scan_c(char *filename){
	init();
	init_file = file_entry_init(filename);
	type_table = init_file->type_table;
	read_new_file(filename);
	yylex();
	printf("comment %d\tfunction_definition %d\tfunction_invocation %d\ttypedefed %d\n", comment, function_definition, function_invocation, typedefed);
	return init_file;
}
