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
        if self.row > len(self.web[0]) or self.column > len(self.web[0][0]):
            print("Error, el valor de fila o columna no es igual al implementado")
            sys.exit()

        i = 0
        j = 0
        index = 0
        while i < self.row:
            while j < self.column:
                self.web[0][i][j] = self.instructions[index]
                self.web[1][i][j] = self.points[index]
                index += 1
                j += 1
                if index == len(self.instructions):
                    break
            i += 1
            j = 0
            if index == len(self.instructions):
                break
        self.master.setSpiderWebInstructions(self.web)