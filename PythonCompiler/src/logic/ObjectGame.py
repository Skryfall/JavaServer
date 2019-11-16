from src.logic.BalloonGame import BalloonGame

class ObjectGame(BalloonGame):
    def __init__(self):
        BalloonGame.__init__(self)
        self.distances = []

    def getDistances(self):
        return self.distances

    def setDistances(self, distances):
        self.distances = distances

    # Metodo que se encarga de realizar las preparaciones del juego del objeto
    # Itera lo requerido por el usuario
    # Al final lo almacena en una lista para que sea serializado
    def handleObjectLogic(self):
        startIndex = 1
        while self.repetitions != 1:
            newAlt = self.instructions[0][0]
            newProf = self.instructions[0][2]
            newTime = self.instructions[0][3]
            for i in self.iterationList:
                if i[2] == 'Inc':
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.increment(self.instructions[len(self.instructions) - 1][0], i[1])
                    elif i[0] == self.instructions[0][2]:
                        newProf = self.master.increment(self.instructions[len(self.instructions) - 1][2], i[1])
                    else:
                        newTime = self.master.increment(self.instructions[len(self.instructions) - 1][3], i[1])
                else:
                    if i[0] == self.instructions[0][0]:
                        newAlt = self.master.decrement(self.instructions[len(self.instructions) - 1][0], i[1])
                    elif i[0] == self.instructions[0][2]:
                        newProf = self.master.decrement(self.instructions[len(self.instructions) - 1][2], i[1])
                    else:
                        newTime = self.master.decrement(self.instructions[len(self.instructions) - 1][3], i[1])
            self.instructions.append((newAlt, self.distances[startIndex], newProf, newTime))
            self.repetitions -= 1
            startIndex += 1
        self.master.setObjectInstructions(self.instructions)