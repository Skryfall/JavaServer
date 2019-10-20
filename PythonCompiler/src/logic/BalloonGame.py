class BalloonGame:
    def __init__(self):
        self.iterationList = []
        self.instructions = []
        self.repetitions = 0

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