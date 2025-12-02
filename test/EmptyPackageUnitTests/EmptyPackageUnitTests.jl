# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

module EmptyPackageUnitTests

using Test, EmptyPackage, Revise

include("test1.jl")

function run()
    test1()
end

end # module EmptyPackageUnitTests
