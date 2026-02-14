# Copyright (c) 2025 Nablarise
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

function test1()
    @test EmptyPackage.sum_math(10) == 20
    f = EmptyPackage.Bar(2, "be", "test")
    @test f.a == 2
    @test f.b == "be"
    @test f.c == "test"
end