# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module EmptyPackage

struct Bar
    a::Int
    b::String
    #c::String # Test struct change.
end

greet() = print("Hello World!")
sum_math(a) = a + 1

f() = 1

end # module EmptyPackage
