import sys

from src.logic.FlagGame import FlagGame

class SpiderWebGame(FlagGame):
    def __init__(self):
        FlagGame.__init__(self)
        self.row = 0
        self.column = 0
        self.web = []

    def getRow(self):
        return self.row

    def setRow(self, row):
        self.row = row

    def getColumn(self):
        return self.column

    def setColumn(self, column):
        self.column = column

    def getWeb(self):
        return self.web

    def setWeb(self, web):
        self.web = web

    def startingMatrixPoint(self, number, list):
        i = 0
        while list[i + 1] != '':
            if number > 0 and list[i + 1] != '':
                number -= 1
            else:
                break
        return number

    def handleSpiderWebLogic(self):
        self.row -= 1
        self.column -= 1
        if self.row > len(self.web[0]) - 1 or self.column > len(self.web[0][0]):
            print("Error, el valor de fila o columna es mayor al implementado")
            sys.exit()

        firstRow = self.startingMatrixPoint(self.row, self.instructions)
        firstColumn = self.startingMatrixPoint(self.column, self.instructions)

        i = 0
        while firstRow != self.row + 1:
            self.web[0][firstRow][firstColumn] = self.instructions[i]
            self.web[1][firstRow][firstColumn] = self.points[i]
            i += 1
            firstColumn += 1
            firstRow += 1

        self.master.setSpiderWebInstructions(self.web)