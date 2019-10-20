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

    def increment(self, number, cuantity):
        number += cuantity
        return number

    def decrement(self, number, cuantity):
        number -= cuantity
        return number
