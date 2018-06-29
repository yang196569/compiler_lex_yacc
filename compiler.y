%{

/*	Definition section */
/*	insert the C library and variables you need */

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
/*Extern variables that communicate with lex*/

extern int yylineno;
extern int yylex();
extern FILE *yyin;
void yyerror(char *);
FILE *file;




char intype[10];

char *tmpstring;


typedef struct node{
    char id[15];
    char type[10];
    int mode;  /*mutable, immutable*/
	int data;
    int index;
    char content[1000];
    struct node *next; 
}symbol_table;


char operator_table[20][50];
int operator_index=0;
//int *operator_ptr;
void push_operator(char* operator);
char* pop_operator();


char operand_table[20][50];
int operand_index=0;
//int *operand_ptr;
void push_operand(char *operand);
char* pop_operand();


struct node *table=0;
struct node *now;
struct node *tmp;

void create_symbol();								/*establish the symbol table structure*/
int insert_symbol(char* id, char *type,char* content);	/*Insert an undeclared ID in symbol table*/
int symbol_assign(char* id, int data);				/*Assign value to a declared ID in symbol table*/
char *lookup_symbol(char* id);						/*Confirm the ID exists in the symbol table*/
int dump_symbol();									/*List the ids and values of all data*/
int lookup_index(char* id);						/*Confirm the ID exists in the symbol table*/


void code(char *operation, char *d1,char *d2);
void emit(char *opcode, char *op1,char *op2);
void emit_label(int L);
void emit_comments(char *comment);

void emit_include();
void emit_prologue();
void emit_epilogue();
void emit_data_segment();
void emit_data_object(struct node *tmp);

void data_add(struct node *tmp); /* For function emit_data_object();*/


int symnum;		

int exist=1;									/*The number of the symbol*/
int indexnow=0;
int errornum=0;
/* Note that you should define the data structure of the symbol table yourself by any form */

%}

/* Token definition */
%token ADD SUB MUL DIV REM
%token LT LOE GT GOE EQUAL NEQ ASSIGN
%token LPAREN RPAREN LBRACK RBRACK COMMA SEMI
%token SQ DQ
%token CHAR CONST BOOL STRING INT IF ELSE WHILE READ PRINT PRINTLN MAIN FALSE TRUE
%token number ID String BOOL_VALUE CHAR_CONST



/* Type definition : 

	Define the type by %union{} to specify the type of token

*/
%union{
    char* identifier;
    int intVal;
    char charVal;
}

/* Type declaration : 
	
	Use %type to specify the type of token within < > 
	if the token or name of grammar rule will return value($$) 

*/
%type <identifier> PROGRAM PROG_BODY ID_LIST ID CONST_STMT LITERAL number String 
 CHAR_CONST BOOL_VALUE CONST_DCL CONST FACTOR ASSIGN ASSIGNMENT_STMT
 SIMPLE_EXPR

 


%%

/* Define your parser grammar rule and the rule action */

PROGRAM:    PROG_HDR       
       |    PROGRAM PROG_BODY       
       ;   

PROG_HDR:   MAIN LPAREN RPAREN  /* main() */
        ;

PROG_BODY:   LBRACK     {emit_prologue();}
         |   DCL_LIST STMT_LIST 
         |   RBRACK {emit_epilogue();} 
         ;

DCL_LIST:   DCL_STMT   DCL_LIST 
        |
        ;

DCL_STMT:   CONST_DCL   
        |   VAR_DCL  
        ;
/* CONSTANT PART*/
CONST_DCL:   CONST   CONST_LIST  SEMI         
        ;

CONST_LIST:   CONST_LIST COMMA  CONST_STMT  
          |   CONST_STMT 
          ;

CONST_STMT:   ID ASSIGN  ID {   
                                strcpy(intype,"const");
                                if(insert_symbol($1,intype,lookup_symbol($3))==-1){
                                    printf("Error when inserting variable to symbol table ===== %d line...1 \n",yylineno);  
                                    errornum++;}
                            }
          |   ID ASSIGN LITERAL {
                                    strcpy(intype,"const");
                                    if(insert_symbol($1,intype,$3)==-1){
                                        printf("Error when inserting variable to symbol table ===== %d line...2 \n",yylineno);
                                        errornum++;}
                                }
          ;

LITERAL:   number       {$$=$1;}
       |   String       {$$=$1;}
       |   CHAR_CONST   {$$=$1;}
       |   BOOL_VALUE   {$$=$1;}
       ;

VAR_DCL:   DATA_TYPE   ID_LIST SEMI
       ;

DATA_TYPE:   INT  {strcpy(intype,"int");}
         |   CHAR  {strcpy(intype,"char");}
         |   BOOL {strcpy(intype,"bool");}
         |   STRING   {strcpy(intype,"string");}
         ;

