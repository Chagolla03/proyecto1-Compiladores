D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%{
#include <stdio.h>
#include <string.h>
#include "y.tab.h"

void count();
void comment();
enum {
	VOIDVAL = 0,
	CHARVAL,
	INTVAL,
	DOUBLEVAL
};
char buffer;
int bufsize;
int column = 0;
int lineno = 0;
%}
%x INCHAR
%option noyywrap

%%
"/*"			{ comment(); }
^#.*             ;
"auto"			{ count(); return(AUTO); }
"break"			{ count(); return(BREAK); }
"case"			{ count(); return(CASE); }
"char"			{ count(); return(CHAR); }
"const"			{ count(); return(CONST); }
"continue"		{ count(); return(CONTINUE); }
"default"		{ count(); return(DEFAULT); }
"do"			{ count(); return(DO); }
"double"		{ count(); return(DOUBLE); }
"else"			{ count(); return(ELSE); }
"enum"			{ count(); return(ENUM); }
"extern"		{ count(); return(EXTERN); }
"float"			{ count(); return(FLOAT); }
"for"			{ count(); return(FOR); }
"goto"			{ count(); return(GOTO); }
"if"			{ count(); return(IF); }
"int"			{ count(); return(INT); }
"long"			{ count(); return(LONG); }
"register"		{ count(); return(REGISTER); }
"return"		{ count(); return(RETURN); }
"short"			{ count(); return(SHORT); }
"signed"		{ count(); return(SIGNED); }
"sizeof"		{ count(); return(SIZEOF); }
"static"		{ count(); return(STATIC); }
"struct"		{ count(); return(STRUCT); }
"switch"		{ count(); return(SWITCH); }
"typedef"		{ count(); return(TYPEDEF); }
"union"			{ count(); return(UNION); }
"unsigned"		{ count(); return(UNSIGNED); }
"void"			{ count(); return(VOID); }
"volatile"		{ count(); return(VOLATILE); }
"while"			{ count(); return(WHILE); }

{L}({L}|{D})*			{ count(); 
						  	yylval.name = strdup(yytext);
							return IDENTIFIER; 
						}

0[xX]{H}+{IS}?			{ count(); 
							yylval.ival = strtol(yytext, NULL, 16);
							yylval.valtype = INTVAL;
							return(CONSTANT); 
						}

0{D}+{IS}?				{ count(); 
							yylval.ival = strtol(yytext, NULL, 8);
							yylval.valtype = INTVAL;
							return(CONSTANT); 
						}

{D}+{IS}?				{ count(); 
							yylval.ival = strtol(yytext, NULL, 10);
							yylval.valtype = INTVAL;
							return(CONSTANT); 
						}


L?'						{ count(); 
							BEGIN(INCHAR);
							buffer = '\0';
							bufsize = 0;
							
						}

<INCHAR>\\.				{
							if(bufsize>0){
								printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
								exit(2);
							}

							switch(yytext[1])
							{
							case 'a':
								buffer = '\a';
								break;
							case 'b':
								buffer = '\b';
								break;
							case 'f':
								buffer = '\f';
								break;
							case 'n':
								buffer = '\n';
								break;
							case 't':
								buffer = '\t';
								break;
							case 'r':
								buffer = '\r';
								break;
							case 'v':
								buffer = '\v';
								break;
							default:
								buffer = yytext[1];
								break;
							bufsize++;
							}
						}
<INCHAR>(\\[0-7]+) 	{//Para caracteres escritos en octal
							count();
							int val;
							if(bufsize>0){
							printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
							exit(2);
							}
							val = strtol(yytext + 1, NULL, 8);
							if(val > 255){
							printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
							exit(2);
							}
							buffer = val;
							bufsize++;
						}

<INCHAR>(\\x{H}+)   { //Para caracteres escritos en hexadecimal
							count();
							int val;
							if(bufsize>0){
							printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
							exit(2);
							}
							val = strtol(yytext + 2, NULL, 16);
							if(val > 255){
							printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
							exit(2);
							}
							buffer = val;
							bufsize++;
							}

<INCHAR>[^\\']+			{
							count();
							if(bufsize>0) {
							printf("ERROR: line %d column %d multibyte char constant!\n", lineno + 1, column);
							exit(2);
							}
							buffer = yytext[0];
							bufsize++;
						}

<INCHAR>'               {
							count();
							BEGIN(INITIAL);
							yylval.cval = buffer;
							yylval.valtype = CHARVAL;
							return(CONSTANT); 
						}

{D}+{E}{FS}?			{ count(); 
							yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							return(CONSTANT); 
						}


{D}*"."{D}+({E})?{FS}?	{ count();
							yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							return(CONSTANT); 
						}


{D}+"."{D}*({E})?{FS}?	{ count(); 
							yylval.dval = atof(yytext);
							yylval.valtype = DOUBLEVAL;
							return(CONSTANT); 
						}


L?\"(\\.|[^\\"])*\"	{ count(); 
						return(STRING_LITERAL); 
					}

