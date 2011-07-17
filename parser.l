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
 * sometimes function name matches '\n', use some function to trim yytext.
 * couldn't parse nested function invocation like foo(bar()). Is this necessary? just to show user some function invoke foo(bar()) and bar()?
 * sholud match string constant? maybe there would be a string contains function definition.
 */
#include "string.h"
#include "hash.h"
#include <string.h>
int function_definition = 0;
int function_invocation = 0;
int comment = 0;
int typedefed = 0;

char *function_return_type = NULL;
char *function_name = NULL;	//this will be used to temporarily store definition function name, which can be used to finish whole function definition
char *cur_function_name = NULL;	//this svaed completely matched definition function name
char *function_args_list = NULL;
char *invocation_function_name = NULL;
char *function_pars_list = NULL;
char *type = NULL;
char *def = NULL;

struct hash_table *type_table;

/*track include file*/
struct file_stack {
	struct file_stack *prev;
	char *filename;
	int lineno;
	YY_BUFFER_STATE bs;
	FILE *f;
} *curbs = NULL;

char *curfilename;

int read_new_file(char *);
int pop_file();
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
	function_return_type = strdup(yytext);
}

(static{WS}|extern{WS})(inline)?	{
	/*FIEMX this should be saved*/
	BEGIN(LOOKING_RETURN_TYPE);/*only match typedefed type*/
}

(inline)	{
	/*FIEMX this should be saved*/
	BEGIN(LOOKING_RETURN_TYPE);/*only match typedefed type*/
}

<LOOKING_RETURN_TYPE>{WS}	{/*skip white space*/}
<LOOKING_RETURN_TYPE>{IDENTIFIER}{POINTER} {
	if (is_defined_type(type_table, yytext)){
		BEGIN(LOOKING_FUNCTION_NAME);
		function_return_type = strdup(yytext);
	}
}
<LOOKING_RETURN_TYPE>.	{ unput(*yytext);BEGIN(INITIAL);}

<LOOKING_FUNCTION_NAME>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_NAME>{IDENTIFIER}	{
	BEGIN(LOOKING_FUNCTION_ARGS);
	free(function_name);
	function_name = strdup(yytext);
}
<LOOKING_FUNCTION_NAME>. {
	unput(*yytext);
	BEGIN(INITIAL);
	free(function_return_type);
	function_return_type = NULL;
}

<LOOKING_FUNCTION_ARGS>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_ARGS>{PARS_LIST}	{
	BEGIN(LOOKING_FUNCTION_BODY);
	function_args_list = strdup(yytext);
}
<LOOKING_FUNCTION_ARGS>.	{
	unput(*yytext);
	BEGIN(INITIAL);
	free(function_return_type);
	function_return_type = NULL;
	free(function_name);
	function_name = NULL;
}

<LOOKING_FUNCTION_BODY>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_BODY>"{"	{
	/* find "{" is to exclude some function declare, and only in function body there will be function invocation*/
	free(cur_function_name);
	cur_function_name = strdup(function_name);
	printf("%s:%3d definition which is '%s %s %s'\n", curbs->filename, yylineno, function_return_type, cur_function_name, function_args_list);
	function_definition++;
	free(function_return_type);
	function_return_type = NULL;
	free(function_name);
	function_name = NULL;
	free(function_args_list);
	function_args_list = NULL;
	BEGIN(INITIAL);
}
<LOOKING_FUNCTION_BODY>.	{
	unput(*yytext);
	BEGIN(INITIAL);
	free(function_return_type);
	function_return_type = NULL;
	free(function_name);
	function_name = NULL;
	free(function_args_list);
	function_args_list = NULL;
}




"typedef"	{
	BEGIN(LOOKING_VAR_TYPE);
}