ID_LIST:   ID_LIST COMMA ID  {if(insert_symbol($3,intype,0)==-1){printf("Error when inserting variable to symbol table ===== %d line \n",yylineno);errornum++;}}
       |   ID {if(insert_symbol($1,intype,0)==-1){printf("Error when inserting variable to symbol table ===== %d line \n",yylineno);errornum++;}}
       ;




STMT_LIST:  STMT_LIST STATEMENT
         |
         ;

STATEMENT:  ASSIGNMENT_STMT  
         |  IO_STMT
         ;

ASSIGNMENT_STMT:    ID ASSIGN SIMPLE_EXPR   SEMI      {printf("ID is %s \t EXPR is %s\n",$1,$3);}     /*  ID = expression ;*/ /*push_operand($1);push_operator($2);code( pop_operator(), pop_operand(), pop_operand() );*/
               ;
IO_STMT:    READ LPAREN ID_LIST RPAREN SEMI           {printf("READ...\n");}     /*read  (  a1  )...*/
       |    PRINT LPAREN SIMPLE_EXPR RPAREN SEMI      {printf("PRINT...\n");}     /*print (  SIMPLE_EXPR  )...*/
       |    PRINTLN LPAREN SIMPLE_EXPR RPAREN SEMI    {printf("PRINT LINE...\n");}     /*println(SIMPLE_EXPR)...*/
       ;

SIMPLE_EXPR:    ADDITIVE_EXPR   REL_OP  ADDITIVE_EXPR
           |    ADDITIVE_EXPR
           ;

ADDITIVE_EXPR:  ADDITIVE_EXPR ADD_OP TERM
             |  TERM
             ;

TERM:   TERM MUL_OP FACTOR
    |   FACTOR
    ;

FACTOR: LPAREN  SIMPLE_EXPR RPAREN
      | ADD ID  {$$=lookup_symbol($2);}
      | SUB ID  {$$=lookup_symbol($2);}
      | ID      {$$=lookup_symbol($1);}
      | LITERAL {$$=$1;}
      ;
REL_OP: LOE | LT | GT | GOE | EQUAL | NEQ 
      ;

ADD_OP: ADD | SUB
      ;

MUL_OP: MUL | DIV | REM
      ;



%%
/*****************************************************************************************************/
int main(int argc, char** argv)
{
    yyin = fopen(argv[1],"r");
    yylineno = 1;
    symnum = 0;

    file = fopen("stage_test.asm","w"); 
    
    yyparse();
    
   
	printf("\nTotal lines : %d \n\n",yylineno);
	dump_symbol();
	
	
	
	fclose(file);
	printf("Generated: %s\n","stage_test.asm");
	
    return 0;
}
/**********************************************************************************/
void yyerror(char *s) {
    printf("%s on %d line \n", s , yylineno);
}


/*symbol create function*/
void create_symbol() {
    printf("Create a symbol table\n");
	table = malloc( sizeof( symbol_table));
    now=table;
}

/*symbol insert function*/
int insert_symbol(char* id, char *type,char* content) {
	if(table==0){
        create_symbol();
     	printf("ID is %s and type is %s and the content is %s \n",id,type,content);
        if(type!=NULL)
            strcpy(now -> type , type);
        strcpy(now -> id , id);
        if(content!=NULL)
            strcpy(now -> content , content);
        //now -> data = data;
        now -> next =NULL;
        now -> index=indexnow++;
        
        printf("Insert a symbol :%s\n",id);
        return 0;    
    }
    if(lookup_symbol(id)==NULL){
        now-> next = malloc( sizeof( symbol_table));
        now = now -> next;
        strcpy(now -> type , type);
        strcpy(now -> id , id);
        printf("ID is %s and type is %s and the content is %s \n",id,type,content); 
        if(content!=NULL)
            strcpy(now -> content , content);
        //now -> data = data;

        now -> next =NULL;
        now -> index=indexnow++;
        printf("Insert a symbol :%s\n",id);
        return 0;
    }
    else return -1;
}


/*symbol value lookup and check exist function*/
char *lookup_symbol(char* id){
	struct node *search=table;
    while(1){
        if(strcmp( search->id,id)==0)return search->content;
        else{
            if(search->next==NULL)return NULL;
            else search=search->next;    
        }
    }
}

/*symbol value assign function*/
int symbol_assign(char* id, int data) {
	struct node *search=table;
    while(1){
        if(strcmp( search->id,id)==0){
            search -> data = data;            
            return 0;
        }
        else{
            if(search->next==NULL)return 1;
            else search=search->next;    
        }
    }
}

int lookup_index(char* id){
	struct node *search=table;
    while(1){
        if(strcmp( search->id,id)==0)return search->index;
        else{
            if(search->next==NULL)return -1;
            else search=search->next;    
        }
    }
}

