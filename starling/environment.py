import logging

import error

log = logging.getLogger(__name__)


class Environment:
    _env_ids = 0

    def __init__(self, parent, bindings=None, label=None):
        self._id = Environment._env_ids
        Environment._env_ids += 1

        self._parent = parent
        self._label = label

        if bindings:
            self.bindings = dict(bindings)
        else:
            self.bindings = None

        if self._parent is not None:
            log.debug('env %s -> %s: %r' %
                      (self, self._parent, self.bindings.keys()))

    def child(self, bindings, label=None):
        return Environment(self, bindings, label)

    def ancestor(self):
        env = self
        while env._parent is not None and env._label != 'global':
            env = env._parent
        return env

    def resolve(self, name):
        env = self
        log.debug('resolve %s in %s' % (name, self._id))

        while env is not None:
            try:
                bind = env.bindings[name]
            except KeyError:
                env = env._parent
            else:
                # pull binding into this environment for effic:ency
                self.bindings[name] = bind
                return lambda: bind.dethunk()

        raise error.StarlingRuntimeError(
            'No binding for %r:\n%r' % (name, self))

    def __str__(self):
        return 'E%s' % self._id

    def __repr__(self):
        return '%s: %s\n%r' % (self, self.bindings.keys(), self._parent)
