from src.logic.BalloonGame import BalloonGame

class ObjectGame(BalloonGame):
    def __init__(self):
        BalloonGame.__init__(self)
        self.index = 0

    def getIndex(self):
        return self.index

    def setIndex(self, index):
        self.index = index