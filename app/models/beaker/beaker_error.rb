# Class for our exceptions.
# One of our exceptions isa StandardError.
# Although the origin of our exception may be from a network call,
# our exceptions are exceptions our classes are raising, not an IO or Network related error.
class Beaker::BeakerError < StandardError
end