<LOOKING_VAR_TYPE>{WS}	{ /*skip white space*/ }
<LOOKING_VAR_TYPE>(void|{INT_TYPE}|{FLOAT_TYPE}){POINTER}	{
	BEGIN(LOOKING_IDENTIFIER);
	type = strdup(yytext);
}
<LOOKING_VAR_TYPE>{STRUCT_TYPE}	{
	BEGIN(LOOKING_STRUCT_BODY_START);
	type = strdup(yytext);
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
	def = strdup(yytext);
	BEGIN(LOOKING_TYPEDEF_END);
}
<LOOKING_STRUCT_BODY_START>.	{ BEGIN(INITIAL);free(type); }

<LOOKING_STRUCT_BODY_END>"}"	{ BEGIN(LOOKING_IDENTIFIER); }
<LOOKING_STRUCT_BODY_END>{WS}|.	{ /*do nothing*/}

<LOOKING_IDENTIFIER>{WS}	{ /*skip white space*/ }
<LOOKING_IDENTIFIER>{IDENTIFIER}	{
	BEGIN(LOOKING_TYPEDEF_END);
	def = strdup(yytext);
}
<LOOKING_IDENTIFIER>.	{ BEGIN(INITIAL); free(type); }

<LOOKING_TYPEDEF_END>{WS}	{ /*skip white space*/ }
<LOOKING_TYPEDEF_END>";"	{
	printf("%s:%3d find whole typedef definition which is 'typedef %s %s'\n", curbs->filename, yylineno, type, def);
	insert_into_hash_table(type_table, def);
	typedefed++;
	free(type);
	free(def);
	BEGIN(INITIAL);
}
<LOOKING_TYPEDEF_END>.	{
	unput(*yytext);
	BEGIN(INITIAL);
	free(type);
	free(def);
}








{IDENTIFIER}	{
	if (is_defined_type(type_table, yytext)){
		function_return_type = strdup(yytext);
		BEGIN(LOOKING_FUNCTION_NAME);	/*this maybe typedefed return type*/
	} else{
		invocation_function_name = strdup(yytext);
		BEGIN(LOOKING_ARGS_LIST);	/*this maybe function name*/
	}
}
{IDENTIFIER}{POINTER}	{
	/*this maybe typedefed pointer which is return type*/
	function_return_type = strdup(yytext);
	if (is_defined_type(type_table, yytext))
		BEGIN(LOOKING_FUNCTION_NAME);
}

<LOOKING_ARGS_LIST>{WS}	{/*skip white space*/}
<LOOKING_ARGS_LIST>"("	{
	/*those code is to avoid nested parentheses*/
	int nested = 1;
	char temp = 0;
	String *args_list = string_init(yytext);
	for (; (temp = input()) && temp != EOF ; string_add(args_list, temp)){
		if (temp == '('){
			nested++;
		} else if ( temp == ')'){
			nested--;
		}
		if (nested == 0){
			string_add(args_list, temp);
			break;
		}
	}
	if (temp == EOF){
		fprintf(stderr, "fatal error in source code, unfinished\n");
		exit(1);
	}
	function_pars_list = strdup(args_list->buffer);
	string_free(args_list);
	BEGIN(LOOKING_INVOCATION_END);
}
<LOOKING_ARGS_LIST>.	{
	unput(*yytext);
	BEGIN(INITIAL);
	free(invocation_function_name);
	invocation_function_name = NULL;
}

<LOOKING_INVOCATION_END>{WS}	{/*skip white space*/}
<LOOKING_INVOCATION_END>[^{]	{
	BEGIN(INITIAL);
	function_invocation++;
	printf("%s:%3d in function '%s' which invoke '%s %s'\n", curbs->filename, yylineno, cur_function_name,  invocation_function_name, function_pars_list);
	free(invocation_function_name);
	invocation_function_name = NULL;
	free(function_pars_list);
}
<LOOKING_INVOCATION_END>.	{
	unput(*yytext);
	BEGIN(INITIAL);
	free(invocation_function_name);
	invocation_function_name = NULL;
	free(function_pars_list);
	function_pars_list = NULL;
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


int main(int argc, char *argv[]){
	read_new_file(argv[1]);
	type_table = init_hash_table();
	yylex();
	printf("comment %d\tfunction_definition %d\tfunction_invocation %d\ttypedefed %d\n", comment, function_definition, function_invocation, typedefed);
}
