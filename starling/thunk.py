import logging

log = logging.getLogger(__name__)


class Thunk:

    def __init__(self, token, name, env=None):
        self.token = token
        self._name = name
        self.env = env
        self._memory = None
        self._remembers = False

    def eval(self):
        if not self._remembers:
            log.info('eval\n%s' % self.token)
            self._memory = self.token.eval(self.env)
            log.debug('result\n%s = %s' % (self.token, self._memory))
            self._remembers = True
        return self._memory

    def __str__(self):
        return self._name
