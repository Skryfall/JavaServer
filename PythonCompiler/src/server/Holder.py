import json


class Holder:

    def __init__(self):
        self.balloonInstructions = []
        self.flagColorsInstructions = []
        self.flagPointsInstructions = []
        self.flagTimeInstructions = []
        self.spiderWebLetterInstructions = []
        self.spiderWebPointsInstructions = []
        self.objectInstructions = []

    def getBalloonInstructions(self):
        return self.balloonInstructions

    def setBalloonInstructions(self, instructions):
        self.balloonInstructions = instructions

    def getFlagColorsInstructions(self):
        return self.flagColorsInstructions

    def setFlagColorsInstructions(self, instructions):
        self.flagColorsInstructions = instructions

    def getFlagPointsInstructions(self):
        return self.flagPointsInstructions

    def setFlagPointsInstructions(self, instructions):
        self.flagPointsInstructions = instructions

    def getFlagTimeInstructions(self):
        return self.flagTimeInstructions

    def setFlagTimeInstructions(self, instructions):
        self.flagTimeInstructions = instructions

    def getSpiderWebLetterInstructions(self):
        return self.spiderWebLetterInstructions

    def setSpiderWebLetterInstructions(self, instructions):
        self.spiderWebLetterInstructions = instructions

    def getSpiderWebPointsInstructions(self):
        return self.spiderWebPointsInstructions

    def setSpiderWebPointsInstructions(self, instructions):
        self.spiderWebPointsInstructions = instructions

    def getObjectInstructions(self):
        return self.objectInstructions

    def setObjectInstructions(self, instructions):
        self.objectInstructions = instructions

    #Funcion que prepara la lista del juego de las banderas para que pueda ser serializada correctamente
    def setFlagInstructions(self, instructions):
        colors = []
        points = []
        time = []
        for i in instructions:
            colors.append(i[0])
            points.append(i[1])
            time.append(i[2])
        self.flagColorsInstructions = colors
        self.flagPointsInstructions = points
        self.flagTimeInstructions = time

    #Funcion que serializa la instancia de la clase a json
    def toJSON(self):
        return json.dumps(self, default = lambda o: o.__dict__)