import json
import sys

import ply.yacc as yacc

from src.logic.BalloonGame import BalloonGame
from src.logic.FlagGame import FlagGame
from src.logic.Master import Master
from src.logic.SpiderWebGame import SpiderWebGame
from src.logic.ObjectGame import ObjectGame
from src.compiler.CompilerLex import tokens
from src.server.ConnectionHandler import ConnectionHandler
from src.server.Holder import Holder

#Instancias de los juegos
balloonGame = BalloonGame()
flagGame = FlagGame()
spiderWebGame = SpiderWebGame()
objectGame = ObjectGame()
serverConnection = ConnectionHandler()
holder = Holder()
master = Master()

#Variables
names = {}
currentGame = 1

#Gramaticas de Libre Contexto

#Gramatica principal
#Tambien se encarga de realizar las preparaciones de los datos para enviarlos al server
def p_statement_main(p):
    """statement : Begin Game1 BeginParentesis initializer add game1 EndParentesis Game2 BeginParentesis initializer add game2 EndParentesis Game3 BeginParentesis initializer add game3 EndParentesis Game4 BeginParentesis initializer add game4 EndParentesis Finish Semicolon"""
    balloonGame.handleBalloonLogic()
    flagGame.handleFlagLogic()
    spiderWebGame.handleSpiderWebLogic()
    objectGame.handleObjectLogic()
    holder.setBalloonInstructions(master.getBalloonInstructions())
    holder.setFlagInstructions(master.getFlagInstructions())
    holder.setSpiderWebLetterInstructions(master.getSpiderWebInstructions()[0])
    holder.setSpiderWebPointsInstructions(master.getSpiderWebInstructions()[1])
    holder.setObjectInstructions(master.getObjectInstructions())
   # serverConnection.sendToServer('http://localhost:9080/MotorTherapy_war_exploded/MotorTherapy/GameData', holder.toJSON())

#Gramatica que cambia la variable que indica el juego que se va a ajustar
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

#Gramatica que indica como es un numero
def p_expression_number(p):
    "expression : Number"
    p[0] = p[1]

#Gramatica que indica como es un string
def p_expression_string(p):
    "expression : String"
    p[0] = p[1]

#Gramatica que indica los nombres de las variables
def p_expression_name(p):
    "expression : Name"
    try:
        p[0] = names[p[1]]
    except LookupError:
        print("Nombre indeterminado '%s'" % p[1])
        p[0] = 0
        sys.exit()

#Gramatica que se encarga del manejo del inicializacion y creacion de variables
def p_initializer_assignOrCreate(p):
    """initializer : assign
                   | create
                   |"""

#Gramatica encargada de asignar un numero a un nombre
def p_assign_int(p):
    """assign : int Name Equals expression Semicolon
              | int Name Equals expression Semicolon assign
              | int Name Equals expression Semicolon create"""
    names[p[2]] = p[4]

#Gramatica vacia
def p_assign_empty(p):
    'assign : '

#Gramatica que se encarga de crear una lista de strings
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

#Gramatica que se encarga de crear una lista de numeros
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

#Gramatica vacia
def p_create_empty(p):
    'create : '

#Gramatica que se encarga de agregar un elemento a una lista
def p_add_toList(p):
    """add : Name LeftSquareBracket expression RightSquareBracket Equals expression Semicolon
           | Name LeftSquareBracket expression RightSquareBracket Equals expression Semicolon add"""
    array = names[p[1]][0]
    if isinstance(array[0], str) and isinstance(p[6], str) and len(p[6]) < array[1] + 3 and array[1] + 1 > p[3] > 0:
        names[p[1]][p[3]] = p[6][1:len(p[6]) - 1]
    elif isinstance(array[0], int) and isinstance(p[6], int) and array[1] + 1 > p[3] > 0:
        names[p[1]][p[3]] = p[6]
    else:
        print("Error, no se pudo agregar el elemento " + p[6] + " a la lista " + p[1])
        sys.exit()