"..."			{ count(); return(ELLIPSIS); }
">>="			{ count(); return(RIGHT_ASSIGN); }
"<<="			{ count(); return(LEFT_ASSIGN); }
"+="			{ count(); return(ADD_ASSIGN); }
"-="			{ count(); return(SUB_ASSIGN); }
"*="			{ count(); return(MUL_ASSIGN); }
"/="			{ count(); return(DIV_ASSIGN); }
"%="			{ count(); return(MOD_ASSIGN); }
"&="			{ count(); return(AND_ASSIGN); }
"^="			{ count(); return(XOR_ASSIGN); }
"|="			{ count(); return(OR_ASSIGN); }
">>"			{ count(); return(RIGHT_OP); }
"<<"			{ count(); return(LEFT_OP); }
"++"			{ count(); return(INC_OP); }
"--"			{ count(); return(DEC_OP); }
"->"			{ count(); return(PTR_OP); }
"&&"			{ count(); return(AND_OP); }
"||"			{ count(); return(OR_OP); }
"<="			{ count(); return(LE_OP); }
">="			{ count(); return(GE_OP); }
"=="			{ count(); return(EQ_OP); }
"!="			{ count(); return(NE_OP); }
";"			{ count(); return(';'); }
("{"|"<%")		{ count(); return('{'); }
("}"|"%>")		{ count(); return('}'); }
","			{ count(); return(','); }
":"			{ count(); return(':'); }
"="			{ count(); return('='); }
"("			{ count(); return('('); }
")"			{ count(); return(')'); }
("["|"<:")		{ count(); return('['); }
("]"|":>")		{ count(); return(']'); }
"."			{ count(); return('.'); }
"&"			{ count(); return('&'); }
"!"			{ count(); return('!'); }
"~"			{ count(); return('~'); }
"-"			{ count(); return('-'); }
"+"			{ count(); return('+'); }
"*"			{ count(); return('*'); }
"/"			{ count(); return('/'); }
"%"			{ count(); return('%'); }
"<"			{ count(); return('<'); }
">"			{ count(); return('>'); }
"^"			{ count(); return('^'); }
"|"			{ count(); return('|'); }
"?"			{ count(); return('?'); }

[ \t\v\n\f]		{ count(); }
.			{ /* ignore bad characters */ }

%%



void comment()
{
	char c, c1;

loop:
	while ((c = input()) != '*' && c != 0)
		;

	if ((c1 = input()) != '/' && c != 0)
	{
		unput(c1);
		goto loop;
	}

	if (c != 0)
		;
}

void count()
{
	int i;

	for (i = 0; yytext[i] != '\0'; i++)
		if (yytext[i] == '\n'){
			column = 0;
			lineno++;
		}
			
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			column++;

	;
}


char * tokens[] = {	
	"AUTO",
	"BREAK",
	"CASE",
	"CHAR",
	"CONST",
	"CONTINUE",
	"DEFAULT",
	"DO",
	"DOUBLE",
	"ELSE",
	"ENUM",
	"EXTERN",
	"FLOAT",
	"FOR",
	"GOTO",
	"IF",
	"INT",
	"LONG",
	"REGISTER",
	"RETURN",
	"SHORT",
	"SIGNED",
	"SIZEOF",
	"STATIC",
	"STRUCT",
	"SWITCH",
	"TYPEDEF",
	"UNION",
	"UNSIGNED",
	"VOID",
	"VOLATILE",
	"WHILE",
    "IDENTIFIER",
	"CONSTANT",
	"STRING_LITERAL",
	"ELLIPSIS",
	"RIGHT_ASSIGN",
	"LEFT_ASSIGN",
	"ADD_ASSIGN",
	"SUB_ASSIGN",
	"MUL_ASSIGN",
	"DIV_ASSIGN",
	"MOD_ASSIGN",
	"AND_ASSIGN",
	"XOR_ASSIGN",
	"OR_ASSIGN",
	"RIGHT_OP",
	"LEFT_OP",
	"INC_OP",
	"DEC_OP",
	"PTR_OP",
	"AND_OP",
	"OR_OP",
	"LE_OP",
	"GE_OP",
	"EQ_OP",
	"NE_OP"};

void print_token(int c)
{
	if(c<256)
		printf("<%c>", c);
	else
		{
			switch(c) {
				case CONSTANT:
					switch(yylval.valtype){
						case INTVAL:
							printf("<%s, %d>", tokens[c-AUTO], yylval.ival);
							break;
						case DOUBLEVAL:
							printf("<%s, %g>", tokens[c-AUTO], yylval.dval);
							break;
						case CHARVAL:
							printf("<%s, \'\\x%02x\'>", tokens[c-AUTO], (unsigned char)yylval.cval);
							break;
					}
					break;
				case IDENTIFIER:
					printf("<%s, \"%s\">", tokens[c-AUTO], yylval.name);
					break;
				case STRING_LITERAL:
					printf("<%s, \"%s\">", tokens[c-AUTO], yylval.sval);
					break;
				default:
					printf("<%s>", tokens[c-AUTO]);
					break;
			}
		}
}



int main (int argc, char *argv[]){
	int c;
	if(argc<2){
		printf("Uso %s archivo\n", argv[0]);
		exit(0);
	}
	yyin = fopen(argv[1], "rt");
	while((c = yylex()) != 0){
		/*printf("[%d]", c);*/
		print_token(c);
	}
	printf("\n");

	return 0;
}


