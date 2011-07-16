%option noyywrap yylineno nodefault

%x LOOKING_FUNCTION_NAME
%x LOOKING_FUNCTION_ARGS
%x LOOKING_FUNCTION_BODY
%x LOOKING_ARGS_LIST
%x LOOKING_INVOCATION_END

WS ([ \t\n]+)
IDENTIFIER ([a-zA-Z_][a-zA-Z0-9_]*)

INT_TYPE ((signed{WS}|unsigned{WS})?(int|long({WS}(int|long))?|short({WS}int)?|char))
FLOAT_TYPE (float|(long{WS})?double)
STRUCT_TYPE (struct{WS}{IDENTIFIER})

RETURN_TYPE ((const{WS})?(void|{INT_TYPE}|{FLOAT_TYPE}|{STRUCT_TYPE})({WS}[*]{1,})?)
PARS_LIST "("([^)]|\n)*")"

%{
/*
 * TODO sometimes function matches '\n', use some function to trim yytext.
 * this code can't treat typedefed variable type in right way, maybe we should read included file and build a table contains all typedefed variable type.
 * couldn't parse nested function invocation like foo(bar()).
 * should sizeof treated as a function?
 */
#include "string.h"
#include <string.h>
int function_definition = 0;
int function_invocation = 0;
int comment = 0;

char *function_return_type = NULL;
char *function_name = NULL;
char *function_args_list = NULL;
char *invocation_function_name = NULL;
char *function_pars_list = NULL;
%}

%%

"/*"([^*]|[*]+[^/*]|\n)*"*/"	{ comment++; }
"//".*\n	{ comment++; }

(auto|break|case|continue|default|do|else|enum|for|goto|if|register|return|sizeof|switch|volatile|while)	{ /*skip some key word*/ }

(static{WS}|extern{WS})?{RETURN_TYPE}	{
	BEGIN(LOOKING_FUNCTION_NAME);
	function_return_type = strdup(yytext);
}

<LOOKING_FUNCTION_NAME>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_NAME>{IDENTIFIER}	{
	BEGIN(LOOKING_FUNCTION_ARGS);
	free(function_name);	//change function name state, this means in new function body
	function_name = strdup(yytext);
}
<LOOKING_FUNCTION_NAME>. {
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
	BEGIN(INITIAL);
	free(function_return_type);
	function_return_type = NULL;
	free(function_name);
	function_name = NULL;
}

<LOOKING_FUNCTION_BODY>{WS}	{/*skip white space*/}
<LOOKING_FUNCTION_BODY>"{"	{
	/* find "{" is to exclude some function declare, and only in function body there will be function invocation*/
	printf("%4d definition which is '%s %s %s'\n", yylineno, function_return_type, function_name, function_args_list);
	function_definition++;
	free(function_return_type);
	function_return_type = NULL;
	//free(function_name);	//shouldn't be actived, because invocation need function_name to determin which function it belongs to
	//function_name = NULL;
	free(function_args_list);
	function_args_list = NULL;
	BEGIN(INITIAL);
}
<LOOKING_FUNCTION_BODY>.	{
	BEGIN(INITIAL);
	free(function_return_type);
	function_return_type = NULL;
	free(function_name);
	function_name = NULL;
	free(function_args_list);
	function_args_list = NULL;
}

{IDENTIFIER}	{
	BEGIN(LOOKING_ARGS_LIST);	/*this maybe function name*/
	invocation_function_name = strdup(yytext);
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
<LOOKING_ARGS_LIST>.	{ BEGIN(INITIAL);free(invocation_function_name);invocation_function_name = NULL; }

<LOOKING_INVOCATION_END>{WS}	{/*skip white space*/}
<LOOKING_INVOCATION_END>[^{]	{
	BEGIN(INITIAL);
	function_invocation++;
	printf("%4d in function '%s' which invoke '%s %s'\n", yylineno,function_name,  invocation_function_name, function_pars_list);
	free(invocation_function_name);
	invocation_function_name = NULL;
	free(function_pars_list);
}
<LOOKING_INVOCATION_END>.	{
	BEGIN(INITIAL);
	free(invocation_function_name);
	invocation_function_name = NULL;
	free(function_pars_list);
	function_pars_list = NULL;
}

.|\n {/*do nothing*/}

%%

int main(){
	yylex();
	printf("comment %d\tfunction_definition %d\tfunction_invocation %d\n", comment, function_definition, function_invocation);
}