#Gramatica vacia
def p_add_empty(p):
    'add : '

#Gramatica para imprimir una variable
def p_function_printExpression(p):
    """function : expression
                | expression function"""
    print(p[1])

#Gramatica de la funcion dow
def p_function_dow(p):
    """function : Dow LeftParentesis expression RightParentesis function Enddo Semicolon
                | Dow LeftParentesis expression RightParentesis function Enddo Semicolon function"""
    if isinstance(p[3], int):
        if currentGame == 1:
            balloonGame.setRepetitions(p[3])
    else:
        print("Error, la funcion Dow no esta escrita de manera correcta.")
        print("La estructura del Dow es: Dow(numero de repeticiones) 'instrucciones' Enddo;")
        sys.exit()

#Gramatica de la funcion balloon
def p_function_balloon(p):
    """function : Balloon LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon
                | Balloon LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int) and isinstance(p[7], int):
        balloon(p[3], p[5], p[7])
    else:
        print("Error, la funcion Balloon no esta escrita de manera correcta.")
        print("La estructura del Balloon es: Balloon(altura, latitud, profundidad);")
        sys.exit()

#Gramatica de la funcion inc
def p_function_inc(p):
    """function : Inc LeftParentesis expression Coma expression RightParentesis Semicolon
                | Inc LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        inc(p[3], p[5])
    else:
        print("Error, la funcion Inc no esta escrita de manera correcta.")
        print("La estructura del Inc es: Inc(valor, cantidad a aumentar);")
        sys.exit()

#Gramatica de la funcion dec
def p_function_dec(p):
    """function : Dec LeftParentesis expression Coma expression RightParentesis Semicolon
                | Dec LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        dec(p[3], p[5])
    else:
        print("Error, la funcion Dec no esta escrita de manera correcta.")
        print("La estructura del Dec es: Inc(valor, cantidad a disminuir);")
        sys.exit()

#Gramatica de la funcion FOR con el Random especial
def p_function_FORList(p):
    """function : FOR expression times using expression Random LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function FOREND Semicolon
                | FOR expression times using expression Random LeftParentesis expression Coma expression Coma expression RightParentesis Semicolon function FOREND Semicolon function"""
    if isinstance(p[2], int) and isinstance(p[5], list) and isinstance(p[8], list) and isinstance(p[10], int) and isinstance(p[12], int) and 0 < p[10] < 11 and 0 < p[12]:
        flagGame.setHowManyRandoms(p[2])
        random(p[5][1:], p[8][1:], p[10], p[12])
    else:
        print("Error, la funcion FOR no esta escrita de manera correcta.")
        print("La estructura del FOR es: FOR 'numero de repeticiones' times using 'lista de banderas' Random(puntaje, cantidad, tiempo) 'instrucciones' FOREND;")
        sys.exit()

#Gramatica de la funcion random
def p_function_random(p):
    """function : Random LeftParentesis expression Coma expression Coma expression Coma expression RightParentesis Semicolon
                | Random LeftParentesis expression Coma expression Coma expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], list) and isinstance(p[5], list) and isinstance(p[7], int) and isinstance(p[9], int):
        random(p[3][1:], p[5][1:], p[7], p[9])
    else:
        print("Error, la funcion Random no esta escrita de manera correcta.")
        print("La estructura del Random es: Random(banderas, puntaje, cantidad, tiempo);")
        sys.exit()

