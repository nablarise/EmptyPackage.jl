module EmptyPackageUnitTests

using Test, EmptyPackage, Revise

include("test1.jl")

function run()
    test1()
end

end # module EmptyPackageUnitTests
