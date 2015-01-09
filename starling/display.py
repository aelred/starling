def display(obj):
    try:
        obj.eval_str
    except AttributeError:
        if obj is None:
            return ''
        elif isinstance(obj, basestring):
            return '"%s"' % obj
        else:
            return str(obj)
    else:
        return obj.eval_str()
