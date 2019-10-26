import random

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

    def checkAmountofFlags(self):
        counter = 0
        for i in self.instructions:
            if (i != ''):
                counter += 1
            else:
                break
        return counter

    def randomizeFlags(self, flags, points, time, quantity, limit):
        index = quantity
        if quantity > limit:
            index = limit
        if quantity < 0:
            index = 0
        i = 0
        temporalFlags = ['', '', '', '', '', '', '', '', '', '']
        temporalPoints = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        randomsList = []
        while i != index + 1:
            randomNumber = random.randint(0, index)
            if not self.master.findNumberInList(randomsList, randomNumber):
                temporalFlags[i] = flags[randomNumber]
                temporalPoints[i] = points[randomNumber]
                randomsList.append(randomNumber)
                i += 1
        while index + 1 != 10:
            temporalFlags[index + 1] = flags[index + 1]
            temporalPoints[index + 1] = points[index + 1]
            index += 1
        return [temporalFlags, temporalPoints, time]

    def handleFlagLogic(self):
        self.itemsToRandomize -= 1
        temporalInstructions = self.instructions
        temporalPoints = self.points
        flagsInList = self.checkAmountofFlags() - 1
        temporalRandom = self.randomTime
        self.instructions = [self.randomizeFlags(temporalInstructions, temporalPoints, self.randomTime, self.itemsToRandomize, flagsInList)]
        while self.howManyRandoms - 1 >= 0:
            for i in self.iterationList:
                if i[2] == 'Inc':
                    if i[0] == temporalRandom:
                        self.randomTime = self.master.increment(self.randomTime, i[1])
                    else:
                        if self.itemsToRandomize < 9:
                            self.itemsToRandomize = self.master.increment(self.itemsToRandomize, i[1])
                else:
                    if i[0] == temporalRandom:
                        self.randomTime = self.master.decrement(self.randomTime, i[1])
                    else:
                        if self.itemsToRandomize > 0:
                            self.itemsToRandomize = self.master.decrement(self.itemsToRandomize, i[1])
            self.instructions.append(self.randomizeFlags(temporalInstructions, temporalPoints, self.randomTime, self.itemsToRandomize, flagsInList))
            self.howManyRandoms -= 1

        self.master.setFlagInstructions(self.instructions)