#Gramatica de la funcion telarana
def p_function_spiderWeb(p):
    """function : TelaArana LeftParentesis expression Coma expression RightParentesis Semicolon
                | TelaArana LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int):
        telarana(p[3], p[5])
    else:
        print("Error, la funcion TelaAraña no esta escrita de manera correcta.")
        print("La estructura correcta es: TelaArana(filas, columnas);")
        sys.exit()

#Gramatica de la funcion asignWord
def p_function_asignWord(p):
    """function : ForAsignWord LeftParentesis expression Coma expression RightParentesis DO AsignWord LeftParentesis expression Coma expression RightParentesis Semicolon
                | ForAsignWord LeftParentesis expression Coma expression RightParentesis DO AsignWord LeftParentesis expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int) and isinstance(p[10], list) and isinstance(p[12], list) and p[3] > 0 and p[5] > 0:
        spiderWebGame.setRow(p[3])
        spiderWebGame.setColumn(p[5])
        spiderWebGame.setInstruction(p[10][1:])
        spiderWebGame.setPoints(p[12][1:])
    else:
        print("Error, la funcion ForAsignWord no esta escrita de manera correcta.")
        print("La estructura correcta es: ForAsignWord(fila, columna) DO AsignWord(palabras, puntajes);")
        sys.exit()

#Gramatica de la funcion object
def p_function_object(p):
    """function : Object LeftParentesis expression Coma expression Coma expression Coma expression RightParentesis Semicolon
                | Object LeftParentesis expression Coma expression Coma expression Coma expression RightParentesis Semicolon function"""
    if isinstance(p[3], int) and isinstance(p[5], int) and isinstance(p[7], int) and isinstance(p[9], int):
        object(p[3], p[5], p[7], p[9])
    else:
        print("Error, la funcion Object no esta escrita de manera correcta.")
        print("La estrucutra correcta es: Object(altura, distancia, profundidad, tiempo);")
        sys.exit()

#Gramatica de la funcion FOR para ser usado con la funcion Object especial
def p_function_FORInt(p):
    """function : FOR expression times using Name Object LeftParentesis expression Coma expression LeftSquareBracket Name RightSquareBracket Coma expression Coma expression RightParentesis function FEnd Semicolon
                | FOR expression times using Name Object LeftParentesis expression Coma expression LeftSquareBracket Name RightSquareBracket Coma expression Coma expression RightParentesis function FEnd Semicolon function"""
    if isinstance(p[2], int) and isinstance(p[5], str) and isinstance(p[8], int) and isinstance(p[10], list) and isinstance(p[12], str) and isinstance(p[15], int) and isinstance(p[17], int) and p[5] == p[12]:
        objectGame.setRepetitions(p[2])
        objectGame.setDistances(p[10][1:])
        object(p[8], p[10][1], p[15], p[17])
    else:
        print("Error, la funcion FOR no esta escrita de manera correcta.")
        print("La esctructura correcta es: FOR 'numero de repeticiones' times using variable Object(altura, 'lista de distancia'[variable], profundidad, tiempo) 'instrucciones' FEnd;")
        sys.exit()

#Gramatica vacia
def p_function_empty(p):
    'function : '

#Manejo de errores en el parseo
def p_error(p):
    if p:
        print("Error de sintaxis de '%s'" % p.value)
        sys.exit()
    else:
        print("Error de sintaxis en Final de Archivo")
        sys.exit()

yacc.yacc()

#Funcion que recibe la altura, latitud y profundidad del globo y la inserta en una lista
def balloon(alt, lat, prof):
    balloonGame.addInstruction((alt, lat, prof))

#Funcion que recibe la altura, latitud, profundidad y tiempo del objeto y lo inserta en una lista
def object(alt, long, prof, sec):
    objectGame.addInstruction((alt, long, prof, sec))

#Funcion que recibe un numero y la cantidad a incrementarlo, seguidamente lo inserta en una lista dependiendo del juego actual
def inc(number, increment):
    if currentGame == 1:
        balloonGame.addIteration((number, increment, 'Inc'))
    if currentGame == 2:
        flagGame.addIteration((number, increment, 'Inc'))
    if currentGame == 4:
        objectGame.addIteration((number, increment, 'Inc'))

