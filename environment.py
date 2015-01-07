import logging

import error

log = logging.getLogger(__name__)


class Environment:
    _env_ids = 0

    def __init__(self, parent, bindings):
        self._id = Environment._env_ids
        Environment._env_ids += 1

        self._parent = parent
        self.bindings = dict(bindings)

        self.log = log.getChild(str(self))

        if self._parent is not None:
            self.log.debug('env %s -> %s: %r' %
                           (self, self._parent, self.bindings.keys()))

    def child(self, bindings):
        return Environment(self, bindings)

    def resolve(self, name):
        env = self

        while env is not None:
            env.log.debug('resolve %s' % (name,))
            if name in env.bindings:
                return env.bindings[name].eval()
            else:
                env = env._parent

        raise error.StarlingRuntimeError(
            'No binding for %r:\n%r' % (name, self))

    def __str__(self):
        return 'E%s' % self._id

    def __repr__(self):
        return '%s: %s\n%r' % (self, self.bindings.keys(), self._parent)
