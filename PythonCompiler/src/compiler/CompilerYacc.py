import ply.yacc as yacc

from src.logic.BalloonGame import BalloonGame
from src.logic.FlagGame import FlagGame
from src.logic.SpiderWebGame import SpiderWebGame
from src.logic.ObjectGame import ObjectGame
from src.compiler.CompilerLex import tokens

balloonGame = BalloonGame()
flagGame = FlagGame()
spiderWebGame = SpiderWebGame()
objectGame = ObjectGame()

names = {}
currentGame = 1

precedence = (
    ()
)

def p_statement_main(p):
    """statement : Begin Game1 BeginParentesis initializer add game1 EndParentesis Game2 BeginParentesis initializer add game2 EndParentesis Game3 BeginParentesis initializer add game3 EndParentesis Game4 BeginParentesis initializer add game4 EndParentesis Finish Semicolon"""
    print(names)
    balloonGame.handleBalloonLogic()

def p_game1_start(p):
    'game1 : function'
    global currentGame
    currentGame = 2

def p_game2_start(p):
    'game2 : function'
    global currentGame
    currentGame = 3

def p_game3_start(p):
    'game3 : function'
    global currentGame
    currentGame = 4

def p_game4_start(p):
    'game4 : function'
    global currentGame
    currentGame = 1

def p_expression_number(p):
    "expression : Number"
    p[0] = p[1]

def p_expression_string(p):
    "expression : String"
    p[0] = p[1]

def p_expression_name(p):
    "expression : Name"
    try:
        p[0] = names[p[1]]
    except LookupError:
        print("Nombre indeterminado '%s'" % p[1])
        p[0] = 0

def p_initializer_assignOrCreate(p):
    """initializer : assign
                   | create
                   |"""

def p_assign_int(p):
    """assign : int Name Equals expression Semicolon
              | int Name Equals expression Semicolon assign
              | int Name Equals expression Semicolon create"""
    names[p[2]] = p[4]

def p_assign_empty(p):
    'assign : '

def p_create_textList(p):
    """create : texto LeftParentesis expression RightParentesis Name LeftSquareBracket expression RightSquareBracket Semicolon
              | texto LeftParentesis expression RightParentesis Name LeftSquareBracket expression RightSquareBracket Semicolon assign
              | texto LeftParentesis expression RightParentesis Name LeftSquareBracket expression RightSquareBracket Semicolon create"""
    array = [("string", p[3], p[7])]
    i = 0
    while i < p[7]:
        array.append("")
        i += 1
    names[p[5]] = array

def p_create_intList(p):
    """create : int Name LeftSquareBracket expression RightSquareBracket Semicolon
              | int Name LeftSquareBracket expression RightSquareBracket Semicolon assign
              | int Name LeftSquareBracket expression RightSquareBracket Semicolon create"""
    array = [(1, p[4])]
    i = 0
    while i < p[4]:
        array.append(0)
        i += 1
    names[p[2]] = array

def p_create_empty(p):
    'create : '

def p_add_toList(p):
    """add : Name LeftSquareBracket expression RightSquareBracket Equals expression Semicolon
           | Name LeftSquareBracket expression RightSquareBracket Equals expression Semicolon add"""
    array = names[p[1]][0]
    if isinstance(array[0], str) and isinstance(p[6], str) and len(p[6]) < array[1] + 3 and array[1] + 1 > p[3] > 0:
        names[p[1]][p[3]] = p[6]
    elif isinstance(array[0], int) and isinstance(p[6], int) and array[1] + 1 > p[3] > 0:
        names[p[1]][p[3]] = p[6]
    else:
        print("Error, no se pudo agregar a la lista")

def p_add_empty(p):
    'add : '

def p_function_printExpression(p):
    """function : expression
                | expression function"""
    print(p[1])

def p_function_dow(p):
    """function : Dow LeftParentesis expression RightParentesis function Enddo Semicolon
                | Dow LeftParentesis expression RightParentesis function Enddo Semicolon function"""
    if isinstance(p[3], int):
        if currentGame == 1:
            balloonGame.setRepetitions(p[3])
    else:
        print("Error, la funcion Dow solo recibe un numero")

def p_function_balloon(p):
    """function : Balloon LeftParentesis expression Coma expression RightParentesis Semicolon
                | Balloon LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        balloon(p[3], p[5])
    else:
        print("Error, la funcion Balloon solo recibe numeros")

def p_function_inc(p):
    """function : Inc LeftParentesis expression Coma expression RightParentesis Semicolon
                | Inc LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        inc(p[3], p[5])
    else:
        print("Error, la funcion Inc solo recibe numeros")

def p_function_dec(p):
    """function : Dec LeftParentesis expression Coma expression RightParentesis Semicolon
                | Dec LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        dec(p[3], p[5])
    else:
        print("Error, la funcion Dec solo recibe numeros")

def p_function_FORList(p):
    """function : FOR expression times using expression Random LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function FOREND Semicolon
                | FOR expression times using expression Random LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function FOREND Semicolon function"""
    if isinstance(p[2], int) and isinstance(p[5], list) and isinstance(p[8], list) and isinstance(p[10], int) and isinstance(p[12], int):
        flagGame.setHowManyRandoms(p[2])
        random(p[5][1:], p[8][1:], p[10], p[12])
    else:
        print("Error, para usar el FOR es necesario incluirle la cantidad de repeticiones, la lista y la funcion Random de 3 argumentos")

def p_function_random(p):
    """function : Random LeftParentesis expression Coma expression Coma expression Coma expression RightParentesis Semicolon
                | Random LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], list) and isinstance(p[5], list) and isinstance(p[7], int) and isinstance(p[9], int):
        random(p[3][1:], p[5][1:], p[7], p[9])
    else:
        print("Error, la funcion Random debe recibir dos listas, y dos numeros")

