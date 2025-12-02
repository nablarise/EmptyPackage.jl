module EmptyPackage

struct Bar
    a::Int
    b::String
    #c::String
end

greet() = print("Hello World!")
sum_math(a) = a + 10

end # module EmptyPackage
