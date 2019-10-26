from src.logic.BalloonGame import BalloonGame

class ObjectGame(BalloonGame):
    def __init__(self):
        BalloonGame.__init__(self)
        self.index = 0
        self.distances = []

    def getIndex(self):
        return self.index

    def setIndex(self, index):
        self.index = index

    def getDistances(self):
        return self.distances

    def setDistances(self, distances):
        self.distances = distances

    def handleObjectLogic(self):
        startIndex = 1
        while self.repetitions != 1:
            newAlt = 0
            newTime = 0
            for i in self.iterationList:
                if i[2] == 'Inc':
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.increment(self.instructions[len(self.instructions) - 1][0], i[1])
                    else:
                        newTime = self.master.increment(self.instructions[len(self.instructions) - 1][2], i[1])
                else:
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.decrement(self.instructions[len(self.instructions) - 1][0], i[1])
                    else:
                        newTime = self.master.decrement(self.instructions[len(self.instructions) - 1][2], i[1])
            self.instructions.append((newAlt, self.distances[startIndex], newTime))
            self.repetitions -= 1
            startIndex += 1
        self.master.setObjectInstructions(self.instructions)