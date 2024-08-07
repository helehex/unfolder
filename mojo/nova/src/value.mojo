# x----------------------------------------------------------------------------------------------x #
# | Helehex 2024
# x----------------------------------------------------------------------------------------------x #
"""Nova Traits."""


trait Equatable(EqualityComparable):
    ...


trait Value(Stringable, Equatable, DefaultableValue):
    ...


trait DefaultableValue(Defaultable, CollectionElement):
    ...


trait StringableValue(Stringable, DefaultableValue):
    ...


trait EquatableValue(Equatable, DefaultableValue):
    ...


trait BoolableValue(Boolable, DefaultableValue):
    ...


trait StringableKeyElement(Stringable, KeyElement):
    ...


trait Drawable:
    def draw(self, canvas: PythonObject):
        ...
