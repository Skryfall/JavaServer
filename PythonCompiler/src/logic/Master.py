class Master(object):
    master = None
    balloonInstructions = []
    flagInstructions = []
    spiderWebInstructions = []
    objectInstructions = []

    def __new__(cls):
        if Master.master is None:
            Master.master = object.__new__(cls)
        return Master.master

    def getBalloonInstructions(self):
        return self.balloonInstructions

    def setBalloonInstructions(self, instructions):
        self.balloonInstructions = instructions

    def getFlagInstructions(self):
        return self.flagInstructions

    def setFlagInstructions(self, instructions):
        self.flagInstructions = instructions

    def getSpiderWebInstructions(self):
        return self.spiderWebInstructions

    def setSpiderWebInstructions(self, instructions):
        self.spiderWebInstructions = instructions

    def getObjectInstructions(self):
        return self.objectInstructions

    def setObjectInstructions(self, instructions):
        self.objectInstructions = instructions

    #Funcion que incrementa un numero cierta cantidad
    def increment(self, number, cuantity):
        number += cuantity
        return number

    #Funcion que decrementa un numero cierta cantidad
    def decrement(self, number, cuantity):
        number -= cuantity
        return number

    #Funcion que busca un numero en una lista
    def findNumberInList(self, list, number):
        for i in list:
            if i == number:
                return True
        return False