def p_function_spiderWeb(p):
    """function : TelaArana LeftParentesis expression Coma expression RightParentesis Semicolon
                | TelaArana LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        telarana(p[3], p[5])
    else:
        print("Error, la funcion TelaAraña recibe unicamente 2 numeros como argumentos")

def p_function_asignWord(p):
    """function : ForAsignWord LeftParentesis expression Coma expression RightParentesis DO AsignWord LeftParentesis expression Coma expression RightParentesis Semicolon
                | ForAsignWord LeftParentesis expression Coma expression RightParentesis DO AsignWord LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int) and isinstance(p[10], list) and isinstance(p[12], list):
        spiderWebGame.setRow(p[3])
        spiderWebGame.setColumn(p[5])
        spiderWebGame.setInstruction(p[10][1:])
        spiderWebGame.setPoints(p[12][1:])
    else:
        print("Error, la funcion ForAsignWord recibe unicamente 2 numeros y la funcion AsignWord recibe 2 listas")

def p_function_object(p):
    """function : Object LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon
                | Object LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int) and isinstance(p[7], int):
        object(p[3], p[5], p[7])
    else:
        print("Error, la funcion Object recibe solamente 3 numeros")

def p_function_FORInt(p):
    """function : FOR expression times using expression Object LeftParentesis expression Coma expression LeftSquareBracket expression RightSquareBracket Coma expression RightParentesis function FEnd Semicolon
                | FOR expression times using expression Object LeftParentesis expression Coma expression LeftSquareBracket expression RightSquareBracket Coma expression RightParentesis function FEnd Semicolon function"""
    if isinstance(p[2], int) and isinstance(p[5], int) and isinstance(p[8], int) and isinstance(p[10], list) and isinstance(p[12], int) and isinstance(p[15], int) and p[5] == p[12] and len(p[10]) > p[12] > 0:
        objectGame.setRepetitions(p[2])
        objectGame.setIndex(p[5])
        object(p[8], p[10][p[12]], p[15])
    else:
        print("Error, la funcion FOR esta definida para usarse con la funcion Object")

def p_function_empty(p):
    'function : '

def p_error(p):
    if p:
        print("Error de sintaxis de '%s'" % p.value)
    else:
        print("Error de sintaxis en EOF")

yacc.yacc()

def balloon(alt, lat):
    balloonGame.addInstruction((alt, lat))

def object(alt, long, sec):
    objectGame.addInstruction((alt, long, sec))

def inc(number, increment):
    if currentGame == 1:
        balloonGame.addIteration((number, increment, 'Inc'))
    if currentGame == 2:
        flagGame.addIteration((number, increment, 'Inc'))
    if currentGame == 4:
        objectGame.addIteration((number, increment, 'Inc'))

def dec(number, decrement):
    if currentGame == 1:
        balloonGame.addIteration((number, decrement, 'Dec'))
    if currentGame == 2:
        flagGame.addIteration((number, decrement, 'Dec'))
    if currentGame == 4:
        objectGame.addIteration((number, decrement, 'Dec'))

def random(flagArray, pointsArray, cant, time):
    if currentGame == 2:
        flagGame.setInstruction(flagArray)
        flagGame.setPoints(pointsArray)
        flagGame.setItemsToRandomize(cant)
        flagGame.setRandomTime(time)

def telarana(row, column):
    i = 0
    j = 0
    matrix = []
    rows = []
    while i < row:
        while j < column:
            rows.append("")
            j += 1
        matrix.append(rows)
        rows = []
        i += 1
        j = 0
    spiderWebGame.setWeb(matrix)

data = """Begin
          Game1{
            int cant = 5;
            int alt = 3;
            int lat = 7;
            Dow(cant)
                Balloon(alt, lat);
                Inc(alt, 1);
                Dec(lat, 2);
            Enddo;  
          }
          Game2{
            int cant = 5;
            int tiempo = 60;
            texto(10) Color[10];
            int puntaje[10];
            Color[1] = "Azul";
            puntaje[1] = 10;
            FOR 5 times using Color
                Random(puntaje, cant, tiempo);
                Inc(cant, 3);
                Dec(tiempo, 10);
            FOREND;
          }
          Game3{
            texto(15) array[5];
            int puntos[5];
            array[1] = "Oceano";
            puntos[1] = 10;
            TelaArana(5, 5);
            ForAsignWord(5, 5) DO
                AsignWord(array, puntos);
          }
          Game4{
            int Dist[5];
            int a = 5;
            Dist[1] = 2;
            Dist[2] = 3;
            Dist[3] = 4;
            Dist[4] = 5;
            Dist[5] = 6;
            FOR 5 times using a
                Object(2, Dist[a], 25)
                Inc(a, 10);
            FEnd;
          }
          Finish;"""

yacc.parse(data)