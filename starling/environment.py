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

    def ancestor(self):
        env = self
        while env._parent is not None:
            env = env._parent
        return env

    def resolve(self, name):
        env = self

        while env is not None:
            env.log.debug('resolve %s' % (name,))
            try:
                bind = env.bindings[name]
            except KeyError:
                env = env._parent
            else:
                # pull binding into this environment for effic:ency
                self.bindings[name] = bind
                return bind.eval()

        raise error.StarlingRuntimeError(
            'No binding for %r:\n%r' % (name, self))

    def __str__(self):
        return 'E%s' % self._id

    def __repr__(self):
        return '%s: %s\n%r' % (self, self.bindings.keys(), self._parent)
