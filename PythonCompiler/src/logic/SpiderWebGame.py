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