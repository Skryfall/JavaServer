import ply.lex as lex

#Tokens del compilador
from src.logic.Master import Master

tokens = ['Number', 'Equals', 'Name', 'int', 'LeftParentesis', 'RightParentesis', 'Balloon', 'Semicolon', 'Coma',
          'Dow', 'Inc', 'Dec', 'Enddo', 'Begin', 'Game1', 'Finish', 'BeginParentesis', 'EndParentesis', 'Game2',
          'texto', 'LeftSquareBracket', 'RightSquareBracket', 'String', 'Random', 'FOR', 'times', 'using', 'FOREND',
          'Game3', 'Game4', 'TelaArana', 'ForAsignWord', 'DO', 'AsignWord', 'Object', 'FEnd', 'Comment']

master = Master()

#Asignacion de los tokens a indicadores, para que sean reconocidos por el parser
t_Equals = r'\='
t_LeftParentesis = r'\('
t_RightParentesis = r'\)'
t_BeginParentesis = r'\{'
t_EndParentesis = r'\}'
t_LeftSquareBracket = r'\['
t_RightSquareBracket = r'\]'
t_Semicolon = r';'
t_Coma = r','

def t_Comment(t):
    r'\//[a-zA-Z_0-9]*'
    master.setComment(True)
    pass

def t_Number(t):
    r'\d+'
    t.value = int(t.value)
    return t

def t_int(t):
    r'int'
    t.type = 'int'
    return t

def t_Object(t):
    r'Object'
    t.type = 'Object'
    return t

def t_AsignWord(t):
    r'AsignWord'
    t.type = 'AsignWord'
    return t

def t_DO(t):
    r'DO'
    t.type = 'DO'
    return t

def t_texto(t):
    r'texto'
    t.type = 'texto'
    return t

def t_TelaArana(t):
    r'TelaArana'
    t.type = 'TelaArana'
    return t

def t_FOREND(t):
    r'FOREND'
    t.type = 'FOREND'
    return t

def t_FEnd(t):
    r'FEnd'
    t.type = 'FEnd'
    return t

def t_ForAsignWord(t):
    r'ForAsignWord'
    t.type = 'ForAsignWord'
    return t

def t_FOR(t):
    r'FOR'
    t.type = 'FOR'
    return t

def t_times(t):
    r'times'
    t.type = 'times'
    return t

def t_using(t):
    r'using'
    t.type = 'using'
    return t

def t_Begin(t):
    r'Begin'
    t.type = 'Begin'
    return t

def t_Game1(t):
    r'Game1'
    t.type = 'Game1'
    return t

def t_Game2(t):
    r'Game2'
    t.type = 'Game2'
    return t

def t_Game3(t):
    r'Game3'
    t.type = 'Game3'
    return t

def t_Game4(t):
    r'Game4'
    t.type = 'Game4'
    return t

def t_Finish(t):
    r'Finish'
    t.type = 'Finish'
    return t

def t_Balloon(t):
    r'Balloon'
    t.type = 'Balloon'
    return t

def t_Dow(t):
    r'Dow'
    t.type = 'Dow'
    return t

def t_Inc(t):
    r'Inc'
    t.type = 'Inc'
    return t

def t_Dec(t):
    r'Dec'
    t.type = 'Dec'
    return t

def t_Enndo(t):
    r'Enddo'
    t.type = 'Enddo'
    return t

def t_Random(t):
    r'Random'
    t.type = 'Random'
    return t

def t_Name(t):
    r'[a-zA-Z_@&-][a-zA-Z_0-9@&-]*'
    t.type = 'Name'
    return t

def t_String(t):
    r'"[a-zA-Z_0-9]*"'
    t.type = 'String'
    return t

def t_newline(t):
    r'\n+'
    t.lexer.lineno += len(t.value)

t_ignore  = ' \t\n'

def t_error(t):
    print("Caracter ilegal '%s'" % t.value[0])
    t.lexer.skip(1)

lex.lex()