#Funcion que recibe un numero y la cantidad a decrementarlo, seguidamente lo inserta en una lista dependiendo del juego actual
def dec(number, decrement):
    if currentGame == 1:
        balloonGame.addIteration((number, decrement, 'Dec'))
    if currentGame == 2:
        flagGame.addIteration((number, decrement, 'Dec'))
    if currentGame == 4:
        objectGame.addIteration((number, decrement, 'Dec'))

#Funcion que recibe la lista de banderas, la lista de los puntos de las banderas, la cantidad de banderas a randomizar y el tiempo de juego, ademas los mete en listas
def random(flagArray, pointsArray, cant, time):
    if currentGame == 2:
        flagGame.setInstruction(flagArray)
        flagGame.setPoints(pointsArray)
        flagGame.setItemsToRandomize(cant)
        flagGame.setRandomTime(time)

#Funcion que recibe una fila y una columna y crea una matriz con los valores dados
def telarana(row, column):
    i = 0
    j = 0
    letterMatrix = []
    letterRows = []
    pointsMatrix = []
    pointsRows = []
    while i < row:
        while j < column:
            letterRows.append("")
            pointsRows.append(0)
            j += 1
        letterMatrix.append(letterRows)
        pointsMatrix.append(pointsRows)
        letterRows = []
        pointsRows = []
        i += 1
        j = 0
    spiderWebGame.setWeb([letterMatrix, pointsMatrix])

#Colores de las banderas: green, red, orange, blue, yellow, brown, purple, gray, magenta y cyan

#String del codigo principal
data = """Begin
          Game1{
            int cant = 5;
            int alt = 3;
            int lat = 7;
            int prof = 1;
            Dow(cant)
                Balloon(alt, lat, prof);
                Inc(alt, 1);
                Dec(lat, 2);
            Enddo;  
          }
          Game2{
            int cant = 3;
            int tiempo = 60;
            texto(10) Color[10];
            int puntaje[10];
            Color[1] = "green";
            Color[2] = "grey";
            Color[3] = "yellow";
            Color[4] = "purple";
            Color[5] = "green";
            Color[6] = "red";
            Color[7] = "brown";
            Color[8] = "cyan";
            Color[9] = "red";
            Color[10] = "magenta";
            puntaje[1] = 10;
            puntaje[2] = 20;
            puntaje[3] = 13;
            puntaje[4] = 200;
            puntaje[5] = 1;
            puntaje[6] = 90;
            puntaje[7] = 76;
            puntaje[8] = 12;
            puntaje[9] = 10;
            puntaje[10] = 50;
            FOR 5 times using Color
                Random(puntaje, cant, tiempo);
                Inc(cant, 3);
                Dec(tiempo, 5);
            FOREND;
          }
          Game3{
            texto(15) array[9];
            int puntos[9];
            array[1] = "Oceano";
            array[2] = "Azul";
            array[3] = "Casa";
            array[4] = "Plata";
            array[5] = "Cama";
            array[6] = "Ojo";
            array[7] = "Perro";
            array[8] = "Nariz";
            array[9] = "Minecraft";
            puntos[1] = 10;
            puntos[2] = 34;
            puntos[3] = 89;
            puntos[4] = 90;
            puntos[5] = 54;
            puntos[6] = 18;
            puntos[7] = 1;
            puntos[8] = 50;
            puntos[9] = 89;
            TelaArana(3, 3);
            ForAsignWord(3, 3) DO
                AsignWord(array, puntos);
          }
          Game4{
            int Dist[5];
            int cnt = 3;
            int tme = 60;
            int profun = 1;
            Dist[1] = 2;
            Dist[2] = 3;
            Dist[3] = 4;
            Dist[4] = 5;
            Dist[5] = 6;
            FOR 5 times using var
                Object(cnt, Dist[var], profun, tme)
                Inc(cnt, 10);
                Dec(tme, 10);
            FEnd;
          }
          Finish;"""

yacc.parse(data)