function test1()
    @testset "Tests" begin
        @test EmptyPackage.sum_math(10) == 20
        f = EmptyPackage.Bar(2, "be")
        @test f.a == 2
        @test f.b == "be"
    end
end