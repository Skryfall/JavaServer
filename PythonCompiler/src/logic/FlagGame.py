from src.logic.BalloonGame import BalloonGame


class FlagGame(BalloonGame):
    def __init__(self):
        BalloonGame.__init__(self)
        self.points = []
        self.howManyRandoms = 0
        self.itemsToRandomize = 0
        self.randomTime = 0

    def getPoints(self):
        return self.points

    def setPoints(self, pointsList):
        self.points = pointsList

    def getHowManyRandoms(self):
        return self.howManyRandoms

    def setHowManyRandoms(self, randoms):
        self.howManyRandoms = randoms

    def getItemsToRandomize(self):
        return self.itemsToRandomize

    def setItemsToRandomize(self, items):
        self.itemsToRandomize = items

    def getRandomTime(self):
        return self.randomTime

    def setRandomTime(self, times):
        self.randomTime = times

