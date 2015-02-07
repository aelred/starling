import logging

log = logging.getLogger(__name__)


class Thunk(object):

    def __init__(self, token, name, env=None):
        self.token = token
        self._name = name
        self._memory = None
        self._remembers = False
        self.env = env
        self.strict_dethunk()

    def strict_dethunk(self):
        # dethunk only if token is strict
        if self.env is not None and not self.token.lazy:
            self.dethunk()

    def dethunk(self):
        if not self._remembers:
            log.info('dethunk (%s)\n%s' % (self.env, self.token))
            self._memory = self.token.trampoline(self.env)
            log.debug('result\n%s = %s' % (self.token, self._memory))
            self._remembers = True

            # forget the environment! WHO CARES ABOUT IT ANYMORE
            # (now it can be garbage collected)
            self.env = None
        return self._memory

    def __str__(self):
        return self._name