/*symbol dump function*/
int dump_symbol(){
	int i=1;
    if(table==0)return -1;
    printf("The symbol table dump :\n");
    struct node *pr=table;
    printf("ID      Type      Content\n");
    printf("%-8s%-10s%s\n",pr->id,pr->type,pr->content);
    while(pr->next!=NULL){
        pr=pr->next;
        printf("%-8s%-10s%s\n",pr->id,pr->type,pr->content);
    }
}








/*  ============    PRODUCE  OBJECT CODE   ============   */

void code(char *operation, char *d1, char *d2){
   /* switch(operation)
    {
        "prog_hdr":emit_prologue(); break;
        "prog_end":emit_epilogue(); break;
        default: printf("Something Wrong while generating object code...\n");
    }*/
}

void emit(char *opcode, char *op1, char *op2){
    fprintf(file,"\t %s",opcode);
    fprintf(file,"\t %s",op1);
    if(op2 != NULL){
        fprintf(file,"\t %s",op2);
    }
    fprintf(file,"\n");
    
}
void emit_label(int L){
    fprintf(file,"_L%4d: \n",L);
}

void emit_comments(char *comment){
    fprintf(file,"; %s \n",comment);
}



void emit_include(){
    fprintf(file,"INCLUDE       Irvine32.inc\n");
    fprintf(file,"INCLUDE       Irvine32.lib\n");
    fprintf(file,"INCLUDE       Kernel32.lib\n");
    fprintf(file,"INCLUDE       User32.inc\n");
}

void emit_prologue(){
    emit_include();
    fprintf(file,".STACK    2048\n");
    fprintf(file,".CODE     \n");
    fprintf(file," _main \t PROC \n");
}

void emit_epilogue(){
    fprintf(file,"\t exit \n");
    fprintf(file,"_main \t ENDP\n");
    emit_data_segment();
    fprintf(file,"\t END  main\n");
}

void emit_data_segment(){
    fprintf(file,".DATA \n");
    fprintf(file,"_SID DB \"VCC Ver. 1.0-A1\" \n");
    emit_data_object(tmp);
}

void emit_data_object(struct node *tmp){
    tmp = table;
    data_add(tmp);
    
    while(tmp->next != NULL){
        tmp = tmp->next;
        data_add(tmp);
    }
}




/* data object of function emit_data_object */
void data_add(struct node *tmp){
        /******CONST*******/
        if(strcmp( tmp->type,"const")==0){
            
            if(strcmp( tmp->content,"TRUE")==0){
                fprintf(file,"%-8s\t DB\t\t1\n",tmp->id);
            }
            else if(strcmp( tmp->content,"FALSE")==0){
                fprintf(file,"%-8s\t DB\t\t0\n",tmp->id);
            }
            
            else{
			
				if(tmp->content[0]=='"'){
					fprintf(file,"%-8s\t DD\t\t%s,0\n",tmp->id,tmp->content);
				}
				else{
					fprintf(file,"%-8s\t DD\t\t%s\n",tmp->id,tmp->content);  
				}
				
				
			}
        }
        /******INT*******/
        else if(strcmp( tmp->type,"int")==0){	
            fprintf(file,"%-8s\t DD\t\t0\n",tmp->id);
			//fprintf(file,"%-8s\t DD\t%s\n",tmp->id,tmp->content);
        }
        /******CHAR*******/
        else if(strcmp( tmp->type,"char")==0){
            fprintf(file,"%-8s\t DB\t\t''\n",tmp->id);
			//fprintf(file,"%-8s\t DB\t%s\n",tmp->id,tmp->content);
        }
        /******BOOL*******/
        else if(strcmp( tmp->type,"bool")==0){
            if(strcmp( tmp->content,"TRUE")==0){
                fprintf(file,"%-8s\t DB\t\t1\n",tmp->id);
            }
            else{
                fprintf(file,"%-8s\t DB\t\t0\n",tmp->id);
            }
        }
        /******STRING*******/
        else {
			
			fprintf(file,"%-8s\t DD\t\t0\n",tmp->id);
			
			
            //fprintf(file,"%-8s\t DD\t%s,0\n",tmp->id,tmp->content);
       		
	   }    
}

void push_operand(char* operand){
    strcpy(operand_table[operand_index],operand);
    operand_index++;
}
char* pop_operand(){
    operand_index--;
    char *tmp ;
    strcpy(tmp,operand_table[operand_index]);
    strcpy(operand_table[operand_index],NULL);
    return tmp;
}

void push_operator(char* operator){
    strcpy(operator_table[operator_index],operator);
    operator_index++;
}
char* pop_operator(){
    operator_index--;
    char *tmp;
    strcpy(tmp,operator_table[operator_index]);
    strcpy(operator_table[operator_index],NULL);
    return tmp;
    
}
