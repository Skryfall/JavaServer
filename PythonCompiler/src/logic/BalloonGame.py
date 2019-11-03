from src.logic.Master import Master


class BalloonGame:
    def __init__(self):
        self.iterationList = []
        self.instructions = []
        self.repetitions = 0
        self.master = Master()

    def getIterationList(self):
        return self.iterationList

    def setIterationList(self, iterationList):
        self.iterationList = iterationList

    def getInstructions(self):
        return self.instructions

    def setInstruction(self, instructions):
        self.instructions = instructions

    def getRepetitions(self):
        return self.repetitions

    def setRepetitions(self, repetitions):
        self.repetitions = repetitions

    def addIteration(self, iteration):
        self.iterationList.append(iteration)

    def addInstruction(self, instruction):
        self.instructions.append(instruction)

    def handleBalloonLogic(self):
        while self.repetitions != 0:
            newAlt = self.instructions[0][0]
            newLat = self.instructions[0][1]
            newProf = self.instructions[0][2]
            for i in self.iterationList:
                if i[2] == 'Inc':
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.increment(self.instructions[len(self.instructions) - 1][0], i[1])
                    elif i[0] == self.instructions[0][1]:
                        newLat = self.master.increment(self.instructions[len(self.instructions) - 1][1], i[1])
                    else:
                        newProf = self.master.increment(self.instructions[len(self.instructions) - 1][2], i[1])
                else:
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.decrement(self.instructions[len(self.instructions) - 1][0], i[1])
                    elif i[0] == self.instructions[0][1]:
                        newLat = self.master.decrement(self.instructions[len(self.instructions) - 1][1], i[1])
                    else:
                        newProf = self.master.decrement(self.instructions[len(self.instructions) - 1][2], i[1])
            self.instructions.append((newAlt, newLat, newProf))
            self.repetitions -= 1
        self.master.setBalloonInstructions(self.instructions)
